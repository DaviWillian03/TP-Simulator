extends GutTest
## Treino simulado + engenheiros de corrida (decisões de 2026-11-08): pesos 35/30/15/20, engenheiros no Pessoal.

const OPTS := {"weather": "dry", "incident_rate": 0.0}


func test_engenheiros_de_2026_viram_cargos_race1_race2() -> void:
	var st := Personnel.team_staff("redbull")
	assert_eq(String(st["race1"]["name"]), "Gianpiero Lambiase", "carro 1 = primeiro piloto da equipe nos dados")
	var williams := Personnel.team_staff("williams")
	assert_true(williams.has("race1") and williams.has("race2"))
	var free := Personnel.staff_pool().filter(func(p: Dictionary) -> bool: return String(p["role"]) in ["race1", "race2"] and not p.has("team"))
	assert_gt(free.size(), 6, "engenheiros genéricos no mercado")


func test_pesos_do_acerto() -> void:
	var drv := {"rating": 95, "attrs": {"consistency": 95, "tyres": 95}}
	var top := PracticeSession.setup_ability({"director": 95, "engineer": 95}, drv)
	assert_almost_eq(float(top["director"]), 0.35, 0.001)
	assert_almost_eq(float(top["engineer"]), 0.30, 0.001)
	assert_almost_eq(float(top["driver"]), 0.15, 0.001)
	assert_almost_eq(float(top["total"]), 0.80, 0.001, "sem a sorte (20%)")
	var low := PracticeSession.setup_ability({"director": 40, "engineer": 40}, {"rating": 40})
	assert_almost_eq(float(low["total"]), 0.0, 0.001)
	assert_gt(PracticeSession.setup_chance({"director": 90, "engineer": 60}, drv), PracticeSession.setup_chance({"director": 60, "engineer": 90}, drv),
		"o diretor pesa mais que o engenheiro")


func test_equipe_tecnica_melhor_acerta_mais() -> void:
	var good := 0.0
	var bad := 0.0
	for s in 6:
		for strong: bool in [true, false]:
			var w := WeekendSim.new("interlagos", OPTS.merged({"seed": 10 + s, "player_team": "williams"}))
			for t: Dictionary in w.teams:
				for id: String in t["practice_skills"]:
					t["practice_skills"][id]["director"] = 95.0 if strong else 45.0
					t["practice_skills"][id]["engineer"] = 95.0 if strong else 45.0
			var p := w.make_practice()
			p.run_to_end()
			var q := 0.0
			for c in p.cars:
				q += (p.setups[c.driver["id"]] as CarSetup).quality()
			if strong:
				good += q
			else:
				bad += q
	assert_gt(good, bad * 1.05, "diretor + engenheiro melhores = acerto melhor")


func test_resumo_do_treino_tem_antes_depois_e_nota() -> void:
	var w := WeekendSim.new("interlagos", OPTS.merged({"player_team": "williams"}))
	var p := w.make_practice()
	p.run_to_end()
	var s := p.summary_of("albon")
	assert_gte(float(s["after"]["aero"]), float(s["before"]["aero"]))
	assert_true(String(s["grade"]) in ["A", "B", "C", "D"])
	assert_eq(String(s["skills"]["engineer_name"]), "James Urwin")
	assert_gt((s["events"] as Array).size(), 0)


func test_campanha_engenheiro_no_pessoal_e_mercado() -> void:
	var camp := Campaign.new_real("williams")
	assert_eq(String(camp.personnel.staff_of(camp, "williams", "race1").get("name", "")), "James Urwin")
	assert_eq(String(camp.personnel.staff_of(camp, "mclaren", "race1").get("name", "")), "Will Joseph")
	var market := camp.personnel.market(camp, "staff", "all", "race2")
	assert_gt(market.size(), 0)
	assert_true(camp.team()["practice_skills"].has("albon"))


func test_save_antigo_sem_engenheiros_so_completa() -> void:
	var camp := Campaign.new_real("williams")
	var director: String = camp.personnel.staff["director"]
	camp.personnel.staff.erase("race1")
	camp.personnel.staff.erase("race2")
	camp.personnel.repair_staff(camp)
	assert_eq(camp.personnel.staff["director"], director, "não mexe no resto")
	assert_ne(String(camp.personnel.staff.get("race1", "")), "")
	assert_ne(String(camp.personnel.staff.get("race2", "")), "")
