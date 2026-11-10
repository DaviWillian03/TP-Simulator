class_name RaceControl
extends RefCounted
## Direção de prova: incidentes, quebras, toques, bandeiras (safety car, VSC, vermelha)
## e comissários (punições). As chances são PROVISÓRIAS e calibradas para o nível
## "realista" escolhido pelo usuário, com mais erros e quebras a pedido dele (2026-11-03): na seca, ~2–3
## abandonos por corrida, várias rodadas/escapadas e algum carro perdendo ritmo por problema mecânico.

enum Flag { GREEN, SC, VSC, RED }

const INCIDENT_PER_LAP := 0.0024  ## chance base de erro do piloto (travada, rodada, batida) por carro por volta
const FAILURE_PER_LAP := 0.0018  ## chance base de problema mecânico por carro por volta
const PARTIAL_FAILURE_SHARE := 0.35  ## parte dos problemas que não tira o carro da prova, só tira ritmo
const POWER_LOSS_S := Vector2(0.25, 0.9)  ## perda por volta numa quebra parcial (até o fim da corrida)
const INVESTIGATION_MIN_S := 45.0  ## investigação dura de ~45 s a ~2 min
const INVESTIGATION_MAX_S := 120.0
const CONTACT_CHANCE := 0.003  ## chance de toque numa tentativa de ultrapassagem (há centenas por corrida)
const PIT_SPEEDING_CHANCE := 0.015
const SC_PACE := 1.6  ## fila atrás do safety car: volta ~60% mais lenta
const VSC_PACE := 1.35
const SC_CATCH_UP := 1.2  ## quem ainda não alcançou a fila anda no tempo mínimo exigido (~1,33x), como na F1
const SC_TARGET_GAP_M := 25.0
const WING_PENALTY_S := 1.8  ## asa totalmente destruída
const FLOOR_PENALTY_S := 1.0
const WING_CHANGE_S := 7.0  ## tempo extra parado para trocar a asa
const RED_FLAG_SUSPENSION_S := 900.0
# estouro de pneu (decisão 2026-11-09): possível com 20% de vida ou menos, mais provável quanto mais gasto
const BLOWOUT_FROM_WEAR := 0.80  ## desgaste a partir do qual o pneu pode estourar (vida <= 20%)
const BLOWOUT_MAX_PER_LAP := 0.30  ## chance por volta com o pneu no fim (vida 0%); cresce com o quadrado
const BLOWOUT_RETIRE := 0.15  ## parte dos estouros que destrói a suspensão/assoalho e tira o carro
const PUNCTURE_LAP_MULT := 1.45  ## volta lenta até o box com o pneu estourado
const PACE_RISK := {CarState.PaceMode.CONSERVE: 0.7, CarState.PaceMode.NORMAL: 1.0, CarState.PaceMode.ATTACK: 1.6}

var _sim_ref: WeakRef  # referência fraca: evita ciclo RaceSim <-> módulo (vazaria memória)
var sim: RaceSim:
	get:
		return _sim_ref.get_ref()
var rate := 1.0  ## multiplicador de incidentes (opção "incident_rate")
var flag := Flag.GREEN
var sc_laps_left := 0
var vsc_time_left := 0.0
var flag_reason := ""
var sc_count := 0
var vsc_count := 0
var red_count := 0
var _last_leader_lap := 0


func _init(p_sim: RaceSim, p_rate: float) -> void:
	_sim_ref = weakref(p_sim)
	rate = p_rate


func is_neutralized() -> bool:
	return flag == Flag.SC or flag == Flag.VSC


func status_text() -> String:
	match flag:
		Flag.SC:
			return "SAFETY CAR · %d VOLTA%s" % [sc_laps_left, "" if sc_laps_left == 1 else "S"]
		Flag.VSC:
			return "SAFETY CAR VIRTUAL"
		Flag.RED:
			return "BANDEIRA VERMELHA"
	return ""


# --- velocidade sob bandeira ---------------------------------------------------------

