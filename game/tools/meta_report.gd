extends SceneTree
## Calibração do meta de paradas (RaceMeta): fator de desgaste de cada pista para 1/2/3 paradas em cada duração.
## Uso: godot --headless -s tools/meta_report.gd [-- --circuit=<id>]


func _init() -> void:
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--circuit="):
			only = a.get_slice("=", 1)
	var tyres := TyreModel.new(GameData.tyres())
	var t0 := Time.get_ticks_msec()
	for r: Dictionary in Campaign.calendar():
		if only != "" and r["id"] != only:
			continue
		var track := TrackModel.new(GameData.circuit(String(r["id"])))
		var line := "%-12s base %.2f |" % [track.id, track.tyre_wear_factor]
		for pct: float in [0.25, 0.5, 1.0]:
			line += " %d%%:" % int(pct * 100)
			for s in [1, 2, 3]:
				line += " %.2f" % RaceMeta.wear_factor(s, track, tyres, pct)
			line += " |"
		print(line)
	print("ms: ", Time.get_ticks_msec() - t0)
	quit()
