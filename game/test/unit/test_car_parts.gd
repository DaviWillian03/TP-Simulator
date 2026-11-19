extends GutTest
## Projetos de peça (v42, 2026-11-19): área + tamanho → custo, prazo, ganho esperado; ao terminar a peça entra nos dois
## carros com ganho real sempre positivo entre 60% e 120% do esperado; esforço dividido com o carro do ano seguinte;
## unidades físicas (desgaste, limite de motor/câmbio) continuam; a IA usa as mesmas regras.

var camp: Campaign
var cp: CarParts


func before_each() -> void:
	camp = Campaign.new_real("williams")
	camp.detail = "advanced"
	camp.budget_musd = 200.0
	cp = camp.my_parts()


func _days(n: int) -> void:
	for i in n:
		camp.day += 1
		cp.day_step(camp)


func _finish(area_id: String, size_id := "M") -> Dictionary:
	assert_true(cp.start_project(camp, area_id, size_id), "projeto iniciado")
	_days(int(cp.project_of(area_id)["days_left"]))
	return cp.deliveries[0]


func test_comeca_com_a_versao_a_nos_dois_carros_e_reserva_no_estoque() -> void:
	for pid: String in CarParts.part_ids():
		assert_eq(cp.spec_list(pid).size(), 1)
		assert_false(cp.unit_on(pid, 0).is_empty(), pid)
		assert_false(cp.unit_on(pid, 1).is_empty(), pid)
	assert_eq(cp.stock("fwing").size(), CarParts.SPARE_A)
	assert_eq(cp.car_effect(0), 0.0, "versão A: sem efeito")
	assert_eq(camp.parts.size(), camp.teams().size(), "todas as equipes têm peças")


func test_tamanho_muda_custo_prazo_e_ganho() -> void:
	var s := cp.project_info(camp, "floor", "S")
	var m := cp.project_info(camp, "floor", "M")
	var l := cp.project_info(camp, "floor", "L")
	assert_lt(float(s["cost"]), float(m["cost"]))
	assert_lt(float(m["cost"]), float(l["cost"]))
	assert_lt(int(s["days"]), int(l["days"]))
	assert_lt(float(s["sec"]), float(m["sec"]))
	assert_lt(float(m["sec"]), float(l["sec"]))
	assert_gt(float(m["sec"]), 0.0, "ganho em s/volta")
	assert_gt(float(m["sec"]), float(m["sec_avg"]), "na pista do tipo da área o ganho é maior que a média")


func test_projeto_paga_ocupa_vaga_e_um_por_area() -> void:
	camp.dev.levels["parts"] = 2
	var cash := camp.budget_musd
	var info := cp.project_info(camp, "fwing", "M")
	assert_true(info["ok"])
	assert_true(cp.start_project(camp, "fwing", "M"))
	assert_almost_eq(camp.budget_musd, cash - float(info["cost"]), 0.001)
	assert_eq(camp.dev.busy(), 1)
	assert_eq(cp.project_info(camp, "fwing", "S")["reason"], "now")
	assert_true(cp.start_project(camp, "floor", "S"))
	assert_eq(cp.project_info(camp, "susp", "S")["reason"], "slots", "fábrica nível 1-2: 2 vagas")


func test_entrega_poe_a_peca_nos_dois_carros_com_ganho_positivo_na_faixa() -> void:
	var e := _finish("fwing", "M")
	var si := cp.latest_spec("fwing")
	assert_eq(si, 1)
	assert_eq(int(cp.unit_on("fwing", 0)["spec"]), si, "carro 0")
	assert_eq(int(cp.unit_on("fwing", 1)["spec"]), si, "carro 1")
	assert_true(bool(cp.spec("fwing", si)["revealed"]), "o real aparece na entrega")
	var b := cp.band(camp, "fwing")
	assert_between(float(e["ratio"]), float(b[0]) - 0.01, float(b[1]) + 0.01)
	assert_gte(float(b[0]), 0.6)
	assert_lte(float(b[1]), 1.2)
	assert_gt(cp.car_effect(0, CarParts.area_profile("fwing")), 0.0, "sempre melhora")
	assert_eq(camp.dev.busy(), 0)
	assert_eq(cp.done_research.size(), 1, "aviso de entrega para o jogador")


func test_ganho_nunca_e_negativo_em_muitas_entregas() -> void:
	for i in 12:
		camp.day += 37
		var r := {"part": "susp", "area": "susp", "size": "M", "days_left": 0, "days_total": 1, "cost": 1.0, "fix": -1}
		cp._finish_research(camp, r)
		var e: Dictionary = cp.deliveries[0]
		assert_between(float(e["ratio"]), 0.6, 1.2)
		for k: String in (e["real"] as Dictionary):
			assert_gte(float(e["real"][k]), 0.0, k)


func test_versoes_somam_em_cima_da_anterior() -> void:
	_finish("floor", "S")
	var v1 := cp.car_effect(0)
	_finish("floor", "S")
	assert_gt(cp.car_effect(0), v1, "a versão C soma ao que a B já dava")


func test_equipe_tecnica_e_fabrica_sobem_o_piso_da_faixa() -> void:
	camp.dev.levels["wind"] = 1
	camp.refresh_rating()
	var lo1 := float(cp.band(camp, "floor")[0])
	camp.dev.levels["wind"] = 5
	assert_gt(float(cp.band(camp, "floor")[0]), lo1)
	assert_lte(float(cp.band(camp, "floor")[0]), 0.6 + float(CarParts.projects_cfg()["max_narrow"]) + 0.0001)


