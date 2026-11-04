class_name QualiSim
extends RefCounted
## Classificação em três partes (Q1/Q2/Q3, ou SQ1/SQ2/SQ3 na sprint) com eliminação.
##
## Cada saída para a pista é: volta de saída → volta lançada → volta de entrada → garagem.
## A volta lançada só vale se começar antes de o relógio zerar. O jogador escolhe o pneu e o
## momento de sair; a IA sai em duas tentativas por parte, a segunda perto do fim.
## A pista evolui (quem sai no fim ganha até ~0,3 s), mas sair tarde arrisca tráfego,
## bandeira vermelha e chuva.

signal lap_completed(car: CarState, lap_time: float, valid: bool)
signal segment_started(index: int)
signal segment_finished(index: int, eliminated: Array)
signal session_event(text: String)
signal session_finished
signal decision_needed(decision: Dictionary)  ## volta comprometida de um carro do jogador: continuar / tentar de novo / box

enum Phase { GARAGE, OUT_LAP, FLYING, IN_LAP }

const SEGMENTS := [
	{"name": "Q1", "minutes": 18.0, "advance": 16},
	{"name": "Q2", "minutes": 15.0, "advance": 10},
	{"name": "Q3", "minutes": 12.0, "advance": 0},
]
const SPRINT_SEGMENTS := [
	{"name": "SQ1", "minutes": 12.0, "advance": 16},
	{"name": "SQ2", "minutes": 10.0, "advance": 10},
	{"name": "SQ3", "minutes": 8.0, "advance": 0},
]
const DT := 0.5
const OUT_LAP_K := 1.35  ## volta de saída ~35% mais lenta (aquecer pneus, abrir espaço)
const IN_LAP_K := 1.3

## Valores PROVISÓRIOS
const EVOLUTION_S := 0.3  ## ganho da pista do começo ao fim de cada parte
const SEGMENT_EVOLUTION_S := 0.1  ## ganho extra a cada parte (pista mais emborrachada)
const NEW_SOFT_SETS := 3  ## jogos novos de macio guardados para a classificação
const USED_TYRE_WEAR := 0.15  ## pneu já usado numa volta lançada
const LAP_NOISE := 0.1
const TRAFFIC_CHANCE := 0.12
const TRAFFIC_LOSS := Vector2(0.15, 0.7)
const TRAFFIC_LATE_BONUS := 0.12  ## mais carros na pista no fim de cada parte
const MISTAKE_BASE := 0.04
const MISTAKE_PER_RATING := 0.003
const TRACK_LIMITS_SHARE := 0.4  ## parte dos erros vira volta apagada por limite de pista
const RED_FLAG_CHANCE := 0.12  ## por parte, com incidentes realistas
const RED_FLAG_PAUSE_S := 180.0
## Objetivo da volta (decidido pelo PILOTO, não pelo jogador): garantir tempo ou buscar o limite
const SAFE_TIME_S := 0.10  ## volta "garantida": um pouco mais lenta...
const SAFE_MISTAKE_K := 0.5  ## ...e com metade da chance de erro
const LIMIT_TIME_S := 0.12  ## no limite: mais rápida...
const LIMIT_MISTAKE_K := 1.8  ## ...e bem mais arriscada
const SECOND_LAP_S := 0.12  ## segunda volta rápida seguida: pneu já gasto por uma volta no limite
const DECISION_TIMEOUT_S := 25.0  ## segundos de sessão para o jogador responder ao rádio
const REVEAL_RANGE := Vector2(0.25, 0.7)  ## em que ponto da volta o problema aparece

var track: TrackModel
var tyres: TyreModel
var weather: WeatherModel
var cars: Array[CarState] = []
var setups: Dictionary = {}
var segments: Array = SEGMENTS
var segment := 0  ## parte atual (0..2)
var seg_time := 0.0  ## relógio da parte atual (segundos desde o início)
var total_time := 0.0
var over := false
var sprint := false
var auto_player := false  ## true = a IA também decide pelos carros do jogador (testes/simular)
var incident_rate := 1.0
var rng := RandomNumberGenerator.new()

