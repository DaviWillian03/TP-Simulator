extends GutTest
## Fim de semana de GP: acerto (CarSetup), treinos com programas, classificação Q1/Q2/Q3,
## sprint, grid vindo da classificação e pontos.

const DRY := {"weather": "dry", "incident_rate": 0.0}

var track: TrackModel
var tyres: TyreModel
var teams: Array
var drivers: Array


func before_all() -> void:
	track = TrackModel.new(GameData.circuit("interlagos"))
	tyres = TyreModel.new(GameData.tyres())
	teams = GameData.teams()
	drivers = GameData.drivers()


func _opts(extra: Dictionary = {}) -> Dictionary:
	var o := DRY.duplicate()
	o["seed"] = 7
	o.merge(extra, true)
	return o


# --- acerto -----------------------------------------------------------------------------

func test_acerto_perfeito_nao_perde_tempo_e_acerto_ruim_perde() -> void:
	var good := CarSetup.new()
	good.aero = 1.0
	good.mech = 1.0
	good.balance = 1.0
	assert_almost_eq(good.lap_penalty_s(), 0.0, 0.0001)
	var bad := CarSetup.new()
	bad.aero = 0.3
	bad.mech = 0.3
	bad.balance = 0.3
	assert_gt(bad.lap_penalty_s(), 0.5, "acerto ruim custa mais de meio segundo por volta")


func test_acerto_entra_no_ritmo_da_corrida() -> void:
	var good := CarSetup.new()
	good.aero = 1.0
	good.mech = 1.0
	good.balance = 1.0
	var bad := CarSetup.new()
	bad.aero = 0.2
	bad.mech = 0.2
	bad.balance = 0.2
	var id: String = drivers[0]["id"]
	var a := RaceSim.new(track, tyres, teams, drivers, _opts({"setups": {id: good}}))
	var b := RaceSim.new(track, tyres, teams, drivers, _opts({"setups": {id: bad}}))
	assert_lt(a._ideal_lap_time(a.cars[0]), b._ideal_lap_time(b.cars[0]))


func test_piloto_reclama_da_area_mais_longe_do_ideal() -> void:
	var s := CarSetup.new()
	s.aero = 0.9
	s.mech = 0.2
	s.balance = 0.8
	assert_string_contains(s.feedback(), "curvas lentas")


# --- treinos ----------------------------------------------------------------------------

func test_programa_e_cortado_no_que_cabe_em_60_minutos() -> void:
	var prog := PracticeSession.valid_program(["race", "race", "race", "aero", "xyz"])
	assert_eq(prog, ["race", "race", "race"] as Array[String], "3×20 min enchem o treino")
	assert_eq(PracticeSession.valid_program(PracticeSession.DEFAULT_PROGRAM).size(), 4, "o programa padrão cabe")


func test_bloco_de_acerto_aero_melhora_a_aerodinamica() -> void:
	var id: String = drivers[0]["id"]
	var start := CarSetup.new()
	var setups := {id: start}
	var before := start.aero
	var before_mech := start.mech
	var p := PracticeSession.new(track, tyres, teams, drivers, setups, {id: ["aero", "aero", "aero"]}, _opts())
	p.run_to_end()
	assert_gt(start.aero, before + 0.2, "três blocos aero aproximam bem do ideal")
	assert_eq(start.mech, before_mech, "sem bloco mecânico, o mecânico não muda")


func test_treino_marca_tempos_e_tem_classificacao() -> void:
	var p := PracticeSession.new(track, tyres, teams, drivers, {}, {}, _opts())
	p.run_to_end()
	assert_true(p.is_over())
	var order := p.standings()
	assert_eq(order.size(), drivers.size())
	assert_lt(order[0].best_lap_time, INF)
	assert_lte(order[0].best_lap_time, order[1].best_lap_time)


func test_simular_o_mesmo_treino_com_a_mesma_semente_da_o_mesmo_resultado() -> void:
	var a := PracticeSession.new(track, tyres, teams, drivers, {}, {}, _opts())
	var b := PracticeSession.new(track, tyres, teams, drivers, {}, {}, _opts())
	a.run_to_end()
	b.run_to_end()
	assert_eq(a.standings()[0].driver["id"], b.standings()[0].driver["id"])
	assert_almost_eq(a.standings()[0].best_lap_time, b.standings()[0].best_lap_time, 0.0001)


func test_jogar_aos_poucos_e_simular_de_uma_vez_dao_o_mesmo_resultado() -> void:
	var a := PracticeSession.new(track, tyres, teams, drivers, {}, {}, _opts())
	var b := PracticeSession.new(track, tyres, teams, drivers, {}, {}, _opts())
	while not a.is_over():
		a.advance(37.0)
	b.run_to_end()
	assert_almost_eq(a.standings()[3].best_lap_time, b.standings()[3].best_lap_time, 0.0001)


