class_name PracticeSession
extends RefCounted
## Treino livre: cada piloto segue um PROGRAMA montado com blocos predefinidos (acerto aero,
## acerto mecânico, simulação de corrida, volta rápida). Cada bloco aproxima o acerto do ideal,
## com resultado aleatório (o piloto pode errar, o carro pode quebrar).
##
## Desde 2026-11-08 o treino é sempre simulado (run_to_end). Quanto cada bloco acerta o carro sai de quem trabalha nele:
## diretor de engenharia de pista 35%, engenheiro de corrida do carro 30%, piloto 15% e sorte 20% (team.practice_skills).

signal lap_completed(car: CarState, lap_time: float)
signal block_finished(car: CarState, block_id: String, text: String)
signal session_finished

const SESSION_S := 3600.0  ## treino livre de 60 minutos
const GARAGE_S := 120.0  ## tempo na garagem entre blocos (ajustes no carro)
const DT := 1.0

## Blocos predefinidos (os ids ficam nos dados do programa; os nomes aparecem na tela).
const BLOCKS := {
	"aero": {"name": "Acerto aero", "minutes": 15},
	"mech": {"name": "Acerto mecânico", "minutes": 15},
	"race": {"name": "Simulação de corrida", "minutes": 20},
	"quali": {"name": "Volta rápida", "minutes": 10},
}
const DEFAULT_PROGRAM := ["aero", "mech", "race", "quali"]

## Efeitos (PROVISÓRIOS)
const W_DIRECTOR := 0.35  ## pesos do acerto sorteado (decisão do usuário, 2026-11-08)
const W_ENGINEER := 0.30
const W_DRIVER := 0.15
const W_LUCK := 0.20
const SKILL_LOW := 40.0  ## nota que vale 0 na conta (e SKILL_LOW + SKILL_SPAN vale 1)
const SKILL_SPAN := 55.0
const GAIN_MIN := 0.25  ## cada bloco cobre de 25% (tudo ruim) a 75% (tudo ótimo) do que falta para o ideal
const GAIN_SPAN := 0.5
const BALANCE_SHARE := 0.4  ## acertar aero/mecânico também melhora o equilíbrio
const PROBLEM_BASE := 0.08  ## chance de um bloco dar errado (mais para pilotos menos precisos)
const PROBLEM_PER_RATING := 0.004
const FUEL_RACE_S := 1.5  ## simulação de corrida: tanque cheio
const FUEL_NORMAL_S := 0.6
const LAP_NOISE := 0.25

var track: TrackModel
var tyres: TyreModel
var weather: WeatherModel
var cars: Array[CarState] = []
var setups: Dictionary = {}  ## id do piloto -> CarSetup (alterado ao fim de cada bloco)
var programs: Dictionary = {}  ## id do piloto -> Array de ids de bloco
var time_s := 0.0
var _acc := 0.0
var over := false
var rng := RandomNumberGenerator.new()
var history: Array[Dictionary] = []  ## {car, block, text, kind ("ok"/"wet"/"spin"/"failure")} — resumo do treino
var setups_before: Dictionary = {}  ## id do piloto -> cópia do CarSetup no começo do treino
var draws: Dictionary = {}  ## id do piloto -> Array das notas sorteadas (0..1) de cada bloco

var _plan: Dictionary = {}  # CarState -> {queue, block, block_end, next_lap}


## options: seed, player_team, weather, rain_probability.
## programs: id do piloto -> Array de blocos (quem não tiver usa um programa padrão da IA).
func _init(p_track: TrackModel, p_tyres: TyreModel, teams: Array, drivers: Array,
		p_setups: Dictionary, p_programs: Dictionary = {}, options: Dictionary = {}) -> void:
	track = p_track
	tyres = p_tyres
	setups = p_setups
	rng.seed = int(options.get("seed", 1))
	var rain_p := float(options.get("rain_probability", track.rain_probability))
	weather = WeatherModel.new(rain_p, SESSION_S, rng, options)
	var player_team: String = options.get("player_team", "")
	for d: Dictionary in drivers:
		var car := CarState.new()
		car.index = cars.size()
		car.driver = d
		car.team = GameData.team_by_id(teams, d["team"])
		car.is_player = car.team["id"] == player_team
		cars.append(car)
		if not setups.has(d["id"]):
			setups[d["id"]] = CarSetup.random_start(rng)
		setups_before[d["id"]] = (setups[d["id"]] as CarSetup).copy()
		draws[d["id"]] = []
		var prog: Array = p_programs.get(d["id"], _ai_program())
		programs[d["id"]] = valid_program(prog)
		_plan[car] = {"queue": programs[d["id"]].duplicate(), "block": "", "block_end": 0.0, "next_lap": INF}
		_start_next_block(car, rng.randf_range(0.0, 90.0))  # nem todos saem no primeiro minuto


