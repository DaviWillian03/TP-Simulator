extends Control
## Configuração do Grande Prêmio — direção Garagem (mockup design/mockups/v3-1-garagem-gp.html).
##
## Destaque: o circuito escolhido (traçado iluminado, nome e números grandes). Embaixo, o
## calendário como carrossel de cartões; à direita, as condições em controles grandes e a ação
## principal. As escolhas ficam no Session e são preservadas ao voltar.

const WEATHER := [["realistic", "Realista", "globe"], ["dry", "Seco", "sun"], ["rain", "Chuva", "rain"], ["variable", "Variável", "mixed"]]
const FORMATS := [["full", "Fim de semana"], ["race_only", "Só a corrida"]]
const MONTHS := ["", "JAN", "FEV", "MAR", "ABR", "MAI", "JUN", "JUL", "AGO", "SET", "OUT", "NOV", "DEZ"]

var _calendar: Array = []
var _page: Dictionary
var _rows: Dictionary = {}  # id do circuito -> cartão (Button) do carrossel
var _card_group := ButtonGroup.new()
var _scroll: ScrollContainer
var _outline: TrackOutline
var _badge_box: HBoxContainer
var _gp_title: Label
var _gp_sub: Label
var _stats: GridContainer
var _laps: Label
var _team_pill: PanelContainer
var _go: CutButton


func _ready() -> void:
	_calendar = GameData.load_json(GameData.DATA_DIR + "calendar_2026.json")["rounds"]
	_page = ScreenKit.garage_page(self, Session.player_team)
	var bd: GarageBackdrop = _page["backdrop"]
	bd.floor_ratio = 1.0
	bd.show_lamps = false
	bd.cone_x = -1.0
	bd.glow_center = Vector2(0.52, 0.42)
	bd.glow_radius = Vector2(0.40, 0.48)
	bd.set_glow(UiStyle.team_color(Session.player_team), 0.28)
	var layer: Control = _page["layer"]

	# cabeçalho
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UiStyle.SP_L)
	var back := ScreenKit.round_button("back", 52, "Voltar")
	back.pressed.connect(Session.go_to_title)
	head.add_child(back)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -2)
	titles.add_child(UiStyle.g_caption("Grande Prêmio · temporada 2026"))
	titles.add_child(UiStyle.g_label("ESCOLHA O FIM DE SEMANA", 30, UiStyle.G_TEXT, "black"))
	head.add_child(titles)
	ScreenKit.place(head, layer, Control.PRESET_TOP_LEFT, Vector2(44, 26))

	# destaque: traçado iluminado
	_outline = TrackOutline.new()
	_outline.line_color = Color("#f4f7ff")
	_outline.line_width = 9.0
	_outline.glow_color = Color("#6eaaff", 0.9)
	_outline.grid = true
	_outline.start_dot = true
	_outline.pad = 30.0
	ScreenKit.place(_outline, layer, Control.PRESET_TOP_LEFT, Vector2(370, 102), Vector2(480, 400))

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", UiStyle.SP_S)
	_badge_box = HBoxContainer.new()
	info.add_child(_badge_box)
	_gp_title = UiStyle.g_label("", UiStyle.FS_DISPLAY, UiStyle.G_TEXT, "black")
	_gp_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_gp_title.custom_minimum_size = Vector2(430, 0)
	_gp_title.add_theme_constant_override("line_spacing", -8)
	info.add_child(_gp_title)
	_gp_sub = UiStyle.g_label("", UiStyle.FS_BODY, UiStyle.G_TEXT_2)
	info.add_child(_gp_sub)
	ScreenKit.place(info, layer, Control.PRESET_TOP_LEFT, Vector2(44, 132), Vector2(430, 0))
	_stats = GridContainer.new()
	_stats.columns = 2
	_stats.add_theme_constant_override("h_separation", 30)
	_stats.add_theme_constant_override("v_separation", 18)
	ScreenKit.place(_stats, layer, Control.PRESET_TOP_LEFT, Vector2(44, 372), Vector2(400, 0))

	# condições
	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", UiStyle.SP_S)
	ScreenKit.place(panel, layer, Control.PRESET_TOP_RIGHT, Vector2(-40, 92), Vector2(360, 0))
	panel.add_child(UiStyle.g_caption("Sua equipe"))
	var team_row := HBoxContainer.new()
	team_row.add_theme_constant_override("separation", UiStyle.SP_S)
	_team_pill = ScreenKit.team_pill(Session.player_team)
	team_row.add_child(_team_pill)
	var swap := ScreenKit.round_button("swap", UiStyle.TOUCH_MIN + 4, "Trocar equipe")
	swap.pressed.connect(func() -> void: ScreenKit.open_team_picker(self, _on_team_changed))
	team_row.add_child(swap)
	panel.add_child(team_row)
	panel.add_child(_gap(4))
	panel.add_child(UiStyle.g_caption("Duração da corrida"))
	panel.add_child(ScreenKit.segmented([[0.25, "25%"], [0.5, "50%"], [1.0, "100%"]], Session.duration_pct, func(v: float) -> void:
		Session.duration_pct = v
		_refresh_laps()))
	_laps = UiStyle.g_label("", UiStyle.FS_SMALL, UiStyle.G_TEXT_2)
	panel.add_child(_laps)
	panel.add_child(UiStyle.g_caption("Clima"))
	panel.add_child(ScreenKit.choice_tiles(WEATHER, Session.gp_weather, func(v: String) -> void: Session.gp_weather = v))
	panel.add_child(_gap(4))
	panel.add_child(UiStyle.g_caption("Formato"))
	panel.add_child(ScreenKit.segmented(FORMATS, Session.gp_format, func(v: String) -> void:
		Session.gp_format = v
		_refresh_cta()))
	panel.add_child(_gap(6))
	_go = CutButton.new()
	_go.pressed.connect(Session.start_gp)
	panel.add_child(_go)
	_refresh_cta()

	# calendário em carrossel
	_scroll = ScrollContainer.new()
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	layer.add_child(_scroll)
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_scroll.offset_left = 0
	_scroll.offset_top = -124
	_scroll.offset_bottom = -16
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", UiStyle.SP_M)
	_scroll.add_child(cards)
	var start_pad := Control.new()
	start_pad.custom_minimum_size = Vector2(UiStyle.SP_XXL - UiStyle.SP_M, 0)
	cards.add_child(start_pad)
	for r: Dictionary in _calendar:
		cards.add_child(_card(r))
	var end_pad := Control.new()
	end_pad.custom_minimum_size = Vector2(120, 0)
	cards.add_child(end_pad)
	var fade := TextureRect.new()  # indica que o carrossel continua
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(UiStyle.G_BG, 0.0), UiStyle.G_BG])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	fade.texture = gt
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ScreenKit.place(fade, layer, Control.PRESET_BOTTOM_RIGHT, Vector2.ZERO, Vector2(150, 140))
	var fade_l := TextureRect.new()
	fade_l.texture = gt
	fade_l.flip_h = true
	fade_l.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ScreenKit.place(fade_l, layer, Control.PRESET_BOTTOM_LEFT, Vector2.ZERO, Vector2(60, 140))

	_select(Session.circuit_id if _rows.has(Session.circuit_id) else _calendar[0]["id"])
	_center_selected.call_deferred()
	layer.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(layer, "modulate:a", 1.0, 0.18)


