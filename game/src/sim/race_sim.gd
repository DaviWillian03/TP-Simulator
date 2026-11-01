class_name RaceSim
extends RefCounted
## Simulação de uma corrida, separada da tela.
##
## Avança em passos fixos de tempo (DT). Com a mesma semente aleatória, a corrida se
## repete igual — isso permite testar as regras com GUT e acelerar o tempo sem mudar o
## resultado. A tela só lê o estado (posições, pneus) e envia ordens do jogador.

signal overtake(attacker: CarState, defender: CarState, zone_name: String)
signal pit_stop(car: CarState, compound: String, stationary_s: float)
signal fastest_lap(car: CarState, lap_time: float)
signal tyre_warning(car: CarState)
signal car_finished(car: CarState, position: int)
signal race_finished

const DT := 0.1  ## segundos de corrida por passo
const GRID_SPACING_M := 10.0
const MIN_GAP_M := 9.0  ## sem ultrapassar, um carro não chega mais perto que isso do da frente
const ATTACK_WINDOW_S := 1.0  ## a menos de 1 s do carro da frente: pode tentar ultrapassar
const DIRTY_AIR_S := 0.3  ## perda máxima por volta andando colado (ar turbulento)
const STRATEGY_FRAC := 0.85  ## ponto da volta onde a IA decide se para no box
const MODE_UPDATE_S := 2.0
const TRACE_STEP_M := 5.0

## Escalas de desempenho (PROVISÓRIAS até a definição dos atributos)
const CAR_K := 0.07  ## s/volta por ponto de nota do carro abaixo de 100
const DRIVER_K := 0.035  ## s/volta por ponto de nota do piloto abaixo de 100
const FUEL_START_S := 3.0  ## carro cheio de combustível é ~3 s/volta mais lento
const LAP_NOISE_SIGMA := 0.12
const PACE_TIME := {CarState.PaceMode.CONSERVE: 0.45, CarState.PaceMode.NORMAL: 0.0, CarState.PaceMode.ATTACK: -0.35}
const PACE_WEAR := {CarState.PaceMode.CONSERVE: 0.7, CarState.PaceMode.NORMAL: 1.0, CarState.PaceMode.ATTACK: 1.35}
const ENERGY_TIME := {CarState.EnergyMode.HARVEST: 0.3, CarState.EnergyMode.BALANCED: 0.0, CarState.EnergyMode.DEPLOY: -0.3}
const ENERGY_SOC := {CarState.EnergyMode.HARVEST: 0.12, CarState.EnergyMode.BALANCED: 0.0, CarState.EnergyMode.DEPLOY: -0.15}
const OVERTAKE_MODE_BONUS_S := 0.25  ## energia extra para quem ataca a menos de 1 s (regra 2026)
const OVERTAKE_MODE_COST := 0.05
const OVERTAKE_SCALE := 0.2  ## quão "suave" é a curva de chance em torno da vantagem exigida
const OVERTAKE_BASE_REQUIRED_S := 0.45  ## vantagem mínima mesmo na pista mais fácil
const OVERTAKE_DIFFICULTY_S := 1.5  ## vantagem extra exigida por ponto de dificuldade da pista
const OVERTAKE_MAX_CHANCE := 0.5

var track: TrackModel
var tyres: TyreModel
var cars: Array[CarState] = []
var total_laps := 0
var duration_pct := 1.0
var time_s := 0.0
var chequered := false
var over := false
var fastest_lap_time := INF
var fastest_lap_car: CarState = null
var overtakes_count := 0
var rng := RandomNumberGenerator.new()

var _accum := 0.0
var _mode_timer := 0.0
var _finish_count := 0
var _trace_dist := PackedFloat64Array()  # maior distância já alcançada por alguém...
var _trace_time := PackedFloat64Array()  # ...e o instante em que foi alcançada (para os intervalos)
var _warned: Dictionary = {}


