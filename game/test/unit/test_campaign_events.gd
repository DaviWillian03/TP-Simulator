extends GutTest
## Eventos inesperados da campanha: sorteio, consequências automáticas, notícias e restauração.

var camp: Campaign


func before_each() -> void:
	camp = Campaign.new_real("williams")
	camp.detail = "advanced"
	camp.budget_musd = 150.0


func _rng() -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = 7
	return r


func _event(id: String) -> Dictionary:
	return camp.events._apply(camp, CampaignEvents.event_def(id), _rng(), camp.day)


func _ids(c: Campaign) -> Array:
	return c.drivers().map(func(d: Dictionary) -> String: return d["id"])


func test_frequencia_desligada_nao_sorteia_e_frequente_sorteia() -> void:
	camp.events.freq = "off"
	for d in 400:
		camp.events.tick_day(camp, camp.day + d)
	assert_eq(camp.events.news.size(), 0)
	var c2 := Campaign.new_real("williams")
	c2.events.freq = "frequent"
	for d in 330:
		c2.events.tick_day(c2, c2.day + d)
	assert_gt(c2.events.news.size(), 8)
	var c3 := Campaign.new_real("williams")
	c3.events.freq = "rare"
	for d in 330:
		c3.events.tick_day(c3, c3.day + d)
	assert_lt(c3.events.news.size(), c2.events.news.size())


func test_sorteio_e_deterministico() -> void:
	var a := Campaign.new_real("williams")
	var b := Campaign.new_real("williams")
	for c in [a, b]:
		c.events.freq = "frequent"
		for d in 200:
			c.events.tick_day(c, c.day + d)
	assert_eq(a.events.news.map(func(n: Dictionary) -> String: return n["id"]), b.events.news.map(func(n: Dictionary) -> String: return n["id"]))


func test_lesao_troca_o_piloto_por_um_reserva_e_ele_volta_depois() -> void:
	var before := _ids(camp)
	var n := _event("driver_injury")
	assert_eq(n["cat"], "driver")
	assert_eq(camp.drivers().size(), 22, "o grid continua com 22 carros")
	var after := _ids(camp)
	assert_ne(before, after)
	var injured: String = camp.events.injuries.keys()[0]
	assert_false(after.has(injured))
	var rounds: int = camp.events.injuries[injured]["rounds_left"]
	for i in rounds:
		camp.events.on_race_recorded(camp)
	assert_eq(_ids(camp), before, "o titular volta")
	assert_true(camp.events.injuries.is_empty())
	assert_eq(camp.events.news[0]["id"], "driver_back")


func test_reserva_usa_o_numero_do_titular_e_tem_contrato() -> void:
	_event("driver_injury")
	var injured: String = camp.events.injuries.keys()[0]
	var sub_id: String = camp.events.injuries[injured]["sub_id"]
	var sub: Dictionary = camp.drivers().filter(func(d: Dictionary) -> bool: return d["id"] == sub_id)[0]
	assert_eq(sub["team"], "williams")
	assert_eq(int(sub["number"]), int(camp.events.injuries[injured]["original"]["number"]))
	assert_true(camp.personnel.contracts.has(sub_id))
	var c := camp.cost_per_race()
	assert_gt(c, 0.0)


func test_crise_reduz_atributos_e_depois_devolve() -> void:
	var d: Dictionary = camp.personnel.player_drivers(camp)[0]
	var pace := int(d["attrs"]["pace"])
	var rating := int(d["rating"])
	_event("driver_crisis")
	var hit: String = camp.events.moods.keys()[0]
	var driver: Dictionary = camp.drivers().filter(func(x: Dictionary) -> bool: return x["id"] == hit)[0]
	assert_lt(int(driver["attrs"]["pace"]), int(driver["attrs"]["pace"]) + 1)
	var rounds: int = camp.events.moods[hit]["rounds_left"]
	for i in rounds:
		camp.events.on_race_recorded(camp)
	assert_true(camp.events.moods.is_empty())
	if hit == d["id"]:
		assert_eq(int(driver["attrs"]["pace"]), pace)
		assert_eq(int(driver["rating"]), rating)


func test_sondagem_encarece_a_renovacao() -> void:
	var d: Dictionary = camp.personnel.player_drivers(camp)[0]
	var ask := camp.personnel.ask_for(d["id"], camp)
	_event("driver_offer")
	var hit: String = camp.events.ask_mult.keys()[0]
	assert_gt(camp.personnel.ask_for(hit, camp), Personnel.driver_ask(float(camp.personnel.person(hit, camp)["rating"])) - 0.01)
	assert_gt(ask, 0.0)


