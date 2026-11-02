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


## options: seed, player_team, weather, rain_probability, incident_rate, sprint, auto_player.
func _init(p_track: TrackModel, p_tyres: TyreModel, teams: Array, drivers: Array,
		p_setups: Dictionary = {}, options: Dictionary = {}) -> void:
	track = p_track
	tyres = p_tyres
	setups = p_setups
	sprint = bool(options.get("sprint", false))
	segments = SPRINT_SEGMENTS if sprint else SEGMENTS
	auto_player = bool(options.get("auto_player", false))
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
	_begin_segment()


# --- tempo ------------------------------------------------------------------------------

func advance(seconds: float) -> void:
	var steps := int(seconds / DT)
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
					flying_time[car] = flying_lap_time(car)
					_set_phase(car, Phase.FLYING, seg_time + flying_time[car])
		Phase.FLYING:
			if seg_time >= phase_end[car]:
				_finish_flying_lap(car)
				_set_phase(car, Phase.IN_LAP, seg_time + _lap_base(car) * IN_LAP_K)
		Phase.IN_LAP:
			if seg_time >= phase_end[car]:
				_set_phase(car, Phase.GARAGE, seg_time)


func _set_phase(car: CarState, p: Phase, end_time: float) -> void:
	phase[car] = p
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
func send_out(car: CarState, compound: String) -> bool:
	if not can_go_out(car):
		return false
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
	return RaceSim.base_lap_time(track, car.team, car.driver) + weather.wetness * RaceSim.WET_TRACK_S


## Tempo da volta lançada que está começando agora (com a sorte da volta).
func flying_lap_time(car: CarState) -> float:
	var t := expected_lap_time(car, run_tyre[car]["compound"], run_tyre[car]["new"])
	t += rng.randfn(0.0, LAP_NOISE)
	var traffic := TRAFFIC_CHANCE + TRAFFIC_LATE_BONUS * clampf(seg_time / segment_length(), 0.0, 1.0)
	if rng.randf() < traffic:
		t += rng.randf_range(TRAFFIC_LOSS.x, TRAFFIC_LOSS.y)
	return t


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


func _finish_flying_lap(car: CarState) -> void:
	var t: float = flying_time[car]
	var valid := true
	var mistake := MISTAKE_BASE + (100.0 - float(car.driver["rating"])) * MISTAKE_PER_RATING
	mistake += weather.wetness * 0.08
	if rng.randf() < mistake * incident_rate:
		if rng.randf() < TRACK_LIMITS_SHARE:
			valid = false
			session_event.emit("%s: volta apagada por limite de pista." % car.code())
		else:
			t += rng.randf_range(0.6, 2.5)
			session_event.emit("%s errou e perdeu a volta." % car.code())
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


func ai_compound(car: CarState) -> String:
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


func is_red_flag() -> bool:
	return red_flag_until > seg_time


func is_over() -> bool:
	return over
