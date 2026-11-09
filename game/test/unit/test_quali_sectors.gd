extends GutTest
## Classificação: setores da volta (roxo = melhor da sessão, verde = melhor do piloto, amarelo = pior).

var track: TrackModel
var tyres: TyreModel


func before_all() -> void:
	track = TrackModel.new(GameData.circuit("interlagos"))
	tyres = TyreModel.new(GameData.tyres())


func _q() -> QualiSim:
	var o := {"weather": "dry", "incident_rate": 0.0, "seed": 4, "player_team": "redbull"}
	return QualiSim.new(track, tyres, GameData.teams(), GameData.drivers(), {}, o)


func test_setores_somam_o_tempo_da_volta_e_acendem_um_a_um() -> void:
	var q := _q()
	var car: CarState = q.cars[0]
	for c in q.cars:
		if c.is_player:
			car = c
	assert_true(q.send_out(car, "soft"))
	var guard := 0
	while q.phase[car] != QualiSim.Phase.FLYING and guard < 5000:
		q.step()
		guard += 1
	var secs: Array = q.lap_sectors[car]
	assert_eq(secs.size(), 3)
	assert_almost_eq(float(secs[0]) + float(secs[1]) + float(secs[2]), float(q.flying_time[car]), 0.001)
	assert_eq(q.sectors_of(car).size(), 0, "nenhum setor fechado no começo da volta")
	var seen := []
	guard = 0
	while q.phase[car] == QualiSim.Phase.FLYING and guard < 5000:
		q.step()
		seen.append(q.sectors_of(car).size())
		guard += 1
	assert_has(seen, 1)
	assert_has(seen, 2)
	assert_eq(q.sectors_of(car).size(), 3, "volta completa: os três setores fechados")


func test_cores_roxo_verde_amarelo() -> void:
	var q := _q()
	var a: CarState = q.cars[0]
	var b: CarState = q.cars[1]
	# setor 1 forçado: a abre a sessão (roxo), depois piora (amarelo); b melhora o próprio sem bater a sessão (verde)
	var colors: Array = []
	q.sector_completed.connect(func(c: CarState, i: int, _t: float, col: String) -> void:
		if i == 0:
			colors.append([c, col]))
	for case: Array in [[a, 25.0], [a, 25.5], [b, 25.2], [b, 24.9]]:
		var car: CarState = case[0]
		q.lap_sectors[car] = [case[1], 30.0, 30.0]
		q.sector_marks[car] = []
		q.phase_start[car] = q.seg_time - 100.0
		q._check_sectors(car, true)
	assert_eq(colors[0][1], "purple", "primeiro tempo da sessão")
	assert_eq(colors[1][1], "yellow", "mais lento que o próprio melhor")
	assert_eq(colors[2][1], "green", "melhor dele, mas não da sessão")
	assert_eq(colors[3][1], "purple", "novo melhor da sessão")
	assert_almost_eq(float(q.session_sector_best[0]), 24.9, 0.001)
