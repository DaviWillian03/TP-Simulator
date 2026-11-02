extends GutTest
## Integração: tela Pessoal (pilotos, técnicos, mercado e negociação).

var camp: Campaign


func before_each() -> void:
	camp = Campaign.new_real("williams")
	camp.budget_musd = 200.0
	Session.campaign = camp
	Session.player_team = "williams"


func after_all() -> void:
	Session.campaign = null


func _open() -> Control:
	var screen: Control = load("res://src/ui/campaign_staff_screen.tscn").instantiate()
	add_child_autofree(screen)
	await wait_process_frames(2)
	return screen


func _free_driver() -> Dictionary:
	for e in camp.personnel.market(camp, "driver", "free"):
		if int(e["rating"]) >= 70:
			return e
	return {}


func test_tela_mostra_pilotos_tecnicos_e_mercado() -> void:
	var screen: Control = await _open()
	assert_gt(screen._left.get_child_count(), 6)
	assert_gt(screen._list.get_child_count(), 10, "mercado de pilotos")
	screen._on_kind("staff")
	assert_gt(screen._list.get_child_count(), 10, "mercado de técnicos")


func test_negociar_com_proposta_alta_assina_para_a_virada() -> void:
	var screen: Control = await _open()
	var e := _free_driver()
	screen._open_sheet(e["id"])
	assert_not_null(screen._sheet)
	screen._sheet.salary = float(e["ask"]) * 1.5
	screen._sheet.years = 3
	screen._sheet._update()
	screen._sheet._on_propose()
	assert_null(screen._sheet, "folha fecha ao assinar")
	assert_true(camp.personnel.pending.has(e["id"]))


func test_contraproposta_aparece_e_pode_ser_aceita() -> void:
	var screen: Control = await _open()
	var e := _free_driver()
	screen._open_sheet(e["id"])
	var sheet = screen._sheet
	sheet.salary = float(e["ask"]) * 0.85
	sheet._update()
	sheet._on_propose()
	assert_true(sheet._reply.visible)
	assert_true(sheet._accept_btn.visible, "botão de aceitar a contraproposta")
	sheet._on_accept_counter()
	assert_true(camp.personnel.pending.has(e["id"]))


func test_proposta_baixa_e_recusada_e_nao_assina() -> void:
	var screen: Control = await _open()
	var e := _free_driver()
	screen._open_sheet(e["id"])
	var sheet = screen._sheet
	sheet.salary = float(e["ask"]) * 0.3
	sheet._update()
	sheet._on_propose()
	assert_eq(sheet._reply_title.text, "Recusa")
	assert_true(camp.personnel.pending.is_empty())
	sheet.closed.emit("")
	sheet.queue_free()


func test_dispensar_pela_folha_marca_o_piloto() -> void:
	var screen: Control = await _open()
	var d: Dictionary = camp.personnel.player_drivers(camp)[0]
	camp.personnel.contracts[d["id"]]["until"] = camp.season + 2
	screen._open_sheet(d["id"])
	screen._sheet._on_dismiss()
	assert_true(camp.personnel.dismissed.has(d["id"]))
	assert_null(screen._sheet)


func test_trocar_tecnico_filtra_o_mercado_pela_funcao() -> void:
	var screen: Control = await _open()
	screen._on_swap("aero")
	assert_eq(screen._kind, "staff")
	assert_eq(screen._role, "aero")
	for c in screen._list.get_children():
		assert_string_contains(((c as Button).get_child(0).get_child(1).get_child(1) as Label).text.to_lower(), "aerodin")
