extends GutTest
## Finanças (v31): prêmio oficial por posição e compromissos.

## (os testes do patrocínio por meta foram para test_sponsorship.gd na v42)


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
