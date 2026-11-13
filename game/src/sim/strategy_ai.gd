class_name StrategyAI
extends RefCounted
## Decisões das equipes controladas pelo computador: pneu de largada, quando parar,
## qual composto colocar e os modos de ritmo/energia durante a corrida.


static func choose_start_compound(grid_position: int, rng: RandomNumberGenerator, dry: Array = ["soft", "medium", "hard"]) -> String:
	var pick := _start_by_roll(grid_position, rng)
	if dry.has(pick):
		return pick
	return String(dry[mini(grid_position / 8, dry.size() - 1)]) if dry.size() > 0 else pick


static func _start_by_roll(grid_position: int, rng: RandomNumberGenerator) -> String:
	var roll := rng.randf()
	if grid_position < 10:
		return "soft" if roll < 0.5 else "medium"
	if roll < 0.2:
		return "soft"
	if roll < 0.8:
		return "medium"
	return "hard"


const LATE_LAPS := 3  ## nas últimas voltas só para em emergência (pneu errado, asa, regra)
const THREAT_GAP_S := 2.5  ## carro logo atrás a menos disso ameaça com o undercut
const STUCK_GAP_S := 1.2  ## colado atrás sem conseguir passar
const NO_GAMBLE_SC := 0.65  ## acima disso, a equipe tende a ficar fora no safety car para ganhar posição


