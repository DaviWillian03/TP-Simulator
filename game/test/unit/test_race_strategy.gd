extends GutTest
## Estratégia antes da largada (decisões de 2026-11-08, mockup v22-2).

const OPTS := {"weather": "dry", "incident_rate": 0.0, "player_team": "williams"}
var tyres := TyreModel.new(GameData.tyres())


func _stock() -> Dictionary:
	return {"soft": {"new": 1, "used": 3}, "medium": {"new": 2, "used": 0}, "hard": {"new": 2, "used": 0}, "inter": {"new": 5, "used": 0}, "wet": {"new": 2, "used": 0}}


func test_planos_dos_engenheiros_somam_o_total_e_cumprem_a_regra() -> void:
	var ctx := RaceStrategy.context(71, 1.0, 21.0, false)
	var plans := RaceStrategy.engineer_plans(tyres, ctx, _stock())
	assert_between(plans.size(), 2, 3)
	for p: Dictionary in plans:
		var sum := 0
		var comps := {}
		for st: Dictionary in p["stints"]:
			sum += int(st["laps"])
			comps[st["compound"]] = true
		assert_eq(sum, 71, p["desc"])
		assert_gte(comps.size(), 2, "dois compostos secos")
	assert_true(String(plans[0]["desc"]).ends_with("mais rápida"))


func test_sprint_pode_ser_sem_parada() -> void:
	var ctx := RaceStrategy.context(24, 1.0, 21.0, true)
	var plans := RaceStrategy.engineer_plans(tyres, ctx, _stock())
	assert_eq((plans[0]["stints"] as Array).size(), 1, "sprint curta: sem parada")


func test_editar_voltas_mantem_o_total_e_avisa() -> void:
	var ctx := RaceStrategy.context(71, 1.0, 21.0, false)
	var p: Dictionary = RaceStrategy.engineer_plans(tyres, ctx, _stock())[0]
	var first := int(p["stints"][0]["laps"])
	assert_true(RaceStrategy.adjust_laps(p, 0, 3))
	assert_eq(int(p["stints"][0]["laps"]), first + 3)
	var sum := 0
	for st: Dictionary in p["stints"]:
		sum += int(st["laps"])
	assert_eq(sum, 71)
	for i in (p["stints"] as Array).size():  # tudo duro: quebra a regra (ou o estoque)
		while p["stints"][i]["compound"] != "hard":
			RaceStrategy.cycle_compound(p, i, tyres, _stock())
	assert_ne(RaceStrategy.warning(p, tyres, ctx, _stock()), "")


func test_plano_chega_na_corrida_com_o_pneu_de_largada() -> void:
	var w := WeekendSim.new("interlagos", OPTS.merged({"seed": 6, "format": "race_only"}))
	var plans := w.engineer_strategy()
	assert_true(plans.has("albon"))
	var chosen: Dictionary = plans["albon"][plans["albon"].size() - 1]
	w.strategy = {"albon": chosen}
	var sim := w.make_race()
	for car in sim.cars:
		if car.driver["id"] == "albon":
			assert_eq(car.tyre, String(chosen["stints"][0]["compound"]))
			assert_false(car.player_plan.is_empty())


func test_plano_so_avisa_na_volta_planejada() -> void:
	var w := WeekendSim.new("interlagos", OPTS.merged({"seed": 8, "format": "race_only", "duration_pct": 0.3}))
	var plan: Dictionary = w.engineer_strategy()["albon"][0]
	w.strategy = {"albon": plan}
	var sim := w.make_race({"radio": false})
	var me: CarState = null
	for c in sim.cars:
		if c.driver["id"] == "albon":
			me = c
	var due: Array = []
	sim.plan_stop_due.connect(func(car: CarState, lap: int, _k: String, _f: bool) -> void:
		if car == me:
			due.append([lap, car.laps_done]))
	var first_stop: int = RaceStrategy.stop_laps(plan)[0]
	while me.laps_done < first_stop + 2 and not sim.is_over():
		sim.step()
	assert_eq(due.size(), 1, "avisou uma vez")
	assert_eq(due[0][0], first_stop)
	assert_eq(due[0][1], first_stop - 1, "no começo da volta planejada")
	assert_eq(me.pit_stops, 0, "o plano não para sozinho: só avisa")
	assert_eq(String(sim.player_plan_next(me)["compound"]), String(plan["stints"][1]["compound"]))
