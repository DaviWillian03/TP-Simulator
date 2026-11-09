class_name CampaignHub
extends Control
## Sede da campanha (mockup v15-1 aprovado, 2026-11-04). Três colunas: o próximo GP (o que a pista pede, como o seu
## carro se sai nela, "avançar com preparação recomendada" e as próximas pistas), até 3 assuntos (DECISÃO × NOTÍCIA, com
## atalho) e a equipe (posições, meta da diretoria, fábrica). Avisos das peças e eventos aparecem ao abrir.

var campaign: Campaign
var _layer: Control
var _hero: PanelContainer
var _date: Label
var _count_days: Label


func _ready() -> void:
	campaign = Session.campaign
	if campaign == null:
		Session.open_campaign.call_deferred()
		return
	if campaign.season_over() or campaign.state != "active":
		Session.open_campaign_report.call_deferred()
		return
	var team := campaign.team()
	var color := Color(team["color"])
	var page := ScreenKit.garage_page(self, campaign.player_team)
	(page["backdrop"] as GarageBackdrop).set_glow(color)
	var layer: Control = page["layer"]

	# mosaico (mockup v26-4): próximo GP · pilotos · carro · sede · tabela · diretoria, com a moldura da campanha
	_layer = layer
	var R := CampaignFrame.CONTENT
	var x0 := R.position.x
	var y0 := R.position.y
	layer.add_child(_gp_tile(Rect2(x0, y0, 540, 330)))
	layer.add_child(_drivers_tile(Rect2(x0 + 556, y0, 380, 330), color))
	layer.add_child(_car_tile(Rect2(x0, y0 + 346, 540, R.size.y - 346)))
	layer.add_child(_hq_tile(Rect2(x0 + 556, y0 + 346, 380, R.size.y - 346)))
	layer.add_child(_table_tile(Rect2(x0 + 952, y0, R.size.x - 952, 390)))
	layer.add_child(_board_tile(Rect2(x0 + 952, y0 + 406, R.size.x - 952, R.size.y - 406)))
	CampaignFrame.apply(layer, "hub", true)
	if Session.campaign_open_news:
		Session.campaign_open_news = false
		_open_news.call_deferred()
	layer.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(layer, "modulate:a", 1.0, 0.18)
	_show_next_event.call_deferred()
	PartsDialogs.show_pending.call_deferred(self, campaign, _after_parts_dialog)
	if campaign.livery != null and not campaign.livery.launch.is_empty():
		_show_launch.call_deferred()


# --- mosaico (v26-4) -------------------------------------------------------------------------------------------

## Bloco do mosaico: botão grande com cantos arredondados; o conteúdo é posicionado à mão dentro dele.
func _tile(r: Rect2, on_press: Callable, fill := Color("#171a21")) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.clip_contents = true
	b.position = r.position
	b.size = r.size
	for st: String in ["normal", "hover", "pressed", "hover_pressed"]:
		var box := UiStyle.g_box(fill if st == "normal" else fill.lightened(0.06), 22, 0, 0)
		box.shadow_color = Color(0, 0, 0, 0.35)
		box.shadow_size = 10
		b.add_theme_stylebox_override(st, box)
	b.pressed.connect(on_press)
	ScreenKit.press_feedback(b)
	return b


## Cabeçalho do bloco: quadrado colorido com ícone + título curto.
func _tile_head(t: Control, icon_name: String, col: Color, text: String, ink := false) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sq := PanelContainer.new()
	sq.add_theme_stylebox_override("panel", UiStyle.g_box(col, 10, 6, 6))
	sq.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sq.add_child(ScreenKit.icon(icon_name, 18, UiStyle.G_INK if ink else Color.WHITE))
	h.add_child(sq)
	if text != "":
		var l := UiStyle.g_label(text, 15, UiStyle.G_TEXT, "black")
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
		l.add_theme_constant_override("shadow_offset_y", 2)
		h.add_child(l)
	h.position = Vector2(16, 14)
	t.add_child(h)


func _pill_chip(text: String, icon_name := "", fill := Color(0.06, 0.07, 0.09, 0.78), fg := UiStyle.G_TEXT) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(fill, 15, 12, 4))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	if icon_name != "":
		h.add_child(ScreenKit.icon(icon_name, 16, fg))
	h.add_child(UiStyle.g_label(text, 13, fg, "black"))
	p.add_child(h)
	return p


func _shade(t: Control, from := 0.3) -> void:
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(0.03, 0.04, 0.055, 0.0), Color(0.03, 0.04, 0.055, 0.92)])
	grad.offsets = PackedFloat32Array([from, 1.0])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_to = Vector2(0, 1)
	var tr := TextureRect.new()
	tr.texture = gt
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.add_child(tr)


## Característica do carro (reta, lentas, rápidas, confiabilidade) como na tela de peças.
static func car_trait(c: Campaign, key: String, car := 0) -> float:
	var traits: Dictionary = c.team().get("car_traits", {})
	if key == "rel":
		return float(traits.get("rel", CarParts.REL_NEUTRAL)) + c.my_parts().known_trait_delta(car, "rel")
	return c.base_rating + c.dev.rating_bonus() + float(traits.get(key, 0.0)) + c.my_parts().known_trait_delta(car, key)


## "GP da Grã-Bretanha" -> "Grã-Bretanha" (cartões com bandeira).
static func gp_short(name: String) -> String:
	var parts := name.split(" ")
	if parts.size() >= 3 and parts[0] == "GP" and parts[1].begins_with("d"):
		return " ".join(parts.slice(2))
	return name


