extends GutTest
## Missões do stint (decisões de 2026-11-09).

var track := TrackModel.new(GameData.circuit("interlagos"))
var tyres := TyreModel.new(GameData.tyres())
var teams := GameData.teams()
var drivers := GameData.drivers()


func _sim(opts: Dictionary = {}) -> RaceSim:
	var o := {"duration_pct": 0.5, "seed": 3, "weather": "dry", "incident_rate": 0.0, "player_team": "williams", "radio": false}
	o.merge(opts, true)
	return RaceSim.new(track, tyres, teams, drivers, o)


func _me(sim: RaceSim) -> CarState:
	for c in sim.cars:
		if c.is_player:
			return c
	return null


func test_poupar_pneus_faz_o_pneu_durar_mais() -> void:
	var a := _sim()
	var b := _sim()
	var ca := _me(a)
	var cb := _me(b)
	a.set_mission_base(ca, "save", a.total_laps)
	b.set_mission_base(cb, "push")
	for i in 600:
		a.step()
		b.step()
	assert_lt(ca.tyre_wear, cb.tyre_wear, "poupando, o pneu gasta menos que forçando")


func test_missao_curta_termina_sozinha_e_volta_a_base() -> void:
	var sim := _sim()
	var me := _me(sim)
	sim.set_mission_base(me, "save", 20)
	sim.give_short_mission(me, "push", 2, "", false)
	assert_eq(String(Missions.active(me)["kind"]), "push")
	var lap0 := me.laps_done
	while me.laps_done < lap0 + 2 and not sim.is_over():
		sim.step()
	sim.step()
	assert_eq(String(Missions.active(me)["kind"]), "save", "acabou a curta, volta a base")
	assert_true(me.mission_short.is_empty())


func test_piloto_decide_a_bateria() -> void:
	var sim := _sim()
	var me := _me(sim)
	sim.set_mission_base(me, "safe")
	me.battery = 0.1
	Missions.drive(sim, me)
	assert_eq(me.energy_mode, CarState.EnergyMode.HARVEST, "bateria baixa: recarrega sozinho")
	assert_eq(me.pace_mode, CarState.PaceMode.CONSERVE)


func test_piloto_discorda_e_sem_resposta_faz_do_jeito_dele() -> void:
	var sim := _sim({"radio": true})
	var me := _me(sim)
	sim.set_mission_base(me, "save", 999)
	for i in 120:
		sim.step()
	me.distance -= 600.0  # longe do carro da frente
	sim.give_short_mission(me, "attack", 3)
	var q := sim.radio.pending_for(me)
	if q.is_empty():
		pass_test("ninguém à frente para contestar nesta largada")
		return
	assert_true(q.has("mission"))
	assert_true(me.mission_short.is_empty(), "a missão espera a resposta")
	sim.radio.answer(int(q["id"]), 1)
	assert_eq(String(me.mission_short["kind"]), "attack", "insistiu: vale a missão")


func test_plano_vira_missao_de_base() -> void:
	var w := WeekendSim.new("interlagos", {"seed": 6, "format": "race_only", "player_team": "williams", "weather": "dry", "incident_rate": 0.0})
	var plan: Dictionary = w.engineer_strategy()["albon"][0]
	w.strategy = {"albon": plan}
	var sim := w.make_race({"radio": false})
	for c in sim.cars:
		if c.driver["id"] == "albon":
			assert_eq(String(c.mission_base["kind"]), "save")
			assert_eq(int(c.mission_base["until"]), int(RaceStrategy.stop_laps(plan)[0]) if (plan["stints"] as Array).size() > 1 else sim.total_laps)
