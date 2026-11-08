extends GutTest
## F2/F3 jogáveis (decisões de 2026-11-08): formato, pneus, sem bateria, DRS e equilíbrio carro/piloto.

const OPTS := {"weather": "dry", "incident_rate": 0.0}


func test_grid_real_da_f2_e_da_f3() -> void:
	var f2 := CategoryRules.feeder_grid("F2")
	assert_eq(f2["teams"].size(), 11)
	assert_eq(f2["drivers"].size(), 22, "11 equipes × 2")
	var f3 := CategoryRules.feeder_grid("F3")
	assert_eq(f3["teams"].size(), 10)
	assert_between(f3["drivers"].size(), 28, 30, "10 equipes × 3")
	var nums := {}
	for d: Dictionary in f2["drivers"]:
		nums[d["number"]] = true
		assert_eq(String(d["code"]).length(), 3)
	assert_eq(nums.size(), 22, "números únicos")


func test_fim_de_semana_da_f2() -> void:
	var w := WeekendSim.new("silverstone", OPTS.merged({"category": "F2", "seed": 3, "player_team": "f2_camposracing"}))
	assert_eq(w.sessions, ["fp1", "quali", "sprint", "race"] as Array[String])
	assert_eq(w.practice_minutes(), 45)
	assert_eq(w.session_name("race"), "Corrida principal")
	assert_eq(w.tyres.dry_compounds(), ["soft", "hard"] as Array[String], "F2: duro e macio")
	var sm := w.tyre_alloc.summary(w.drivers[0]["id"])
	assert_eq(sm["hard"][1], 3)
	assert_eq(sm["soft"][1], 2)
	assert_false(sm.has("inter"), "F2 não tem intermediário")
	w.simulate_current()  # treino
	assert_eq(w.tyre_alloc.returned_count(w.drivers[0]["id"]), 0, "F2 não devolve jogos no treino")
	w.simulate_current()  # classificação
	var g: Array = w.grids["race"]
	var s: Array = w.grids["sprint"]
	assert_eq(s[0], g[9], "sprint: os 10 primeiros invertidos")
	assert_eq(s[9], g[0])
	assert_eq(s[10], g[10])
	var ctx := w.race_context()
	assert_between(int(ctx["total_laps"]), 18, 24, "sprint ~120 km em Silverstone")
	var sim := w.make_race()
	assert_eq(sim.total_laps, int(ctx["total_laps"]))
	assert_true(sim.drs)
	assert_eq(sim.energy_k, 0.0, "sem bateria")
	w.simulate_current()  # sprint
	w.simulate_current()  # principal
	assert_true(w.is_over())
	var top := 0
	for id: String in w.points:
		top = maxi(top, int(w.points[id]))
	assert_gte(top, 25, "pontos da F2 (principal 25)")


func test_f3_um_composto_sem_parada_obrigatoria() -> void:
	var w := WeekendSim.new("silverstone", OPTS.merged({"category": "F3", "seed": 4}))
	assert_eq(w.tyres.dry_compounds(), ["medium"] as Array[String])
	assert_eq(w.tyre_alloc.summary(w.drivers[0]["id"])["medium"][1], 4)
	for i in 3:
		w.simulate_current()
	var sim := w.make_race()
	assert_true(sim.compound_rule_ok(sim.cars[0]), "F3: sem regra de dois compostos")
	var g: Array = w.grids["race"]
	assert_eq(w.grids["sprint"][0], g[11], "F3: 12 primeiros invertidos")


func test_f2_e_mais_lenta_e_pesa_mais_o_piloto() -> void:
	var track := TrackModel.new(GameData.circuit("silverstone"))
	var f1 := {"car_rating": 80.0}
	var f2 := {"car_rating": 80.0, "category": "F2"}
	var d := {"rating": 80}
	assert_gt(RaceSim.base_lap_time(track, f2, d), RaceSim.base_lap_time(track, f1, d) + 3.0, "F2 bem mais lenta")
	var good := {"rating": 90}
	var gain_f1 := RaceSim.base_lap_time(track, f1, d) - RaceSim.base_lap_time(track, f1, good)
	var gain_f2 := RaceSim.base_lap_time(track, f2, d) - RaceSim.base_lap_time(track, f2, good)
	assert_almost_eq(gain_f2, gain_f1 * 2.0, 0.001, "piloto pesa o dobro na F2")


func test_estrategia_f3_pode_ser_sem_parada() -> void:
	var w := WeekendSim.new("silverstone", OPTS.merged({"category": "F3", "seed": 5, "format": "race_only", "player_team": "f3_premaracing"}))
	var plans := w.engineer_strategy()
	assert_false(plans.is_empty())
	var first: Dictionary = plans.values()[0][0]
	assert_eq((first["stints"] as Array).size(), 1, "F3: sem parada")
