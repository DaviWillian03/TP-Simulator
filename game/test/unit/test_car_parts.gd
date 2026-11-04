extends GutTest
## Peças físicas do carro (decisões do usuário, 2026-11-04): pesquisa → especificação (resultado escondido) → fabricar
## unidades → instalar em cada carro; só o carro equipado ganha; o resultado real aparece depois da corrida; a IA usa
## as mesmas regras.

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


## Pesquisa uma peça até o fim e devolve o índice da nova especificação.
func _research(pid: String, dir_id: String) -> int:
	assert_true(cp.start_research(camp, pid, dir_id), "pesquisa iniciada")
	_days(int(cp.research_of(pid)["days_left"]))
	return cp.latest_spec(pid)


func test_comeca_com_a_versao_a_nos_dois_carros_e_reserva_no_estoque() -> void:
	for pid: String in CarParts.part_ids():
		assert_eq(cp.spec_list(pid).size(), 1)
		assert_false(cp.unit_on(pid, 0).is_empty(), pid)
		assert_false(cp.unit_on(pid, 1).is_empty(), pid)
	assert_eq(cp.stock("fwing").size(), CarParts.SPARE_A)
	assert_eq(cp.car_effect(0), 0.0, "versão A: sem efeito")
	assert_eq(camp.parts.size(), camp.teams().size(), "todas as equipes têm peças")


func test_pesquisa_ocupa_vaga_custa_e_libera_a_spec_com_resultado_escondido() -> void:
	var cash := camp.budget_musd
	var info := cp.research_info(camp, "fwing", "high")
	assert_true(info["ok"])
	assert_true(cp.start_research(camp, "fwing", "high"))
	assert_almost_eq(camp.budget_musd, cash - float(info["cost"]), 0.001)
	assert_eq(camp.dev.busy(), 1, "a pesquisa da peça ocupa uma vaga de projeto")
	assert_eq(cp.research_info(camp, "fwing", "low")["reason"], "now", "uma pesquisa por peça")
	_days(int(info["days"]))
	assert_eq(cp.spec_list("fwing").size(), 2)
	var s := cp.spec("fwing", 1)
	assert_eq(s["v"], "B")
	assert_false(bool(s["revealed"]), "o resultado real só aparece depois da corrida")
	assert_true(["good", "small", "bad"].has(s["outcome"]))
	assert_eq(camp.dev.busy(), 0)
	assert_eq(cp.done_research.size(), 1, "aviso de pesquisa concluída para o jogador")


func test_estoque_nao_melhora_o_carro_so_o_carro_equipado() -> void:
	var b := _research("fwing", "high")
	cp.spec("fwing", b)["real"] = {"slow": 2.0, "straight": -1.0}  # força um bom resultado para medir
	assert_true(cp.order_units(camp, "fwing", b, 1))
	_days(cp.ready_in(camp, "fwing", 0) + 10)
	var units := cp.stock("fwing", b)
	assert_eq(units.size(), 1, "unidade pronta no estoque")
	assert_eq(cp.car_effect(0), 0.0, "no estoque não vale nada")
	cp.install(int(units[0]["uid"]), 0)
	assert_gt(cp.car_effect(0, {"straight": 0.0, "slow": 1.0, "fast": 0.0}), 1.9, "carro 0 ganhou nas curvas lentas")
	assert_eq(cp.car_effect(1), 0.0, "o outro carro continua igual")
	assert_eq(cp.stock("fwing", 0).size(), CarParts.SPARE_A + 1, "a peça antiga voltou para o estoque")


func test_efeito_depende_da_pista() -> void:
	var b := _research("rwing", "high")
	cp.spec("rwing", b)["real"] = {"slow": 2.0, "straight": -1.0}
	cp.order_units(camp, "rwing", b, 1, [0])
	_days(20)
	var monaco := Campaign.track_profile("monaco")
	var monza := Campaign.track_profile("monza")
	assert_gt(cp.car_effect(0, monaco), 0.0, "alta carga é boa em Mônaco")
	assert_lt(cp.car_effect(0, monza), 0.0, "e ruim em Monza")


func test_corrida_revela_o_resultado_e_desgasta_as_unidades() -> void:
	var b := _research("floor", "fast")
	cp.order_units(camp, "floor", b, 1, [1])
	_days(20)
	assert_eq(int(cp.unit_on("floor", 1)["spec"]), b)
	var out := cp.after_race(camp)
	assert_eq(out.size(), 1)
	assert_true(bool(cp.spec("floor", b)["revealed"]))
	assert_eq(cp.reveals.size(), 1, "aviso para o jogador na sede")
	assert_gt(float(cp.unit_on("fwing", 0)["wear"]), 0.0)


