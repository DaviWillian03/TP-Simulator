extends GutTest
## Fábrica da campanha (v42, 2026-11-19): quatro estruturas com efeito escrito em números, obras com custo e dias,
## vagas de projeto, migração da árvore de P&D antiga. Modelo sem tela.

var camp: Campaign


func before_each() -> void:
	camp = Campaign.new_real("ferrari")  # motor próprio
	camp.budget_musd = 140.0
	camp.detail = "advanced"  # no avançado o jogador escolhe; o essencial tem teste próprio


func test_cada_nivel_tem_efeito_escrito_em_numeros() -> void:
	for sid: String in CarDevelopment.STRUCT_ORDER:
		for lv in range(1, 6):
			var lines := CarDevelopment.effect_lines(sid, lv)
			assert_gt(lines.size(), 0, sid)
			for l: String in lines:
				assert_true(RegEx.create_from_string("\\d").search(l) != null, "%s %d: %s" % [sid, lv, l])
	assert_ne(CarDevelopment.effect_lines("wind", 2), CarDevelopment.effect_lines("wind", 3), "subir de nível muda o efeito")
	assert_true(CarDevelopment.effect_text("parts", 3).contains("[b]3[/b]"), "números em negrito no texto")


func test_tunel_de_vento_acelera_e_aperta_a_aero() -> void:
	camp.dev.levels["wind"] = 1
	var d1 := camp.dev.days_mult("aero")
	var n1 := camp.dev.narrow("aero")
	camp.dev.levels["wind"] = 4
	assert_lt(camp.dev.days_mult("aero"), d1)
	assert_gt(camp.dev.narrow("aero"), n1)
	assert_eq(camp.dev.days_mult("chassis"), camp.dev.days_mult("chassis"), "não mexe nas peças mecânicas")


func test_fabrica_de_pecas_da_vagas_e_acelera_as_mecanicas() -> void:
	camp.dev.levels["parts"] = 2
	var d2 := camp.dev.days_mult("chassis")
	assert_eq(camp.dev.slots(), 2)
	camp.dev.levels["parts"] = 3
	assert_eq(camp.dev.slots(), 3)
	assert_lt(camp.dev.days_mult("chassis"), d2)


func test_obra_da_fabrica_paga_demora_e_sobe_o_nivel() -> void:
	camp.dev.levels["wind"] = 3
	var before := camp.budget_musd
	var info := camp.dev.upgrade_info("wind", camp.budget_musd)
	assert_true(info["ok"])
	assert_true(camp.dev.start_upgrade(camp, "wind"))
	assert_almost_eq(camp.budget_musd, before - float(info["cost"]), 0.001)
	assert_eq(camp.dev.upgrade_info("wind", camp.budget_musd)["reason"], "works", "uma obra por vez")
	camp.dev.tick(camp, int(info["days"]) - 1)
	assert_eq(camp.dev.level_of("wind"), 3)
	camp.dev.tick(camp, 1)
	assert_eq(camp.dev.level_of("wind"), 4)
	assert_eq(camp.dev.work_of("wind"), {})


func test_nivel_maximo_e_falta_de_caixa() -> void:
	camp.dev.levels["sim"] = 5
	camp.dev.levels["wind"] = 2
	assert_eq(camp.dev.upgrade_info("sim", 999.0)["reason"], "max")
	assert_eq(camp.dev.upgrade_info("wind", 10.0)["reason"], "cash")


func test_marketing_sobe_ofertas_metas_e_custo_por_corrida() -> void:
	var cost := camp.cost_per_race()
	var mult := camp.dev.sponsor_mult()
	var infl := camp.dev.influence()
	camp.dev.levels["media"] = camp.dev.level_of("media") + 1
	assert_gt(camp.dev.sponsor_mult(), mult, "ofertas valem mais")
	assert_gt(camp.dev.influence(), infl)
	assert_gte(camp.dev.goals_per_offer(), CarDevelopment.goals_at(camp.dev.level_of("media") - 1))
	assert_gt(camp.cost_per_race(), cost - 0.0001)


func test_simulador_aumenta_o_ganho_dos_treinos() -> void:
	var base := camp.dev.practice_gain_mult()
	camp.dev.levels["sim"] = 5
	assert_gt(camp.dev.practice_gain_mult(), base)
	camp.refresh_rating()
	assert_almost_eq(float(camp.team()["practice_gain_mult"]), 1.2, 0.0001, "simulador nível 5: +20%")


func test_modo_essencial_o_diretor_comeca_projetos_dentro_do_teto() -> void:
	camp.detail = "essential"
	camp.dev.levels["parts"] = 3
	var allowance := camp.dev.auto_allowance(camp)
	camp.dev.tick(camp, 1)
	assert_gte(camp.dev.busy(), 2, "começa projetos de peça (médios; pequenos quando a verba do mês aperta)")
	assert_lte(camp.dev.auto_spent, allowance + 0.001, "dentro da verba do mês (teto de gastos ÷ meses)")
	camp.detail = "advanced"
	camp.my_parts().research.clear()
	camp.dev.parts_busy = 0
	camp.dev.tick(camp, 1)
	assert_eq(camp.my_parts().research.size(), 0, "no avançado nada é automático")


func test_salvar_e_carregar_mantem_a_fabrica() -> void:
	camp.dev.start_upgrade(camp, "wind")
	camp.dev.carry = 1.5
	var copy := Campaign.from_dict(JSON.parse_string(JSON.stringify(camp.to_dict())))
	assert_eq(copy.dev.works.size(), 1)
	assert_eq(copy.dev.level_of("wind"), camp.dev.level_of("wind"))
	assert_almost_eq(copy.dev.carry, 1.5, 0.001, "sem migrar de novo (save da v42)")
	assert_almost_eq(copy.budget_musd, camp.budget_musd, 0.001)


func test_save_antigo_da_arvore_vira_nota_do_carro() -> void:
	var old := {"levels": {"wind": 2, "sim": 1, "parts": 2, "media": 1}, "carry": 0.4,
		"done": {"cur": {"aero.0.0": "full", "aero.0.1": "partial"}, "next": {"chassis.0.0": "full"}}, "projects": [], "works": []}
	var d := CarDevelopment.from_dict(old)
	assert_gt(d.carry, 0.4, "os nós de desempenho prontos viraram nota")
	assert_lt(d.carry, 2.0)
	assert_eq(d.level_of("wind"), 2)
	assert_almost_eq(CarDevelopment.from_dict({"carry": 0.4, "v": 42}).carry, 0.4, 0.0001)


func test_equipe_criada_comeca_com_o_nivel_da_origem() -> void:
	var c := Campaign.new_created({"origin": "garage", "name": "Teste", "short": "TST", "drivers": ["f2_a", "f2_b"]})
	assert_eq(c.dev.overall_level(), 1)
	assert_eq(c.dev.slots(), 2)
	assert_false(c.has_own_engine())


func test_virada_soma_heranca_e_o_que_foi_feito_para_o_carro_novo() -> void:
	camp.dev.carry = 1.0
	camp.dev.rollover(2.0, 0.7)
	assert_almost_eq(camp.dev.carry, (1.0 + 2.0) * CarDevelopment.CARRY_SHARE + 0.7, 0.0001)
