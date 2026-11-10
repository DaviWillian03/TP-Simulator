extends GutTest
## Finanças (v31): patrocínio garantido × por meta, prêmio oficial por posição e compromissos.

func _camp() -> Campaign:
	var c := Campaign.new_real("williams")
	c.sponsors.contracts.clear()
	return c


func _offer(c: Campaign) -> Dictionary:
	var zone: String = Sponsorship.zones()[0]["id"]
	var o := c.sponsors.offers_for(c, zone)
	assert_gt(o.size(), 0)
	return {"zone": zone, "offer": o[0]}


func test_oferta_tem_garantido_e_meta_com_mesmo_total_e_maior_potencial() -> void:
	var c := _camp()
	var o: Dictionary = _offer(c)["offer"]
	assert_lt(float(o["goal_per_race"]), float(o["per_race"]), "por meta paga menos por corrida")
	var safe_year: float = float(o["per_race"]) * Campaign.calendar().size()
	var goal_year: float = float(o["goal_per_race"]) * Campaign.calendar().size() + float(o["goal_bonus"])
	assert_gt(goal_year, safe_year, "cumprida a meta, rende mais que o garantido")
	assert_gte(int(o["goal_pos"]), 1)


func test_contrato_por_meta_paga_o_bonus_so_se_a_meta_for_cumprida() -> void:
	var c := _camp()
	var d := _offer(c)
	var res := c.sponsors.accept(c, d["zone"], d["offer"]["key"], "goal")
	assert_true(res["ok"])
	var ct: Dictionary = c.sponsors.contracts[d["zone"]]
	assert_gt(int(ct["goal_pos"]), 0)
	assert_gt(float(ct["goal_bonus"]), 0.0)
	var pos := int(ct["goal_pos"])
	assert_eq(c.sponsors.settle_goals(c, pos), float(ct["goal_bonus"]), "na posição da meta: paga")
	assert_eq(c.sponsors.settle_goals(c, pos + 1), 0.0, "uma posição pior: não paga")


func test_contrato_garantido_nao_tem_meta() -> void:
	var c := _camp()
	var d := _offer(c)
	c.sponsors.accept(c, d["zone"], d["offer"]["key"])
	var ct: Dictionary = c.sponsors.contracts[d["zone"]]
	assert_eq(int(ct["goal_pos"]), 0)
	assert_eq(c.sponsors.settle_goals(c, 11), 0.0)


func test_fim_da_temporada_credita_o_bonus_da_meta_no_caixa() -> void:
	var c := _camp()
	var d := _offer(c)
	c.sponsors.accept(c, d["zone"], d["offer"]["key"], "goal")
	c.sponsors.contracts[d["zone"]]["goal_pos"] = 11  # meta folgada: qualquer posição cumpre
	var before := c.budget_musd
	var bonus: float = float(c.sponsors.contracts[d["zone"]]["goal_bonus"])
	c.round = 22
	c.close_season()
	assert_gte(c.budget_musd - before, bonus, "bônus entra no caixa (além do prêmio)")


func test_save_preserva_a_meta_do_contrato() -> void:
	var c := _camp()
	var d := _offer(c)
	c.sponsors.accept(c, d["zone"], d["offer"]["key"], "goal")
	var back := Sponsorship.from_dict(JSON.parse_string(JSON.stringify(c.sponsors.to_dict())))
	assert_eq(int(back.contracts[d["zone"]]["goal_pos"]), int(c.sponsors.contracts[d["zone"]]["goal_pos"]))
	assert_almost_eq(float(back.contracts[d["zone"]]["goal_bonus"]), float(c.sponsors.contracts[d["zone"]]["goal_bonus"]), 0.001)


func test_compromissos_somam_folha_operacao_e_emprestimo() -> void:
	var c := Campaign.new_real("williams")
	var base := c.committed_total()
	assert_gt(base, 0.0, "folha e operação já são compromissos")
	var ids: Array = c.commitments().map(func(x: Dictionary) -> String: return String(x["id"]))
	assert_true(ids.has("payroll") and ids.has("ops"))
	assert_true(c.take_loan(10.0, 0))
	assert_gt(c.committed_total(), base, "o empréstimo vira compromisso")
	assert_almost_eq(c.free_cash(), c.budget_musd - c.committed_total(), 0.0001)


func test_projecao_do_premio_mostra_quanto_vale_subir_e_descer() -> void:
	var c := Campaign.new_real("williams")
	c.team_points["mercedes"] = 100
	c.team_points["williams"] = 50
	c.team_points["haas"] = 20
	var p := c.prize_projection()
	var table := c.prize_table()
	assert_eq(float(p["prize"]), float(table[int(p["position"]) - 1]))
	assert_gt(float(p["up"]), 0.0)
	assert_gt(int(p["gap_up"]), 0)
	assert_eq(c.prize_table().size(), 12)