static func track_art(circuit_id: String) -> Texture2D:
	var path := "res://assets/tracks/%s.jpg" % circuit_id
	return load(path) if ResourceLoader.exists(path) else null


static func flag_rect(country_code: String, h: int) -> TextureRect:
	var path := "res://assets/flags/%s.svg" % country_code
	var f := TextureRect.new()
	if ResourceLoader.exists(path):
		f.texture = load(path)
	f.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	f.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	f.custom_minimum_size = Vector2(roundi(h * 4.0 / 3.0), h)
	f.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	f.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return f


func _gp_tile(r: Rect2) -> Control:
	var rd := campaign.next_round()
	var circuit := GameData.circuit(rd["id"])
	var t := _tile(r, Session.open_campaign_calendar)
	var art := TextureRect.new()
	art.texture = track_art(rd["id"])
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.add_child(art)
	_shade(t, 0.25)
	_tile_head(t, "flag", UiStyle.RED, "PRÓXIMO GP")
	var days := campaign.days_to_event()
	var ready := campaign.event_ready()
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	if not ready:
		var one := Button.new()
		one.text = "+1 DIA"
		one.focus_mode = Control.FOCUS_NONE
		one.custom_minimum_size = Vector2(0, 32)
		for st: String in ["normal", "hover", "pressed", "hover_pressed"]:
			one.add_theme_stylebox_override(st, UiStyle.g_box(Color(0.06, 0.07, 0.09, 0.78), 16, 12, 0))
		one.add_theme_font_size_override("font_size", UiStyle.fs(13))
		one.pressed.connect(_on_one_day)
		top.add_child(one)
	top.add_child(_pill_chip("HOJE" if ready else "%d DIA%s" % [days, "" if days == 1 else "S"], "timer", UiStyle.RED, Color.WHITE))
	top.mouse_filter = Control.MOUSE_FILTER_PASS
	ScreenKit.place(top, t, Control.PRESET_TOP_RIGHT, Vector2(-16, 12))
	# nome com a bandeira + data, chuva e sprint
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 6)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var nh := HBoxContainer.new()
	nh.add_theme_constant_override("separation", 12)
	nh.add_child(flag_rect(String(circuit.get("country_code", "")), 30))
	var nm := UiStyle.g_label(gp_short(String(rd["grand_prix"])).to_upper(), 34 if gp_short(String(rd["grand_prix"])).length() <= 14 else 28, UiStyle.G_TEXT, "black")
	nm.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	nm.add_theme_constant_override("shadow_offset_y", 2)
	nh.add_child(nm)
	info.add_child(nh)
	var ch := HBoxContainer.new()
	ch.add_theme_constant_override("separation", 6)
	ch.add_child(_pill_chip(campaign.date_text(Campaign._day_of(String(rd["date"]))).get_slice(", ", 1).to_lower(), "cal"))
	ch.add_child(_pill_chip("%d%%" % roundi(float(circuit.get("rain_probability", 0)) * 100), "rain"))
	if campaign.regs.is_sprint(rd["id"]):
		ch.add_child(_pill_chip("SPRINT", "", UiStyle.SECTION["staff"], Color.WHITE))
	info.add_child(ch)
	info.position = Vector2(20, r.size.y - 104)
	t.add_child(info)
	# como o carro se sai aqui: afinidade e ritmo estimado
	var fit := campaign.track_fit(rd["id"])
	var rank := campaign.track_rank(rd["id"])
	var fit_col := UiStyle.G_UP if fit > 0.35 else (UiStyle.G_DOWN if fit < -0.35 else Color("#F5C542"))
	var rings := HBoxContainer.new()
	rings.add_theme_constant_override("separation", 8)
	rings.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rings.add_child(RingGauge.make((fit + 1.0) / 2.0, 58, fit_col, "", "", "car"))
	rings.add_child(RingGauge.make(1.0 - float(rank - 1) / 5.0, 58, UiStyle.G_UP if rank <= 2 else UiStyle.SECTION["drivers"], "P%d" % (rank * 2 - 1)))
	rings.position = Vector2(r.size.x - 20 - 124, r.size.y - 78)
	t.add_child(rings)
	return t


func _drivers_tile(r: Rect2, color: Color) -> Control:
	var t := _tile(r, Session.open_campaign_team)
	var ids := campaign.team_driver_ids(campaign.player_team)
	var rows := campaign.driver_standings()
	var half := r.size.x / maxf(ids.size(), 1)
	for i in ids.size():
		var d := _driver(ids[i])
		var col := Control.new()
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.position = Vector2(i * half, 0)
		col.size = Vector2(half, r.size.y)
		var bg := ColorRect.new()
		bg.color = Color(color, 0.16 if i == 0 else 0.1)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(bg)
		var num := UiStyle.g_label(str(int(d.get("number", 0))), 120, Color(color, 0.32), "black")
		num.position = Vector2(8, 26)
		col.add_child(num)
		var av := DriverPhotos.make_avatar(d, color, 96)
		av.position = Vector2(half / 2.0 - 48, 70)
		col.add_child(av)
		var nm := String(d.get("name", ""))
		var sl := UiStyle.g_label(nm.get_slice(" ", nm.get_slice_count(" ") - 1).to_upper(), 21, UiStyle.G_TEXT, "black")
		sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sl.position = Vector2(0, 180)
		sl.size = Vector2(half, 30)
		col.add_child(sl)
		var pos := 0
		for k in rows.size():
			if rows[k][0] == ids[i]:
				pos = k + 1
		var ring := RingGauge.make(1.0 - float(pos - 1) / maxf(rows.size() - 1, 1.0), 64, UiStyle.SECTION["drivers"], "%dº" % pos, str(int(campaign.driver_points.get(ids[i], 0))))
		ring.position = Vector2(half / 2.0 - 32, 222)
		col.add_child(ring)
		t.add_child(col)
		if i > 0:
			var sep := ColorRect.new()
			sep.color = Color(0, 0, 0, 0.35)
			sep.position = Vector2(i * half - 2, 0)
			sep.size = Vector2(4, r.size.y)
			sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
			t.add_child(sep)
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.SECTION["drivers"], 10, 6, 6))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(ScreenKit.icon("users", 18, Color.WHITE))
	badge.position = Vector2(r.size.x - 48, 14)
	t.add_child(badge)
	return t