## Velocidade do carro neste passo considerando a bandeira (green_speed = ritmo normal).
func flag_speed(car: CarState, green_speed: float) -> float:
	match flag:
		Flag.VSC:
			return green_speed / VSC_PACE
		Flag.SC:
			var sc_speed := sim.track.length_m / (sim.track.base_lap_time_s * SC_PACE)
			var gap_m := car.gap_ahead_s * car.speed if car.gap_ahead_s >= 0.0 else -1.0
			if gap_m < 0.0 or gap_m > SC_TARGET_GAP_M:
				return minf(green_speed, sc_speed * SC_CATCH_UP) if gap_m >= 0.0 else sc_speed
			return sc_speed
	return green_speed


# --- avanço por passo ----------------------------------------------------------------

## Resolve as investigações vencidas: punição (círculo vermelho na torre) ou arquivamento.
func _resolve_investigations() -> void:
	for car in sim.cars:
		if car.investigation.is_empty() or sim.time_s < float(car.investigation["until_s"]):
			continue
		var inv: Dictionary = car.investigation
		car.investigation = {}
		if car.retired:
			continue
		if inv["guilty"]:
			give_penalty(car, float(inv["secs"]), String(inv["reason"]))
		else:
			sim.incident.emit(car, "cleared", "%s: sem punição, investigação arquivada" % car.display_name())


func step(dt: float, running: Array[CarState]) -> void:
	_resolve_investigations()
	if flag == Flag.VSC:
		vsc_time_left -= dt
		if vsc_time_left <= 0.0:
			_go_green("Fim do safety car virtual")
	if rate <= 0.0 or flag == Flag.RED:
		return
	var s := sim
	var lap_time := maxf(s.track.base_lap_time_s, 30.0)
	for car in running:
		if car.stall_s > 0.0:
			car.stall_s = maxf(0.0, car.stall_s - dt)
			continue
		if car.in_pit:
			continue
		if not car.punctured and s.rng.randf() < blowout_chance_per_lap(car) * dt / lap_time:
			_blowout(car)
			continue
		var p_incident := incident_rate_per_lap(car) * dt / lap_time
		if flag == Flag.GREEN and s.rng.randf() < p_incident:
			_incident(car)
		elif s.rng.randf() < FAILURE_PER_LAP * rate * _failure_mult(car) * dt / lap_time:
			_failure(car)


## Multiplicador de quebras do carro: da equipe ou, na campanha, de cada carro (peças instaladas).
func _failure_mult(car: CarState) -> float:
	var team_m := float(car.team.get("failure_mult", 1.0))
	var by: Dictionary = car.team.get("failure_by_driver", {})
	if by.has(car.driver.get("id", "")):
		return team_m * float(by[car.driver["id"]])  # fator relativo das peças de confiabilidade deste carro
	return team_m


## Chance de incidente por volta para este carro, agora (pista, pneus, ordens, piloto).
func incident_rate_per_lap(car: CarState) -> float:
	var s := sim
	var w := s.weather.wetness
	var r := INCIDENT_PER_LAP * rate
	r *= 1.0 + 9.0 * w + 2.0 * s.weather.rain_now()
	r *= 1.0 + s.tyres.wet_penalty(car.tyre, w) / 4.0  # pneu errado para a pista
	r *= 1.0 + 6.0 * maxf(0.0, car.tyre_wear - 0.78)
	r *= PACE_RISK[car.pace_mode]
	if car.defend_hard:
		r *= 1.3
	r *= 1.0 + car.damage_wing
	if car.laps_done == 0:
		r *= 3.0  # largada
	r *= clampf(1.0 + (90.0 - DriverStats.attr(car.driver, "consistency")) * 0.03, 0.6, 1.6)
	return r


## Chance de estouro por volta: 0 acima de 20% de vida, ~2% com 15%, ~7,5% com 10%, 30% com o pneu no fim.
## Atacar pesa mais; atrás do safety car, menos. Pneu de chuva/intermediário também estoura.
func blowout_chance_per_lap(car: CarState) -> float:
	var x := (car.tyre_wear - BLOWOUT_FROM_WEAR) / (1.0 - BLOWOUT_FROM_WEAR)
	if x <= 0.0:
		return 0.0
	var p := BLOWOUT_MAX_PER_LAP * minf(x, 1.4) * minf(x, 1.4)
	p *= PACE_RISK[car.pace_mode]
	if is_neutralized():
		p *= 0.4
	return minf(p, 0.8)


