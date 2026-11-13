extends GutTest
## 3 categorias, fase 1: F2 e F3 correm em paralelo; acesso e rebaixamento no fim do ano.

var camp: Campaign


func before_each() -> void:
	camp = Campaign.new_real("williams")


func test_grids_reais_e_vagas_preenchidas() -> void:
	var f2: Series = camp.series["F2"]
	var f3: Series = camp.series["F3"]
	assert_eq(f2.teams.size(), 11)
	assert_eq(f3.teams.size(), 10)
	assert_eq(f2.drivers_on_grid().size(), 22, "F2: 11 × 2")
	assert_eq(f3.drivers_on_grid().size(), 30, "F3: 10 × 3")
	assert_eq(String(f2.seat_of["rafael_camara"]), "f2_invictaracing", "pilotos reais na sua equipe de 2026")


func test_rodada_soma_pontos_de_sprint_e_corrida() -> void:
	var f2: Series = camp.series["F2"]
	var r := f2.simulate_round(f2.rounds[0], camp._prospect_ratings(), 1)
	assert_eq((r["feature"] as Array).size(), 22)
	var total := 0
	for k: String in f2.points_d:
		total += int(f2.points_d[k])
	assert_gt(total, 0)
	assert_lte(total, 101 + 39, "no máximo a soma das tabelas de corrida e sprint")
	assert_eq(f2.driver_results(f2.driver_standings()[0][0]).size(), 1)


func test_categoria_so_corre_nos_fins_de_semana_dela() -> void:
	var f3: Series = camp.series["F3"]
	assert_false(f3.runs_on(1), "Xangai não tem F3")
	camp._run_series(1)
	assert_eq(f3.rounds_done(), 0)
	camp._run_series(0)
	assert_eq(f3.rounds_done(), 1)


func test_acesso_e_rebaixamento_na_virada() -> void:
	for i in Campaign.calendar().size():
		camp._run_series(i)
	camp.team_points = {"mclaren": 300, "cadillac": 1}
	for t: Dictionary in camp.teams():
		if not camp.team_points.has(t["id"]):
			camp.team_points[t["id"]] = 50
	var m := camp.decide_moves()
	assert_eq(m["down_f2"], "cadillac", "último da F1 desce")
	var up_f1: String = m["up_f1"]
	var up_f2: String = m["up_f2"]
	camp.start_next_season()
	assert_true(GameData.team_by_id(camp.teams(), "cadillac").is_empty(), "Cadillac saiu da F1")
	assert_false(GameData.team_by_id(camp.teams(), up_f1).is_empty(), "campeã da F2 entrou")
	assert_eq(camp.teams().size(), 11, "o número de equipes não muda")
	assert_eq(camp.drivers().filter(func(d: Dictionary) -> bool: return d["team"] == up_f1).size(), 2, "sobe com os pilotos")
	assert_false((camp.series["F2"] as Series).team("cadillac").is_empty(), "Cadillac está na F2")
	assert_false((camp.series["F2"] as Series).team(up_f2).is_empty(), "campeã da F3 está na F2")
	assert_eq((camp.series["F2"] as Series).teams.size(), 11)
	assert_eq((camp.series["F3"] as Series).teams.size(), 10)
	var weakest := 999.0
	for t: Dictionary in camp.teams():
		if t["id"] != up_f1:
			weakest = minf(weakest, float(t["car_rating"]))
	assert_lt(float(GameData.team_by_id(camp.teams(), up_f1)["car_rating"]), weakest + 0.5, "entra com o carro mais fraco")
	var copy := Campaign.from_dict(JSON.parse_string(JSON.stringify(camp.to_dict())))
	assert_false(GameData.team_by_id(copy.teams(), up_f1).is_empty(), "salvo e carregado com o grid novo")
	assert_eq((copy.series["F2"] as Series).teams.size(), 11)


func test_sua_equipe_rebaixada_recebe_propostas() -> void:
	camp.team_points = {"williams": 0}
	for t: Dictionary in camp.teams():
		if t["id"] != "williams":
			camp.team_points[t["id"]] = 100
	camp.round = Campaign.calendar().size()
	camp.trust = 80.0
	camp.goal_shift = 20
	var rep := camp.close_season()
	assert_eq(rep["verdict"], "relegated")
	assert_false(camp.job_offers().is_empty())