func _car_tile(r: Rect2) -> Control:
	var t := _tile(r, Session.open_campaign_car, Color("#1d1813"))
	_tile_head(t, "car", UiStyle.SECTION["car"], "CARRO", true)
	ScreenKit.place(_pill_chip("%d/%d" % [campaign.dev.busy(), campaign.dev.slots()], "factory", Color(1, 1, 1, 0.1)), t, Control.PRESET_TOP_RIGHT, Vector2(-16, 14))
	var car := TextureRect.new()
	car.texture = CarArt.car_texture(campaign.team())
	car.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	car.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	car.position = Vector2(24, 44)
	car.size = Vector2(r.size.x - 48, r.size.y - 124)
	car.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.add_child(car)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for k: Array in [["straight", "#F5C542", "t_straight"], ["slow", "#ff6a5a", "t_slow"], ["fast", "#5c93ea", "t_fast"], ["rel", "#2FD38A", "t_rel"]]:
		var v := car_trait(campaign, k[0])
		var cell := HBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.alignment = BoxContainer.ALIGNMENT_CENTER
		cell.add_theme_constant_override("separation", 6)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(ScreenKit.icon(k[2], 18, Color(k[1])))
		cell.add_child(RingGauge.make(clampf(v / 100.0, 0.0, 1.0), 56, Color(k[1]), str(roundi(v))))
		row.add_child(cell)
	row.position = Vector2(12, r.size.y - 70)
	row.size = Vector2(r.size.x - 24, 60)
	t.add_child(row)
	return t


func _hq_tile(r: Rect2) -> Control:
	var t := _tile(r, Session.open_campaign_hq, Color("#13201b"))
	var campus := HqCampus.new()
	campus.colors = HqCampus.default_colors()
	campus.position = Vector2(0, 30)
	campus.size = Vector2(r.size.x, r.size.y - 30)
	campus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	campus.fit(campus.size)
	t.add_child(campus)
	_tile_head(t, "hq", UiStyle.SECTION["hq"], "SEDE", true)
	var busy := 0
	for sid: String in CarDevelopment.STRUCT_ORDER:
		if not campaign.dev.work_of(sid).is_empty():
			busy += 1
	var chip := _pill_chip("%d OBRA%s" % [busy, "" if busy == 1 else "S"] if busy > 0 else "LIVRE", "up", UiStyle.SECTION["hq"], UiStyle.G_INK)
	ScreenKit.place(chip, t, Control.PRESET_TOP_RIGHT, Vector2(-16, 14))
	return t


func _table_tile(r: Rect2) -> Control:
	var t := _tile(r, Session.open_campaign_standings)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.add_child(ScreenKit.icon("trophy", 20, UiStyle.SECTION["champ"]))
	h.add_child(UiStyle.g_label("TABELA", 15, UiStyle.G_TEXT, "black"))
	v.add_child(h)
	var rows := campaign.team_standings()
	for i in mini(rows.size(), 7):
		var tid: String = rows[i][0]
		var mine := tid == campaign.player_team
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.08) if mine else Color(0, 0, 0, 0), 10, 6, 2))
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rh := HBoxContainer.new()
		rh.add_theme_constant_override("separation", 8)
		var n := UiStyle.g_label(str(i + 1), 16, UiStyle.G_TEXT, "black")
		n.custom_minimum_size = Vector2(16, 0)
		rh.add_child(n)
		var bar := ColorRect.new()
		bar.color = UiStyle.team_color(tid)
		bar.custom_minimum_size = Vector2(6, 28)
		rh.add_child(bar)
		rh.add_child(TeamEmblems.make_rect(tid, 28))
		var pts := UiStyle.g_label(str(rows[i][1]), 15, UiStyle.G_TEXT, "black")
		pts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rh.add_child(pts)
		p.add_child(rh)
		v.add_child(p)
	v.position = Vector2(14, 14)
	v.size = Vector2(r.size.x - 28, r.size.y - 28)
	t.add_child(v)
	return t


func _board_tile(r: Rect2) -> Control:
	var t := _tile(r, Session.open_campaign_council)
	var goal := campaign.season_goal()
	var pos := campaign.team_position(campaign.player_team)
	var ok := pos <= goal
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 8)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ring := RingGauge.make(clampf(float(goal) / float(maxi(pos, 1)), 0.05, 1.0), 104, UiStyle.SECTION["board"] if ok else UiStyle.G_DOWN, "%dº" % pos, "meta %dº" % goal, "", 9.0)
	ring.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ring)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 6)
	h.add_child(ScreenKit.icon("smile", 18, UiStyle.G_UP if campaign.trust >= 40.0 else UiStyle.G_DOWN))
	h.add_child(UiStyle.g_label(campaign.trust_label().to_upper(), 13, UiStyle.G_TEXT, "black"))
	v.add_child(h)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.add_child(v)
	return t


