extends GutTest
## Classificação (2026-11-18): setores zeram a cada parte (1ª volta = verde), bandeirada depois do fim do tempo e
## comparativo ao vivo contra o pole ou o tempo de corte, como na transmissão.

var track: TrackModel
var tyres: TyreModel


func before_all() -> void:
	track = TrackModel.new(GameData.circuit("interlagos"))
	tyres = TyreModel.new(GameData.tyres())


func _q() -> QualiSim:
	var o := {"weather": "dry", "incident_rate": 0.0, "seed": 9, "player_team": "redbull", "auto_player": true}
	return QualiSim.new(track, tyres, GameData.teams(), GameData.drivers(), {}, o)


func _run_segment(q: QualiSim) -> void:
	var seg := q.segment
	var guard := 0
	while q.segment == seg and not q.is_over() and not q.waiting and guard < 200000:
		q.step()
		guard += 1


func test_primeira_volta_de_cada_parte_e_verde_ou_roxa() -> void:
	var q := _q()
	q.pause_between = true
	var firsts := {}  # car -> cores da 1ª volta lançada da parte atual
	q.sector_completed.connect(func(car: CarState, i: int, _t: float, color: String) -> void:
		var key := "%d|%d" % [q.segment, car.index]
		if not firsts.has(key):  # só o 1º setor da 1ª volta da parte (uma volta abortada já cria a referência)
			firsts[key] = [color])
	for k in 2:
		_run_segment(q)
		if q.waiting:
			q.resume()
	assert_false(firsts.is_empty())
	for key: String in firsts:
		for c: String in firsts[key]:
			assert_ne(c, "yellow", "1ª volta da parte nunca é amarela (%s)" % key)


func test_parte_continua_depois_do_tempo_e_da_bandeirada() -> void:
	var q := _q()
	q.pause_between = true
	var guard := 0
	while q.time_left_s() > 0.0 and guard < 200000:
		q.step()
		guard += 1
	var running := q.still_running()
	assert_true(q.flag_out(), "tempo esgotado e a parte ainda não acabou")
	_run_segment(q)
	assert_gt(q.flagged.size(), 0, "quem cruzou a linha depois do tempo recebeu a bandeirada")
	assert_gte(q.flagged.size(), running, "todos que estavam em volta receberam")


func test_alvo_do_comparativo_e_pole_ou_corte() -> void:
	var q := _q()
	var guard := 0
	while q.time_left_s() > q.segment_length() * 0.35 and guard < 200000:
		q.step()
		guard += 1
	var order := q.segment_order()
	var adv: int = q.segments[q.segment]["advance"]
	var safe: CarState = order[1]
	var out: CarState = order[order.size() - 1]
	var t_safe := q.live_target(safe)
	assert_eq(String(t_safe["kind"]), "pole", "quem está passando de fase compara com o pole")
	assert_eq(t_safe["car"], order[0])
	var t_out := q.live_target(out)
	assert_eq(String(t_out["kind"]), "cut", "quem está na zona de eliminação compara com o corte")
	assert_eq(t_out["car"], order[adv - 1])
	assert_eq(String(q.live_target(order[0])["kind"]), "own", "o pole compara com a própria melhor")
