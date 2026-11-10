extends GutTest
## Marco 2: clima, pneus de chuva, bandeiras, abandonos, danos, punições, ordens e rádio.

var track_data: Dictionary
var tyres: TyreModel


func before_all() -> void:
	track_data = GameData.circuit("interlagos")
	tyres = TyreModel.new(GameData.tyres())


func _sim(options: Dictionary, drivers: Array = []) -> RaceSim:
	var opts := {"duration_pct": 0.25, "weather": "dry", "incident_rate": 0.0, "seed": 3}
	opts.merge(options, true)
	var field: Array = drivers if not drivers.is_empty() else GameData.drivers()
	return RaceSim.new(TrackModel.new(track_data), TyreModel.new(GameData.tyres()), GameData.teams(), field, opts)


func _run_laps(sim: RaceSim, laps: int) -> void:
	var target := sim.leader_lap() + laps
	var n := 0
	while sim.leader_lap() < target and not sim.is_over() and n < 200000:
		sim.step()
		n += 1


func _player_cars(sim: RaceSim) -> Array[CarState]:
	var out: Array[CarState] = []
	for c in sim.cars:
		if c.is_player:
			out.append(c)
	return out


# --- clima e pneus -------------------------------------------------------------------

func test_cruzamentos_slick_inter_chuva() -> void:
	assert_eq(tyres.best_for_wetness(0.05, ["medium", "inter", "wet"]), "medium")
	assert_eq(tyres.best_for_wetness(0.35, ["medium", "inter", "wet"]), "inter")
	assert_eq(tyres.best_for_wetness(0.85, ["medium", "inter", "wet"]), "wet")


func test_chuva_molha_e_depois_a_pista_seca() -> void:
	var rng := RandomNumberGenerator.new()
	var w := WeatherModel.new(0.0, 3000.0, rng, {"weather": [{"start_s": 100.0, "end_s": 700.0, "intensity": 1.0}]})
	for i in 4000:  # 400 s
		w.step(0.1)
	assert_gt(w.wetness, 0.7, "chuva forte encharca")
	for i in 12000:  # +1200 s sem chuva
		w.step(0.1)
	assert_lt(w.wetness, 0.1, "pista seca depois")


func test_previsao_fica_mais_certa_perto_da_chuva() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var w := WeatherModel.new(0.0, 3000.0, rng, {"weather": [{"start_s": 600.0, "end_s": 1200.0, "intensity": 1.0}]})
	var far := w.forecast(75.0)  # chuva começa daqui a ~8 voltas
	w.time_s = 520.0  # agora começa na próxima volta
	var near := w.forecast(75.0)
	assert_gt(near[0], 0.75, "janela imediata: chuva quase certa")
	assert_lt(far[0], 0.35, "longe da chuva: janela imediata seca")


func test_ia_coloca_pneu_de_chuva_e_fica_isenta_da_regra() -> void:
	var sim := _sim({"weather": [{"start_s": 200.0, "end_s": 5000.0, "intensity": 0.9}]})
	sim.run_to_end()
	var on_wet := 0
	for car in sim.cars:
		if not sim.tyres.is_dry(car.tyre):
			on_wet += 1
		assert_false(car.disqualified, "%s não deve ser desclassificado" % car.code())
	assert_gt(on_wet, 18, "quase todos terminam com intermediário/chuva")


# --- bandeiras -----------------------------------------------------------------------

func test_safety_car_agrupa_o_pelotao_e_proibe_ultrapassagens() -> void:
	var sim := _sim({})
	_run_laps(sim, 5)
	var tenth := sim.standings()[9]
	var gap_before := sim.gap_to_leader_s(tenth)
	for car in sim.cars:  # ninguém para (o teste mede o agrupamento, não o ciclo de paradas)
		car.ai_plan.clear()
		car.ai_gamble = 1.0
	sim.control.deploy_sc("teste")
	var overtakes_before := sim.overtakes_count
	_run_laps(sim, 2)
	assert_eq(sim.control.flag, RaceControl.Flag.SC)
	assert_eq(sim.overtakes_count, overtakes_before, "sem ultrapassagens sob safety car")
	var gap_after := sim.gap_to_leader_s(sim.standings()[9])
	assert_lt(gap_after, gap_before, "pelotão agrupado: %.1f -> %.1f" % [gap_before, gap_after])
	var order := sim.standings()
	for i in range(1, 10):  # fila do safety car: ninguém fica longe do carro da frente
		assert_lt(sim.gap_to_leader_s(order[i]) - sim.gap_to_leader_s(order[i - 1]), 1.2, "fila compacta (%s)" % order[i].code())
	_run_laps(sim, 4)
	assert_eq(sim.control.flag, RaceControl.Flag.GREEN, "safety car recolhe")


