extends GutTest
## Toque entre carros (2026-11-10): sempre custa algo e, de vez em quando, vira rodada, furo ou batida.


func _sim(seed_value: int) -> RaceSim:
	return RaceSim.new(TrackModel.new(GameData.circuit("interlagos")), TyreModel.new(GameData.tyres()),
		GameData.teams(), GameData.drivers(), {"duration_pct": 0.25, "seed": seed_value, "weather": "dry"})


func test_todo_toque_tem_consequencia() -> void:
	var kinds := {}
	for i in 150:
		var sim := _sim(i + 1)
		var seen: Array = []
		sim.incident.connect(func(_c: CarState, k: String, _t: String) -> void: seen.append(k))
		var a: CarState = sim.cars[0]
		var b: CarState = sim.cars[1]
		assert_true(sim.control.check_contact(a, b, 1.0e6))
		var outcome := ""
		for k: String in seen:
			if k in ["lockup", "damage", "spin", "blowout", "crash"]:
				outcome = k
		assert_ne(outcome, "", "o toque gerou um desfecho (sorteio %d)" % i)
		kinds[outcome] = int(kinds.get(outcome, 0)) + 1
		var cost := a.stall_s + b.stall_s + a.damage_wing + b.damage_wing + a.damage_floor + b.damage_floor
		assert_true(cost > 0.0 or a.retired or b.retired or a.punctured or b.punctured, "perdeu tempo, ritmo ou carro")
	assert_gt(int(kinds.get("lockup", 0)), 30, "toque leve é o mais comum")
	for k in ["damage", "spin", "blowout", "crash"]:
		assert_gt(int(kinds.get(k, 0)), 3, "'%s' acontece de vez em quando" % k)
	assert_lt(int(kinds.get("crash", 0)), 40, "abandono por toque é raro")


func test_rodada_e_furo_custam_tempo_de_verdade() -> void:
	var spins := 0
	for i in 200:
		var sim := _sim(100 + i)
		var seen: Array = []
		sim.incident.connect(func(_c: CarState, k: String, _t: String) -> void: seen.append(k))
		sim.control.check_contact(sim.cars[2], sim.cars[3], 1.0e6)
		if "spin" in seen:
			spins += 1
			var worst := maxf(sim.cars[2].stall_s, sim.cars[3].stall_s)
			assert_gte(worst, 4.0, "rodada perde ao menos 4 s")
		if "blowout" in seen:
			assert_true(sim.cars[2].punctured or sim.cars[3].punctured, "pneu furado vai para o box")
	assert_gt(spins, 5)


func test_sem_incidentes_nao_ha_toque() -> void:
	var sim := RaceSim.new(TrackModel.new(GameData.circuit("interlagos")), TyreModel.new(GameData.tyres()),
		GameData.teams(), GameData.drivers(), {"duration_pct": 0.25, "seed": 1, "weather": "dry", "incident_rate": 0.0})
	assert_false(sim.control.check_contact(sim.cars[0], sim.cars[1], 1.0e6))
