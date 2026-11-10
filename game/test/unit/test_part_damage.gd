extends GutTest
## Danos por peça (2026-11-10): 5 peças, só a asa dianteira se conserta, dano permanente soma no ritmo e na chance de quebra.


func _sim(seed_value: int = 1) -> RaceSim:
	return RaceSim.new(TrackModel.new(GameData.circuit("interlagos")), TyreModel.new(GameData.tyres()),
		GameData.teams(), GameData.drivers(), {"duration_pct": 0.25, "seed": seed_value, "weather": "dry"})


func test_cada_peca_custa_tempo_e_soma() -> void:
	var sim := _sim()
	var car: CarState = sim.cars[0]
	var base := sim.ideal_pace(car)
	var total := 0.0
	for p: String in CarState.PARTS:
		car.add_damage(p, 0.5)
		total += 0.5 * float(RaceControl.PART_PENALTY_S[p])
		assert_almost_eq(sim.ideal_pace(car) - base, total, 0.01, "após " + p)
	assert_almost_eq(car.damage_loss_s(), total, 0.001)


func test_estado_da_peca_para_a_tela() -> void:
	var car: CarState = _sim().cars[0]
	for p: String in CarState.PARTS:
		assert_eq(car.part_state(p), 0)
	car.add_damage("floor", 0.2)
	assert_eq(car.part_state("floor"), 1)
	car.add_damage("floor", 0.3)
	assert_eq(car.part_state("floor"), 2)
	car.power_loss_s = 0.5
	assert_eq(car.part_state("pu"), 2, "quebra parcial aparece no motor/câmbio")
	car.add_damage("susp", 5.0)
	assert_eq(car.damage_susp, 1.0, "limite de 100%")


func test_dano_permanente_aumenta_a_chance_de_quebra() -> void:
	var sim := _sim()
	var car: CarState = sim.cars[3]
	var base := sim.control._failure_mult(car)
	car.add_damage("floor", 0.5)
	car.add_damage("susp", 0.5)
	assert_almost_eq(sim.control._failure_mult(car), base * (1.0 + RaceControl.DAMAGE_FAILURE_K * 1.0) / 1.0, 0.0001)
	car.damage_wing = 1.0
	assert_almost_eq(sim.control._failure_mult(car), base * (1.0 + RaceControl.DAMAGE_FAILURE_K * 1.0), 0.0001, "asa dianteira (reparável) não conta")


func test_toque_danifica_a_peca_do_lado_certo() -> void:
	var front := 0
	var rear := 0
	for i in 120:
		var sim := _sim(i + 1)
		var att: CarState = sim.cars[4]
		var def: CarState = sim.cars[5]
		sim.control._contact_outcome(att, def, true)
		sim.control._contact_outcome(def, att, false)
		assert_eq(att.damage_rear, 0.0, "quem ataca não racha a traseira")
		assert_eq(def.damage_wing, 0.0, "quem é atingido não racha a asa dianteira")
		if att.damage_wing > 0.0:
			front += 1
		if def.damage_rear > 0.0:
			rear += 1
	assert_gt(front, 40, "o atacante amassa a frente com frequência")
	assert_gt(rear, 40, "o atingido amassa a traseira com frequência")
