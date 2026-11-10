extends Control
## Criação da equipe da campanha — direção Garagem (mockups design/mockups/v5-2 a v5-5).
## Quatro passos: origem → identidade → motor e objetivos → pilotos. As escolhas ficam em
## `spec` (formato de Campaign.new_created) e são preservadas ao voltar um passo.

const STEPS := ["Origem", "Identidade", "Motor e objetivos", "Pilotos"]
const PRIMARY := ["#0E7C66", "#1868DB", "#E8002D", "#FF8000", "#6A2C91", "#111111", "#F2F2F2"]
const SECONDARY := ["#F2A900", "#FFFFFF", "#111111", "#27F4D2", "#E10600", "#9AA3B2", "#FF87BC"]
const SHAPES := ["square", "hex", "circle", "shield", "diamond"]
const HINTS := [
	"A origem define o começo e o tipo de desafio. Dinheiro e fábrica: valores PROVISÓRIOS.",
	"Pintura completa, patrocínios no carro e logo livre chegam com o estúdio de design (P9).",
	"Montadora estreante já começa com motor próprio; as outras origens podem escolher.",
	"Notas dos pilotos: PROVISÓRIAS até a pesquisa de atributos.",
]

var step := 0
var spec := {"origin": "garage", "name": "", "short": "", "color": "#0E7C66", "color2": "#F2A900", "shape": "hex",
	"country": "Brasil", "engine": "Mercedes", "objective": {"id": "win"}, "detail": "essential", "ai_difficulty": "normal",
	"drivers": []}
var data: Dictionary
var _page: Dictionary
var _content: Control
var _steps_bar: Control
var _next: CutButton
var _hint: Label
var _preview: Dictionary = {}
var _pool_list: VBoxContainer
var _slots: VBoxContainer
var _filter := "all"


func _ready() -> void:
	data = Campaign.origins_data()
	_page = ScreenKit.garage_page(self, "custom")
	var bd: GarageBackdrop = _page["backdrop"]
	bd.floor_ratio = 1.0
	bd.show_lamps = false
	bd.cone_x = -1.0
	bd.glow_center = Vector2(0.6, 0.55)
	bd.set_glow(Color(spec["color"]), 0.24)
	var layer: Control = _page["layer"]

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UiStyle.SP_L)
	var back := ScreenKit.round_button("back", 52, "Voltar")
	back.pressed.connect(Session.open_campaign)
	head.add_child(back)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -2)
	titles.add_child(UiStyle.g_caption("Campanha · criar equipe"))
	titles.add_child(UiStyle.g_label("CRIAR EQUIPE", 30, UiStyle.G_TEXT, "black"))
	head.add_child(titles)
	ScreenKit.place(head, layer, Control.PRESET_TOP_LEFT, Vector2(44, 24))

	_content = Control.new()
	layer.add_child(_content)
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content.offset_left = 44
	_content.offset_right = -44
	_content.offset_top = 150
	_content.offset_bottom = -100

	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", UiStyle.SP_L)
	layer.add_child(foot)
	foot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	foot.offset_left = 44
	foot.offset_right = -44
	foot.offset_top = -86
	foot.offset_bottom = -26
	var prev := Button.new()
	prev.text = "VOLTAR"
	prev.icon = load("res://assets/icons/back.svg")
	prev.add_theme_constant_override("icon_max_width", 20)
	prev.focus_mode = Control.FOCUS_NONE
	prev.custom_minimum_size = Vector2(140, UiStyle.TOUCH_MAIN)
	prev.add_theme_stylebox_override("normal", UiStyle.g_box(UiStyle.G_SURFACE_HOVER, 14, 20, 0))
	prev.add_theme_stylebox_override("pressed", UiStyle.g_box(UiStyle.G_SURFACE_PRESS, 14, 20, 0))
	prev.add_theme_stylebox_override("hover", UiStyle.g_box(UiStyle.G_SURFACE_PRESS, 14, 20, 0))
	prev.pressed.connect(func() -> void:
		if step == 0:
			Session.open_campaign()
		else:
			_go(step - 1))
	ScreenKit.press_feedback(prev)
	foot.add_child(prev)
	_hint = UiStyle.g_label("", UiStyle.FS_SMALL, UiStyle.G_TEXT_3)
	_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	foot.add_child(_hint)
	_next = CutButton.new()
	_next.custom_minimum_size = Vector2(320, UiStyle.TOUCH_MAIN + 4)
	_next.pressed.connect(_on_next)
	foot.add_child(_next)
	_go(Session.debug_ui.to_int() if Session.debug_ui.is_valid_int() else 0)


