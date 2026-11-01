extends GutTest
## Integração: a tela de corrida monta a interface e as ordens do jogador chegam à simulação.

var screen: Control


func before_each() -> void:
	Session.player_team = "williams"
	Session.duration_pct = 0.25
	Session.race_seed = 2
	Session.debug_advance_s = 0.0
	Session.sim_overrides = {"weather": "dry", "incident_rate": 0.0}
	screen = load("res://src/ui/race_screen.tscn").instantiate()
	add_child_autofree(screen)
	await wait_process_frames(2)
	screen.paused = true  # o teste controla o tempo


func after_all() -> void:
	Session.sim_overrides = {}


func test_tela_monta_um_painel_para_cada_carro_do_jogador() -> void:
	assert_eq(screen._car_panels.size(), 2)
	for p: CarControlPanel in screen._car_panels:
		assert_eq(p.car.team["id"], "williams")


func test_botao_box_leva_o_carro_ao_box_com_o_pneu_escolhido() -> void:
	var panel: CarControlPanel = screen._car_panels[0]
	var target := "hard" if panel.car.tyre != "hard" else "medium"
	panel._compound_buttons[target].button_pressed = true
	panel._box_btn.button_pressed = true  # emite "toggled", como um toque do jogador
	assert_true(panel.car.pit_requested)
	var steps := 0
	while panel.car.pit_stops == 0 and steps < 30000:
		screen.sim.step()
		steps += 1
	assert_eq(panel.car.pit_stops, 1)
	assert_eq(panel.car.tyre, target)
	panel.refresh(1)
	assert_true(panel._box_btn.button_pressed, "ainda no pit lane: botão continua marcado")
	while panel.car.in_pit and steps < 40000:
		screen.sim.step()
		steps += 1
	panel.refresh(1)
	assert_false(panel._box_btn.button_pressed, "de volta à pista: botão solta")


func test_cancelar_box_antes_da_entrada() -> void:
	var panel: CarControlPanel = screen._car_panels[1]
	panel._box_btn.button_pressed = true
	panel._box_btn.button_pressed = false
	assert_false(panel.car.pit_requested)


func test_botoes_de_ritmo_mudam_o_modo_do_carro() -> void:
	var panel: CarControlPanel = screen._car_panels[0]
	var attack: Button = null
	for b in _all_buttons(panel):
		if b.text.to_lower() == "atacar":
			attack = b
	assert_not_null(attack)
	attack.emit_signal("pressed")
	assert_eq(panel.car.pace_mode, CarState.PaceMode.ATTACK)


func _all_buttons(node: Node) -> Array[Button]:
	var out: Array[Button] = []
	for c in node.get_children():
		if c is Button:
			out.append(c)
		out.append_array(_all_buttons(c))
	return out
