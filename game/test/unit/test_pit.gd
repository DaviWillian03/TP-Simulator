extends GutTest
## Box da direção Garagem: parada física, plano e custos, estoque de pneus, asa, fila da parada
## dupla, mini-jogo, investigação e punição no box.

var track: TrackModel
var tyres: TyreModel
var teams: Array
var drivers: Array


func before_all() -> void:
	track = TrackModel.new(GameData.circuit("interlagos"))
	tyres = TyreModel.new(GameData.tyres())
	teams = GameData.teams()
	drivers = GameData.drivers()


func _sim(extra: Dictionary = {}) -> RaceSim:
	var o := {"duration_pct": 0.5, "seed": 5, "weather": "dry", "incident_rate": 0.0, "player_team": "williams", "radio": false}
	o.merge(extra, true)
	return RaceSim.new(track, tyres, teams, drivers, o)


func _mine(sim: RaceSim) -> Array[CarState]:
	var l: Array[CarState] = []
	for c in sim.cars:
		if c.is_player:
			l.append(c)
	return l


## Avança até o carro parar no box (ou até o limite de segundos).
func _until_stopped(sim: RaceSim, car: CarState, limit_s := 400.0) -> bool:
	var t := 0.0
	while t < limit_s:
		sim.step()
		t += RaceSim.DT
		if car.in_pit and car.box_hold_s > 0.0:
			return true
	return false


func test_custos_do_plano_somam_as_parcelas() -> void:
	var sim := _sim()
	var car := _mine(sim)[0]
	car.penalty_pending_s = 5.0
	var plan := PitStop.make_plan("hard", false, true, true)
	var e := PitStop.estimate(car, plan)
	assert_almost_eq(float(e["total"]), PitStop.BASE_S + RaceControl.WING_CHANGE_S + 5.0, 0.001)
	plan["serve_penalty"] = false
	assert_almost_eq(float(PitStop.estimate(car, plan)["penalty"]), 0.0, 0.001, "punição fica de fora se não for cumprida")


func test_carro_para_de_verdade_no_box_pelo_tempo_do_plano() -> void:
	var sim := _sim()
	var car := _mine(sim)[0]
	sim.advance(20.0)
	assert_true(sim.set_pit_plan(car, PitStop.make_plan("hard", false, false, true)))
	assert_true(_until_stopped(sim, car), "chega ao box e para")
	var hold := car.box_hold_s
	assert_gt(hold, PitStop.BASE_S - 0.01)
	var stopped := 0.0
	while car.box_hold_s > 0.0:
		assert_almost_eq(car.speed, 0.0, 0.0001, "parado")
		sim.step()
		stopped += RaceSim.DT
	assert_almost_eq(stopped, hold, 0.25)
	assert_eq(car.tyre, "hard", "troca os pneus ao fim do tempo parado")
	assert_eq(car.pit_stops, 1)


func test_parada_padrao_custa_o_mesmo_tempo_total_de_antes() -> void:
	# com o plano padrão (2,4 s) o tempo no pit lane + parado equivale ao modelo anterior
	var sim := _sim()
	var car := _mine(sim)[0]
	car.pit_requested = true
	car.pit_compound = "hard"
	var t0 := -1.0
	var t1 := -1.0
	for i in 12000:
		sim.step()
		if car.in_pit and t0 < 0.0:
			t0 = sim.time_s
		if t0 >= 0.0 and not car.in_pit:
			t1 = sim.time_s
			break
	assert_gt(t1, t0)
	var expected := track.pit_lane_length_m() / (track.length_m / sim.ideal_pace(car)) + track.pit_lane_loss_s
	assert_almost_eq(t1 - t0, expected + (car.pit_stationary_s - PitStop.BASE_S), 4.0)


func test_estoque_gasta_jogo_novo_e_usado() -> void:
	var sim := _sim()
	var car := _mine(sim)[0]
	car.tyre_stock["hard"] = {"new": 1, "used": 1}
	sim.advance(20.0)
	assert_true(sim.set_pit_plan(car, PitStop.make_plan("hard", true)))
	_until_stopped(sim, car)
	while car.in_pit:
		sim.step()
	assert_eq(car.tyre_stock["hard"], {"new": 1, "used": 0})
	assert_almost_eq(car.tyre_wear, PitStop.USED_SET_WEAR, 0.05, "jogo usado começa com desgaste")


func test_sem_jogo_no_estoque_o_plano_e_recusado() -> void:
	var sim := _sim()
	var car := _mine(sim)[0]
	car.tyre_stock["soft"] = {"new": 0, "used": 0}
	assert_false(sim.set_pit_plan(car, PitStop.make_plan("soft")))
	assert_false(car.pit_requested)