## Volta do líder completada (conta as voltas do safety car).
func on_leader_lap(lap: int) -> void:
	if lap <= _last_leader_lap:
		return
	_last_leader_lap = lap
	if flag == Flag.SC:
		sc_laps_left -= 1
		if sc_laps_left <= 0:
			_go_green("Safety car recolhe — relargada!")


# --- incidentes ----------------------------------------------------------------------

func _incident(car: CarState) -> void:
	var roll := sim.rng.randf()
	if roll < 0.3:
		# travada / escapada: perde pouco tempo, mas o pneu fica "quadrado" (gasta mais dali para a frente)
		var small := sim.rng.randf_range(1.0, 3.0)
		car.stall_s = small
		car.tyre_wear = minf(1.0, car.tyre_wear + sim.rng.randf_range(0.04, 0.1))
		sim.incident.emit(car, "lockup", "%s trava os pneus e escapa (%.1f s)" % [car.display_name(), small])
	elif roll < 0.65:
		var loss := sim.rng.randf_range(3.0, 9.0)
		car.stall_s = loss
		if sim.rng.randf() < 0.4:
			car.damage_wing = minf(1.0, car.damage_wing + sim.rng.randf_range(0.1, 0.35))
		sim.incident.emit(car, "spin", "%s roda e perde %.0f s" % [car.display_name(), loss])
	elif roll < 0.83:
		sim.retire_car(car, "batida")
		sim.incident.emit(car, "crash", "%s bate e abandona!" % car.display_name())
		var neut := sim.rng.randf()
		# bandeira vermelha é rara: batida grave na chuva forte ou engavetamento na largada
		var red_chance := 0.2 if sim.weather.wetness > 0.7 else (0.06 if car.laps_done == 0 else 0.0)
		if sim.rng.randf() < red_chance:
			red_flag("Batida forte de %s" % car.display_name())
		elif neut < 0.55:
			deploy_sc("Batida de %s" % car.display_name())
		elif neut < 0.85:
			deploy_vsc("Batida de %s" % car.display_name())
	else:
		car.stall_s = sim.rng.randf_range(2.0, 4.0)
		if sim.rng.randf() < 0.5:
			car.damage_wing = minf(1.0, car.damage_wing + sim.rng.randf_range(0.3, 0.7))
			sim.incident.emit(car, "damage", "%s sai da pista e danifica a asa" % car.display_name())
		else:
			car.damage_floor = minf(1.0, car.damage_floor + sim.rng.randf_range(0.3, 0.6))
			sim.incident.emit(car, "damage", "%s passa por cima da zebra e danifica o assoalho" % car.display_name())


func _blowout(car: CarState) -> void:
	var life := roundi(maxf(0.0, 1.0 - car.tyre_wear) * 100.0)
	if sim.rng.randf() < BLOWOUT_RETIRE:
		sim.retire_car(car, "pneu estourado")
		sim.incident.emit(car, "blowout", "%s: pneu estoura (%d%% de vida) e destrói a suspensão — abandona!" % [car.display_name(), life])
		if sim.rng.randf() < 0.6:
			deploy_vsc("Detritos do pneu de %s" % car.display_name())
		else:
			deploy_sc("Detritos do pneu de %s" % car.display_name())
		return
	car.punctured = true
	car.stall_s = sim.rng.randf_range(1.5, 3.5)
	car.damage_floor = minf(1.0, car.damage_floor + sim.rng.randf_range(0.1, 0.35))
	if not car.in_pit and not car.pit_requested:
		sim.request_pit(car, StrategyAI.choose_compound(sim, car, sim.total_laps - car.laps_done))
	sim.incident.emit(car, "blowout", "%s: pneu estoura (%d%% de vida)! Volta lenta para o box" % [car.display_name(), life])
	if sim.rng.randf() < 0.25:
		deploy_vsc("Detritos do pneu de %s" % car.display_name())