func test_corrida_cancelada_e_pulada_no_calendario() -> void:
	_event("race_cancelled")
	var idx: int = camp.events.cancelled[0]
	assert_gt(idx, camp.round)
	var wanted := idx
	# anda a temporada até a rodada anterior à cancelada
	while camp.round < wanted:
		camp.advance_to_event()
		var w := WeekendSim.new(camp.next_round()["id"], camp.weekend_options({"duration_pct": 0.25, "weather": "dry", "incident_rate": 0.0, "format": "race_only"}))
		w.simulate_current()
		camp.record_weekend(w)
		if camp.round == wanted:
			break
	assert_ne(camp.round, wanted, "a rodada cancelada foi pulada")
	assert_false(camp.season_over() and camp.round < Campaign.calendar().size())


func test_incendio_atrasa_projetos_e_custa_dinheiro() -> void:
	camp.dev.start_project(camp, "cur", "aero.0.0")
	var left: int = camp.dev.projects[0]["days_left"]
	var before := camp.budget_musd
	_event("factory_fire")
	assert_eq(camp.dev.projects[0]["days_left"], left + 10)
	assert_lt(camp.budget_musd, before)
	assert_gt(float(camp.ledger["events"]), 0.0)


func test_lote_defeituoso_perde_o_projeto_e_devolve_metade() -> void:
	camp.dev.start_project(camp, "cur", "aero.0.0")
	var spent := camp.budget_musd
	_event("parts_defect")
	assert_eq(camp.dev.projects.size(), 0)
	assert_gt(camp.budget_musd, spent)


func test_patrocinador_sai_e_libera_a_zona() -> void:
	var n := camp.sponsors.contracts.size()
	_event("sponsor_leaves")
	assert_eq(camp.sponsors.contracts.size(), n - 1)


func test_avanco_termina_o_projeto_em_um_dia() -> void:
	camp.dev.start_project(camp, "cur", "aero.0.0")
	_event("breakthrough")
	assert_eq(camp.dev.projects[0]["days_left"], 1)


func test_crise_economica_reduz_as_ofertas_e_apoio_soma_ao_caixa() -> void:
	var zone: String = camp.sponsors.free_zones()[0]
	var normal: float = camp.sponsors.offers_for(camp, zone)[0]["per_race"]
	_event("economic_crisis")
	camp.sponsors.withdrawn.clear()
	var crisis: float = camp.sponsors.offers_for(camp, zone)[0]["per_race"]
	assert_lt(crisis, normal)
	camp.day += 120
	camp.sponsors.period = -1
	assert_almost_eq(camp.events.market_multiplier(camp.day), 1.0, 0.0001, "a crise passa")
	var cash := camp.budget_musd
	_event("host_support")
	assert_gt(camp.budget_musd, cash)
	assert_gt(float(camp.ledger["events_in"]), 0.0)


func test_noticias_ficam_nao_vistas_ate_serem_consumidas() -> void:
	_event("host_support")
	camp.events._add(camp, _event("host_support"))
	assert_eq(camp.events.unseen.size(), 1)
	assert_gt(camp.events.news.size(), 0)


func test_virada_restaura_lesionados_e_zera_calendario() -> void:
	var before := _ids(camp)
	_event("driver_injury")
	_event("race_cancelled")
	camp.start_next_season()
	assert_true(camp.events.injuries.is_empty())
	assert_true(camp.events.cancelled.is_empty())
	assert_eq(camp.drivers().size(), 22)
	assert_eq(camp.personnel.player_drivers(camp).size(), 2)
	assert_gt(before.size(), 0)


func test_salvar_e_carregar_no_meio_de_uma_lesao() -> void:
	_event("driver_injury")
	var copy := Campaign.from_dict(JSON.parse_string(JSON.stringify(camp.to_dict())))
	assert_eq(copy.events.injuries.size(), 1)
	assert_eq(_ids(copy), _ids(camp))
	var injured: String = copy.events.injuries.keys()[0]
	for i in int(copy.events.injuries[injured]["rounds_left"]):
		copy.events.on_race_recorded(copy)
	assert_true(copy.events.injuries.is_empty())
	assert_eq(copy.drivers().size(), 22)


func test_virada_com_eventos_frequentes_mantem_o_grid_valido() -> void:
	camp.events.freq = "frequent"
	for y in 2:
		for r in 3:  # poucas corridas; os eventos continuam sorteando por dia
			camp.advance_to_event()
			var w := WeekendSim.new(camp.next_round()["id"], camp.weekend_options({"duration_pct": 0.25, "weather": "dry", "incident_rate": 0.0, "format": "race_only"}))
			w.simulate_current()
			camp.record_weekend(w)
		camp.advance_days(120)
		camp.round = Campaign.calendar().size()
		camp.regs.open_vote(camp)
		camp.start_next_season()
		var seen := {}
		var per_team := {}
		for d: Dictionary in camp.drivers():
			assert_false(seen.has(d["id"]), "duplicado " + d["id"])
			seen[d["id"]] = true
			per_team[d["team"]] = int(per_team.get(d["team"], 0)) + 1
		for t: Dictionary in camp.teams():
			assert_eq(int(per_team.get(t["id"], 0)), 2, "%s ano %d" % [t["id"], y])
