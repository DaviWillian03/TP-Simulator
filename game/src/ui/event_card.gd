class_name EventCard
extends Control
## Cartão de notícia de um evento inesperado (mockup v13-1): título, texto e chips de consequência. A consequência já foi
## aplicada (decisão do usuário: automática, sem escolhas); o jogador só confirma "Entendi".

signal dismissed


func setup(item: Dictionary) -> void:
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
	var st := UiStyle.g_box(UiStyle.G_LIGHT, 26, 38, 24)
	st.content_margin_left = 40
	st.border_width_left = 10
	st.border_color = UiStyle.RED
	st.shadow_color = Color(0, 0, 0, 0.55)
	st.shadow_size = 24
	panel.add_theme_stylebox_override("panel", st)
	panel.custom_minimum_size = Vector2(760, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	v.add_child(UiStyle.g_caption("Notícia · %s" % String(CampaignEvents.CAT_NAMES.get(item["cat"], "CAMPANHA")).to_lower(), UiStyle.G_INK_2))
	var title := UiStyle.g_label(String(item["title"]), 32, UiStyle.G_INK, "black")
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(title)
	var text := UiStyle.g_label(String(item["text"]), 16, Color("#2b303a"))
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(660, 0)
	v.add_child(text)
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 10)
	for c: Dictionary in item.get("chips", []):
		var p := PanelContainer.new()
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.add_theme_stylebox_override("panel", UiStyle.g_box(Color("#e3e6eb"), 14, 14, 8))
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", -2)
		var col := UiStyle.G_INK
		if c["kind"] == "bad":
			col = Color("#b3261e")
		elif c["kind"] == "good":
			col = Color("#2a6b3f")
		cv.add_child(UiStyle.g_label(String(c["big"]), 19, col, "black"))
		var sm := UiStyle.g_label(String(c["small"]), 12, UiStyle.G_INK_2)
		sm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cv.add_child(sm)
		p.add_child(cv)
		chips.add_child(p)
	v.add_child(chips)
	var row := HBoxContainer.new()
	row.add_child(UiStyle.hspacer())
	var ok := CutButton.new()
	ok.text = "ENTENDI"
	ok.custom_minimum_size = Vector2(260, UiStyle.TOUCH_MAIN)
	ok.add_theme_font_size_override("font_size", 18)
	ok.pressed.connect(func() -> void:
		dismissed.emit()
		queue_free())
	row.add_child(ok)
	v.add_child(row)
