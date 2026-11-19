extends GutTest
## Patrocínios v42 (2026-11-19): principal + 3 secundários, 3 ofertas por vaga (garantido, equilibrado, ousado),
## fixo por corrida + bônus por metas (não cumprir só perde o bônus), marcas fictícias, migração do save antigo.

var camp: Campaign


func before_each() -> void:
	camp = Campaign.new_real("williams")
	camp.detail = "advanced"
	camp.sponsors.contracts.clear()
	camp.sponsors.offers.clear()


func _offer(slot_id: String, kind_id: String) -> Dictionary:
	for o: Dictionary in camp.sponsors.offers_for(camp, slot_id):
		if o["kind"] == kind_id:
			return o
	return {}


func test_principal_e_tres_secundarios() -> void:
	var ids: Array = Sponsorship.slots().map(func(z: Dictionary) -> String: return String(z["id"]))
	assert_eq(ids.size(), 4)
	assert_eq(ids[0], "main")
	var total := 0.0
	for z: Dictionary in Sponsorship.slots():
		total += float(z["share"])
	assert_almost_eq(total, 1.0, 0.001, "as fatias somam o patrocínio base")


func test_tres_ofertas_por_vaga_com_tipos_diferentes() -> void:
	var o := camp.sponsors.offers_for(camp, "main")
	assert_eq(o.size(), 3)
	var kinds: Array = o.map(func(x: Dictionary) -> String: return String(x["kind"]))
	assert_eq(kinds, ["safe", "balanced", "bold"])
	var brands: Array = o.map(func(x: Dictionary) -> String: return String(x["brand"]))
	assert_ne(brands[0], brands[1])
	assert_true((_offer("main", "safe")["goals"] as Array).is_empty(), "garantido: sem metas")
	assert_false((_offer("main", "bold")["goals"] as Array).is_empty())
	assert_eq(camp.sponsors.offers_for(camp, "main")[0]["key"], o[0]["key"], "as ofertas não mudam ao reabrir a tela")


func test_ousado_paga_menos_fixo_e_mais_potencial() -> void:
	var safe := _offer("main", "safe")
	var bold := _offer("main", "bold")
	var n := Campaign.calendar().size()
	assert_lt(float(bold["per_race"]), float(safe["per_race"]))
	assert_gt(float(bold["per_race"]) * n + float(bold["bonus_total"]), float(safe["per_race"]) * n, "com as metas cumpridas, rende mais")


func test_marcas_sao_ficticias() -> void:
	var names: Array = (Sponsorship.data()["brands"] as Array).map(func(b: Dictionary) -> String: return String(b["name"]))
	for real: String in ["Ipiranga", "Havaianas", "Natura", "Petrobras", "Shell"]:
		assert_false(names.has(real), real)


func test_aceitar_fecha_contrato_e_tira_as_ofertas() -> void:
	var o := _offer("main", "balanced")
	var r := camp.sponsors.accept(camp, "main", String(o["key"]))
	assert_true(r["ok"], str(r))
	assert_eq(String(camp.sponsors.contracts["main"]["brand"]), String(o["brand"]))
	assert_eq(camp.sponsors.offers_for(camp, "main").size(), 0, "vaga ocupada não tem ofertas")
	assert_false(camp.sponsors.accept(camp, "main", String(o["key"]))["ok"])
	assert_almost_eq(camp.sponsors.per_race_total(), float(o["per_race"]), 0.001)


func test_diretor_comercial_assina_o_equilibrado_antes_da_corrida() -> void:
	assert_gt(camp.sponsor_per_race(), 0.0, "previsão conta a vaga livre pelo valor garantido")
	assert_eq(camp.sponsors.fill_free(camp), 4)
	for z: String in camp.sponsors.contracts:
		assert_eq(String(camp.sponsors.contracts[z]["kind"]), "balanced")
	assert_true(camp.sponsors.free_slots().is_empty())


func test_meta_de_contagem_paga_uma_vez_quando_cumprida() -> void:
	var o := _offer("main", "balanced")
	camp.sponsors.accept(camp, "main", String(o["key"]))
	var c: Dictionary = camp.sponsors.contracts["main"]
	c["goals"] = [{"type": "podiums", "target": 1, "bonus": 5.0, "paid": false}, {"type": "wins", "target": 3, "bonus": 9.0, "paid": false}]
	assert_eq(camp.sponsors.after_race(camp), 0.0, "sem pódio ainda")
	var me: String = camp.team_driver_ids("williams")[0]
	var others: Array = camp.drivers().map(func(d: Dictionary) -> String: return String(d["id"])).filter(func(id: String) -> bool: return id != me)
	camp.history.append({"round": 1, "circuit": "x", "results": [others[0], me] + others.slice(1)})
	assert_eq(camp.sponsors.after_race(camp), 5.0, "pódio: paga o bônus")
	assert_eq(camp.sponsors.after_race(camp), 0.0, "não paga de novo")
	var p := Sponsorship.progress(camp, c["goals"][1])
	assert_eq(int(p["value"]), 0)
	assert_false(bool(c["goals"][1]["paid"]), "vitórias: ainda não")


