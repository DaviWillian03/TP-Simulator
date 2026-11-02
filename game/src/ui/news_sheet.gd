class_name NewsSheet
extends Control
## Lista de notícias da temporada + frequência dos eventos (mockup v13-1). Tocar numa notícia não faz nada: ela só informa.

signal closed


func setup(camp: Campaign) -> void:
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
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 0)
	scroll.add_child(list)
	if camp.events.news.is_empty():
		list.add_child(UiStyle.g_label("Nenhum evento até agora. Eles aparecem enquanto o tempo passa.", 14, UiStyle.G_TEXT_3))
	for n: Dictionary in camp.events.news:
		list.add_child(_item(n))


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
