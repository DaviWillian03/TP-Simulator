extends Control
## Patrocínios — zonas do carro, contratos e ofertas (mockup v11-2). Cinco zonas com valor diferente; um
## patrocinador por zona. As marcas (só texto, sem logos) fazem ofertas todo mês conforme a influência:
## aceitar, pedir mais (uma vez, com risco de a marca desistir) ou deixar passar. Rescindir custa multa.

var campaign: Campaign
var sp: Sponsorship
var _layer: Control
var _zone := ""
var _hero: CarHero
var _pins: Dictionary = {}
var _right: VBoxContainer
var _toasts: ToastFeed
var _per_race: Label
var _cash: Label
var _summary: Label
var _pips: Control


func _ready() -> void:
	campaign = Session.campaign
	if campaign == null:
		Session.open_campaign.call_deferred()
		return
	sp = campaign.sponsors
	var team := campaign.team()
	var page := ScreenKit.garage_page(self, campaign.player_team)
	(page["backdrop"] as GarageBackdrop).set_glow(Color(team["color"]), 0.18)
	_layer = page["layer"]
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UiStyle.SP_L)
	var back := ScreenKit.round_button("back", 52, "Voltar à sede")
	back.pressed.connect(Session.open_campaign_hub)
	head.add_child(back)
	head.add_child(TeamEmblems.make_rect(campaign.player_team, 46))
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -2)
	titles.add_child(UiStyle.g_caption("%s · temporada %d" % [team["name"], campaign.season]))
	titles.add_child(UiStyle.g_label("PATROCÍNIOS", 26, UiStyle.G_TEXT, "black"))
	head.add_child(titles)
	ScreenKit.place(head, _layer, Control.PRESET_TOP_LEFT, Vector2(44, 20))
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", UiStyle.SP_M)
	var c1 := _chip("Patrocínio por corrida")
	_per_race = c1.get_meta("value")
	chips.add_child(c1)
	var c2 := _chip("Caixa")
	_cash = c2.get_meta("value")
	chips.add_child(c2)
	ScreenKit.place(chips, _layer, Control.PRESET_TOP_RIGHT, Vector2(-44, 26))
	ScreenKit.campaign_nav(_layer, "sponsors")

	var inf := ScreenKit.g_card(Color(1, 1, 1, 0.06), 22, 20, 12)
	var iv := VBoxContainer.new()
	iv.add_theme_constant_override("separation", 2)
	inf.add_child(iv)
	iv.add_child(UiStyle.g_caption("Influência"))
	var ir := HBoxContainer.new()
	ir.add_theme_constant_override("separation", 12)
	ir.add_child(UiStyle.g_label(str(campaign.dev.influence()), 34, UiStyle.G_TEXT, "black"))
	var im := VBoxContainer.new()
	im.alignment = BoxContainer.ALIGNMENT_CENTER
	im.add_theme_constant_override("separation", 3)
	_pips = InfluencePips.new()
	(_pips as InfluencePips).level = campaign.dev.influence()
	im.add_child(_pips)
	var inf_note := UiStyle.g_label("marcas até o nível %d · sobe com a fábrica" % campaign.dev.influence(), 12, UiStyle.G_TEXT_2, "bold")
	inf_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inf_note.custom_minimum_size = Vector2(180, 0)
	im.add_child(inf_note)
	ir.add_child(im)
	iv.add_child(ir)
	ScreenKit.place(inf, _layer, Control.PRESET_TOP_LEFT, Vector2(44, 150), Vector2(300, 96))
	var con := ScreenKit.g_card(Color(1, 1, 1, 0.06), 22, 20, 12)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 2)
	con.add_child(cv)
	cv.add_child(UiStyle.g_caption("Contratos"))
	_summary = UiStyle.g_label("", 14, Color("#c3c9d3"), "bold")
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cv.add_child(_summary)
	ScreenKit.place(con, _layer, Control.PRESET_TOP_LEFT, Vector2(356, 150), Vector2(260, 96))

	_hero = CarHero.new()
	_hero.custom_minimum_size = Vector2(572, 160)
	ScreenKit.place(_hero, _layer, Control.PRESET_TOP_LEFT, Vector2(44, 330), Vector2(572, 160))
	var first := 0
	for d: Dictionary in campaign.drivers():
		if d["team"] == campaign.player_team:
			first = int(d["number"])
			break
	var c2col := Color(team.get("color2", "#ffffff"))
	_hero.set_team(campaign.player_team, first, c2col if c2col.get_luminance() > 0.35 else Color.WHITE, team)
	for z: Dictionary in Sponsorship.zones():
		var pin := Button.new()
		pin.focus_mode = Control.FOCUS_NONE
		pin.custom_minimum_size = Vector2(34, 34)
		pin.add_theme_font_override("font", UiStyle.G_BLACK)
		pin.add_theme_font_size_override("font_size", UiStyle.fs(15))
		pin.pressed.connect(_on_zone.bind(z["id"]))
		_layer.add_child(pin)
		var pos: Array = z["pin"]
		pin.position = Vector2(44 + 572 * float(pos[0]) - 17, 330 + 160 * float(pos[1]) - 17)
		_pins[z["id"]] = pin
	_right = VBoxContainer.new()
	_right.add_theme_constant_override("separation", 6)
	ScreenKit.scroll_column(_right, _layer, Vector2(1280 - 44 - 596, 150), Vector2(596, 720 - 150 - 8))
	_toasts = ToastFeed.new()
	_toasts.custom_minimum_size = Vector2(420, 0)
	ScreenKit.place(_toasts, _layer, Control.PRESET_TOP_LEFT, Vector2(44, 520), Vector2(420, 0))
	var free := sp.free_zones()
	_zone = free[0] if not free.is_empty() else String(Sponsorship.zones()[0]["id"])
	_refresh()


