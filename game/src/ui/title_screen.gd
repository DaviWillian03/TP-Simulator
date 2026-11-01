extends Control
## Tela inicial: logo, modos de jogo (ainda em construção) e corrida rápida em Interlagos.

const LOGO := preload("res://assets/branding/logo.svg")

var _team_group := ButtonGroup.new()
var _duration_group := ButtonGroup.new()
var _team_ids: Array[String] = []


func _ready() -> void:
	theme = UiStyle.make_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiStyle.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	col.custom_minimum_size = Vector2(1000, 0)
	center.add_child(col)

	var logo := TextureRect.new()
	logo.texture = LOGO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(0, 150)
	col.add_child(logo)
	var subtitle := UiStyle.label("Gestão de automobilismo · Temporada 2026", 18, UiStyle.MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(subtitle)

	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 12)
	for m: String in ["Grande Prêmio", "Campanha", "Corrida Caótica"]:
		var b := UiStyle.button("%s\n(em construção)" % m)
		b.disabled = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 58)
		modes.add_child(b)
	col.add_child(modes)

	var quick := UiStyle.panel()
	col.add_child(quick)
	var q := VBoxContainer.new()
	q.add_theme_constant_override("separation", 10)
	quick.add_child(q)
	q.add_child(UiStyle.label("CORRIDA RÁPIDA · GP DE SÃO PAULO · INTERLAGOS", 15, UiStyle.ACCENT_2, true))
	q.add_child(UiStyle.label("Escolha sua equipe", 14, UiStyle.MUTED))

	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	q.add_child(grid)
	for t: Dictionary in GameData.teams():
		var b := UiStyle.button(t["name"], true, _team_group)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_tint_team_button(b, Color(t["color"]))
		b.set_meta("team_id", t["id"])
		b.button_pressed = t["id"] == Session.player_team
		grid.add_child(b)
		_team_ids.append(t["id"])

	var bottom := HBoxContainer.new()
	q.add_child(bottom)
	bottom.add_child(UiStyle.label("Duração", 14, UiStyle.MUTED))
	var laps := int(GameData.circuit(Session.circuit_id)["laps"])
	for pct: float in [0.25, 0.5, 1.0]:
		var b := UiStyle.button("%d%% · %d voltas" % [roundi(pct * 100), maxi(3, roundi(laps * pct))], true, _duration_group)
		b.set_meta("pct", pct)
		b.button_pressed = is_equal_approx(pct, Session.duration_pct)
		bottom.add_child(b)
	bottom.add_child(UiStyle.hspacer())
	var go := UiStyle.button("LARGAR  ▶")
	go.custom_minimum_size = Vector2(200, 48)
	go.add_theme_stylebox_override("normal", UiStyle.box(UiStyle.ACCENT, 8, UiStyle.ACCENT))
	go.add_theme_stylebox_override("hover", UiStyle.box(UiStyle.ACCENT.lightened(0.1), 8, UiStyle.ACCENT))
	go.add_theme_font_override("font", UiStyle.BOLD_FONT)
	go.pressed.connect(_on_start)
	bottom.add_child(go)

	var footer := UiStyle.label("Primeiro marco jogável · protótipo", 12, Color("#55617A"))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(footer)


func _tint_team_button(b: Button, c: Color) -> void:
	for state: String in ["normal", "hover", "pressed", "hover_pressed"]:
		var base: StyleBoxFlat = theme.get_stylebox(state, "Button").duplicate()
		base.border_width_left = 6
		base.border_color = c if state in ["normal", "hover"] else UiStyle.ACCENT
		base.content_margin_left = 12
		b.add_theme_stylebox_override(state, base)


func _on_start() -> void:
	var team_btn := _team_group.get_pressed_button()
	var dur_btn := _duration_group.get_pressed_button()
	if team_btn:
		Session.player_team = team_btn.get_meta("team_id")
	if dur_btn:
		Session.duration_pct = dur_btn.get_meta("pct")
	Session.start_race()
