extends GutTest
## Patrocínios por zona, ofertas mensais e livro-caixa da campanha.

var camp: Campaign


func before_each() -> void:
	camp = Campaign.new_real("williams")
	camp.detail = "advanced"
	camp.budget_musd = 150.0


func test_contratos_iniciais_somam_o_patrocinio_base() -> void:
	var target: float = Campaign.origins_data()["finance"]["sponsor_default"]
	assert_almost_eq(camp.sponsor_per_race(), target, 0.35)
	assert_gt(camp.sponsors.contracts.size(), 2)
	for z in camp.sponsors.contracts:
		assert_ne(Sponsorship.zone(z), {}, z)


func test_equipe_melhor_tem_mais_zonas_ocupadas() -> void:
	var top := Campaign.new_real("mclaren")
	var low := Campaign.new_real("cadillac")
	assert_gt(top.sponsors.contracts.size(), low.sponsors.contracts.size())


func test_zona_livre_recebe_tres_ofertas_de_marcas_ate_a_influencia() -> void:
	var free := camp.sponsors.free_zones()
	assert_gt(free.size(), 0)
	var offers := camp.sponsors.offers_for(camp, free[0])
	assert_eq(offers.size(), 3)
	for o in offers:
		assert_lte(int(o["tier"]), camp.dev.influence())
		assert_gt(float(o["per_race"]), 0.0)
		assert_between(int(o["years"]), 1, 3)


func test_ofertas_sao_deterministicas_e_mudam_a_cada_mes() -> void:
	var z: String = camp.sponsors.free_zones()[0]
	var a := camp.sponsors.offers_for(camp, z).map(func(o: Dictionary) -> String: return o["key"])
	var b := camp.sponsors.offers_for(camp, z).map(func(o: Dictionary) -> String: return o["key"])
	assert_eq(a, b)
	camp.day += 45
	var c := camp.sponsors.offers_for(camp, z).map(func(o: Dictionary) -> String: return o["key"])
	assert_ne(a, c)


func test_aceitar_oferta_ocupa_a_zona_e_soma_ao_patrocinio() -> void:
	var z: String = camp.sponsors.free_zones()[0]
	var before := camp.sponsor_per_race()
	var o: Dictionary = camp.sponsors.offers_for(camp, z)[0]
	var res := camp.sponsors.accept(camp, z, o["key"])
	assert_true(res["ok"])
	assert_true(camp.sponsors.contracts.has(z))
	assert_almost_eq(camp.sponsor_per_race(), before + float(o["per_race"]), 0.0001)
	assert_false(camp.sponsors.accept(camp, z, o["key"])["ok"], "zona já ocupada")
	assert_eq(camp.sponsors.offers_for(camp, z).size(), 0)


func test_pedir_mais_so_uma_vez_e_pode_subir_ou_perder_a_oferta() -> void:
	var z: String = camp.sponsors.free_zones()[0]
	var o: Dictionary = camp.sponsors.offers_for(camp, z)[0]
	var res := camp.sponsors.ask_more(camp, z, o["key"])
	assert_false(camp.sponsors.ask_more(camp, z, o["key"])["ok"], "uma vez por oferta")
	var left := camp.sponsors.offers_for(camp, z)
	if res["ok"]:
		var again: Dictionary = left.filter(func(x: Dictionary) -> bool: return x["key"] == o["key"])[0]
		assert_gt(float(again["per_race"]), float(o["per_race"]))
		assert_true(again["asked"])
	else:
		assert_true(left.filter(func(x: Dictionary) -> bool: return x["key"] == o["key"]).is_empty(), "marca desistiu")


func test_rescindir_cobra_multa_e_libera_a_zona() -> void:
	var z: String = camp.sponsors.contracts.keys()[0]
	var before := camp.budget_musd
	var fee := camp.sponsors.terminate(camp, z)
	assert_gt(fee, 0.0)
	assert_almost_eq(camp.budget_musd, before - fee, 0.001)
	assert_false(camp.sponsors.contracts.has(z))
	assert_almost_eq(float(camp.ledger["contracts"]), fee, 0.001)


func test_bonus_por_podio_entra_no_caixa() -> void:
	var w := WeekendSim.new("interlagos", camp.weekend_options({"duration_pct": 0.25, "weather": "dry", "incident_rate": 0.0, "format": "race_only"}))
	w.simulate_current()
	# força um pódio da equipe do jogador
	var mine: Array = camp.drivers().filter(func(d: Dictionary) -> bool: return d["team"] == "williams").map(func(d: Dictionary) -> String: return d["id"])
	var order: Array = w.results["race"].duplicate()
	for id in mine:
		order.erase(id)
	order.insert(0, mine[0])
	w.results["race"] = order
	var before := camp.budget_musd
	camp.advance_to_event()
	camp.record_weekend(w)
	assert_almost_eq(float(camp.ledger["bonus"]), camp.sponsors.bonus_per_podium(), 0.0001)
	assert_gt(float(camp.ledger["sponsors"]), 0.0)
	assert_gt(camp.budget_musd, before - camp.cost_per_race() - 0.001 + camp.sponsor_per_race())


func test_livro_caixa_registra_gastos_de_pd_fabrica_e_contratos() -> void:
	camp.dev.start_project(camp, "cur", "aero.0.0")
	camp.dev.start_upgrade(camp, "wind")
	assert_gt(float(camp.ledger["rd"]), 0.0)
	assert_gt(float(camp.ledger["works"]), 0.0)
	var rd := float(camp.ledger["rd"])
	camp.dev.cancel_project(camp, "cur", "aero.0.0")
	assert_lt(float(camp.ledger["rd"]), rd)
	assert_gt(camp.expense_total(), 0.0)


func test_historico_do_caixa_e_projecao() -> void:
	assert_eq(camp.cash_log.size(), 1)
	camp.advance_to_event()
	var w := WeekendSim.new(camp.next_round()["id"], camp.weekend_options({"duration_pct": 0.25, "weather": "dry", "incident_rate": 0.0, "format": "race_only"}))
	w.simulate_current()
	camp.record_weekend(w)
	assert_eq(camp.cash_log.size(), 2)
	assert_gt(camp.projected_cash_end(), 0.0)


func test_virada_zera_o_livro_e_vence_contratos() -> void:
	var z: String = camp.sponsors.contracts.keys()[0]
	camp.sponsors.contracts[z]["until"] = camp.season  # vence agora
	camp.record("rd", 5.0)
	camp.start_next_season()
	assert_false(camp.sponsors.contracts.has(z))
	assert_true(camp.ledger.is_empty())
	assert_eq(camp.cash_log.size(), 1)
	assert_true(camp.sponsors.free_zones().has(z))


func test_salvar_e_carregar_guarda_patrocinios_e_livro() -> void:
	var z: String = camp.sponsors.free_zones()[0]
	camp.sponsors.accept(camp, z, camp.sponsors.offers_for(camp, z)[0]["key"])
	camp.record("rd", 12.0)
	var copy := Campaign.from_dict(JSON.parse_string(JSON.stringify(camp.to_dict())))
	assert_eq(copy.sponsors.contracts.keys().size(), camp.sponsors.contracts.keys().size())
	assert_almost_eq(copy.sponsor_per_race(), camp.sponsor_per_race(), 0.0001)
	assert_almost_eq(float(copy.ledger["rd"]), 12.0, 0.0001)
	assert_eq(copy.cash_log.size(), camp.cash_log.size())
