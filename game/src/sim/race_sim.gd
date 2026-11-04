class_name RaceSim
extends RefCounted
## Simulação de uma corrida, separada da tela.
##
## Avança em passos fixos de tempo (DT). Com a mesma semente aleatória, a corrida se
## repete igual — isso permite testar as regras com GUT e acelerar o tempo sem mudar o
## resultado. A tela só lê o estado (posições, pneus, clima, bandeiras) e envia ordens.
##
## Módulos: WeatherModel (clima), RaceControl (incidentes, bandeiras, punições),
## RadioSystem (rádio dos pilotos do jogador), StrategyAI (decisões das equipes rivais).

signal overtake(attacker: CarState, defender: CarState, zone_name: String)
signal pit_stop(car: CarState, compound: String, stationary_s: float)
signal fastest_lap(car: CarState, lap_time: float)
@warning_ignore("unused_signal")  # emitido por RaceControl/RadioSystem
signal incident(car: CarState, kind: String, text: String)
@warning_ignore("unused_signal")  # emitido por RaceControl/RadioSystem
signal flag_changed(flag: int, text: String)
@warning_ignore("unused_signal")  # emitido por RaceControl/RadioSystem
signal penalty(car: CarState, kind: String, reason: String)
signal team_order_result(car: CarState, obeyed: bool, text: String)
@warning_ignore("unused_signal")  # emitido por RaceControl/RadioSystem
signal radio_message(message: Dictionary)
@warning_ignore("unused_signal")  # emitido por RaceControl/RadioSystem
signal radio_answered(message: Dictionary)
signal car_finished(car: CarState, position: int)
signal pit_box_stop(car: CarState, hold_s: float)  ## carro parou no box (a tela pode abrir o mini-jogo)
signal race_finished

const WEAR_SHORT_RACE_EXP := 0.5  ## quanto o desgaste cresce em corridas curtas (1 = proporcional)
const DT := 0.1  ## segundos de corrida por passo
const GRID_SPACING_M := 10.0
const MIN_GAP_M := 9.0  ## sem ultrapassar, um carro não chega mais perto que isso do da frente
const ATTACK_WINDOW_S := 1.0  ## a menos de 1 s do carro da frente: pode tentar ultrapassar
const DIRTY_AIR_S := 0.25  ## perda máxima por volta andando colado (ar turbulento)
const STRATEGY_FRAC := 0.85  ## ponto da volta onde a IA decide se para no box
const MODE_UPDATE_S := 2.0
const TRACE_STEP_M := 5.0

## Escalas de desempenho (PROVISÓRIAS até a definição dos atributos)
const CAR_K := 0.105  ## s/volta por ponto de nota do carro abaixo de 100 (calibrado: ~55% do resultado, tools/balance_report.gd)
const DRIVER_K := 0.019  ## s/volta por ponto de ritmo do piloto abaixo de 100 (calibrado: ~25% do resultado)
const FUEL_START_S := 3.0  ## carro cheio de combustível é ~3 s/volta mais lento
const LAP_NOISE_SIGMA := 0.12
const WET_TRACK_S := 4.0  ## pista totalmente molhada deixa todos ~4 s/volta mais lentos
const RUBBER_GAIN_S := 0.4  ## pista totalmente emborrachada: ~0,4 s/volta mais rápida
const PACE_TIME := {CarState.PaceMode.CONSERVE: 0.45, CarState.PaceMode.NORMAL: 0.0, CarState.PaceMode.ATTACK: -0.35}
const PACE_WEAR := {CarState.PaceMode.CONSERVE: 0.7, CarState.PaceMode.NORMAL: 1.0, CarState.PaceMode.ATTACK: 1.35}
const ENERGY_TIME := {CarState.EnergyMode.HARVEST: 0.3, CarState.EnergyMode.BALANCED: 0.0, CarState.EnergyMode.DEPLOY: -0.3}
## carga da bateria por volta: Equilíbrio recarrega devagar (antes era 0 e a bateria só esvaziava), Carregar
## recarrega rápido (custa ritmo), Bateria gasta (ganha ritmo). Ver test_battery.
const ENERGY_SOC := {CarState.EnergyMode.HARVEST: 0.18, CarState.EnergyMode.BALANCED: 0.05, CarState.EnergyMode.DEPLOY: -0.14}
const OVERTAKE_MODE_BONUS_S := 0.2  ## energia extra para quem ataca a menos de 1 s (regra 2026)
const OVERTAKE_MODE_COST := 0.03
const OVERTAKE_SCALE := 0.21  ## quão "suave" é a curva de chance em torno da vantagem exigida
const OVERTAKE_BASE_REQUIRED_S := 0.4  ## vantagem mínima mesmo na pista mais fácil
const OVERTAKE_DIFFICULTY_S := 1.4  ## vantagem extra exigida por ponto de dificuldade da pista
const OVERTAKE_MAX_CHANCE := 0.5
const OVERTAKE_HARD_TRACK_S := 4.0  ## pistas muito travadas (dificuldade > 0,7) exigem bem mais
const DEFEND_HARD_S := 0.15  ## "defender forte" exige mais vantagem de quem ataca
const LET_BY_WINDOW_S := 1.2
const SPRINT_DISTANCE := 3.0  ## a sprint tem ~1/3 da distância da corrida
const RACE_POINTS := [25, 18, 15, 12, 10, 8, 6, 4, 2, 1]
const SPRINT_POINTS := [8, 7, 6, 5, 4, 3, 2, 1]