func _chip(caption: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_SURFACE_HOVER, 26, 18, 7))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var cap := UiStyle.g_caption(caption)
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(cap)
	var v := UiStyle.g_label("", 17, UiStyle.G_TEXT, "black")
	h.add_child(v)
	p.add_child(h)
	p.set_meta("value", v)
	return p


func _money(v: float) -> String:
	return ("%.2f" % v).replace(".", ",")


func _refresh() -> void:
	_per_race.text = "US$ %s mi" % _money(sp.per_race_total())
	_cash.text = "US$ %d mi" % int(campaign.budget_musd)
	_summary.text = "%d de %d zonas ocupadas\nUS$ %s mi por corrida · bônus por pódio US$ %s mi" % [sp.contracts.size(), Sponsorship.zones().size(), _money(sp.per_race_total()), _money(sp.bonus_per_podium())]
	for z: Dictionary in Sponsorship.zones():
		var pin: Button = _pins[z["id"]]
		var taken := sp.contracts.has(z["id"])
		var sel: bool = z["id"] == _zone
		var idx := Sponsorship.zones().find(z) + 1
		pin.text = str(idx)
		var fill := UiStyle.RED if taken else Color("#2b2f38")
		for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
			var st := UiStyle.g_box(fill, 17, 0, 0)
			st.set_border_width_all(3)
			st.border_color = Color.WHITE if sel else Color("#8f98a7")
			pin.add_theme_stylebox_override(s, st)
	for c in _right.get_children():
		_right.remove_child(c)
		c.queue_free()
	_right.add_child(UiStyle.g_caption("Zonas do carro"))
	for z: Dictionary in Sponsorship.zones():
		_right.add_child(_zone_row(z))
	if sp.contracts.has(_zone):
		_right.add_child(UiStyle.g_caption("Contrato · %s" % Sponsorship.zone(_zone)["name"]))
		_right.add_child(_contract_card(_zone))
	else:
		_right.add_child(UiStyle.g_caption("Ofertas · %s (mudam todo mês)" % Sponsorship.zone(_zone)["name"]))
		var offers := sp.offers_for(campaign, _zone)
		for o in offers:
			_right.add_child(_offer_row(o))
		if offers.is_empty():
			_right.add_child(UiStyle.g_label("Sem ofertas agora. Novas marcas aparecem no próximo mês.", 14, UiStyle.G_TEXT_3))


