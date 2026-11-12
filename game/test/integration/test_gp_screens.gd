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
	assert_eq(screen._rows.size(), 25, "22 GPs de 2026 + 3 pistas extras de 2012 (Sepang, Bahrein, Hockenheim)")
	assert_true(screen._rows.has("sepang") and screen._rows.has("bahrain") and screen._rows.has("hockenheim"))
	(screen._rows["monaco"] as Button).button_pressed = true
	assert_eq(Session.circuit_id, "monaco")
	assert_true((screen._rows["monaco"] as Button).button_pressed, "o cartão escolhido fica marcado")
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


func test_treino_simulado_usa_o_programa_e_mostra_o_resultado() -> void:
	var w := _weekend_at("fp1")
	w.set_program("albon", ["race", "race", "race"])
	var screen: Control = await _open("res://src/ui/weekend_screen.tscn")
	assert_eq(screen.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text == "JOGAR").size(), 0,
		"treino não tem JOGAR (sempre simulado)")
	w.show_practice_report = true  # o que o botão SIMULAR faz antes de recarregar o painel
	w.simulate_current()
	assert_gt(float(w.setups["albon"].race_prep), 0.3, "três simulações de corrida preparam o ritmo de corrida")
	assert_true((w.last_practice["drivers"] as Dictionary).has("albon"))
	assert_true(String(w.last_practice["drivers"]["albon"]["grade"]) in ["A", "B", "C", "D"])
	var again: Control = await _open("res://src/ui/weekend_screen.tscn")
	assert_not_null(again._report_root, "abre a folha de resultado do treino")
	assert_false(w.show_practice_report, "a folha abre uma vez só")


func test_classificacao_ao_vivo_manda_o_carro_para_a_pista() -> void:
	_weekend_at("quali")
	var screen: Control = await _open("res://src/ui/quali_screen.tscn")
	screen.time_scale = 0.0
	var panel: Dictionary = screen._panels[0]
	var car: CarState = panel["car"]
	(panel["go"] as Button).pressed.emit()
	assert_not_null(screen._out_sheet, "o botão abre a folha de saída (v22-1)")
	var t0: float = screen.q.seg_time
	screen._process(1.0)
	assert_eq(screen.q.seg_time, t0, "a sessão espera enquanto a folha está aberta")
	screen._pick_out("set", screen.q.best_set(car, "medium"))
	screen._pick_out("mode", "limit")
	screen._pick_out("laps", 2)
	screen._confirm_out()
	assert_eq(screen.q.status_of(car), "Volta de saída")
	assert_eq(car.tyre, "medium")
	assert_eq(screen.q.laps_left[car], 2)
	assert_eq(screen.q.player_mode[car], "limit")
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


func test_classificacao_para_no_fim_do_q1_e_mostra_o_resultado_ate_confirmar() -> void:
	_weekend_at("quali")
	var screen: Control = await _open("res://src/ui/quali_screen.tscn")
	screen.q.auto_player = true
	var guard := 0
	while not screen.q.waiting and guard < 100000:
		screen.q.step()
		guard += 1
	screen._show_result(0)
	await wait_process_frames(2)
	assert_not_null(screen._result, "a folha de resultado do Q1 abre")
	var t: float = screen.q.total_time
	screen._process(5.0)
	assert_eq(screen.q.total_time, t, "o Q2 não começa sozinho")
	assert_eq(screen.q.segment, 0)
	var res: QualiResultSheet = screen._result
	res.confirmed.emit()  # o que o botão CONTINUAR faz
	assert_eq(screen.q.segment, 1, "confirmou: começa o Q2")
	assert_false(screen.q.waiting)


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

## Menu principal só com logo e modos (v16-1); a escolha de equipe é uma tela dentro do modo (v16-2).
func test_menu_sem_equipe_e_escolha_de_equipe_troca_e_confirma() -> void:
	var before := Session.player_team
	var title: Control = await _open("res://src/ui/title_screen.tscn")
	assert_false("_team_pill" in title, "o menu principal não tem escolha de equipe")
	Session.team_select_mode = "gp"
	var screen: Control = await _open("res://src/ui/team_select_screen.tscn")
	assert_eq(screen._strip.get_child_count(), 11, "um emblema por equipe")
	var tile: Button = screen._strip.get_child(2).get_child(0)  # Ferrari (terceira equipe nos dados)
	tile.pressed.emit()
	await wait_process_frames(1)
	assert_eq(screen._team, "ferrari")
	assert_eq(screen._name.text, "FERRARI")
	assert_eq(screen._drivers.get_child_count(), 3, "título + 2 pilotos")
	Session.player_team = before


func test_menu_nao_tem_corrida_rapida() -> void:
	var screen: Control = await _open("res://src/ui/title_screen.tscn")
	for l: Label in screen.find_children("*", "Label", true, false):
		assert_false(l.text.to_lower().contains("corrida rápida"), "o modo saiu do jogo (2026-11-08)")


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


func test_estrategia_antes_da_largada_edita_e_confirma() -> void:
	var w := _weekend_at("race")
	var screen: Control = await _open("res://src/ui/strategy_screen.tscn")
	assert_true(screen.chosen.has("albon") and screen.chosen.has("sainz"))
	var laps0: int = screen.chosen["albon"]["stints"][0]["laps"]
	if (screen.chosen["albon"]["stints"] as Array).size() > 1:
		assert_true(RaceStrategy.adjust_laps(screen.chosen["albon"], 0, 2))
		assert_eq(int(screen.chosen["albon"]["stints"][0]["laps"]), laps0 + 2)
	w.strategy = screen.chosen.duplicate(true)  # o que o IR PARA O GRID grava
	var sim := w.make_race()
	for car in sim.cars:
		if car.driver["id"] == "albon":
			assert_eq(car.tyre, String(screen.chosen["albon"]["stints"][0]["compound"]))


func test_grid_mostra_da_ultima_fila_para_a_primeira_e_larga() -> void:
	var w := _weekend_at("race")
	var screen: Control = await _open("res://src/ui/grid_screen.tscn")
	assert_eq(screen.row, screen.rows - 1, "começa pela última fila")
	assert_eq(screen._cards.size(), 2, "dois pilotos por vez")
	screen._process(screen.ROW_S + 0.01)
	assert_eq(screen.row, screen.rows - 2)
	assert_true(w.quali_times["race"].size() > 0, "tempos da classificação para os cartões")
	assert_eq(screen.order[0].driver["id"], w.grids["race"][0], "a ordem é a do grid")


func test_escolha_de_equipe_troca_para_a_f2() -> void:
	var before_team := Session.player_team
	var before_cat := Session.category
	Session.team_select_mode = "gp"
	Session.category = "F1"
	var screen: Control = await _open("res://src/ui/team_select_screen.tscn")
	screen._set_category("F2")
	await wait_process_frames(1)
	assert_eq(screen._teams.size(), 11)
	assert_true(String(screen._team).begins_with("f2_"))
	assert_eq(screen._strip.get_child_count(), 11)
	Session.player_team = before_team
	Session.category = before_cat


func test_gp_da_f2_mostra_so_as_etapas_da_categoria() -> void:
	var before_team := Session.player_team
	Session.player_team = "f2_camposracing"
	var screen: Control = await _open("res://src/ui/gp_setup_screen.tscn")
	assert_eq(screen._calendar.size(), 17, "14 etapas da categoria + 3 pistas extras (valem para qualquer categoria)")
	assert_eq(Session.category, "F2")
	Session.player_team = before_team
	Session.category = "F1"