var track: TrackModel
var tyres: TyreModel
var weather: WeatherModel
var control: RaceControl
var radio: RadioSystem
var cars: Array[CarState] = []
var total_laps := 0
var duration_pct := 1.0
var sprint := false
var time_s := 0.0
var chequered := false
var over := false
var fastest_lap_time := INF
var fastest_lap_car: CarState = null
var overtakes_count := 0
var rng := RandomNumberGenerator.new()

## regulamento técnico (TechRules): mexe no tempo de volta, energia, ultrapassagem, desgaste e reabastecimento
var tech: Dictionary = TechRules.DEFAULT.duplicate()
var tech_lap_s := 0.0
var energy_k := 1.0
var overtake_k := 1.0
var dirty_k := 1.0
var wear_k := 1.0
var refuel := false
var engine_pitch := 1.0
var fuel_window_laps := 999
var team_box_free_at: Dictionary = {}  ## id da equipe -> instante em que o box fica livre
var _accum := 0.0
var _mode_timer := 0.0
var _finish_count := 0
var _leader_laps := 0
var _trace_dist := PackedFloat64Array()  # maior distância já alcançada por alguém...
var _trace_time := PackedFloat64Array()  # ...e o instante em que foi alcançada (para os intervalos)


## options: duration_pct (0.25/0.5/1.0), seed (int), player_team (String),
##          weather ("dry"/"rain"/"variable"/segmentos/ausente), rain_probability (padrão: do circuito),
##          incident_rate (0 = sem incidentes; 1 = realista),
##          radio (false = pilotos do jogador não perguntam nem decidem sozinhos),
##          grid (Array de ids de piloto na ordem de largada, vindo da classificação),
##          sprint (true = ~1/3 da distância, sem regra dos 2 compostos),
##          setups (Dictionary id do piloto -> CarSetup, vindo dos treinos)
func _init(p_track: TrackModel, p_tyres: TyreModel, teams: Array, drivers: Array, options: Dictionary = {}) -> void:
	track = p_track
	tyres = p_tyres
	duration_pct = float(options.get("duration_pct", 1.0))
	sprint = bool(options.get("sprint", false))
	total_laps = maxi(3, roundi(track.laps * duration_pct / (SPRINT_DISTANCE if sprint else 1.0)))
	rng.seed = int(options.get("seed", 1))
	_apply_tech(options.get("tech", {}))
	var rain_p := float(options.get("rain_probability", track.rain_probability))
	weather = WeatherModel.new(rain_p, total_laps * track.base_lap_time_s * 1.05, rng, options)
	control = RaceControl.new(self, float(options.get("incident_rate", 1.0)))
	radio = RadioSystem.new(self)
	radio.enabled = bool(options.get("radio", true))
	var player_team: String = options.get("player_team", "")
	for d: Dictionary in drivers:
		var car := CarState.new()
		car.index = cars.size()
		car.driver = d
		car.team = GameData.team_by_id(teams, d["team"])
		car.is_player = car.team["id"] == player_team
		if car.is_player:
			var stocks: Dictionary = options.get("tyre_stock", {})
			car.tyre_stock = (stocks[d["id"]] as Dictionary).duplicate(true) if stocks.has(d["id"]) else PitStop.default_stock()
		var setups: Dictionary = options.get("setups", {})
		if setups.has(d["id"]):
			(setups[d["id"]] as CarSetup).apply_to(car)
		cars.append(car)
	_setup_grid(options.get("grid", []))


