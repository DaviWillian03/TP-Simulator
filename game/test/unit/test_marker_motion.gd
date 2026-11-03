extends GutTest
## Animações dos marcadores: ultrapassagem por dentro, rodada saindo e voltando, carro batido parado fora.


func _car(d: float) -> CarState:
	var c := CarState.new()
	c.distance = d
	c.driver = {"id": "x%d" % int(d), "number": 1}
	return c


func test_overtake_slides_attacker_alongside_then_settles() -> void:
	var m := MarkerMotion.new()
	var att := _car(1050.0)  # já trocados pela simulação: o atacante "pulou" 50 m à frente
	var def := _car(1000.0)
	m.on_overtake(att, def)
	assert_lt(m.distance_offset(att), -30.0, "o atacante aparece onde estava")
	assert_gt(m.distance_offset(def), 20.0)
	m.step(MarkerMotion.PASS_TIME / 2.0)
	assert_gt(absf(m.lateral(att)), MarkerMotion.PASS_SIDE_M * 0.8, "no meio da manobra está ao lado (por dentro)")
	m.step(MarkerMotion.PASS_TIME)
	assert_almost_eq(m.lateral(att), 0.0, 0.01, "termina na linha da pista")
	assert_lt(absf(m.distance_offset(att)), 5.0, "e na posição real")


func test_spin_goes_off_track_and_comes_back() -> void:
	var m := MarkerMotion.new()
	var car := _car(500.0)
	car.stall_s = 6.0
	m.on_incident(car, "spin", 14.0, 500.0)
	car.stall_s = 4.0
	assert_gt(absf(m.lateral(car)), 14.0, "fora da pista enquanto perde tempo")
	assert_true(m.is_off_track(car))
	car.stall_s = 0.0
	assert_almost_eq(m.lateral(car), 0.0, 0.01, "voltou para a pista")
	assert_false(m.is_off_track(car))


func test_crashed_car_stays_off_track_then_disappears() -> void:
	var m := MarkerMotion.new()
	var car := _car(800.0)
	m.on_incident(car, "crash", 14.0, 800.0)
	m.step(1.0)
	assert_true(m.is_wreck_visible(car))
	assert_almost_eq(m.wreck_distance(car), 800.0, 0.01, "parado onde bateu")
	assert_gt(absf(m.wreck_lateral(car)), 14.0, "fora da pista")
	m.step(MarkerMotion.WRECK_TIME)
	assert_false(m.is_wreck_visible(car), "some depois de alguns segundos")
