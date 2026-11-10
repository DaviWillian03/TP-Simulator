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


func test_chamar_box_abre_a_tela_do_box_sem_pausar() -> void:
	var panel: CarControlPanel = screen._car_panels[0]
	panel.pit_pressed.emit(panel.car)
	assert_not_null(screen._pit, "a tela do box abre")
	assert_true(screen.time_scale <= RaceScreen_PIT_MAX, "velocidade limitada a 2×")
	assert_eq(screen._pit.get_parent(), screen._layer)
	assert_eq(screen._track_view.get_parent(), screen._pit._mini, "a pista vai para a miniatura")
	screen._pit._cancel()
	assert_null(screen._pit)
	assert_eq(screen._track_view.get_parent(), screen._track_holder, "a pista volta ao lugar")


const RaceScreen_PIT_MAX := 2.0


func test_confirmar_plano_leva_o_carro_ao_box_com_o_pneu_escolhido() -> void:
	var car: CarState = screen._car_panels[0].car
	var target := "hard" if car.tyre != "hard" else "medium"
	screen._open_pit(car)
	screen._pit._compound = target
	screen._pit._wing = 1
	screen._pit._confirm()
	assert_null(screen._pit, "tela fecha ao confirmar")
	assert_true(car.pit_requested)
	assert_eq(car.plan["compound"], target)
	var steps := 0
	while car.pit_stops == 0 and steps < 30000:
		screen.sim.step()
		steps += 1
	assert_eq(car.pit_stops, 1)
	assert_eq(car.tyre, target)
	assert_eq(car.wing_step, 1, "ajuste de asa aplicado na parada")
	assert_eq(PitStop.sets_left(car, target), PitStop.DEFAULT_STOCK[target]["new"] - 1, "gastou um jogo do estoque")


func test_cancelar_box_pela_tela() -> void:
	var car: CarState = screen._car_panels[1].car
	screen.sim.request_pit(car, "hard")
	screen._open_pit(car)
	screen._pit._cancel()
	assert_false(car.pit_requested)
	assert_true(car.plan.is_empty())


func test_tela_do_box_oferece_punicao_e_custa_tempo() -> void:
	var car: CarState = screen._car_panels[0].car
	car.penalty_pending_s = 5.0
	screen._open_pit(car)
	assert_true(screen._pit._serve, "cumprir a punição vem marcado")
	var with_pen: float = screen._pit._estimate_total()
	screen._pit._serve = false
	var without: float = screen._pit._estimate_total()
	assert_almost_eq(with_pen - without, 5.0, 0.01)
	screen._pit._cancel()


func test_parada_dupla_segura_o_companheiro_uma_volta() -> void:
	var car: CarState = screen._car_panels[0].car
	var mate: CarState = screen._car_panels[1].car
	screen._open_pit(car)
	screen._pit._double = 1
	screen._pit._confirm()
	assert_true(car.pit_requested)
	assert_false(mate.pit_requested, "o companheiro espera")
	assert_eq(mate.pit_defer_laps, mate.laps_done + 1)


func test_minijogo_de_toque_aparece_no_box_e_ajusta_o_tempo() -> void:
	var car: CarState = screen._car_panels[0].car
	screen.set_time_scale(4.0)
	screen.sim.request_pit(car, "hard")
	var steps := 0
	while not (car.in_pit and car.box_hold_s > 0.0) and steps < 30000:
		screen.sim.step()
		steps += 1
	assert_not_null(screen._tap, "o mini-jogo abre quando o carro para")
	assert_eq(screen.time_scale, 1.0, "carro parado: 1×")
	var hold: float = car.box_hold_s
	screen._tap._t = PitTapOverlay.SWEEP_S * 0.5  # marcador no centro do verde
	screen._tap._tap()
	assert_true(car.box_tapped)
	assert_almost_eq(car.box_hold_s, hold + PitStop.TAP_PERFECT_S, 0.01)
	while car.in_pit and steps < 40000:
		screen.sim.step()
		steps += 1
	screen._tap._process(1.0)
	assert_null(screen._tap, "fecha depois da parada")
	assert_eq(screen.time_scale, 4.0, "volta à velocidade anterior")


func test_precisao_do_toque() -> void:
	assert_eq(PitTapOverlay.accuracy_at(0.5), 1.0)
	assert_eq(PitTapOverlay.accuracy_at(0.0), 0.0)
	assert_between(PitTapOverlay.accuracy_at(0.4), 0.0, 1.0)