func _apply_tech(t: Dictionary) -> void:
	tech = TechRules.merged(t)
	var k := TechRules.knobs(tech)
	tech_lap_s = k["lap_s"]
	energy_k = k["energy_k"]
	overtake_k = k["overtake_k"]
	dirty_k = k["dirty_k"]
	wear_k = k["wear_k"]
	refuel = k["refuel"]
	engine_pitch = k["pitch"]
	fuel_window_laps = maxi(3, ceili(total_laps * TechRules.REFUEL_WINDOW)) if refuel else 999


# --- largada -------------------------------------------------------------------------

func _setup_grid(grid_ids: Array = []) -> void:
	var scored: Array = []
	for car in cars:
		var pos := grid_ids.find(car.driver["id"])
		if grid_ids.is_empty():
			# sem classificação ("só a corrida"): ritmo puro + um pouco de sorte
			scored.append([_ideal_lap_time(car) + rng.randfn(0.0, 0.15), car])
		else:
			scored.append([float(pos if pos >= 0 else 1000 + car.index), car])
	scored.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for i in scored.size():
		var car: CarState = scored[i][1]
		car.grid_position = i
		car.distance = -GRID_SPACING_M * i - 5.0
		car.tyre = StrategyAI.choose_start_compound(i, rng)
		if weather.wetness >= 0.2:
			car.tyre = tyres.best_for_wetness(weather.wetness, ["inter", "wet"])
		car.compounds_used = [car.tyre]
		if car.is_player and PitStop.take_set(car, car.tyre, false):
			car.tyre_wear = PitStop.USED_SET_WEAR  # sem jogo novo: larga com um usado
		car.pit_compound = "hard" if car.tyre != "hard" else "medium"
		car.ai_pit_wear = rng.randf_range(0.66, 0.76)
		car.lap_noise = rng.randfn(0.0, LAP_NOISE_SIGMA)


# --- consultas usadas pela tela e pela IA ---------------------------------------------

func race_distance() -> float:
	return total_laps * track.length_m


func wear_multiplier() -> float:
	# corridas mais curtas desgastam mais (senão ninguém pararia), mas não na proporção cheia:
	# com o expoente 1 uma corrida de 25% pedia 3 paradas em 18 voltas (balanceado: ver DECISIONS)
	return track.tyre_wear_factor / pow(duration_pct, WEAR_SHORT_RACE_EXP) * wear_k


func frac_of(car: CarState) -> float:
	return fposmod(car.distance, track.length_m) / track.length_m


## Distância "visual" com interpolação entre passos da simulação (movimento suave).
func render_distance(car: CarState) -> float:
	if car.finished or car.retired:
		return car.distance
	return car.distance + car.speed * _accum


func leader_lap() -> int:
	return mini(_leader_laps + 1, total_laps)


## Classificação atual: na pista por voltas e distância; chegada pelo tempo (com punições);
## abandonos depois; desclassificados por último.
func standings() -> Array[CarState]:
	var list := cars.duplicate()
	list.sort_custom(_compare_position)
	return list


func _compare_position(a: CarState, b: CarState) -> bool:
	if a.disqualified != b.disqualified:
		return b.disqualified
	if a.retired != b.retired:
		return b.retired
	if a.laps_done != b.laps_done:
		return a.laps_done > b.laps_done
	if a.finished != b.finished:
		return a.finished
	if a.finished:
		return a.classified_time() < b.classified_time()
	return a.distance > b.distance


## Diferença para o líder em segundos.
## Em andamento: há quanto tempo o líder passou pelo ponto onde o carro está.
## Depois da chegada: diferença entre os tempos de classificação (com punições).
func gap_to_leader_s(car: CarState) -> float:
	var lead := leader()
	if car == lead:
		return 0.0
	if car.finished and lead.finished:
		return maxf(0.0, car.classified_time() - lead.classified_time())
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
	if car.finished or car.retired:
		return lead.laps_done - car.laps_done
	return floori((lead.distance - car.distance) / track.length_m)


func is_over() -> bool:
	return over


## Vida restante (em voltas) do pneu atual até o início do penhasco.
func tyre_laps_left(car: CarState) -> float:
	var c: Dictionary = tyres.compounds[car.tyre]
	var per_lap := tyres.wear_per_lap(car.tyre) * wear_multiplier() * tyres.wet_wear_multiplier(car.tyre, weather.wetness)
	return maxf(0.0, (float(c["cliff_start"]) - car.tyre_wear) / per_lap)


func teammate_of(car: CarState) -> CarState:
	for other in cars:
		if other != car and other.team["id"] == car.team["id"]:
			return other
	return null


## Ritmo do carro agora, sem tráfego nem sorte (para comparar quem é mais rápido).
func ideal_pace(car: CarState) -> float:
	return _lap_time(car, false)


# --- ordens do jogador ---------------------------------------------------------------

