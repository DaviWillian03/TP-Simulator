extends GutTest
## Temporada extra 2012 (2026-11-12): pacote de temporada, KERS por volta, DRS, dois compostos por pista, Mundial por temporada.


func _sim(opts: Dictionary = {}) -> RaceSim:
	var o := {"duration_pct": 0.25, "seed": 4, "weather": "dry", "incident_rate": 0.0, "category": "F1_2012"}
	o.merge(opts, true)
	return RaceSim.new(TrackModel.new(GameData.circuit("interlagos")), TyreModel.new(GameData.tyres()), GameData.teams(), GameData.drivers(), o)


func test_pacote_2026_e_o_mesmo_de_antes() -> void:
	assert_eq(Season.teams("2026").size(), GameData.teams().size())
	assert_eq(Season.drivers("2026").size(), GameData.drivers().size())
	assert_eq(Season.calendar("2026").size(), Campaign.calendar().size())
	assert_eq(Season.category("2026"), "F1")


func test_regras_2012_kers_drs_sem_bateria_de_2026() -> void:
	var sim := _sim()
	assert_true(sim.kers, "KERS por volta")
	assert_true(sim.drs, "DRS")
	assert_eq(sim.energy_k, 0.0, "sem a bateria de 2026")
	var f1 := RaceSim.new(TrackModel.new(GameData.circuit("interlagos")), TyreModel.new(GameData.tyres()), GameData.teams(), GameData.drivers(), {"duration_pct": 0.25, "seed": 4})
	assert_false(f1.kers, "2026 não muda")
	assert_false(f1.drs)


func test_kers_esvazia_com_o_uso_e_enche_na_linha() -> void:
	var sim := _sim()
	var car: CarState = sim.cars[0]
	car.kers_plan = "max"
	car.laps_done = 1
	car.kers = 1.0
	sim._kers_step(car)
	assert_true(car.kers_on)
	assert_lt(car.kers, 1.0, "a barra esvazia a cada uso")
	for i in 200:
		sim._kers_step(car)
	assert_eq(car.kers, 0.0, "acabou a carga da volta")
	assert_false(car.kers_on)
	sim._complete_lap(car, 2, sim.time_s)
	assert_eq(car.kers, 1.0, "volta cheio na linha de chegada")


func test_ritmo_decide_como_o_piloto_gasta_o_kers() -> void:
	var sim := _sim()
	var car: CarState = sim.cars[3]
	for pair: Array in [["safe", "defend"], ["save", "defend"], ["normal", "exits"], ["attack", "attack"], ["push", "max"]]:
		sim.set_mission_base(car, String(pair[0]))
		assert_eq(car.kers_plan, String(pair[1]), "Ritmo %s" % pair[0])
	sim.set_mission_base(car, "safe")
	car.laps_done = 1
	car.kers = 1.0
	sim._kers_step(car)
	assert_false(car.kers_on, "guardando para defender: sem ninguém atrás, não gasta")


func test_dois_compostos_por_pista() -> void:
	var w := WeekendSim.new("spa", {"seed": 2, "player_team": "williams", "category": "F1_2012", "dry_pair": ["medium", "hard"], "weather": "dry"})
	assert_eq(w.tyres.dry_compounds(), ["medium", "hard"] as Array[String])
	var sets: Array = w.tyre_alloc.sets[w.drivers[0]["id"]]
	var n := {}
	for s: Dictionary in sets:
		n[s["compound"]] = int(n.get(s["compound"], 0)) + 1
	assert_eq(int(n.get("medium", 0)), 5, "5 jogos do mais macio")
	assert_eq(int(n.get("hard", 0)), 6, "6 jogos do mais duro")
	assert_false(n.has("soft"))


func test_mundial_2012_usa_o_calendario_e_as_regras_da_temporada() -> void:
	var w := WorldChampionship.start("williams", "2012")
	assert_eq(w.season, 2012)
	assert_eq(w.cal().size(), 20, "os 20 GPs de 2012 (Valência, Coreia e Índia com traçado do OpenStreetMap)")
	assert_eq(String(w.next_round()["id"]), "albertpark")
	var o := w.weekend_options()
	assert_eq(String(o["category"]), "F1_2012")
	assert_eq(o["dry_pair"], ["soft", "medium"])
	var back := WorldChampionship.from_dict(w.to_dict())
	assert_eq(back.season_id, "2012", "o save guarda a temporada")
	assert_eq(WorldChampionship.start("williams").season_id, "2026", "o padrão continua 2026")


