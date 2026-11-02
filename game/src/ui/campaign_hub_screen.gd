extends Control
## Sede da campanha (versão mínima, mesma composição da tela inicial aprovada): o carro da
## equipe, as condições da equipe, a próxima rodada (jogar o fim de semana) e o campeonato de
## construtores. A sede completa (finanças, pessoal, P&D…) ganha mockup próprio nas próximas camadas.

const MONTHS := ["", "JAN", "FEV", "MAR", "ABR", "MAI", "JUN", "JUL", "AGO", "SET", "OUT", "NOV", "DEZ"]

var campaign: Campaign


func _ready() -> void:
	campaign = Session.campaign
	if campaign == null:
		Session.open_campaign.call_deferred()
		return
	var team := campaign.team()
	var page := ScreenKit.garage_page(self, campaign.player_team)
	(page["backdrop"] as GarageBackdrop).set_glow(Color(team["color"]))
	var layer: Control = page["layer"]

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UiStyle.SP_L)
	var back := ScreenKit.round_button("back", 52, "Menu")
	back.pressed.connect(Session.go_to_title)
	head.add_child(back)
	var emb := TeamEmblems.make_rect(campaign.player_team, 48)
	head.add_child(emb)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -2)
	titles.add_child(UiStyle.g_caption("Sede · temporada %d" % campaign.season))
	titles.add_child(UiStyle.g_label(String(team["name"]).to_upper(), 30, UiStyle.G_TEXT, "black"))
	head.add_child(titles)
	ScreenKit.place(head, layer, Control.PRESET_TOP_LEFT, Vector2(44, 24))

	# condições da equipe
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", UiStyle.SP_M)
	ScreenKit.place(info, layer, Control.PRESET_TOP_LEFT, Vector2(52, 120), Vector2(392, 0))
	info.add_child(_next_round_tile())
	var stats := GridContainer.new()
	stats.columns = 2
	stats.add_theme_constant_override("h_separation", 26)
	stats.add_theme_constant_override("v_separation", 12)
	var engine := "Próprio" if campaign.engine == "own" else (campaign.engine if campaign.engine != "" else String(team.get("power_unit", "")))
	stats.add_child(ScreenKit.stat("US$ %d mi" % int(campaign.budget_musd), "orçamento"))
	stats.add_child(ScreenKit.stat("Nível %d" % campaign.factory_level, "fábrica"))
	stats.add_child(ScreenKit.stat(engine, "motor"))
	stats.add_child(ScreenKit.stat("US$ %d mi" % int(campaign.debt_musd), "dívidas"))
	for s in stats.get_children():
		((s as VBoxContainer).get_child(0) as Label).add_theme_font_size_override("font_size", 28)
	info.add_child(stats)
	var obj := PanelContainer.new()
	obj.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_SURFACE, 16, 16, 10))
	var ov := VBoxContainer.new()
	ov.add_theme_constant_override("separation", 0)
	ov.add_child(UiStyle.g_caption("Objetivo"))
	var origin_name := String(campaign.origin.get("name", "Equipe real"))
	ov.add_child(UiStyle.g_label("%s · %s" % [campaign.objective_text(), origin_name], 16, UiStyle.G_TEXT, "bold"))
	obj.add_child(ov)
	info.add_child(obj)

	# campeonato de construtores (top 6 + a sua equipe)
	var table := VBoxContainer.new()
	table.add_theme_constant_override("separation", 2)
	ScreenKit.place(table, layer, Control.PRESET_TOP_RIGHT, Vector2(-44, 34), Vector2(330, 0))
	table.add_child(UiStyle.g_caption("Construtores · após %d de 22" % campaign.round))
	var rows := campaign.team_standings()
	for i in rows.size():
		var mine: bool = rows[i][0] == campaign.player_team
		if i >= 6 and not mine:
			continue
		table.add_child(_standing_row(i + 1, rows[i][0], int(rows[i][1]), mine))

	var car := CarHero.new()
	layer.add_child(car)
	car.custom_minimum_size = Vector2(760, 213)
	car.anchor_left = 0.69
	car.anchor_right = 0.69
	car.anchor_top = 0.80
	car.anchor_bottom = 0.80
	car.offset_left = -360
	car.offset_right = 400
	car.offset_top = -213
	car.offset_bottom = 0
	var first := 0
	for d: Dictionary in campaign.drivers():
		if d["team"] == campaign.player_team:
			first = int(d["number"])
			break
	var c2 := Color(team.get("color2", "#ffffff"))
	car.set_team(campaign.player_team, first, c2 if c2.get_luminance() > 0.35 else Color.WHITE, team)
	var plates := HBoxContainer.new()
	plates.add_theme_constant_override("separation", UiStyle.SP_XXL)
	ScreenKit.place(plates, layer, Control.PRESET_BOTTOM_RIGHT, Vector2(-56, -30))
	for d: Dictionary in campaign.drivers():
		if d["team"] == campaign.player_team:
			plates.add_child(_plate(d, Color(team["color"])))
	layer.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(layer, "modulate:a", 1.0, 0.18)


func _next_round_tile() -> Control:
	if campaign.season_over():
		var t := ScreenKit.mode_tile("Temporada encerrada", "Virada de temporada chega numa próxima camada", "main")
		t.disabled = true
		return t
	var r := campaign.next_round()
	var date: String = r["date"]
	var tile := ScreenKit.mode_tile(String(r["grand_prix"]), "RD %d · %s %s · fim de semana%s" % [int(r["round"]), date.substr(8, 2),
		MONTHS[int(date.substr(5, 2))], " sprint" if r.get("sprint", false) else ""], "main")
	tile.pressed.connect(Session.play_campaign_round)
	return tile


func _standing_row(pos: int, team_id: String, pts: int, mine: bool) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(Color(UiStyle.team_color_from(campaign.teams(), team_id), 0.28) if mine else UiStyle.G_SURFACE, 12, 12, 6))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)
	var n := UiStyle.g_label(str(pos), 15, UiStyle.G_TEXT_2, "black")
	n.custom_minimum_size = Vector2(24, 0)
	h.add_child(n)
	h.add_child(TeamEmblems.make_rect(team_id, 20))
	var name := UiStyle.g_label(String(GameData.team_by_id(campaign.teams(), team_id).get("name", team_id)), 15, UiStyle.G_TEXT, "bold")
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.clip_text = true
	h.add_child(name)
	h.add_child(UiStyle.g_label("%d pts" % pts, 15, UiStyle.G_TEXT, "black"))
	return p


func _plate(d: Dictionary, color: Color) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UiStyle.SP_M)
	var n := UiStyle.g_label(str(int(d["number"])), 54, Color(0, 0, 0, 0), "black")
	n.add_theme_color_override("font_outline_color", color.lightened(0.25))
	n.add_theme_constant_override("outline_size", 3)
	h.add_child(n)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_END
	v.add_theme_constant_override("separation", -2)
	v.add_child(UiStyle.g_caption(String(d.get("nationality", ""))))
	v.add_child(UiStyle.g_label(d["name"], 19, UiStyle.G_TEXT, "black"))
	v.add_child(UiStyle.g_label("%d pts" % int(campaign.driver_points.get(d["id"], 0)), 14, UiStyle.G_TEXT_2))
	h.add_child(v)
	return h


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.go_to_title()
