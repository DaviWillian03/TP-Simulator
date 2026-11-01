extends GutTest
## Simulação de corrida: chegada, regras, pit stop, ultrapassagens e determinismo.

var track_data: Dictionary
var tyre_data: Dictionary
var teams: Array
var drivers: Array


func before_all() -> void:
	track_data = GameData.circuit("interlagos")
	tyre_data = GameData.tyres()
	teams = GameData.teams()
	drivers = GameData.drivers()


## Corridas destes testes: pista seca e sem incidentes, salvo se o teste pedir o contrário.
func _sim(options: Dictionary, overrides: Dictionary = {}) -> RaceSim:
	var td := track_data.duplicate(true)
	td.merge(overrides, true)
	var opts := {"weather": "dry", "incident_rate": 0.0}
	opts.merge(options, true)
	return RaceSim.new(TrackModel.new(td), TyreModel.new(tyre_data), teams, drivers, opts)


func _result_codes(sim: RaceSim) -> Array:
	var out := []
	for car in sim.standings():
		out.append(car.code())
	return out


func test_corrida_25_por_cento_termina_com_todos_classificados() -> void:
	var sim := _sim({"duration_pct": 0.25, "seed": 7})
	assert_eq(sim.total_laps, 18)
	sim.run_to_end()
	assert_true(sim.is_over())
	var result := sim.standings()
	assert_eq(result.size(), 22)
	for car in result:
		assert_true(car.finished, "%s terminou" % car.code())
	assert_eq(result[0].laps_done, 18)


func test_tempo_de_volta_e_realista_para_interlagos() -> void:
	var sim := _sim({"duration_pct": 0.25, "seed": 3})
	sim.run_to_end()
	assert_between(sim.fastest_lap_time, 70.0, 80.0, "volta mais rápida em segundos")


func test_mesma_semente_produz_a_mesma_corrida() -> void:
	var a := _sim({"duration_pct": 0.25, "seed": 42})
	var b := _sim({"duration_pct": 0.25, "seed": 42})
	a.run_to_end()
	b.run_to_end()
	assert_eq(_result_codes(a), _result_codes(b))
	assert_eq(a.overtakes_count, b.overtakes_count)


func test_ia_cumpre_a_regra_dos_dois_compostos() -> void:
	var sim := _sim({"duration_pct": 0.5, "seed": 11})
	sim.run_to_end()
	for car in sim.cars:
		assert_true(sim.tyres.rule_satisfied(car.compounds_used), "%s usou %s" % [car.code(), car.compounds_used])
		assert_false(car.disqualified)
		assert_gt(car.pit_stops, 0)


func test_jogador_sem_parar_e_desclassificado() -> void:
	var sim := _sim({"duration_pct": 0.25, "seed": 5, "player_team": "williams", "radio": false})
	sim.run_to_end()  # o jogador não chamou ninguém para o box (e o rádio está desligado)
	for car in sim.cars:
		if car.is_player:
			assert_eq(car.pit_stops, 0)
			assert_true(car.disqualified, "%s deveria ser desclassificado" % car.code())


func test_pit_stop_do_jogador_troca_o_pneu() -> void:
	var sim := _sim({"duration_pct": 0.25, "seed": 5, "player_team": "williams"})
	var car: CarState = null
	for c in sim.cars:
		if c.is_player:
			car = c
			break
	var new_compound := "hard" if car.tyre != "hard" else "medium"
	sim.request_pit(car, new_compound)
	var steps := 0
	while car.pit_stops == 0 and steps < 20000:
		sim.step()
		steps += 1
	assert_eq(car.pit_stops, 1)
	assert_eq(car.tyre, new_compound)
	assert_lt(car.tyre_wear, 0.05)
	assert_eq(car.compounds_used.size(), 2)


func test_pit_stop_custa_o_tempo_do_pit_lane() -> void:
	# mesmo carro, mesma semente: com e sem parada na volta 2
	var base := _sim({"duration_pct": 0.25, "seed": 9, "player_team": "cadillac"})
	var pit := _sim({"duration_pct": 0.25, "seed": 9, "player_team": "cadillac"})
	var car_base: CarState = base.cars[21]
	var car_pit: CarState = pit.cars[21]
	pit.request_pit(car_pit, "hard")
	while car_base.laps_done < 3:
		base.step()
	while car_pit.laps_done < 3:
		pit.step()
	var loss := car_pit.lap_start_time - car_base.lap_start_time
	assert_between(loss, 15.0, 35.0, "perda de tempo do pit stop em segundos")


func test_modo_ataque_gasta_mais_pneu() -> void:
	var calm := _sim({"duration_pct": 0.25, "seed": 1, "player_team": "haas"})
	var push := _sim({"duration_pct": 0.25, "seed": 1, "player_team": "haas"})
	for c in push.cars:
		if c.is_player:
			push.set_pace_mode(c, CarState.PaceMode.ATTACK)
	for i in 1500:
		calm.step()
		push.step()
	var wear_calm := 0.0
	var wear_push := 0.0
	for i in calm.cars.size():
		if calm.cars[i].is_player:
			wear_calm += calm.cars[i].tyre_wear
			wear_push += push.cars[i].tyre_wear
	assert_gt(wear_push, wear_calm)


func test_pista_dificil_tem_menos_ultrapassagens() -> void:
	var easy_total := 0
	var hard_total := 0
	for s in [1, 2, 3]:
		var easy := _sim({"duration_pct": 0.25, "seed": s}, {"overtaking_difficulty": 0.1})
		var hard := _sim({"duration_pct": 0.25, "seed": s}, {"overtaking_difficulty": 0.95})
		easy.run_to_end()
		hard.run_to_end()
		easy_total += easy.overtakes_count
		hard_total += hard.overtakes_count
	assert_gt(easy_total, hard_total * 2, "fácil=%d difícil=%d" % [easy_total, hard_total])


func test_diferenca_para_o_lider_cresce_ao_longo_do_grid() -> void:
	var sim := _sim({"duration_pct": 0.25, "seed": 4})
	for i in 3000:
		sim.step()
	var order := sim.standings()
	assert_eq(sim.gap_to_leader_s(order[0]), 0.0)
	assert_gt(sim.gap_to_leader_s(order[10]), sim.gap_to_leader_s(order[1]))


func test_diferencas_finais_sao_positivas_e_crescentes() -> void:
	# regressão: carros que cruzavam a linha depois do líder apareciam com +0.0 s
	var sim := _sim({"duration_pct": 0.25, "seed": 8})
	sim.run_to_end()
	var order := sim.standings()
	var previous := 0.0
	for i in range(1, order.size()):
		var car := order[i]
		if car.disqualified or sim.laps_behind_leader(car) > 0:
			continue
		var gap := sim.gap_to_leader_s(car)
		assert_gt(gap, 0.0, "%s" % car.code())
		assert_true(gap >= previous, "%s: %.3f depois de %.3f" % [car.code(), gap, previous])
		previous = gap


func test_tempos_de_volta_tem_precisao_de_milissegundos() -> void:
	var sim := _sim({"duration_pct": 0.25, "seed": 8})
	sim.run_to_end()
	var not_round := 0
	for car in sim.cars:
		var tenths := car.best_lap_time * 10.0
		if absf(tenths - roundf(tenths)) > 0.001:
			not_round += 1
	assert_gt(not_round, 15, "tempos não deveriam ser múltiplos de 0,1 s")
