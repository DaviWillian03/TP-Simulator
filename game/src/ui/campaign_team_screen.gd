extends Control
## Equipe (mockup v26-7): o carro grande no chão da garagem, as quatro características em anéis e os dois pilotos em
## cartões com o número gigante, três notas em anéis e a posição no campeonato. Atalhos para Peças e Pintura.

const ATTR_RINGS := [["pace", "#E10600", "bolt"], ["consistency", "#2FD38A", "check"], ["racecraft", "#4C8DFF", "swap"]]

var campaign: Campaign


func _ready() -> void:
	campaign = Session.campaign
	if campaign == null:
		Session.open_campaign.call_deferred()
		return
	var team := campaign.team()
	var color := Color(team["color"])
	var page := ScreenKit.garage_page(self, campaign.player_team)
	(page["backdrop"] as GarageBackdrop).set_glow(color)
	var layer: Control = page["layer"]
	var R := CampaignFrame.CONTENT
	# carro grande + reflexo
	var tex := CarArt.car_texture(team)
	var car := TextureRect.new()
	car.texture = tex
	car.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	car.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	car.position = Vector2(330, 300)
	car.size = Vector2(820, 300)
	car.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(car)
	var refl := car.duplicate() as TextureRect
	refl.flip_v = true
	refl.modulate = Color(1, 1, 1, 0.12)
	refl.position = Vector2(330, 470)
	layer.add_child(refl)
	# características do carro
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 56)
	for k: Array in [["straight", "#F5C542", "t_straight"], ["slow", "#E10600", "t_slow"], ["fast", "#4C8DFF", "t_fast"], ["rel", "#2FD38A", "t_rel"]]:
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 6)
		var val := CampaignHub.car_trait(campaign, k[0])
		v.add_child(RingGauge.make(clampf(val / 100.0, 0.0, 1.0), 92, Color(k[1]), str(roundi(val)), "", "", 8.0))
		var ic := ScreenKit.icon(k[2], 22, Color(k[1]))
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(ic)
		stats.add_child(v)
	ScreenKit.place(stats, layer, Control.PRESET_TOP_LEFT, Vector2(410, R.position.y + 8))
	# pilotos
	var ids := campaign.team_driver_ids(campaign.player_team)
	var rows := campaign.driver_standings()
	for i in mini(ids.size(), 2):
		var x := R.position.x + 10.0 if i == 0 else R.end.x - 290.0
		layer.add_child(_driver_card(ids[i], color, Rect2(x, R.position.y + 4, 280, 250), rows))
	# legenda e atalhos
	var leg := HBoxContainer.new()
	leg.add_theme_constant_override("separation", 8)
	for k: Array in [["t_straight", "#F5C542", "reta"], ["t_slow", "#E10600", "lentas"], ["t_fast", "#4C8DFF", "rápidas"], ["t_rel", "#2FD38A", "confiab."]]:
		leg.add_child(_legend(k[0], Color(k[1]), k[2]))
	ScreenKit.place(leg, layer, Control.PRESET_BOTTOM_LEFT, Vector2(R.position.x + 10, -22))
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", 10)
	var paint := ScreenKit.light_button("PINTURA")
	paint.pressed.connect(Session.open_campaign_studio)
	acts.add_child(paint)
	var parts := CutButton.new()
	parts.text = "PEÇAS"
	parts.custom_minimum_size = Vector2(160, 56)
	parts.add_theme_font_size_override("font_size", UiStyle.fs(18))
	parts.pressed.connect(Session.open_campaign_car)
	acts.add_child(parts)
	ScreenKit.place(acts, layer, Control.PRESET_BOTTOM_RIGHT, Vector2(-16, -16))
	CampaignFrame.apply(layer, "team", true)


func _driver_card(id: String, color: Color, r: Rect2, rows: Array) -> Control:
	var d: Dictionary = {}
	for x: Dictionary in campaign.drivers():
		if x["id"] == id:
			d = x
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.clip_contents = true
	b.position = r.position
	b.size = r.size
	for st: String in ["normal", "hover", "pressed", "hover_pressed"]:
		var box := UiStyle.g_box(Color(color, 0.22) if st == "normal" else Color(color, 0.3), 22, 0, 0)
		box.bg_color = Color("#171a21").lerp(color, 0.28 if st == "normal" else 0.36)
		b.add_theme_stylebox_override(st, box)
	b.pressed.connect(Session.open_campaign_staff)
	ScreenKit.press_feedback(b)
	var num := UiStyle.g_label(str(int(d.get("number", 0))), 150, Color(1, 1, 1, 0.16), "black")
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	num.position = Vector2(0, -26)
	num.size = Vector2(r.size.x - 10, 160)
	b.add_child(num)
	var av := DriverPhotos.make_avatar(d, color, 84)
	av.position = Vector2(18, 18)
	b.add_child(av)
	var nm := UiStyle.g_label(String(d.get("name", "")).to_upper(), 20, UiStyle.G_TEXT, "black")
	nm.position = Vector2(18, 112)
	nm.size = Vector2(r.size.x - 36, 30)
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.add_child(nm)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	for a: Array in ATTR_RINGS:
		var v := DriverStats.attr(d, a[0])
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 2)
		cell.add_child(RingGauge.make(clampf(v / 100.0, 0.0, 1.0), 54, Color(a[1]), str(roundi(v))))
		var ic := ScreenKit.icon(a[2], 14, Color(a[1]))
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cell.add_child(ic)
		h.add_child(cell)
	var pos := 0
	for k in rows.size():
		if rows[k][0] == id:
			pos = k + 1
	var pl := UiStyle.g_label("%dº" % pos, 28, UiStyle.G_TEXT, "black")
	pl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(pl)
	h.position = Vector2(18, 150)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	for c in b.get_children():
		if c is Control:
			(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


func _legend(icon_name: String, col: Color, text: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(Color(0.06, 0.07, 0.09, 0.8), 15, 12, 4))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.add_child(ScreenKit.icon(icon_name, 16, col))
	h.add_child(UiStyle.g_label(text, 13, UiStyle.G_TEXT, "black"))
	p.add_child(h)
	return p
