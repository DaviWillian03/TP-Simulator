extends GutTest
## Integração do modo Grande Prêmio: configuração, painel do fim de semana, treino e
## classificação ao vivo e a corrida usando o grid da classificação.

const OPTS := {"player_team": "williams", "duration_pct": 0.25, "weather": "dry", "incident_rate": 0.0, "seed": 4}


func after_each() -> void:
	Session.weekend = null
	Session.debug_advance_s = 0.0


func _open(scene: String) -> Control:
	var screen: Control = load(scene).instantiate()
	add_child_autofree(screen)
	await wait_process_frames(2)
	return screen


func _weekend_at(session: String) -> WeekendSim:
	var w := WeekendSim.new("interlagos", OPTS)
	while w.session_id() != session:
		w.simulate_current()
	Session.weekend = w
	return w


func test_configuracao_mostra_o_calendario_e_troca_o_circuito() -> void:
	var screen: Control = await _open("res://src/ui/gp_setup_screen.tscn")
	assert_eq(screen._rows.size(), 22, "22 GPs no calendário")
	(screen._rows["monaco"] as Button).button_pressed = true
	assert_eq(Session.circuit_id, "monaco")
	assert_string_contains(screen._gp_title.text, "MÔNACO")
	Session.circuit_id = "interlagos"


func test_painel_monta_o_programa_do_treino_com_blocos() -> void:
	var w := _weekend_at("fp1")
	var screen: Control = await _open("res://src/ui/weekend_screen.tscn")
	var albon := "albon"
	assert_eq(w.program_of(albon).size(), 4, "começa com o programa padrão")
	screen._remove_block(albon, 3)
	screen._remove_block(albon, 2)
	screen._add_block(albon, "aero")
	assert_eq(w.program_of(albon), ["aero", "mech", "aero"] as Array[String])
	assert_true((screen._program_boxes[albon]["minutes"].text as String).begins_with("45 / 60 min"))


func test_treino_ao_vivo_usa_o_programa_e_termina() -> void:
	var w := _weekend_at("fp1")
	w.set_program("albon", ["race", "race", "race"])
	var screen: Control = await _open("res://src/ui/practice_screen.tscn")
	assert_eq(screen.p.programs["albon"], ["race", "race", "race"] as Array[String])
	screen.p.run_to_end()
	screen._refresh_ui()
	assert_true(screen._end_card.visible)
	var before: float = w.setups["albon"].race_prep
	assert_gt(before, 0.3, "três simulações de corrida preparam o ritmo de corrida")


func test_classificacao_ao_vivo_manda_o_carro_para_a_pista() -> void:
	_weekend_at("quali")
	var screen: Control = await _open("res://src/ui/quali_screen.tscn")
	screen.time_scale = 0.0
	var panel: Dictionary = screen._panels[0]
	var car: CarState = panel["car"]
	panel["tyres"]["medium"].button_pressed = true
	(panel["go"] as Button).pressed.emit()
	assert_eq(screen.q.status_of(car), "Volta de saída")
	assert_eq(car.tyre, "medium")
	screen._refresh_ui()
	assert_true((panel["go"] as Button).disabled, "não dá para sair de novo com o carro na pista")


func test_simular_resto_da_classificacao_gera_o_grid() -> void:
	var w := _weekend_at("quali")
	var screen: Control = await _open("res://src/ui/quali_screen.tscn")
	screen._simulate_rest()
	assert_true(screen.q.is_over())
	assert_true(screen._end_card.visible)
	w.finish_quali(screen.q)
	assert_eq(w.grids["race"].size(), 22)
	assert_eq(w.session_id(), "race")


func test_corrida_do_gp_larga_com_o_grid_da_classificacao() -> void:
	var w := _weekend_at("race")
	var screen: Control = await _open("res://src/ui/race_screen.tscn")
	screen.paused = true
	assert_not_null(screen.weekend)
	var pole: String = w.grids["race"][0]
	for car: CarState in screen.sim.cars:
		if car.driver["id"] == pole:
			assert_eq(car.grid_position, 0)
	var setup: CarSetup = w.setups["albon"]
	for car: CarState in screen.sim.cars:
		if car.driver["id"] == "albon":
			assert_almost_eq(car.setup_penalty_s, setup.lap_penalty_s(), 0.0001, "acerto dos treinos vale na corrida")


# --- direção Garagem: tela inicial e configuração ---------------------------------------

