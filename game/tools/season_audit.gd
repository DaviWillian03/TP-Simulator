extends SceneTree
## Auditoria de uma temporada da campanha (modo Essencial, corridas curtas simuladas): caixa, teto, confiança, posição,
## evolução das notas e a virada (acesso/rebaixamento). Uso: godot --headless -s tools/season_audit.gd -- [--team=williams] [--seasons=1]


func _init() -> void:
	var args := {}
	for a: String in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var camp := Campaign.new_real(String(args.get("team", "williams")))
	camp.detail = "essential"
	var seasons := int(args.get("seasons", "1"))
	for s in seasons:
		var r0 := {}
		for t: Dictionary in camp.teams():
			r0[t["id"]] = float(t["car_rating"])
		while not camp.season_over():
			camp.advance_to_event()
			var w := WeekendSim.new(camp.next_round()["id"], camp.weekend_options({"duration_pct": 0.1, "format": "race_only", "weather": "dry"}))
			w.simulate_current()
			camp.record_weekend(w)
			if camp.round % 6 == 0:
				print("  rd %2d  caixa %6.1f  teto usado %5.1f  confiança %4.0f  pos %d  dívida %4.1f  P&D vagas %d/%d" % [camp.round, camp.budget_musd, camp.cap_spent(),
					camp.trust, camp.team_position(camp.player_team), camp.debt_total(), camp.dev.busy(), camp.dev.slots()])
		var rows := camp.team_standings()
		var line := ""
		for r: Array in rows:
			var t := GameData.team_by_id(camp.teams(), r[0])
			line += "%s %d (%+.1f) · " % [String(t["name"]).left(8), r[1], float(t["car_rating"]) - float(r0.get(r[0], t["car_rating"]))]
		print("TEMPORADA %d: %s" % [camp.season, line])
		print("  ledger: ", camp.ledger)
		var rep := camp.close_season()
		print("  veredito %s  pos %d meta %d  caixa %.1f  confiança %.0f  movimentos %s" % [rep["verdict"], rep["position"], rep["goal"], camp.budget_musd, camp.trust, camp.moves])
		var f2: Series = camp.series["F2"]
		var f3: Series = camp.series["F3"]
		print("  F2 campeão pilotos %s (%d) · F3 %s · rodadas F2 %d F3 %d" % [f2.driver_standings()[0][0], f2.driver_standings()[0][1], f3.driver_standings()[0][0], f2.rounds_done(), f3.rounds_done()])
		if camp.state != "active":
			print("  campanha encerrada: ", camp.state)
			break
		camp.start_next_season()
		print("  grid F1 %d: %s" % [camp.season, ", ".join(camp.teams().map(func(t: Dictionary) -> String: return String(t["name"]).left(10)))])
	quit()
