extends GutTest
## Largada (2026-11-10): grid em filas, sorte por piloto com viés pela habilidade real, trocas na 1ª reta.


func _sim(seed_value: int, grid: Array = []) -> RaceSim:
	var opts := {"duration_pct": 0.25, "seed": seed_value, "weather": "dry", "incident_rate": 0.0}
	if not grid.is_empty():
		opts["grid"] = grid
	return RaceSim.new(TrackModel.new(GameData.circuit("interlagos")), TyreModel.new(GameData.tyres()),
		GameData.teams(), GameData.drivers(), opts)


func test_grid_em_filas_escalonadas_e_espacadas() -> void:
	var sim := _sim(1)
	var ordered := sim.cars.duplicate()
	ordered.sort_custom(func(a: CarState, b: CarState) -> bool: return a.grid_position < b.grid_position)
	for i in range(1, ordered.size()):
		var gap: float = ordered[i - 1].distance - ordered[i].distance
		assert_almost_eq(gap, RaceSim.GRID_SPACING_M, 0.001, "slot %d" % i)
	assert_gt(RaceSim.GRID_SPACING_M, RaceSim.MIN_GAP_M, "o espaço do grid cabe a distância mínima")
	assert_gt(RaceSim.GRID_LATERAL_M, 3.0)


func test_resultado_depende_so_da_semente() -> void:
	var a := StartModel.roll("norris", 7)
	var b := StartModel.roll("norris", 7)
	assert_eq(a, b)
	assert_ne(StartModel.roll("norris", 7)[0], StartModel.roll("norris", 8)[0])


func test_maioria_normal_e_caudas_existem() -> void:
	var great := 0
	var bad := 0
	var normal := 0
	var n := 4000
	for i in n:
		var r := StartModel.roll("piastri", i)
		match String(r[1]):
			"great": great += 1
			"bad": bad += 1
			_: normal += 1
			
	assert_gt(float(normal) / n, 0.75, "maioria no padrão")
	assert_gt(great, 100, "largadas muito boas acontecem")
	assert_gt(bad, 100, "largadas muito ruins acontecem")


func test_habilidade_desloca_as_chances() -> void:
	var good := StartModel.chances(StartModel.skill_of("sainz"))
	var poor := StartModel.chances(StartModel.skill_of("hulkenberg"))
	assert_gt(good.x, poor.x, "bom largador tem mais largadas topo")
	assert_lt(good.y, poor.y, "bom largador tem menos largadas ruins")
	var neutral := StartModel.chances(StartModel.skill_of("desconhecido"))
	assert_almost_eq(neutral.x, 0.06, 0.0001)
	assert_gt(StartModel.chances(50.0, 1.0).y, StartModel.chances(50.0, 0.0).y, "chuva aumenta largada ruim")


func test_perfis_ficam_nos_limites() -> void:
	for i in 500:
		var g: float = StartModel.roll("alonso", i)[0]
		assert_between(g, -StartModel.BAD_RANGE.y, StartModel.GOOD_RANGE.y)
	assert_almost_eq(StartModel.speed_mult(0.2, StartModel.PHASE_S), 1.0, 0.0001)
	assert_almost_eq(StartModel.speed_mult(0.2, 0.0), StartModel.RAMP_FROM, 0.0001)
	assert_almost_eq(StartModel.bump(StartModel.PHASE_S), 0.0, 0.0001)


func test_largada_ruim_perde_posicoes_e_boa_ganha() -> void:
	var sim := _sim(3)
	var mid: CarState = sim.cars[10]
	var ids: Array = []
	for c in sim.cars:
		ids.append(c.driver["id"])
		c.start_gain = 0.0
		c.start_kind = ""
	var start_pos: int = mid.grid_position
	mid.start_gain = -0.35
	mid.start_kind = "bad"
	var guard := 0
	while sim.time_s < StartModel.PHASE_S + 4.0 and guard < 400:
		sim.step()
		guard += 1
	var pos_bad: int = sim.standings().find(mid)
	assert_gt(pos_bad, start_pos + 3, "perde várias posições (grid %d -> %d)" % [start_pos, pos_bad])
	var sim2 := _sim(3)
	var mid2: CarState = sim2.cars[10]
	for c in sim2.cars:
		c.start_gain = 0.0
	var start2: int = mid2.grid_position
	mid2.start_gain = 0.25
	mid2.start_kind = "great"
	guard = 0
	while sim2.time_s < StartModel.PHASE_S + 4.0 and guard < 400:
		sim2.step()
		guard += 1
	var pos_good: int = sim2.standings().find(mid2)
	assert_lt(pos_good, start2 - 3, "ganha várias posições (grid %d -> %d)" % [start2, pos_good])


func test_sem_ninguem_com_sorte_o_grid_se_mantem() -> void:
	var sim := _sim(5)
	for c in sim.cars:
		c.start_gain = 0.0
	var guard := 0
	while sim.time_s < StartModel.PHASE_S and guard < 200:
		sim.step()
		guard += 1
	var order := sim.standings()
	for i in order.size():  # sem sorte, só o ritmo: no máximo um vizinho de grid bem mais rápido passa nos primeiros metros
		assert_lte(absi(order[i].grid_position - i), 1, "posição %d (grid %d)" % [i, order[i].grid_position])


func test_largada_resultado_avisa_so_quem_foi_bem_ou_mal() -> void:
	var sim := _sim(9)
	var reports := []
	sim.start_result.connect(func(c: CarState, places: int) -> void: reports.append([c, places]))
	var guard := 0
	while sim.time_s < StartModel.PHASE_S + 1.0 and guard < 300:
		sim.step()
		guard += 1
	for r: Array in reports:
		assert_gte(absi(int(r[1])), 2)