func _gap(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


# --- calendário -------------------------------------------------------------------------

func _card(r: Dictionary) -> Button:
	var circuit := GameData.circuit(r["id"])
	var b := Button.new()
	b.toggle_mode = true
	b.button_group = _card_group
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(176, 108)
	var light := UiStyle.g_box(UiStyle.G_LIGHT, UiStyle.R_TILE, 14, 10)
	light.border_width_top = 4
	light.border_color = UiStyle.team_color(Session.player_team)
	b.add_theme_stylebox_override("normal", UiStyle.g_box(UiStyle.G_SURFACE, UiStyle.R_TILE, 14, 10))
	b.add_theme_stylebox_override("hover", UiStyle.g_box(UiStyle.G_SURFACE_HOVER, UiStyle.R_TILE, 14, 10))
	b.add_theme_stylebox_override("pressed", light)
	b.add_theme_stylebox_override("hover_pressed", light)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 14
	v.offset_top = 10
	var date: String = r["date"]
	var cap := UiStyle.g_caption("RD %d · %s %s" % [int(r["round"]), date.substr(8, 2), MONTHS[int(date.substr(5, 2))]])
	var city := UiStyle.g_label(circuit.get("city", circuit.get("short_name", "")), 17, UiStyle.G_TEXT, "black")
	city.custom_minimum_size = Vector2(150, 0)
	city.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(cap)
	v.add_child(city)
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 4)
	if r.get("sprint", false):
		chips.add_child(_chip("Sprint", UiStyle.RED, Color.WHITE))
	if r.get("night", false):
		chips.add_child(_chip("Noite", Color("#26324a"), Color("#ffd36b")))
	v.add_child(chips)
	var mini := TrackOutline.new()
	mini.line_color = Color("#c9d0db")
	mini.line_width = 3.0
	mini.pad = 4.0
	mini.set_circuit(circuit)
	b.add_child(mini)
	mini.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE)
	mini.custom_minimum_size = Vector2(62, 50)
	mini.offset_left = -72
	mini.offset_top = -58
	mini.offset_right = -10
	mini.offset_bottom = -8
	for l: Label in [cap, city]:
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var paint := func() -> void:
		var on := b.button_pressed
		city.add_theme_color_override("font_color", UiStyle.G_INK if on else UiStyle.G_TEXT)
		cap.add_theme_color_override("font_color", UiStyle.G_INK_2 if on else UiStyle.G_TEXT_3)
		mini.line_color = UiStyle.G_INK if on else Color("#c9d0db")
		mini.queue_redraw()
	b.toggled.connect(func(on: bool) -> void:
		paint.call()
		if on:
			_select(r["id"]))
	paint.call()
	ScreenKit.press_feedback(b)
	_rows[r["id"]] = b
	return b


