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


func test_cartao_do_radio_responde_e_chama_para_o_box() -> void:
	var car: CarState = screen._car_panels[0].car
	screen.sim.radio.ask(car, "Pergunta de teste?", [{"label": "Box: duro", "action": "pit", "arg": "hard"}, {"label": "Fica", "action": "stay", "arg": ""}], 0)
	screen._refresh_ui()
	assert_true(screen._radio.visible, "cartão aparece")
	var first: Button = screen._radio._answers.get_child(0)
	first.emit_signal("pressed")
	assert_true(car.pit_requested)
	assert_eq(car.pit_compound, "hard")
	screen._refresh_ui()
	assert_false(screen._radio.visible, "cartão some depois da resposta")


func test_menu_dados_abre_e_atualiza_as_tres_abas() -> void:
	for i in 600:
		screen.sim.step()
	screen._drawer.visible = true
	for tab in 3:
		screen._drawer._select(tab)
		screen._drawer.refresh()
	screen._drawer._select(0)
	screen._drawer.refresh()
	var cells: Array = screen._drawer._table._rows[0]["cells"]
	assert_eq((cells[0].get_child(0) as Label).text, "1", "posição no quadrado da equipe")
	assert_ne((cells[1] as Label).text, "", "nome do piloto")


func test_faixa_de_status_mostra_safety_car() -> void:
	for i in 600:
		screen.sim.step()
	screen.sim.control.deploy_sc("teste")
	screen._refresh_ui()
	assert_true(screen._standings._status_panel.visible)
	assert_string_contains(screen._standings._status.text, "SAFETY CAR")


func test_tempo_acelerado_leva_a_camera_3d_para_a_vista_geral_e_depois_volta() -> void:
	var view: TrackView3D = screen._track_view
	view.cycle_camera()  # segue o primeiro carro do jogador
	assert_eq(view.cam_mode, TrackView3D.CamMode.FOLLOW_1)
	screen.set_time_scale(8.0)
	assert_eq(view.cam_mode, TrackView3D.CamMode.OVERVIEW)
	screen.set_time_scale(4.0)
	assert_eq(view.cam_mode, TrackView3D.CamMode.OVERVIEW)
	screen.set_time_scale(1.0)
	assert_eq(view.cam_mode, TrackView3D.CamMode.FOLLOW_1)
	assert_almost_eq(view.distance, 140.0, 0.01)


func test_camera_escolhida_no_tempo_acelerado_e_respeitada() -> void:
	var view: TrackView3D = screen._track_view
	screen.set_time_scale(8.0)
	view.cycle_camera()  # jogador escolhe seguir um carro mesmo no 8×
	screen.set_time_scale(2.0)
	assert_eq(view.cam_mode, TrackView3D.CamMode.FOLLOW_1)