var phase: Dictionary = {}  ## CarState -> Phase
var phase_end: Dictionary = {}  ## CarState -> instante (seg_time) em que a fase termina
var flying_time: Dictionary = {}  ## CarState -> tempo da volta lançada em andamento
var best: Dictionary = {}  ## CarState -> Array[float] melhor volta em cada parte (INF = sem tempo)
var best_set_at: Dictionary = {}  ## CarState -> Array[float] quando marcou (desempate)
var new_softs: Dictionary = {}  ## CarState -> jogos novos de macio restantes
var run_tyre: Dictionary = {}  ## CarState -> {compound, new}
var eliminated_in: Dictionary = {}  ## CarState -> parte em que caiu (-1 = segue)
var crashed: Dictionary = {}  ## CarState -> true se bateu (fora do resto da classificação)
var ai_plan: Dictionary = {}  ## CarState -> Array[float] instantes de saída planejados
var red_flag_at := INF
var red_flag_until := -1.0
var lap_mode: Dictionary = {}  ## CarState -> "safe" | "limit" (escolha do piloto na volta lançada atual)
var laps_left: Dictionary = {}  ## CarState -> voltas rápidas que ainda faltam nesta saída (plano de 1 ou 2)
var lap_event: Dictionary = {}  ## CarState -> {kind, loss, valid, reveal, revealed} do que vai acontecer nesta volta
var pending: Array[Dictionary] = []  ## decisões abertas para o jogador
var championship: Dictionary = {}
var tech_lap_s := 0.0  ## regulamento técnico: carros mais rápidos/lentos para todos  ## driver id -> posição no campeonato (campanha); quem briga pelo título arrisca menos
var _next_decision := 1
var phase_d0: Dictionary = {}  ## CarState -> fração da volta em que a fase começou (abortar no meio da volta)
var phase_start: Dictionary = {}  ## CarState -> instante (seg_time) em que a fase começou (para o carro andar na pista 3D)
var _acc := 0.0  ## tempo que sobrou de um quadro (a tela chama advance() com frações de segundo)


## options: seed, player_team, weather, rain_probability, incident_rate, sprint, auto_player.
func _init(p_track: TrackModel, p_tyres: TyreModel, teams: Array, drivers: Array,
		p_setups: Dictionary = {}, options: Dictionary = {}) -> void:
	track = p_track
	tyres = p_tyres
	setups = p_setups
	sprint = bool(options.get("sprint", false))
	segments = SPRINT_SEGMENTS if sprint else SEGMENTS
	auto_player = bool(options.get("auto_player", false))
	championship = options.get("championship", {})
	tech_lap_s = float(TechRules.knobs(options.get("tech", {}))["lap_s"])
	incident_rate = float(options.get("incident_rate", 1.0))
	rng.seed = int(options.get("seed", 1))
	var total := 0.0
	for s: Dictionary in segments:
		total += s["minutes"] * 60.0
	var rain_p := float(options.get("rain_probability", track.rain_probability))
	weather = WeatherModel.new(rain_p, total, rng, options)
	weather.rubber = 0.5  # pista já emborrachada pelos treinos
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
		phase[car] = Phase.GARAGE
		phase_end[car] = 0.0
		best[car] = [INF, INF, INF]
		best_set_at[car] = [INF, INF, INF]
		new_softs[car] = NEW_SOFT_SETS
		eliminated_in[car] = -1
	_set_cuts(cars.size())
	_begin_segment()


## Cortes por número de carros: 10 chegam ao Q3 e o resto é dividido entre Q1 e Q2
## (22 carros: 6 + 6 — regra 2026; 24 carros com a equipe criada: 7 + 7).
func _set_cuts(n: int) -> void:
	var out := maxi(1, floori((n - 10) / 2.0))
	segments = segments.duplicate(true)
	segments[0]["advance"] = n - out
	segments[1]["advance"] = 10