func _go(p_step: int) -> void:
	step = clampi(p_step, 0, STEPS.size() - 1)
	if _steps_bar:
		_steps_bar.queue_free()
	var items: Array = []
	for i in STEPS.size():
		items.append([STEPS[i], str(i + 1), "done" if i < step else ("now" if i == step else "next")])
	_steps_bar = ScreenKit.step_bar(items)
	(_page["layer"] as Control).add_child(_steps_bar)
	_steps_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_steps_bar.offset_left = 44
	_steps_bar.offset_right = -44
	_steps_bar.offset_top = 96
	_steps_bar.offset_bottom = 132
	for c in _content.get_children():
		c.queue_free()
	_preview = {}
	match step:
		0:
			_build_origin()
		1:
			_build_identity()
		2:
			_build_engine()
		3:
			_build_drivers()
	_hint.text = HINTS[step]
	_next.text = "FUNDAR EQUIPE" if step == 3 else "AVANÇAR"
	_validate()


func _on_next() -> void:
	if step < 3:
		_go(step + 1)
		return
	var c := Campaign.new_created(spec)
	if c.is_valid():
		Session.start_campaign(c)


func _validate() -> void:
	match step:
		1:
			_next.disabled = String(spec["name"]).strip_edges().length() < 2 or String(spec["short"]).strip_edges().length() != 3
		3:
			_next.disabled = (spec["drivers"] as Array).size() != 2
		_:
			_next.disabled = false
	_next.get_child(0).queue_redraw()


# --- 1 · origem -------------------------------------------------------------------------

