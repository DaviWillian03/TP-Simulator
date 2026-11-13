extends SceneTree
## Confere o meta de paradas (RaceMeta) em corridas simuladas: paradas médias do top 10 e do vencedor.
## Uso: godot --headless -s tools/meta_check.gd [-- --circuits=a,b --pcts=0.25,1.0 --seeds=3]


func _init() -> void:
	var circuits := ["interlagos", "silverstone", "monaco", "bahrain"]
	var pcts := [0.25, 0.5, 1.0]
	var seeds := 3
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--circuits="):
			circuits = Array(a.get_slice("=", 1).split(","))
		elif a.begins_with("--pcts="):
			pcts = Array(a.get_slice("=", 1).split(",")).map(func(x: String) -> float: return float(x))
		elif a.begins_with("--seeds="):
			seeds = int(a.get_slice("=", 1))
	var tyres := TyreModel.new(GameData.tyres())
	for cid: String in circuits:
		var track := TrackModel.new(GameData.circuit(cid))
		for pct: float in pcts:
			var line := "%-12s %3d%% |" % [cid, int(pct * 100)]
			for stops in [1, 2, 3]:
				var top := 0.0
				var win := 0.0
				for s in seeds:
					var o := {"duration_pct": pct, "seed": 100 + s, "weather": "dry", "incident_rate": 0.0, "radio": false,
						"wear_factor": RaceMeta.wear_factor(stops, track, tyres, pct), "wear_nominal": RaceMeta.wear_factor(2, track, tyres, pct)}
					var sim := RaceSim.new(TrackModel.new(GameData.circuit(cid)), TyreModel.new(GameData.tyres()), GameData.teams(), GameData.drivers(), o)
					sim.run_to_end()
					var order := sim.standings()
					win += order[0].pit_stops
					for i in 10:
						top += order[i].pit_stops
				line += " meta %d: top10 %.1f venc %.1f |" % [stops, top / (10.0 * seeds), win / seeds]
			print(line)
	quit()
