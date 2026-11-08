extends GutTest
## Pessoal da campanha: contratos de pilotos e técnicos, mercado, negociação e virada de temporada.

var camp: Campaign


func before_each() -> void:
	camp = Campaign.new_real("williams")
	camp.detail = "advanced"
	camp.budget_musd = 200.0


func _mine() -> Array[Dictionary]:
	return camp.personnel.player_drivers(camp)


func _free_driver(min_rating: int = 70) -> Dictionary:
	for e in camp.personnel.market(camp, "driver", "free"):
		if int(e["rating"]) >= min_rating:
			return e
	return {}


func test_montagem_cria_contratos_e_equipe_tecnica() -> void:
	for d: Dictionary in camp.drivers():
		assert_true(camp.personnel.contracts.has(d["id"]), d["id"])
		assert_gt(float(camp.personnel.contracts[d["id"]]["salary"]), 0.0)
	assert_eq(Personnel.ROLES.size(), 6, "4 técnicos + 2 engenheiros de corrida (2026-11-08) além do chefe de equipe e dos pilotos")
	for role: String in Personnel.ROLES:
		assert_ne(camp.personnel.staff[role], "", role)
	assert_eq(camp.personnel.person(camp.personnel.staff["director"])["name"], "Pat Fry", "equipe real: técnicos reais de 2026")
	var ferrari := Campaign.new_real("ferrari")
	assert_eq(ferrari.personnel.person(ferrari.personnel.staff["aero"])["name"], "Diego Tondi")


func test_salario_pedido_cresce_com_a_nota() -> void:
	assert_almost_eq(Personnel.driver_ask(78.0), 3.0, 0.15)
	assert_gt(Personnel.driver_ask(86.0), Personnel.driver_ask(78.0))
	assert_gt(Personnel.staff_ask(85.0), Personnel.staff_ask(60.0))


func test_folha_entra_no_custo_por_corrida() -> void:
	assert_gt(camp.personnel.payroll_per_race(camp), 0.0)
	var base: float = Campaign.origins_data()["finance"]["cost_base"]
	assert_almost_eq(camp.cost_per_race(), base + camp.dev.upkeep_per_race() + camp.personnel.payroll_per_race(camp), 0.0001)


func test_avaliacao_aceita_contrapropoe_ou_recusa() -> void:
	var e := _free_driver()
	var ask: float = e["ask"]
	assert_eq(camp.personnel.evaluate(camp, e["id"], ask * 1.5, 3)["result"], "accept")
	var counter := camp.personnel.evaluate(camp, e["id"], ask * 0.85, 3)
	assert_eq(counter["result"], "counter")
	assert_gt(float(counter["counter"]), ask * 0.85)
	assert_eq(camp.personnel.evaluate(camp, e["id"], ask * 0.4, 3)["result"], "refuse")
	assert_gt(float(camp.personnel.evaluate(camp, e["id"], ask * 1.2, 3)["interest"]), float(camp.personnel.evaluate(camp, e["id"], ask * 0.6, 3)["interest"]))


func test_mercado_filtra_livres_e_equipes() -> void:
	for e in camp.personnel.market(camp, "driver", "free"):
		assert_eq(e["team"], "")
		assert_false(e["mine"])
	for e in camp.personnel.market(camp, "driver", "teams"):
		assert_ne(e["team"], "")
	assert_gt(camp.personnel.market(camp, "staff", "all", "aero").size(), 3)
	for e in camp.personnel.market(camp, "staff", "all", "aero"):
		assert_eq(e["role"], "aero")


func test_multa_so_existe_com_contrato_ainda_valido() -> void:
	var other: Dictionary = {}
	for e in camp.personnel.market(camp, "driver", "teams"):
		if int(e["until"]) > camp.season:
			other = e
			break
	if not other.is_empty():
		assert_gt(camp.personnel.buyout_cost(other["id"], camp), 0.0)
	for e in camp.personnel.market(camp, "driver", "free"):
		assert_eq(camp.personnel.buyout_cost(e["id"], camp), 0.0)