## Corta o programa no que cabe nos 60 minutos (soma dos blocos; a garagem entre um bloco e
## outro sai do tempo do próprio treino e pode encurtar o último bloco).
static func valid_program(prog: Array) -> Array[String]:
	var out: Array[String] = []
	var used := 0
	for id: String in prog:
		if not BLOCKS.has(id):
			continue
		var need := int(BLOCKS[id]["minutes"])
		if used + need > int(SESSION_S / 60.0):
			break
		out.append(id)
		used += need
	return out


static func program_minutes(prog: Array) -> int:
	var m := 0
	for id: String in prog:
		m += int(BLOCKS[id]["minutes"]) if BLOCKS.has(id) else 0
	return m


func _ai_program() -> Array:
	var p := DEFAULT_PROGRAM.duplicate()
	if rng.randf() < 0.5:  # ordem dos dois primeiros varia entre equipes
		p[0] = "mech"
		p[1] = "aero"
	return p


# --- tempo ------------------------------------------------------------------------------

func advance(seconds: float) -> void:
	_acc += seconds  # guarda o resto do quadro (a 60 fps um quadro é menor que um passo)
	var steps := int(_acc / DT)
	_acc -= steps * DT
	for i in steps:
		if over:
			return
		step()


func run_to_end() -> void:
	while not over:
		step()


func step() -> void:
	time_s += DT
	weather.step(DT)
	for car in cars:
		var plan: Dictionary = _plan[car]
		if plan["block"] == "":
			continue
		if time_s >= plan["next_lap"]:
			_complete_lap(car, plan)
		if time_s >= plan["block_end"]:
			_finish_block(car, plan)
	if time_s >= SESSION_S:
		over = true
		session_finished.emit()


func _start_next_block(car: CarState, delay: float) -> void:
	var plan: Dictionary = _plan[car]
	if plan["queue"].is_empty() or time_s + delay >= SESSION_S:
		plan["block"] = ""
		return
	var id: String = plan["queue"].pop_front()
	plan["block"] = id
	var full := float(BLOCKS[id]["minutes"]) * 60.0
	plan["block_end"] = minf(SESSION_S, time_s + delay + full)
	plan["block_share"] = clampf((plan["block_end"] - time_s - delay) / full, 0.0, 1.0)  # cortado pelo fim do treino
	car.tyre = "soft" if id == "quali" else "medium"
	car.tyre_wear = 0.0
	plan["next_lap"] = time_s + delay + practice_lap_time(car, id) * 1.3  # volta de saída


func _complete_lap(car: CarState, plan: Dictionary) -> void:
	var t := practice_lap_time(car, plan["block"]) + rng.randfn(0.0, LAP_NOISE)
	car.last_lap_time = t
	car.lap_times.append(t)
	car.laps_done += 1
	car.best_lap_time = minf(car.best_lap_time, t)
	car.tyre_wear += tyres.wear_per_lap(car.tyre) * track.tyre_wear_factor
	lap_completed.emit(car, t)
	plan["next_lap"] = time_s + practice_lap_time(car, plan["block"])


## Tempo de uma volta lançada neste bloco (sem a sorte da volta).
func practice_lap_time(car: CarState, block_id: String) -> float:
	var setup: CarSetup = setups[car.driver["id"]]
	var t := RaceSim.base_lap_time(track, car.team, car.driver) + setup.lap_penalty_s()
	t += tyres.pace_penalty(car.tyre, car.tyre_wear)
	t += tyres.wet_penalty(car.tyre, weather.wetness) + weather.wetness * RaceSim.WET_TRACK_S
	if block_id == "race":
		t += FUEL_RACE_S
	elif block_id == "quali":
		t -= setup.quali_bonus_s()
	else:
		t += FUEL_NORMAL_S
	return t


## Capacidade de acerto do piloto (0..1): regularidade e gestão de pneus (quem sente o carro e explica o que falta).
static func driver_setup_skill(driver: Dictionary) -> float:
	return (DriverStats.attr(driver, "consistency") + DriverStats.attr(driver, "tyres")) / 2.0


static func _n(skill: float) -> float:
	return clampf((skill - SKILL_LOW) / SKILL_SPAN, 0.0, 1.0)


## Parte fixa do acerto (sem a sorte), 0..0.8. skills: {director, engineer} (notas 0-100).
static func setup_ability(skills: Dictionary, driver: Dictionary) -> Dictionary:
	var dir := W_DIRECTOR * _n(float(skills.get("director", 55)))
	var eng := W_ENGINEER * _n(float(skills.get("engineer", 55)))
	var drv := W_DRIVER * _n(driver_setup_skill(driver))
	return {"director": dir, "engineer": eng, "driver": drv, "luck": W_LUCK * 0.5, "total": dir + eng + drv}