## options: duration_pct (0.25/0.5/1.0), seed (int), player_team (String)
func _init(p_track: TrackModel, p_tyres: TyreModel, teams: Array, drivers: Array, options: Dictionary = {}) -> void:
	track = p_track
	tyres = p_tyres
	duration_pct = float(options.get("duration_pct", 1.0))
	total_laps = maxi(3, roundi(track.laps * duration_pct))
	rng.seed = int(options.get("seed", 1))
	var player_team: String = options.get("player_team", "")
	for d: Dictionary in drivers:
		var car := CarState.new()
		car.index = cars.size()
		car.driver = d
		car.team = GameData.team_by_id(teams, d["team"])
		car.is_player = car.team["id"] == player_team
		cars.append(car)
	_setup_grid()


# --- largada -------------------------------------------------------------------------

func _setup_grid() -> void:
	# Classificação simulada: ritmo puro + um pouco de sorte.
	var scored: Array = []
	for car in cars:
		scored.append([_ideal_lap_time(car) + rng.randfn(0.0, 0.15), car])
	scored.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for i in scored.size():
		var car: CarState = scored[i][1]
		car.grid_position = i
		car.distance = -GRID_SPACING_M * i - 5.0
		car.tyre = StrategyAI.choose_start_compound(i, rng)
		car.compounds_used = [car.tyre]
		car.pit_compound = "hard" if car.tyre != "hard" else "medium"
		car.ai_pit_wear = rng.randf_range(0.66, 0.76)
		car.lap_noise = rng.randfn(0.0, LAP_NOISE_SIGMA)


# --- consultas usadas pela tela e pela IA ---------------------------------------------

func race_distance() -> float:
	return total_laps * track.length_m


func wear_multiplier() -> float:
	# corridas mais curtas desgastam proporcionalmente mais, para manter as paradas
	return track.tyre_wear_factor / duration_pct


func frac_of(car: CarState) -> float:
	return fposmod(car.distance, track.length_m) / track.length_m


## Distância "visual" com interpolação entre passos da simulação (movimento suave).
func render_distance(car: CarState) -> float:
	if car.finished:
		return car.distance
	return car.distance + car.speed * _accum


func leader_lap() -> int:
	var best := 0
	for car in cars:
		best = maxi(best, car.laps_done)
	return mini(best + 1, total_laps)


## Classificação atual: voltas completas, depois quem terminou antes, depois a distância.
func standings() -> Array[CarState]:
	var list := cars.duplicate()
	list.sort_custom(_compare_position)
	return list


func _compare_position(a: CarState, b: CarState) -> bool:
	if a.disqualified != b.disqualified:
		return b.disqualified
	if a.laps_done != b.laps_done:
		return a.laps_done > b.laps_done
	if a.finished != b.finished:
		return a.finished
	if a.finished:
		return a.finish_time < b.finish_time
	return a.distance > b.distance


## Diferença para o líder em segundos.
## Em andamento: há quanto tempo o líder passou pelo ponto onde o carro está.
## Depois da chegada: diferença entre os tempos de chegada.
func gap_to_leader_s(car: CarState) -> float:
	var lead := leader()
	if car == lead:
		return 0.0
	if car.finished and lead.finished:
		return maxf(0.0, car.finish_time - lead.finish_time)
	var d := minf(car.distance, race_distance())
	if d <= 0.0 or _trace_dist.is_empty():
		return 0.0
	return maxf(0.0, time_s - _time_at_distance(d))


## Segundos até o carro imediatamente à frente na mesma faixa (-1 se não houver).
## Calculado uma vez por passo em _update_gaps.
func gap_to_car_ahead_s(car: CarState) -> float:
	return car.gap_ahead_s


func leader() -> CarState:
	return standings()[0]


func laps_behind_leader(car: CarState) -> int:
	var lead := leader()
	if car.finished:
		return lead.laps_done - car.laps_done
	return floori((lead.distance - car.distance) / track.length_m)


func is_over() -> bool:
	return over