func test_contratacao_so_vale_na_virada() -> void:
	var e := _free_driver()
	var mine_before := _mine().map(func(d: Dictionary) -> String: return d["id"])
	var replace: String = mine_before[0]
	var res := camp.personnel.sign(camp, e["id"], float(e["ask"]) * 1.5, 3, replace)
	assert_true(res["ok"], str(res))
	assert_true(camp.personnel.pending.has(e["id"]))
	assert_eq(_mine().map(func(d: Dictionary) -> String: return d["id"]), mine_before, "ainda não mudou")
	camp.start_next_season()
	var after := _mine().map(func(d: Dictionary) -> String: return d["id"])
	assert_true(after.has(e["id"]))
	assert_false(after.has(replace), "o dispensado saiu")
	assert_eq(after.size(), 2)
	assert_eq(camp.personnel.contracts[e["id"]]["team"], "williams")


func test_sem_vaga_exige_escolher_quem_sai() -> void:
	var e := _free_driver()
	var res := camp.personnel.sign(camp, e["id"], float(e["ask"]) * 1.5, 3)
	assert_false(res["ok"])
	assert_string_contains(res["text"], "vaga")


func test_proposta_baixa_nao_assina() -> void:
	var e := _free_driver()
	var res := camp.personnel.sign(camp, e["id"], float(e["ask"]) * 0.4, 2, _mine()[0]["id"])
	assert_false(res["ok"])
	assert_true(camp.personnel.pending.is_empty())


func test_dispensar_paga_multa_e_vaga_e_preenchida_sozinha() -> void:
	var d := _mine()[0]
	camp.personnel.contracts[d["id"]]["until"] = camp.season + 2
	var before := camp.budget_musd
	var fee := camp.personnel.dismiss(camp, d["id"])
	assert_gt(fee, 0.0)
	assert_almost_eq(camp.budget_musd, before - fee, 0.001)
	camp.start_next_season()
	var ids := _mine().map(func(x: Dictionary) -> String: return x["id"])
	assert_eq(ids.size(), 2, "a equipe sempre fecha o ano com 2 pilotos")
	assert_false(ids.has(d["id"]))


func test_renovar_mantem_o_piloto_com_o_novo_contrato() -> void:
	var d := _mine()[0]
	camp.personnel.contracts[d["id"]]["until"] = camp.season  # vence agora
	var ask := camp.personnel.ask_for(d["id"], camp)
	var res := camp.personnel.sign(camp, d["id"], ask * 1.4, 4)
	assert_true(res["ok"], str(res))
	camp.start_next_season()
	assert_true(_mine().map(func(x: Dictionary) -> String: return x["id"]).has(d["id"]))
	assert_eq(int(camp.personnel.contracts[d["id"]]["until"]), 2026 + 4)


func test_contrato_vencido_sem_renovar_libera_o_piloto() -> void:
	var d := _mine()[0]
	camp.personnel.contracts[d["id"]]["until"] = camp.season
	camp.start_next_season()
	assert_false(_mine().map(func(x: Dictionary) -> String: return x["id"]).has(d["id"]))
	assert_eq(_mine().size(), 2)


func test_contratar_tecnico_troca_a_funcao_na_virada() -> void:
	var old: String = camp.personnel.staff["aero"]
	var best := camp.personnel.market(camp, "staff", "free", "aero")
	assert_gt(best.size(), 0)
	var e: Dictionary = best[0]
	var res := camp.personnel.sign(camp, e["id"], float(e["ask"]) * 1.5, 3)
	assert_true(res["ok"], str(res))
	assert_eq(camp.personnel.staff["aero"], old, "antes da virada continua o antigo")
	camp.start_next_season()
	assert_eq(camp.personnel.staff["aero"], e["id"])
	assert_eq(camp.personnel.contracts[old]["team"], "", "o antigo vira agente livre")