func test_tela_inicial_troca_a_equipe_pela_folha() -> void:
	var before := Session.player_team
	var screen: Control = await _open("res://src/ui/title_screen.tscn")
	screen._open_team_picker()
	await wait_process_frames(1)
	var sheet: Node = screen.get_child(screen.get_child_count() - 1)
	var cards := sheet.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.toggle_mode)
	assert_eq(cards.size(), 11, "uma opção por equipe")
	(cards[2] as Button).pressed.emit()  # Ferrari (terceira equipe nos dados)
	assert_eq(Session.player_team, "ferrari")
	await wait_process_frames(1)
	var names: Array = screen._team_pill.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)
	assert_has(names, "Ferrari", "a pílula mostra a nova equipe")
	Session.player_team = before


func test_corrida_rapida_guarda_a_duracao_escolhida() -> void:
	var before := Session.duration_pct
	var screen: Control = await _open("res://src/ui/title_screen.tscn")
	screen._open_quick_race()
	await wait_process_frames(1)
	var sheet: Node = screen.get_child(screen.get_child_count() - 1)
	for b: Button in sheet.find_children("*", "Button", true, false):
		if b.has_meta("value") and is_equal_approx(float(b.get_meta("value")), 0.5):
			b.pressed.emit()
	assert_almost_eq(Session.duration_pct, 0.5, 0.001)
	Session.duration_pct = before


func test_configuracao_preserva_as_escolhas_do_session() -> void:
	Session.gp_weather = "rain"
	Session.gp_format = "race_only"
	var screen: Control = await _open("res://src/ui/gp_setup_screen.tscn")
	var pressed: Array = []
	for b: Button in screen.find_children("*", "Button", true, false):
		if b.has_meta("value") and b.button_pressed:
			pressed.append(b.get_meta("value"))
	assert_has(pressed, "rain")
	assert_has(pressed, "race_only")
	assert_eq(screen._go.text, "COMEÇAR CORRIDA", "o botão diz o que vai acontecer")
	Session.gp_weather = "realistic"
	Session.gp_format = "full"


# --- campanha ---------------------------------------------------------------------------

func test_criacao_de_equipe_valida_nome_sigla_e_pilotos() -> void:
	var screen: Control = await _open("res://src/ui/team_creator_screen.tscn")
	screen._go(1)
	await wait_process_frames(1)
	assert_true(screen._next.disabled, "sem nome e sigla não avança")
	screen.spec["name"] = "Aurora Racing"
	screen.spec["short"] = "AUR"
	screen._validate()
	assert_false(screen._next.disabled)
	screen._go(3)
	await wait_process_frames(1)
	assert_true(screen._next.disabled, "precisa de dois pilotos")
	screen._toggle_driver("rafael_camara")
	screen._toggle_driver("gabriele_mini")
	assert_false(screen._next.disabled)
	assert_eq(screen.spec["drivers"], ["rafael_camara", "gabriele_mini"])
	screen._toggle_driver("rafael_camara")
	assert_true(screen._next.disabled, "tocar de novo tira o piloto")


func test_origem_montadora_trava_o_motor_proprio() -> void:
	var screen: Control = await _open("res://src/ui/team_creator_screen.tscn")
	screen.spec["origin"] = "manufacturer"
	screen._go(2)
	await wait_process_frames(1)
	assert_eq(screen.spec["engine"], "own")
	var enabled: Array = screen._content.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.toggle_mode and not b.disabled and String(b.text).contains("cliente"))
	assert_eq(enabled.size(), 0, "fornecedores desabilitados para a montadora")


func test_sede_avanca_o_tempo_e_leva_ao_fim_de_semana() -> void:
	var c := Campaign.new_real("williams")
	Session.campaign = c
	var screen: Control = await _open("res://src/ui/campaign_hub_screen.tscn")
	var days := c.days_to_event()
	assert_gt(days, 0)
	screen._on_one_day()  # recarrega a sede com 1 dia a menos
	assert_eq(c.days_to_event(), days - 1)
	c.advance_to_event()
	assert_true(c.event_ready())
	Session.campaign = null


func test_relatorio_fecha_a_temporada_uma_unica_vez() -> void:
	var c := Campaign.new_real("mclaren")
	c.round = 22
	Session.campaign = c
	var screen: Control = await _open("res://src/ui/campaign_report_screen.tscn")
	assert_eq(c.seasons.size(), 1)
	assert_eq(screen.report["season"], 2026)
	var again: Control = await _open("res://src/ui/campaign_report_screen.tscn")
	assert_eq(c.seasons.size(), 1, "reabrir o relatório não fecha a temporada de novo")
	Session.campaign = null