func test_upgrade_ruim_piora_e_correcao_pode_recuperar() -> void:
	var b := _research("susp", "traction")
	var s := cp.spec("susp", b)
	s["outcome"] = "bad"
	s["real"] = {"slow": -1.0}
	s["revealed"] = true
	var fix := cp.fix_info(camp, "susp", b)
	assert_true(fix["ok"])
	assert_lt(float(fix["cost"]), cp.research_cost("susp", "traction"), "corrigir é mais barato")
	assert_true(cp.start_fix(camp, "susp", b))
	_days(int(fix["days"]))
	assert_true(bool(s["fixed"]))
	assert_false(bool(s["revealed"]), "a correção volta a ser testada na pista")


func test_chance_de_acerto_vem_da_fabrica_e_da_ousadia() -> void:
	var safe := cp.success_chance(camp, "fwing", "high")
	var bold := cp.success_chance(camp, "fwing", "bold")
	assert_lt(bold, safe, "direção ousada: mais risco")
	camp.dev.levels["wind"] = 5
	assert_gt(cp.success_chance(camp, "fwing", "high"), safe, "túnel de vento melhor: mais acerto")
	var odds := cp.outcome_odds(camp, "fwing", "high")
	assert_almost_eq(float(odds["good"]) + float(odds["small"]) + float(odds["bad"]), 1.0, 0.0001)


func test_motor_so_para_quem_fabrica() -> void:
	assert_eq(cp.research_info(camp, "pu", "power")["reason"], "engine", "Williams usa motor Mercedes")
	var merc := Campaign.new_real("mercedes")
	assert_true(merc.my_parts().research_info(merc, "pu", "power")["ok"])


func test_preparacao_recomendada_instala_a_melhor_peca_para_a_pista() -> void:
	var b := _research("fwing", "high")
	cp.spec("fwing", b)["real"] = {"slow": 2.0, "straight": -1.0}
	cp.spec("fwing", b)["revealed"] = true
	cp.order_units(camp, "fwing", b, 2)
	_days(30)
	assert_gt(cp.auto_prepare(Campaign.track_profile("monaco")), 0)
	assert_eq(int(cp.unit_on("fwing", 0)["spec"]), b)
	assert_eq(int(cp.unit_on("fwing", 1)["spec"]), b)


func test_gp_leva_o_efeito_de_cada_carro() -> void:
	var b := _research("fwing", "high")
	cp.spec("fwing", b)["real"] = {"slow": 2.0}
	cp.order_units(camp, "fwing", b, 1, [0])
	_days(20)
	camp.refresh_rating()
	var gp := GameData.team_by_id(camp.teams_for_gp("monaco"), "williams")
	var ids := camp.team_driver_ids("williams")
	assert_gt(float(gp["car_delta"][ids[0]]), float(gp["car_delta"][ids[1]]))
	assert_almost_eq(float(gp["car_rating"]), camp.base_rating, 0.0001, "a nota da equipe volta à base; o carro leva o delta")


func test_salva_e_carrega() -> void:
	var b := _research("fwing", "low")
	cp.order_units(camp, "fwing", b, 1)
	var copy := Campaign.from_dict(JSON.parse_string(JSON.stringify(camp.to_dict())))
	var c2 := copy.my_parts()
	assert_eq(c2.spec_list("fwing").size(), 2)
	assert_eq(c2.queue.size(), 1)
	assert_eq(c2.spec("fwing", b)["outcome"], cp.spec("fwing", b)["outcome"])
	assert_eq(int(c2.unit_on("fwing", 0)["uid"]), int(cp.unit_on("fwing", 0)["uid"]))


func test_ia_pesquisa_instala_e_tambem_erra() -> void:
	var outcomes := {}
	for i in 220:
		camp.day += 1
		for p: CarParts in camp.parts.values():
			p.day_step(camp)
	var installed_new := 0
	for p: CarParts in camp.parts.values():
		if p.team_id == camp.player_team:
			continue
		for pid: String in CarParts.part_ids():
			for s: Dictionary in p.spec_list(pid):
				outcomes[s["outcome"]] = true
			if int(p.unit_on(pid, 0)["spec"]) > 0:
				installed_new += 1
	assert_true(outcomes.has("good"))
	assert_true(outcomes.has("bad") or outcomes.has("small"), "a IA também erra")
	assert_gt(installed_new, 10, "a IA instala as peças novas")
