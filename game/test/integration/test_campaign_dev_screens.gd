extends GutTest
## Integração: telas Carro, Novo projeto e Fábrica da campanha (v42).

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


func _find_text(node: Node, needle: String) -> bool:
	if node is Label and (node as Label).text.to_upper().contains(needle.to_upper()):
		return true
	if node is Button and (node as Button).text.to_upper().contains(needle.to_upper()):
		return true
	for c in node.get_children():
		if _find_text(c, needle):
			return true
	return false


func test_tela_do_carro_mostra_notas_projetos_esforco_e_entregas() -> void:
	camp.my_parts().start_project(camp, "floor", "L")
	var screen: Control = await _open("res://src/ui/campaign_car_screen.tscn")
	for t in ["Notas do carro", "Curvas rápidas", "Projetos em andamento", "Assoalho", "Esforço da equipe", "Evolução", "Últimas entregas", "Novo projeto"]:
		assert_true(_find_text(screen, t), t)


func test_esforco_pela_tela_muda_a_divisao() -> void:
	var screen: Control = await _open("res://src/ui/campaign_car_screen.tscn")
	screen._on_effort(40.0)
	assert_almost_eq(camp.my_parts().next_share, 0.4, 0.0001)


func test_novo_projeto_escolhe_area_tamanho_e_inicia() -> void:
	var screen: Control = await _open("res://src/ui/campaign_project_screen.tscn")
	assert_true(_find_text(screen, "Faixa do resultado"))
	assert_true(_find_text(screen, "Quem aperta a faixa"))
	screen._area = "floor"
	screen._size = "L"
	screen._refresh()
	await wait_process_frames(1)
	var before := camp.budget_musd
	screen._on_start()
	assert_eq(camp.my_parts().research.size(), 1)
	assert_eq(String(camp.my_parts().research[0]["size"]), "L")
	assert_lt(camp.budget_musd, before)


func test_aviso_de_entrega_aparece_e_limpa() -> void:
	var cp := camp.my_parts()
	cp.start_project(camp, "fwing", "S")
	cp.research[0]["days_left"] = 1
	camp.day += 1
	cp.day_step(camp)
	assert_eq(cp.done_research.size(), 1)
	var screen: Control = await _open("res://src/ui/campaign_car_screen.tscn")
	await wait_process_frames(2)
	assert_true(_find_text(screen, "Projeto entregue"))
	assert_eq(cp.done_research.size(), 0)


func test_tela_da_fabrica_tem_quatro_cartoes_com_antes_e_depois() -> void:
	camp.dev.levels["wind"] = 2
	var screen: Control = await _open("res://src/ui/campaign_factory_screen.tscn")
	assert_true(_find_text(screen, "Aero: −8% de dias por projeto"), "agora")
	assert_true(_find_text(screen, "Aero: −15% de dias por projeto"), "próximo nível")
	assert_true(_find_text(screen, "AMPLIAR"))
	var before := camp.budget_musd
	screen._on_upgrade("sim")
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