## Plano de corrida da equipe (decidido na largada): quantas paradas e em que voltas, com variação por equipe —
## uns fazem a estratégia "padrão", outros apostam numa alternativa (uma parada a mais, com pneus mais macios, ou um
## primeiro stint longo). Sorteio próprio (semente da corrida + carro): não muda o resto da simulação.
static func make_plan(sim: RaceSim, car: CarState, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("plan|%d|%d|%s" % [seed_value, car.index, String(car.driver.get("id", ""))])
	car.ai_gamble = rng.randf()
	_plan_from(sim, car, rng, car.laps_done)


static func _plan_from(sim: RaceSim, car: CarState, rng: RandomNumberGenerator, from_lap: int) -> void:
	car.ai_plan.clear()
	car.ai_plan_stops = car.pit_stops
	var total := sim.total_laps
	var remaining := total - from_lap
	if remaining <= LATE_LAPS or not sim.tyres.is_dry(car.tyre):
		return
	var mult := sim.wear_multiplier()
	var life_now := sim.tyre_laps_left(car) if from_lap > 0 else sim.tyres.expected_life_laps(car.tyre, mult)
	var hard: String = sim.tyres.dry_compounds()[sim.tyres.dry_compounds().size() - 1]
	var life_hard := sim.tyres.expected_life_laps(hard, mult)
	var need_rule := not sim.compound_rule_ok(car)
	# mínimo de paradas para chegar ao fim (e cumprir a regra de compostos)
	var stops := 0
	if life_now < remaining:
		stops = 1
		while life_now + life_hard * stops < remaining and stops < 4:
			stops += 1
	elif need_rule:
		stops = 1
	# alternativa: uma parada a mais (pneus mais macios, ataque) para quem aposta, se a corrida for longa o bastante
	if stops >= 1 and remaining >= 18 and car.ai_gamble > 0.78:
		stops += 1
	if stops == 0:
		return
	# janelas: stints quase iguais, o primeiro limitado pela vida do pneu atual, com variação da equipe
	var first_max := maxf(life_now * rng.randf_range(0.82, 0.98), 2.0)
	var last := from_lap
	for i in range(1, stops + 1):
		var ideal := from_lap + remaining * float(i) / float(stops + 1) * 0.92  # um pouco antes do meio: pneu novo vale (undercut)
		var jitter := rng.randfn(0.0, maxf(remaining * 0.07, 0.8))
		if car.ai_gamble > 0.7 and i == 1 and stops == 1:
			jitter += remaining * 0.12  # primeiro stint longo (pneu duro na largada costuma fazer isso)
		var lap := roundi(ideal + jitter)
		if i == 1:
			lap = mini(lap, from_lap + roundi(first_max))
		lap = clampi(lap, last + 2, total - LATE_LAPS - (stops - i))
		car.ai_plan.append(lap)
		last = lap


## Chamado uma vez por volta (no ponto de decisão, antes da entrada do box).
static func decide_pit(sim: RaceSim, car: CarState) -> void:
	if car.pit_requested or car.in_pit or car.finished or car.retired:
		return
	var remaining := sim.total_laps - car.laps_done
	if remaining <= 1:
		return
	if car.ai_plan_stops != car.pit_stops:  # parou fora do plano (clima, safety car, asa): refaz o plano do ponto atual
		var rr := RandomNumberGenerator.new()
		rr.seed = hash("replan|%d|%d|%d" % [car.index, car.laps_done, car.pit_stops])
		_plan_from(sim, car, rr, car.laps_done)
	# 1) clima: o tipo de pneu certo vale mais que tudo
	var weather_choice := weather_compound(sim, car, remaining)
	if weather_choice != "":
		car.pit_compound = weather_choice
		car.pit_requested = true
		return
	# 2) asa muito danificada: parar para trocar
	if car.damage_wing > 0.35 and remaining > 3:
		car.pit_compound = best_compound(sim, car, remaining)
		car.pit_requested = true
		return
	# 3) pista seca: segue o plano; o desgaste só antecipa a parada se o pneu acabar antes da janela
	if not sim.tyres.is_dry(car.tyre):
		return
	var rule_ok := sim.compound_rule_ok(car)
	var current_life_left := sim.tyre_laps_left(car)
	var can_reach_end := current_life_left >= remaining
	var planned := not car.ai_plan.is_empty() and car.laps_done >= car.ai_plan[0]
	if planned and rule_ok and can_reach_end and car.ai_plan.size() == 1 and remaining <= LATE_LAPS + 2:
		car.ai_plan.clear()  # já cumpriu a regra e o pneu aguenta: não vale parar no fim
		planned = false
	# reação aos rivais (só IA): cobrir o undercut de quem vinha logo atrás e parou; ou tentar o undercut em quem
	# segura o carro há algumas voltas. Só perto da janela planejada — ninguém para cedo demais por isso.
	if not car.is_player and not planned and not car.ai_plan.is_empty() and remaining > LATE_LAPS + 2:
		var to_window := car.ai_plan[0] - car.laps_done
		var near := to_window <= maxi(roundi(sim.total_laps * 0.15), 2)
		car.stuck_laps = car.stuck_laps + 1 if car.gap_ahead_s >= 0.0 and car.gap_ahead_s < STUCK_GAP_S else 0
		var rr := RandomNumberGenerator.new()
		rr.seed = hash("react|%d|%d|%d" % [car.index, car.laps_done, sim.options_seed])
		if near and car.last_threat_idx >= 0 and car.last_threat_idx < sim.cars.size():
			var rival: CarState = sim.cars[car.last_threat_idx]
			if rival.last_pit_lap >= car.laps_done - 1 and rival.last_pit_lap >= 0 and rr.randf() < 0.75 - 0.4 * car.ai_gamble:
				planned = true  # cobre o undercut: para já
		if not planned and near and car.stuck_laps >= 2 and rr.randf() < 0.25 + 0.5 * car.ai_gamble:
			planned = true  # tenta o undercut em quem está segurando
	var worn_out := car.tyre_wear >= car.ai_pit_wear + 0.08 and not can_reach_end
	if worn_out and remaining <= LATE_LAPS and car.tyre_wear < 0.95:
		worn_out = false  # nas últimas voltas a parada custa mais que o pneu gasto: segura até o fim
	var must_stop_for_rule := not rule_ok and remaining <= LATE_LAPS
	if planned or worn_out or must_stop_for_rule:
		var stint := remaining
		if car.ai_plan.size() >= 2:
			stint = car.ai_plan[1] - car.laps_done
		car.pit_compound = choose_compound(sim, car, stint)
		car.pit_requested = true
		if not car.ai_plan.is_empty():
			car.ai_plan.remove_at(0)
		car.ai_plan_stops = car.pit_stops + 1  # a parada já faz parte do plano (não precisa refazer)


## Se o tipo de pneu (slick/intermediário/chuva) está errado para a pista e trocar compensa,
## retorna o composto a colocar; senão "". Cada piloto reage com um pouco de atraso/variação.
static func weather_compound(sim: RaceSim, car: CarState, remaining: int) -> String:
	var w := sim.weather.wetness  # a pista agora (o piloto sente)
	# o que vem pela frente: a previsão DA EQUIPE (pode errar, como a do jogador); sem previsão, o clima real
	var fc := sim.forecast_of(String(car.team["id"]))
	var coming := fc.expected_rain(sim.time_s, sim.track.base_lap_time_s) if fc != null else sim.weather.rain_now()
	var trend := 0.06 if coming > WeatherModel.RAIN_THRESHOLD else -0.04
	var judgement := (car.ai_pit_wear - 0.71) * 0.6  # mesmo sorteio do piloto: uns arriscam mais
	var target := sim.tyres.best_for_wetness(clampf(w + trend + judgement, 0.0, 1.0))
	if sim.tyres.tyre_class(target) == sim.tyres.tyre_class(car.tyre):
		return ""
	var gain := sim.tyres.wet_penalty(car.tyre, w) - sim.tyres.wet_penalty(target, w)
	# só troca o tipo de pneu se o ganho nas próximas voltas pagar a parada com folga
	# (evita ficar trocando para lá e para cá perto do ponto de cruzamento)
	if gain * mini(remaining, 6) < sim.track.pit_lane_loss_s * 1.1:
		return ""
	return best_compound(sim, car, remaining) if sim.tyres.is_dry(target) else target


## Melhor composto para a pista agora (chuva → inter/chuva; seco → pela duração restante).
static func best_compound(sim: RaceSim, car: CarState, remaining: int) -> String:
	var best := sim.tyres.best_for_wetness(sim.weather.wetness)
	return best if not sim.tyres.is_dry(best) else choose_compound(sim, car, remaining)


## Safety car/VSC: parada barata. A IA aproveita se o pneu já está gasto, se precisa cumprir
## a regra, trocar o tipo de pneu ou reparar a asa.
static func on_neutralization(sim: RaceSim, car: CarState) -> void:
	if car.pit_requested or car.in_pit:
		return
	var remaining := sim.total_laps - car.laps_done
	if remaining <= 2:
		return
	var best := sim.tyres.best_for_wetness(sim.weather.wetness)
	var wrong_type := sim.tyres.tyre_class(best) != sim.tyres.tyre_class(car.tyre)
	if wrong_type or car.damage_wing > 0.15:
		car.pit_compound = best_compound(sim, car, remaining)
		car.pit_requested = true
		return
	# parada barata: vale se a janela planejada está perto (ou o pneu já está gasto). Quem aposta pode ficar fora para
	# ganhar posição; ninguém para no começo da corrida só para cumprir a regra.
	var near_window := not car.ai_plan.is_empty() and car.ai_plan[0] - car.laps_done <= maxi(roundi(sim.total_laps * 0.2), 2)
	var worth := car.tyre_wear > 0.45 or near_window or (not sim.compound_rule_ok(car) and remaining <= maxi(roundi(sim.total_laps * 0.35), 4))
	if worth and car.ai_gamble > NO_GAMBLE_SC and car.tyre_wear < 0.55:
		worth = false
	if worth and remaining <= LATE_LAPS + 2 and car.tyre_wear < 0.65:
		worth = false  # safety car no fim: só troca quem está com o pneu realmente gasto (perder posição não compensa)
	if worth:
		car.pit_compound = best_compound(sim, car, remaining)
		car.pit_requested = true


## Composto mais macio que aguenta até o fim; se nenhum aguentar, o mais duro
## (vai precisar de outra parada). Respeita a regra de compostos obrigatórios.
static func choose_compound(sim: RaceSim, car: CarState, remaining_laps: int) -> String:
	var candidates := sim.tyres.dry_compounds()
	if not sim.compound_rule_ok(car):
		var filtered: Array[String] = []
		for c in candidates:
			if not car.compounds_used.has(c):
				filtered.append(c)
		if not filtered.is_empty():
			candidates = filtered
	var mult := sim.wear_multiplier()
	for c in candidates:  # do mais macio para o mais duro
		if sim.tyres.expected_life_laps(c, mult) >= remaining_laps:
			return c
	return candidates[candidates.size() - 1]


## Modos de ritmo e energia da IA, reavaliados periodicamente.
static func update_modes(sim: RaceSim, car: CarState) -> void:
	var gap_ahead := sim.gap_to_car_ahead_s(car)
	var attacking := gap_ahead >= 0.0 and gap_ahead < 1.0
	if attacking and car.tyre_wear < 0.6:
		car.pace_mode = CarState.PaceMode.ATTACK
	elif car.tyre_wear > car.ai_pit_wear - 0.05 and (sim.total_laps - car.laps_done) > 2:
		car.pace_mode = CarState.PaceMode.CONSERVE
	else:
		car.pace_mode = CarState.PaceMode.NORMAL
	if car.battery < 0.25:
		car.energy_mode = CarState.EnergyMode.HARVEST
	elif attacking and car.battery > 0.4:
		car.energy_mode = CarState.EnergyMode.DEPLOY
	else:
		car.energy_mode = CarState.EnergyMode.BALANCED
