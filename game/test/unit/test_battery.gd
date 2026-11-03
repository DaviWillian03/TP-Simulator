extends GutTest
## Bateria: Equilíbrio recarrega devagar, Carregar recarrega rápido, Usar gasta (antes ficava sempre vazia).


func _race() -> RaceSim:
	return RaceSim.new(TrackModel.new(GameData.circuit("monza")), TyreModel.new(GameData.tyres()),
		GameData.teams(), GameData.drivers(), {"weather": "dry", "incident_rate": 0.0, "player_team": "redbull", "radio": false, "seed": 4})


func _mine(sim: RaceSim) -> CarState:
	for c in sim.cars:
		if c.is_player:
			return c
	return null


func _after_laps(mode: int, start: float, laps: float) -> float:
	var sim := _race()
	var car := _mine(sim)
	sim.advance(30.0)
	car.battery = start
	sim.set_energy_mode(car, mode)
	sim.advance(sim.track.base_lap_time_s * laps)
	return car.battery


func test_balanced_slowly_recharges() -> void:
	assert_gt(_after_laps(CarState.EnergyMode.BALANCED, 0.3, 3.0), 0.36, "Equilíbrio recupera carga com o tempo")


func test_harvest_recharges_faster_than_balanced() -> void:
	assert_gt(_after_laps(CarState.EnergyMode.HARVEST, 0.3, 3.0), _after_laps(CarState.EnergyMode.BALANCED, 0.3, 3.0) + 0.15)


func test_deploy_drains() -> void:
	assert_lt(_after_laps(CarState.EnergyMode.DEPLOY, 0.8, 3.0), 0.55, "Usar gasta a bateria")