## Chance de bom acerto mostrada na tela (0..1): a parte fixa + a sorte média.
static func setup_chance(skills: Dictionary, driver: Dictionary) -> float:
	return float(setup_ability(skills, driver)["total"]) + W_LUCK * 0.5


func skills_of(car: CarState) -> Dictionary:
	return (car.team.get("practice_skills", {}) as Dictionary).get(car.driver["id"], {})


## Nota sorteada de um bloco (0..1): diretor 35 + engenheiro 30 + piloto 15 + sorte 20.
func _draw(car: CarState) -> float:
	return float(setup_ability(skills_of(car), car.driver)["total"]) + W_LUCK * rng.randf()


func _finish_block(car: CarState, plan: Dictionary) -> void:
	var id: String = plan["block"]
	var setup: CarSetup = setups[car.driver["id"]]
	var c := _draw(car)
	(draws[car.driver["id"]] as Array).append(c)
	var gain := (GAIN_MIN + GAIN_SPAN * c) * float(plan.get("block_share", 1.0)) * float(car.team.get("practice_gain_mult", 1.0))
	var text := ""
	var kind := "ok"
	var problem_chance := PROBLEM_BASE + (100.0 - DriverStats.attr(car.driver, "consistency")) * PROBLEM_PER_RATING
	if weather.wetness > 0.3 and id != "race":
		gain *= 0.4  # acerto de pista seca não se aprende na chuva
		kind = "wet"
		text = "Pista molhada: pouco aprendizado no %s." % BLOCKS[id]["name"].to_lower()
	elif rng.randf() < problem_chance:
		if rng.randf() < 0.35:
			gain = 0.0
			kind = "failure"
			text = "Problema mecânico: o carro passou o bloco de %s na garagem." % BLOCKS[id]["name"].to_lower()
		else:
			gain *= 0.5
			kind = "spin"
			text = "%s rodou e perdeu parte do bloco de %s." % [car.driver["name"], BLOCKS[id]["name"].to_lower()]
	match id:
		"aero":
			setup.aero += (1.0 - setup.aero) * gain
			setup.balance += (1.0 - setup.balance) * gain * BALANCE_SHARE
		"mech":
			setup.mech += (1.0 - setup.mech) * gain
			setup.balance += (1.0 - setup.balance) * gain * BALANCE_SHARE
		"race":
			setup.race_prep += (1.0 - setup.race_prep) * gain * 1.4
		"quali":
			setup.quali_prep += (1.0 - setup.quali_prep) * gain * 1.4
	setup.race_prep = minf(setup.race_prep, 1.0)
	setup.quali_prep = minf(setup.quali_prep, 1.0)
	if text == "":
		text = "%s concluído." % BLOCKS[id]["name"]
	history.append({"car": car, "block": id, "text": text, "kind": kind})
	block_finished.emit(car, id, text)
	plan["block"] = ""
	_start_next_block(car, GARAGE_S)


# --- consultas --------------------------------------------------------------------------

## Resumo do treino de um piloto para a tela de resultado (v21): acerto antes/depois, nota A–D e o que aconteceu.
func summary_of(driver_id: String) -> Dictionary:
	var before: CarSetup = setups_before[driver_id]
	var after: CarSetup = setups[driver_id]
	var events: Array = []
	var car_ref: CarState = null
	for c in cars:
		if c.driver["id"] == driver_id:
			car_ref = c
	for h: Dictionary in history:
		if h["car"] == car_ref:
			events.append({"kind": h["kind"], "text": h["text"], "block": h["block"]})
	var ds: Array = draws[driver_id]
	var avg := 0.0
	for x: float in ds:
		avg += x
	avg = avg / ds.size() if not ds.is_empty() else 0.0
	return {"before": {"aero": before.aero, "mech": before.mech, "balance": before.balance},
		"after": {"aero": after.aero, "mech": after.mech, "balance": after.balance},
		"quality": after.quality(), "grade": CarSetup.grade(after.quality()), "draw": avg, "events": events,
		"skills": skills_of(car_ref) if car_ref != null else {}}


## Classificação do treino pela melhor volta (quem não marcou tempo fica no fim).
func standings() -> Array[CarState]:
	var list := cars.duplicate()
	list.sort_custom(func(a: CarState, b: CarState) -> bool:
		if a.best_lap_time != b.best_lap_time:
			return a.best_lap_time < b.best_lap_time
		return a.index < b.index)
	return list


## O que o carro está fazendo agora (para a tela ao vivo).
func status_of(car: CarState) -> String:
	var plan: Dictionary = _plan[car]
	if plan["block"] == "":
		return "Programa concluído" if plan["queue"].is_empty() else "Garagem"
	return BLOCKS[plan["block"]]["name"]


func time_left_s() -> float:
	return maxf(0.0, SESSION_S - time_s)


func is_over() -> bool:
	return over
