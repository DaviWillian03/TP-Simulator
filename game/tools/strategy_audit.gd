extends SceneTree
## Auditoria de estratégia da IA (paradas tardias, nº de paradas, variedade de pneus) e do espetáculo da corrida.
## Uso: godot --headless -s tools/strategy_audit.gd -- --pct=0.25 --seeds=1,2,3,4,5 [--weather=dry|rain]

var _pits: Array = []
var _overtakes := 0


func _init() -> void:
	var args := {}
	for a: String in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var pct := float(args.get("pct", "0.25"))
	var seeds: Array = String(args.get("seeds", "1,2,3")).split(",")
	var circuits: Array = String(args.get("circuits", "interlagos,monza,monaco,silverstone,suzuka,baku")).split(",")
	var tot := {"races": 0, "cars": 0, "late": 0, "stops0": 0, "stops1": 0, "stops2": 0, "stops3": 0, "overtakes": 0, "dnf": 0, "win_from_pole": 0,
		"compounds": {}, "first_stop_spread": []}
	for c: String in circuits:
		for s: String in seeds:
			var opts := {"duration_pct": pct, "seed": int(s), "player_team": "", "incident_rate": 1.0}
			if args.has("weather"):
				opts["weather"] = args["weather"]
			var sim := RaceSim.new(TrackModel.new(GameData.circuit(c)), TyreModel.new(GameData.tyres()), GameData.teams(), GameData.drivers(), opts)
			_pits = []
			_overtakes = 0
			sim.pit_stop.connect(func(car: CarState, comp: String, _st: float) -> void: _pits.append([car.driver["id"], sim.leader_lap(), comp, sim.weather.rain_now()]))
			sim.overtake.connect(func(_a: CarState, _d: CarState, _z: String) -> void: _overtakes += 1)
			var grid_first: String = sim.standings()[0].driver["id"]
			var guard := 0
			while not sim.is_over() and guard < 200000:
				sim.advance(1.0)
				guard += 1
			var laps: int = sim.total_laps
			tot["races"] += 1
			tot["overtakes"] += _overtakes
			var per := {}
			for p: Array in _pits:
				per[p[0]] = int(per.get(p[0], 0)) + 1
				tot["compounds"][p[2]] = int(tot["compounds"].get(p[2], 0)) + 1
				if int(p[1]) >= laps - maxi(2, roundi(laps * 0.15)) and float(p[3]) < 0.1:
					tot["late"] += 1
			if args.has("laps"):
				var hist := {}
				for p: Array in _pits:
					hist[int(p[1])] = int(hist.get(int(p[1]), 0)) + 1
				var ks := hist.keys()
				ks.sort()
				print("   paradas por volta: ", ks.map(func(k: int) -> String: return "%d:%d" % [k, hist[k]]))
			var firsts: Array = []
			var seen := {}
			for p: Array in _pits:
				if not seen.has(p[0]):
					seen[p[0]] = true
					firsts.append(int(p[1]))
			if not firsts.is_empty():
				firsts.sort()
				(tot["first_stop_spread"] as Array).append(firsts[firsts.size() - 1] - firsts[0])
			for car: CarState in sim.cars:
				tot["cars"] += 1
				if car.retired:
					tot["dnf"] += 1
				var n := int(per.get(car.driver["id"], 0))
				tot["stops%d" % mini(n, 3)] += 1
			if sim.standings()[0].driver["id"] == grid_first:
				tot["win_from_pole"] += 1
			print("%-12s seed %s  voltas %d  paradas %s  ultrap %d" % [c, s, laps, str(per.values().reduce(func(a: int, b: int) -> int: return a + b, 0)), _overtakes])
	print(JSON.stringify(tot, "  "))
	quit()
