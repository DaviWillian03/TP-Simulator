extends GutTest
## Integração: telas Carro (árvore de P&D) e Fábrica da campanha.

var camp: Campaign


func before_each() -> void:
	camp = Campaign.new_real("ferrari")
	camp.budget_musd = 150.0
	camp.detail = "advanced"
	Session.campaign = camp
	Session.player_team = "ferrari"


func after_all() -> void:
	Session.campaign = null


func _open(scene: String) -> Control:
	var screen: Control = load(scene).instantiate()
	add_child_autofree(screen)
	await wait_process_frames(2)
	return screen


func test_tela_do_carro_monta_arvore_e_painel() -> void:
	var screen: Control = await _open("res://src/ui/campaign_car_screen.tscn")
	assert_not_null(screen._tree)
	assert_eq(screen._rail.get_child_count(), 4, "4 departamentos")
	assert_gt(screen._right.get_child_count(), 5)


func test_tocar_no_no_seleciona_e_iniciar_projeto_paga() -> void:
	var screen: Control = await _open("res://src/ui/campaign_car_screen.tscn")
	var pos: Vector2 = screen._tree.node_position("aero.0.0")
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = pos
	screen._tree._gui_input(ev)
	assert_eq(screen._selected, "aero.0.0")
	var before := camp.budget_musd
	screen._on_start("aero.0.0")
	assert_eq(camp.dev.projects.size(), 1)
	assert_lt(camp.budget_musd, before)
	assert_eq(camp.dev.node_state("cur", "aero.0.0", camp), "now")
	screen._on_cancel("aero.0.0")
	assert_eq(camp.dev.projects.size(), 0)


func test_abas_do_carro_do_ano_seguinte_e_motor_apagado_para_cliente() -> void:
	var screen: Control = await _open("res://src/ui/campaign_car_screen.tscn")
	screen._on_car_tab("next")
	assert_eq(screen._car, "next")
	camp.dev.start_project(camp, "next", "chassis.0.0")
	assert_eq(camp.dev.projects[0]["car"], "next")
	var customer := Campaign.new_real("williams")
	assert_eq(customer.dev.node_state("cur", "engine.0.0", customer), "lock")


func test_modo_essencial_mostra_o_diretor_e_preenche_vagas() -> void:
	var screen: Control = await _open("res://src/ui/campaign_car_screen.tscn")
	screen._on_mode("essential")
	assert_eq(camp.detail, "essential")
	assert_eq(camp.dev.busy(), camp.dev.slots(), "o diretor preenche as vagas (peças e árvore)")
	screen._on_focus("aero")
	assert_eq(camp.dev.focus, "aero")


func test_sugerir_escolhe_um_no_aberto() -> void:
	var screen: Control = await _open("res://src/ui/campaign_car_screen.tscn")
	screen._on_suggest()
	assert_ne(screen._selected, "")
	assert_eq(camp.dev.node_state("cur", screen._selected, camp), "open")


func test_tela_da_fabrica_tem_quatro_cartoes_e_iniciar_obra() -> void:
	var screen: Control = await _open("res://src/ui/campaign_factory_screen.tscn")
	assert_eq(screen._grid.get_child_count(), 4, "um cartão por estrutura, na grade que rola")
	var before := camp.budget_musd
	camp.dev.start_upgrade(camp, "sim")
	assert_lt(camp.budget_musd, before)
	assert_false(camp.dev.work_of("sim").is_empty())


func test_nav_da_campanha_tem_carro_e_fabrica_ativos() -> void:
	var screen: Control = await _open("res://src/ui/campaign_hub_screen.tscn")
	var enabled := []
	for b in _buttons(screen):
		if not b.disabled and b.tooltip_text in ["Início", "Tabela", "Carro", "Sede"]:  # barra de ícones (v26)
			enabled.append(b.tooltip_text)
	assert_eq(enabled.size(), 4)


func _buttons(node: Node) -> Array[Button]:
	var out: Array[Button] = []
	for c in node.get_children():
		if c is Button:
			out.append(c)
		out.append_array(_buttons(c))
	return out
