extends GutTest
## Regras da campanha (pedido do usuário, 2026-11-04): número 1 do campeão, números dos novatos e idade mínima na F1.

var camp: Campaign


func before_each() -> void:
	camp = Campaign.new_real("williams")


func _num(id: String) -> int:
	for d: Dictionary in camp.drivers():
		if d["id"] == id:
			return int(d["number"])
	return -1


func test_campeao_usa_o_1_e_norris_volta_ao_4() -> void:
	camp.driver_points = {"verstappen": 400, "norris": 300}
	camp.start_next_season()
	if _num("verstappen") > 0:
		assert_eq(_num("verstappen"), 1, "o campeão usa o 1")
	if _num("norris") > 0:
		assert_eq(_num("norris"), 4, "Norris volta ao número de carreira")
	var ones := camp.drivers().filter(func(d: Dictionary) -> bool: return int(d["number"]) == 1)
	assert_lte(ones.size(), 1, "só um carro com o 1")


func test_campeao_que_ja_tem_o_1_continua() -> void:
	camp.driver_points = {"norris": 400}
	camp.start_next_season()
	if _num("norris") > 0:
		assert_eq(_num("norris"), 1)


func test_numeros_unicos_depois_da_virada() -> void:
	camp.driver_points = {"leclerc": 400}
	camp.start_next_season()
	camp.driver_points = {"russell": 400}
	camp.start_next_season()
	var seen := {}
	for d: Dictionary in camp.drivers():
		assert_false(seen.has(int(d["number"])), "número %d repetido" % int(d["number"]))
		seen[int(d["number"])] = true


func test_novato_herda_numero_de_quem_saiu_ou_mantem_o_da_base() -> void:
	camp.free_number(7)
	var inherited := 0
	var kept := 0
	for i in 20:
		var p := {"id": "teste_%d" % i, "number": 0}
		var n := camp.rookie_number(p)
		assert_ne(n, 1)
		if n == 7:
			inherited += 1
			camp.free_number(7)
		else:
			kept += 1
	assert_gt(inherited, 0, "às vezes herda o número de quem saiu")
	assert_gt(kept, 0, "às vezes mantém o número da categoria")


func test_menor_de_18_nao_vai_para_a_f1() -> void:
	var kid := {"id": "kid", "birth": "%d-06-01" % (camp.season - 16)}
	assert_false(Personnel.old_enough(kid, camp.season + 1), "17 anos na próxima temporada")
	assert_true(Personnel.old_enough({"id": "x", "birth": "%d-01-01" % (camp.season - 20)}, camp.season + 1))
	for p: Dictionary in camp.personnel._available_drivers(camp):
		assert_true(Personnel.old_enough(p, camp.season + 1), "%s não pode estar no mercado da F1" % p.get("name", ""))
