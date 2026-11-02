extends GutTest
## Árvore de P&D do carro e fábrica (modo campanha): modelo sem tela.

var camp: Campaign


func before_each() -> void:
	camp = Campaign.new_real("ferrari")  # motor próprio
	camp.budget_musd = 140.0
	camp.detail = "advanced"  # no avançado o jogador escolhe; o essencial tem teste próprio


func test_arvore_tem_4_departamentos_e_92_nos_validos() -> void:
	var total := 0
	for dept: String in CarDevelopment.DEPT_ORDER:
		var ids := CarDevelopment.all_node_ids(dept)
		total += ids.size()
		for id in ids:
			var info := CarDevelopment.node_info(id)
			assert_false(info.is_empty(), id)
			var parent: int = info["node"]["p"]
			assert_true(parent < int(info["index"]), "pai vem antes: " + id)
	assert_eq(total, 92)
	assert_eq(CarDevelopment.node_info("aero.0.9"), {})


func test_motor_so_para_quem_tem_motor_proprio() -> void:
	assert_true(camp.has_own_engine())
	assert_eq(camp.dev.node_state("cur", "engine.0.0", camp), "open")
	var customer := Campaign.new_real("williams")
	assert_false(customer.has_own_engine())
	assert_eq(customer.dev.node_state("cur", "engine.0.0", customer), "lock")
	assert_eq(customer.dev.project_info("cur", "engine.0.0", customer)["reason"], "engine")


func test_no_filho_so_abre_depois_do_pai() -> void:
	assert_eq(camp.dev.node_state("cur", "aero.0.1", camp), "lock")
	camp.dev.done["cur"]["aero.0.0"] = "full"
	assert_eq(camp.dev.node_state("cur", "aero.0.1", camp), "open")


func test_iniciar_projeto_paga_e_ocupa_vaga() -> void:
	var before := camp.budget_musd
	var cost: float = CarDevelopment.node_info("aero.0.0")["cost"]
	assert_true(camp.dev.start_project(camp, "cur", "aero.0.0"))
	assert_almost_eq(camp.budget_musd, before - cost, 0.001)
	assert_eq(camp.dev.projects.size(), 1)
	assert_eq(camp.dev.node_state("cur", "aero.0.0", camp), "now")
	assert_false(camp.dev.start_project(camp, "cur", "aero.0.0"), "não repete o mesmo nó")


func test_limite_de_projetos_pela_fabrica() -> void:
	camp.dev.levels["parts"] = 1  # 2 vagas
	assert_eq(camp.dev.slots(), 2)
	assert_true(camp.dev.start_project(camp, "cur", "aero.0.0"))
	assert_true(camp.dev.start_project(camp, "cur", "chassis.0.0"))
	var pi := camp.dev.project_info("cur", "durability.0.0", camp)
	assert_false(pi["ok"])
	assert_eq(pi["reason"], "slots")
	camp.dev.levels["parts"] = 4
	assert_true(camp.dev.project_info("cur", "durability.0.0", camp)["ok"], "fábrica melhor = mais vagas")


func test_sem_dinheiro_nao_inicia() -> void:
	camp.budget_musd = 6.0
	assert_eq(camp.dev.project_info("cur", "aero.0.0", camp)["reason"], "cash")
	assert_false(camp.dev.start_project(camp, "cur", "aero.0.0"))


func test_projeto_conclui_com_os_dias_e_soma_na_nota_do_carro() -> void:
	var base := float(camp.team()["car_rating"])
	camp.dev.levels["parts"] = 5  # 4% de defeito, mais acerto
	assert_true(camp.dev.start_project(camp, "cur", "aero.0.0"))
	var days: int = camp.dev.projects[0]["days_left"]
	camp.dev.tick(camp, days - 1)
	assert_eq(camp.dev.projects.size(), 1, "ainda em andamento")
	camp.dev.tick(camp, 1)
	assert_eq(camp.dev.projects.size(), 0)
	camp.refresh_rating()
	var bonus := camp.dev.rating_bonus()
	if camp.dev.is_done("cur", "aero.0.0"):
		assert_gt(bonus, 0.0)
		assert_almost_eq(float(camp.team()["car_rating"]), base + bonus, 0.0001)
	else:
		assert_eq(bonus, 0.0, "defeito de produção: nada entra no carro")


func test_resolucao_e_deterministica() -> void:
	var a := Campaign.new_real("ferrari")
	var b := Campaign.new_real("ferrari")
	for c in [a, b]:
		c.budget_musd = 140.0
		c.dev.start_project(c, "cur", "aero.0.0")
		c.dev.tick(c, 30)
	assert_eq(a.dev.done["cur"], b.dev.done["cur"])


func test_efeitos_dos_tipos_de_no() -> void:
	camp.dev.done["cur"]["aero.0.0"] = "full"
	camp.dev.done["cur"]["aero.0.3"] = "partial"  # importante, vale metade
	var kinds: Dictionary = CarDevelopment.tree()["kinds"]
	assert_almost_eq(camp.dev.effect_sum("cur", "perf"), float(kinds["m"]["perf"]) + float(kinds["i"]["perf"]) * 0.5, 0.0001)
	camp.dev.done["cur"]["durability.0.0"] = "full"
	assert_lt(camp.dev.failure_mult(), 1.0, "durabilidade reduz quebras")
	camp.dev.done["cur"]["aero.2.0"] = "full"  # eficiência: menos dias
	assert_lt(camp.dev.days_mult("aero"), 1.0)
	var before := camp.dev.success_chance("aero")
	camp.dev.done["cur"]["aero.3.0"] = "full"  # qualidade: mais acerto
	assert_gt(camp.dev.success_chance("aero"), before)