func test_grid_2012_equipes_pilotos_e_forma_real() -> void:
	var teams := Season.teams("2012")
	var drivers := Season.drivers("2012")
	assert_eq(teams.size(), 12, "12 equipes de 2012")
	assert_eq(drivers.size(), 24, "grid titular: 24 pilotos")
	var ids := {}
	for t: Dictionary in teams:
		ids[String(t["id"])] = 0
	for d: Dictionary in drivers:
		assert_true(ids.has(String(d["team"])), "%s numa equipe de 2012" % d["id"])
		ids[String(d["team"])] = int(ids[String(d["team"])]) + 1
	for id: String in ids:
		assert_eq(int(ids[id]), 2, "%s com dois pilotos" % id)
	assert_true(ids.has("lotus") and ids.has("hrt") and not ids.has("audi"))
	assert_eq(String(GameData.team_by_id(teams, "mclaren")["color"]).to_lower(), "#a8afb8", "McLaren prateada em 2012, não laranja")
	var rf := Season.real_form("2012")
	assert_eq((rf["base"] as Dictionary).size(), 12)
	assert_gt(float(rf["base"]["redbull"]), float(rf["base"]["hrt"]), "campeã à frente da última")
	for rd: Dictionary in Season.calendar("2012"):
		assert_true((rf["rounds"] as Dictionary).has(String(rd["id"])), "forma real em %s" % rd["id"])


func test_mundial_2012_passa_o_grid_da_epoca_ao_fim_de_semana() -> void:
	var w := WorldChampionship.start("lotus", "2012")
	var o := w.weekend_options()
	assert_eq((o["teams"] as Array).size(), 12)
	var names := (o["drivers"] as Array).map(func(d: Dictionary) -> String: return String(d["id"]))
	assert_has(names, "raikkonen")
	assert_does_not_have(names, "norris")


func test_corrida_2012_roda_com_o_grid_da_epoca() -> void:
	var sim := RaceSim.new(TrackModel.new(GameData.circuit("sepang")), TyreModel.new(GameData.tyres()), Season.teams("2012"), Season.drivers("2012"),
		{"duration_pct": 0.1, "seed": 7, "weather": "dry", "incident_rate": 0.0, "category": "F1_2012"})
	assert_eq(sim.cars.size(), 24)
	var guard := 0
	while not sim.over and guard < 200000:
		sim.step()
		guard += 1
	assert_true(sim.over, "a corrida termina")


func test_emblemas_e_fotos_seguem_a_temporada() -> void:
	TeamEmblems.use_local = false
	TeamEmblems.use_season("2012")
	assert_eq(DriverPhotos.season, "2012")
	assert_not_null(TeamEmblems.get_texture("hrt"), "equipe só de 2012 tem emblema gerado")
	var mc12 := TeamEmblems.get_texture("mclaren")
	TeamEmblems.use_season("2026")
	assert_ne(TeamEmblems.get_texture("mclaren"), mc12, "de volta a 2026, emblema de 2026")
	assert_eq(DriverPhotos.season, "2026")
	assert_true(CarArt.car_texture(GameData.team_by_id(Season.teams("2012"), "mclaren")) != CarArt.car_texture(GameData.team_by_id(GameData.teams(), "mclaren")), "carro com as cores de 2012")
	TeamEmblems.use_local = true


func _weekend_2012(cid: String = "suzuka") -> WeekendSim:
	return WeekendSim.new(cid, {"player_team": "lotus", "duration_pct": 0.25, "seed": 3, "weather": "dry", "incident_rate": 0.0,
		"teams": Season.teams("2012"), "drivers": Season.drivers("2012"), "category": "F1_2012", "dry_pair": ["soft", "hard"]})


func test_top10_larga_com_o_pneu_do_q2() -> void:
	var w := _weekend_2012()
	while w.session_id() != "race":
		w.simulate_current()
	assert_eq(w.start_rule.size(), 10, "os 10 que foram ao Q3")
	var grid: Array = w.grids["race"]
	for did: String in w.start_rule:
		assert_lt(grid.find(did), 10, "%s está no top 10" % did)
	var sim := w.make_race()
	for car in sim.cars:
		var did := String(car.driver["id"])
		if w.start_rule.has(did):
			assert_eq(car.tyre, String(w.start_rule[did]), "%s larga com o pneu do Q2" % did)
	var plans := w.engineer_strategy()
	for did: String in plans:
		if w.start_rule.has(did):
			for plan: Dictionary in plans[did]:
				assert_eq(String(plan["stints"][0]["compound"]), String(w.start_rule[did]), "plano do engenheiro respeita a regra")
				var used := {}
				for st: Dictionary in plan["stints"]:
					used[String(st["compound"])] = true
				assert_gt(used.size(), 1, "continua com dois compostos secos")
	var back := WeekendSim.from_save(w.to_save())
	assert_eq(back.start_rule, w.start_rule, "o autosave guarda a regra")


func test_regra_do_q2_nao_vale_em_2026() -> void:
	var w := WeekendSim.new("suzuka", {"player_team": "williams", "duration_pct": 0.25, "seed": 3, "weather": "dry", "incident_rate": 0.0})
	while w.session_id() != "race":
		w.simulate_current()
	assert_true(w.start_rule.is_empty())


