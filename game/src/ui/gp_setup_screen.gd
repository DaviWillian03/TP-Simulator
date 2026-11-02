extends Control
## Configuração do Grande Prêmio (mockup m3-a): calendário 2026 à esquerda; à direita o
## traçado e os dados do circuito escolhido, a equipe, a duração, o clima e o formato.

const WEATHER := [["realistic", "Realista"], ["dry", "Seco"], ["rain", "Chuva"], ["variable", "Variável"]]
const FORMATS := [["full", "Fim de semana completo"], ["race_only", "Só a corrida"]]

var _calendar: Array = []
var _row_group := ButtonGroup.new()
var _team_group := ButtonGroup.new()
var _dur_group := ButtonGroup.new()
var _weather_group := ButtonGroup.new()
var _format_group := ButtonGroup.new()
var _outline: TrackOutline
var _gp_title: Label
var _gp_sub: Label
var _gp_info: Label
var _rows: Dictionary = {}  # id do circuito -> Button


func _ready() -> void:
	_calendar = GameData.load_json(GameData.DATA_DIR + "calendar_2026.json")["rounds"]
	var root := ScreenKit.page(self)
	var head := ScreenKit.masthead(root, "Grande Prêmio", "Escolha o fim de semana · temporada 2026", "%d GPs" % _calendar.size())
	var back := UiStyle.compact(UiStyle.button("Menu"), 13)
	back.custom_minimum_size = Vector2(70, 34)
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(Session.go_to_title)
	head["bar"].add_child(back)
	head["bar"].move_child(back, 2)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	body.add_child(_build_calendar())
	body.add_child(_build_options())
	_select(Session.circuit_id if _rows.has(Session.circuit_id) else _calendar[0]["id"])


# --- calendário -------------------------------------------------------------------------

func _build_calendar() -> Control:
	var sheet := PanelContainer.new()
	sheet.add_theme_stylebox_override("panel", UiStyle.sheet_box())
	sheet.custom_minimum_size = Vector2(470, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	sheet.add_child(v)
	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", UiStyle.box(UiStyle.INK, 0, 0))
	header.add_child(_row_cells(["RD", "GRANDE PRÊMIO", "CIRCUITO", "DATA"], UiStyle.PAPER, true))
	v.add_child(header)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 0)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for r: Dictionary in _calendar:
		var circuit := GameData.circuit(r["id"])
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = _row_group
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 25)
		b.add_theme_stylebox_override("normal", UiStyle.row_box(UiStyle.PAPER))
		b.add_theme_stylebox_override("hover", UiStyle.row_box(UiStyle.PAPER_2))
		b.add_theme_stylebox_override("pressed", UiStyle.row_box(UiStyle.INK))
		b.add_theme_stylebox_override("hover_pressed", UiStyle.row_box(UiStyle.INK))
		var date: String = r["date"]
		var cells := _row_cells([str(int(r["round"])), r["grand_prix"], circuit.get("city", circuit.get("short_name", "")),
			"%s/%s" % [date.substr(8, 2), date.substr(5, 2)]], UiStyle.INK, false, r)
		cells.set_anchors_preset(Control.PRESET_FULL_RECT)
		b.add_child(cells)
		b.set_meta("cells", cells)
		b.toggled.connect(func(on: bool) -> void:
			_paint_row(cells, UiStyle.PAPER if on else UiStyle.INK)
			if on:
				_select(r["id"]))
		_rows[r["id"]] = b
		list.add_child(b)
	return sheet


func _row_cells(texts: Array, color: Color, header: bool, r: Dictionary = {}) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 0)
	h.custom_minimum_size = Vector2(0, 24)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var widths := [34, 0, 116, 62]
	for i in texts.size():
		if i > 0:
			h.add_child(UiStyle.vsep(Color("#3d3d3d") if header else UiStyle.RULE))
		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_left", 6)
		m.add_theme_constant_override("margin_right", 6)
		m.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if widths[i] > 0:
			m.custom_minimum_size = Vector2(widths[i], 0)
		else:
			m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 6)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var l: Label = UiStyle.caption(texts[i], color) if header else UiStyle.label(texts[i], 13, color, i < 2)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if i == 2:
			l.clip_text = true  # cidade: corta se for longa (o nome do GP mantém a largura natural)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if i == 0 and not header:
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if i == 3:
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(l)
		if i == 1 and not header:
			if r.get("sprint", false):
				cell.add_child(_tag("Sprint", UiStyle.RED, Color.WHITE))
			if r.get("night", false):
				cell.add_child(_tag("Noite", UiStyle.INK, Color("#f5c400")))
		m.add_child(cell)
		h.add_child(m)
	return h


func _tag(text: String, bg: Color, fg: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.box(bg, 4, 0))
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UiStyle.label(text.to_upper(), 9, fg, true)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	return p


