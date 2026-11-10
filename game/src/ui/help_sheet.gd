class_name HelpSheet
extends RefCounted
## Folha de ajuda (mockup v32-2): assuntos em cartões e o texto do assunto escolhido. Conteúdo em data/help.json.


static func open(screen: Control, topic_id: String = "") -> void:
	var topics: Array = GameData.load_json(GameData.DATA_DIR + "help.json").get("topics", [])
	if topics.is_empty():
		return
	var sh := ScreenKit.sheet("Ajuda", 1040)
	var root: Control = sh["root"]
	var body: VBoxContainer = sh["body"]
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 10)
	body.add_child(cards)
	var detail := VBoxContainer.new()
	detail.add_theme_constant_override("separation", 10)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.05), 18, 20, 16))
	box.custom_minimum_size = Vector2(0, 250)
	box.add_child(detail)
	body.add_child(box)
	var pick := func(id: String) -> void:
		for t: Dictionary in topics:
			if t["id"] != id:
				continue
			for c in detail.get_children():
				c.queue_free()
			detail.add_child(UiStyle.g_label(String(t["heading"]), 22, Color("#F5C542"), "black"))
			for line: String in t["lines"]:
				var l := UiStyle.g_label("• " + line, 15, UiStyle.G_TEXT, "bold")
				l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				detail.add_child(l)
		for c: Button in cards.get_children():
			var on: bool = String(c.get_meta("topic")) == id
			c.set_pressed_no_signal(on)
			(c.get_meta("paint") as Callable).call(on)
	var group := ButtonGroup.new()
	for t: Dictionary in topics:
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 108)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.set_meta("topic", t["id"])
		for st: String in ["normal", "hover"]:
			b.add_theme_stylebox_override(st, UiStyle.g_box(UiStyle.G_SURFACE, 16, 0, 0))
		for st: String in ["pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(st, UiStyle.g_box(UiStyle.G_LIGHT, 16, 0, 0))
		var v := VBoxContainer.new()
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_theme_constant_override("separation", 2)
		b.add_child(v)
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 12
		v.offset_top = 10
		v.offset_right = -8
		var ic := ScreenKit.icon(String(t["icon"]), 26, UiStyle.G_TEXT)
		v.add_child(ic)
		var tl := UiStyle.g_label(String(t["title"]), 15, UiStyle.G_TEXT, "black")
		tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(tl)
		var sl := UiStyle.g_label(String(t["sub"]), 11, UiStyle.G_TEXT_2, "bold")
		sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(sl)
		var id: String = t["id"]
		b.pressed.connect(func() -> void: pick.call(id))
		var paint := func(on: bool) -> void:  # cartão escolhido é claro: texto e ícone escuros
			var ink := UiStyle.G_INK if on else UiStyle.G_TEXT
			tl.add_theme_color_override("font_color", ink)
			sl.add_theme_color_override("font_color", UiStyle.G_INK_2 if on else UiStyle.G_TEXT_2)
			ic.modulate = ink
		b.set_meta("paint", paint)
		b.toggled.connect(paint)
		cards.add_child(b)
	var first := topic_id if topic_id != "" else String(topics[0]["id"])
	pick.call(first)
	screen.add_child(root)