func _build_origin() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	_content.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var group := ButtonGroup.new()
	for o: Dictionary in data["origins"]:
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_stylebox_override("normal", UiStyle.g_box(UiStyle.G_SURFACE, 20, 20, 20))
		b.add_theme_stylebox_override("hover", UiStyle.g_box(UiStyle.G_SURFACE_HOVER, 20, 20, 20))
		b.add_theme_stylebox_override("pressed", UiStyle.g_box(UiStyle.G_LIGHT, 20, 20, 20))
		b.add_theme_stylebox_override("hover_pressed", UiStyle.g_box(UiStyle.G_LIGHT, 20, 20, 20))
		var v := VBoxContainer.new()
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_theme_constant_override("separation", 10)
		b.add_child(v)
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 20
		v.offset_right = -20
		v.offset_top = 20
		v.offset_bottom = -18
		var badge := PanelContainer.new()
		badge.custom_minimum_size = Vector2(52, 52)
		badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var ic := ScreenKit.icon(o["icon"], 28)
		badge.add_child(ic)
		v.add_child(badge)
		var name_l := UiStyle.g_label(String(o["name"]).to_upper(), 23, UiStyle.G_TEXT, "black")
		name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(name_l)
		var desc := UiStyle.g_label(o["desc"], 14, UiStyle.G_TEXT_2)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size = Vector2(0, 62)
		v.add_child(desc)
		var labels: Array[Label] = [name_l, desc]
		var dots_all: Array = []
		for pair: Array in [["money", "Dinheiro"], ["factory", "Fábrica"], ["engine", "Motor"], ["patience", "Paciência"]]:
			var r := HBoxContainer.new()
			r.add_theme_constant_override("separation", 10)
			var l := UiStyle.g_label(pair[1], 13, UiStyle.G_TEXT_2)
			l.custom_minimum_size = Vector2(72, 0)
			r.add_child(l)
			labels.append(l)
			var score := int(o["scores"][pair[0]])
			for k in 5:
				var dot := Panel.new()
				dot.custom_minimum_size = Vector2(22, 8)
				dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				dot.set_meta("full", k < score)
				r.add_child(dot)
				dots_all.append(dot)
			v.add_child(r)
		var spacer := Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(spacer)
		var tags := HBoxContainer.new()
		tags.add_theme_constant_override("separation", 6)
		var tag_labels: Array[Label] = []
		for t: String in [o["difficulty"], o["complexity"]]:
			var chip := PanelContainer.new()
			chip.set_meta("chip", true)
			var tl := UiStyle.g_caption(t)
			tl.set_meta("hard", t == "Difícil")
			chip.add_child(tl)
			tags.add_child(chip)
			tag_labels.append(tl)
		v.add_child(tags)
		var paint := func() -> void:
			var on := b.button_pressed
			badge.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_INK if on else UiStyle.G_SURFACE_HOVER, 14, 12, 12))
			for l: Label in labels:
				l.add_theme_color_override("font_color", UiStyle.G_INK if on and l == name_l else (UiStyle.G_INK_2 if on else (UiStyle.G_TEXT if l == name_l else UiStyle.G_TEXT_2)))
			for dot: Panel in dots_all:
				var full: bool = dot.get_meta("full")
				dot.add_theme_stylebox_override("panel", UiStyle.g_box((Color("#1868DB") if on else Color("#5c93ea")) if full else (Color("#d6d9df") if on else Color(1, 1, 1, 0.12)), 4, 0, 0))
			for tl: Label in tag_labels:
				var hard: bool = tl.get_meta("hard")
				tl.add_theme_color_override("font_color", (UiStyle.G_RED_PRESS if on else Color("#ffb4a8")) if hard else (UiStyle.G_INK_2 if on else UiStyle.G_TEXT_2))
				(tl.get_parent() as PanelContainer).add_theme_stylebox_override("panel", UiStyle.g_box(Color("#e3e6eb") if on else UiStyle.G_SURFACE_HOVER, 10, 8, 4))
		b.toggled.connect(func(_on: bool) -> void: paint.call())
		b.button_pressed = o["id"] == spec["origin"]
		paint.call()
		var id: String = o["id"]
		b.pressed.connect(func() -> void:
			spec["origin"] = id
			if Campaign.origin_by_id(id).get("own_engine", false):
				spec["engine"] = "own")
		ScreenKit.press_feedback(b)
		row.add_child(b)


# --- 2 · identidade ---------------------------------------------------------------------

