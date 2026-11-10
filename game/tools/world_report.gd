extends SceneTree
## Relatório de calibração do Campeonato Mundial F1: simula temporadas completas só com a IA e mostra pontos por
## equipe e vitórias por piloto. Uso: godot --headless -s tools/world_report.gd -- --seeds=1,2 --pct=0.1

func _init() -> void:
	var seeds: Array = [1]
	var pct := 0.1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = a.trim_prefix("--seeds=").split(",")
		elif a.begins_with("--pct="):
			pct = float(a.trim_prefix("--pct="))
	var team_pts := {}
	var wins := {}
	for sd in seeds:
		var w := WorldChampionship.start("williams")
		w.seed_base = int(sd)
		w.parts.setup(GameData.teams(), w.seed_base)
		while not w.season_over():
			var wk := WeekendSim.new(w.next_round()["id"], w.weekend_options({"duration_pct": pct}))
			var guard := 0
			while not wk.is_over() and guard < 20:
				wk.simulate_current()
				guard += 1
			w.record_weekend(wk)
		for row: Array in w.team_standings():
			team_pts[row[0]] = int(team_pts.get(row[0], 0)) + int(row[1])
		for id: String in w.wins:
			wins[id] = int(wins.get(id, 0)) + int(w.wins[id])
	var rows: Array = []
	for id: String in team_pts:
		rows.append([id, float(team_pts[id]) / seeds.size()])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1])
	print("PONTOS MÉDIOS POR EQUIPE (", seeds.size(), " temporada(s), corrida a ", pct * 100, "%):")
	for r: Array in rows:
		print("  %-12s %6.1f" % [r[0], r[1]])
	var ws: Array = []
	for id: String in wins:
		ws.append([id, float(wins[id]) / seeds.size()])
	ws.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1])
	print("VITÓRIAS POR TEMPORADA (média):")
	for r: Array in ws.slice(0, 8):
		print("  %-12s %4.1f" % [r[0], r[1]])
	quit()
