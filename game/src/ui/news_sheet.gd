class_name NewsSheet
extends Control
## Lista de notícias da temporada + frequência dos eventos (mockup v13-1). Tocar numa notícia não faz nada: ela só informa.

signal closed
signal decision_requested(uid: int)  ## tocar numa decisão aberta do mercado (aba Mercado, mockup v27-3)

var _camp: Campaign
var _list: VBoxContainer
var _tab := "all"


func setup(camp: Campaign, tab := "all") -> void:
	_camp = camp
	_tab = tab
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.025, 0.03, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	var st := UiStyle.g_box(Color("#17191e"), 24, 26, 20)
	st.shadow_color = Color(0, 0, 0, 0.55)
	st.shadow_size = 22
	panel.add_theme_stylebox_override("panel", st)
	panel.custom_minimum_size = Vector2(700, 560)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var head := HBoxContainer.new()
	head.add_child(UiStyle.g_label("NOTÍCIAS DA TEMPORADA", 24, UiStyle.G_TEXT, "black"))
	head.add_child(UiStyle.hspacer())
	var close := ScreenKit.round_button("close", UiStyle.TOUCH_MIN, "Fechar")
	close.pressed.connect(func() -> void:
		closed.emit()
		queue_free())
	head.add_child(close)
	v.add_child(head)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(UiStyle.g_label("Frequência dos eventos", 14, UiStyle.G_TEXT_2, "bold"))
	var opts: Array = []
	for k: String in ["rare", "normal", "frequent", "off"]:
		opts.append([k, CampaignEvents.FREQUENCIES[k]])
	row.add_child(ScreenKit.segmented(opts, camp.events.freq, func(f: String) -> void:
		camp.events.freq = f
		camp.save()))
	v.add_child(row)
	v.add_child(ScreenKit.segmented([["all", "Tudo"], ["market", "Mercado"]], _tab, func(t: String) -> void:
		_tab = t
		_fill()))
	var scroll := DragScroll.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 0)
	scroll.add_child(_list)
	_fill()


func _fill() -> void:
	for c in _list.get_children():
		c.queue_free()
	if _tab == "market":
		for d: Dictionary in _camp.personnel.transfers.decisions:
			_list.add_child(_decision_row(d))
	var shown := 0
	for n: Dictionary in _camp.events.news:
		if _tab == "market" and String(n.get("cat", "")) != "market":
			continue
		_list.add_child(_item(n))
		shown += 1
	if shown == 0 and (_tab != "market" or _camp.personnel.transfers.decisions.is_empty()):
		_list.add_child(UiStyle.g_label("Nada por aqui ainda. As notícias aparecem enquanto o tempo passa.", 14, UiStyle.G_TEXT_3))


## Decisão aberta do mercado: emblema da equipe, título e "decidir".
func _decision_row(d: Dictionary) -> Control:
	var pe: Personnel = _camp.personnel
	var who: Dictionary = pe.person(String(d["id"]), _camp)
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 64)
	for st: String in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, UiStyle.g_box(Color(0.88, 0.02, 0.0, 0.14 if st == "normal" else 0.22), 16, 12, 8))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for k: String in ["left", "right"]:
		m.add_theme_constant_override("margin_" + k, 12)
	m.add_child(h)
	b.add_child(m)
	var e := TeamEmblems.make_rect(String(d["team"]), 40)
	e.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(e)
	var name := String(who.get("name", ""))
	var team_name := String(GameData.team_by_id(_camp.teams(), String(d["team"])).get("name", ""))
	var t := ("%s FAZ PROPOSTA POR %s" % [team_name, name]) if d["kind"] == "offer" else ("%s QUER RENOVAR" % name)
	var l := UiStyle.g_label(t.to_upper(), 15, UiStyle.G_TEXT, "black")
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	var tag := UiStyle.g_label("DECIDIR", 13, Color("#ff8a80"), "black")
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(tag)
	b.pressed.connect(func() -> void:
		decision_requested.emit(int(d["uid"]))
		queue_free())
	return b


func _item(n: Dictionary) -> Control:
	var col: Color = CampaignEvents.CAT_COLORS.get(n["cat"], Color("#8f98a7"))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var dot := PanelContainer.new()
	dot.custom_minimum_size = Vector2(34, 34)
	dot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	dot.add_theme_stylebox_override("panel", UiStyle.g_box(Color(col, 0.2), 17, 0, 0))
	var l := UiStyle.g_label(String(CampaignEvents.CAT_NAMES.get(n["cat"], "?")).left(1), 15, col, "black")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dot.add_child(l)
	if String(n.get("team", "")) != "":
		var em := TeamEmblems.make_rect(String(n["team"]), 34)
		em.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		h.add_child(em)
	else:
		h.add_child(dot)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 0)
	v.add_child(UiStyle.g_label(String(n["title"]).capitalize() if false else String(n["title"]), 15, UiStyle.G_TEXT, "black"))
	var d := Time.get_datetime_dict_from_unix_time(int(n["day"]) * 86400)
	var months := ["", "JAN", "FEV", "MAR", "ABR", "MAI", "JUN", "JUL", "AGO", "SET", "OUT", "NOV", "DEZ"]
	v.add_child(UiStyle.g_label("%02d %s" % [int(d["day"]), months[int(d["month"])]], 12, UiStyle.G_TEXT_2, "bold"))
	var t := UiStyle.g_label(String(n["text"]), 13, Color("#c3c9d3"))
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	h.add_child(v)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_top", 8)
	m.add_theme_constant_override("margin_bottom", 8)
	m.add_child(h)
	return m
