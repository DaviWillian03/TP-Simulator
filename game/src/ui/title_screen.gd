extends Control
## Menu principal (mockup v16-1 aprovado, 2026-11-04): só o logo do jogo e os modos. A escolha de equipe fica dentro de
## cada modo (tela de escolha de equipe). Modos ainda não implementados aparecem apagados, com cadeado.

const LOGO := preload("res://assets/branding/logo.svg")

var _page: Dictionary
var _quick_tile: Button
var _gp_tile: Button
var _camp_tile: Button


func _ready() -> void:
	_page = ScreenKit.garage_page(self, Session.player_team)
	var bd: GarageBackdrop = _page["backdrop"]
	bd.set_glow(Color("#2a3346"), 0.35)
	var layer: Control = _page["layer"]

	var logo := TextureRect.new()
	logo.texture = LOGO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ScreenKit.place(logo, layer, Control.PRESET_TOP_LEFT, Vector2(420, 64), Vector2(440, 172))

	var modes := VBoxContainer.new()
	modes.add_theme_constant_override("separation", UiStyle.SP_M - 2)
	ScreenKit.place(modes, layer, Control.PRESET_TOP_LEFT, Vector2(405, 272), Vector2(470, 0))
	var saved := Campaign.load_saved()
	_camp_tile = ScreenKit.mode_tile("Campanha", ("Continuar: %s · RD %d" % [saved.team().get("name", ""), mini(saved.round + 1, 22)]) if saved != null else "Assuma uma equipe ou crie a sua", "main")
	_camp_tile.pressed.connect(Session.open_campaign)
	modes.add_child(_camp_tile)
	_gp_tile = ScreenKit.mode_tile("Grande Prêmio", "Um fim de semana avulso", "alt")
	_gp_tile.pressed.connect(Session.open_team_select.bind("gp"))
	modes.add_child(_gp_tile)
	_quick_tile = ScreenKit.mode_tile("Corrida rápida", "Escolha a duração e a equipe e largue", "alt")
	_quick_tile.pressed.connect(_open_quick_race)
	modes.add_child(_quick_tile)
	modes.add_child(ScreenKit.locked_row("Corrida Caótica"))
	ScreenKit.place(UiStyle.g_caption("Temporada 2026 · 22 Grandes Prêmios"), layer, Control.PRESET_BOTTOM_RIGHT, Vector2(-44, -34))

	layer.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(layer, "modulate:a", 1.0, 0.18)
	if Session.debug_ui == "quick":  # (captura da folha)
		_open_quick_race()


# --- folhas -----------------------------------------------------------------------------

func _open_quick_race() -> void:
	var circuit := GameData.circuit(Session.circuit_id)
	var s := ScreenKit.sheet("Corrida rápida", 720)
	var body: VBoxContainer = s["body"]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UiStyle.SP_XL)
	var trk := TrackOutline.new()
	trk.line_color = UiStyle.G_TEXT
	trk.line_width = 5.0
	trk.glow_color = Color(1, 1, 1, 0.25)
	trk.start_dot = true
	trk.custom_minimum_size = Vector2(220, 170)
	trk.set_circuit(circuit)
	row.add_child(trk)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", UiStyle.SP_S)
	info.add_child(UiStyle.g_caption(circuit.get("country", "")))
	info.add_child(UiStyle.g_label(String(circuit.get("grand_prix", "")).to_upper(), UiStyle.FS_TITLE, UiStyle.G_TEXT, "black"))
	info.add_child(UiStyle.g_label("%s · largada imediata, sem treinos" % circuit.get("short_name", ""), UiStyle.FS_BODY, UiStyle.G_TEXT_2))
	var laps_label := UiStyle.g_label("", UiStyle.FS_SMALL, UiStyle.G_TEXT_2)
	var laps := int(circuit.get("laps", 0))
	var refresh := func() -> void:
		laps_label.text = "%d voltas" % maxi(3, roundi(laps * Session.duration_pct))
	info.add_child(UiStyle.g_caption("Duração", UiStyle.G_TEXT_3))
	info.add_child(ScreenKit.segmented([[0.25, "25%"], [0.5, "50%"], [1.0, "100%"]], Session.duration_pct, func(v: float) -> void:
		Session.duration_pct = v
		refresh.call()))
	info.add_child(laps_label)
	refresh.call()
	row.add_child(info)
	body.add_child(row)
	var go := CutButton.new()
	go.text = "ESCOLHER EQUIPE"
	go.pressed.connect(Session.open_team_select.bind("quick"))
	body.add_child(go)
	add_child(s["root"])