func _brand_badge(name: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", UiStyle.g_box(Color.WHITE, 8, 12, 4))
	var l := UiStyle.g_label(name, 15, UiStyle.G_INK, "black")
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return p


func _zone_row(z: Dictionary) -> Control:
	var id: String = z["id"]
	var on := id == _zone
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 48)
	for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(s, UiStyle.g_box(UiStyle.G_LIGHT if on else Color(1, 1, 1, 0.07), 16, 14, 0))
	ScreenKit.press_feedback(b)
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 12)
	b.add_child(h)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 14
	h.offset_right = -14
	var num := PanelContainer.new()
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	num.custom_minimum_size = Vector2(28, 28)
	num.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	num.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.RED, 14, 0, 0))
	var nl := UiStyle.g_label(str(Sponsorship.zones().find(z) + 1), 14, Color.WHITE, "black")
	nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num.add_child(nl)
	h.add_child(num)
	var nv := VBoxContainer.new()
	nv.alignment = BoxContainer.ALIGNMENT_CENTER
	nv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nv.add_theme_constant_override("separation", -3)
	nv.custom_minimum_size = Vector2(120, 0)
	var n1 := UiStyle.g_label(String(z["name"]), 16, UiStyle.G_INK if on else UiStyle.G_TEXT, "black")
	n1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nv.add_child(n1)
	var n2 := UiStyle.g_label("valor ×%s" % ("%.1f" % float(z["mult"])).replace(".", ","), 12, UiStyle.G_INK_2 if on else UiStyle.G_TEXT_2, "bold")
	n2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nv.add_child(n2)
	h.add_child(nv)
	if sp.contracts.has(id):
		var c: Dictionary = sp.contracts[id]
		h.add_child(_brand_badge(String(c["brand"])))
		h.add_child(UiStyle.hspacer())
		var rv := VBoxContainer.new()
		rv.alignment = BoxContainer.ALIGNMENT_CENTER
		rv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rv.add_theme_constant_override("separation", -3)
		var r1 := UiStyle.g_label("US$ %s mi" % _money(float(c["per_race"])), 17, UiStyle.G_INK if on else UiStyle.G_TEXT, "black")
		r1.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		r1.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rv.add_child(r1)
		var r2 := UiStyle.g_label("por corrida · até %d" % int(c["until"]), 11, UiStyle.G_INK_2 if on else UiStyle.G_TEXT_2, "bold")
		r2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		r2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rv.add_child(r2)
		h.add_child(rv)
	else:
		h.add_child(UiStyle.hspacer())
		var rv2 := VBoxContainer.new()
		rv2.alignment = BoxContainer.ALIGNMENT_CENTER
		rv2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rv2.add_theme_constant_override("separation", -3)
		var o1 := UiStyle.g_label("%d ofertas" % sp.offers_for(campaign, id).size(), 17, Color("#ffd24a") if not on else Color("#8a6f00"), "black")
		o1.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		o1.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rv2.add_child(o1)
		var o2 := UiStyle.g_label("zona livre", 11, UiStyle.G_INK_2 if on else UiStyle.G_TEXT_2, "bold")
		o2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		o2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rv2.add_child(o2)
		h.add_child(rv2)
	b.pressed.connect(_on_zone.bind(id))
	return b


func _offer_row(o: Dictionary) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.07), 16, 14, 8))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	p.add_child(h)
	h.add_child(_brand_badge(String(o["brand"])))
	var t := VBoxContainer.new()
	t.alignment = BoxContainer.ALIGNMENT_CENTER
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_constant_override("separation", -2)
	t.add_child(UiStyle.g_label(String(o["category"]), 15, UiStyle.G_TEXT, "black"))
	var bonus := "sem bônus" if float(o["bonus"]) <= 0.0 else "+ US$ %s mi por pódio" % _money(float(o["bonus"]))
	var terms := UiStyle.g_label("%d ano%s · %s" % [int(o["years"]), "" if int(o["years"]) == 1 else "s", bonus], 12, UiStyle.G_TEXT_2, "bold")
	terms.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # quebra a linha em vez de alargar a coluna
	t.add_child(terms)
	h.add_child(t)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", -3)
	var v1 := UiStyle.g_label("US$ %s mi" % _money(float(o["per_race"])), 18, UiStyle.G_TEXT, "black")
	v1.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(v1)
	var v2 := UiStyle.g_label("por corrida", 11, Color("#7fe0b1"), "bold")
	v2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(v2)
	h.add_child(v)
	var more := Button.new()
	more.text = "PEDIR MAIS"
	more.focus_mode = Control.FOCUS_NONE
	more.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MIN)
	more.disabled = bool(o["asked"])
	for s: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		more.add_theme_stylebox_override(s, UiStyle.g_box(Color("#e3e6eb") if s != "disabled" else Color(1, 1, 1, 0.08), 12, 12, 0))
	for k: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		more.add_theme_color_override(k, UiStyle.G_INK)
	more.add_theme_color_override("font_disabled_color", UiStyle.G_TEXT_OFF)
	more.add_theme_font_override("font", UiStyle.G_BLACK)
	more.add_theme_font_size_override("font_size", UiStyle.fs(12))
	more.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	more.pressed.connect(_on_ask_more.bind(o["key"]))
	ScreenKit.press_feedback(more)
	h.add_child(more)
	var ok := CutButton.new()
	ok.text = "ACEITAR"
	ok.custom_minimum_size = Vector2(120, UiStyle.TOUCH_MIN)
	ok.add_theme_font_size_override("font_size", UiStyle.fs(13))
	ok.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ok.pressed.connect(_on_accept.bind(o["key"]))
	h.add_child(ok)
	return p


