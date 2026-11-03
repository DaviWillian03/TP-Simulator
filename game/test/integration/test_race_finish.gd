extends GutTest
## Largada com as 5 luzes, bandeirada e pódio animado no fim da corrida.


func _sim() -> RaceSim:
	return RaceSim.new(TrackModel.new(GameData.circuit("interlagos")), TyreModel.new(GameData.tyres()),
		GameData.teams(), GameData.drivers(), {"weather": "dry", "incident_rate": 0.0, "duration_pct": 0.1, "seed": 3})


func test_start_lights_light_one_by_one_then_go_out() -> void:
	var lights := StartLights.new()
	add_child_autofree(lights)
	watch_signals(lights)
	lights.start(0.1)
	await wait_seconds(StartLights.STEP_S * 2.5)
	assert_between(lights.lit_count(), 2, 3, "acendem uma a uma")
	assert_false(lights.is_out())
	await wait_seconds(StartLights.STEP_S * 3.0 + 0.3)
	assert_true(lights.is_out(), "apagam todas juntas: largada")
	assert_signal_emit_count(lights, "light_on", 5)
	assert_signal_emitted(lights, "lights_out")


func test_podium_shows_the_top_three_and_leads_to_results() -> void:
	var sim := _sim()
	sim.run_to_end()
	var top3: Array[CarState] = []
	for car in sim.standings():
		if top3.size() < 3:
			top3.append(car)
	var podium := PodiumView.new()
	add_child_autofree(podium)
	podium.setup(top3, "GP de São Paulo")
	watch_signals(podium)
	assert_eq(podium._steps.size(), 3, "três degraus")
	var go: Button = null
	for c in podium.get_children():
		if c is CutButton:
			go = c
	assert_not_null(go)
	go.pressed.emit()
	assert_signal_emitted(podium, "done", "o botão leva ao resultado completo")


func test_finished_cars_get_the_chequered_flag_in_the_tower() -> void:
	var sim := _sim()
	sim.run_to_end()
	var panel := StandingsPanel.new()
	add_child_autofree(panel)
	panel.setup(sim)
	panel.refresh()
	var flagged := 0
	for row: Dictionary in panel._rows:
		if row["icons"]["finished"].visible:
			flagged += 1
	var finished := sim.cars.filter(func(c: CarState) -> bool: return c.finished and not c.disqualified).size()
	assert_eq(flagged, finished, "bandeira quadriculada em quem recebeu a bandeirada")
