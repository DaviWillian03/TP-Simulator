extends GutTest
## Regras técnicas (motor, aerodinâmica, chassi, reabastecimento, calendário): efeito na corrida, Conselho e ano de virada.

const DRY := {"weather": "dry", "incident_rate": 0.0, "seed": 7, "duration_pct": 0.3, "radio": false}


func _race(tech: Dictionary, circuit: String = "interlagos") -> RaceSim:
	var o := DRY.duplicate()
	o["tech"] = tech
	return RaceSim.new(TrackModel.new(GameData.circuit(circuit)), TyreModel.new(GameData.tyres()), GameData.teams(), GameData.drivers(), o)


func test_v10_is_faster_and_battery_matters_less() -> void:
	var base := _race({})
	var v10 := _race({"engine": "v10"})
	var car_a := base.cars[0]
	var car_b := v10.cars[0]
	assert_lt(v10.ideal_pace(car_b), base.ideal_pace(car_a), "V10 mais rápido")
	assert_lt(v10.energy_k, base.energy_k, "modos de energia pesam menos")
	assert_gt(v10.engine_pitch, 1.0, "som mais agudo")


func test_ground_effect_brings_more_overtakes() -> void:
	var a := _race({}, "silverstone")
	var b := _race({"aero": "ground"}, "silverstone")
	a.run_to_end()
	b.run_to_end()
	assert_gt(b.overtakes_count, a.overtakes_count, "efeito solo: mais ultrapassagens")


func test_heavy_chassis_wears_tyres_more() -> void:
	assert_gt(_race({"chassis": "heavy"}).wear_multiplier(), _race({}).wear_multiplier())


func test_refuelling_forces_extra_stops() -> void:
	var a := _race({})
	var b := _race({"refuel": true})
	a.run_to_end()
	b.run_to_end()
	var stops_a := 0
	var stops_b := 0
	for c in a.cars:
		stops_a += c.pit_stops
	for c in b.cars:
		if not c.retired:
			assert_gte(c.pit_stops, 2, "%s: com reabastecimento são ao menos 2 paradas" % c.code())
		stops_b += c.pit_stops
	assert_gt(stops_b, stops_a)


func test_council_offers_one_technical_proposal_and_applies_it() -> void:
	var camp := Campaign.new_real("williams")
	camp.round = Campaign.calendar().size()
	camp.regs.open_vote(camp)
	var tech: Array = camp.regs.proposals.filter(func(p: Dictionary) -> bool: return p["kind"] == "tech")
	assert_eq(tech.size(), 1, "uma proposta técnica por temporada")
	var p: Dictionary = tech[0]
	for t: String in camp.regs.votes[p["id"]]:
		camp.regs.votes[p["id"]][t] = "y"  # aprovada
	camp.start_next_season()
	for k: String in p["set"]:
		assert_eq(camp.regs.tech[k], p["set"][k], "vale na temporada seguinte")
	assert_true(camp.weekend_options().has("tech"))


func test_regulation_reset_brings_the_grid_closer() -> void:
	var camp := Campaign.new_real("williams")
	var spread := func() -> float:
		var lo := 999.0
		var hi := -999.0
		for t: Dictionary in camp.teams():
			lo = minf(lo, float(t["car_rating"]))
			hi = maxf(hi, float(t["car_rating"]))
		return hi - lo
	var before: float = spread.call()
	camp.regulation_reset(["aero"])
	camp.refresh_rating()
	assert_lt(spread.call(), before, "ano de virada: os carros se aproximam")


func test_twenty_race_calendar_skips_dropped_rounds() -> void:
	var camp := Campaign.new_real("williams")
	camp.regs.tech["races"] = 21
	assert_eq(camp.regs.race_count(), 21)
	var dropped: Array = camp.regs.dropped_ids()
	assert_eq(dropped.size(), 2)
	for i in Campaign.calendar().size():
		camp.round = i
		camp._skip_cancelled()
		assert_false(dropped.has(String(Campaign.calendar()[mini(camp.round, Campaign.calendar().size() - 1)]["id"])) and camp.round < Campaign.calendar().size(), "etapa fora do calendário é pulada")


func test_tech_survives_save_and_load() -> void:
	var camp := Campaign.new_real("williams")
	camp.regs.tech["engine"] = "v8"
	camp.regs.tech["refuel"] = true
	var loaded := Campaign.from_dict(JSON.parse_string(JSON.stringify(camp.to_dict())))
	assert_eq(loaded.regs.tech["engine"], "v8")
	assert_true(loaded.regs.tech["refuel"])
