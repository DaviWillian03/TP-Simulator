extends GutTest
## Previsão por equipe (2026-11-13): erra mais com pessoal fraco, melhora quando a chuva chega perto, nunca é 100%,
## e a IA decide pela previsão da própria equipe.

const LAP := 90.0
const RAIN_AT := 1800.0  ## chuva começa na volta 20


func _weather() -> WeatherModel:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	return WeatherModel.new(0.0, 6000.0, rng, {"weather": [{"start_s": RAIN_AT, "end_s": 3600.0, "intensity": 0.7}]})


func _avg_error(skill: float, now: float) -> float:
	var w := _weather()
	var total := 0.0
	var n := 0
	for s in 60:
		var fc := TeamForecast.new(w, skill, 1000 + s, 6000.0)
		var win := fc.window(now, LAP, 30)
		var real := (RAIN_AT - now) / LAP
		total += absf((float(win["start"]) if int(win["start"]) >= 0 else 30.0) - real)
		n += 1
	return total / n


func test_pessoal_melhor_erra_menos() -> void:
	var weak := _avg_error(50.0, 0.0)
	var strong := _avg_error(90.0, 0.0)
	assert_lt(strong, weak, "equipe forte erra menos (forte %.1f × fraca %.1f voltas)" % [strong, weak])
	assert_gt(strong, 0.3, "nem a melhor equipe acerta sempre")


func test_erro_encolhe_quando_a_chuva_chega_perto() -> void:
	var far := _avg_error(65.0, 0.0)
	var near := _avg_error(65.0, RAIN_AT - 3 * LAP)
	assert_lt(near, far, "perto da chuva a previsão melhora (%.1f → %.1f voltas)" % [far, near])


func test_nunca_cem_por_cento() -> void:
	var w := _weather()
	var fc := TeamForecast.new(w, 100.0, 7, 6000.0)
	for e: Dictionary in fc.by_lap(RAIN_AT + 300.0, LAP, 10):
		assert_lte(float(e["chance"]), TeamForecast.CHANCE_MAX)
		assert_gte(float(e["chance"]), TeamForecast.CHANCE_MIN)
	assert_lte(fc.confidence(0), TeamForecast.CONF_MAX, "confiança nunca chega a 100%")


func test_cada_equipe_tem_a_sua_previsao_na_corrida() -> void:
	var sim := RaceSim.new(TrackModel.new(GameData.circuit("interlagos")), TyreModel.new(GameData.tyres()), GameData.teams(), GameData.drivers(),
		{"duration_pct": 0.25, "seed": 3, "incident_rate": 0.0, "weather": [{"start_s": 600.0, "end_s": 2000.0, "intensity": 0.8}]})
	assert_eq(sim.forecasts.size(), GameData.teams().size(), "uma previsão por equipe")
	var skills := {}
	for tid: String in sim.forecasts:
		skills[snappedf((sim.forecasts[tid] as TeamForecast).skill, 0.1)] = true
	assert_gt(skills.size(), 1, "o pessoal de cada equipe muda a qualidade da previsão")
	var guard := 0
	while not sim.over and guard < 200000:
		sim.step()
		guard += 1
	var wet_tyres := 0
	for c in sim.cars:
		if not c.retired and not sim.tyres.is_dry(c.tyre):
			wet_tyres += 1
	assert_gt(wet_tyres, 0, "com a própria previsão a IA ainda vai para pneus de chuva")
