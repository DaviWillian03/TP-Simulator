extends Control
## Tela inicial — direção Garagem (mockup design/mockups/v3-1-garagem-inicio.html).
##
## O carro da sua equipe sob a luz é o destaque; à esquerda, os modos em blocos de tamanhos
## diferentes (Grande Prêmio é a ação principal). Modos ainda não implementados aparecem como
## texto apagado com cadeado, sem parecer tocáveis. Equipe e corrida rápida abrem folhas.

const LOGO := preload("res://assets/branding/logo.svg")

var _page: Dictionary
var _team_pill: PanelContainer
var _car: CarHero
var _plates: HBoxContainer
var _quick_tile: Button
var _gp_tile: Button


func _ready() -> void:
	_page = ScreenKit.garage_page(self, Session.player_team)
	var layer: Control = _page["layer"]

	var logo := TextureRect.new()
	logo.texture = LOGO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	ScreenKit.place(logo, layer, Control.PRESET_TOP_LEFT, Vector2(52, 32), Vector2(190, 76))
	ScreenKit.place(UiStyle.g_caption("Temporada 2026 · 22 Grandes Prêmios"), layer, Control.PRESET_TOP_LEFT, Vector2(56, 118))

	var modes := VBoxContainer.new()
	modes.add_theme_constant_override("separation", UiStyle.SP_M)
	ScreenKit.place(modes, layer, Control.PRESET_TOP_LEFT, Vector2(52, 166), Vector2(392, 0))
	var camp := ScreenKit.mode_tile("Campanha", "Assuma uma equipe ou crie a sua", "main")
	camp.pressed.connect(Session.open_campaign)
	modes.add_child(camp)
	_gp_tile = ScreenKit.mode_tile("Grande Prêmio", "Um fim de semana avulso", "alt")
	_gp_tile.pressed.connect(Session.open_gp_setup)
	modes.add_child(_gp_tile)
	_quick_tile = ScreenKit.mode_tile("Corrida rápida", "", "alt")
	_quick_tile.pressed.connect(_open_quick_race)
	modes.add_child(_quick_tile)
	modes.add_child(ScreenKit.locked_row("Corrida Caótica"))

	var team_row := HBoxContainer.new()
	team_row.add_theme_constant_override("separation", UiStyle.SP_M)
	_team_pill = ScreenKit.team_pill(Session.player_team)
	team_row.add_child(_team_pill)
	var swap := ScreenKit.round_button("swap", UiStyle.TOUCH_MIN + 4, "Trocar equipe")
	swap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swap.pressed.connect(_open_team_picker)
	team_row.add_child(swap)
	ScreenKit.place(team_row, layer, Control.PRESET_TOP_RIGHT, Vector2(-44, 38))

	_car = CarHero.new()  # posição por proporção: centro em 69% da largura, rodas em 73% da altura
	layer.add_child(_car)
	_car.custom_minimum_size = Vector2(820, 230)
	_car.anchor_left = 0.69
	_car.anchor_right = 0.69
	_car.anchor_top = 0.736
	_car.anchor_bottom = 0.736
	_car.offset_left = -410
	_car.offset_right = 410
	_car.offset_top = -230
	_car.offset_bottom = 0
	_plates = HBoxContainer.new()
	_plates.add_theme_constant_override("separation", UiStyle.SP_XXL)
	ScreenKit.place(_plates, layer, Control.PRESET_BOTTOM_RIGHT, Vector2(-56, -36))
	_apply_team()

	layer.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(layer, "modulate:a", 1.0, 0.18)
	match Session.debug_ui:  # (capturas de tela das folhas)
		"team":
			_open_team_picker()
		"quick":
			_open_quick_race()


## Atualiza tudo o que depende da equipe: pílula, carro, números dos pilotos e brilho.
func _apply_team() -> void:
	var team_id := Session.player_team
	var color := UiStyle.team_color(team_id)
	ScreenKit.update_team_pill(_team_pill, team_id)
	(_page["backdrop"] as GarageBackdrop).set_glow(color)
	var drivers: Array[Dictionary] = []
	for d: Dictionary in GameData.drivers():
		if d["team"] == team_id:
			drivers.append(d)
	var team := GameData.team_by_id(GameData.teams(), team_id)
	var c2 := Color(team.get("color2", "#ffffff"))
	_car.set_team(team_id, int(drivers[0]["number"]) if drivers.size() > 0 else 0, c2 if c2.get_luminance() > 0.35 else Color.WHITE)
	for c in _plates.get_children():
		c.queue_free()
	for d in drivers:
		_plates.add_child(_plate(d, color))
	var circuit := GameData.circuit(Session.circuit_id)
	(_quick_tile.get_child(0).get_child(0).get_child(1) as Label).text = "%s · direto para a largada" % circuit.get("short_name", "")
	var saved := Campaign.load_saved()
	if saved != null:
		var camp: Button = (_gp_tile.get_parent() as VBoxContainer).get_child(0)
		(camp.get_child(0).get_child(0).get_child(1) as Label).text = "Continuar: %s · RD %d" % [saved.team().get("name", ""), mini(saved.round + 1, 22)]


func _plate(d: Dictionary, color: Color) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UiStyle.SP_M)
	var n := UiStyle.g_label(str(int(d["number"])), 62, Color(0, 0, 0, 0), "black")
	n.add_theme_color_override("font_outline_color", color.lightened(0.25))
	n.add_theme_constant_override("outline_size", 3)
	h.add_child(n)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_END
	v.add_theme_constant_override("separation", -2)
	v.add_child(UiStyle.g_caption(String(d["nationality"])))
	v.add_child(UiStyle.g_label(d["name"], 20, UiStyle.G_TEXT, "black"))
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(0, 8)
	v.add_child(pad)
	h.add_child(v)
	return h


# --- folhas -----------------------------------------------------------------------------

func _open_team_picker() -> void:
	ScreenKit.open_team_picker(self, func(_id: String) -> void: _apply_team())


func _open_quick_race() -> void:
	var circuit := GameData.circuit(Session.circuit_id)
	var s := ScreenKit.sheet("Corrida rápida", 720)
	var body: VBoxContainer = s["body"]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UiStyle.SP_XL)
	var trk := TrackOutline.new()
	trk.line_color = UiStyle.G_TEXT
	trk.line_width = 5.0
	trk.glow_color = Color(UiStyle.team_color(Session.player_team), 0.6)
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
	go.text = "LARGAR"
	go.pressed.connect(Session.start_race)
	body.add_child(go)
	add_child(s["root"])