func _chip(caption: String, value: String, size: int) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_SURFACE_HOVER, 26, 18, 7))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -3)
	v.add_child(UiStyle.g_caption(caption))
	var l := UiStyle.g_label(value, size, UiStyle.G_TEXT, "black")
	v.add_child(l)
	p.add_child(v)
	p.set_meta("value", l)
	return p


## Próximo GP (mockup v15-1): bandeira do país atrás do nome, o que a pista pede (reta/lentas/rápidas), como o seu
## carro se sai neste perfil, a ação principal ("avançar com preparação recomendada") e as próximas pistas.
func _event_card() -> Control:
	var r := campaign.next_round()
	var circuit := GameData.circuit(r["id"])
	var prof := Campaign.track_profile(r["id"])
	var card := PanelContainer.new()
	card.clip_contents = true
	card.add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.06), 22, 0, 0))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	card.add_child(v)
	_hero = card
	# faixa do título com a bandeira
	var band := PanelContainer.new()
	band.clip_contents = true
	band.add_theme_stylebox_override("panel", UiStyle.g_box(Color(0, 0, 0, 0.25), 0, 0, 0))
	var path := "res://assets/flags/%s.svg" % String(circuit.get("country_code", ""))
	if ResourceLoader.exists(path):
		var flag := TextureRect.new()
		flag.texture = load(path)
		flag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		flag.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		flag.modulate = Color(1, 1, 1, 0.32)
		flag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		band.add_child(flag)
	var bt := VBoxContainer.new()
	bt.add_theme_constant_override("separation", 0)
	var days := campaign.days_to_event()
	var ready := campaign.event_ready()
	bt.add_child(_shadowed(UiStyle.g_caption("Próximo GP · rodada %d de %d · %s" % [int(r["round"]), Campaign.calendar().size(),
		"começa agora" if ready else "em %d dia%s" % [days, "" if days == 1 else "s"]], UiStyle.G_TEXT)))
	bt.add_child(_shadowed(UiStyle.g_label(String(r["grand_prix"]).to_upper(), 34, UiStyle.G_TEXT, "black")))
	var weekend := " · sprint" if campaign.regs.is_sprint(r["id"]) else ""
	bt.add_child(_shadowed(UiStyle.g_label("%s · %s · chuva %d%%%s" % [circuit.get("city", circuit.get("short_name", "")),
		campaign.date_text(Campaign._day_of(String(r["date"]))).to_lower(), roundi(float(circuit.get("rain_probability", 0)) * 100), weekend], 14, UiStyle.G_TEXT)))
	var bmar := MarginContainer.new()
	for k: String in ["left", "right"]:
		bmar.add_theme_constant_override("margin_" + k, 22)
	bmar.add_theme_constant_override("margin_top", 14)
	bmar.add_theme_constant_override("margin_bottom", 14)
	bmar.add_child(bt)
	band.add_child(bmar)
	v.add_child(band)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	var bm := MarginContainer.new()
	for k: String in ["left", "right"]:
		bm.add_theme_constant_override("margin_" + k, 22)
	bm.add_theme_constant_override("margin_top", 10)
	bm.add_theme_constant_override("margin_bottom", 14)
	bm.add_child(body)
	v.add_child(bm)
	# o que a pista pede
	var need := HBoxContainer.new()
	need.add_theme_constant_override("separation", 10)
	var cap := UiStyle.g_caption("O que a pista pede")
	cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	need.add_child(cap)
	var trk := TrackOutline.new()
	trk.line_color = UiStyle.G_TEXT_2
	trk.line_width = 3.0
	trk.pad = 4.0
	trk.custom_minimum_size = Vector2(46, 46)
	trk.set_circuit(circuit)
	need.add_child(trk)
	body.add_child(need)
	var top := maxf(maxf(float(prof["straight"]), float(prof["slow"])), float(prof["fast"]))
	for row: Array in [["slow", "t_slow", "#ff6a5a", "Curvas lentas"], ["fast", "t_fast", "#5c93ea", "Curvas rápidas"], ["straight", "t_straight", "#ffd24a", "Reta"]]:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		h.add_child(ScreenKit.icon(row[1], 18, Color(row[2])))
		var l := UiStyle.g_label(row[3], 14, UiStyle.G_TEXT, "bold")
		l.custom_minimum_size = Vector2(118, 0)
		h.add_child(l)
		var bar := _Bar.new()
		bar.value = float(prof[row[0]]) / maxf(top, 0.01)
		bar.color = Color(row[2])
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(bar)
		var n := UiStyle.g_label("%d%%" % roundi(float(prof[row[0]]) * 100.0), 15, UiStyle.G_TEXT, "black")
		n.custom_minimum_size = Vector2(46, 0)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h.add_child(n)
		body.add_child(h)
	# seu carro neste perfil
	body.add_child(UiStyle.g_caption("Seu carro nesta pista"))
	var facts := HBoxContainer.new()
	facts.add_theme_constant_override("separation", 8)
	var rank := campaign.track_rank(r["id"])
	facts.add_child(_fact("P%d–P%d" % [rank * 2 - 1, rank * 2], "ritmo estimado"))
	var fit := campaign.track_fit(r["id"])
	facts.add_child(_fact("forte" if fit > 0.35 else ("fraca" if fit < -0.35 else "neutra"), "afinidade", Color("#7fe0b1") if fit > 0.35 else (Color("#ff8a80") if fit < -0.35 else UiStyle.G_TEXT)))
	var plan := campaign.my_parts().prepare_plan(prof)
	facts.add_child(_fact("%d troca%s" % [plan.size(), "" if plan.size() == 1 else "s"] if not plan.is_empty() else "Pronto", "preparação"))
	body.add_child(facts)
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", 8)
	var go := CutButton.new()
	go.text = ("JOGAR" if ready else "AVANÇAR") + (" COM PREPARAÇÃO" if not plan.is_empty() else (" O FIM DE SEMANA" if ready else " ATÉ O GP"))
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.add_theme_font_size_override("font_size", UiStyle.fs(17))
	go.pressed.connect(_on_advance)
	acts.add_child(go)
	if not ready:
		var one := ScreenKit.light_button("+1 DIA")
		one.pressed.connect(_on_one_day)
		acts.add_child(one)
	body.add_child(acts)
	if not plan.is_empty():
		var parts_txt: Array[String] = []
		var ids := campaign.team_driver_ids(campaign.player_team)
		for p: Dictionary in plan:
			var code := Campaign.driver_code(String(_driver(ids[int(p["car"])]).get("name", ""))) if int(p["car"]) < ids.size() else "?"
			parts_txt.append("%s %s no %s" % [String(CarParts.part(p["part"])["name"]).to_lower(), campaign.my_parts().spec(p["part"], int(p["spec"]))["v"], code])
		var rec := UiStyle.g_label("Recomendado: " + ", ".join(parts_txt) + ". Revise em Carro.", 12, UiStyle.G_TEXT_2)
		rec.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(rec)
	# próximas pistas
	var cal := Campaign.calendar()
	var after: Array = []
	for i in range(campaign.round + 1, mini(campaign.round + 3, cal.size())):
		after.append(cal[i])
	if not after.is_empty():
		body.add_child(UiStyle.g_caption("Depois"))
		for a: Dictionary in after:
			var h := HBoxContainer.new()
			var c2 := GameData.circuit(a["id"])
			var l := UiStyle.g_label("%s · %s" % [campaign.date_text(Campaign._day_of(String(a["date"]))).get_slice(", ", 1).to_lower(), c2.get("short_name", a["id"])], 13, UiStyle.G_TEXT, "bold")
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(l)
			var f := campaign.track_fit(a["id"])
			h.add_child(UiStyle.g_label("ponto forte" if f > 0.35 else ("ponto fraco" if f < -0.35 else "neutro"), 13,
				Color("#7fe0b1") if f > 0.35 else (Color("#ff8a80") if f < -0.35 else UiStyle.G_TEXT), "black"))
			body.add_child(h)
	return card


