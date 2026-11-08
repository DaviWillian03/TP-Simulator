extends GutTest
## Pneus do fim de semana (regra real de 2026, decisão de 2026-11-08).

const OPTS := {"weather": "dry", "incident_rate": 0.0, "player_team": "williams"}


func _dry(a: TyreAllocation, did: String) -> int:
	return a.available(did, true).filter(func(s: Dictionary) -> bool: return s["compound"] in TyreAllocation.DRY).size()


func test_distribuicao_real() -> void:
	var a := TyreAllocation.make(["x"], false)
	var sm := a.summary("x")
	assert_eq(sm["soft"][1], 8)
	assert_eq(sm["medium"][1], 3)
	assert_eq(sm["hard"][1], 2)
	assert_eq(sm["inter"][1], 5)
	assert_eq(sm["wet"][1], 2)
	var sp := TyreAllocation.make(["x"], true).summary("x")
	assert_eq([sp["soft"][1], sp["medium"][1], sp["hard"][1]], [6, 4, 2], "sprint: 12 jogos")
	assert_eq(a.available("x").filter(func(s: Dictionary) -> bool: return s["compound"] == "soft").size(), 7, "1 macio guardado para o Q3")


func test_treino_gasta_e_devolve_dois() -> void:
	var a := TyreAllocation.make(["x"], false)
	a.consume_practice("x", [{"block": "aero", "laps": 5}, {"block": "mech", "laps": 5}, {"block": "race", "laps": 9}, {"block": "quali", "laps": 3}])
	var used := a.available("x", true).filter(func(s: Dictionary) -> bool: return int(s["laps"]) > 0)
	assert_eq(used.size(), 3, "aero e mecânico dividem o mesmo jogo")
	a.return_after_practice("x")
	assert_eq(a.returned_count("x"), 2)
	assert_eq(_dry(a, "x"), 11)


func test_fim_de_semana_deixa_sete_jogos_e_reserva_para_a_corrida() -> void:
	var w := WeekendSim.new("interlagos", OPTS.merged({"seed": 3}))
	for i in 3:
		w.simulate_current()
	assert_eq(w.tyre_alloc.returned_count("albon"), 6, "2 por treino livre")
	assert_eq(_dry(w.tyre_alloc, "albon"), 7)
	var st := w.tyre_alloc.race_stock("albon")
	assert_gte(int(st["medium"]["new"]), 1, "último médio novo guardado")
	assert_gte(int(st["hard"]["new"]), 1, "último duro novo guardado")
	assert_eq(w.tyre_alloc.available("albon", true).filter(func(s: Dictionary) -> bool: return s["q3"]).size(), 1)


func test_macio_do_q3_so_sai_no_q3_e_e_devolvido() -> void:
	var w := WeekendSim.new("interlagos", OPTS.merged({"seed": 5}))
	for i in 3:
		w.simulate_current()
	var q := w.make_quali(true)
	var car: CarState = q.cars[0]
	var q3_id := -1
	for s: Dictionary in w.tyre_alloc.sets[car.driver["id"]]:
		if s["q3"]:
			q3_id = int(s["id"])
	assert_false(q.sets_for(car).any(func(s: Dictionary) -> bool: return int(s["id"]) == q3_id), "fechado no Q1")
	q.run_to_end()
	w.finish_quali(q)
	for c in q.cars:
		var s := w.tyre_alloc.get_set(c.driver["id"], q3_id)
		if q.eliminated_in[c] < 0 and not q.crashed.has(c):
			assert_true(s["returned"], "%s chegou ao Q3 e devolveu" % c.code())
		else:
			assert_false(s["returned"], "%s fica com o macio novo" % c.code())


func test_sprint_devolve_o_jogo_mais_usado() -> void:
	var a := TyreAllocation.make(["x"], true)
	var before := a.returned_count("x")
	a.after_sprint("x", [{"compound": "medium", "laps": 20}])
	assert_eq(a.returned_count("x"), before + 1)
	assert_eq(a.race_stock("x")["medium"]["new"], 3)


func test_atitude_do_jogador_vale_na_volta() -> void:
	var w := WeekendSim.new("interlagos", OPTS.merged({"seed": 2}))
	for i in 3:
		w.simulate_current()
	var q := w.make_quali()
	var me: CarState = null
	for c in q.cars:
		if c.is_player:
			me = c
			break
	q.advance(30.0)
	var used_id := q.best_set(me, "medium")
	assert_true(q.send_out_set(me, used_id, 2, "limit"))
	while q.lap_mode.get(me, "") == "" and not q.is_over():
		q.step()
	assert_eq(q.lap_mode[me], "limit")
	assert_eq(q.laps_left[me], 2)
	assert_eq(String(q.run_tyre[me]["compound"]), "medium")
