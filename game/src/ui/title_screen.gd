extends Control
## Tela inicial (estilo revista): logo, modos de jogo (Grande Prêmio; os outros em construção)
## e corrida rápida.

const LOGO := preload("res://assets/branding/logo-light.svg")

var _team_group := ButtonGroup.new()
var _duration_group := ButtonGroup.new()
var _team_info: Label


func _ready() -> void:
	theme = UiStyle.make_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiStyle.PAPER
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 40
	root.offset_top = 22
	root.offset_right = -40
	root.offset_bottom = -18
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	# cabeçalho: logo + edição
	var mast := HBoxContainer.new()
	var logo := TextureRect.new()
	logo.texture = LOGO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	logo.custom_minimum_size = Vector2(360, 140)
	mast.add_child(logo)
	mast.add_child(UiStyle.hspacer())
	var edition := VBoxContainer.new()
	edition.alignment = BoxContainer.ALIGNMENT_END
	var season := UiStyle.label("TEMPORADA 2026", 40, UiStyle.RED, true)
	season.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	edition.add_child(season)
	var sub := UiStyle.caption("Gestão de automobilismo · 11 equipes · 22 pilotos")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	edition.add_child(sub)
	mast.add_child(edition)
	root.add_child(mast)
	root.add_child(UiStyle.rule(UiStyle.RULE_THICK))

	# modos de jogo (ainda em construção)
	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 12)
	var gp := UiStyle.accent(UiStyle.button("Grande Prêmio ▶"))
	gp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gp.custom_minimum_size = Vector2(0, 44)
	gp.add_theme_font_size_override("font_size", 16)
	gp.pressed.connect(Session.open_gp_setup)
	modes.add_child(gp)
	for m: String in ["Campanha", "Corrida Caótica"]:
		var b := UiStyle.button("%s — em construção" % m)
		b.disabled = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 44)
		modes.add_child(b)
	root.add_child(modes)
	root.add_child(UiStyle.rule(UiStyle.RULE_MID))

	# corrida rápida
	var head := HBoxContainer.new()
	head.add_child(UiStyle.label("CORRIDA RÁPIDA", 28, UiStyle.INK, true))
	var where := UiStyle.caption("GP de São Paulo · Interlagos")
	where.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(where)
	root.add_child(head)
	root.add_child(UiStyle.caption("Escolha sua equipe", UiStyle.MUTED))

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	root.add_child(grid)
	for t: Dictionary in GameData.teams():
		var b := UiStyle.button(t["name"], true, _team_group)
		b.icon = TeamEmblems.get_texture(t["id"])
		b.expand_icon = false
		b.add_theme_constant_override("icon_max_width", 24)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_override("font", UiStyle.HEAVY_FONT)
		b.add_theme_font_size_override("font_size", 14)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 50)
		b.set_meta("team_id", t["id"])
		b.button_pressed = t["id"] == Session.player_team
		grid.add_child(b)

	_team_info = UiStyle.label("", 20, UiStyle.INK, true)
	root.add_child(_team_info)
	_team_group.pressed.connect(func(_b: BaseButton) -> void: _update_team_info())
	_update_team_info()

	var push_down := Control.new()
	push_down.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(push_down)
	root.add_child(UiStyle.rule(UiStyle.RULE_MID))
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 8)
	var dur := UiStyle.caption("Duração", UiStyle.MUTED)
	dur.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bottom.add_child(dur)
	var laps := int(GameData.circuit(Session.circuit_id)["laps"])
	for pct: float in [0.25, 0.5, 1.0]:
		var b := UiStyle.button("%d%% · %d voltas" % [roundi(pct * 100), maxi(3, roundi(laps * pct))], true, _duration_group)
		b.set_meta("pct", pct)
		b.custom_minimum_size = Vector2(150, 44)
		b.button_pressed = is_equal_approx(pct, Session.duration_pct)
		bottom.add_child(b)
	bottom.add_child(UiStyle.hspacer())
	var go := UiStyle.accent(UiStyle.button("Largar ▶"))
	go.custom_minimum_size = Vector2(220, 52)
	go.add_theme_font_size_override("font_size", 20)
	go.pressed.connect(_on_start)
	bottom.add_child(go)
	root.add_child(bottom)
	var foot := UiStyle.caption("Primeiro marco jogável · emblemas originais — logos reais podem ser importados pelo jogador", UiStyle.MUTED)
	root.add_child(foot)


## Mostra os pilotos e o motor da equipe selecionada.
func _update_team_info() -> void:
	var btn := _team_group.get_pressed_button()
	if btn == null:
		_team_info.text = ""
		return
	var team_id: String = btn.get_meta("team_id")
	var names: Array[String] = []
	for d: Dictionary in GameData.drivers():
		if d["team"] == team_id:
			names.append("#%d %s" % [int(d["number"]), d["name"]])
	var team := GameData.team_by_id(GameData.teams(), team_id)
	_team_info.text = "Seus pilotos: %s   ·   Motor %s" % ["  e  ".join(names), team["power_unit"]]


func _on_start() -> void:
	var team_btn := _team_group.get_pressed_button()
	var dur_btn := _duration_group.get_pressed_button()
	if team_btn:
		Session.player_team = team_btn.get_meta("team_id")
	if dur_btn:
		Session.duration_pct = dur_btn.get_meta("pct")
	Session.start_race()