## Vida restante (em voltas) do pneu atual até o início do penhasco.
func tyre_laps_left(car: CarState) -> float:
	var c: Dictionary = tyres.compounds[car.tyre]
	var per_lap := tyres.wear_per_lap(car.tyre) * wear_multiplier()
	return maxf(0.0, (float(c["cliff_start"]) - car.tyre_wear) / per_lap)


# --- ordens do jogador ---------------------------------------------------------------

func request_pit(car: CarState, compound: String) -> void:
	if car.finished or car.in_pit:
		return
	car.pit_compound = compound
	car.pit_requested = true


func cancel_pit(car: CarState) -> void:
	if not car.in_pit:
		car.pit_requested = false


func set_pace_mode(car: CarState, mode: CarState.PaceMode) -> void:
	car.pace_mode = mode


func set_energy_mode(car: CarState, mode: CarState.EnergyMode) -> void:
	car.energy_mode = mode


# --- avanço do tempo -----------------------------------------------------------------

## Avança a corrida pelo tempo dado (já multiplicado pela velocidade 1×/2×/4×/8×).
func advance(seconds: float) -> void:
	_accum += seconds
	while _accum >= DT and not over:
		_accum -= DT
		step()


## Roda a corrida inteira de uma vez (testes e simulação automática).
func run_to_end(max_steps: int = 2_000_000) -> void:
	var n := 0
	while not over and n < max_steps:
		step()
		n += 1


func step() -> void:
	time_s += DT
	_mode_timer -= DT
	if _mode_timer <= 0.0:
		_mode_timer = MODE_UPDATE_S
		for car in cars:
			if not car.is_player and not car.finished:
				StrategyAI.update_modes(self, car)

	var order := _running_order()
	_update_gaps(order)
	for car in order:
		car.speed = car.pit_speed if car.in_pit else track.length_m / _lap_time(car, true)

	_resolve_overtakes(order)
	order = _running_order()

	for i in order.size():
		var car: CarState = order[i]
		var prev := car.distance
		var target := prev + car.speed * DT
		if not car.in_pit:
			var ahead := _same_lane_ahead(order, i)
			if ahead != null:
				target = minf(target, ahead.distance - MIN_GAP_M)
		target = maxf(target, prev)  # nunca anda para trás
		car.distance = target
		_after_move(car, prev, target)

	_update_trace()
	if chequered and _all_finished():
		over = true
		race_finished.emit()


# --- modelo de ritmo -----------------------------------------------------------------

## Tempo de volta ideal (sem tráfego, sem aleatoriedade, pneu macio novo, sem combustível).
func _ideal_lap_time(car: CarState) -> float:
	return track.base_lap_time_s \
		+ (100.0 - float(car.team["car_rating"])) * CAR_K \
		+ (100.0 - float(car.driver["rating"])) * DRIVER_K


## Tempo de volta no estado atual. with_traffic inclui ruído e ar turbulento.
func _lap_time(car: CarState, with_traffic: bool) -> float:
	var t := _ideal_lap_time(car)
	t += tyres.pace_penalty(car.tyre, car.tyre_wear)
	t += FUEL_START_S * (1.0 - clampf(car.distance / race_distance(), 0.0, 1.0))
	t += PACE_TIME[car.pace_mode]
	if car.energy_mode != CarState.EnergyMode.DEPLOY or car.battery > 0.0:
		t += ENERGY_TIME[car.energy_mode]
	if with_traffic:
		t += car.lap_noise
		var gap := gap_to_car_ahead_s(car)
		if gap >= 0.0 and gap < ATTACK_WINDOW_S:
			t += DIRTY_AIR_S * (1.0 - gap / ATTACK_WINDOW_S)
	return t


# --- ultrapassagens ------------------------------------------------------------------