func _shadowed(l: Label) -> Label:
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l


func _fact(value: String, caption: String, col: Color = UiStyle.G_TEXT) -> PanelContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", UiStyle.g_box(Color(0, 0, 0, 0.3), 14, 12, 8))
	var fv := VBoxContainer.new()
	fv.add_theme_constant_override("separation", -3)
	fv.add_child(UiStyle.g_label(value, 20, col, "black"))
	fv.add_child(UiStyle.g_label(caption, 11, UiStyle.G_TEXT_2, "bold"))
	p.add_child(fv)
	return p


func _driver(id: String) -> Dictionary:
	for d: Dictionary in campaign.drivers():
		if d["id"] == id:
			return d
	return {}


func _on_advance() -> void:
	var r := campaign.next_round()
	if not r.is_empty():  # preparação recomendada: as melhores peças disponíveis para esta pista
		campaign.my_parts().auto_prepare(Campaign.track_profile(r["id"]))
		campaign.refresh_rating()
	if campaign.event_ready():
		Session.play_campaign_round()
		return
	campaign.advance_to_event()
	campaign.save()
	Session.open_campaign_hub()


func _on_one_day() -> void:
	campaign.advance_days(1)
	campaign.save()
	Session.open_campaign_hub()


func _objective_card(color: Color) -> Control:
	var card := ScreenKit.g_card(UiStyle.G_SURFACE, 20, 20, 14)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	card.add_child(v)
	v.add_child(UiStyle.g_caption("Meta da diretoria"))
	var goal := campaign.season_goal()
	var total := campaign.teams().size()
	var pos := campaign.team_position(campaign.player_team)
	var gl := UiStyle.g_label("Top %d dos construtores" % goal, 18, UiStyle.G_TEXT, "black")
	gl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(gl)
	# barra: posição atual dentro da escala (1º ... último); marca = meta
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = float(total - 1)
	bar.value = maxf(float(total - pos), 0.4)  # (último colocado: sobra um traço, a barra não parece quebrada)
	bar.custom_minimum_size = Vector2(0, 12)
	bar.add_theme_stylebox_override("background", UiStyle.g_box(Color(1, 1, 1, 0.1), 6, 0, 0))
	bar.add_theme_stylebox_override("fill", UiStyle.g_box(color.lightened(0.15) if pos <= goal else Color("#8f98a7"), 6, 0, 0))
	v.add_child(bar)
	var marks := HBoxContainer.new()
	var l := UiStyle.g_label("Hoje: %dº" % pos, 13, UiStyle.G_TEXT_2)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	marks.add_child(l)
	marks.add_child(UiStyle.g_label("Meta: %dº" % goal, 13, UiStyle.G_TEXT_2))
	v.add_child(marks)
	var pat := HBoxContainer.new()
	pat.add_theme_constant_override("separation", UiStyle.SP_M)
	var pl := UiStyle.g_caption("Confiança")
	pat.add_child(pl)
	var tb := ProgressBar.new()
	tb.show_percentage = false
	tb.max_value = 100.0
	tb.value = campaign.trust
	tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tb.custom_minimum_size = Vector2(0, 10)
	tb.add_theme_stylebox_override("background", UiStyle.g_box(Color(1, 1, 1, 0.1), 5, 0, 0))
	tb.add_theme_stylebox_override("fill", UiStyle.g_box(Color("#5c93ea") if campaign.trust >= 40.0 else Color("#ffb4a8"), 5, 0, 0))
	pat.add_child(tb)
	pat.add_child(UiStyle.g_label(campaign.trust_label(), 15, UiStyle.G_TEXT, "black"))
	v.add_child(pat)
	return card