func test_largada_consome_um_jogo_do_estoque() -> void:
	var sim := _sim()
	var car := _mine(sim)[0]
	var left := PitStop.sets_left(car, car.tyre)
	var full: Dictionary = PitStop.default_stock()[car.tyre]
	assert_eq(left, int(full["new"]) + int(full["used"]) - 1)


func test_rivais_tem_estoque_ilimitado() -> void:
	var sim := _sim()
	for c in sim.cars:
		if not c.is_player:
			assert_true(c.tyre_stock.is_empty())


func test_box_conserta_so_a_asa_dianteira() -> void:
	var sim := _sim()
	var car := _mine(sim)[0]
	car.damage_wing = 0.5
	car.damage_floor = 0.4
	car.damage_rear = 0.3
	car.damage_susp = 0.2
	car.damage_pu = 0.1
	sim.advance(20.0)
	sim.set_pit_plan(car, PitStop.make_plan("hard", false, true))
	_until_stopped(sim, car)
	while car.in_pit:
		sim.step()
	assert_eq(car.damage_wing, 0.0, "asa dianteira trocada")
	assert_almost_eq(car.damage_floor, 0.4, 0.0001, "assoalho não tem conserto")
	assert_almost_eq(car.damage_rear, 0.3, 0.0001, "asa traseira não tem conserto")
	assert_almost_eq(car.damage_susp, 0.2, 0.0001, "suspensão não tem conserto")
	assert_almost_eq(car.damage_pu, 0.1, 0.0001, "motor/câmbio não tem conserto")


func test_punicao_cumprida_no_box_ou_levada_ao_fim() -> void:
	for serve in [true, false]:
		var sim := _sim()
		var car := _mine(sim)[0]
		car.penalty_pending_s = 5.0
		sim.advance(20.0)
		sim.set_pit_plan(car, PitStop.make_plan("hard", false, false, serve))
		_until_stopped(sim, car)
		if serve:
			assert_gt(car.box_hold_s, PitStop.BASE_S + 4.0, "parado a mais pelos 5 s")
		while car.in_pit:
			sim.step()
		assert_almost_eq(car.penalty_pending_s, 0.0 if serve else 5.0, 0.001)


func test_parada_dupla_segundo_carro_espera_a_fila() -> void:
	var sim := _sim()
	var cars := _mine(sim)
	sim.advance(20.0)
	for c in cars:
		assert_true(sim.set_pit_plan(c, PitStop.make_plan("hard")))
	var first: CarState = null
	var second: CarState = null
	for i in 8000:
		sim.step()
		for c in cars:
			if c.box_hold_s > 0.0 and first == null:
				first = c
			elif c.box_hold_s > 0.0 and c != first and second == null:
				second = c
		if second != null:
			break
	assert_not_null(first)
	assert_not_null(second)
	assert_gt(second.box_wait_s, 0.0, "o segundo espera o primeiro sair")
	assert_almost_eq(first.box_wait_s, 0.0, 0.001)


func test_segurar_o_companheiro_evita_a_fila_e_volta_depois() -> void:
	var sim := _sim()
	var cars := _mine(sim)
	sim.advance(20.0)
	sim.set_pit_plan(cars[0], PitStop.make_plan("hard"))
	sim.set_pit_plan(cars[1], PitStop.make_plan("hard"))
	sim.defer_pit(cars[1], 1)
	assert_false(cars[1].pit_requested)
	var lap := cars[1].laps_done
	while cars[1].laps_done < lap + 1:
		sim.step()
	assert_true(cars[1].pit_requested or cars[1].in_pit, "o pedido volta a valer uma volta depois")


func test_toque_do_mini_jogo_ajusta_o_tempo_uma_vez() -> void:
	var sim := _sim()
	var car := _mine(sim)[0]
	sim.advance(20.0)
	sim.set_pit_plan(car, PitStop.make_plan("hard"))
	_until_stopped(sim, car)
	var before := car.box_hold_s
	assert_almost_eq(sim.pit_tap(car, 1.0), PitStop.TAP_PERFECT_S, 0.001)
	assert_almost_eq(car.box_hold_s, before + PitStop.TAP_PERFECT_S, 0.001)
	assert_almost_eq(sim.pit_tap(car, 0.0), 0.0, 0.001, "só vale um toque por parada")
	assert_almost_eq(PitStop.tap_delta(0.0), PitStop.TAP_MISS_S, 0.001)


