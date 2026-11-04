extends GutTest
## Estúdio de design: pintura em camadas (só visual), especiais, capacete e lançamento do carro.

var camp: Campaign


func before_each() -> void:
	camp = Campaign.new_real("williams")


func test_pintura_padrao_com_cores_da_equipe_e_svg_valido() -> void:
	var l := camp.livery
	assert_eq(String(l.main["base"]).to_upper(), String(camp.team()["color"]).to_upper())
	var img := Image.new()
	assert_eq(img.load_svg_from_string(Livery.car_svg(l.main), 1.0), OK, "o SVG da pintura carrega")
	assert_eq(img.get_width(), 1000)


func test_camadas_tem_limite_e_todos_os_tipos_desenham() -> void:
	var p := camp.livery.main
	for k: String in Livery.KINDS:
		assert_true(camp.livery.add_layer(p, k, "#00E1FF"))
	for f: String in Livery.FINISHES:
		p["finish"] = f
		var img := Image.new()
		assert_eq(img.load_svg_from_string(Livery.car_svg(p), 0.5), OK, "acabamento " + f)
	while (p["layers"] as Array).size() < Livery.MAX_LAYERS:
		camp.livery.add_layer(p, "stripe", "#ffffff")
	assert_false(camp.livery.add_layer(p, "stripe", "#ffffff"), "no máximo 12 camadas")


func test_pintura_e_so_visual() -> void:
	var before := float(camp.team()["car_rating"])
	camp.livery.main = Livery.generate("#E10600", "#FFFFFF", 7)
	camp.refresh_rating()
	assert_eq(float(camp.team()["car_rating"]), before)
	assert_true(camp.team().has("livery_paint"), "o carro desenhado usa a pintura")


func test_especial_vale_so_no_gp_marcado() -> void:
	var sp := Livery.generate("#FFD24A", "#11141A", 3)
	camp.livery.specials.append({"name": "Casa", "round": 5, "paint": sp})
	assert_eq(camp.livery.paint_for_round(5), sp)
	assert_eq(camp.livery.paint_for_round(6), camp.livery.main)


func test_lancamento_na_virada_da_nota_e_aplica_efeitos() -> void:
	camp.start_next_season()
	var l: Dictionary = camp.livery.launch
	assert_false(l.is_empty(), "lançamento pendente para a sede")
	assert_between(int(l["stars"]), 1, 5)
	assert_eq(int(l["season"]), camp.season)
	assert_true(camp.livery.specials.is_empty(), "especiais zeram na temporada nova")


func test_capacete_e_salvar_carregar() -> void:
	camp.livery.helmet["pattern"] = "stars"
	var img := Image.new()
	assert_eq(img.load_svg_from_string(Livery.helmet_svg(camp.livery.helmet), 1.0), OK)
	camp.livery.specials.append({"name": "X", "round": 3, "paint": Livery.generate("#111111", "#ffffff", 1)})
	var copy := Campaign.from_dict(JSON.parse_string(JSON.stringify(camp.to_dict())))
	assert_eq(copy.livery.helmet["pattern"], "stars")
	assert_eq(copy.livery.specials.size(), 1)
	assert_eq(int(copy.livery.specials[0]["round"]), 3)
