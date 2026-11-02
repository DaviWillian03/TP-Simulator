extends GutTest
## Atributos dos pilotos: dados, nota geral, efeitos na simulação e evolução por idade.

func _driver(id: String) -> Dictionary:
	for d: Dictionary in GameData.drivers():
		if d["id"] == id:
			return d.duplicate(true)
	return {}


func test_todos_os_pilotos_tem_atributos_validos() -> void:
	for d: Dictionary in GameData.drivers():
		assert_true(DriverStats.has_attrs(d), d["id"])
		for k: String in DriverStats.KEYS:
			assert_between(float(d["attrs"][k]), 50.0, 99.0, "%s %s" % [d["id"], k])
		assert_between(int(d["potential"]), 70, 99)
		assert_almost_eq(float(d["rating"]), DriverStats.overall(d), 1.0, "nota geral = média ponderada: " + d["id"])
		assert_true(String(d["birth"]).length() == 10, d["id"])


func test_pesos_somam_um() -> void:
	var total := 0.0
	for k: String in DriverStats.WEIGHTS:
		total += float(DriverStats.WEIGHTS[k])
	assert_almost_eq(total, 1.0, 0.0001)


func test_titulos_mundiais_conhecidos() -> void:
	assert_eq(int(_driver("hamilton")["titles"]), 7)
	assert_eq(int(_driver("verstappen")["titles"]), 4)
	assert_eq(int(_driver("alonso")["titles"]), 2)
	assert_eq(int(_driver("piastri")["titles"]), 0)


func test_idade_pela_data_de_nascimento() -> void:
	assert_eq(DriverStats.age(_driver("hamilton"), 2026), 41)
	assert_eq(DriverStats.age(_driver("antonelli"), 2026), 20)
	assert_eq(DriverStats.age({}, 2026), 0)


func test_sem_atributos_usa_a_nota_geral() -> void:
	var f := {"id": "x", "rating": 77}
	assert_eq(DriverStats.attr(f, "wet"), 77.0)
	assert_eq(DriverStats.overall(f), 77.0)


func test_ritmo_e_classificacao_mudam_o_tempo_de_volta() -> void:
	var track := TrackModel.new(GameData.circuit("interlagos"))
	var team := GameData.team_by_id(GameData.teams(), "williams")
	var a := _driver("albon")
	var b := a.duplicate(true)
	b["attrs"]["pace"] = int(a["attrs"]["pace"]) - 10
	assert_gt(RaceSim.base_lap_time(track, team, b), RaceSim.base_lap_time(track, team, a))


func _race(driver_override: Callable) -> RaceSim:
	var drivers := GameData.drivers().duplicate(true)
	for d: Dictionary in drivers:
		driver_override.call(d)
	return RaceSim.new(TrackModel.new(GameData.circuit("interlagos")), TyreModel.new(GameData.tyres()), GameData.teams(), drivers,
		{"duration_pct": 0.25, "seed": 4, "weather": "dry", "incident_rate": 0.0})


func test_gestao_de_pneus_reduz_o_desgaste() -> void:
	var good := _race(func(d: Dictionary) -> void: d["attrs"]["tyres"] = 95)
	var bad := _race(func(d: Dictionary) -> void: d["attrs"]["tyres"] = 55)
	for s in 1200:
		good.step()
		bad.step()
	assert_lt(good.cars[5].tyre_wear, bad.cars[5].tyre_wear)


func test_habilidade_na_chuva_ajuda_com_pista_molhada() -> void:
	var good := _race(func(d: Dictionary) -> void: d["attrs"]["wet"] = 99)
	var bad := _race(func(d: Dictionary) -> void: d["attrs"]["wet"] = 60)
	good.weather.wetness = 0.7
	bad.weather.wetness = 0.7
	assert_lt(good.ideal_pace(good.cars[3]), bad.ideal_pace(bad.cars[3]))


func test_evolucao_jovem_sobe_e_veterano_cai() -> void:
	var young := _driver("antonelli")
	young["attrs"]["pace"] = 70
	young["rating"] = roundi(DriverStats.overall(young))
	var before_young := DriverStats.overall(young)
	for y in 3:
		DriverStats.evolve(young, 2027 + y, 1)
	assert_gt(DriverStats.overall(young), before_young)
	var old := _driver("alonso")
	var before_old := DriverStats.overall(old)
	for y in 4:
		DriverStats.evolve(old, 2027 + y, 1)
	assert_lt(DriverStats.overall(old), before_old)
	assert_eq(DriverStats.evolve({"id": "f2", "rating": 70}, 2027, 1), 0, "sem atributos nada muda")


func test_campanha_evolui_o_grid_na_virada() -> void:
	var camp := Campaign.new_real("williams")
	var before: Dictionary = {}
	for d: Dictionary in camp.drivers():
		before[d["id"]] = int(d["rating"])
	camp.start_next_season()
	var changed := 0
	for d: Dictionary in camp.drivers():
		if before.has(d["id"]) and int(d["rating"]) != int(before[d["id"]]):
			changed += 1
	assert_gt(changed, 0, "alguém muda de nota na virada")


func test_dados_pesquisados_de_2026_estao_nos_pilotos_e_equipes() -> void:
	for d: Dictionary in GameData.drivers():
		assert_true(d.has("career"), d["id"])
		assert_gte(int(d["career"]["starts"]), int(d["career"]["wins"]))
		assert_gte(int(d["career"]["podiums"]), int(d["career"]["wins"]))
		if d.get("height_cm", null) != null:
			assert_between(int(d["height_cm"]), 160, 195, d["id"])
		assert_between(int(d["weight_kg"]), 55, 85, d["id"])
	assert_eq(_driver("bearman")["height_cm"], null, "fontes em conflito")
	assert_eq(int(_driver("antonelli")["titles"]), 1)
	assert_eq(int(_driver("hamilton")["career"]["wins"]), 106)
	var mercedes := GameData.team_by_id(GameData.teams(), "mercedes")
	var cad := GameData.team_by_id(GameData.teams(), "cadillac")
	assert_gt(float(mercedes["car_rating"]), float(cad["car_rating"]) + 15.0)
	assert_eq(GameData.team_by_id(GameData.teams(), "astonmartin")["principal"], "Adrian Newey")
