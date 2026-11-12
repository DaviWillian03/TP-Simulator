extends GutTest
## A IA usa a mesma gerência de corrida do jogador (2026-11-12): ritmo, abordagem e ordens de equipe.


func _sim(seed_value: int = 3) -> RaceSim:
	return RaceSim.new(TrackModel.new(GameData.circuit("interlagos")), TyreModel.new(GameData.tyres()),
		GameData.teams(), GameData.drivers(), {"duration_pct": 0.5, "seed": seed_value, "weather": "dry", "incident_rate": 0.0, "player_team": "williams"})


func _ai(sim: RaceSim) -> Array[CarState]:
	var out: Array[CarState] = []
	for c in sim.cars:
		if not c.is_player:
			out.append(c)
	return out


func test_ia_usa_varios_ritmos_e_abordagens_numa_corrida() -> void:
	var sim := _sim()
	var kinds := {}
	var levels := {}
	var guard := 0
	while not sim.is_over() and guard < 200000:
		sim.step()
		guard += 1
		if guard % 50 == 0:
			for c in _ai(sim):
				kinds[String(c.mission_base.get("kind", ""))] = true
				levels[c.approach] = true
	for k in ["normal", "push", "attack"]:
		assert_true(kinds.has(k), "a IA usou o ritmo '%s'" % k)
	assert_gt(levels.size(), 1, "a IA variou a abordagem")


func test_ia_com_carro_machucado_traz_pra_casa_sem_riscos() -> void:
	var sim := _sim()
	var c: CarState = _ai(sim)[0]
	c.add_damage("floor", 0.8)
	Missions.ai_choose(sim, c)
	assert_eq(String(c.mission_base["kind"]), "safe")
	assert_eq(c.approach, -1)


func test_ia_manda_abrir_para_o_companheiro_mais_rapido() -> void:
	var sim := _sim()
	var a: CarState = null
	for c in _ai(sim):
		if c.team["id"] == "mclaren":
			a = c
			break
	var b := sim.teammate_of(a)
	sim.advance(30.0)
	b.distance = a.distance - 20.0  # colado atrás
	b.speed = a.speed
	a.tyre_wear = 0.7
	b.tyre_wear = 0.1  # pneu muito melhor
	var asked := false
	for i in 20:  # o piloto pode recusar; a IA insiste a cada volta
		a.ai_order_retry_lap = -1
		Missions.ai_team_orders(sim, a)
		if a.team_order == CarState.TeamOrder.NO_DEFEND:
			asked = true
			break
	assert_true(asked, "o carro da frente recebeu 'não defender' do companheiro mais rápido")
	b.distance = a.distance - 400.0  # longe: briga liberada
	Missions.ai_team_orders(sim, a)
	assert_eq(a.team_order, CarState.TeamOrder.FREE)
