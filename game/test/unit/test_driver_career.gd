extends GutTest
## Carreira na campanha: aposentadoria (32–47, média ~36–37), base que evolui e sobe, pilotos novos na F3.


func test_retire_chance_curve() -> void:
	var d := {"birth": "1990-01-01", "rating": 80}
	assert_eq(DriverCareer.retire_chance(d, 2021, true, false), 0.0, "31 anos: ninguém para")
	assert_gt(DriverCareer.retire_chance(d, 2027, true, false), DriverCareer.retire_chance(d, 2023, true, false), "o risco cresce com a idade")
	assert_eq(DriverCareer.retire_chance(d, 2037, true, false), 1.0, "47 anos: aposenta")
	var star := {"birth": "1990-01-01", "rating": 94}
	assert_lt(DriverCareer.retire_chance(star, 2027, true, false), DriverCareer.retire_chance(d, 2027, true, false), "craque dura mais")
	assert_lt(DriverCareer.retire_chance(d, 2027, true, true), DriverCareer.retire_chance(d, 2027, true, false), "com contrato quase nunca para")


func test_regen_is_young_fictional_f3_driver() -> void:
	var used := {}
	var r := DriverCareer.make_regen(2027, 0, 1, used)
	assert_eq(r["category"], "F3")
	assert_between(DriverCareer.age_in(r, 2027), 16, 18)
	assert_between(int(r["rating"]), 46, 60)
	assert_gt(int(r["potential"]), int(r["rating"]))
	assert_true(used.has(r["name"]))
	assert_true(String(r["id"]).begins_with("regen_"))


func test_fifteen_seasons_keep_the_world_alive() -> void:
	var camp := Campaign.new_real("williams")
	var pe := camp.personnel
	var ages: Array = []
	var regen_in_f1 := false
	for i in 15:
		camp.start_next_season()
		assert_eq(camp.drivers().size(), 22, "o grid continua cheio (temporada %d)" % camp.season)
		var f3 := pe.feeder().filter(func(x: Dictionary) -> bool: return x["category"] == "F3").size()
		var f2 := pe.feeder().filter(func(x: Dictionary) -> bool: return x["category"] == "F2").size()
		assert_eq(f3, DriverCareer.F3_SIZE, "F3 completa com pilotos novos")
		assert_lte(f2, DriverCareer.F2_SIZE)
		for d: Dictionary in camp.drivers():
			if String(d["id"]).begins_with("regen_"):
				regen_in_f1 = true
	for r: Dictionary in pe.retired:
		if r["f1"]:
			ages.append(int(r["age"]))
	assert_gt(ages.size(), 5, "pilotos da F1 se aposentaram ao longo de 15 anos")
	var total := 0.0
	for a: int in ages:
		assert_between(a, DriverCareer.RETIRE_MIN, DriverCareer.RETIRE_MAX)
		total += a
	var mean := total / ages.size()
	assert_between(mean, 34.5, 40.0, "média de aposentadoria perto de 36–37 (amostra pequena)")
	assert_true(regen_in_f1, "pilotos novos fictícios chegam à F1")


func test_career_lists_survive_save_and_load() -> void:
	var camp := Campaign.new_real("williams")
	camp.start_next_season()
	var before := camp.personnel.feeder().size()
	var loaded := Campaign.from_dict(JSON.parse_string(JSON.stringify(camp.to_dict())))
	assert_eq(loaded.personnel.feeder().size(), before)
	assert_eq(loaded.personnel.retired.size(), camp.personnel.retired.size())