func _resolve_overtakes(order: Array[CarState]) -> void:
	for i in range(1, order.size()):
		var att: CarState = order[i]
		if att.in_pit:
			continue
		var def := _same_lane_ahead(order, i)
		if def == null:
			continue
		var gap_m := def.distance - att.distance
		if gap_m > att.speed * ATTACK_WINDOW_S:
			continue
		var next_d := att.distance + att.speed * DT
		for zone: Dictionary in track.overtaking_zones:
			if _crossed(att.distance, next_d, float(zone["braking_frac"])):
				if _try_overtake(att, def, zone):
					var def_d := def.distance
					def.distance = att.distance
					att.distance = def_d
					def.distance -= def.speed * 0.25  # quem é ultrapassado perde um pouco de tempo
					overtakes_count += 1
					overtake.emit(att, def, zone["name"])
				break


func _try_overtake(att: CarState, def: CarState, zone: Dictionary) -> bool:
	var advantage := _lap_time(def, false) - _lap_time(att, false)  # > 0: atacante mais rápido
	if att.battery > 0.1:
		advantage += OVERTAKE_MODE_BONUS_S
		att.battery = maxf(0.0, att.battery - OVERTAKE_MODE_COST)
	# Ex.: Interlagos (0,35) exige ~1,0 s/volta de vantagem para a chance chegar à metade do máximo;
	# uma pista tipo Mônaco (0,95) exige ~1,9 s.
	var required := OVERTAKE_BASE_REQUIRED_S + track.overtaking_difficulty * OVERTAKE_DIFFICULTY_S
	var p := float(zone["strength"]) / (1.0 + exp(-(advantage - required) / OVERTAKE_SCALE))
	return rng.randf() < clampf(p, 0.0, OVERTAKE_MAX_CHANCE)


# --- eventos de volta, box e chegada -------------------------------------------------

func _after_move(car: CarState, prev: float, now: float) -> void:
	var moved := now - prev
	if moved <= 0.0:
		return
	var lap_part := moved / track.length_m
	car.tyre_wear += tyres.wear_per_lap(car.tyre) * wear_multiplier() * PACE_WEAR[car.pace_mode] * lap_part
	car.battery = clampf(car.battery + ENERGY_SOC[car.energy_mode] * lap_part, 0.0, 1.0)

	if not car.is_player and _crossed(prev, now, STRATEGY_FRAC):
		StrategyAI.decide_pit(self, car)

	if car.is_player and car.tyre_wear >= 0.7 and not _warned.get(car.index, false):
		_warned[car.index] = true
		tyre_warning.emit(car)

	if car.pit_requested and not car.in_pit and _crossed(prev, now, track.pit_entry_frac):
		var on_last_lap := car.laps_done + 1 >= total_laps
		if not chequered and not on_last_lap:
			_enter_pit(car)

	# volta completa (cruzou a linha em k * comprimento, k >= 1)
	var lap_before := floori(prev / track.length_m)
	var lap_after := floori(now / track.length_m)
	if now > 0.0 and lap_after > lap_before and lap_after >= 1:
		# instante exato em que cruzou a linha, interpolado dentro do passo
		var line_d := lap_after * track.length_m
		var cross_time := time_s - DT + DT * (line_d - prev) / moved
		_complete_lap(car, lap_after, cross_time)
		if car.finished:
			return

	if car.in_pit and not car.pit_service_done and _crossed(prev, now, track.pit_box_frac):
		_change_tyres(car)
	elif car.in_pit and car.pit_service_done and _crossed(prev, now, track.pit_exit_frac):
		car.in_pit = false
		car.pit_requested = false


func _enter_pit(car: CarState) -> void:
	car.in_pit = true
	car.pit_service_done = false
	var stationary := 2.4 + absf(rng.randfn(0.0, 0.3))
	if rng.randf() < 0.05:
		stationary += rng.randf_range(2.0, 5.0)  # parada lenta
	car.pit_stationary_s = stationary
	var normal_speed := track.length_m / _lap_time(car, false)
	var lane := track.pit_lane_length_m()
	var lane_time := lane / normal_speed + track.pit_lane_loss_s + (stationary - 2.4)
	car.pit_speed = lane / lane_time