func _build_identity() -> void:
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	_content.add_child(left)
	left.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	left.offset_right = 520
	left.add_child(UiStyle.g_caption("Nome da equipe"))
	var name_edit := _line_edit(spec["name"], "Ex.: Aurora Racing", 24)
	name_edit.text_changed.connect(func(t: String) -> void:
		spec["name"] = t
		if String(spec["short"]).is_empty() or String(spec["short"]) == _auto_short(t.left(t.length() - 1)):
			spec["short"] = _auto_short(t)
			_preview["short_edit"].text = spec["short"]
		_refresh_preview()
		_validate())
	left.add_child(name_edit)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UiStyle.SP_M)
	var sv := VBoxContainer.new()
	sv.add_child(UiStyle.g_caption("Sigla"))
	var short_edit := _line_edit(spec["short"], "AUR", 3)
	short_edit.custom_minimum_size.x = 150
	short_edit.text_changed.connect(func(t: String) -> void:
		spec["short"] = t.to_upper()
		_refresh_preview()
		_validate())
	sv.add_child(short_edit)
	_preview["short_edit"] = short_edit
	row.add_child(sv)
	var cv := VBoxContainer.new()
	cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cv.add_child(UiStyle.g_caption("Sede"))
	var country := Button.new()
	country.focus_mode = Control.FOCUS_NONE
	country.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MAIN)
	country.text = spec["country"]
	country.alignment = HORIZONTAL_ALIGNMENT_LEFT
	country.icon = load("res://assets/icons/flag.svg")
	country.add_theme_constant_override("icon_max_width", 20)
	country.add_theme_stylebox_override("normal", UiStyle.g_box(UiStyle.G_SURFACE_HOVER, 14, 18, 0))
	country.add_theme_stylebox_override("hover", UiStyle.g_box(UiStyle.G_SURFACE_PRESS, 14, 18, 0))
	country.add_theme_stylebox_override("pressed", UiStyle.g_box(UiStyle.G_SURFACE_PRESS, 14, 18, 0))
	country.add_theme_font_size_override("font_size", UiStyle.fs(19))
	country.pressed.connect(_open_countries.bind(country))
	cv.add_child(country)
	row.add_child(cv)
	left.add_child(row)
	left.add_child(UiStyle.g_caption("Cor principal"))
	left.add_child(_swatches(PRIMARY, "color"))
	left.add_child(UiStyle.g_caption("Cor de destaque"))
	left.add_child(_swatches(SECONDARY, "color2"))
	left.add_child(UiStyle.g_caption("Forma do emblema"))
	var shapes := HBoxContainer.new()
	shapes.add_theme_constant_override("separation", 10)
	var group := ButtonGroup.new()
	for sh: String in SHAPES:
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(60, 60)
		b.add_theme_stylebox_override("normal", UiStyle.g_box(UiStyle.G_SURFACE_HOVER, 14, 0, 0))
		b.add_theme_stylebox_override("pressed", UiStyle.g_box(UiStyle.G_LIGHT, 14, 0, 0))
		b.add_theme_stylebox_override("hover_pressed", UiStyle.g_box(UiStyle.G_LIGHT, 14, 0, 0))
		b.add_theme_stylebox_override("hover", UiStyle.g_box(UiStyle.G_SURFACE_PRESS, 14, 0, 0))
		b.icon = CarArt.emblem_texture(sh, "#8f98a7", "#8f98a7", "")
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_theme_constant_override("icon_max_width", 30)
		b.button_pressed = sh == spec["shape"]
		b.pressed.connect(func() -> void:
			spec["shape"] = sh
			_refresh_preview())
		shapes.add_child(b)
	left.add_child(shapes)

	var card := ScreenKit.g_card(Color(1, 1, 1, 0.04), 24, 26, 22)
	_content.add_child(card)
	card.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	card.offset_left = -640
	card.offset_bottom = -20
	card.clip_contents = true
	var pv := VBoxContainer.new()
	card.add_child(pv)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	var emb_box := Control.new()
	emb_box.custom_minimum_size = Vector2(110, 110)
	var emb := TextureRect.new()
	emb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emb_box.add_child(emb)
	emb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var emb_text := UiStyle.g_label("", 26, Color.WHITE, "black")
	emb_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emb_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emb_box.add_child(emb_text)
	emb_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top.add_child(emb_box)
	var tv := VBoxContainer.new()
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	tv.add_child(UiStyle.g_caption("Prévia"))
	var title := UiStyle.g_label("", 32, UiStyle.G_TEXT, "black")
	tv.add_child(title)
	var sub := UiStyle.g_label("", UiStyle.FS_BODY, UiStyle.G_TEXT_2)
	tv.add_child(sub)
	top.add_child(tv)
	pv.add_child(top)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pv.add_child(sp)
	var car := CarHero.new()
	car.custom_minimum_size = Vector2(588, 165)
	pv.add_child(car)
	_preview.merge({"emb": emb, "emb_text": emb_text, "title": title, "sub": sub, "car": car})
	_refresh_preview()