func request_pit(car: CarState, compound: String) -> void:
	if car.finished or car.in_pit or car.retired:
		return
	car.pit_compound = compound
	car.pit_requested = true
	if not car.plan.is_empty():
		car.plan["compound"] = compound


## Plano completo da parada (tela do box). Devolve false se faltar o jogo de pneus escolhido.
func set_pit_plan(car: CarState, plan: Dictionary) -> bool:
	if car.finished or car.in_pit or car.retired:
		return false
	if not PitStop.has_set(car, plan["compound"], plan.get("use_used", false)):
		return false
	car.plan = plan.duplicate()
	car.pit_compound = plan["compound"]
	car.repair_wing = bool(plan.get("repair_wing", false))
	car.pit_requested = true
	car.pit_defer_laps = -1
	return true


## Segura o pedido de box por n voltas (parada dupla: o outro carro entra primeiro).
func defer_pit(car: CarState, laps: int) -> void:
	if car.in_pit:
		return
	car.pit_requested = false
	car.pit_defer_laps = car.laps_done + laps


## Segundos até o carro chegar à entrada do pit lane (0 se já está no box).
func pit_entry_eta_s(car: CarState) -> float:
	if car.in_pit:
		return 0.0
	var ahead := fposmod(track.pit_entry_frac * track.length_m - fposmod(car.distance, track.length_m), track.length_m)
	return ahead / (track.length_m / _lap_time(car, false))


## Quanto o carro esperaria na fila do box se entrasse agora (o box ocupado pelo companheiro).
func box_queue_wait_s(car: CarState) -> float:
	var arrive := time_s + pit_entry_eta_s(car) + 8.0  # ~8 s de pit lane até o box
	return maxf(0.0, float(team_box_free_at.get(car.team["id"], 0.0)) - arrive)


## Mini-jogo: toque do jogador com o carro parado (accuracy 1 = perfeito). Vale uma vez por parada.
func pit_tap(car: CarState, accuracy: float) -> float:
	if not car.in_pit or car.box_hold_s <= 0.0 or car.box_tapped:
		return 0.0
	car.box_tapped = true
	var d := PitStop.tap_delta(accuracy)
	car.box_hold_s = maxf(0.4, car.box_hold_s + d)
	car.pit_stationary_s += d
	return d


func cancel_pit(car: CarState) -> void:
	if not car.in_pit and not car.drive_through:
		car.pit_requested = false


func set_pace_mode(car: CarState, mode: CarState.PaceMode) -> void:
	car.pace_mode = mode


func set_energy_mode(car: CarState, mode: CarState.EnergyMode) -> void:
	car.energy_mode = mode


## Ordem de equipe. "Não brigar" vale para a dupla; "deixar passar" é para este carro abrir
## para o companheiro. O piloto pode desobedecer (mais provável se estiver brigando por pódio
## ou se for melhor que o companheiro).
func set_team_order(car: CarState, order: CarState.TeamOrder) -> void:
	var mate := teammate_of(car)
	if order == CarState.TeamOrder.FREE:
		car.team_order = order
		if mate != null and mate.team_order == CarState.TeamOrder.HOLD:
			mate.team_order = order
		team_order_result.emit(car, true, "Pilotos liberados para disputar.")
		return
	var p := 0.85
	var pos := standings().find(car) + 1
	if order == CarState.TeamOrder.LET_BY and pos <= 3:
		p -= 0.2
	if mate != null and DriverStats.overall(car.driver) > DriverStats.overall(mate.driver):
		p -= 0.15
	var who := car.display_name().get_slice(" ", 0)
	if rng.randf() >= p:
		car.team_order = CarState.TeamOrder.FREE
		var text := "%s: \"Não vou abrir! Ele que me passe na pista.\"" % who if order == CarState.TeamOrder.LET_BY \
			else "%s: \"Desculpa, mas eu vou atacar.\"" % who
		team_order_result.emit(car, false, text)
		return
	car.team_order = order
	if order == CarState.TeamOrder.HOLD and mate != null:
		mate.team_order = order
	var ok := "%s: \"Entendido, vou abrir.\"" % who if order == CarState.TeamOrder.LET_BY else "%s: \"Ok, posições mantidas.\"" % who
	team_order_result.emit(car, true, ok)


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
	weather.step(DT, control.flag == RaceControl.Flag.GREEN)
	_mode_timer -= DT
	if _mode_timer <= 0.0:
		_mode_timer = MODE_UPDATE_S
		for car in cars:
			if not car.is_player and not car.finished and not car.retired:
				StrategyAI.update_modes(self, car)

	var order := _running_order()
	_update_gaps(order)
	for car in order:
		if car.drive_through and not car.pit_requested:
			car.pit_requested = true
		if car.in_pit and car.box_hold_s > 0.0:
			car.speed = 0.0
			car.box_hold_s -= DT
			if car.box_hold_s <= 0.0:
				car.box_hold_s = 0.0
				_service_car(car)
		elif car.in_pit:
			car.speed = car.pit_speed
		elif car.stall_s > 0.0:
			car.speed = 0.0
		else:
			car.speed = control.flag_speed(car, track.length_m / _lap_time(car, true))

	if control.flag == RaceControl.Flag.GREEN:
		_resolve_overtakes(order)
		_apply_let_by(order)
		order = _running_order()

	for i in order.size():
		var car: CarState = order[i]
		var prev := car.distance
		var target := prev + car.speed * DT
		if car.lane() == 0:
			var ahead := _same_lane_ahead(order, i)
			if ahead != null:
				target = minf(target, ahead.distance - MIN_GAP_M)
		target = maxf(target, prev)  # nunca anda para trás
		car.distance = target
		_after_move(car, prev, target)

	control.step(DT, _running_order())
	_update_trace()
	if chequered and _all_finished():
		over = true
		race_finished.emit()