# --- tempo ------------------------------------------------------------------------------

func advance(seconds: float) -> void:
	# acumula o resto: a 60 fps e 4× cada quadro traz só ~0,07 s, menos que um passo (DT = 0,5 s);
	# sem isso o relógio nunca andava na tela e só dava para "simular"
	_acc += seconds
	var steps := int(_acc / DT)
	_acc -= steps * DT
	for i in steps:
		if over:
			return
		step()


func run_to_end(max_steps: int = 100_000) -> void:
	var n := 0
	while not over and n < max_steps:
		step()
		n += 1


func step() -> void:
	if over:
		return
	if red_flag_until > seg_time:
		# bandeira vermelha: relógio parado, todos na garagem
		red_flag_until -= DT
		weather.step(DT)
		return
	seg_time += DT
	total_time += DT
	weather.step(DT)
	if seg_time >= red_flag_at:
		_red_flag()
	for car in active_cars():
		_update_car(car)
	for d in pending.duplicate():  # sem resposta no prazo: o piloto decide
		if seg_time >= float(d["until"]) or phase.get(d["car"], Phase.GARAGE) != Phase.FLYING:
			pending.erase(d)
			_apply_choice(d["car"], _ai_choice(d["car"]))
	if seg_time >= segment_length() and _nobody_on_valid_lap():
		_end_segment()


func _update_car(car: CarState) -> void:
	match phase[car]:
		Phase.GARAGE:
			if (auto_player or not car.is_player) and _ai_wants_to_go(car):
				send_out(car, ai_compound(car))
		Phase.OUT_LAP:
			if seg_time >= phase_end[car]:
				if phase_end[car] > segment_length():
					# o relógio zerou antes de começar a volta lançada: volta para a garagem
					_set_phase(car, Phase.IN_LAP, seg_time + _lap_base(car) * IN_LAP_K * 0.5)
					session_event.emit("%s não abriu a volta a tempo." % car.code())
				else:
					_start_flying(car, false)
		Phase.FLYING:
			_check_reveal(car)
			if seg_time >= phase_end[car]:
				_finish_flying_lap(car)
				laps_left[car] = int(laps_left.get(car, 1)) - 1
				if int(laps_left[car]) > 0 and seg_time < segment_length() and not crashed.has(car):
					_start_flying(car, true)  # plano de 2 voltas: emenda a segunda sem volta de saída
				else:
					_set_phase(car, Phase.IN_LAP, seg_time + _lap_base(car) * IN_LAP_K)
		Phase.IN_LAP:
			if seg_time >= phase_end[car]:
				_set_phase(car, Phase.GARAGE, seg_time)


func _set_phase(car: CarState, p: Phase, end_time: float, from_frac: float = 0.0) -> void:
	phase[car] = p
	phase_start[car] = seg_time
	phase_d0[car] = from_frac
	phase_end[car] = end_time


func _nobody_on_valid_lap() -> bool:
	for car in active_cars():
		if phase[car] == Phase.FLYING:
			return false
		if phase[car] == Phase.OUT_LAP and phase_end[car] <= segment_length() + DT:
			return false
	return true


# --- ordens -----------------------------------------------------------------------------

## Manda o carro para a pista com o pneu escolhido. Só funciona com o carro na garagem,
## na parte em que ele ainda está classificado e com o relógio rodando.
func send_out(car: CarState, compound: String, laps: int = 1) -> bool:
	if not can_go_out(car):
		return false
	laps_left[car] = clampi(laps, 1, 2)
	var fresh := false
	if compound == "soft" and new_softs[car] > 0:
		new_softs[car] -= 1
		fresh = true
	elif compound != "soft":
		fresh = true  # médios/duros/chuva: há jogos novos de sobra para a classificação
	run_tyre[car] = {"compound": compound, "new": fresh}
	car.tyre = compound
	_set_phase(car, Phase.OUT_LAP, seg_time + _lap_base(car) * OUT_LAP_K)
	return true