func test_estoque_do_gp_vem_do_que_sobrou_dos_jogos_do_fim_de_semana() -> void:
	var w := WeekendSim.new("interlagos", {"seed": 4, "player_team": "williams", "weather": "dry", "incident_rate": 0.0})
	while w.session_id() != "quali":
		w.simulate_current()
	w.simulate_current()
	var st: Dictionary = w.race_tyre_stock()["albon"]
	var dry := 0
	for k: String in ["soft", "medium", "hard"]:
		dry += int(st[k]["new"]) + int(st[k]["used"])
	assert_between(dry, 6, 7, "13 jogos − 6 devolvidos nos treinos (− o macio do Q3 de quem chegou lá)")
	assert_gt(int(st["soft"]["used"]), 0, "a classificação gastou macios")
	assert_gt(int(st["medium"]["new"]) + int(st["hard"]["new"]), 1, "médio e duro novos guardados para a corrida")


func test_toque_abre_investigacao_e_so_depois_sai_a_punicao() -> void:
	var found := false
	for seed_value in range(1, 60):
		var sim := RaceSim.new(track, tyres, teams, drivers, {"duration_pct": 0.5, "seed": seed_value, "weather": "dry", "incident_rate": 6.0, "radio": false})
		var seen := {"investigated": null}
		sim.incident.connect(func(car: CarState, kind: String, _t: String) -> void:
			if kind == "investigation" and seen["investigated"] == null:
				seen["investigated"] = car)
		for i in 30000:
			sim.step()
			var car: CarState = seen["investigated"]
			if car != null:
				assert_eq(car.penalty_pending_s, 0.0, "durante a investigação ainda não há punição") if not car.investigation.is_empty() else null
				if car.investigation.is_empty():
					break
		if seen["investigated"] != null:
			found = true
			break
	assert_true(found, "com muitos incidentes alguém é investigado")


func test_minijogo_verde_escuro_ganha_mais_que_o_claro_e_cinza_pune() -> void:
	assert_almost_eq(PitStop.tap_delta(1.0), PitStop.TAP_PERFECT_S, 0.001)
	var light := PitStop.tap_delta(0.9)
	assert_lt(PitStop.tap_delta(1.0), light - 0.2, "verde escuro ganha bem mais que o claro colado nele")
	assert_lt(light, 0.0, "verde claro ainda ganha")
	assert_gt(PitStop.tap_delta(0.0), 0.9, "cinza custa ~1 s")
	assert_gt(PitStop.TAP_NONE_S, PitStop.TAP_MISS_S, "deixar passar custa mais que o cinza")


func test_deixar_passar_o_minijogo_custa_mais_e_vale_uma_vez() -> void:
	var sim := _sim()
	var car := _mine(sim)[0]
	sim.advance(20.0)
	sim.set_pit_plan(car, PitStop.make_plan("hard"))
	assert_true(_until_stopped(sim, car))
	var before := car.box_hold_s
	assert_almost_eq(sim.pit_no_tap(car), PitStop.TAP_NONE_S, 0.001)
	assert_almost_eq(car.box_hold_s, before + PitStop.TAP_NONE_S, 0.001)
	assert_almost_eq(sim.pit_tap(car, 1.0), 0.0, 0.001, "depois de passar, não dá mais para tocar")


func test_ia_erra_paradas_as_vezes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var small := 0
	var slow := 0
	var n := 4000
	for i in n:
		var e := PitStop.ai_error(rng)
		match String(e["kind"]):
			"small":
				small += 1
				assert_between(float(e["extra"]), 0.5, 1.4)
			"slow", "stuck":
				slow += 1
				assert_gt(float(e["extra"]), 1.99)
	assert_between(float(small) / n, 0.10, 0.18, "pequenos atrasos ~14%")
	assert_between(float(slow) / n, 0.04, 0.08, "paradas lentas ~6%")


func test_double_stack_o_carro_de_tras_perde_tempo_na_fila() -> void:
	var sim := _sim()
	var cars := _mine(sim)
	sim.advance(20.0)
	for c in cars:
		sim.set_pit_plan(c, PitStop.make_plan("hard"))
	# os dois param na mesma volta: o de trás chega com o box ocupado
	var t := 0.0
	while t < 400.0 and not (cars[0].in_pit and cars[1].in_pit and cars[0].box_hold_s > 0.0 and cars[1].box_hold_s > 0.0):
		sim.step()
		t += RaceSim.DT
	var back := cars[0] if cars[0].box_wait_s > cars[1].box_wait_s else cars[1]
	var front := cars[1] if back == cars[0] else cars[0]
	assert_gt(back.box_wait_s, 0.0, "o carro de trás espera o box")
	assert_gt(back.box_hold_s, front.box_hold_s + PitStop.QUEUE_GAP_S - 0.01, "fica parado pelo menos o tempo do primeiro + a folga")