# --- modelo de ritmo -----------------------------------------------------------------

## Tempo de volta ideal (sem tráfego, sem aleatoriedade, pneu macio novo, sem combustível).
func _ideal_lap_time(car: CarState) -> float:
	return base_lap_time(track, car.team, car.driver) + car.setup_penalty_s


## Volta ideal sem pneu, combustível nem acerto: pista + carro + piloto.
## Compartilhada com treinos e classificação para que o carro rápido seja rápido em tudo.
static func base_lap_time(p_track: TrackModel, team: Dictionary, driver: Dictionary) -> float:
	return p_track.base_lap_time_s \
		+ (100.0 - float(team["car_rating"]) - float((team.get("car_delta", {}) as Dictionary).get(driver.get("id", ""), 0.0))) * CAR_K \
		+ (100.0 - DriverStats.attr(driver, "pace")) * DRIVER_K


## Pontos pela posição final (1 = vencedor). Sprint: 8 primeiros; corrida: 10 primeiros.
static func points_for(position: int, is_sprint: bool) -> int:
	var table: Array = SPRINT_POINTS if is_sprint else RACE_POINTS
	return table[position - 1] if position >= 1 and position <= table.size() else 0


## Regra dos 2 compostos secos (só na corrida principal, com pista seca).
func compound_rule_ok(car: CarState) -> bool:
	return sprint or tyres.rule_satisfied(car.compounds_used)


## Tempo de volta no estado atual (bandeira verde). with_traffic inclui ruído e ar turbulento.
func _lap_time(car: CarState, with_traffic: bool) -> float:
	var t := _ideal_lap_time(car)
	t += tyres.pace_penalty(car.tyre, car.tyre_wear)
	var wet_skill := 1.0 + (80.0 - DriverStats.attr(car.driver, "wet")) * DriverStats.WET_K
	t += (tyres.wet_penalty(car.tyre, weather.wetness) + weather.wetness * WET_TRACK_S) * clampf(wet_skill, 0.7, 1.4)
	t -= weather.rubber * RUBBER_GAIN_S
	t += tech_lap_s
	if refuel:  # tanque pequeno: só o peso do combustível desde a última parada
		t += FUEL_START_S * TechRules.REFUEL_FUEL_K * (1.0 - clampf(float(car.tyre_laps) / fuel_window_laps, 0.0, 1.0))
	else:
		t += FUEL_START_S * (1.0 - clampf(car.distance / race_distance(), 0.0, 1.0))
	t += PACE_TIME[car.pace_mode]
	t -= PitStop.WING_LAP_S * car.wing_step
	if car.energy_mode != CarState.EnergyMode.DEPLOY or car.battery > 0.0:
		t += ENERGY_TIME[car.energy_mode] * energy_k
	t += car.damage_wing * RaceControl.WING_PENALTY_S + car.damage_floor * RaceControl.FLOOR_PENALTY_S + car.power_loss_s
	t += radio.confidence_delta_s(car)
	if with_traffic:
		t += car.lap_noise
		var gap := gap_to_car_ahead_s(car)
		if gap >= 0.0 and gap < ATTACK_WINDOW_S:
			t += DIRTY_AIR_S * dirty_k * (1.0 - gap / ATTACK_WINDOW_S)
	return t


# --- ultrapassagens e ordens de equipe -------------------------------------------------