# --- classificação ----------------------------------------------------------------------

func test_classificacao_elimina_6_no_q1_e_6_no_q2() -> void:
	var q := QualiSim.new(track, tyres, teams, drivers, {}, _opts({"auto_player": true}))
	var out_by_segment := [0, 0, 0]
	q.segment_finished.connect(func(seg: int, out: Array) -> void: out_by_segment[seg] = out.size())
	q.run_to_end()
	assert_true(q.is_over())
	assert_eq(out_by_segment, [6, 6, 0])
	var grid := q.grid_ids()
	assert_eq(grid.size(), 22)
	var unique := {}
	for id in grid:
		unique[id] = true
	assert_eq(unique.size(), 22, "cada piloto aparece uma vez no grid")


func test_q3_define_os_10_primeiros_do_grid() -> void:
	var q := QualiSim.new(track, tyres, teams, drivers, {}, _opts({"auto_player": true}))
	q.run_to_end()
	var order := q.standings()
	for i in 10:
		assert_eq(q.eliminated_in[order[i]], -1, "os 10 primeiros chegaram ao Q3")
	for i in range(10, 16):
		assert_eq(q.eliminated_in[order[i]], 1)
	for i in range(16, 22):
		assert_eq(q.eliminated_in[order[i]], 0)
	assert_lte(q.best[order[0]][2], q.best[order[1]][2], "pole = melhor volta do Q3")


func test_carro_do_jogador_parado_na_garagem_fica_sem_tempo_e_cai_no_q1() -> void:
	var q := QualiSim.new(track, tyres, teams, drivers, {}, _opts({"player_team": "mclaren"}))
	q.run_to_end()
	for car in q.cars:
		if car.is_player:
			assert_eq(q.eliminated_in[car], 0)
			assert_eq(q.best[car][0], INF)


func test_jogador_sai_no_fim_e_aproveita_a_pista_melhor() -> void:
	var q := QualiSim.new(track, tyres, teams, drivers, {}, _opts({"player_team": "williams"}))
	var me: CarState = null
	for car in q.cars:
		if car.is_player:
			me = car
			break
	var early := q.track_evolution_s()
	q.advance(q.segment_length() * 0.75)
	assert_gt(q.track_evolution_s(), early + 0.15, "a pista melhora ao longo da parte")
	assert_true(q.send_out(me, "soft"))
	assert_false(q.send_out(me, "soft"), "não sai de novo enquanto está na pista")
	assert_eq(q.status_of(me), "Volta de saída")
	assert_eq(q.new_softs[me], QualiSim.NEW_SOFT_SETS - 1, "gastou um jogo novo de macios")
	while q.segment == 0 and not q.is_over():
		q.step()
	assert_lt(q.best[me][0], INF, "marcou tempo antes do fim do Q1")


func test_volta_lancada_que_comeca_depois_do_relogio_zerar_nao_vale() -> void:
	var q := QualiSim.new(track, tyres, teams, drivers, {}, _opts({"player_team": "williams"}))
	var me: CarState = null
	for car in q.cars:
		if car.is_player:
			me = car
			break
	q.advance(q.segment_length() - 20.0)  # 20 s para o fim: não dá para completar a volta de saída
	assert_true(q.send_out(me, "soft"))
	while q.segment == 0 and not q.is_over():
		q.step()
	assert_eq(q.best[me][0], INF)


func test_bandeira_vermelha_aborta_as_voltas() -> void:
	var events: Array[String] = []
	var found := false
	for s in range(1, 40):
		var q := QualiSim.new(track, tyres, teams, drivers, {}, {"weather": "dry", "incident_rate": 5.0, "seed": s, "auto_player": true})
		q.session_event.connect(func(t: String) -> void: events.append(t))
		q.run_to_end()
		if not q.crashed.is_empty():
			found = true
			assert_eq(q.grid_ids().size(), 22, "mesmo com batida o grid fica completo")
			break
	assert_true(found, "com muitos incidentes alguém bate em alguma das sementes")
	assert_true(events.any(func(t: String) -> bool: return t.begins_with("Bandeira vermelha")))


func test_classificacao_sprint_tem_partes_mais_curtas() -> void:
	var q := QualiSim.new(track, tyres, teams, drivers, {}, _opts({"sprint": true, "auto_player": true}))
	assert_eq(q.segment_name(), "SQ1")
	assert_almost_eq(q.segment_length(), 12.0 * 60.0, 0.01)


# --- corrida: grid, sprint e pontos -----------------------------------------------------

