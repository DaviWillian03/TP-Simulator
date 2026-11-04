extends SceneTree
## Relatório do desenvolvimento por peças da IA ao longo de uma temporada (calibração).
## Uso: godot --headless -s tools/parts_report.gd -- [--team=williams] [--days=280]


func _init() -> void:
	var args := {}
	for a: String in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var camp := Campaign.new_real(String(args.get("team", "williams")))
	camp.detail = "advanced"
	var days := int(args.get("days", "280"))
	var start := {}
	for t: Dictionary in camp.teams():
		start[t["id"]] = float(t["car_rating"])
	for i in days:
		camp.day += 1
		for cp: CarParts in camp.parts.values():
			cp.day_step(camp)
		if i % 14 == 13:  # uma "corrida" a cada duas semanas: desgaste e revelações
			for cp: CarParts in camp.parts.values():
				cp.after_race(camp)
	camp.refresh_rating()
	var total := 0.0
	for t: Dictionary in camp.teams():
		var cp: CarParts = camp.parts[t["id"]]
		var counts := {"good": 0, "small": 0, "bad": 0}
		for pid: String in CarParts.part_ids():
			for s: Dictionary in cp.spec_list(pid):
				if counts.has(s["outcome"]):
					counts[s["outcome"]] += 1
		var gain := float(t["car_rating"]) - float(start[t["id"]])
		if t["id"] != camp.player_team:
			total += gain
		print("%-12s %5.1f -> %5.1f (%+.2f)  acertos %d · menores %d · ruins %d  k=%.2f" % [t["id"], start[t["id"]], t["car_rating"], gain,
			counts["good"], counts["small"], counts["bad"], cp.gain_k])
	print("ganho médio da IA: %+.2f" % (total / (camp.teams().size() - 1)))
	quit()
