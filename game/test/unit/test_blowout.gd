extends GutTest
## Pneus nas corridas curtas e estouro de pneu (decisão de 2026-11-09).

var tyres: TyreModel


func before_all() -> void:
	tyres = TyreModel.new(GameData.tyres())


func _sim(circuit: String, options: Dictionary = {}) -> RaceSim:
	var opts := {"duration_pct": 0.25, "weather": "dry", "incident_rate": 0.0, "seed": 5}
	opts.merge(options, true)
	return RaceSim.new(TrackModel.new(GameData.circuit(circuit)), TyreModel.new(GameData.tyres()), GameData.teams(), GameData.drivers(), opts)


func test_corrida_curta_gasta_o_pneu_na_proporcao() -> void:
	var short := _sim("interlagos", {"duration_pct": 0.25})
	var full := _sim("interlagos", {"duration_pct": 1.0})
	assert_gt(short.wear_multiplier(), full.wear_multiplier() * 3.0)


func test_pistas_tem_desgaste_diferente() -> void:
	var lusail := TrackModel.new(GameData.circuit("lusail"))
	var monaco := TrackModel.new(GameData.circuit("monaco"))
	assert_gt(lusail.tyre_wear_factor, 1.2)
	assert_lt(monaco.tyre_wear_factor, 0.9)


func test_duas_paradas_competem_em_pista_de_alto_desgaste() -> void:
	# em Barcelona (25%) a melhor estratégia de 1 parada fica a poucos segundos (ou atrás) da melhor de 2
	var sim := _sim("barcelona")
	var ctx := RaceStrategy.context(sim.total_laps, sim.wear_multiplier(), sim.track.pit_lane_loss_s, false, sim.tyre_pace_k)
	var best := {1: INF, 2: INF}
	for a: String in ["soft", "medium", "hard"]:
		for b: String in ["soft", "medium", "hard"]:
			for c: String in ["soft", "medium", "hard"]:
				for l1 in range(2, sim.total_laps - 1):
					if a != b:
						best[1] = minf(best[1], _cost([[a, l1], [b, sim.total_laps - l1]], ctx))
					for l2 in range(2, sim.total_laps - l1 - 1):
						if a != b or b != c:
							best[2] = minf(best[2], _cost([[a, l1], [b, l2], [c, sim.total_laps - l1 - l2]], ctx))
	assert_lt(best[2] - best[1], 8.0, "2 paradas não podem ser muito piores numa pista de alto desgaste")


func _cost(stints: Array, ctx: Dictionary) -> float:
	var out: Array = []
	for s: Array in stints:
		out.append({"compound": s[0], "laps": s[1], "new": true})
	return RaceStrategy.cost(tyres, out, ctx)


func test_estouro_so_com_vinte_por_cento_ou_menos() -> void:
	var sim := _sim("interlagos")
	var car: CarState = sim.cars[0]
	car.pace_mode = CarState.PaceMode.NORMAL
	car.tyre_wear = 0.79
	assert_eq(sim.control.blowout_chance_per_lap(car), 0.0)
	car.tyre_wear = 0.85
	var p15 := sim.control.blowout_chance_per_lap(car)
	car.tyre_wear = 0.92
	var p8 := sim.control.blowout_chance_per_lap(car)
	car.tyre_wear = 1.0
	var p0 := sim.control.blowout_chance_per_lap(car)
	assert_gt(p15, 0.0)
	assert_gt(p8, p15 * 2.0, "quanto menos vida, muito mais chance")
	assert_gt(p0, p8)


func test_pneu_estourado_vai_ao_box_devagar_e_troca() -> void:
	var sim := _sim("interlagos", {"incident_rate": 1.0, "seed": 11})
	var car: CarState = sim.cars[3]
	var clean := sim.ideal_pace(car)
	car.tyre_wear = 0.9
	sim.control._blowout(car)
	if car.retired:
		assert_eq(car.retire_reason, "pneu estourado")
		return
	assert_true(car.punctured)
	assert_true(car.pit_requested, "estouro obriga a parar")
	assert_gt(sim.ideal_pace(car), clean * 1.3, "volta lenta até o box")
	var n := 0
	while car.punctured and n < 100000 and not sim.is_over():
		sim.step()
		n += 1
	assert_false(car.punctured, "a troca de pneus resolve")
	assert_lt(car.tyre_wear, 0.5)


func test_pneu_no_fim_estoura_em_algumas_voltas() -> void:
	var sim := _sim("interlagos", {"incident_rate": 1.0, "seed": 2})
	var car: CarState = sim.cars[5]
	var popped: Array = []  # lambdas capturam por valor: o array guarda o resultado
	sim.incident.connect(func(c: CarState, kind: String, _t: String) -> void:
		if c == car and kind == "blowout":
			popped.append(true))
	for i in 60000:
		if not popped.is_empty() or sim.is_over():
			break
		if not car.punctured:
			car.tyre_wear = maxf(car.tyre_wear, 1.0)
		sim.step()
	assert_false(popped.is_empty(), "pneu sem vida estoura")
