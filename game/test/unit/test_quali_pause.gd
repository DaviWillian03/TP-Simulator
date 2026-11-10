extends GutTest
## Classificação: com `pause_between` a sessão para ao fim do Q1/Q2 e só segue com `resume()`.

var track: TrackModel
var tyres: TyreModel


func before_all() -> void:
	track = TrackModel.new(GameData.circuit("interlagos"))
	tyres = TyreModel.new(GameData.tyres())


func _q(pause: bool) -> QualiSim:
	var o := {"weather": "dry", "incident_rate": 0.0, "seed": 4, "player_team": "redbull"}
	var q := QualiSim.new(track, tyres, GameData.teams(), GameData.drivers(), {}, o)
	q.auto_player = true
	q.pause_between = pause
	return q


func _until_waiting(q: QualiSim) -> void:
	var guard := 0
	while not q.waiting and not q.over and guard < 200000:
		q.step()
		guard += 1


func test_sem_pausa_as_partes_seguem_sozinhas() -> void:
	var q := _q(false)
	q.run_to_end()
	assert_true(q.over)
	assert_false(q.waiting)


func test_com_pausa_para_no_fim_do_q1_e_o_relogio_nao_anda() -> void:
	var q := _q(true)
	_until_waiting(q)
	assert_true(q.waiting, "parou depois do Q1")
	assert_eq(q.segment, 0, "ainda é a parte que acabou")
	var t := q.total_time
	for i in 50:
		q.step()
	assert_eq(q.total_time, t, "esperando a confirmação, nada avança")
	var out := 0
	for c in q.cars:
		if q.eliminated_in[c] == 0:
			out += 1
	assert_eq(out, 6, "6 eliminados no Q1 (22 carros)")


func test_resume_comeca_o_q2_e_depois_o_q3_e_o_fim() -> void:
	var q := _q(true)
	_until_waiting(q)
	q.resume()
	assert_false(q.waiting)
	assert_eq(q.segment, 1)
	_until_waiting(q)
	assert_true(q.waiting, "parou depois do Q2")
	q.resume()
	assert_eq(q.segment, 2)
	_until_waiting(q)
	assert_true(q.over, "o Q3 é a última parte: termina sem esperar")
	assert_false(q.waiting)


func test_simular_o_resto_nao_espera_confirmacao() -> void:
	var q := _q(true)
	_until_waiting(q)
	q.run_to_end()
	assert_true(q.over)
