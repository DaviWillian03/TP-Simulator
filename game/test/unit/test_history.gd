extends GutTest
## Histórico da campanha (decisões de 2026-11-08): carreira até 2025 + campanha, campeões e Lendas.

const PATH := "user://test_history.json"


func _driver(c: Campaign, id: String) -> Dictionary:
	for d: Dictionary in c.drivers():
		if d["id"] == id:
			return d
	return {}


func test_carreira_ate_2025_nos_dados() -> void:
	var c := Campaign.new_real("mclaren")
	var ham := c.career_of(_driver(c, "hamilton"))
	assert_eq(int(ham["wins"]), 105)
	assert_eq(int(ham["titles"]), 7)
	assert_eq(int(c.career_of(_driver(c, "antonelli"))["titles"]), 0, "o título de 2026 não conta até 2025")
	assert_eq(int(c.career_of(_driver(c, "lindblad"))["starts"]), 0, "estreante")


func test_corridas_da_campanha_somam_e_o_campeao_entra_no_historico() -> void:
	var c := Campaign.new_feeder("f2_camposracing")  # F1 simulada rápida: dá para rodar a temporada inteira
	var starts0 := int(c.career_of(_driver(c, "norris"))["starts"])
	while not c.season_over():
		c._auto_f1_round()
	assert_eq(int(c.career_of(_driver(c, "norris"))["starts"]), starts0 + 22, "22 GPs (sem sprint)")
	var wins := 0
	for id: String in c.season_log:
		wins += int(c.season_log[id]["wins"])
	assert_eq(wins, 22, "uma vitória por GP")
	c.feeder_close_season()
	assert_eq(c.champions.size(), 1)
	var ch: Dictionary = c.champions[0]
	assert_eq(int(ch["season"]), 2026)
	assert_eq(String(ch["driver"]), String(c.driver_standings()[0][0]))
	var champ := _driver(c, String(ch["driver"]))
	assert_eq(int(c.career_log[ch["driver"]]["titles"]), 1)
	assert_true(int(c.career_of(champ)["titles"]) >= 1)
	assert_true(c.save(PATH))
	var l := Campaign.load_saved(PATH)
	assert_eq(l.champions.size(), 1)
	assert_eq(int(l.career_of(_driver(l, "norris"))["starts"]), starts0 + 22)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func test_aposentado_com_titulo_vira_lenda() -> void:
	var c := Campaign.new_real("mclaren")
	var prev := c.drivers().duplicate(true)
	c.personnel.retired.append({"name": "Lewis Hamilton", "age": 42, "season": c.season, "f1": true, "id": "hamilton"})
	c.personnel.retired.append({"name": "Lance Stroll", "age": 28, "season": c.season, "f1": true, "id": "stroll"})
	c._legends_from_retirements(prev, c.season)
	assert_eq(c.legend_adds.size(), 1, "Stroll não tem título nem 10 vitórias")
	assert_eq(String(c.legend_adds[0]["name"]), "Lewis Hamilton")
	assert_eq(int(c.legend_adds[0]["titles"]), 7)


func test_lendas_nos_dados() -> void:
	var l: Array = GameData.load_json(GameData.DATA_DIR + "legends.json")["legends"]
	assert_eq(l.size(), 15)
	for x: Dictionary in l:
		assert_eq((x["title_years"] as Array).size(), int(x["titles"]), x["name"])
