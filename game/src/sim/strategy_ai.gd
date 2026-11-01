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
	if car.pit_requested or car.in_pit or car.finished:
		return
	var remaining := sim.total_laps - car.laps_done
	if remaining <= 1:
		return
	var rule_ok := sim.tyres.rule_satisfied(car.compounds_used)
	var current_life_left := sim.tyre_laps_left(car)
	var must_stop_for_rule := not rule_ok and remaining <= 3
	var tyres_done := car.tyre_wear >= car.ai_pit_wear
	var can_reach_end := current_life_left >= remaining
	if must_stop_for_rule or (tyres_done and not (can_reach_end and rule_ok)):
		car.pit_compound = choose_compound(sim, car, remaining)
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
