extends GutTest
## Corpo técnico: 4 cargos em todas as equipes, nomes reais com fonte, efeito nos treinos e no desenvolvimento.


func test_every_team_has_the_four_roles() -> void:
	for t: Dictionary in GameData.teams():
		var st := Personnel.team_staff(String(t["id"]))
		for role: String in Personnel.ROLES:
			assert_true(st.has(role), "%s sem %s" % [t["id"], role])
			assert_between(int(st[role]["skill"]), 60, 99)


func test_real_names_have_titles_and_generic_ones_do_not() -> void:
	var reals := 0
	for p: Dictionary in Personnel.team_staff_data():
		if p["real"]:
			reals += 1
			assert_true(p.has("real_title"), p["name"])
		else:
			assert_false(p.has("real_title"), p["name"])
	assert_gt(reals, 30, "a maioria dos cargos com nome real")


func test_trackside_engineering_changes_practice_skills() -> void:
	var camp := Campaign.new_real("williams")
	var albon: Dictionary = camp.team()["practice_skills"]["albon"]
	var before := float(albon["director"])
	camp.personnel.staff["trackside"] = Personnel.team_staff("mercedes")["trackside"]["id"]  # Shovlin
	camp.refresh_rating()
	assert_ne(float(camp.team()["practice_skills"]["albon"]["director"]), before)
	assert_eq(String(camp.team()["practice_skills"]["albon"]["engineer_name"]), "James Urwin")


func test_better_ai_staff_develops_faster() -> void:
	var camp := Campaign.new_real("williams")
	var merc := camp.personnel.ai_dev_factor(camp, "mercedes")
	var cad := camp.personnel.ai_dev_factor(camp, "cadillac")
	assert_gt(merc, cad, "corpo técnico melhor desenvolve mais rápido")


func test_poached_staff_leaves_a_vacancy_the_ai_fills_at_rollover() -> void:
	var camp := Campaign.new_real("williams")
	var allison: String = Personnel.team_staff("mercedes")["director"]["id"]
	camp.personnel.contracts[allison]["team"] = ""  # saiu da Mercedes
	assert_true(camp.personnel.staff_of(camp, "mercedes", "director").is_empty())
	camp.start_next_season()
	assert_false(camp.personnel.staff_of(camp, "mercedes", "director").is_empty(), "a IA contrata outro diretor")
