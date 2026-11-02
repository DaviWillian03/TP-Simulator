class_name PracticeSession
extends RefCounted
## Treino livre: cada piloto segue um PROGRAMA montado com blocos predefinidos (acerto aero,
## acerto mecânico, simulação de corrida, volta rápida). Cada bloco aproxima o acerto do ideal,
## com resultado aleatório (o piloto pode errar, o carro pode quebrar).
##
## "Jogar" e "simular" usam o mesmo código: jogar avança aos poucos (advance) e a tela mostra
## os tempos e os avisos; simular chama run_to_end. Com a mesma semente, o resultado é igual.

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
const GAIN_MIN := 0.35  ## cada bloco cobre de 35% a 65% do que falta para o ideal
const GAIN_MAX := 0.65
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
var over := false
var rng := RandomNumberGenerator.new()
var history: Array[Dictionary] = []  ## {car, block, text} — resumo do treino

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
	var steps := int(seconds / DT)
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


func _finish_block(car: CarState, plan: Dictionary) -> void:
	var id: String = plan["block"]
	var setup: CarSetup = setups[car.driver["id"]]
	var gain := rng.randf_range(GAIN_MIN, GAIN_MAX) * float(plan.get("block_share", 1.0)) * float(car.team.get("practice_gain_mult", 1.0))
	var text := ""
	var problem_chance := PROBLEM_BASE + (100.0 - float(car.driver["rating"])) * PROBLEM_PER_RATING
	if weather.wetness > 0.3 and id != "race":
		gain *= 0.4  # acerto de pista seca não se aprende na chuva
		text = "Pista molhada: pouco aprendizado no %s." % BLOCKS[id]["name"].to_lower()
	elif rng.randf() < problem_chance:
		if rng.randf() < 0.35:
			gain = 0.0
			text = "Problema mecânico: o carro passou o %s na garagem." % BLOCKS[id]["name"].to_lower()
		else:
			gain *= 0.5
			text = "%s rodou e perdeu parte do %s." % [car.driver["name"], BLOCKS[id]["name"].to_lower()]
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
	history.append({"car": car, "block": id, "text": text})
	block_finished.emit(car, id, text)
	plan["block"] = ""
	_start_next_block(car, GARAGE_S)


# --- consultas --------------------------------------------------------------------------

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
