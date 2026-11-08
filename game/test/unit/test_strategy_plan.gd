extends GutTest
## Plano de estratégia da IA (auditoria de 2026-11-08): paradas espalhadas pela corrida, variedade de planos e nada de
## parar em massa nas últimas voltas só para cumprir a regra dos compostos.


func _race(circuit: String, pct: float, seed_value: int) -> Array:
	var sim := RaceSim.new(TrackModel.new(GameData.circuit(circuit)), TyreModel.new(GameData.tyres()), GameData.teams(), GameData.drivers(),
		{"duration_pct": pct, "weather": "dry", "incident_rate": 0.0, "seed": seed_value})
	var stops: Array = []
	sim.pit_stop.connect(func(car: CarState, _c: String, _s: float) -> void: stops.append([car.code(), car.laps_done]))
	sim.run_to_end()
	return [sim, stops]


func test_corrida_curta_sem_paradas_em_massa_no_fim() -> void:
	var r := _race("monza", 0.25, 1)
	var sim: RaceSim = r[0]
	var late := (r[1] as Array).filter(func(s: Array) -> bool: return int(s[1]) >= sim.total_laps - 2).size()
	assert_lte(late, 3, "no máximo uns poucos param nas 2 últimas voltas (%d)" % late)
	for car in sim.cars:
		assert_false(car.disqualified, "todos cumprem a regra dos compostos")


func test_janelas_variadas() -> void:
	var r := _race("interlagos", 0.25, 2)
	var laps := {}
	for s: Array in r[1]:
		laps[int(s[1])] = int(laps.get(int(s[1]), 0)) + 1
	assert_gte(laps.size(), 4, "paradas em várias voltas diferentes")
	var top := 0
	for k in laps:
		top = maxi(top, int(laps[k]))
	assert_lt(top, 12, "não para metade do grid na mesma volta")


func test_plano_respeita_o_fim_da_corrida() -> void:
	var sim := RaceSim.new(TrackModel.new(GameData.circuit("suzuka")), TyreModel.new(GameData.tyres()), GameData.teams(), GameData.drivers(),
		{"duration_pct": 1.0, "weather": "dry", "incident_rate": 0.0, "seed": 5})
	var counts := {}
	for car in sim.cars:
		counts[car.ai_plan.size()] = int(counts.get(car.ai_plan.size(), 0)) + 1
		for lap: int in car.ai_plan:
			assert_lte(lap, sim.total_laps - StrategyAI.LATE_LAPS, "nenhuma parada planejada nas últimas voltas")
			assert_gte(lap, 2)
	assert_gte(counts.size(), 2, "estratégias diferentes no grid (%s)" % str(counts))
