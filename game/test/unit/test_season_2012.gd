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
	assert_eq(w.cal().size(), 20, "20 GPs de 2012")
	assert_eq(String(w.next_round()["id"]), "albertpark")
	var o := w.weekend_options()
	assert_eq(String(o["category"]), "F1_2012")
	assert_eq(o["dry_pair"], ["soft", "medium"])
	var back := WorldChampionship.from_dict(w.to_dict())
	assert_eq(back.season_id, "2012", "o save guarda a temporada")
	assert_eq(WorldChampionship.start("williams").season_id, "2026", "o padrão continua 2026")
