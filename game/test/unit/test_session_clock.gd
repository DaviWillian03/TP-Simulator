extends GutTest
## O relógio das sessões tem que andar mesmo com quadros curtos (a 60 fps e 4× cada quadro traz só
## ~0,07 s, menos que um passo de 0,5 s). Antes o resto era descartado e a classificação ficava parada.

const DRY := {"weather": "dry", "incident_rate": 0.0, "seed": 5}

var track: TrackModel
var tyres: TyreModel


func before_all() -> void:
	track = TrackModel.new(GameData.circuit("interlagos"))
	tyres = TyreModel.new(GameData.tyres())


func _quali() -> QualiSim:
	return QualiSim.new(track, tyres, GameData.teams(), GameData.drivers(), {}, DRY.merged({"player_team": "redbull"}))


func test_quali_clock_runs_with_short_frames() -> void:
	var q := _quali()
	for i in 600:  # 10 s reais a 60 fps, velocidade 4×
		q.advance((1.0 / 60.0) * 4.0)
	assert_almost_eq(q.seg_time, 40.0, 1.0, "40 s de classificação em 10 s reais a 4×")


func test_quali_same_result_with_small_or_big_steps() -> void:
	var a := _quali()
	var b := _quali()
	for i in 1200:
		a.advance(0.05)
	b.advance(60.0)
	assert_almost_eq(a.seg_time, b.seg_time, 0.6)


func test_practice_clock_runs_with_short_frames() -> void:
	var p := PracticeSession.new(track, tyres, GameData.teams(), GameData.drivers(), {}, {}, DRY)
	var before: float = p.time_s if "time_s" in p else 0.0
	for i in 300:
		p.advance(1.0 / 60.0 * 4.0)
	var after: float = p.time_s if "time_s" in p else 0.0
	assert_gt(after, before + 15.0, "o treino também anda com quadros curtos")


func test_quali_cars_move_around_the_lap_on_track() -> void:
	var q := _quali()
	var car: CarState = null
	for c in q.cars:
		if c.is_player:
			car = c
			break
	assert_false(q.marker_visible(car), "na garagem o carro não aparece na pista")
	assert_true(q.send_out(car, "soft"))
	q.advance(30.0)
	assert_true(q.marker_visible(car), "saiu da garagem: aparece")
	var d1 := q.render_distance(car)
	q.advance(20.0)
	var d2 := q.render_distance(car)
	assert_gt(d2, d1, "o carro avança pela volta de saída")
	assert_lt(d2, track.length_m + 0.1, "e a distância fica dentro de uma volta")
	for i in 100:  # termina saída, lançada e entrada
		q.advance(10.0)
	assert_false(q.marker_visible(car), "voltou à garagem: some da pista")
