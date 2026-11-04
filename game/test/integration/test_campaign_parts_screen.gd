extends GutTest
## Integração: tela Carro · peças (carro interativo) e avisos das peças.

var camp: Campaign


func before_each() -> void:
	camp = Campaign.new_real("williams")
	camp.budget_musd = 150.0
	camp.detail = "advanced"
	Session.campaign = camp
	Session.player_team = "williams"


func after_all() -> void:
	Session.campaign = null


func _open() -> Control:
	var screen: Control = load("res://src/ui/campaign_parts_screen.tscn").instantiate()
	add_child_autofree(screen)
	await wait_process_frames(2)
	return screen


func test_monta_carro_com_seis_etiquetas_e_quatro_caracteristicas() -> void:
	var screen: Control = await _open()
	assert_eq(screen._stage._labels.size(), CarParts.part_ids().size(), "uma etiqueta por peça")
	assert_eq(screen._strip.get_child_count(), 4, "reta, lentas, rápidas, confiabilidade")


func test_tocar_na_peca_e_desenvolver_inicia_pesquisa() -> void:
	var screen: Control = await _open()
	(screen._stage._labels["rwing"] as Button).pressed.emit()
	assert_eq(screen._part, "rwing")
	screen._tab = "dev"
	screen._choice = "high"
	screen._refresh()
	var before := camp.budget_musd
	var go: CutButton = screen._panel.get_child(screen._panel.get_child_count() - 1)
	assert_eq(go.text, "INICIAR PESQUISA")
	go.pressed.emit()
	assert_false(camp.my_parts().research_of("rwing").is_empty())
	assert_lt(camp.budget_musd, before)


func test_usar_instala_unidade_nova_do_estoque() -> void:
	var cp := camp.my_parts()
	cp.research.append({"part": "fwing", "dir": "high", "days_left": 1, "days_total": 16, "cost": 2.2, "fix": -1})
	camp.day += 1
	cp.day_step(camp)
	cp.done_research.clear()
	cp.order_units(camp, "fwing", 1, 1)
	for i in 10:
		camp.day += 1
		cp.day_step(camp)
	var screen: Control = await _open()
	var ids := camp.team_driver_ids("williams")
	var opts: Array = screen._use_options(ids)
	assert_eq(opts[0]["kind"], "install")
	screen._choice = opts[0]["id"]
	screen._confirm_use(opts)
	assert_eq(int(cp.unit_on("fwing", 0)["spec"]), 1, "spec B no carro 0")


func test_aviso_de_pesquisa_concluida_aparece_e_encomenda() -> void:
	var cp := camp.my_parts()
	cp.research.append({"part": "floor", "dir": "fast", "days_left": 1, "days_total": 16, "cost": 3.0, "fix": -1})
	camp.day += 1
	cp.day_step(camp)
	assert_eq(cp.done_research.size(), 1)
	var screen: Control = await _open()
	await wait_process_frames(2)
	assert_eq(cp.done_research.size(), 0, "o aviso foi mostrado")
	var go: CutButton = null
	for b: Node in screen.find_children("*", "CutButton", true, false):
		if (b as CutButton).text == "CONFIRMAR" and b.get_parent() is VBoxContainer and b.get_parent().get_parent().get_parent() is PanelContainer \
				and not screen._panel.is_ancestor_of(b):
			go = b
	assert_not_null(go, "botão do aviso")
	go.pressed.emit()
	assert_eq(cp.queue.size(), 2, "encomendou 2 unidades (padrão)")