func can_go_out(car: CarState) -> bool:
	return not over and phase[car] == Phase.GARAGE and eliminated_in[car] < 0 \
		and not crashed.has(car) and seg_time < segment_length() and red_flag_until <= seg_time


# --- tempo de volta ---------------------------------------------------------------------

func _lap_base(car: CarState) -> float:
	# classificação: o atributo "quali" troca o ritmo de corrida na volta lançada
	var quali_gain := (DriverStats.attr(car.driver, "quali") - DriverStats.attr(car.driver, "pace")) * DriverStats.QUALI_K
	var wet_skill := 1.0 + (80.0 - DriverStats.attr(car.driver, "wet")) * DriverStats.WET_K
	return RaceSim.base_lap_time(track, car.team, car.driver) + tech_lap_s - quali_gain + weather.wetness * RaceSim.WET_TRACK_S * clampf(wet_skill, 0.7, 1.4)


## Volta esperada sem sorte (a tela usa para mostrar o efeito da evolução da pista).
func expected_lap_time(car: CarState, compound: String, fresh: bool) -> float:
	var setup: CarSetup = setups[car.driver["id"]]
	var t := _lap_base(car) + setup.lap_penalty_s() - setup.quali_bonus_s()
	t += tyres.pace_penalty(compound, 0.0 if fresh else USED_TYRE_WEAR)
	t += tyres.wet_penalty(compound, weather.wetness)
	t -= track_evolution_s()
	return t


## Quanto a pista já melhorou nesta parte (s/volta).
func track_evolution_s() -> float:
	return EVOLUTION_S * clampf(seg_time / segment_length(), 0.0, 1.0) + SEGMENT_EVOLUTION_S * segment


## Começa uma volta lançada: o piloto escolhe o objetivo, e o que vai dar errado (se der) é sorteado agora e
## revelado no meio da volta (aí dá para abortar). repeat = segunda volta seguida ou nova tentativa.
func _start_flying(car: CarState, repeat: bool) -> void:
	lap_mode[car] = choose_lap_mode(car)
	var t := expected_lap_time(car, run_tyre[car]["compound"], run_tyre[car]["new"] and not repeat)
	t += rng.randfn(0.0, LAP_NOISE)
	t += SECOND_LAP_S if repeat else 0.0
	t += -LIMIT_TIME_S if lap_mode[car] == "limit" else SAFE_TIME_S
	var ev := {}
	var traffic := TRAFFIC_CHANCE + TRAFFIC_LATE_BONUS * clampf(seg_time / segment_length(), 0.0, 1.0)
	if rng.randf() < traffic:
		ev = {"kind": "traffic", "loss": rng.randf_range(TRAFFIC_LOSS.x, TRAFFIC_LOSS.y), "valid": true}
	var mistake := MISTAKE_BASE + (100.0 - DriverStats.attr(car.driver, "consistency")) * MISTAKE_PER_RATING
	mistake += weather.wetness * 0.08
	mistake *= LIMIT_MISTAKE_K if lap_mode[car] == "limit" else SAFE_MISTAKE_K
	if rng.randf() < mistake * incident_rate:
		if rng.randf() < TRACK_LIMITS_SHARE:
			ev = {"kind": "limits", "loss": 0.0, "valid": false}
		else:
			ev = {"kind": "mistake", "loss": rng.randf_range(0.6, 2.5), "valid": true}
	if not ev.is_empty():
		ev["reveal"] = rng.randf_range(REVEAL_RANGE.x, REVEAL_RANGE.y)
		ev["revealed"] = false
		t += float(ev["loss"])
	lap_event[car] = ev
	flying_time[car] = t
	_set_phase(car, Phase.FLYING, seg_time + t)


