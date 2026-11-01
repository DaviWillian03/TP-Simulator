extends GutTest
## Integridade dos dados de 2026.


func test_grid_2026_tem_11_equipes_e_22_pilotos() -> void:
	assert_eq(GameData.teams().size(), 11)
	assert_eq(GameData.drivers().size(), 22)


func test_cada_equipe_tem_dois_pilotos() -> void:
	var count := {}
	for d: Dictionary in GameData.drivers():
		count[d["team"]] = count.get(d["team"], 0) + 1
	for t: Dictionary in GameData.teams():
		assert_eq(count.get(t["id"], 0), 2, "equipe %s" % t["id"])


func test_numeros_e_codigos_sao_unicos() -> void:
	var numbers := {}
	var codes := {}
	for d: Dictionary in GameData.drivers():
		assert_false(numbers.has(d["number"]), "número repetido %s" % d["number"])
		assert_false(codes.has(d["code"]), "código repetido %s" % d["code"])
		numbers[d["number"]] = true
		codes[d["code"]] = true


func test_tracado_de_interlagos_tem_o_comprimento_oficial() -> void:
	var track := TrackModel.new(GameData.circuit("interlagos"))
	var perimeter := 0.0
	for i in track.points.size():
		perimeter += track.points[i].distance_to(track.points[(i + 1) % track.points.size()])
	assert_almost_eq(perimeter, track.length_m, track.length_m * 0.01)
	assert_eq(track.laps, 71)


func test_position_at_volta_fecha_no_mesmo_ponto() -> void:
	var track := TrackModel.new(GameData.circuit("interlagos"))
	assert_almost_eq(track.position_at(0.0).distance_to(track.position_at(1.0)), 0.0, 0.01)
	assert_true(track.position_at(0.5).distance_to(track.position_at(0.0)) > 100.0)