func _finance_card() -> Control:
	var card := ScreenKit.g_card(UiStyle.G_SURFACE, 20, 20, 12)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 34)
	card.add_child(h)
	for f: Array in [["Orçamento", "US$ %d mi" % int(campaign.budget_musd)], ["Custo por rodada", "US$ %.1f mi" % campaign.cost_per_race()],
			["Patrocínio por rodada", "US$ %.1f mi" % campaign.sponsor_per_race()]]:
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", -2)
		v.add_child(UiStyle.g_caption(f[0]))
		v.add_child(UiStyle.g_label(f[1], 20, UiStyle.G_TEXT, "black"))
		h.add_child(v)
	if campaign.dev.news.size() > 0:  # última notícia do desenvolvimento do carro
		var wrap := VBoxContainer.new()
		wrap.add_theme_constant_override("separation", 4)
		card.remove_child(h)
		card.add_child(wrap)
		wrap.add_child(h)
		var n := UiStyle.g_label("P&D · " + String(campaign.dev.news[0]), 13, Color("#c3c9d3"))
		n.clip_text = true
		wrap.add_child(n)
	return card


func _standing_row(pos: int, team_id: String, pts: int, mine: bool) -> Control:
	var p := PanelContainer.new()
	var fill := Color(UiStyle.team_color_from(campaign.teams(), team_id), 0.3) if mine else Color(0, 0, 0, 0)
	var st := UiStyle.g_box(fill, 10, 6, 6)
	if not mine:
		st.border_color = Color(1, 1, 1, 0.07)
		st.border_width_bottom = 1
	p.add_theme_stylebox_override("panel", st)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)
	var n := UiStyle.g_label(str(pos), 15, UiStyle.G_TEXT_2, "black")
	n.custom_minimum_size = Vector2(24, 0)
	h.add_child(n)
	h.add_child(TeamEmblems.make_rect(team_id, 20))
	var name := UiStyle.g_label(String(GameData.team_by_id(campaign.teams(), team_id).get("name", team_id)), 16, UiStyle.G_TEXT, "bold")
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.clip_text = true
	h.add_child(name)
	var pl := UiStyle.g_label(str(pts), 17, UiStyle.G_TEXT, "black")
	pl.custom_minimum_size = Vector2(44, 0)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(pl)
	return p


# --- assuntos (até 3): decisões das peças, vaga de projeto livre, notícias --------------------------

func _topics() -> Array:
	var out: Array = []
	var cp := campaign.my_parts()
	var ids := campaign.team_driver_ids(campaign.player_team)
	var codes: Array = ids.map(func(id: String) -> String: return Campaign.driver_code(String(_driver(id).get("name", ""))))
	for pid: String in CarParts.part_ids():
		var latest := cp.latest_spec(pid)
		var s := cp.spec(pid, latest)
		var st := cp.stock(pid, latest)
		if latest == 0 or st.is_empty() or (bool(s["revealed"]) and s["outcome"] == "bad"):
			continue
		var missing: Array = []
		for car in mini(2, ids.size()):
			if int(cp.unit_on(pid, car).get("spec", 0)) < latest:
				missing.append(car)
		if missing.is_empty():
			continue
		var name := "%s %s" % [CarParts.part(pid)["name"], s["v"]]
		var acts: Array = []
		for car: int in missing:
			acts.append(["No " + String(codes[car]), _install_action.bind(int(st[0]["uid"]), car)])
		out.append({"kind": "dec", "title": "%s pronta: %d no estoque" % [name, st.size()], "link": "Carro",
			"text": "Ainda não testada na pista: o resultado real aparece depois da primeira corrida.", "actions": acts.slice(0, mini(st.size() + 1, 2))})
	for pid: String in CarParts.part_ids():
		for car in mini(2, ids.size()):
			var u := cp.unit_on(pid, car)
			if float(u.get("wear", 0.0)) >= CarParts.WEAR_SOFT:
				out.append({"kind": "dec", "title": "%s gasta no carro de %s (%d%%)" % [CarParts.part(pid)["name"], codes[car], roundi(100.0 - float(u["wear"]))],
					"text": "Acima de %d%% de desgaste a peça perde rendimento. Troque por uma reserva ou fabrique outra." % roundi(CarParts.WEAR_SOFT), "link": "Carro", "actions": []})
	if campaign.dev.busy() < campaign.dev.slots():
		out.append({"kind": "news", "title": "Vaga de projeto livre (%d de %d)" % [campaign.dev.busy(), campaign.dev.slots()],
			"text": "Pesquise uma peça nova ou um nó da árvore de P&D.", "link": "Carro", "actions": []})
	for n: Dictionary in campaign.events.news.slice(0, 2):
		out.append({"kind": "news", "title": String(n.get("title", "")).capitalize() if String(n.get("title", "")) == String(n.get("title", "")).to_upper() else n.get("title", ""),
			"text": n.get("text", ""), "link": "Notícias", "actions": []})
	return out.slice(0, 3)


