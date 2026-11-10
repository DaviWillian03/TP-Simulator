extends Control
## Entrada da campanha — direção Garagem (mockup design/mockups/v5-1-campanha-entrada.html).
## Duas escolhas grandes: assumir uma equipe real ou criar a própria (12ª do grid). Se houver
## campanha salva, um atalho para continuar aparece no topo.

var _real_car: CarHero


func _ready() -> void:
	var page := ScreenKit.garage_page(self, "custom")
	var bd: GarageBackdrop = page["backdrop"]
	bd.floor_ratio = 1.0
	bd.show_lamps = false
	bd.cone_x = -1.0
	bd.glow_center = Vector2(0.5, 0.55)
	bd.set_glow(Color("#0E7C66"), 0.26)
	var layer: Control = page["layer"]

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UiStyle.SP_L)
	var back := ScreenKit.round_button("back", 52, "Menu")
	back.pressed.connect(Session.go_to_title)
	head.add_child(back)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -2)
	titles.add_child(UiStyle.g_caption("Temporada 2026"))
	titles.add_child(UiStyle.g_label("CAMPANHA", 30, UiStyle.G_TEXT, "black"))
	head.add_child(titles)
	ScreenKit.place(head, layer, Control.PRESET_TOP_LEFT, Vector2(44, 24))

	var saved := Campaign.load_saved()
	if saved != null:
		var cont := Button.new()
		cont.text = "CONTINUAR · %s · RD %d" % [String(saved.team().get("name", "")).to_upper(), mini(saved.round + 1, 22)]
		cont.focus_mode = Control.FOCUS_NONE
		cont.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MAIN)
		cont.add_theme_font_size_override("font_size", UiStyle.fs(16))
		cont.icon = load("res://assets/icons/chevron.svg")
		cont.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cont.add_theme_constant_override("icon_max_width", 20)
		cont.pressed.connect(func() -> void: Session.start_campaign(saved))
		ScreenKit.press_feedback(cont)
		ScreenKit.place(cont, layer, Control.PRESET_TOP_RIGHT, Vector2(-44, 26))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 36)
	layer.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 44
	row.offset_right = -44
	row.offset_top = 120
	row.offset_bottom = -44

	var real := _choice(false, "Equipe real", "ASSUMIR UMA\nEQUIPE DO GRID",
		"Dirigentes, engenheiros, pilotos e nível reais da temporada 2026. Escolha entre as 11 equipes.",
		["11 equipes", "Pilotos de F1", "Metas da diretoria"], "ESCOLHER EQUIPE")
	row.add_child(real["card"])
	_real_car = real["car"]
	_real_car.set_team(Session.player_team, _first_number(Session.player_team), Color.WHITE)
	real["button"].pressed.connect(_pick_real_team)
	var mine := _choice(true, "Equipe criada · 12ª do grid", "CRIAR SUA\nPRÓPRIA EQUIPE",
		"Funde a equipe com uma das 4 origens, escolha motor, cores e pilotos da F2 e da F3, e desafie o grid.",
		["4 origens", "Motor próprio possível", "Pilotos da F2/F3"], "CRIAR EQUIPE")
	row.add_child(mine["card"])
	(mine["car"] as CarHero).set_team("custom", 7, Color("#F2A900"), {"id": "custom", "custom": true, "color": "#0E7C66", "color2": "#F2A900"})
	mine["button"].pressed.connect(Session.open_team_creator)


func _choice(light: bool, kicker: String, title: String, desc: String, pills: Array, cta: String) -> Dictionary:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_LIGHT if light else UiStyle.G_SURFACE, 24, 34, 28))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	var ink := UiStyle.G_INK if light else UiStyle.G_TEXT
	var ink2 := UiStyle.G_INK_2 if light else UiStyle.G_TEXT_2
	v.add_child(UiStyle.g_caption(kicker, ink2 if light else UiStyle.G_TEXT_3))
	var t := UiStyle.g_label(title, 44, ink, "black")
	t.add_theme_constant_override("line_spacing", -10)
	v.add_child(t)
	var d := UiStyle.g_label(desc, UiStyle.FS_BODY, ink2)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(d)
	var pr := HBoxContainer.new()
	pr.add_theme_constant_override("separation", 8)
	for p: String in pills:
		var chip := PanelContainer.new()
		chip.add_theme_stylebox_override("panel", UiStyle.g_box(Color("#e3e6eb") if light else UiStyle.G_SURFACE_HOVER, 16, 12, 5))
		chip.add_child(UiStyle.g_label(p, 13, ink))
		pr.add_child(chip)
	v.add_child(pr)
	var car := CarHero.new()
	car.custom_minimum_size = Vector2(500, 150)
	car.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(car)
	var b: Button
	if light:
		b = CutButton.new()
		b.text = cta
		b.custom_minimum_size = Vector2(260, UiStyle.TOUCH_MAIN)
	else:
		b = Button.new()
		b.text = cta
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(230, UiStyle.TOUCH_MAIN)
		b.add_theme_stylebox_override("normal", UiStyle.g_box(UiStyle.G_SURFACE_HOVER, 14, 24, 0))
		b.add_theme_stylebox_override("hover", UiStyle.g_box(UiStyle.G_SURFACE_PRESS, 14, 24, 0))
		b.add_theme_stylebox_override("pressed", UiStyle.g_box(UiStyle.G_SURFACE_PRESS, 14, 24, 0))
		b.add_theme_font_size_override("font_size", UiStyle.fs(17))
		ScreenKit.press_feedback(b)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(b)
	return {"card": card, "car": car, "button": b}


func _first_number(team_id: String) -> int:
	for d: Dictionary in GameData.drivers():
		if d["team"] == team_id:
			return int(d["number"])
	return 0


## Equipe real: abre a escolha de equipe (mockup v16-2) e de lá começa a campanha.
func _pick_real_team() -> void:
	Session.open_team_select("campaign")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.go_to_title()
