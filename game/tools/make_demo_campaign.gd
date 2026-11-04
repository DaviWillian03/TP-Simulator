extends SceneTree
## Campanha de demonstração na reta final (capturas do campeonato ao vivo): pontos reais de 2026 após 20 rodadas
## (tools/research/snapshot), rodada 21. Grava em user://campaign.json (sobrescreve a campanha salva!).
## Uso: godot --headless -s tools/make_demo_campaign.gd -- [--team=mercedes] [--round=20]


func _init() -> void:
	var args := {}
	for a: String in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var camp := Campaign.new_real(String(args.get("team", "mercedes")))
	var snap: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://../tools/research/snapshot_2026-11-02.json"))
	if snap == null:
		snap = JSON.parse_string(FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://").path_join("../tools/research/snapshot_2026-11-02.json")))
	for id: String in snap["driver_points"]:
		camp.driver_points[id] = int(snap["driver_points"][id])
	for id: String in snap["team_points"]:
		camp.team_points[id] = int(snap["team_points"][id])
	camp.round = int(args.get("round", "20"))
	for i in camp.round:  # F2 e F3 já correram as rodadas até aqui
		camp._run_series(i)
	camp.day = Campaign._day_of(String(Campaign.calendar()[camp.round]["date"])) - 3
	camp.save()
	print("campanha de demonstração salva: rodada %d" % (camp.round + 1))
	quit()