func _line_edit(value: String, placeholder: String, max_len: int) -> LineEdit:
	var e := LineEdit.new()
	e.text = value
	e.placeholder_text = placeholder
	e.max_length = max_len
	e.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MAIN)
	e.add_theme_stylebox_override("normal", UiStyle.g_box(UiStyle.G_SURFACE_HOVER, 14, 18, 0))
	var focus := UiStyle.g_box(UiStyle.G_SURFACE_HOVER, 14, 18, 0)
	focus.border_color = Color(UiStyle.G_TEXT, 0.6)
	focus.set_border_width_all(2)
	e.add_theme_stylebox_override("focus", focus)
	e.add_theme_font_override("font", UiStyle.G_BOLD)
	e.add_theme_font_size_override("font_size", UiStyle.fs(20))
	e.add_theme_color_override("font_color", UiStyle.G_TEXT)
	e.add_theme_color_override("font_placeholder_color", UiStyle.G_TEXT_OFF)
	return e


func _auto_short(name: String) -> String:
	var plain := Campaign.driver_code("x " + name.strip_edges().get_slice(" ", 0))
	return plain


func _swatches(colors: Array, key: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var group := ButtonGroup.new()
	for c: String in colors:
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(UiStyle.TOUCH_MIN, UiStyle.TOUCH_MIN)
		var n := UiStyle.g_box(Color(c), 12, 0, 0)
		var sel := UiStyle.g_box(Color(c), 12, 0, 0)
		sel.border_color = UiStyle.G_LIGHT
		sel.set_border_width_all(3)
		sel.expand_margin_left = 3
		sel.expand_margin_right = 3
		sel.expand_margin_top = 3
		sel.expand_margin_bottom = 3
		for s: String in ["normal", "hover"]:
			b.add_theme_stylebox_override(s, n)
		for s: String in ["pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(s, sel)
		b.tooltip_text = c
		b.button_pressed = c == spec[key]
		b.pressed.connect(func() -> void:
			spec[key] = c
			_refresh_preview())
		h.add_child(b)
	return h


func _open_countries(btn: Button) -> void:
	var s := ScreenKit.sheet("Sede da equipe", 900)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	(s["body"] as VBoxContainer).add_child(grid)
	for c: String in data["countries"]:
		var b := Button.new()
		b.text = c
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(200, 48)
		ScreenKit._selectable_styles(b, 14)
		b.add_theme_stylebox_override("normal", UiStyle.g_box(UiStyle.G_SURFACE, 14, 10, 0))
		b.toggle_mode = true
		b.button_pressed = c == spec["country"]
		b.pressed.connect(func() -> void:
			spec["country"] = c
			btn.text = c
			_refresh_preview()
			(s["root"] as Control).queue_free())
		grid.add_child(b)
	add_child(s["root"])


func _refresh_preview() -> void:
	(_page["backdrop"] as GarageBackdrop).set_glow(Color(spec["color"]), 0.24)
	if _preview.is_empty() or not _preview.has("emb"):
		return
	(_preview["emb"] as TextureRect).texture = CarArt.emblem_texture(spec["shape"], spec["color"], spec["color2"], spec["short"])
	var et: Label = _preview["emb_text"]
	et.text = String(spec["short"]).to_upper()
	et.add_theme_color_override("font_color", Color(spec["color2"]))
	var name := String(spec["name"]).strip_edges()
	(_preview["title"] as Label).text = (name if name != "" else "Sua equipe").to_upper()
	(_preview["sub"] as Label).text = "Sede: %s · 12ª equipe do grid" % spec["country"]
	(_preview["car"] as CarHero).set_team("custom", 0, Color(spec["color2"]),
		{"id": "custom", "custom": true, "color": spec["color"], "color2": spec["color2"]})


# --- 3 · motor e objetivos --------------------------------------------------------------

func _build_engine() -> void:
	var own := bool(Campaign.origin_by_id(spec["origin"]).get("own_engine", false))
	if own:
		spec["engine"] = "own"
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	_content.add_child(left)
	left.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	left.offset_right = 740
	left.add_child(UiStyle.g_caption("Motor"))
	var engines := GridContainer.new()
	engines.columns = 3
	engines.add_theme_constant_override("h_separation", 10)
	engines.add_theme_constant_override("v_separation", 10)
	var group := ButtonGroup.new()
	var opts: Array = []
	for e: String in data["engine_suppliers"]:
		opts.append([e, e, "cliente"])
	opts.append(["own", "Motor próprio", "P&D de motor completa"])
	for o: Array in opts:
		var b := _tile_button(o[1], o[2], group)
		b.custom_minimum_size = Vector2(240, 64)
		b.button_pressed = spec["engine"] == o[0]
		b.disabled = own and o[0] != "own"
		var val: String = o[0]
		b.pressed.connect(func() -> void:
			spec["engine"] = val
			_build_summary())
		engines.add_child(b)
	left.add_child(engines)
	left.add_child(UiStyle.g_caption("Objetivo de longo prazo"))
	var objs := GridContainer.new()
	objs.columns = 2
	objs.add_theme_constant_override("h_separation", 10)
	objs.add_theme_constant_override("v_separation", 10)
	var og := ButtonGroup.new()
	for o: Dictionary in data["objectives"]:
		var label := String(o["name"]) % int(o["seasons"]) if String(o["name"]).contains("%d") else String(o["name"])
		var b := _tile_button(label, "", og)
		b.custom_minimum_size = Vector2(365, 58)
		b.button_pressed = spec["objective"]["id"] == o["id"]
		var obj := {"id": o["id"]}
		if o.has("seasons"):
			obj["seasons"] = o["seasons"]
		b.pressed.connect(func() -> void:
			spec["objective"] = obj
			_build_summary())
		objs.add_child(b)
	left.add_child(objs)
	var segs := HBoxContainer.new()
	segs.add_theme_constant_override("separation", 20)
	var dv := VBoxContainer.new()
	dv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dv.add_child(UiStyle.g_caption("Nível de detalhe"))
	dv.add_child(ScreenKit.segmented([["essential", "Essencial"], ["advanced", "Avançado"]], spec["detail"], func(v: String) -> void:
		spec["detail"] = v
		_build_summary()))
	segs.add_child(dv)
	var av := VBoxContainer.new()
	av.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	av.add_child(UiStyle.g_caption("Dificuldade da IA"))
	av.add_child(ScreenKit.segmented([["easy", "Fácil"], ["normal", "Normal"], ["hard", "Difícil"]], spec["ai_difficulty"], func(v: String) -> void:
		spec["ai_difficulty"] = v
		_build_summary()))
	segs.add_child(av)
	left.add_child(segs)
	var card := ScreenKit.g_card(UiStyle.G_SURFACE, 20, 24, 20)
	_content.add_child(card)
	card.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	card.offset_left = -400
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 0)
	card.add_child(sv)
	_preview["summary"] = sv
	_build_summary()


func _tile_button(title: String, sub: String, group: ButtonGroup) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.button_group = group
	b.focus_mode = Control.FOCUS_NONE
	ScreenKit._selectable_styles(b, 14)
	b.add_theme_stylebox_override("normal", UiStyle.g_box(UiStyle.G_SURFACE_HOVER, 14, 16, 0))
	b.add_theme_stylebox_override("disabled", UiStyle.g_box(UiStyle.G_OFF, 14, 16, 0))
	b.text = title if sub == "" else "%s\n%s" % [title, sub]
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_override("font", UiStyle.G_BOLD)
	b.add_theme_font_size_override("font_size", UiStyle.fs(16))
	b.add_theme_color_override("font_color", UiStyle.G_TEXT)
	b.add_theme_color_override("font_disabled_color", UiStyle.G_TEXT_OFF)
	return b


func _build_summary() -> void:
	if not _preview.has("summary"):
		return
	var sv: VBoxContainer = _preview["summary"]
	for c in sv.get_children():
		c.queue_free()
	sv.add_child(UiStyle.g_label("RESUMO", 24, UiStyle.G_TEXT, "black"))
	var o := Campaign.origin_by_id(spec["origin"])
	var obj := "Metas da diretoria"
	for x: Dictionary in data["objectives"]:
		if x["id"] == spec["objective"]["id"]:
			obj = String(x["name"]) % int(x["seasons"]) if String(x["name"]).contains("%d") else String(x["name"])
	var rows := [["Origem", o.get("name", "")], ["Equipe", String(spec["name"]) if spec["name"] != "" else "—"],
		["Motor", "Próprio" if spec["engine"] == "own" else spec["engine"]], ["Orçamento inicial", "US$ %d mi" % int(o.get("budget_musd", 0))],
		["Dívidas", "US$ %d mi" % int(o.get("debt_musd", 0))], ["Fábrica", "Nível %d" % int(o.get("factory_level", 1))], ["Objetivo", obj],
		["Detalhe · IA", "%s · %s" % [{"essential": "Essencial", "advanced": "Avançado"}[spec["detail"]], {"easy": "Fácil", "normal": "Normal", "hard": "Difícil"}[spec["ai_difficulty"]]]]]
	for r: Array in rows:
		var h := HBoxContainer.new()
		h.custom_minimum_size = Vector2(0, 40)
		var k := UiStyle.g_label(r[0], 15, UiStyle.G_TEXT_2)
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(k)
		h.add_child(UiStyle.g_label(String(r[1]), 15, UiStyle.G_TEXT, "black"))
		sv.add_child(h)
		var line := ColorRect.new()
		line.color = Color(1, 1, 1, 0.07)
		line.custom_minimum_size = Vector2(0, 1)
		sv.add_child(line)


# --- 4 · pilotos ------------------------------------------------------------------------

func _build_drivers() -> void:
	var left := ScreenKit.g_card(Color(1, 1, 1, 0.04), 20, 0, 0)
	_content.add_child(left)
	left.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	left.offset_right = 740
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	left.add_child(v)
	var head := HBoxContainer.new()
	var pad := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 14)
	pad.add_child(head)
	v.add_child(pad)
	var seg := ScreenKit.segmented([["all", "Todos"], ["F2", "F2"], ["F3", "F3"]], _filter, func(f: String) -> void:
		_filter = f
		_fill_pool())
	seg.custom_minimum_size = Vector2(300, 0)
	head.add_child(seg)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	var count := UiStyle.g_label("%d pilotos reais · F2 e F3 2026" % Campaign.feeder_drivers().size(), 14, UiStyle.G_TEXT_3)
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(count)
	var scroll := DragScroll.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_pool_list = VBoxContainer.new()
	_pool_list.add_theme_constant_override("separation", 0)
	_pool_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_pool_list)
	_slots = VBoxContainer.new()
	_slots.add_theme_constant_override("separation", 14)
	_content.add_child(_slots)
	_slots.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	_slots.offset_left = -420
	_fill_pool()
	_fill_slots()


