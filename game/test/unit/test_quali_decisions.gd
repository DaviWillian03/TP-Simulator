extends GutTest
## Classificação: plano de 1 ou 2 voltas, volta comprometida (continuar / tentar de novo / box) e objetivo
## da volta escolhido pelo piloto.

var track: TrackModel
var tyres: TyreModel


func before_all() -> void:
	track = TrackModel.new(GameData.circuit("interlagos"))
	tyres = TyreModel.new(GameData.tyres())


func _q(extra: Dictionary = {}) -> QualiSim:
	var o := {"weather": "dry", "incident_rate": 0.0, "seed": 9, "player_team": "redbull"}
	o.merge(extra, true)
	return QualiSim.new(track, tyres, GameData.teams(), GameData.drivers(), {}, o)


func _mine(q: QualiSim) -> CarState:
	for c in q.cars:
		if c.is_player:
			return c
	return null


func _until_flying(q: QualiSim, car: CarState) -> void:
	var guard := 0
	while q.phase[car] != QualiSim.Phase.FLYING and guard < 5000:
		q.step()
		guard += 1


func _force_problem(q: QualiSim, car: CarState, kind: String, valid: bool) -> void:
	q.lap_event[car] = {"kind": kind, "loss": 0.8, "valid": valid, "reveal": 0.3, "revealed": false}


func test_two_lap_plan_does_two_flying_laps_in_one_run() -> void:
	var q := _q()
	var car := _mine(q)
	var laps := [0]
	q.lap_completed.connect(func(c: CarState, _t: float, _v: bool) -> void:
		if c == car:
			laps[0] += 1)
	assert_true(q.send_out(car, "soft", 2))
	var guard := 0
	while q.phase[car] != QualiSim.Phase.IN_LAP and guard < 8000:
		q.step()
		guard += 1
	assert_eq(laps[0], 2, "duas voltas lançadas seguidas, sem voltar à garagem")


func test_compromised_lap_asks_the_player_and_retry_starts_a_new_attempt() -> void:
	var q := _q()
	var car := _mine(q)
	var asked := [false]
	q.decision_needed.connect(func(_d: Dictionary) -> void: asked[0] = true)
	q.send_out(car, "soft")
	_until_flying(q, car)
	_force_problem(q, car, "traffic", true)
	var guard := 0
	while q.pending_for(car).is_empty() and guard < 3000:
		q.step()
		guard += 1
	assert_true(asked[0], "o rádio pergunta no meio da volta")
	var d := q.pending_for(car)
	assert_eq(d["options"].size(), 3)
	q.answer(int(d["id"]), 1)
	assert_eq(q.phase[car], QualiSim.Phase.OUT_LAP, "abortou: volta lenta até a linha")
	assert_false(q.run_tyre[car]["new"], "a nova tentativa é com pneu já usado")
	_until_flying(q, car)
	assert_eq(q.phase[car], QualiSim.Phase.FLYING, "e começa outra volta lançada")


func test_box_answer_goes_to_in_lap() -> void:
	var q := _q()
	var car := _mine(q)
	q.send_out(car, "soft")
	_until_flying(q, car)
	_force_problem(q, car, "limits", false)
	var guard := 0
	while q.pending_for(car).is_empty() and guard < 3000:
		q.step()
		guard += 1
	q.answer(int(q.pending_for(car)["id"]), 2)
	assert_eq(q.phase[car], QualiSim.Phase.IN_LAP)


func test_no_answer_the_driver_decides() -> void:
	var q := _q()
	var car := _mine(q)
	q.send_out(car, "soft")
	_until_flying(q, car)
	_force_problem(q, car, "limits", false)  # volta apagada: o piloto aborta (tenta de novo ou vai ao box)
	for i in int((QualiSim.DECISION_TIMEOUT_S + 60.0) / QualiSim.DT):
		q.step()
		if q.phase[car] != QualiSim.Phase.FLYING:
			break
	assert_true(q.pending_for(car).is_empty(), "a pergunta vence e some")
	assert_ne(q.phase[car], QualiSim.Phase.FLYING, "não insiste numa volta que já vai ser apagada")


func test_driver_picks_the_limit_in_the_pole_fight_and_safe_early_on() -> void:
	var q := _q()
	var ver: CarState = null
	for c in q.cars:
		if c.driver["id"] == "verstappen":
			ver = c
	# início do Q1, sem pressa: um piloto de leitura alta garante o tempo
	var safe := 0
	for i in 40:
		if q.choose_lap_mode(ver) == "safe":
			safe += 1
	assert_gt(safe, 28, "começo de Q1 sem tempo marcado: garantir primeiro")
	# disputa da pole (Q3, entre os primeiros): vai ao limite
	q.segment = 2
	q.best[ver] = [70.0, 70.0, 70.0]
	var limit := 0
	for i in 40:
		if q.choose_lap_mode(ver) == "limit":
			limit += 1
	assert_gt(limit, 28, "na briga pela pole arrisca")


func test_title_contender_avoids_needless_risk() -> void:
	var q := _q({"championship": {"verstappen": 1}})
	var ver: CarState = null
	for c in q.cars:
		if c.driver["id"] == "verstappen":
			ver = c
	q.best[ver] = [72.0, INF, INF]
	q.seg_time = q.segment_length() - 30.0  # última chance
	for c in q.cars:
		if c != ver:
			q.best[c] = [73.0, INF, INF]  # ele está em 1º: classificado com folga
	var safe := 0
	for i in 40:
		if q.choose_lap_mode(ver) == "safe":
			safe += 1
	assert_gt(safe, 28, "quem lidera o campeonato não arrisca à toa no Q1")
