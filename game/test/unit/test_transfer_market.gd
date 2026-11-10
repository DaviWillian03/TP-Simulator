extends GutTest
## Mercado vivo: contratos futuros da IA, propostas de rivais pelos seus e pedidos de renovação.

var camp: Campaign


func before_each() -> void:
	camp = Campaign.new_real("williams")
	camp.budget_musd = 150.0


func _run_rounds(from: int, to: int) -> void:
	for r in range(from, to):
		camp.round = r
		camp.day += 14
		camp.personnel.transfers.after_round(camp)


func test_ia_fecha_contratos_futuros_sem_passar_de_dois_pilotos() -> void:
	var m: TransferMarket = camp.personnel.transfers
	_run_rounds(0, 6)
	assert_true(m.future.is_empty(), "o mercado só abre depois de ~30% da temporada")
	_run_rounds(7, 22)
	assert_false(m.decided.is_empty(), "a IA decidiu sobre quem vence o contrato")
	for t: Dictionary in camp.teams():
		assert_lte(m.seats_next(camp, t["id"]), 2, t["id"])
	for id: String in m.future:
		assert_ne(String(m.future[id]["team"]), camp.player_team)


func test_virada_aplica_os_contratos_futuros_e_todos_tem_dois_pilotos() -> void:
	var m: TransferMarket = camp.personnel.transfers
	_run_rounds(7, 22)
	var moves := {}
	for id: String in m.future:
		if int(m.future[id]["start"]) == camp.season + 1:
			moves[id] = m.future[id]["team"]
	camp.round = Campaign.calendar().size()
	camp.personnel.rollover(camp)
	for id: String in moves:
		if camp.personnel.person(id, camp).is_empty():
			continue  # aposentou-se na virada
		var found := ""
		for d: Dictionary in camp.drivers():
			if d["id"] == id:
				found = d["team"]
		assert_eq(found, moves[id], "%s foi para a equipe do contrato futuro" % id)
	for t: Dictionary in camp.teams():
		assert_eq(camp.personnel.player_or_team_seats(camp, t["id"]), 2, t["id"])


func _offer(id: String, ends_now: bool) -> Dictionary:
	var m: TransferMarket = camp.personnel.transfers
	m._add_decision(camp, {"kind": "offer", "id": id, "team": "ferrari", "salary": 9.0, "years": 2, "fee": 6.0, "ends_now": ends_now})
	return m.decisions.back()


func test_proposta_cobrir_aceitar_multa_e_deixar_ir() -> void:
	var p: Personnel = camp.personnel
	var m: TransferMarket = p.transfers
	var ids: Array = p.player_drivers(camp).map(func(d: Dictionary) -> String: return d["id"])
	# cobrir: o salário vai para o da proposta
	var d1 := _offer(ids[0], false)
	m.resolve(camp, int(d1["uid"]), "cover")
	assert_almost_eq(float(p.contract_of(ids[0])["salary"]), 9.0, 0.01)
	assert_false(m.leaving.has(ids[0]))
	# aceitar a multa: entra dinheiro agora e ele sai na virada para a rival
	var before := camp.budget_musd
	var d2 := _offer(ids[1], false)
	m.resolve(camp, int(d2["uid"]), "fee")
	assert_almost_eq(camp.budget_musd, before + 6.0, 0.01)
	assert_eq(String(m.leaving.get(ids[1], "")), "ferrari")
	assert_eq(int(m.future[ids[1]]["start"]), camp.season + 1)


func test_deixar_ir_com_contrato_longo_so_sai_quando_vence() -> void:
	var p: Personnel = camp.personnel
	var m: TransferMarket = p.transfers
	var id: String = p.player_drivers(camp)[0]["id"]
	p.contracts[id]["until"] = camp.season + 2
	var d := _offer(id, false)
	m.resolve(camp, int(d["uid"]), "let_go")
	assert_false(m.leaving.has(id), "cumpre o contrato")
	assert_eq(int(m.future[id]["start"]), camp.season + 3)


func test_renovacao_aceitar_e_recusar() -> void:
	var p: Personnel = camp.personnel
	var m: TransferMarket = p.transfers
	var ids: Array = p.player_drivers(camp).map(func(d: Dictionary) -> String: return d["id"])
	m._add_decision(camp, {"kind": "renewal", "id": ids[0], "team": camp.player_team, "salary": 5.0, "years": 2, "fee": 0.0, "ends_now": true, "asks": 1})
	m.resolve(camp, int(m.decisions.back()["uid"]), "accept")
	assert_eq(int(p.pending[ids[0]]["until"]), camp.season + 2)
	m._add_decision(camp, {"kind": "renewal", "id": ids[1], "team": camp.player_team, "salary": 5.0, "years": 2, "fee": 0.0, "ends_now": true, "asks": 2})
	m.resolve(camp, int(m.decisions.back()["uid"]), "refuse")
	assert_true(camp.events.moods.has(ids[1]), "recusar baixa a confiança do piloto")
	assert_eq(TransferMarket.options_for({"kind": "renewal", "asks": 2}).size(), 2, "na segunda vez não há 'depois'")


func test_sem_resposta_vale_a_opcao_conservadora() -> void:
	var p: Personnel = camp.personnel
	var m: TransferMarket = p.transfers
	var id: String = p.player_drivers(camp)[0]["id"]
	p.contracts[id]["until"] = camp.season
	_offer(id, true)
	camp.day += TransferMarket.DECISION_DAYS + 1
	m._expire(camp)
	assert_true(m.decisions.is_empty())
	assert_eq(String(m.leaving.get(id, "")), "ferrari", "deixou ir na virada")


func test_salvar_e_carregar() -> void:
	_run_rounds(7, 16)
	_offer(camp.personnel.player_drivers(camp)[0]["id"], true)
	var m2 := TransferMarket.from_dict(JSON.parse_string(JSON.stringify(camp.personnel.transfers.to_dict())))
	assert_eq(m2.future.size(), camp.personnel.transfers.future.size())
	assert_eq(m2.decisions.size(), camp.personnel.transfers.decisions.size())
	assert_eq(typeof(m2.decisions[0]["uid"]), TYPE_INT)