func test_tocar_na_torre_segue_o_carro_e_tocar_de_novo_volta_a_vista_geral() -> void:
	var car: CarState = screen.sim.cars[7]
	screen._standings.driver_pressed.emit(car)
	assert_eq(screen._track_view.cam_mode, TrackView3D.CamMode.CAR)
	assert_eq(screen._track_view.followed, car)
	assert_eq(screen._standings.followed, car, "linha em foco na torre")
	screen._standings.driver_pressed.emit(car)
	assert_eq(screen._track_view.cam_mode, TrackView3D.CamMode.OVERVIEW)
	assert_null(screen._standings.followed)


func test_torre_alterna_diferenca_para_o_carro_da_frente_e_para_o_lider() -> void:
	for i in 900:
		screen.sim.step()
	var order: Array[CarState] = screen.sim.standings()
	var st: StandingsPanel = screen._standings
	st.interval_mode = true
	st.refresh()
	var ahead: float = screen.sim.gap_to_leader_s(order[2]) - screen.sim.gap_to_leader_s(order[1])
	assert_eq((st._rows[2]["gap"] as Label).text, "+%.1f" % ahead)
	st.interval_mode = false
	st.refresh()
	assert_eq((st._rows[2]["gap"] as Label).text, "+%.1f" % screen.sim.gap_to_leader_s(order[2]))


func test_icones_de_status_e_abandono_na_torre() -> void:
	for i in 900:
		screen.sim.step()
	var st: StandingsPanel = screen._standings
	var order: Array[CarState] = screen.sim.standings()
	var rival: CarState = order[4]
	rival.investigation = {"until_s": 999.0, "secs": 5, "reason": "teste", "guilty": true}
	var pen: CarState = order[5]
	pen.penalty_pending_s = 5.0
	st.refresh()
	assert_true(st._rows[4]["icons"]["investigation"].visible, "triângulo amarelo")
	assert_true(st._rows[5]["icons"]["penalty"].visible, "círculo vermelho")
	assert_eq(st._rows[order.find(screen.sim.fastest_lap_car)]["icons"]["fastest"].visible, screen.sim.fastest_lap_car != null)
	# abandono vai para o fim da torre, apagado e com "FORA" no lugar da diferença (como na transmissão)
	order[0].retired = true
	order[0].retire_reason = "motor"
	st.refresh()
	var last: Dictionary = st._rows[st._rows.size() - 1]
	assert_eq(st._row_cars[st._rows.size() - 1], order[0])
	assert_eq((last["gap"] as Label).text, "FORA")
	assert_eq((last["name"] as Label).text, order[0].code(), "sigla de 3 letras")


func test_rival_mostra_so_idade_do_pneu_e_meu_carro_mostra_barra_de_vida() -> void:
	screen._refresh_ui()
	var st: StandingsPanel = screen._standings
	for i in st._rows.size():
		var mine := st._row_cars[i].is_player
		assert_eq(st._rows[i]["life"].visible, mine)
		assert_eq(st._rows[i]["age"].visible, not mine)


func test_ordens_de_equipe_no_cartao() -> void:
	var panel: CarControlPanel = screen._car_panels[0]
	watch_signals(screen.sim)
	assert_eq(panel._order_btns.size(), 3, "briga liberada, não defender, não atacar")
	var found := false
	for b in panel._order_btns:
		if b.text.to_upper().begins_with("NÃO\nATACAR"):  # o jogo mostra tudo em caixa alta
			b.emit_signal("pressed")
			found = true
	assert_true(found, "botão 'Não atacar' no cartão")
	assert_signal_emitted(screen.sim, "team_order_result", "a ordem chegou à simulação (o piloto pode obedecer ou não)")


func test_folha_de_missoes_define_a_base_e_da_missao_curta() -> void:
	var panel: CarControlPanel = screen._car_panels[0]
	var car: CarState = panel.car
	var mission: Button = panel._mission_btn  # símbolo de alvo (2026-11-10)
	assert_not_null(mission, "o cartão tem o botão de missões (sem Poupar/Normal/Atacar)")
	var before: bool = screen.paused
	mission.emit_signal("pressed")
	assert_true(screen.paused, "a corrida espera a decisão")
	screen._mission_ui["kind"] = "safe"
	screen.sim.set_mission_base(car, "safe")
	assert_eq(String(car.mission_base["kind"]), "safe")
	screen.sim.give_short_mission(car, "push", 2, "", false)
	assert_eq(String(Missions.active(car)["kind"]), "push")
	(screen._mission_ui["root"] as Control).queue_free()
	await wait_process_frames(2)
	assert_eq(screen.paused, before, "fechou a folha: a corrida volta ao estado de antes")


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