func _resolve_overtakes(order: Array[CarState]) -> void:
	for i in range(1, order.size()):
		var att: CarState = order[i]
		if att.lane() != 0:
			continue
		var def := _same_lane_ahead(order, i)
		if def == null:
			continue
		if att.team["id"] == def.team["id"] and (att.team_order == CarState.TeamOrder.HOLD or def.team_order == CarState.TeamOrder.HOLD):
			continue  # "não brigar"
		var gap_m := def.distance - att.distance
		if gap_m > att.speed * ATTACK_WINDOW_S:
			continue
		var next_d := att.distance + att.speed * DT
		for zone: Dictionary in track.overtaking_zones:
			if _crossed(att.distance, next_d, float(zone["braking_frac"])):
				if control.check_contact(att, def):
					break
				if _try_overtake(att, def, zone):
					_swap(att, def, 0.25)
					overtakes_count += 1
					overtake.emit(att, def, zone["name"])
				break


func _try_overtake(att: CarState, def: CarState, zone: Dictionary) -> bool:
	var advantage := _lap_time(def, false) - _lap_time(att, false)  # > 0: atacante mais rápido
	advantage += (DriverStats.attr(att.driver, "racecraft") - DriverStats.attr(def.driver, "racecraft")) * DriverStats.RACECRAFT_K
	var required_base := (OVERTAKE_BASE_REQUIRED_S + track.overtaking_difficulty * OVERTAKE_DIFFICULTY_S \
		+ maxf(0.0, track.overtaking_difficulty - 0.7) * OVERTAKE_HARD_TRACK_S) * overtake_k + (DEFEND_HARD_S if def.defend_hard else 0.0)
	# modo de ultrapassagem: gasta bateria só quando faz diferença (sem ele faltaria vantagem) e no máximo uma
	# vez por volta — antes era usado em toda tentativa e a bateria ficava sempre vazia
	if att.battery > 0.1 and att.boost_lap != att.laps_done and advantage < required_base \
			and advantage + OVERTAKE_MODE_BONUS_S * energy_k > required_base - 2.0 * OVERTAKE_SCALE:
		advantage += OVERTAKE_MODE_BONUS_S * energy_k
		att.battery = maxf(0.0, att.battery - OVERTAKE_MODE_COST)
		att.boost_lap = att.laps_done
	# Ex.: Interlagos (0,35) exige ~0,9 s/volta de vantagem para a chance chegar à metade do máximo;
	# Mônaco (0,95) exige ~2,8 s (ainda quase impossível). Mais fácil desde 2026-11-03 (pedido do usuário).
	var p := float(zone["strength"]) / (1.0 + exp(-(advantage - required_base) / OVERTAKE_SCALE))
	return rng.randf() < clampf(p, 0.0, OVERTAKE_MAX_CHANCE)


## Troca de posição: quem estava atrás passa à frente; quem foi passado perde `loss_s`.
func _swap(behind: CarState, ahead: CarState, loss_s: float) -> void:
	var ahead_d := ahead.distance
	ahead.distance = behind.distance - ahead.speed * loss_s
	behind.distance = ahead_d


## "Deixar passar": quando o companheiro encosta, o carro abre a posição.
func _apply_let_by(order: Array[CarState]) -> void:
	for i in order.size():
		var car := order[i]
		if car.team_order != CarState.TeamOrder.LET_BY or car.lane() != 0:
			continue
		var mate := teammate_of(car)
		if mate == null or mate.lane() != 0 or mate.finished or mate.retired:
			car.team_order = CarState.TeamOrder.FREE
			continue
		var gap := (car.distance - mate.distance) / maxf(mate.speed, 1.0)
		var j := order.find(mate)
		if j == i + 1 and gap > 0.0 and gap < LET_BY_WINDOW_S:
			_swap(mate, car, 0.4)
			car.team_order = CarState.TeamOrder.FREE
			team_order_result.emit(car, true, "%s abre para %s." % [car.code(), mate.code()])


# --- eventos de volta, box e chegada -------------------------------------------------

