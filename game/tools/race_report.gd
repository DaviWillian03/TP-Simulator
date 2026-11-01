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
	var summary := args.has("summary")
	for s: String in seeds:
		_report(circuit, pct, int(s), summary)
	quit()


func _parse_args() -> Dictionary:
	var out := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		if kv.size() == 2:
			out[kv[0]] = kv[1]
	return out


func _report(circuit: String, pct: float, seed_value: int, summary: bool = false) -> void:
	var sim := RaceSim.new(TrackModel.new(GameData.circuit(circuit)), TyreModel.new(GameData.tyres()),
		GameData.teams(), GameData.drivers(), {"duration_pct": pct, "seed": seed_value})
	var penalties := [0]
	var incidents := {}
	var max_wet := [0.0]
	sim.penalty.connect(func(_c: CarState, _k: String, _r: String) -> void: penalties[0] += 1)
	sim.incident.connect(func(_c: CarState, k: String, _t: String) -> void: incidents[k] = incidents.get(k, 0) + 1)
	sim.flag_changed.connect(func(_f: int, _t: String) -> void: max_wet[0] = maxf(max_wet[0], sim.weather.wetness))
	var t0 := Time.get_ticks_msec()
	sim.run_to_end()
	var ms := Time.get_ticks_msec() - t0
	print("\n=== %s | %d voltas | semente %d | simulado em %d ms ===" % [sim.track.short_name, sim.total_laps, seed_value, ms])
	print("Ultrapassagens: %d | Volta mais rápida: %s (%s)" % [sim.overtakes_count, _fmt(sim.fastest_lap_time), sim.fastest_lap_car.code()])
	var stops := {}
	for car in sim.cars:
		stops[car.pit_stops] = stops.get(car.pit_stops, 0) + 1
	print("Paradas por carro: %s" % stops)
	var dnf := 0
	for car in sim.cars:
		if car.retired:
			dnf += 1
	print("Chuva: %s | SC %d · VSC %d · vermelha %d | abandonos %d | incidentes %s | punições %d" % [
		"sim" if not sim.weather.segments.is_empty() else "não", sim.control.sc_count, sim.control.vsc_count,
		sim.control.red_count, dnf, incidents, penalties[0]])
	if summary:
		return
	var pos := 1
	for car in sim.standings():
		var behind := sim.laps_behind_leader(car)
		var gap := "+%d volta(s)" % behind if behind > 0 else ("+%.1fs" % sim.gap_to_leader_s(car) if pos > 1 else _fmt(car.finish_time))
		var status := "  DSQ" if car.disqualified else ("  ABANDONO (%s)" % car.retire_reason if car.retired else "")
		print("%2d. %s %-16s grid %2d  %-12s paradas %d  %s%s" % [pos, car.code(), car.team["name"], car.grid_position + 1,
			gap, car.pit_stops, "-".join(car.compounds_used), status])
		pos += 1


func _fmt(seconds: float) -> String:
	var m := floori(seconds / 60.0)
	return "%d:%06.3f" % [m, seconds - m * 60]