func _fill_pool() -> void:
	for c in _pool_list.get_children():
		c.queue_free()
	var pool := Campaign.feeder_drivers().filter(func(d: Dictionary) -> bool: return _filter == "all" or d["category"] == _filter)
	pool.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["rating"]) > int(b["rating"]))
	var chosen: Array = spec["drivers"]
	for d: Dictionary in pool:
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 46)
		var on := chosen.has(d["id"])
		var bg := Color(Color(spec["color"]), 0.3) if on else Color(0, 0, 0, 0)
		for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
			var st := UiStyle.g_box(bg if s == "normal" else Color(1, 1, 1, 0.06), 0, 16, 0)
			st.border_color = Color(1, 1, 1, 0.07)
			st.border_width_bottom = 1
			b.add_theme_stylebox_override(s, st)
		var h := HBoxContainer.new()
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_theme_constant_override("separation", 14)
		b.add_child(h)
		h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		h.offset_left = 16
		h.offset_right = -16
		h.add_child(_cat_badge(d["category"]))
		for col: Array in [[d["name"], 0, "black", UiStyle.G_TEXT, 16], [d["series_team"], 190, "semi", UiStyle.G_TEXT_2, 14],
				[d["nationality"], 130, "semi", UiStyle.G_TEXT_2, 14], [str(int(d["rating"])), 50, "black", UiStyle.G_TEXT, 18]]:
			var l := UiStyle.g_label(col[0], col[4], col[3], col[2])
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			l.clip_text = true
			if int(col[1]) == 0:
				l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			else:
				l.custom_minimum_size = Vector2(col[1], 0)
			if col[0] == str(int(d["rating"])):
				l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			h.add_child(l)
		var id: String = d["id"]
		b.pressed.connect(_toggle_driver.bind(id))
		_pool_list.add_child(b)


