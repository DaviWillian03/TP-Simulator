extends GutTest
## Campeonato Mundial F1: temporada real de 2026, sem desenvolvimento, com limite de motor/câmbio.

const DRY := {"weather": "dry", "incident_rate": 0.0, "duration_pct": 0.1}


func _w() -> WorldChampionship:
	var w := WorldChampionship.start("williams")
	w.seed_base = 11
	w.parts.setup(GameData.teams(), 11)
	return w


func test_notas_vem_da_temporada_real_e_o_grid_e_equilibrado() -> void:
	var w := _w()
	var teams := w.teams_for_gp("austin")
	var by := {}
	for t: Dictionary in teams:
		by[t["id"]] = float(t["car_rating"])
	assert_gt(by["mercedes"], by["cadillac"], "a Mercedes (dominante em 2026) é melhor que a Cadillac")
	assert_gt(by["mercedes"], by["williams"])
	var spread := float(by.values().max()) - float(by.values().min())
	assert_lt(spread, 9.0, "grid mais equilibrado que o real (a diferença antes passava de 11 pontos)")
	assert_gt(spread, 3.0, "mas ainda há favoritos")


func test_pista_com_resultado_real_muda_a_forca_da_equipe() -> void:
	var w := _w()
	var a := {}
	for t: Dictionary in w.teams_for_gp("hungaroring"):  # McLaren venceu na Hungria
		a[t["id"]] = float(t["car_rating"])
	var b := {}
	for t: Dictionary in w.teams_for_gp("lasvegas"):  # corrida ainda sem dado real: só a base
		b[t["id"]] = float(t["car_rating"])
	assert_gt(a["mclaren"], b["mclaren"], "McLaren vai melhor na Hungria que a base")
	assert_true(w.has_real_data("hungaroring"))
	assert_false(w.has_real_data("lasvegas"))


func test_temporada_tem_22_gps_e_pilotos_reais() -> void:
	var w := _w()
	assert_eq(WorldChampionship.calendar().size(), 23, "22 GPs reais + GP da Malásia")
	assert_eq(w.drivers().size(), 22)
	assert_eq(w.next_round()["id"], "albertpark")


func test_fim_de_semana_soma_pontos_e_avanca_a_rodada() -> void:
	var w := _w()
	var opts := w.weekend_options(DRY)
	assert_true(opts["world"])
	var wk := WeekendSim.new(w.next_round()["id"], opts)
	var guard := 0
	while not wk.is_over() and guard < 20:
		wk.simulate_current()
		guard += 1
	assert_true(wk.is_over())
	w.record_weekend(wk)
	assert_eq(w.round, 1)
	var total := 0
	for row: Array in w.driver_standings():
		total += int(row[1])
	assert_gt(total, 0)
	var winner: String = wk.results["race"][0]
	assert_eq(int(w.wins[winner]), 1)
	assert_eq(w.history.size(), 1)


func test_motor_ganha_punicao_so_perto_do_fim_da_temporada() -> void:
	var w := _w()
	var teams := GameData.teams()
	var first_round := {}
	for r in 22:
		for t: Dictionary in teams:
			if int(w.parts.penalty_for(String(t["id"]), 0)["places"]) > 0 and not first_round.has(t["id"]):
				first_round[t["id"]] = r + 1
		w.parts.after_race(teams)
	assert_gt(first_round.size(), 6, "a maioria das equipes passa do limite de 4 motores")
	for id: String in first_round:
		assert_gt(int(first_round[id]), 12, "%s: o 5º motor só aparece no fim do ano" % id)


func test_desgaste_alto_aumenta_chance_de_quebra() -> void:
	var w := _w()
	assert_eq(w.parts.worn_fail_mult("ferrari", 0), 1.0)
	w.parts.unit("ferrari", 0, "pu")["wear"] = 100.0
	assert_gt(w.parts.worn_fail_mult("ferrari", 0), 1.5)


func test_save_e_carga_preservam_tudo() -> void:
	var w := _w()
	w.driver_points["norris"] = 25
	w.round = 4
	w.wins["norris"] = 1
	w.save("user://_wc_test.json")
	var r := WorldChampionship.load_saved("user://_wc_test.json")
	assert_not_null(r)
	assert_eq(r.round, 4)
	assert_eq(int(r.driver_points["norris"]), 25)
	assert_eq(r.player_team, "williams")
	assert_eq(r.parts.state.size(), w.parts.state.size())
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://_wc_test.json"))


func test_gp_da_malasia_e_a_4a_etapa_de_2026() -> void:
	var cal := Campaign.calendar()
	assert_eq(String(cal[3]["id"]), "sepang")
	assert_eq(String(cal[3]["grand_prix"]), "GP da Malásia")
	assert_eq(String(cal[4]["id"]), "miami")


func test_save_antigo_continua_na_mesma_corrida_depois_da_malasia() -> void:
	assert_eq(Campaign.migrate_round({"round": 2}), 2, "antes da Malásia: ela entra no caminho")
	assert_eq(Campaign.migrate_round({"round": 3}), 4, "a próxima era Miami: continua Miami")
	assert_eq(Campaign.migrate_round({"round": 10, "calendar_n": 23}), 10, "save novo não muda")