func test_vsc_mantem_as_diferencas_e_termina_sozinho() -> void:
	var sim := _sim({})
	_run_laps(sim, 2)  # cedo: na corrida de 25% o macio já pede box por volta da 4ª
	for c in sim.cars:  # ninguém precisa parar: isola o efeito do VSC nas diferenças
		c.tyre_wear = 0.0
		c.compounds_used = ["medium", "hard"]
		c.pit_requested = false
	var order := sim.standings()
	var spread_before := sim.gap_to_leader_s(order[9]) - sim.gap_to_leader_s(order[1])
	sim.control.deploy_vsc("teste")
	for i in 500:  # 50 s
		sim.step()
	assert_eq(sim.control.flag, RaceControl.Flag.VSC)
	order = sim.standings()
	var spread_during := sim.gap_to_leader_s(order[9]) - sim.gap_to_leader_s(order[1])
	assert_almost_eq(spread_during, spread_before * RaceControl.VSC_PACE, spread_before * 0.6)
	for i in 2000:
		sim.step()
	assert_eq(sim.control.flag, RaceControl.Flag.GREEN)


func test_bandeira_vermelha_troca_pneus_e_relarga_atras_do_safety_car() -> void:
	var sim := _sim({})
	_run_laps(sim, 6)
	sim.control.red_flag("teste")
	for car in sim.cars:
		assert_eq(car.tyre_wear, 0.0, "%s com pneus novos" % car.code())
	assert_eq(sim.control.flag, RaceControl.Flag.SC)
	assert_eq(sim.control.sc_laps_left, 2)


func test_parar_sob_safety_car_custa_menos() -> void:
	# o tempo dentro do pit lane é fixo (limite de velocidade); sob SC a pista fica mais lenta,
	# então a perda em relação a quem está na pista diminui
	var green := _sim({"player_team": "haas", "radio": false})
	var sc := _sim({"player_team": "haas", "radio": false})
	_run_laps(green, 4)
	_run_laps(sc, 4)
	sc.control.deploy_sc("teste")
	sc.control.sc_laps_left = 99
	var a: CarState = green.cars[14]
	var b: CarState = sc.cars[14]
	green.request_pit(a, "hard")
	sc.request_pit(b, "hard")
	while not a.in_pit:
		green.step()
	while not b.in_pit:
		sc.step()
	var lane := green.track.pit_lane_length_m()
	# tempo andando no pit lane (o tempo parado é no box, separado): só o efeito da bandeira
	var core_a := lane / a.pit_speed
	var core_b := lane / b.pit_speed
	assert_almost_eq(core_b, core_a, core_a * 0.05, "tempo no pit lane não muda com a bandeira")
	var track_green := lane / (green.track.length_m / green.ideal_pace(a))
	var track_sc := lane / sc.control.flag_speed(b, sc.track.length_m / sc.ideal_pace(b))
	var loss_green := core_a - track_green
	var loss_sc := core_b - track_sc
	assert_lt(loss_sc, loss_green - 2.5, "perda sob SC %.1f s vs bandeira verde %.1f s" % [loss_sc, loss_green])


# --- abandonos, danos e punições -------------------------------------------------------

func test_abandono_e_classificado_no_fim_e_a_corrida_termina() -> void:
	var sim := _sim({})
	_run_laps(sim, 3)
	var victim := sim.standings()[0]
	sim.retire_car(victim, "teste")
	sim.run_to_end()
	assert_true(sim.is_over())
	var result := sim.standings()
	assert_eq(result[result.size() - 1], victim, "abandono vai para o fim")
	assert_lt(victim.laps_done, result[0].laps_done)


func test_asa_danificada_deixa_mais_lento_e_o_box_conserta() -> void:
	var sim := _sim({"player_team": "alpine", "radio": false})
	var car := _player_cars(sim)[0]
	var pace := sim.ideal_pace(car)
	car.damage_wing = 0.5
	assert_almost_eq(sim.ideal_pace(car) - pace, 0.5 * RaceControl.WING_PENALTY_S, 0.01)
	car.repair_wing = true
	sim.request_pit(car, "hard")
	var n := 0
	while car.pit_stops == 0 and n < 30000:
		sim.step()
		n += 1
	assert_eq(car.damage_wing, 0.0)
	assert_gt(car.pit_stationary_s, RaceControl.WING_CHANGE_S)


func test_punicao_nao_cumprida_vai_para_o_tempo_final() -> void:
	var sim := _sim({})
	_run_laps(sim, 2)
	var car := sim.standings()[0]
	sim.control.give_penalty(car, 10.0, "teste")
	assert_eq(car.license_points, 3)
	car.ai_pit_wear = 9.0  # não para mais (não cumpre a punição no box)...
	car.ai_plan.clear()  # ...nem pelo plano de estratégia...
	car.compounds_used = ["medium", "hard"]  # ...nem por causa da regra dos compostos
	sim.run_to_end()
	assert_almost_eq(car.classified_time() - car.finish_time, 10.0, 0.001)


