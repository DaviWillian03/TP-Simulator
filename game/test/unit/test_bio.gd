extends GutTest
## Resumos de pilotos e técnicos (só dados existentes) e informações de equipe.

func test_resumo_de_piloto_da_f1_usa_a_carreira() -> void:
	var d := {}
	for dd: Dictionary in GameData.drivers():
		if dd["id"] == "norris":
			d = dd
	var t := Bio.driver(d, 2026)
	assert_string_contains(t, "Reino Unido")
	assert_string_contains(t, "vitórias")
	assert_string_contains(t, "título")


func test_resumo_de_piloto_da_base_cita_categoria_e_equipe() -> void:
	var p := {"name": "X", "nationality": "Brasil", "category": "F2", "series_team": "Invicta Racing", "rating": 78, "birth": "2005-01-01", "potential": 95}
	var t := Bio.driver(p, 2026)
	assert_string_contains(t, "F2")
	assert_string_contains(t, "Invicta Racing")
	assert_string_contains(t, "potencial 95")


func test_resumo_de_tecnico_real() -> void:
	var t := Bio.staff({"role": "director", "nationality": "Reino Unido", "real": true}, "Mercedes")
	assert_string_contains(t, "Diretor técnico da Mercedes")
	assert_string_contains(t, "real")


func test_equipes_tem_sede_fundacao_e_diretor_tecnico() -> void:
	for t: Dictionary in GameData.teams():
		assert_true(t.has("hq"), "%s tem sede" % t["id"])
		assert_gte(int(t.get("founded", 0)), 1950, "%s tem ano" % t["id"])
		assert_not_null(t.get("technical_director"), "%s tem diretor técnico" % t["id"])
		assert_not_null(t.get("principal"), "%s tem chefe de equipe" % t["id"])
