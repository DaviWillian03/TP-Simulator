extends GutTest
## Item 5: teto de gastos (trava rígida), restrição de túnel de vento, empréstimo e adiantamento, eventos novos.

var camp: Campaign


func before_each() -> void:
	camp = Campaign.new_real("williams")
	camp.detail = "advanced"
	camp.budget_musd = 300.0


func test_teto_trava_projetos_e_pecas() -> void:
	camp.record("rd", Campaign.COST_CAP_MUSD - 1.0)
	assert_almost_eq(camp.cap_left(), 1.0, 0.001)
	assert_eq(camp.dev.project_info("cur", "aero.0.0", camp)["reason"], "cap", "projeto bloqueado pelo teto")
	assert_eq(camp.my_parts().research_info(camp, "fwing", "high")["reason"], "cap", "pesquisa de peça bloqueada")
	assert_false(camp.my_parts().order_units(camp, "fwing", 0, 3), "fabricação acima do que resta (3 × 0,35) bloqueada")
	assert_true(camp.my_parts().order_units(camp, "fwing", 0, 2), "2 unidades (0,70) ainda cabem")


func test_salarios_e_obras_ficam_fora_do_teto() -> void:
	camp.record("payroll", 50.0)
	camp.record("works", 60.0)
	camp.record("debt", 10.0)
	assert_eq(camp.cap_spent(), 0.0)


func test_tunel_pela_posicao_do_ano_anterior() -> void:
	camp.last_positions = {"williams": 1, "mclaren": camp.teams().size()}
	assert_almost_eq(camp.atr_mult("williams"), 0.70, 0.001, "campeão: 70%")
	assert_almost_eq(camp.atr_mult("mclaren"), 1.15, 0.001, "último: 115%")
	camp.refresh_rating()
	var champ_days := camp.dev.days_mult("aero")
	var champ_ok := camp.dev.success_chance("aero")
	camp.last_positions["williams"] = camp.teams().size()
	camp.refresh_rating()
	assert_lt(camp.dev.days_mult("aero"), champ_days, "mais tempo de túnel: menos dias")
	assert_gt(camp.dev.success_chance("aero"), champ_ok)


func test_virada_grava_as_posicoes() -> void:
	camp.team_points = {"mclaren": 100, "williams": 50}
	camp.start_next_season()
	assert_eq(int(camp.last_positions["mclaren"]), 1)
	assert_eq(int(camp.last_positions["williams"]), 2)


func test_emprestimo_paga_parcelas_com_juros() -> void:
	var cash := camp.budget_musd
	assert_true(camp.take_loan(20.0, 1))
	assert_almost_eq(camp.budget_musd, cash + 20.0, 0.001)
	var l: Dictionary = camp.loans[0]
	assert_almost_eq(float(l["total"]), 21.6, 0.01, "8% de juros")
	assert_eq(int(l["races_left"]), 11)
	camp._pay_credit()
	assert_eq(int(camp.loans[0]["races_left"]), 10)
	assert_false(camp.take_loan(Campaign.BANK_LIMIT_MUSD, 0), "acima do limite do banco")


func test_adiantamento_reduz_o_patrocinio_seguinte() -> void:
	var room := camp.advance_room()
	assert_gt(room, 0.0)
	assert_true(camp.take_advance(room))
	assert_eq(camp.advance_room(), 0.0, "um adiantamento por vez")
	var before := float(camp.ledger.get("sponsors", 0.0))
	camp._pay_credit()
	assert_lt(float(camp.ledger.get("sponsors", 0.0)), before)


func test_credito_salva_e_carrega() -> void:
	camp.take_loan(10.0, 0)
	camp.take_advance(2.0)
	camp.last_positions = {"williams": 3}
	var c := Campaign.from_dict(JSON.parse_string(JSON.stringify(camp.to_dict())))
	assert_eq(c.loans.size(), 1)
	assert_false(c.advance.is_empty())
	assert_eq(int(c.last_positions["williams"]), 3)


func test_gp_adiado_muda_a_data() -> void:
	var cands := camp.events._postpone_candidates(camp)
	assert_false(cands.is_empty())
	var i: int = cands[0]
	var d := camp.round_day(i)
	camp.events.postponed[i] = 7
	assert_eq(camp.round_day(i), d + 7)


func test_eventos_das_rivais() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	for id: String in ["rival_factory_fire", "rival_staff_leaves", "rival_sponsor", "principal_change", "race_postponed"]:
		var e: Dictionary = CampaignEvents.data()["events"].filter(func(x: Dictionary) -> bool: return x["id"] == id)[0]
		var n := camp.events._apply(camp, e, rng, camp.day)
		assert_ne(String(n["title"]), "", id)
	assert_false(camp.events.principals.is_empty(), "troca de chefe registrada")
	var c := Campaign.from_dict(JSON.parse_string(JSON.stringify(camp.to_dict())))
	var tid: String = camp.events.principals.keys()[0]
	assert_eq(GameData.team_by_id(c.teams(), tid)["principal"], camp.events.principals[tid], "o chefe novo continua depois de carregar")
