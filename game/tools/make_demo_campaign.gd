extends SceneTree
## Campanha de demonstração na reta final (capturas do campeonato ao vivo): pontos reais de 2026 após 20 rodadas
## (tools/research/snapshot), rodada 21. Grava em user://campaign.json (sobrescreve a campanha salva!).
## Com --dev, simula também o desenvolvimento do carro rodada a rodada (projetos de peça do jogador e da IA, desgaste,
## gráfico da temporada e resultados aproximados pela nota) — base das capturas da tela Carro (v42).
## Uso: godot --headless -s tools/make_demo_campaign.gd -- [--team=mercedes] [--round=20] [--dev]


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
	var target := int(args.get("round", "20"))
	if args.has("dev"):
		_simulate_dev(camp, target)
	camp.round = target
	for i in camp.round:  # F2 e F3 já correram as rodadas até aqui
		camp._run_series(i)
	camp.day = Campaign._day_of(String(Campaign.calendar()[camp.round]["date"])) - 3
	camp.save()
	print("campanha de demonstração salva: rodada %d" % (camp.round + 1))
	quit()


## Rodada a rodada: o tempo passa (projetos da IA e do jogador andam), a corrida desgasta as peças, a nota de cada equipe
## vai para o gráfico e o resultado sai da nota com um pouco de sorte.
func _simulate_dev(camp: Campaign, rounds: int) -> void:
	var cp := camp.my_parts()
	cp.next_share = 0.2
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for r in rounds:
		camp.round = r
		var race_day := Campaign._day_of(String(Campaign.calendar()[r]["date"]))
		while camp.day < race_day:
			camp.day += 1
			for p: CarParts in camp.parts.values():
				p.day_step(camp)
			camp.dev.camp_day_step(camp, [])
		cp.auto_projects(camp, 9.0)  # o jogador começa projetos uma vez por rodada
		camp.refresh_rating()
		var order: Array = camp.drivers().filter(func(d: Dictionary) -> bool: return camp.team_of(String(d["id"])) != "")
		var score := {}
		for d: Dictionary in order:
			var t := GameData.team_by_id(camp.teams(), camp.team_of(String(d["id"])))
			score[d["id"]] = float(t.get("car_rating", 80.0)) + float(d.get("rating", 80)) * 0.3 + rng.randfn(0.0, 2.5)
		order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(score[a["id"]]) > float(score[b["id"]]))
		camp.history.append({"round": r + 1, "circuit": Campaign.calendar()[r]["id"], "results": order.map(func(d: Dictionary) -> String: return String(d["id"]))})
		for p: CarParts in camp.parts.values():
			p.after_race(camp)
		camp.sponsors.fill_free(camp)
		camp.sponsors.after_race(camp)
		camp.round = r + 1
		camp.log_ratings()
	cp.done_research.clear()  # as entregas da demo já foram "vistas"
