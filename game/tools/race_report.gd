extends SceneTree
## Simula corridas inteiras sem gráficos e imprime um relatório (ferramenta de balanceamento).
##
## Uso (na pasta game/):
##   godot --headless -s tools/race_report.gd -- --circuit=interlagos --pct=1.0 --seeds=1,2,3


func _init() -> void:
	var args := _parse_args()
	var circuit: String = args.get("circuit", "interlagos")
	var pct := float(args.get("pct", "1.0"))
	var seeds: Array = str(args.get("seeds", "1")).split(",")
	for s: String in seeds:
		_report(circuit, pct, int(s))
	quit()


func _parse_args() -> Dictionary:
	var out := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		if kv.size() == 2:
			out[kv[0]] = kv[1]
	return out


func _report(circuit: String, pct: float, seed_value: int) -> void:
	var sim := RaceSim.new(TrackModel.new(GameData.circuit(circuit)), TyreModel.new(GameData.tyres()),
		GameData.teams(), GameData.drivers(), {"duration_pct": pct, "seed": seed_value})
	var t0 := Time.get_ticks_msec()
	sim.run_to_end()
	var ms := Time.get_ticks_msec() - t0
	print("\n=== %s | %d voltas | semente %d | simulado em %d ms ===" % [sim.track.short_name, sim.total_laps, seed_value, ms])
	print("Ultrapassagens: %d | Volta mais rápida: %s (%s)" % [sim.overtakes_count, _fmt(sim.fastest_lap_time), sim.fastest_lap_car.code()])
	var stops := {}
	for car in sim.cars:
		stops[car.pit_stops] = stops.get(car.pit_stops, 0) + 1
	print("Paradas por carro: %s" % stops)
	var pos := 1
	for car in sim.standings():
		var behind := sim.laps_behind_leader(car)
		var gap := "+%d volta(s)" % behind if behind > 0 else ("+%.1fs" % sim.gap_to_leader_s(car) if pos > 1 else _fmt(car.finish_time))
		print("%2d. %s %-16s grid %2d  %-12s paradas %d  %s%s" % [pos, car.code(), car.team["name"], car.grid_position + 1,
			gap, car.pit_stops, "-".join(car.compounds_used), "  DSQ" if car.disqualified else ""])
		pos += 1


func _fmt(seconds: float) -> String:
	var m := int(seconds) / 60
	return "%d:%06.3f" % [m, seconds - m * 60]
