extends GutTest
## Demitido recebe proposta de outra equipe (#17) e segue a carreira no mesmo mundo.

var camp: Campaign


func before_each() -> void:
	camp = Campaign.new_real("ferrari")


func test_propostas_vem_da_metade_de_baixo_do_grid() -> void:
	var offers := camp.job_offers()
	assert_between(offers.size(), 1, 3)
	assert_false(offers.has("ferrari"))
	for tid: String in offers:
		assert_gt(camp.rating_rank(tid), 5, "%s é da metade de baixo" % tid)
	assert_eq(camp.job_offers(), offers, "determinístico")


func test_aceitar_troca_de_equipe_e_mantem_o_mundo() -> void:
	camp.round = Campaign.calendar().size()
	camp.trust = 0.0
	var report := camp.close_season()
	assert_eq(report["verdict"], "fired")
	var tid: String = camp.job_offers()[0]
	var grid := camp.drivers().size()
	camp.switch_team(tid)
	camp.start_next_season()
	assert_eq(camp.player_team, tid)
	assert_eq(camp.state, "active")
	assert_eq(camp.season, 2027)
	assert_eq(camp.seasons.size(), 1, "o histórico da carreira continua")
	assert_eq(camp.drivers().size(), grid)
	assert_true(camp.rival_carry.has("ferrari"), "a Ferrari volta para a IA")
	assert_false(camp.rival_carry.has(tid))
	for role: String in Personnel.ROLES:
		var id: String = camp.personnel.staff.get(role, "")
		if id != "":
			assert_eq(String(camp.personnel.contracts[id]["team"]), tid, "técnicos da nova equipe")
	var copy := Campaign.from_dict(JSON.parse_string(JSON.stringify(camp.to_dict())))
	assert_eq(copy.player_team, tid)