func test_engenheiros_reais_de_2012() -> void:
	Season.active = "2012"
	var sk := Personnel.practice_skills_for(null, "ferrari", ["alonso", "massa"])
	assert_eq(String(sk["alonso"]["engineer_name"]), "Andrea Stella")
	assert_eq(String(sk["massa"]["engineer_name"]), "Rob Smedley")
	var hrt := Personnel.practice_skills_for(null, "hrt", ["delarosa"])
	assert_ne(String(hrt["delarosa"]["engineer_name"]), "", "sem fonte: engenheiro genérico")
	Season.active = Season.DEFAULT
	var now := Personnel.practice_skills_for(null, "ferrari", ["leclerc", "hamilton"])
	assert_ne(String(now["hamilton"]["engineer_name"]), "Andrea Stella", "2026 continua com o pessoal de 2026")


func test_largada_forcada_troca_os_compostos_de_lugar() -> void:
	var plan := {"stints": [{"compound": "hard", "laps": 9}, {"compound": "soft", "laps": 4}]}
	WeekendSim._force_start(plan, "soft")
	assert_eq(String(plan["stints"][0]["compound"]), "soft")
	assert_eq(int(plan["stints"][0]["laps"]), 4, "o stint vai inteiro, com as voltas dele")
	assert_eq(String(plan["stints"][1]["compound"]), "hard")
	assert_eq(int(plan["stints"][1]["laps"]), 9)


func test_pistas_de_valencia_coreia_e_india_rodam() -> void:
	for cid: String in ["valencia", "yeongam", "buddh"]:
		var c := GameData.circuit(cid)
		assert_almost_eq(float(c["length_m"]), {"valencia": 5419.0, "yeongam": 5615.0, "buddh": 5125.0}[cid], 1.0, cid)
		var sim := RaceSim.new(TrackModel.new(c), TyreModel.new(GameData.tyres()), Season.teams("2012"), Season.drivers("2012"),
			{"duration_pct": 0.1, "seed": 2, "weather": "dry", "incident_rate": 0.0, "category": "F1_2012"})
		var guard := 0
		while not sim.over and guard < 200000:
			sim.step()
			guard += 1
		assert_true(sim.over, "corrida termina em %s" % cid)


func test_toda_pista_tem_dois_compostos_em_2012() -> void:
	for f: String in DirAccess.get_files_at("res://data/circuits"):
		if not f.ends_with(".json") or f.begins_with("LICENSE"):
			continue
		var cid := f.get_basename()
		assert_eq(Season.compounds_for("2012", cid).size(), 2, "%s com o par de 2012" % cid)
	assert_eq(Season.compounds_for("2012", "interlagos"), ["medium", "hard"], "Interlagos 2012: médio e duro (real)")
	assert_eq(Season.compounds_for("2012", "lusail"), ["medium", "hard"], "pista de outro ano: par da época")
	assert_true(Season.compounds_for("2026", "interlagos").is_empty(), "2026 não restringe por pista")


func test_supermacio_so_onde_a_pirelli_levou_em_2012() -> void:
	assert_eq(Season.compounds_for("2012", "monaco"), ["supersoft", "soft"], "Mônaco 2012: supermacio + macio")
	assert_eq(Season.compounds_for("2012", "barcelona"), ["soft", "hard"], "Barcelona 2012: macio + duro")
	var w := WeekendSim.new("monaco", {"player_team": "ferrari", "duration_pct": 0.25, "seed": 5, "weather": "dry", "incident_rate": 0.0,
		"teams": Season.teams("2012"), "drivers": Season.drivers("2012"), "category": "F1_2012", "dry_pair": ["supersoft", "soft"]})
	assert_eq(w.tyres.dry_compounds(), ["supersoft", "soft"] as Array[String])
	assert_eq(String(w.tyres.compounds["soft"]["color"]).to_lower(), "#f5c400", "macio amarelo em 2012")
	assert_eq(String(w.tyres.compounds["supersoft"]["color"]).to_lower(), "#e8261c", "supermacio vermelho")
	while w.session_id() != "race":
		w.simulate_current()
	var stock: Dictionary = w.race_tyre_stock(true)["alonso"]
	assert_gt(int(stock["soft"]["new"]) + int(stock["soft"]["used"]), 0, "o treino guarda macio para a corrida")
	for plan: Dictionary in w.engineer_strategy()["alonso"]:
		var used := {}
		for st: Dictionary in plan["stints"]:
			used[String(st["compound"])] = true
		assert_gt(used.size(), 1, "plano com os dois compostos: %s" % plan["desc"])
	var f1 := TyreModel.new(GameData.tyres())
	assert_false(f1.has_compound("supersoft"), "2026 não tem supermacio")
	assert_eq(String(f1.compounds["soft"]["color"]).to_lower(), "#e8261c", "2026: macio continua vermelho")