## Depois do último aviso das peças, recarrega a sede (assuntos e fábrica mudam com as encomendas).
func _after_parts_dialog() -> void:
	var cp := campaign.my_parts()
	if cp.done_research.is_empty() and cp.reveals.is_empty():
		Session.open_campaign_hub.call_deferred()


## Lançamento do carro novo (mockup v18-3): a pintura, a nota da crítica e o que rendeu.
func _show_launch() -> void:
	var l: Dictionary = campaign.livery.launch
	var sh := ScreenKit.sheet("Lançamento do carro %d" % int(l.get("season", campaign.season)), 900)
	var body: VBoxContainer = sh["body"]
	var tex := TextureRect.new()
	tex.texture = Livery.car_texture(campaign.livery.main)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.custom_minimum_size = Vector2(0, 190)
	body.add_child(tex)
	body.add_child(UiStyle.g_label("%s %d É REVELADO" % [String(campaign.team()["name"]).to_upper(), int(l.get("season", campaign.season))], 30, UiStyle.G_TEXT, "black"))
	var stars := HBoxContainer.new()
	stars.add_theme_constant_override("separation", 4)
	for i in 5:
		stars.add_child(UiStyle.g_label("★", 26, Color("#ffd24a") if i < int(l.get("stars", 3)) else Color("#4b5260"), "black"))
	stars.add_child(UiStyle.g_label("  nota da crítica %d de 5" % int(l.get("stars", 3)), 14, Color("#c3c9d3"), "bold"))
	body.add_child(stars)
	var q := HBoxContainer.new()
	q.add_theme_constant_override("separation", 10)
	var quotes: Array = l.get("quotes", [])
	for i in quotes.size():
		var p := PanelContainer.new()
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.06), 14, 12, 10))
		var v := VBoxContainer.new()
		v.add_child(UiStyle.g_caption("Revista do paddock" if i == 0 else "Torcida"))
		var t := UiStyle.g_label(String(quotes[i]), 13, Color("#c3c9d3"), "bold")
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(t)
		p.add_child(v)
		q.add_child(p)
	body.add_child(q)
	var gains := HBoxContainer.new()
	gains.add_theme_constant_override("separation", 10)
	var bonus := float(l.get("bonus", 0.0))
	var trust := int(l.get("trust", 0))
	for g: Array in [["US$ %s mi" % ("%.1f" % bonus).replace(".", ","), "bônus das marcas", bonus > 0.0], ["%+d" % trust, "confiança da diretoria", trust >= 0]]:
		var p := PanelContainer.new()
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.add_theme_stylebox_override("panel", UiStyle.g_box(Color(0.22, 0.83, 0.42, 0.12) if g[2] else Color(1, 0.4, 0.4, 0.12), 14, 14, 10))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", -3)
		v.add_child(UiStyle.g_label(g[0], 20, Color("#7fe0b1") if g[2] else Color("#ff8a80"), "black"))
		v.add_child(UiStyle.g_label(g[1], 12, UiStyle.G_TEXT_2, "bold"))
		p.add_child(v)
		gains.add_child(p)
	body.add_child(gains)
	var ok := CutButton.new()
	ok.text = "CONTINUAR"
	ok.size_flags_horizontal = Control.SIZE_SHRINK_END
	ok.custom_minimum_size = Vector2(240, 56)
	ok.pressed.connect(func() -> void:
		campaign.livery.launch = {}
		campaign.save()
		sh["root"].queue_free())
	body.add_child(ok)
	_layer.add_child(sh["root"])


func _install_action(uid: int, car: int) -> void:
	campaign.my_parts().install(uid, car)
	campaign.refresh_rating()
	campaign.save()
	Session.open_campaign_hub()


func _fill_topics(col: VBoxContainer) -> void:
	var topics := _topics()
	var card := ScreenKit.g_card(Color(1, 1, 1, 0.06), 22, 16, 14)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	card.add_child(v)
	v.add_child(UiStyle.g_caption("Assuntos · %d" % topics.size()))
	if topics.is_empty():
		var l := UiStyle.g_label("Tudo em ordem. Nada pede a sua atenção antes do próximo GP.", 14, UiStyle.G_TEXT_2)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
	for t: Dictionary in topics:
		v.add_child(_topic(t))
	col.add_child(card)