func _after_move(car: CarState, prev: float, now: float) -> void:
	var moved := now - prev
	if moved <= 0.0:
		return
	var lap_part := moved / track.length_m
	var wear: float = tyres.wear_per_lap(car.tyre) * wear_multiplier() * PACE_WEAR[car.pace_mode]
	wear *= tyres.wet_wear_multiplier(car.tyre, weather.wetness)
	wear *= 1.0 + PitStop.WING_WEAR * car.wing_step
	wear *= clampf(1.0 + (75.0 - DriverStats.attr(car.driver, "tyres")) * DriverStats.TYRE_K, 0.85, 1.2)
	if control.is_neutralized():
		wear *= 0.5
	car.tyre_wear += wear * lap_part * car.wear_factor
	var soc: float = ENERGY_SOC[car.energy_mode] * energy_k + (0.1 if control.is_neutralized() else 0.0)
	# reabastecimento: o tanque acaba e o carro TEM de parar (a estratégia escolhe o pneu)
	if refuel and car.tyre_laps >= fuel_window_laps and not car.pit_requested and not car.in_pit \
			and car.laps_done + 1 < total_laps and not car.finished and not car.retired:
		request_pit(car, StrategyAI.choose_compound(self, car, total_laps - car.laps_done))
		if car.is_player:
			incident.emit(car, "fuel", "%s precisa reabastecer: box nesta volta." % car.display_name())
	car.battery = clampf(car.battery + soc * lap_part, 0.0, 1.0)

	if not car.is_player and _crossed(prev, now, STRATEGY_FRAC):
		StrategyAI.decide_pit(self, car)

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

	if car.in_pit and not car.pit_service_done and car.box_hold_s <= 0.0 and _crossed(prev, now, track.pit_box_frac):
		_begin_service(car)
	elif car.in_pit and car.pit_service_done and _crossed(prev, now, track.pit_exit_frac):
		car.in_pit = false
		car.pit_requested = false


func _enter_pit(car: CarState) -> void:
	car.in_pit = true
	car.pit_service_done = false
	car.box_hold_s = 0.0
	car.box_tapped = false
	var stationary := 0.0
	if not car.drive_through:  # drive-through passa pelo pit lane sem parar
		var plan := car.plan if not car.plan.is_empty() else PitStop.make_plan(car.pit_compound)
		if not car.is_player and car.damage_wing > 0.15:
			plan["repair_wing"] = true
		if car.repair_wing:
			plan["repair_wing"] = true
		if not car.is_player:
			plan["serve_penalty"] = true
		car.plan = plan
		stationary = float(PitStop.estimate(car, plan)["total"]) + absf(rng.randfn(0.0, 0.3))
		if rng.randf() < 0.05:
			stationary += rng.randf_range(2.0, 5.0)  # parada lenta
		if refuel:
			stationary += TechRules.REFUEL_S
	car.pit_stationary_s = stationary
	# o pit lane tem limite de velocidade: o tempo andando é fixo (ritmo de bandeira verde), por
	# isso parar sob safety car/VSC custa menos. A parte parada (2,4 s padrão) acontece no box.
	var normal_speed := track.length_m / _lap_time(car, false)
	var lane := track.pit_lane_length_m()
	var lane_time := lane / normal_speed + track.pit_lane_loss_s - PitStop.BASE_S
	car.pit_speed = lane / maxf(lane_time, 1.0)


## O carro chegou ao box: espera a vez (se o companheiro ocupa o box) e fica parado.
func _begin_service(car: CarState) -> void:
	if car.drive_through:
		_service_car(car)
		return
	var team_id: String = car.team["id"]
	var wait := maxf(0.0, float(team_box_free_at.get(team_id, 0.0)) - time_s)
	car.box_wait_s = wait
	car.box_hold_s = wait + car.pit_stationary_s
	team_box_free_at[team_id] = time_s + car.box_hold_s + PitStop.QUEUE_GAP_S
	car.speed = 0.0
	pit_box_stop.emit(car, car.box_hold_s)


func _service_car(car: CarState) -> void:
	car.pit_service_done = true
	if car.drive_through:
		car.drive_through = false
		pit_stop.emit(car, "", 0.0)
		return
	var plan := car.plan if not car.plan.is_empty() else PitStop.make_plan(car.pit_compound)
	if plan.get("serve_penalty", true):
		car.penalty_pending_s = 0.0  # cumpriu a punição de tempo parado no box
	if car.repair_wing or plan.get("repair_wing", false):
		car.damage_wing = 0.0
		car.repair_wing = false
	if plan.get("repair_floor", false):
		car.damage_floor *= 0.5
	if car.is_player:
		car.wing_step = int(plan.get("wing_step", car.wing_step))
	var used := PitStop.take_set(car, car.pit_compound, plan.get("use_used", false))
	car.tyre = car.pit_compound
	car.tyre_wear = PitStop.USED_SET_WEAR if used else 0.0
	car.tyre_laps = 0
	car.plan = {}
	if not car.compounds_used.has(car.tyre):
		car.compounds_used.append(car.tyre)
	car.pit_stops += 1
	control.on_pit_stop(car)
	pit_stop.emit(car, car.tyre, car.pit_stationary_s)