func _cat_badge(cat: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(40, 0)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.RED if cat == "F2" else Color("#1868DB"), 8, 6, 2))
	var l := UiStyle.g_label(cat, 13, Color.WHITE, "black")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


func _toggle_driver(id: String) -> void:
	var chosen: Array = spec["drivers"]
	if chosen.has(id):
		chosen.erase(id)
	elif chosen.size() < 2:
		chosen.append(id)
	else:
		chosen[1] = id  # lista cheia: troca o 2º piloto
	_fill_pool()
	_fill_slots()
	_validate()


func _fill_slots() -> void:
	for c in _slots.get_children():
		c.queue_free()
	_slots.add_child(UiStyle.g_caption("Seus pilotos"))
	var chosen: Array = spec["drivers"]
	for i in 2:
		if i < chosen.size():
			var d: Dictionary = {}
			for f: Dictionary in Campaign.feeder_drivers():
				if f["id"] == chosen[i]:
					d = f
			if d.is_empty():  # piloto que saiu da lista (ex.: dados atualizados): o lugar fica vago
				continue
			var b := Button.new()
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(0, 96)
			b.add_theme_stylebox_override("normal", UiStyle.g_box(UiStyle.G_SURFACE, 20, 0, 0))
			b.add_theme_stylebox_override("hover", UiStyle.g_box(UiStyle.G_SURFACE_HOVER, 20, 0, 0))
			b.add_theme_stylebox_override("pressed", UiStyle.g_box(UiStyle.G_SURFACE_PRESS, 20, 0, 0))
			var v := VBoxContainer.new()
			v.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.alignment = BoxContainer.ALIGNMENT_CENTER
			b.add_child(v)
			v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			v.offset_left = 20
			v.offset_right = -20
			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 10)
			h.add_child(_cat_badge(d["category"]))
			var n := UiStyle.g_label(d["name"], 22, UiStyle.G_TEXT, "black")
			n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(n)
			h.add_child(UiStyle.g_label(str(int(d["rating"])), 24, UiStyle.G_TEXT, "black"))
			v.add_child(h)
			v.add_child(UiStyle.g_label("%s · vinha da %s · toque para tirar" % [d["nationality"], d["series_team"]], 13, UiStyle.G_TEXT_2))
			b.pressed.connect(_toggle_driver.bind(String(d["id"])))
			_slots.add_child(b)
		else:
			var empty := PanelContainer.new()
			var st := UiStyle.g_box(Color(0, 0, 0, 0), 20, 20, 18)
			st.border_color = Color(1, 1, 1, 0.18)
			st.set_border_width_all(2)
			empty.add_theme_stylebox_override("panel", st)
			var v := VBoxContainer.new()
			v.add_child(UiStyle.g_label("Escolha o %dº piloto" % (i + 1), 22, UiStyle.G_TEXT_2, "black"))
			v.add_child(UiStyle.g_label("Toque num nome da lista", 13, UiStyle.G_TEXT_3))
			empty.add_child(v)
			_slots.add_child(empty)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if step > 0:
			_go(step - 1)
		else:
			Session.open_campaign()