## Objetivo da volta, escolhido pelo piloto: a situação diz o que seria certo (garantir um tempo cedo,
## arriscar na última chance ou na briga pela pole; quem disputa o título evita riscos à toa) e a "leitura de
## corrida" (regularidade + ultrapassagem/defesa) diz quantas vezes ele acerta essa escolha.
func choose_lap_mode(car: CarState) -> String:
	var order := segment_order()
	var pos := order.find(car)
	var adv: int = segments[segment]["advance"]
	var has_time: bool = best[car][segment] < INF
	var in_danger := not has_time or (adv > 0 and pos >= adv - 2)
	var pole_fight := adv == 0 and pos <= 3
	var last_chance := time_left_s() < _lap_base(car) * (OUT_LAP_K + 2.0) + 20.0  # não dá para outra saída depois
	var right := "limit" if pole_fight or (in_danger and last_chance) else "safe"
	if right == "limit" and not pole_fight and int(championship.get(car.driver["id"], 99)) <= 3 and has_time and pos < adv:
		right = "safe"  # briga pelo título: não arrisca perder a classificação por um décimo
	var iq := (DriverStats.attr(car.driver, "consistency") + DriverStats.attr(car.driver, "racecraft")) / 2.0
	var p_right := clampf(0.55 + (iq - 70.0) * 0.015, 0.55, 0.95)
	if rng.randf() > p_right:
		return "safe" if right == "limit" else "limit"
	return right


func lap_mode_label(car: CarState) -> String:
	return "buscando o limite" if lap_mode.get(car, "safe") == "limit" else "garantindo tempo"


## No meio da volta aparece o problema sorteado no início: o jogador decide (rádio) ou a IA decide sozinha.
func _check_reveal(car: CarState) -> void:
	var ev: Dictionary = lap_event.get(car, {})
	if ev.is_empty() or bool(ev["revealed"]):
		return
	var span := maxf(float(phase_end[car]) - float(phase_start[car]), 0.001)
	if (seg_time - float(phase_start[car])) / span < float(ev["reveal"]):
		return
	ev["revealed"] = true
	var text: String = {"traffic": "Pegou tráfego e perdeu %.1f s" % float(ev["loss"]), "mistake": "Errou e perdeu %.1f s" % float(ev["loss"]),
		"limits": "Passou do limite da pista: esta volta vai ser apagada"}[ev["kind"]]
	if car.is_player and not auto_player:
		var d := {"id": _next_decision, "car": car, "kind": "question", "text": text + ". E agora?",
			"options": [{"label": "Continuar"}, {"label": "Abortar e tentar de novo"}, {"label": "Voltar ao box"}],
			"until": seg_time + DECISION_TIMEOUT_S, "deadline_text": "Sem resposta, o piloto decide sozinho"}
		_next_decision += 1
		pending.append(d)
		decision_needed.emit(d)
	else:
		_apply_choice(car, _ai_choice(car))


## O que a IA (ou o piloto sem resposta) faz: continua se a perda é pequena; senão tenta de novo se ainda há
## tempo, ou desiste para o box.
func _ai_choice(car: CarState) -> int:
	var ev: Dictionary = lap_event.get(car, {})
	if ev.is_empty():
		return 0
	var bad := not bool(ev["valid"]) or float(ev["loss"]) > 0.35
	if not bad:
		return 0
	return 1 if _can_retry(car) else (2 if not bool(ev["valid"]) else 0)


## Dá tempo de completar esta volta devagar e começar outra antes do relógio zerar?
func _can_retry(car: CarState) -> bool:
	var rem := 1.0 - _lap_progress(car)
	return seg_time + rem * _lap_base(car) * OUT_LAP_K < segment_length()


func _lap_progress(car: CarState) -> float:
	var span := maxf(float(phase_end[car]) - float(phase_start[car]), 0.001)
	var p := clampf((seg_time - float(phase_start[car])) / span, 0.0, 1.0)
	return float(phase_d0.get(car, 0.0)) + p * (1.0 - float(phase_d0.get(car, 0.0)))


func pending_for(car: CarState) -> Dictionary:
	for d in pending:
		if d["car"] == car:
			return d
	return {}