func _failure(car: CarState) -> void:
	var what: String = ["motor", "câmbio", "sistema híbrido", "freios", "hidráulica"][sim.rng.randi() % 5]
	if car.power_loss_s <= 0.0 and sim.rng.randf() < PARTIAL_FAILURE_SHARE:
		# quebra parcial: segue na prova, mas mais lento até o fim (não se conserta no box)
		car.power_loss_s = sim.rng.randf_range(POWER_LOSS_S.x, POWER_LOSS_S.y)
		sim.incident.emit(car, "issue", "%s com problema de %s: perde %.1f s por volta" % [car.display_name(), what, car.power_loss_s])
		return
	sim.retire_car(car, "quebra: " + what)
	sim.incident.emit(car, "failure", "%s abandona: problema de %s" % [car.display_name(), what])
	if sim.rng.randf() < 0.5:
		deploy_vsc("Carro de %s parado na pista" % car.display_name())


## Chamado em cada tentativa de ultrapassagem (e nos cruzamentos da largada, com `chance_mult` maior). Retorna true se houve toque.
func check_contact(att: CarState, def: CarState, chance_mult: float = 1.0) -> bool:
	if rate <= 0.0:
		return false
	var p := CONTACT_CHANCE * rate * chance_mult * (1.0 + 3.0 * sim.weather.wetness)
	if att.pace_mode == CarState.PaceMode.ATTACK:
		p *= 1.5
	if def.defend_hard:
		p *= 1.6
	if sim.rng.randf() >= p:
		return false
	var victim := att if sim.rng.randf() < 0.6 else def
	sim.incident.emit(att, "contact", "Toque entre %s e %s!" % [att.display_name(), def.display_name()])
	_contact_outcome(victim, def if victim == att else att)
	# o causador fica sob investigação; o veredito sai depois (a chance de punição segue 50%)
	if att.investigation.is_empty():
		var guilty := sim.rng.randf() < 0.5
		var secs := 5.0 if sim.rng.randf() < 0.7 else 10.0
		att.investigation = {"until_s": sim.time_s + sim.rng.randf_range(INVESTIGATION_MIN_S, INVESTIGATION_MAX_S),
			"secs": secs, "reason": "causou colisão com %s" % def.display_name(), "guilty": guilty}
		sim.incident.emit(att, "investigation", "%s sob investigação por toque com %s" % [att.display_name(), def.display_name()])
	return true