func _chip(text: String, bg: Color, fg: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(bg, 9, 7, 1))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UiStyle.g_caption(text, fg)
	l.add_theme_font_size_override("font_size", 11)
	p.add_child(l)
	return p


func _center_selected() -> void:
	var b: Button = _rows.get(Session.circuit_id)
	if b:
		_scroll.scroll_horizontal = int(maxf(0.0, b.position.x - _scroll.size.x / 2.0 + b.size.x / 2.0))


# --- circuito escolhido -----------------------------------------------------------------

func _select(circuit_id: String) -> void:
	Session.circuit_id = circuit_id
	var b: Button = _rows[circuit_id]
	if not b.button_pressed:
		b.button_pressed = true
		return  # o sinal "toggled" chama _select de novo
	var c := GameData.circuit(circuit_id)
	var r: Dictionary = {}
	for x: Dictionary in _calendar:
		if x["id"] == circuit_id:
			r = x
	_outline.set_circuit(c)
	for ch in _badge_box.get_children():
		ch.queue_free()
	var date: String = r.get("date", "")
	_badge_box.add_child(ScreenKit.badge("RD %d · %s %s" % [int(r.get("round", 0)), date.substr(8, 2), MONTHS[int(date.substr(5, 2))]],
		UiStyle.team_color(Session.player_team), "flag"))
	var title := String(c["grand_prix"]).to_upper()
	_gp_title.text = title
	_gp_title.add_theme_font_size_override("font_size", UiStyle.FS_DISPLAY if title.length() <= 16 else 40)
	var fmt := "fim de semana sprint" if c.get("sprint", false) else "fim de semana normal"
	if c.get("night", false):
		fmt += " · noturna"
	_gp_sub.text = "%s\n%s, %s · %s" % [c["name"], c["short_name"], c.get("country", ""), fmt]
	for ch in _stats.get_children():
		ch.queue_free()
	var diff := float(c["overtaking_difficulty"])
	var ov := "FÁCIL" if diff < 0.3 else ("MÉDIA" if diff < 0.6 else "DIFÍCIL")
	_stats.add_child(ScreenKit.stat(String.num(float(c["length_m"]) / 1000.0, 3).replace(".", ","), "km"))
	_stats.add_child(ScreenKit.stat(str(int(c["laps"])), "voltas"))
	_stats.add_child(ScreenKit.stat("%d%%" % roundi(float(c["rain_probability"]) * 100), "chance de chuva"))
	_stats.add_child(ScreenKit.stat(ov, "ultrapassagem"))
	_refresh_laps()


func _refresh_laps() -> void:
	var laps := int(GameData.circuit(Session.circuit_id).get("laps", 0))
	_laps.text = "%d voltas na corrida" % maxi(3, roundi(laps * Session.duration_pct))


func _refresh_cta() -> void:
	_go.text = "COMEÇAR CORRIDA" if Session.gp_format == "race_only" else "COMEÇAR FIM DE SEMANA"


func _on_team_changed(team_id: String) -> void:
	ScreenKit.update_team_pill(_team_pill, team_id)
	var color := UiStyle.team_color(team_id)
	(_page["backdrop"] as GarageBackdrop).set_glow(color, 0.28)
	for b: Button in _rows.values():
		var st: StyleBoxFlat = b.get_theme_stylebox("pressed").duplicate()
		st.border_color = color
		b.add_theme_stylebox_override("pressed", st)
		b.add_theme_stylebox_override("hover_pressed", st)
	_select(Session.circuit_id)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:  # botão "voltar" do Android
		Session.go_to_title()