## Resposta do jogador: 0 = continuar, 1 = abortar e tentar de novo, 2 = voltar ao box.
func answer(decision_id: int, option: int) -> void:
	for d in pending.duplicate():
		if int(d["id"]) == decision_id:
			pending.erase(d)
			_apply_choice(d["car"], option)


func _apply_choice(car: CarState, option: int) -> void:
	if phase.get(car, Phase.GARAGE) != Phase.FLYING:
		return
	var from := _lap_progress(car)
	var rem := 1.0 - from
	match option:
		1:
			if not _can_retry(car):
				option = 2
			else:  # volta lenta até a linha e outra tentativa (pneu já usado)
				run_tyre[car]["new"] = false
				laps_left[car] = maxi(int(laps_left.get(car, 1)), 1)
				lap_event[car] = {}
				_set_phase(car, Phase.OUT_LAP, seg_time + rem * _lap_base(car) * OUT_LAP_K, from)
				session_event.emit("%s aborta a volta e prepara outra tentativa." % car.code())
				return
	if option == 2:
		lap_event[car] = {}
		laps_left[car] = 0
		_set_phase(car, Phase.IN_LAP, seg_time + rem * _lap_base(car) * IN_LAP_K, from)
		session_event.emit("%s desiste da volta e volta ao box." % car.code())


func _finish_flying_lap(car: CarState) -> void:
	var t: float = flying_time[car]
	var ev: Dictionary = lap_event.get(car, {})
	var valid: bool = ev.get("valid", true)
	if not ev.is_empty():
		match ev["kind"]:
			"limits":
				session_event.emit("%s: volta apagada por limite de pista." % car.code())
			"mistake":
				session_event.emit("%s errou e perdeu a volta." % car.code())
	lap_event[car] = {}
	car.last_lap_time = t
	car.lap_times.append(t)
	if valid and t < best[car][segment]:
		best[car][segment] = t
		best_set_at[car][segment] = total_time
	if valid and t < car.best_lap_time:
		car.best_lap_time = t
	lap_completed.emit(car, t, valid)


func _red_flag() -> void:
	red_flag_at = INF
	var running: Array[CarState] = []
	for car in active_cars():
		if phase[car] == Phase.FLYING:
			running.append(car)
	if running.is_empty():
		return
	var culprit: CarState = running[rng.randi() % running.size()]
	crashed[culprit] = true
	culprit.retire_reason = "batida na classificação"
	for car in active_cars():
		if phase[car] != Phase.GARAGE:
			_set_phase(car, Phase.GARAGE, seg_time)  # volta abortada, pneu gasto
	red_flag_until = seg_time + RED_FLAG_PAUSE_S
	pending.clear()
	session_event.emit("Bandeira vermelha: %s bateu. Voltas abortadas." % culprit.display_name())
	_plan_ai_runs(true)


# --- IA ---------------------------------------------------------------------------------

func _plan_ai_runs(after_red_flag: bool = false) -> void:
	var length := segment_length()
	for car in active_cars():
		var run_s := _lap_base(car) * (OUT_LAP_K + 1.0) + 20.0
		var last_start := length - run_s + _lap_base(car) * 1.0 - rng.randf_range(15.0, 70.0)
		if after_red_flag:
			# depois da vermelha: uma última tentativa para quem ainda tem tempo
			ai_plan[car] = [maxf(seg_time + rng.randf_range(5.0, 40.0), minf(last_start, length - run_s * 0.6))]
		else:
			ai_plan[car] = [rng.randf_range(0.06, 0.35) * length, last_start]


func _ai_wants_to_go(car: CarState) -> bool:
	var plan: Array = ai_plan.get(car, [])
	if plan.is_empty() or seg_time < plan[0]:
		return false
	plan.pop_front()
	return true


func ai_compound(_car: CarState) -> String:
	if weather.wetness >= 0.2:
		return tyres.best_for_wetness(weather.wetness, ["inter", "wet"])
	return "soft"


# --- partes -----------------------------------------------------------------------------