func _topic(t: Dictionary) -> Control:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	var st := UiStyle.g_box(Color(1, 1, 1, 0.06), 16, 14, 12)
	for k: String in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		b.add_theme_stylebox_override(k, st)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", st)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	box.add_child(v)
	var head := HBoxContainer.new()
	var dec: bool = t["kind"] == "dec"
	var tag := PanelContainer.new()
	tag.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.RED if dec else Color(1, 1, 1, 0.14), 7, 8, 2))
	tag.add_child(UiStyle.g_label("DECISÃO" if dec else "NOTÍCIA", 10, Color.WHITE if dec else UiStyle.G_TEXT_2, "black"))
	head.add_child(tag)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	var link := Button.new()
	link.flat = true
	link.focus_mode = Control.FOCUS_NONE
	link.text = String(t["link"]) + "  ›"
	link.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MIN - 8)
	link.add_theme_font_size_override("font_size", UiStyle.fs(12))
	link.add_theme_color_override("font_color", UiStyle.G_TEXT_2)
	link.pressed.connect(Session.open_campaign_car if t["link"] == "Carro" else _open_news)
	head.add_child(link)
	v.add_child(head)
	var title := UiStyle.g_label(t["title"], 16, UiStyle.G_TEXT, "black")
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(title)
	var tx := UiStyle.g_label(t["text"], 13, UiStyle.G_TEXT_2)
	tx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(tx)
	if not (t["actions"] as Array).is_empty():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var first := true
		for a: Array in t["actions"]:
			var ab := ScreenKit.light_button(a[0]) if first else ScreenKit.glass_pill_button(a[0])
			ab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ab.pressed.connect(a[1])
			row.add_child(ab)
			first = false
		v.add_child(row)
	return box


# --- equipe e fábrica --------------------------------------------------------------------------------

func _team_card(color: Color) -> Control:
	var card := ScreenKit.g_card(Color(1, 1, 1, 0.06), 22, 16, 14)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	v.add_child(UiStyle.g_caption("Equipe"))
	var pos := campaign.team_position(campaign.player_team)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.add_child(UiStyle.g_label("%dº" % pos, 30, UiStyle.G_TEXT, "black"))
	var l := UiStyle.g_label("construtores · %d pts" % int(campaign.team_points.get(campaign.player_team, 0)), 13, UiStyle.G_TEXT_2, "bold")
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	v.add_child(h)
	var rows := campaign.driver_standings()
	var last: Array = campaign.history[campaign.history.size() - 1]["results"] if not campaign.history.is_empty() else []
	for id: String in campaign.team_driver_ids(campaign.player_team):
		var d := _driver(id)
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 10)
		r.add_child(DriverPhotos.make_avatar(d, color, 44))
		var dv := VBoxContainer.new()
		dv.add_theme_constant_override("separation", -3)
		dv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nm := String(d.get("name", ""))
		dv.add_child(UiStyle.g_label(nm.get_slice(" ", nm.get_slice_count(" ") - 1), 16, UiStyle.G_TEXT, "black"))
		var dpos := 0
		for i in rows.size():
			if rows[i][0] == id:
				dpos = i + 1
		dv.add_child(UiStyle.g_label("%dº · %d pts" % [dpos, int(campaign.driver_points.get(id, 0))], 12, UiStyle.G_TEXT_2, "bold"))
		r.add_child(dv)
		var fin := last.find(id)
		if fin >= 0:
			r.add_child(UiStyle.g_label("P%d" % (fin + 1), 20, UiStyle.RED, "black"))
		v.add_child(r)
	return card


func _factory_card() -> Control:
	var card := ScreenKit.g_card(Color(1, 1, 1, 0.06), 22, 16, 12)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	card.add_child(v)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.add_child(ScreenKit.icon("factory", 18, UiStyle.G_TEXT_3))
	h.add_child(UiStyle.g_caption("Fábrica"))
	v.add_child(h)
	v.add_child(UiStyle.g_label("%d de %d projetos" % [campaign.dev.busy(), campaign.dev.slots()], 18, UiStyle.G_TEXT, "black"))
	var cp := campaign.my_parts()
	var items: Array[String] = []
	for r: Dictionary in cp.research:
		items.append("%s (%d d)" % [String(CarParts.part(r["part"])["name"]).to_lower(), int(r["days_left"])])
	for p: Dictionary in campaign.dev.projects:
		var info := CarDevelopment.node_info(p["id"])
		if not info.is_empty():
			items.append("%s (%d d)" % [String(info["node"]["n"]).to_lower(), int(p["days_left"])])
	if not cp.queue.is_empty():
		items.append("%d peça%s na produção" % [cp.queue.size(), "" if cp.queue.size() == 1 else "s"])
	var l := UiStyle.g_label(" · ".join(items) if not items.is_empty() else "Nada em andamento.", 12, UiStyle.G_TEXT_2, "bold")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	return card


## Barra horizontal simples (0..1).
class _Bar:
	extends Control
	var value := 0.5
	var color := Color.WHITE

	func _init() -> void:
		custom_minimum_size = Vector2(0, 10)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_style_box(UiStyle.g_box(Color(1, 1, 1, 0.1), 5, 0, 0), Rect2(Vector2.ZERO, size))
		if value > 0.0:
			draw_style_box(UiStyle.g_box(color, 5, 0, 0), Rect2(Vector2.ZERO, Vector2(size.x * clampf(value, 0.02, 1.0), size.y)))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.go_to_title()


# --- eventos inesperados ------------------------------------------------------------------------

## Mostra, um de cada vez, os eventos que aconteceram desde a última visita (consequência já aplicada).
func _show_next_event() -> void:
	if campaign.events.unseen.is_empty() or not is_inside_tree():
		return
	var item: Dictionary = campaign.events.unseen.pop_back()  # a mais antiga primeiro
	var card := EventCard.new()
	card.setup(item)
	card.dismissed.connect(func() -> void:
		campaign.save()
		_show_next_event.call_deferred())
	_layer.add_child(card)


func _open_news() -> void:
	var sheet := NewsSheet.new()
	sheet.setup(campaign)
	sheet.closed.connect(func() -> void: campaign.events.unseen.clear())
	_layer.add_child(sheet)