func test_selo_de_bandeira_mostra_safety_car() -> void:
	for i in 600:
		screen.sim.step()
	assert_false(screen._flag_pill.visible, "pista verde: sem selo")
	screen.sim.control.deploy_sc("teste")
	screen._refresh_ui()
	assert_true(screen._flag_pill.visible)
	assert_eq(screen._flag_label.text, "SAFETY CAR")


func test_tempo_acelerado_leva_a_camera_3d_para_a_vista_geral_e_depois_volta() -> void:
	var view: TrackView3D = screen._track_view
	var car: CarState = screen._car_panels[0].car
	screen._standings.driver_pressed.emit(car)  # segue o primeiro carro do jogador
	assert_eq(view.cam_mode, TrackView3D.CamMode.CAR)
	screen.set_time_scale(8.0)
	assert_eq(view.cam_mode, TrackView3D.CamMode.OVERVIEW)
	screen.set_time_scale(4.0)
	assert_eq(view.cam_mode, TrackView3D.CamMode.OVERVIEW)
	screen.set_time_scale(1.0)
	assert_eq(view.cam_mode, TrackView3D.CamMode.CAR)
	assert_eq(view.followed, car)
	assert_almost_eq(view.distance, 140.0, 0.01)


func test_camera_escolhida_no_tempo_acelerado_e_respeitada() -> void:
	var view: TrackView3D = screen._track_view
	var car: CarState = screen._car_panels[0].car
	screen.set_time_scale(8.0)
	screen._standings.driver_pressed.emit(car)  # jogador escolhe seguir um carro mesmo no 8×
	screen.set_time_scale(2.0)
	assert_eq(view.cam_mode, TrackView3D.CamMode.CAR)


func _find_confirm(n: Node) -> Button:
	if n is CutButton and (n as Button).text.to_upper() == "CONFIRMAR":
		return n
	for c in n.get_children():
		var r := _find_confirm(c)
		if r != null:
			return r
	return null


func test_folha_de_missoes_confirma_base_e_curta_de_uma_vez() -> void:
	var panel: CarControlPanel = screen._car_panels[0]
	var car: CarState = panel.car
	panel._mission_btn.emit_signal("pressed")
	await wait_process_frames(2)
	var ui: Dictionary = screen._mission_ui
	var root: Control = ui["root"]
	ui["kind"] = "attack"
	ui["short"] = "push"
	ui["laps"] = 2
	var ok := _find_confirm(root)
	assert_not_null(ok, "um só botão CONFIRMAR (sem Definir base / Dar missão)")
	ok.emit_signal("pressed")
	await wait_process_frames(2)
	assert_eq(String(car.mission_base["kind"]), "attack", "a base foi aplicada")
	assert_eq(String(Missions.active(car)["kind"]), "push", "a missão curta foi aplicada na mesma janela")
	assert_false(is_instance_valid(root) and root.is_inside_tree(), "a folha fechou")


func test_folha_cabe_na_tela_e_o_botao_de_fechar_fica_visivel() -> void:
	# regressão: com a fonte larga em caixa alta a folha passava da tela e o X ficava de fora (jogo "travado")
	var panel: CarControlPanel = screen._car_panels[0]
	panel._mission_btn.emit_signal("pressed")
	await wait_process_frames(4)
	var root: Control = screen._mission_ui["root"]
	var view := root.get_viewport_rect()
	var box := _first_panel(root)
	assert_not_null(box)
	var r := box.get_global_transform() * Rect2(Vector2.ZERO, box.size)
	assert_true(view.grow(1.0).encloses(r), "a folha inteira cabe na tela: %s dentro de %s" % [r, view])
	root.queue_free()


func _first_panel(n: Node) -> Control:
	if n is PanelContainer:
		return n
	for c in n.get_children():
		var r := _first_panel(c)
		if r != null:
			return r
	return null