func _change_tyres(car: CarState) -> void:
	car.tyre = car.pit_compound
	car.tyre_wear = 0.0
	car.tyre_laps = 0
	if not car.compounds_used.has(car.tyre):
		car.compounds_used.append(car.tyre)
	car.pit_stops += 1
	car.pit_service_done = true
	_warned.erase(car.index)
	pit_stop.emit(car, car.tyre, car.pit_stationary_s)


func _complete_lap(car: CarState, lap_number: int, cross_time: float) -> void:
	car.laps_done = lap_number
	car.last_lap_time = cross_time - car.lap_start_time
	car.lap_start_time = cross_time
	car.tyre_laps += 1
	car.lap_noise = rng.randfn(0.0, LAP_NOISE_SIGMA)
	if lap_number > 1:  # a 1ª volta inclui a largada parada
		car.best_lap_time = minf(car.best_lap_time, car.last_lap_time)
		if car.last_lap_time < fastest_lap_time:
			fastest_lap_time = car.last_lap_time
			fastest_lap_car = car
			fastest_lap.emit(car, car.last_lap_time)
	if not chequered and lap_number >= total_laps:
		chequered = true
	if chequered:
		_finish(car, cross_time)


func _finish(car: CarState, cross_time: float) -> void:
	car.finished = true
	car.finish_time = cross_time
	car.in_pit = false
	car.speed = 0.0
	if not tyres.rule_satisfied(car.compounds_used):
		car.disqualified = true  # regra dos 2 compostos não cumprida
	_finish_count += 1
	car_finished.emit(car, _finish_count)


# --- utilidades ----------------------------------------------------------------------

## O carro passou pelo ponto "frac" da volta entre as distâncias a e b?
func _crossed(a: float, b: float, frac: float) -> bool:
	var offset := frac * track.length_m
	return floorf((b - offset) / track.length_m) > floorf((a - offset) / track.length_m)


func _running_order() -> Array[CarState]:
	var list: Array[CarState] = []
	for car in cars:
		if not car.finished:
			list.append(car)
	list.sort_custom(func(a: CarState, b: CarState) -> bool: return a.distance > b.distance)
	return list


## Carro mais próximo à frente (em distância total) que está na mesma faixa (pista ou box).
## Carros com uma volta a mais ficam longe em distância total: é a "bandeira azul" implícita.
func _same_lane_ahead(order: Array[CarState], i: int) -> CarState:
	var car := order[i]
	for j in range(i - 1, -1, -1):
		var other := order[j]
		if other.in_pit == car.in_pit:
			return other
	return null


func _update_gaps(order: Array[CarState]) -> void:
	for i in order.size():
		var car := order[i]
		var ahead := _same_lane_ahead(order, i)
		car.gap_ahead_s = -1.0 if ahead == null else (ahead.distance - car.distance) / maxf(car.speed, 1.0)


func _all_finished() -> bool:
	for car in cars:
		if not car.finished:
			return false
	return true


func _update_trace() -> void:
	var lead := -INF
	for car in cars:
		lead = maxf(lead, car.distance)
	lead = minf(lead, race_distance())  # depois da bandeirada a referência do líder para
	if lead <= 0.0:
		return
	if _trace_dist.is_empty() or lead - _trace_dist[_trace_dist.size() - 1] >= TRACE_STEP_M:
		_trace_dist.append(lead)
		_trace_time.append(time_s)


func _time_at_distance(d: float) -> float:
	var i := _trace_dist.bsearch(d, true)
	if i <= 0:
		return _trace_time[0]
	if i >= _trace_dist.size():
		return _trace_time[_trace_dist.size() - 1]
	var d0 := _trace_dist[i - 1]
	var d1 := _trace_dist[i]
	var t := 0.0 if d1 <= d0 else (d - d0) / (d1 - d0)
	return lerpf(_trace_time[i - 1], _trace_time[i], t)