## Consequência do toque (pedido de 2026-11-10: batida precisa custar algo). Quase sempre alguém perde tempo ou
## ritmo; de vez em quando há rodada, pneu furado ou batida que tira um (raramente os dois) da prova.
##   leve 38% · danos 27% · rodada 17% · furo 10% · batida forte 8%
func _contact_outcome(victim: CarState, other: CarState) -> void:
	var roll := sim.rng.randf()
	if roll < 0.38:
		victim.stall_s = sim.rng.randf_range(0.8, 2.2)  # escapa da trajetória e perde tempo
		victim.damage_wing = minf(1.0, victim.damage_wing + sim.rng.randf_range(0.08, 0.25))
		if sim.rng.randf() < 0.4:
			other.stall_s = sim.rng.randf_range(0.5, 1.2)
		sim.incident.emit(victim, "lockup", "%s perde tempo no toque (%.1f s)" % [victim.display_name(), victim.stall_s])
	elif roll < 0.65:
		victim.damage_wing = minf(1.0, victim.damage_wing + sim.rng.randf_range(0.3, 0.7))
		victim.stall_s = sim.rng.randf_range(1.0, 3.0)
		var what := "asa"
		if sim.rng.randf() < 0.4:
			victim.damage_floor = minf(1.0, victim.damage_floor + sim.rng.randf_range(0.15, 0.4))
			what = "asa e assoalho"
		if sim.rng.randf() < 0.35:
			other.damage_wing = minf(1.0, other.damage_wing + sim.rng.randf_range(0.1, 0.3))
		sim.incident.emit(victim, "damage", "%s danifica %s no toque" % [victim.display_name(), what])
	elif roll < 0.82:
		var loss := sim.rng.randf_range(4.0, 9.0)
		victim.stall_s = loss
		victim.damage_wing = minf(1.0, victim.damage_wing + sim.rng.randf_range(0.15, 0.45))
		sim.incident.emit(victim, "spin", "%s roda depois do toque e perde %.0f s" % [victim.display_name(), loss])
	elif roll < 0.92:
		victim.punctured = true
		victim.stall_s = sim.rng.randf_range(1.5, 3.0)
		victim.damage_floor = minf(1.0, victim.damage_floor + sim.rng.randf_range(0.1, 0.3))
		if not victim.in_pit and not victim.pit_requested:
			sim.request_pit(victim, StrategyAI.choose_compound(sim, victim, sim.total_laps - victim.laps_done))
		sim.incident.emit(victim, "blowout", "%s fura o pneu no toque! Volta lenta para o box" % victim.display_name())
	else:
		sim.retire_car(victim, "batida")
		sim.incident.emit(victim, "crash", "%s bate forte no toque e abandona!" % victim.display_name())
		if sim.rng.randf() < 0.2 and not other.retired:
			sim.retire_car(other, "batida")
			sim.incident.emit(other, "crash", "%s também fica sem carro!" % other.display_name())
		var neut := sim.rng.randf()
		if neut < 0.5:
			deploy_sc("Batida entre %s e %s" % [victim.display_name(), other.display_name()])
		elif neut < 0.85:
			deploy_vsc("Batida entre %s e %s" % [victim.display_name(), other.display_name()])


func on_pit_stop(car: CarState) -> void:
	if rate > 0.0 and sim.rng.randf() < PIT_SPEEDING_CHANCE:
		give_penalty(car, 5.0, "excesso de velocidade no pit lane")


# --- comissários ---------------------------------------------------------------------

func give_penalty(car: CarState, seconds: float, reason: String) -> void:
	car.penalty_pending_s += seconds
	car.penalties_total_s += seconds
	car.license_points += 2 if seconds <= 5.0 else 3
	sim.penalty.emit(car, "%d s" % int(seconds), reason)


func give_drive_through(car: CarState, reason: String) -> void:
	car.drive_through = true
	car.license_points += 3
	sim.penalty.emit(car, "drive-through", reason)


# --- bandeiras -----------------------------------------------------------------------

func deploy_sc(reason: String) -> void:
	if flag == Flag.SC or flag == Flag.RED:
		return
	flag = Flag.SC
	sc_laps_left = sim.rng.randi_range(3, 5)
	flag_reason = reason
	sc_count += 1
	sim.flag_changed.emit(flag, "SAFETY CAR — " + reason)
	sim.on_neutralization()


func deploy_vsc(reason: String) -> void:
	if flag != Flag.GREEN:
		return
	flag = Flag.VSC
	vsc_time_left = sim.rng.randf_range(60.0, 150.0)
	flag_reason = reason
	vsc_count += 1
	sim.flag_changed.emit(flag, "SAFETY CAR VIRTUAL — " + reason)
	sim.on_neutralization()


## Bandeira vermelha: corrida suspensa, troca de pneus liberada, relargada atrás do safety car.
func red_flag(reason: String) -> void:
	if flag == Flag.RED:
		return
	flag = Flag.RED
	red_count += 1
	flag_reason = reason
	sim.flag_changed.emit(flag, "BANDEIRA VERMELHA — " + reason)
	var waited := 0.0
	while waited < RED_FLAG_SUSPENSION_S:  # o tempo passa para o clima durante a suspensão
		sim.weather.step(10.0, false)
		waited += 10.0
	sim.free_tyre_change()
	flag = Flag.GREEN
	deploy_sc("relargada após bandeira vermelha")
	sc_laps_left = 2


func _go_green(text: String) -> void:
	flag = Flag.GREEN
	flag_reason = ""
	sim.flag_changed.emit(flag, text)