## Na linha escolhida o texto fica claro (fundo de tinta); as etiquetas mantêm as cores.
func _paint_row(cells: HBoxContainer, color: Color) -> void:
	for m in cells.get_children():
		if m is MarginContainer:
			var l: Label = m.get_child(0).get_child(0)
			l.add_theme_color_override("font_color", color)


# --- opções -----------------------------------------------------------------------------

func _build_options() -> Control:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	var frame := ScreenKit.card()
	frame.custom_minimum_size = Vector2(312, 206)
	_outline = TrackOutline.new()
	frame.add_child(_outline)
	top.add_child(frame)
	var info := VBoxContainer.new()
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	_gp_title = UiStyle.label("", 28, UiStyle.INK, true)
	_gp_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(_gp_title)
	_gp_sub = UiStyle.caption("")
	info.add_child(_gp_sub)
	_gp_info = UiStyle.label("", 14)
	_gp_info.add_theme_constant_override("line_spacing", 6)
	info.add_child(_gp_info)
	top.add_child(info)
	v.add_child(top)

	v.add_child(UiStyle.caption("Sua equipe", UiStyle.MUTED))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for t: Dictionary in GameData.teams():
		var b := UiStyle.button(t["name"], true, _team_group)
		b.icon = TeamEmblems.get_texture(t["id"])
		b.expand_icon = false
		b.add_theme_constant_override("icon_max_width", 20)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 13)
		b.clip_text = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 34)
		b.set_meta("id", t["id"])
		b.button_pressed = t["id"] == Session.player_team
		grid.add_child(b)
	v.add_child(grid)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 6)
	row1.add_child(_cap("Duração"))
	for pct: float in [0.25, 0.5, 1.0]:
		var b := _choice("%d%%" % roundi(pct * 100), _dur_group, pct, is_equal_approx(pct, Session.duration_pct))
		row1.add_child(b)
	row1.add_child(_gap(18))
	row1.add_child(_cap("Clima"))
	for w: Array in WEATHER:
		row1.add_child(_choice(w[1], _weather_group, w[0], w[0] == Session.gp_weather))
	v.add_child(row1)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 6)
	row2.add_child(_cap("Formato"))
	for f: Array in FORMATS:
		row2.add_child(_choice(f[1], _format_group, f[0], f[0] == Session.gp_format))
	row2.add_child(UiStyle.hspacer())
	var go := UiStyle.accent(UiStyle.button("Começar ▶"))
	go.custom_minimum_size = Vector2(194, 48)
	go.add_theme_font_size_override("font_size", 20)
	go.pressed.connect(_on_start)
	row2.add_child(go)
	v.add_child(row2)
	return v


func _cap(text: String) -> Label:
	var l := UiStyle.caption(text, UiStyle.MUTED)
	l.custom_minimum_size = Vector2(70, 0)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


func _gap(w: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 0)
	return c


func _choice(text: String, group: ButtonGroup, value: Variant, pressed: bool) -> Button:
	var b := UiStyle.button(text, true, group)
	b.set_meta("value", value)
	b.button_pressed = pressed
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 13)
	return b


func _select(circuit_id: String) -> void:
	Session.circuit_id = circuit_id
	var b: Button = _rows[circuit_id]
	if not b.button_pressed:
		b.button_pressed = true
		return  # o sinal "toggled" chama _select de novo
	var c := GameData.circuit(circuit_id)
	_outline.set_circuit(c)
	_gp_title.text = String(c["grand_prix"]).to_upper()
	_gp_sub.text = ("%s · %s" % [c["name"], c["short_name"]]).to_upper()
	var diff := float(c["overtaking_difficulty"])
	var ov := "fácil" if diff < 0.3 else ("média" if diff < 0.6 else "difícil")
	var fmt := "fim de semana sprint" if c.get("sprint", false) else "fim de semana normal"
	if c.get("night", false):
		fmt += " · corrida noturna"
	_gp_info.text = "%s km · %d voltas\nUltrapassagem: %s · Chuva: %d%% de chance\nFormato: %s" % [
		String.num(float(c["length_m"]) / 1000.0, 3).replace(".", ","), int(c["laps"]), ov,
		roundi(float(c["rain_probability"]) * 100), fmt]


func _on_start() -> void:
	var team := _team_group.get_pressed_button()
	if team:
		Session.player_team = team.get_meta("id")
	if _dur_group.get_pressed_button():
		Session.duration_pct = _dur_group.get_pressed_button().get_meta("value")
	if _weather_group.get_pressed_button():
		Session.gp_weather = _weather_group.get_pressed_button().get_meta("value")
	if _format_group.get_pressed_button():
		Session.gp_format = _format_group.get_pressed_button().get_meta("value")
	Session.start_gp()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:  # botão "voltar" do Android
		Session.go_to_title()