func test_grid_da_classificacao_e_respeitado_na_largada() -> void:
	var ids: Array = []
	for d: Dictionary in drivers:
		ids.append(d["id"])
	ids.reverse()
	var sim := RaceSim.new(track, tyres, teams, drivers, _opts({"grid": ids}))
	for car in sim.cars:
		assert_eq(car.grid_position, ids.find(car.driver["id"]))


func test_sprint_tem_um_terco_da_distancia_e_nao_exige_dois_compostos() -> void:
	var full := RaceSim.new(track, tyres, teams, drivers, _opts())
	var sprint := RaceSim.new(track, tyres, teams, drivers, _opts({"sprint": true}))
	assert_almost_eq(float(sprint.total_laps), full.total_laps / 3.0, 1.0)
	sprint.run_to_end()
	for car in sprint.cars:
		assert_false(car.disqualified, "%s sem DSQ na sprint" % car.code())


func test_pontos_da_corrida_e_da_sprint() -> void:
	assert_eq(RaceSim.points_for(1, false), 25)
	assert_eq(RaceSim.points_for(10, false), 1)
	assert_eq(RaceSim.points_for(11, false), 0)
	assert_eq(RaceSim.points_for(1, true), 8)
	assert_eq(RaceSim.points_for(8, true), 1)
	assert_eq(RaceSim.points_for(9, true), 0)


# --- fim de semana ----------------------------------------------------------------------

func test_fim_de_semana_normal_e_sprint_tem_as_sessoes_certas() -> void:
	var normal := WeekendSim.new("interlagos", {"seed": 1})
	assert_eq(normal.sessions, ["fp1", "fp2", "fp3", "quali", "race"] as Array[String])
	var sprint := WeekendSim.new("shanghai", {"seed": 1})
	assert_eq(sprint.sessions, ["fp1", "sprint_quali", "sprint", "quali", "race"] as Array[String])
	var only := WeekendSim.new("interlagos", {"format": "race_only"})
	assert_eq(only.sessions, ["race"] as Array[String])


func test_clima_seco_zera_a_previsao_e_chuva_garante() -> void:
	assert_eq(WeekendSim.new("interlagos", {"weather": "dry"}).forecast, [0.0, 0.0, 0.0] as Array[float])
	assert_eq(WeekendSim.new("interlagos", {"weather": "rain"}).forecast, [1.0, 1.0, 1.0] as Array[float])


func test_fim_de_semana_sprint_completo_distribui_os_pontos() -> void:
	var w := WeekendSim.new("shanghai", {"seed": 3, "player_team": "williams", "duration_pct": 0.25, "weather": "dry", "incident_rate": 0.0})
	while not w.is_over():
		w.simulate_current()
	var total := 0
	for id: String in w.points:
		total += w.points[id]
	assert_eq(total, 101 + 36, "corrida (25..1) + sprint (8..1), sem abandonos")
	assert_eq(w.grids["race"].size(), 22)
	assert_eq(w.grids["sprint"].size(), 22)
	assert_eq(w.results["race"].size(), 22)
	assert_ne(w.summaries["fp1"], "")


func test_largada_da_corrida_segue_o_grid_da_classificacao() -> void:
	var w := WeekendSim.new("interlagos", {"seed": 5, "duration_pct": 0.25, "weather": "dry", "incident_rate": 0.0})
	while w.session_id() != "race":
		w.simulate_current()
	var sim := w.make_race()
	var pole: String = w.grids["race"][0]
	for car in sim.cars:
		if car.driver["id"] == pole:
			assert_eq(car.grid_position, 0)


func test_treinos_melhoram_o_acerto_ao_longo_do_fim_de_semana() -> void:
	var w := WeekendSim.new("interlagos", {"seed": 2, "weather": "dry", "incident_rate": 0.0})
	var total_before := 0.0
	for id: String in w.setups:
		total_before += (w.setups[id] as CarSetup).lap_penalty_s()
	while w.session_id() != "quali":
		w.simulate_current()
	var total_after := 0.0
	for id: String in w.setups:
		total_after += (w.setups[id] as CarSetup).lap_penalty_s()
	assert_lt(total_after, total_before * 0.5, "três treinos cortam mais da metade da perda pelo acerto")


func test_simular_a_corrida_faz_a_estrategia_parar_tambem_os_carros_do_jogador() -> void:
	var w := WeekendSim.new("interlagos", {"seed": 6, "player_team": "williams", "duration_pct": 0.25,
		"weather": "dry", "incident_rate": 0.0, "format": "race_only"})
	w.simulate_current()
	for id: String in ["albon", "sainz"]:
		assert_lt(w.results["race"].find(id), 20, "%s não pode ser desclassificado por falta de parada" % id)
