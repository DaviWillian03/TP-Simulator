extends GutTest
## Componentes com limite por temporada (motor e câmbio) e punição de grid.

var cp: CarParts


func before_each() -> void:
	cp = CarParts.new()
	cp.setup("williams")


## Usa n unidades de `pid` no carro 0 (cada uma corre uma vez).
func _use(pid: String, n: int) -> void:
	for i in n:
		var u := cp._add_unit(pid, 0, -1)
		cp.install(int(u["uid"]), 0)
		cp.used["0|%s" % pid] = (cp.used.get("0|%s" % pid, []) as Array) + [int(u["uid"])]


func _new_on_car(pid: String) -> void:
	var u := cp._add_unit(pid, 0, -1)
	cp.install(int(u["uid"]), 0)


func test_dentro_do_limite_nao_ha_punicao() -> void:
	_use("pu", 3)
	_new_on_car("pu")
	assert_eq(int(cp.penalty_for(0)["places"]), 0, "4º motor: dentro do limite")


func test_quinto_motor_10_posicoes_e_sexto_5() -> void:
	_use("pu", 4)
	_new_on_car("pu")
	assert_eq(int(cp.penalty_for(0)["places"]), 10)
	_use("pu", 1)
	_new_on_car("pu")
	assert_eq(int(cp.penalty_for(0)["places"]), 5)


func test_motor_e_cambio_juntos_passam_de_15_e_largam_do_fundo() -> void:
	_use("pu", 4)
	_use("gearbox", 4)
	_new_on_car("pu")
	_new_on_car("gearbox")
	var p := cp.penalty_for(0)
	assert_eq(int(p["places"]), 15)
	assert_false(bool(p["back"]))
	_use("gearbox", 1)
	_new_on_car("gearbox")
	_use("pu", 0)
	var p2 := cp.penalty_for(0)
	assert_eq(int(p2["places"]), 15, "10 do motor + 5 do 6º câmbio")


func test_corrida_registra_as_unidades_e_a_virada_zera() -> void:
	var camp := Campaign.new_real("williams")
	var mine: CarParts = camp.my_parts()
	mine.after_race(camp)
	assert_eq(mine.used_count(0, "pu"), 1)
	assert_eq(mine.used_count(1, "gearbox"), 1)
	mine.rollover()
	assert_eq(mine.used_count(0, "pu"), 0)


func test_grid_recuam_e_fundo() -> void:
	var cars: Array = []
	for i in 6:
		var c := CarState.new()
		c.driver = {"id": "d%d" % i}
		cars.append(c)
	var out := RaceSim.apply_grid_penalties(cars, {"d0": {"places": 3, "back": false}, "d1": {"places": 20, "back": true}})
	var ids: Array = out.map(func(c: CarState) -> String: return c.driver["id"])
	assert_eq(ids, ["d2", "d3", "d4", "d0", "d5", "d1"], "P1 com 3 posições larga em 4º; o do fundo vai por último")


func test_ia_no_limite_estica_o_motor() -> void:
	var camp := Campaign.new_real("williams")
	var ai: CarParts = camp.parts["ferrari"]
	for i in 4:
		ai.used["0|pu"] = (ai.used.get("0|pu", []) as Array) + [1000 + i]
	ai.unit_on("pu", 0)["wear"] = 80.0
	var before := int(ai.unit_on("pu", 0)["uid"])
	ai._replace_worn(camp)
	assert_eq(int(ai.unit_on("pu", 0)["uid"]), before, "no limite, só troca perto de quebrar")
	assert_eq(ai.queued("pu").size(), 0)


func test_motor_gasto_quebra_mais() -> void:
	assert_almost_eq(cp.worn_fail_mult(0), 1.0, 0.001)
	cp.unit_on("pu", 0)["wear"] = 100.0
	assert_gt(cp.worn_fail_mult(0), 1.5)