func test_punicao_e_cumprida_parado_no_box() -> void:
	var sim := _sim({"player_team": "audi", "radio": false})
	var car := _player_cars(sim)[0]
	sim.control.give_penalty(car, 5.0, "teste")
	sim.request_pit(car, "hard")
	var n := 0
	while car.pit_stops == 0 and n < 30000:
		sim.step()
		n += 1
	assert_eq(car.penalty_pending_s, 0.0)
	assert_gt(car.pit_stationary_s, 5.0)


# --- ordens de equipe ----------------------------------------------------------------

func test_deixar_passar_troca_os_companheiros() -> void:
	var pair: Array = []
	for d: Dictionary in GameData.drivers():
		if d["team"] == "mclaren":
			pair.append(d)
	var sim := _sim({"player_team": "mclaren", "radio": false}, pair)  # só a dupla na pista
	_run_laps(sim, 2)
	var cars := _player_cars(sim)
	var ahead := cars[0] if cars[0].distance > cars[1].distance else cars[1]
	var behind := sim.teammate_of(ahead)
	behind.distance = ahead.distance - 15.0  # companheiro colado atrás
	ahead.team_order = CarState.TeamOrder.NO_DEFEND  # (obediência testada à parte)
	for i in 30:
		sim.step()
	assert_gt(behind.distance, ahead.distance, "%s abriu para %s" % [ahead.code(), behind.code()])
	assert_eq(ahead.team_order, CarState.TeamOrder.NO_DEFEND, "a ordem vale até ser trocada")


func test_nao_brigar_impede_disputa_entre_companheiros() -> void:
	var sim := _sim({"duration_pct": 0.5})
	for c in sim.cars:
		c.team_order = CarState.TeamOrder.NO_ATTACK
	var same_team := [0]
	sim.overtake.connect(func(a: CarState, d: CarState, _z: String) -> void:
		if a.team["id"] == d.team["id"]:
			same_team[0] += 1)
	sim.run_to_end()
	assert_eq(same_team[0], 0)


func test_piloto_as_vezes_desobedece() -> void:
	var obeyed := 0
	var refused := 0
	for s in 40:
		var sim := _sim({"player_team": "ferrari", "seed": s})
		var car := _player_cars(sim)[0]
		sim.set_team_order(car, CarState.TeamOrder.NO_DEFEND)
		if car.team_order == CarState.TeamOrder.NO_DEFEND:
			obeyed += 1
		else:
			refused += 1
	assert_gt(obeyed, refused, "na maioria obedece")
	assert_gt(refused, 0, "mas nem sempre")


# --- rádio ---------------------------------------------------------------------------

func test_radio_pergunta_sobre_chuva_e_a_resposta_chama_para_o_box() -> void:
	var sim := _sim({"player_team": "williams", "weather": [{"start_s": 150.0, "end_s": 5000.0, "intensity": 1.0}]})
	var asked: Array[Dictionary] = []
	sim.radio_message.connect(func(msg: Dictionary) -> void:
		if msg["kind"] == "question":
			asked.append(msg))
	var n := 0
	while asked.is_empty() and n < 60000:
		sim.step()
		n += 1
	assert_false(asked.is_empty(), "piloto perguntou")
	var m := asked[0]
	assert_string_contains(m["text"], "chover")
	sim.radio.answer(m["id"], 0)
	var car: CarState = m["car"]
	assert_true(car.pit_requested)
	assert_eq(car.pit_compound, "inter")
	assert_eq(car.confidence, 1, "resposta certa deixa o piloto confiante")


func test_sem_resposta_o_piloto_decide_sozinho() -> void:
	var sim := _sim({"player_team": "williams", "weather": [{"start_s": 150.0, "end_s": 5000.0, "intensity": 1.0}]})
	var asked: Array[Dictionary] = []
	sim.radio_message.connect(func(msg: Dictionary) -> void:
		if msg["kind"] == "question":
			asked.append(msg))
	var n := 0
	while asked.is_empty() and n < 60000:
		sim.step()
		n += 1
	var m := asked[0]
	_run_laps(sim, 3)
	assert_true(m["answered"])
	assert_true(m["auto"])


func test_safety_car_gera_pergunta_de_parada() -> void:
	var sim := _sim({"player_team": "haas"})
	_run_laps(sim, 2)
	sim.control.deploy_sc("teste")
	for car in _player_cars(sim):
		var q := sim.radio.pending_for(car)
		assert_false(q.is_empty(), "%s recebeu pergunta" % car.code())
		assert_string_contains(q["text"], "Safety car")
