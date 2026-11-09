extends GutTest
## Integração: telas Patrocínios e Finanças da campanha.

var camp: Campaign


func before_each() -> void:
	camp = Campaign.new_real("williams")
	camp.budget_musd = 150.0
	Session.campaign = camp
	Session.player_team = "williams"


func after_all() -> void:
	Session.campaign = null


func _open(scene: String) -> Control:
	var screen: Control = load(scene).instantiate()
	add_child_autofree(screen)
	await wait_process_frames(2)
	return screen


func test_patrocinios_mostra_cinco_zonas_e_ofertas_da_zona_livre() -> void:
	var screen: Control = await _open("res://src/ui/campaign_sponsors_screen.tscn")
	assert_eq(screen._pins.size(), 5)
	assert_true(camp.sponsors.free_zones().has(screen._zone), "começa numa zona livre")
	assert_gt(screen._right.get_child_count(), 8)


func test_aceitar_oferta_pela_tela_fecha_contrato() -> void:
	var screen: Control = await _open("res://src/ui/campaign_sponsors_screen.tscn")
	var zone: String = screen._zone
	var before := camp.sponsor_per_race()
	var key: String = camp.sponsors.offers_for(camp, zone)[0]["key"]
	screen._on_accept(key)
	assert_true(camp.sponsors.contracts.has(zone))
	assert_gt(camp.sponsor_per_race(), before)


func test_pedir_mais_pela_tela_marca_a_oferta() -> void:
	var screen: Control = await _open("res://src/ui/campaign_sponsors_screen.tscn")
	var zone: String = screen._zone
	var key: String = camp.sponsors.offers_for(camp, zone)[0]["key"]
	screen._on_ask_more(key)
	assert_true(camp.sponsors.asked.has(key))


func test_selecionar_zona_ocupada_mostra_o_contrato_e_rescindir_cobra_multa() -> void:
	var screen: Control = await _open("res://src/ui/campaign_sponsors_screen.tscn")
	var taken: String = camp.sponsors.contracts.keys()[0]
	screen._on_zone(taken)
	var before := camp.budget_musd
	screen._on_terminate(taken)
	assert_lt(camp.budget_musd, before)
	assert_false(camp.sponsors.contracts.has(taken))


func test_financas_monta_com_livro_caixa_e_grafico() -> void:
	camp.record("sponsors", 10.0)
	camp.record("rd", 7.0)
	var screen: Control = await _open("res://src/ui/campaign_finance_screen.tscn")
	assert_not_null(screen)
	assert_almost_eq(camp.income_total(), 10.0, 0.001)
	assert_almost_eq(camp.expense_total(), 7.0, 0.001)


func test_nav_tem_patrocinios_e_financas_ativos() -> void:
	var screen: Control = await _open("res://src/ui/campaign_hub_screen.tscn")
	var names := []
	for b in _buttons(screen):
		if not b.disabled:
			names.append(b.tooltip_text)  # barra de ícones (v26)
	assert_true(names.has("Patroc."))
	assert_true(names.has("Caixa"))


func _buttons(node: Node) -> Array[Button]:
	var out: Array[Button] = []
	for c in node.get_children():
		if c is Button:
			out.append(c)
		out.append_array(_buttons(c))
	return out