func test_meta_de_posicao_paga_no_fim_do_ano_so_se_cumprida() -> void:
	camp.sponsors.accept(camp, "main", String(_offer("main", "bold")["key"]))
	var c: Dictionary = camp.sponsors.contracts["main"]
	c["goals"] = [{"type": "pos", "target": 5, "bonus": 12.0, "paid": false}]
	assert_eq(camp.sponsors.settle_goals(camp, 6), 0.0, "6º: perde só o bônus")
	assert_eq(camp.sponsors.settle_goals(camp, 5), 12.0)
	assert_eq(camp.sponsors.settle_goals(camp, 1), 0.0, "já pago")


func test_fim_da_temporada_credita_o_bonus_no_caixa() -> void:
	camp.sponsors.accept(camp, "main", String(_offer("main", "bold")["key"]))
	camp.sponsors.contracts["main"]["goals"] = [{"type": "pos", "target": 12, "bonus": 7.0, "paid": false}]
	var before := camp.budget_musd
	camp.round = Campaign.calendar().size()
	camp.close_season()
	assert_gte(camp.budget_musd - before, 7.0, "bônus entra no caixa (além do prêmio)")


func test_contratos_terminam_na_virada_e_chegam_ofertas_novas() -> void:
	camp.sponsors.fill_free(camp)
	camp.start_next_season()
	assert_eq(camp.sponsors.contracts.size(), 0, "modo avançado: o jogador escolhe de novo")
	var o := camp.sponsors.offers_for(camp, "nose")
	assert_eq(o.size(), 3)
	assert_eq(int(o[0]["season"]), camp.season)


func test_marketing_sobe_valor_e_numero_de_metas() -> void:
	camp.dev.set_all_levels(1)
	var v1 := float(_offer("main", "safe")["per_race"])
	var g1 := (_offer("main", "bold")["goals"] as Array).size()
	camp.sponsors.offers.clear()
	camp.dev.levels["media"] = 4
	var v4 := float(_offer("main", "safe")["per_race"])
	var g4 := (_offer("main", "bold")["goals"] as Array).size()
	assert_gt(v4, v1, "ofertas mais valiosas (+25% contra a sorte de ±9%)")
	assert_gt(g4, g1, "mais metas por oferta")


func test_save_preserva_contratos_metas_e_ofertas() -> void:
	camp.sponsors.accept(camp, "main", String(_offer("main", "bold")["key"]))
	camp.sponsors.contracts["main"]["goals"][0]["paid"] = true
	camp.sponsors.offers_for(camp, "halo")
	var back := Sponsorship.from_dict(JSON.parse_string(JSON.stringify(camp.sponsors.to_dict())))
	assert_eq(String(back.contracts["main"]["brand"]), String(camp.sponsors.contracts["main"]["brand"]))
	assert_true(bool(back.contracts["main"]["goals"][0]["paid"]))
	assert_eq(int(back.contracts["main"]["goals"][0]["target"]), int(camp.sponsors.contracts["main"]["goals"][0]["target"]))
	assert_eq((back.offers["halo"] as Array).size(), 3)
	assert_almost_eq(back.base, camp.sponsors.base, 0.001)


func test_save_antigo_de_zonas_vira_vagas_novas() -> void:
	var old := {"contracts": {"rear_wing": {"brand": "Ipiranga", "category": "Energia", "tier": 2, "per_race": 1.2, "bonus": 0.2, "until": 2026},
		"sidepods": {"brand": "Natura", "category": "Beleza", "tier": 2, "per_race": 0.8, "bonus": 0.1, "until": 2027}}, "news": []}
	var s := Sponsorship.from_dict(old)
	assert_almost_eq(s.base, 2.0, 0.001, "o total antigo vira o patrocínio base")
	assert_true(s.contracts.has("main"))
	assert_eq(s.contracts.size(), 2)
	assert_almost_eq(s.per_race_total(), 2.0 * (0.55 + 0.15), 0.05)
	for c: Dictionary in s.contracts.values():
		assert_false(String(c["brand"]) in ["Ipiranga", "Natura"], "marcas reais trocadas por fictícias")