func _complete_lap(car: CarState, lap_number: int, cross_time: float) -> void:
	car.laps_done = lap_number
	if car.pit_defer_laps >= 0 and lap_number >= car.pit_defer_laps:
		car.pit_defer_laps = -1
		car.pit_requested = true  # fim do adiamento: o box volta a valer
	car.last_lap_time = cross_time - car.lap_start_time
	car.lap_start_time = cross_time
	car.lap_times.append(car.last_lap_time)
	car.tyre_laps += 1
	car.lap_noise = rng.randfn(0.0, LAP_NOISE_SIGMA)
	if lap_number > _leader_laps:
		_leader_laps = lap_number
		control.on_leader_lap(lap_number)
	var green_lap := control.flag == RaceControl.Flag.GREEN
	if lap_number > 1 and green_lap:  # a 1ª volta inclui a largada parada
		car.best_lap_time = minf(car.best_lap_time, car.last_lap_time)
		if car.last_lap_time < fastest_lap_time:
			fastest_lap_time = car.last_lap_time
			fastest_lap_car = car
			fastest_lap.emit(car, car.last_lap_time)
	if not chequered and lap_number >= total_laps:
		chequered = true
	if chequered:
		_finish(car, cross_time)
	elif car.is_player:
		radio.on_lap(car)


func _finish(car: CarState, cross_time: float) -> void:
	car.finished = true
	car.finish_time = cross_time
	car.in_pit = false
	car.speed = 0.0
	if not compound_rule_ok(car):
		car.disqualified = true  # regra dos 2 compostos não cumprida
	_finish_count += 1
	car_finished.emit(car, _finish_count)


# --- chamados pela direção de prova ----------------------------------------------------

func retire_car(car: CarState, reason: String) -> void:
	car.retired = true
	car.retire_reason = reason
	car.speed = 0.0
	car.in_pit = false
	car.pit_requested = false
	car.stall_s = 0.0


## Safety car ou VSC acionado: parada "barata". A IA aproveita; o jogador recebe a pergunta.
func on_neutralization() -> void:
	for car in _running_order():
		if car.is_player:
			radio.on_neutralization(car)
		else:
			StrategyAI.on_neutralization(self, car)


## Bandeira vermelha: todos podem trocar pneus (e reparar a asa) sem perder tempo.
func free_tyre_change() -> void:
	for car in _running_order():
		var remaining := total_laps - car.laps_done
		var best := tyres.best_for_wetness(weather.wetness + 0.05)
		var compound := best
		if tyres.is_dry(best):
			compound = car.pit_compound if car.is_player and tyres.is_dry(car.pit_compound) else StrategyAI.choose_compound(self, car, remaining)
		car.tyre = compound
		car.tyre_wear = PitStop.USED_SET_WEAR if PitStop.take_set(car, compound, false) else 0.0
		car.tyre_laps = 0
		if not car.compounds_used.has(compound):
			car.compounds_used.append(compound)
		car.damage_wing = 0.0
		car.in_pit = false
		car.pit_requested = false
		car.stall_s = 0.0


# --- utilidades ----------------------------------------------------------------------

## O carro passou pelo ponto "frac" da volta entre as distâncias a e b?
func _crossed(a: float, b: float, frac: float) -> bool:
	var offset := frac * track.length_m
	return floorf((b - offset) / track.length_m) > floorf((a - offset) / track.length_m)


func _running_order() -> Array[CarState]:
	var list: Array[CarState] = []
	for car in cars:
		if not car.finished and not car.retired:
			list.append(car)
	list.sort_custom(func(a: CarState, b: CarState) -> bool: return a.distance > b.distance)
	return list


## Carro mais próximo à frente (em distância total) na mesma faixa (pista, box ou fora do traçado).
## Carros com uma volta a mais ficam longe em distância total: é a "bandeira azul" implícita.
func _same_lane_ahead(order: Array[CarState], i: int) -> CarState:
	var car := order[i]
	var lane := car.lane()
	if lane == 2:
		return null  # fora do traçado não disputa nada
	for j in range(i - 1, -1, -1):
		var other := order[j]
		if other.lane() == lane:
			return other
	return null


func _update_gaps(order: Array[CarState]) -> void:
	for i in order.size():
		var car := order[i]
		var ahead := _same_lane_ahead(order, i)
		car.gap_ahead_s = -1.0 if ahead == null else (ahead.distance - car.distance) / maxf(car.speed, 1.0)


func _all_finished() -> bool:
	for car in cars:
		if not car.finished and not car.retired:
			return false
	return true


func _update_trace() -> void:
	var lead := -INF
	for car in cars:
		if not car.retired:
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