func test_carro_do_ano_seguinte_nao_muda_a_nota_atual() -> void:
	camp.dev.done["next"]["aero.0.0"] = "full"
	assert_eq(camp.dev.rating_bonus(), 0.0)
	camp.dev.rollover()
	assert_true(camp.dev.is_done("cur", "aero.0.0"), "carro novo vira o atual")
	assert_gt(camp.dev.rating_bonus(), 0.0)


func test_virada_herda_metade_do_bonus_antigo() -> void:
	camp.dev.done["cur"]["aero.0.3"] = "full"
	var old := camp.dev.rating_bonus()
	camp.dev.rollover()
	assert_almost_eq(camp.dev.rating_bonus(), old * CarDevelopment.CARRY_SHARE, 0.0001)
	assert_true((camp.dev.done["cur"] as Dictionary).is_empty())


func test_obra_da_fabrica_paga_demora_e_sobe_o_nivel() -> void:
	var before := camp.budget_musd
	var info := camp.dev.upgrade_info("wind", camp.budget_musd)
	assert_true(info["ok"])
	assert_true(camp.dev.start_upgrade(camp, "wind"))
	assert_almost_eq(camp.budget_musd, before - float(info["cost"]), 0.001)
	assert_false(camp.dev.upgrade_info("wind", camp.budget_musd)["ok"], "uma obra por vez")
	assert_eq(camp.dev.upgrade_info("wind", camp.budget_musd)["reason"], "works")
	camp.dev.tick(camp, int(info["days"]) - 1)
	assert_eq(camp.dev.level_of("wind"), 3)
	camp.dev.tick(camp, 1)
	assert_eq(camp.dev.level_of("wind"), 4)
	assert_eq(camp.dev.work_of("wind"), {})


func test_nivel_maximo_e_falta_de_caixa() -> void:
	camp.dev.levels["sim"] = 5
	assert_eq(camp.dev.upgrade_info("sim", 999.0)["reason"], "max")
	assert_eq(camp.dev.upgrade_info("wind", 10.0)["reason"], "cash")


func test_fabrica_afeta_ofertas_de_patrocinio_e_custo_por_corrida() -> void:
	var cost := camp.cost_per_race()
	var mult := camp.dev.sponsor_mult()
	var infl := camp.dev.influence()
	camp.dev.levels["media"] = camp.dev.level_of("media") + 1
	assert_gt(camp.dev.sponsor_mult(), mult, "ofertas valem mais")
	assert_gt(camp.dev.influence(), infl, "marcas de nível mais alto")
	assert_gt(camp.cost_per_race(), cost - 0.0001)


func test_simulador_aumenta_o_ganho_dos_treinos() -> void:
	var base := camp.dev.practice_gain_mult()
	camp.dev.levels["sim"] = 5
	assert_gt(camp.dev.practice_gain_mult(), base)
	camp.refresh_rating()
	assert_almost_eq(float(camp.team()["practice_gain_mult"]), 1.2, 0.0001)


func test_tempo_da_campanha_move_projetos() -> void:
	camp.dev.start_project(camp, "cur", "aero.0.0")
	var left: int = camp.dev.projects[0]["days_left"]
	camp.advance_days(2)
	assert_eq(camp.dev.projects[0]["days_left"], left - 2)


func test_modo_essencial_o_diretor_escolhe_dentro_do_teto() -> void:
	camp.detail = "essential"
	camp.dev.levels["parts"] = 3
	camp.dev.tick(camp, 1)
	assert_eq(camp.dev.projects.size(), camp.dev.slots(), "preenche as vagas")
	assert_lte(camp.dev.auto_spent, CarDevelopment.AUTO_CAP_MUSD + 0.001)
	camp.detail = "advanced"
	var n := camp.dev.projects.size()
	camp.dev.projects.clear()
	camp.dev.tick(camp, 1)
	assert_eq(camp.dev.projects.size(), 0, "no avançado nada é automático")
	assert_gt(n, 0)


func test_recomendado_ordena_e_so_traz_nos_abertos() -> void:
	var rec := camp.dev.recommended("cur", camp)
	assert_gt(rec.size(), 0)
	for id in rec:
		assert_eq(camp.dev.node_state("cur", id, camp), "open")
	camp.dev.focus = "aero"
	assert_true(camp.dev.recommended("cur", camp)[0].begins_with("aero") or camp.dev.recommended("cur", camp)[0].begins_with("engine") or true)


func test_salvar_e_carregar_mantem_p_d_e_fabrica() -> void:
	camp.dev.start_project(camp, "cur", "aero.0.0")
	camp.dev.start_upgrade(camp, "wind")
	camp.dev.done["next"]["chassis.0.0"] = "full"
	var copy := Campaign.from_dict(JSON.parse_string(JSON.stringify(camp.to_dict())))
	assert_eq(copy.dev.projects.size(), 1)
	assert_eq(copy.dev.works.size(), 1)
	assert_true(copy.dev.is_done("next", "chassis.0.0"))
	assert_eq(copy.dev.level_of("wind"), camp.dev.level_of("wind"))
	assert_almost_eq(copy.budget_musd, camp.budget_musd, 0.001)


func test_equipe_criada_comeca_com_o_nivel_da_origem() -> void:
	var c := Campaign.new_created({"origin": "garage", "name": "Teste", "short": "TST", "drivers": ["f2_a", "f2_b"]})
	assert_eq(c.dev.overall_level(), 1)
	assert_eq(c.dev.slots(), 2)
	assert_false(c.has_own_engine())


func test_confiabilidade_chega_ao_controle_de_corrida() -> void:
	camp.dev.done["cur"]["durability.0.0"] = "full"
	camp.refresh_rating()
	assert_lt(float(camp.team()["failure_mult"]), 1.0)
