class_name StrategyAI
extends RefCounted
## Decisões das equipes controladas pelo computador: pneu de largada, quando parar,
## qual composto colocar e os modos de ritmo/energia durante a corrida.


static func choose_start_compound(grid_position: int, rng: RandomNumberGenerator) -> String:
	var roll := rng.randf()
	if grid_position < 10:
		return "soft" if roll < 0.5 else "medium"
	if roll < 0.2:
		return "soft"
	if roll < 0.8:
		return "medium"
	return "hard"


## Chamado uma vez por volta (no ponto de decisão, antes da entrada do box).
static func decide_pit(sim: RaceSim, car: CarState) -> void:
	if car.pit_requested or car.in_pit or car.finished or car.retired:
		return
	var remaining := sim.total_laps - car.laps_done
	if remaining <= 1:
		return
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
	# 3) desgaste normal e regra dos compostos (só em pista seca)
	if not sim.tyres.is_dry(car.tyre):
		return
	var rule_ok := sim.tyres.rule_satisfied(car.compounds_used)
	var current_life_left := sim.tyre_laps_left(car)
	var must_stop_for_rule := not rule_ok and remaining <= 3
	var tyres_done := car.tyre_wear >= car.ai_pit_wear
	var can_reach_end := current_life_left >= remaining
	if must_stop_for_rule or (tyres_done and not (can_reach_end and rule_ok)):
		car.pit_compound = choose_compound(sim, car, remaining)
		car.pit_requested = true


## Se o tipo de pneu (slick/intermediário/chuva) está errado para a pista e trocar compensa,
## retorna o composto a colocar; senão "". Cada piloto reage com um pouco de atraso/variação.
static func weather_compound(sim: RaceSim, car: CarState, remaining: int) -> String:
	var w := sim.weather.wetness
	var trend := 0.06 if sim.weather.rain_now() > WeatherModel.RAIN_THRESHOLD else -0.04
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
	var worth := car.tyre_wear > 0.35 or car.damage_wing > 0.15 \
		or sim.tyres.tyre_class(best) != sim.tyres.tyre_class(car.tyre) \
		or (not sim.tyres.rule_satisfied(car.compounds_used) and remaining > 3)
	if worth:
		car.pit_compound = best_compound(sim, car, remaining)
		car.pit_requested = true


## Composto mais macio que aguenta até o fim; se nenhum aguentar, o mais duro
## (vai precisar de outra parada). Respeita a regra de compostos obrigatórios.
static func choose_compound(sim: RaceSim, car: CarState, remaining_laps: int) -> String:
	var candidates := sim.tyres.dry_compounds()
	if not sim.tyres.rule_satisfied(car.compounds_used):
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