func test_esforco_para_o_ano_seguinte_divide_o_ganho_e_rende_na_virada() -> void:
	cp.next_share = 0.5
	var e := _finish("floor", "M")
	assert_almost_eq(float(e["share"]), 0.5, 0.001)
	assert_gt(cp.next_bank, 0.0, "parte do ganho guardada para o carro novo")
	var expected_full := CarParts.fx_rating(e["expected"]) * float(e["ratio"])
	assert_almost_eq(cp.car_effect(0), expected_full * 0.5, 0.05, "metade no carro atual")
	assert_almost_eq(cp.next_bank, expected_full * 0.5 * float(CarParts.projects_cfg()["next_k"]), 0.05, "e a outra metade rende mais na virada")
	var est := camp.next_car_estimate()
	var bank := cp.next_bank
	camp.start_next_season()
	assert_almost_eq(camp.dev.carry, est, 0.01, "a prévia bate com a virada")
	assert_gte(camp.dev.carry, bank)
	assert_eq(camp.my_parts().next_bank, 0.0)


func test_confiabilidade_fica_toda_no_carro_atual() -> void:
	cp.next_share = 0.5
	var e := _finish("rel", "M")
	assert_eq(float(e["share"]), 0.0)
	assert_gt(cp.trait_delta(0, "rel"), 0.0)
	assert_eq(cp.next_bank, 0.0)


func test_motor_potencia_so_para_quem_fabrica() -> void:
	assert_eq(cp.project_info(camp, "power", "M")["reason"], "engine", "Williams usa motor Mercedes")
	assert_true(cp.project_info(camp, "rel", "M")["ok"], "confiabilidade é para todos")
	var merc := Campaign.new_real("mercedes")
	merc.budget_musd = 100.0
	assert_true(merc.my_parts().project_info(merc, "power", "M")["ok"])


func test_corrida_desgasta_e_a_equipe_troca_a_peca_gasta_sozinha() -> void:
	cp.unit_on("fwing", 0)["wear"] = 75.0
	cp.after_race(camp)
	assert_gt(float(cp.unit_on("fwing", 1)["wear"]), 0.0)
	assert_lt(float(cp.unit_on("fwing", 0)["wear"]), 75.0, "a reserva entrou no carro")


func test_gp_leva_o_efeito_de_cada_carro() -> void:
	_finish("fwing", "L")
	camp.refresh_rating()
	var gp := GameData.team_by_id(camp.teams_for_gp("monaco"), "williams")
	var ids := camp.team_driver_ids("williams")
	assert_almost_eq(float(gp["car_delta"][ids[0]]), float(gp["car_delta"][ids[1]]), 0.3, "os dois carros recebem a peça")
	assert_gt(float(gp["car_delta"][ids[0]]), 0.0)


func test_salva_e_carrega() -> void:
	cp.next_share = 0.3
	_finish("fwing", "M")
	cp.start_project(camp, "floor", "L")
	var copy := Campaign.from_dict(JSON.parse_string(JSON.stringify(camp.to_dict())))
	var c2 := copy.my_parts()
	assert_eq(c2.spec_list("fwing").size(), 2)
	assert_eq(c2.research.size(), 1)
	assert_eq(String(c2.research[0]["area"]), "floor")
	assert_eq(c2.deliveries.size(), 1)
	assert_almost_eq(c2.next_share, 0.3, 0.0001)
	assert_almost_eq(c2.next_bank, cp.next_bank, 0.0001)
	assert_eq(int(c2.unit_on("fwing", 0)["uid"]), int(cp.unit_on("fwing", 0)["uid"]))


func test_pesquisa_de_save_antigo_termina_como_projeto() -> void:
	cp.research.append({"part": "rwing", "dir": "high", "days_left": 1, "days_total": 16, "cost": 2.2, "fix": -1})
	_days(1)
	assert_eq(cp.latest_spec("rwing"), 1)
	assert_eq(String(cp.deliveries[0]["area"]), "rwing")
	assert_gt(cp.car_effect(0), 0.0)


func test_ia_faz_projetos_e_melhora_ao_longo_do_ano() -> void:
	var before := {}
	for p: CarParts in camp.parts.values():
		before[p.team_id] = p.avg_effect()
	for i in 220:
		camp.day += 1
		for p: CarParts in camp.parts.values():
			p.day_step(camp)
	var better := 0
	for p: CarParts in camp.parts.values():
		if p.team_id == camp.player_team:
			continue
		assert_gt(p.deliveries.size(), 3, p.team_id)
		for e: Dictionary in p.deliveries:
			assert_between(float(e["ratio"]), 0.55, 1.21)
		if p.avg_effect() > float(before[p.team_id]):
			better += 1
	assert_eq(better, camp.teams().size() - 1, "todas as equipes da IA melhoraram")


func test_notas_por_area_e_registro_da_temporada() -> void:
	var a := camp.area_ratings("williams")
	for k: String in ["straight", "slow", "fast", "rel"]:
		assert_true(a.has(k), k)
	var best := camp.best_rival_areas()
	assert_gt(float(best["fast"]), 0.0)
	_finish("floor", "L")
	camp.refresh_rating()
	assert_gt(float(camp.area_ratings("williams")["fast"]), float(a["fast"]), "assoalho sobe as curvas rápidas")
	camp.log_ratings()
	assert_eq((camp.rating_log["williams"] as Array).size(), 2, "ponto de partida + rodada")
	assert_false(camp.area_last.is_empty())