func _contract_card(zone_id: String) -> Control:
	var c: Dictionary = sp.contracts[zone_id]
	var card := PanelContainer.new()
	var st := UiStyle.g_box(UiStyle.G_LIGHT, 20, 22, 14)
	st.border_width_left = 7
	st.border_color = UiStyle.RED
	card.add_theme_stylebox_override("panel", st)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	top.add_child(_brand_badge(String(c["brand"])))
	top.add_child(UiStyle.g_label("%s · nível %d" % [c["category"], int(c["tier"])], 14, UiStyle.G_INK_2, "bold"))
	v.add_child(top)
	var facts := HBoxContainer.new()
	facts.add_theme_constant_override("separation", 8)
	var years := int(c["until"]) - campaign.season + 1
	for f: Array in [["US$ %s mi" % _money(float(c["per_race"])), "por corrida"], ["US$ %s mi" % _money(float(c["bonus"])), "bônus por pódio"], ["até %d" % int(c["until"]), "%d temporada%s" % [years, "" if years == 1 else "s"]]]:
		var p := PanelContainer.new()
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.add_theme_stylebox_override("panel", UiStyle.g_box(Color("#e3e6eb"), 12, 10, 6))
		var fv := VBoxContainer.new()
		fv.add_theme_constant_override("separation", -2)
		fv.add_child(UiStyle.g_label(f[0], 17, UiStyle.G_INK, "black"))
		fv.add_child(UiStyle.g_label(f[1], 12, UiStyle.G_INK_2))
		p.add_child(fv)
		facts.add_child(p)
	v.add_child(facts)
	var fee := float(c["per_race"]) * float(Sponsorship.data()["terminate_races_per_year"]) * maxi(years, 1)
	var end := Button.new()
	end.text = "RESCINDIR CONTRATO · MULTA US$ %s mi" % ("%.1f" % fee).replace(".", ",")
	end.focus_mode = Control.FOCUS_NONE
	end.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MIN)
	for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
		end.add_theme_stylebox_override(s, UiStyle.g_box(Color("#e3e6eb"), 12, 14, 0))
	for k: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		end.add_theme_color_override(k, UiStyle.G_INK)
	end.add_theme_font_override("font", UiStyle.G_BLACK)
	end.add_theme_font_size_override("font_size", UiStyle.fs(13))
	end.pressed.connect(_on_terminate.bind(zone_id))
	ScreenKit.press_feedback(end)
	v.add_child(end)
	return card


# --- ações --------------------------------------------------------------------------------------

func _on_zone(id: String) -> void:
	_zone = id
	_refresh()


func _on_accept(key: String) -> void:
	var res := sp.accept(campaign, _zone, key)
	if res["ok"]:
		campaign.save()
	_toasts.push(String(res["text"]), "hot" if res["ok"] else "note")
	_refresh()


func _on_ask_more(key: String) -> void:
	var res := sp.ask_more(campaign, _zone, key)
	campaign.save()
	_toasts.push(String(res["text"]), "hot" if res["ok"] else "note")
	_refresh()


func _on_terminate(zone_id: String) -> void:
	var fee := sp.terminate(campaign, zone_id)
	campaign.save()
	_toasts.push("Contrato rescindido (multa US$ %s mi)." % ("%.1f" % fee).replace(".", ","))
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.open_campaign_hub()


## Cinco marcas de influência (amarelas até o nível atual).
class InfluencePips:
	extends Control

	var level := 1

	func _init() -> void:
		custom_minimum_size = Vector2(5 * 27 + 4 * 5, 10)

	func _draw() -> void:
		for i in 5:
			var st := StyleBoxFlat.new()
			st.bg_color = Color("#ffd24a") if i < level else Color(1, 1, 1, 0.14)
			st.set_corner_radius_all(5)
			draw_style_box(st, Rect2(i * 32.0, 0.0, 27.0, 10.0))
