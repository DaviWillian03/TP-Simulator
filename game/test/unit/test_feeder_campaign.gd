extends GutTest
## Campanha na F2/F3 (decisões de 2026-11-08, mockup v23-3).

const PATH := "user://test_feeder_campaign.json"


func test_comeca_na_f2_com_operacao_dinheiro_e_pessoal() -> void:
	var c := Campaign.new_feeder("f2_camposracing")
	assert_true(c.is_feeder())
	assert_eq(c.category(), "F2")
	assert_eq(c.my_feeder_drivers().size(), 2)
	assert_almost_eq(c.feeder.cash, 4.8, 0.01)
	assert_eq(c.feeder.staff.size(), 3, "chefe + 2 engenheiros")
	assert_true(c.feeder_rounds().has(c.round), "a campanha para na próxima etapa da F2")
	var before := c.feeder.car_rating()
	var area := "mech"
	for a: String in FeederCareer.AREAS:
		if int(c.feeder.levels[a]) < FeederCareer.MAX_LEVEL:
			area = a
	assert_ne(c.feeder_upgrade(area), "")
	assert_gt(c.feeder.car_rating(), before)
	assert_eq(float(c.my_series().team("f2_camposracing")["car_rating"]), c.feeder.car_rating(), "a nota vai para o campeonato")


func test_f3_tem_tres_carros_e_tres_engenheiros() -> void:
	var c := Campaign.new_feeder("f3_premaracing")
	assert_eq(c.category(), "F3")
	assert_eq(c.my_feeder_drivers().size(), 3)
	assert_eq(c.feeder.staff_roles(), ["chief", "eng1", "eng2", "eng3"])


func test_etapa_jogada_conta_no_campeonato_e_a_f1_anda_sozinha() -> void:
	var c := Campaign.new_feeder("f2_camposracing")
	var r0 := c.round
	var w := WeekendSim.new(String(c.next_round()["id"]), c.feeder_weekend_options({"weather": "dry", "incident_rate": 0.0}))
	assert_eq(w.category, "F2")
	assert_eq(w.drivers.size(), 22)
	while not w.is_over():
		w.simulate_current()
	var cash0 := c.feeder.cash
	c.record_feeder_weekend(w)
	assert_eq(c.my_series().rounds_done(), 1)
	var total := 0
	for row: Array in c.my_series().team_standings():
		total += int(row[1])
	assert_gt(total, 0, "pontos da etapa no campeonato da F2")
	assert_gt(c.round, r0, "a rodada da F1 passou (simulada)")
	assert_true(c.season_over() or c.feeder_rounds().has(c.round), "parou na próxima etapa da F2")
	assert_ne(c.feeder.cash, cash0, "contas da etapa")
	var f1pts := 0
	for row: Array in c.team_standings():
		f1pts += int(row[1])
	assert_gt(f1pts, 0, "F1 simulada somou pontos")


func test_salva_e_carrega() -> void:
	var c := Campaign.new_feeder("f2_camposracing")
	c.feeder_upgrade("eng")
	assert_true(c.save(PATH))
	var l := Campaign.load_saved(PATH)
	assert_true(l.is_feeder())
	assert_eq(int(l.feeder.levels["eng"]), int(c.feeder.levels["eng"]))
	assert_almost_eq(l.feeder.cash, c.feeder.cash, 0.001)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func test_contratar_engenheiro_do_mercado() -> void:
	var c := Campaign.new_feeder("f2_camposracing")
	var cands := c.feeder.candidates("eng1", c.season)
	assert_eq(cands.size(), 3)
	var best: Dictionary = cands[2]
	assert_true(c.feeder.hire("eng1", best))
	assert_eq(String(c.feeder.staff["eng1"]["name"]), String(best["name"]))


func test_campea_da_f3_sobe_para_a_f2_com_verba() -> void:
	var c := Campaign.new_feeder("f3_premaracing")
	while not c.season_over():
		c._auto_f1_round()
	c.feeder_close_season()
	c.moves["up_f2"] = "f3_premaracing"
	var cash := c.feeder.cash
	c.feeder_start_next_season()
	assert_eq(c.category(), "F2")
	assert_eq(c.feeder.staff_roles().size(), 3, "na F2: chefe + 2 engenheiros")
	assert_eq(c.my_feeder_drivers().size(), 2)
	assert_almost_eq(c.feeder.cash, cash + float(FeederCareer.ECON["F3"]["entry_up"]), 0.01)
	assert_eq(c.season, 2027)


func test_campea_da_f2_entra_na_f1() -> void:
	var c := Campaign.new_feeder("f2_camposracing")
	while not c.season_over():
		c._auto_f1_round()
	c.feeder_close_season()
	var t1 := c.team_standings()
	c.moves["up_f1"] = "f2_camposracing"
	c.moves["down_f2"] = t1[t1.size() - 1][0]
	var cash := c.feeder.cash
	c.feeder_start_next_season()
	assert_false(c.is_feeder(), "agora a campanha é da F1")
	assert_false(c.team().is_empty(), "a equipe está no grid da F1")
	assert_eq(c.team_driver_ids("f2_camposracing").size(), 2)
	assert_gte(c.budget_musd, cash + Campaign.F1_ENTRY_MUSD - 0.5, "caixa da base + verba de entrada")
	var weakest := 999.0
	for t: Dictionary in c.teams():
		if t["id"] != "f2_camposracing":
			weakest = minf(weakest, float(t["car_rating"]))
	assert_lt(c.base_rating, weakest + 3.0, "entra com um dos carros mais fracos")
