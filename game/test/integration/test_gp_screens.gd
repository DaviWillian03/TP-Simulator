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
	assert_eq(screen._program_boxes[albon]["minutes"].text, "45 / 60 min")


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