func _begin_segment() -> void:
	seg_time = 0.0
	red_flag_until = -1.0
	red_flag_at = INF
	if rng.randf() < RED_FLAG_CHANCE * incident_rate:
		red_flag_at = rng.randf_range(0.3, 0.9) * segment_length()
	for car in cars:
		if phase.has(car):
			_set_phase(car, Phase.GARAGE, 0.0)
	_plan_ai_runs()
	segment_started.emit(segment)


func _end_segment() -> void:
	var order := segment_order()
	var adv: int = segments[segment]["advance"]
	var out: Array[CarState] = []
	if adv > 0:
		for i in range(adv, order.size()):
			eliminated_in[order[i]] = segment
			out.append(order[i])
	segment_finished.emit(segment, out)
	if segment >= segments.size() - 1:
		over = true
		session_finished.emit()
		return
	segment += 1
	_begin_segment()


## Carros que ainda disputam a parte atual.
func active_cars() -> Array[CarState]:
	var list: Array[CarState] = []
	for car in cars:
		if eliminated_in[car] < 0:
			list.append(car)
	return list


## Ordem da parte atual: melhor volta nesta parte; desempate por quem marcou primeiro.
func segment_order() -> Array[CarState]:
	var list := active_cars()
	var s := segment
	list.sort_custom(func(a: CarState, b: CarState) -> bool:
		if best[a][s] != best[b][s]:
			return best[a][s] < best[b][s]
		if best_set_at[a][s] != best_set_at[b][s]:
			return best_set_at[a][s] < best_set_at[b][s]
		return a.index < b.index)
	return list


## Classificação para a tela: quem segue na parte atual, depois os eliminados (Q2, depois Q1).
func standings() -> Array[CarState]:
	var list := segment_order()
	for s in range(segment - 1, -1, -1):
		var out: Array[CarState] = []
		for car in cars:
			if eliminated_in[car] == s:
				out.append(car)
		out.sort_custom(func(a: CarState, b: CarState) -> bool:
			if best[a][s] != best[b][s]:
				return best[a][s] < best[b][s]
			return a.index < b.index)
		list.append_array(out)
	return list


## Grid de largada (ids dos pilotos) depois do fim da classificação.
func grid_ids() -> Array[String]:
	var ids: Array[String] = []
	for car in standings():
		ids.append(car.driver["id"])
	return ids


func segment_length() -> float:
	return float(segments[segment]["minutes"]) * 60.0


func segment_name() -> String:
	return segments[segment]["name"]


func time_left_s() -> float:
	return maxf(0.0, segment_length() - seg_time)


func best_in_segment(car: CarState) -> float:
	return best[car][segment] if eliminated_in[car] < 0 else best[car][eliminated_in[car]]


func status_of(car: CarState) -> String:
	if eliminated_in[car] >= 0:
		return "Eliminado no %s" % segments[eliminated_in[car]]["name"]
	if crashed.has(car):
		return "Bateu"
	match phase[car]:
		Phase.OUT_LAP:
			return "Volta de saída"
		Phase.FLYING:
			return "Volta lançada"
		Phase.IN_LAP:
			return "Volta de entrada"
	return "Garagem"


## Distância percorrida na volta da fase atual (saída, lançada ou entrada), para desenhar o carro na
## pista. Interpola com o tempo que sobrou do último passo (`_acc`), então o movimento é suave.
func render_distance(car: CarState) -> float:
	if phase[car] == Phase.GARAGE:
		return 0.0
	var start: float = phase_start.get(car, 0.0)
	var span := maxf(float(phase_end[car]) - start, 0.001)
	var d0: float = phase_d0.get(car, 0.0)
	return (d0 + clampf((seg_time + _acc - start) / span, 0.0, 1.0) * (1.0 - d0)) * track.length_m


## O carro aparece na pista (na garagem, batido ou eliminado ele some).
func marker_visible(car: CarState) -> bool:
	return phase[car] != Phase.GARAGE and not crashed.has(car)


func is_red_flag() -> bool:
	return red_flag_until > seg_time


func is_over() -> bool:
	return over