func test_tecnicos_melhoram_prazo_e_acerto_dos_projetos() -> void:
	camp.personnel.staff["director"] = ""
	camp.personnel.staff["aero"] = ""
	camp.refresh_rating()
	var days0 := camp.dev.days_mult("aero")
	var ok0 := camp.dev.success_chance("aero")
	var best: Dictionary = camp.personnel.market(camp, "staff", "all", "aero")[0]
	camp.personnel.staff["aero"] = best["id"]
	camp.refresh_rating()
	assert_lt(camp.dev.days_mult("aero"), days0)
	assert_gt(camp.dev.success_chance("aero"), ok0)
	assert_eq(camp.dev.days_mult("chassis"), camp.dev.days_mult("chassis"))


func test_virada_mantem_o_grid_valido_por_varias_temporadas() -> void:
	for y in 5:
		camp.start_next_season()
		var seen: Dictionary = {}
		var numbers: Dictionary = {}
		var per_team: Dictionary = {}
		for d: Dictionary in camp.drivers():
			assert_false(seen.has(d["id"]), "piloto duplicado " + d["id"])
			seen[d["id"]] = true
			assert_false(numbers.has(d["number"]), "número repetido %d" % d["number"])
			numbers[d["number"]] = true
			per_team[d["team"]] = int(per_team.get(d["team"], 0)) + 1
		assert_eq(camp.drivers().size(), 22, "ano %d" % y)
		for t: Dictionary in camp.teams():
			assert_eq(int(per_team.get(t["id"], 0)), 2, "%s no ano %d" % [t["id"], y])


func test_ia_renova_dispensa_e_contrata() -> void:
	var before := camp.drivers().map(func(d: Dictionary) -> String: return d["id"])
	for i in 3:
		camp.start_next_season()
	var after := camp.drivers().map(func(d: Dictionary) -> String: return d["id"])
	var changed := 0
	for id in after:
		if not before.has(id):
			changed += 1
	assert_gt(changed, 0, "o grid muda ao longo dos anos")


func test_equipe_criada_fecha_24_carros_depois_da_virada() -> void:
	var c := Campaign.new_created({"origin": "garage", "name": "Teste", "short": "TST", "drivers": ["rafael_camara", "joshua_durksen"]})
	c.start_next_season()
	assert_eq(c.drivers().size(), 24)
	assert_eq(c.personnel.player_drivers(c).size(), 2)


func test_salvar_e_carregar_guarda_contratos_e_grid() -> void:
	var e := _free_driver()
	camp.personnel.sign(camp, e["id"], float(e["ask"]) * 1.5, 3, _mine()[0]["id"])
	camp.start_next_season()
	var e2 := _free_driver(60)
	if not e2.is_empty():
		camp.personnel.sign(camp, e2["id"], float(e2["ask"]) * 1.5, 2, _mine()[1]["id"])
	var copy := Campaign.from_dict(JSON.parse_string(JSON.stringify(camp.to_dict())))
	assert_eq(copy.drivers().map(func(d: Dictionary) -> String: return d["id"]), camp.drivers().map(func(d: Dictionary) -> String: return d["id"]))
	assert_eq(copy.personnel.pending.keys(), camp.personnel.pending.keys())
	assert_eq(copy.personnel.staff, camp.personnel.staff)
	assert_almost_eq(copy.cost_per_race(), camp.cost_per_race(), 0.0001)


func test_contraproposta_sempre_e_aceita_ao_ser_proposta() -> void:
	for e in camp.personnel.market(camp, "driver", "all").slice(0, 12):
		var ev := camp.personnel.evaluate(camp, e["id"], float(e["ask"]) * 0.85, 3)
		if ev["result"] == "counter":
			assert_eq(camp.personnel.evaluate(camp, e["id"], float(ev["counter"]), 3)["result"], "accept", e["id"])
