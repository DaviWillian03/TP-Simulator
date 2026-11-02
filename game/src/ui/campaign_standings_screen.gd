extends Control
## Campeonatos da campanha — direção Garagem (mockup design/mockups/v6-2-campanha-campeonatos.html).
## Construtores à esquerda e pilotos à direita (rolam), com a sua equipe e seus pilotos
## destacados na cor da equipe. Usa a TimingTable no estilo "garage".

var campaign: Campaign


func _ready() -> void:
	campaign = Session.campaign
	if campaign == null:
		Session.open_campaign.call_deferred()
		return
	var page := ScreenKit.garage_page(self, campaign.player_team)
	(page["backdrop"] as GarageBackdrop).set_glow(UiStyle.team_color(campaign.player_team), 0.14)
	var layer: Control = page["layer"]

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UiStyle.SP_L)
	var back := ScreenKit.round_button("back", 52, "Voltar à sede")
	back.pressed.connect(Session.open_campaign_hub)
	head.add_child(back)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -2)
	titles.add_child(UiStyle.g_caption("%s · após %d de %d rodadas" % [campaign.team()["name"], campaign.round, Campaign.calendar().size()]))
	titles.add_child(UiStyle.g_label("CAMPEONATOS", 30, UiStyle.G_TEXT, "black"))
	head.add_child(titles)
	ScreenKit.place(head, layer, Control.PRESET_TOP_LEFT, Vector2(44, 22))

	var teams := _table(layer, "Construtores", 44, 600)
	teams.setup([
		{"title": "Pos", "width": 46, "kind": "pos"},
		{"title": "Equipe", "width": 0, "kind": "team"},
		{"title": "Vit.", "width": 60, "align": "right"},
		{"title": "Pts", "width": 70, "align": "right"},
	], campaign.teams().size(), "garage")
	var rows := campaign.team_standings()
	for i in rows.size():
		var id: String = rows[i][0]
		var t := GameData.team_by_id(campaign.teams(), id)
		var w := 0
		for d: Dictionary in campaign.drivers():
			if d["team"] == id:
				w += int(campaign.wins.get(d["id"], 0))
		teams.set_row_style(i, "me" if id == campaign.player_team else "normal")
		teams.set_pos(i, 0, str(i + 1), Color(t["color"]))
		teams.set_team(i, 1, id, t["name"])
		teams.set_text(i, 2, str(w))
		teams.set_text(i, 3, str(rows[i][1]))

	var drivers := _table(layer, "Pilotos", 664, 572)
	drivers.setup([
		{"title": "Pos", "width": 46, "kind": "pos"},
		{"title": "Piloto", "width": 0, "kind": "team"},
		{"title": "Vit.", "width": 60, "align": "right"},
		{"title": "Pts", "width": 70, "align": "right"},
	], campaign.drivers().size(), "garage")
	var drows := campaign.driver_standings()
	for i in drows.size():
		var id: String = drows[i][0]
		var d := _driver(id)
		var team_id: String = d["team"]
		drivers.set_row_style(i, "me" if team_id == campaign.player_team else "normal")
		drivers.set_pos(i, 0, str(i + 1), UiStyle.team_color_from(campaign.teams(), team_id))
		drivers.set_team(i, 1, team_id, StandingsPanel.surname(d["name"]))
		drivers.set_text(i, 2, str(int(campaign.wins.get(id, 0))))
		drivers.set_text(i, 3, str(drows[i][1]))
	layer.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(layer, "modulate:a", 1.0, 0.18)


## Tabela rolável com título, ocupando a altura útil da tela.
func _table(layer: Control, title: String, x: float, w: float) -> TimingTable:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layer.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	scroll.offset_left = x
	scroll.offset_right = x + w
	scroll.offset_top = 96
	scroll.offset_bottom = -24
	var table := TimingTable.new()
	table.me_color = UiStyle.team_color(campaign.player_team)
	table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(table)
	return table


func _driver(id: String) -> Dictionary:
	for d: Dictionary in campaign.drivers():
		if d["id"] == id:
			return d
	return {}


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.open_campaign_hub()
