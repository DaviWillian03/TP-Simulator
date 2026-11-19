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


func _find_text(node: Node, needle: String) -> bool:
	if node is Label and (node as Label).text.to_upper().contains(needle.to_upper()):
		return true
	if node is Button and (node as Button).text.to_upper().contains(needle.to_upper()):
		return true
	for c in node.get_children():
		if _find_text(c, needle):
			return true
	return false


func test_patrocinios_mostra_tres_ofertas_do_principal_e_vagas_secundarias() -> void:
	camp.sponsors.contracts.clear()
	var screen: Control = await _open("res://src/ui/campaign_sponsors_screen.tscn")
	assert_true(_find_text(screen, "escolha 1 de 3 ofertas"))
	for o: Dictionary in camp.sponsors.offers_for(camp, "main"):
		assert_true(_find_text(screen, String(o["brand"])), String(o["brand"]))
	assert_true(_find_text(screen, "ver 3 ofertas"))
	assert_true(_find_text(screen, "Bônus em jogo"))


func test_assinar_pela_tela_fecha_contrato() -> void:
	camp.sponsors.contracts.clear()
	var screen: Control = await _open("res://src/ui/campaign_sponsors_screen.tscn")
	var o: Dictionary = camp.sponsors.offers_for(camp, "main")[2]
	screen._on_accept("main", String(o["key"]))
	assert_true(camp.sponsors.contracts.has("main"))
	assert_eq(String(camp.sponsors.contracts["main"]["kind"]), "bold")


func test_contrato_assinado_mostra_metas_com_progresso() -> void:
	camp.sponsors.contracts.clear()
	camp.sponsors.accept(camp, "main", String(camp.sponsors.offers_for(camp, "main")[1]["key"]))
	var screen: Control = await _open("res://src/ui/campaign_sponsors_screen.tscn")
	var g: Dictionary = camp.sponsors.contracts["main"]["goals"][0]
	assert_true(_find_text(screen, Sponsorship.goal_text(g)))


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


func test_financas_tem_quatro_abas_e_todas_montam() -> void:
	var screen: Control = await _open("res://src/ui/campaign_finance_screen.tscn")
	for tab: String in ["cash", "income", "prize", "commit"]:
		screen._tab = tab
		screen._show_tab()
		await wait_process_frames(2)
		assert_gt(screen._holder.get_child_count(), 1, "aba %s montou os cartões" % tab)


