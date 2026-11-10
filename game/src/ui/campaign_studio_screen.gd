extends Control
## Estúdio de design (mockups v18 aprovados, 2026-11-04; P9). Abas: Pintura (camadas recortadas na carroceria, cores,
## acabamentos — só visual), Patrocínios (zonas do carro com a marca e o valor), Capacete, Logo (equipe criada) e
## Especiais (até 3 pinturas para GPs escolhidos). "Gerar pintura" monta uma pintura automática com as cores da equipe.

const TABS := [["paint", "Pintura"], ["sponsors", "Patrocínios"], ["helmet", "Capacete"], ["logo", "Logo"], ["specials", "Especiais"]]
const ICON_TOOLS := [["left", "back", "Mover para trás"], ["right", "chevron", "Mover para a frente"], ["rotate", "undo", "Girar"],
	["mirror", "swap", "Espelhar"], ["wider", "plus", "Mais larga"], ["thinner", "minus", "Mais fina"], ["delete", "close", "Apagar camada"]]

var campaign: Campaign
var livery: Livery
var _layer: Control
var _tab := "paint"
var _target := -1  ## -1 = pintura principal; 0..2 = especial
var _sel := -1  ## camada escolhida (-1 = base)
var _content: Control
var _toasts: ToastFeed
var _tabs_box: PanelContainer


func _ready() -> void:
	campaign = Session.campaign
	if campaign == null:
		Session.open_campaign.call_deferred()
		return
	livery = campaign.livery
	for a: String in OS.get_cmdline_user_args():  # (capturas) --tab=<aba>
		if a.begins_with("--tab="):
			_tab = a.trim_prefix("--tab=")
	var team := campaign.team()
	var page := ScreenKit.garage_page(self, campaign.player_team)
	(page["backdrop"] as GarageBackdrop).set_glow(Color(team["color"]), 0.22)
	_layer = page["layer"]
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UiStyle.SP_L)
	var back := ScreenKit.round_button("back", 52, "Voltar à sede")
	back.pressed.connect(Session.open_campaign_hub)
	head.add_child(back)
	head.add_child(TeamEmblems.make_rect(campaign.player_team, 44))
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -2)
	titles.add_child(UiStyle.g_caption("%s · carro %d" % [team["name"], campaign.season]))
	titles.add_child(UiStyle.g_label("ESTÚDIO DE DESIGN", 26, UiStyle.G_TEXT, "black"))
	head.add_child(titles)
	ScreenKit.place(head, _layer, Control.PRESET_TOP_LEFT, Vector2(44, 20))
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", 10)
	var gen := ScreenKit.glass_pill_button("Gerar pintura")
	gen.icon = load("res://assets/icons/bolt.svg")
	gen.add_theme_constant_override("icon_max_width", 18)
	gen.pressed.connect(_generate)
	acts.add_child(gen)
	var save := CutButton.new()
	save.text = "SALVAR"
	save.custom_minimum_size = Vector2(170, 52)
	save.add_theme_font_size_override("font_size", UiStyle.fs(17))
	save.pressed.connect(_save)
	acts.add_child(save)
	ScreenKit.place(acts, _layer, Control.PRESET_TOP_RIGHT, Vector2(-44, 22))
	ScreenKit.campaign_nav(_layer, "studio")
	_toasts = ToastFeed.new()
	ScreenKit.place(_toasts, _layer, Control.PRESET_TOP_LEFT, Vector2(560, 150), Vector2(300, 0))
	_refresh()


func _paint() -> Dictionary:
	if _target >= 0 and _target < livery.specials.size():
		return livery.specials[_target]["paint"]
	return livery.main


func _refresh() -> void:
	if _tabs_box != null:
		_tabs_box.queue_free()
	var opts: Array = []
	for t: Array in TABS:
		opts.append([t[0], ("%s · %d/3" % [t[1], livery.specials.size()]) if t[0] == "specials" else t[1]])
	_tabs_box = ScreenKit.segmented(opts, _tab, func(v: Variant) -> void: _tab = String(v); _refresh())
	ScreenKit.place(_tabs_box, _layer, Control.PRESET_TOP_LEFT, Vector2(44, 86))
	if _content != null:
		_content.queue_free()
	_content = Control.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_content)
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	match _tab:
		"sponsors":
			_build_sponsors()
		"helmet":
			_build_helmet()
		"logo":
			_build_logo()
		"specials":
			_build_specials()
		_:
			_build_paint()
	_toasts.move_to_front()


func _panel(pos: Vector2, w: float) -> VBoxContainer:
	var card := ScreenKit.g_card(Color(0.03, 0.035, 0.047, 0.74), 20, 12, 12)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	card.add_child(v)
	ScreenKit.place(card, _content, Control.PRESET_TOP_LEFT, pos, Vector2(w, 0))
	return v


func _car(pos: Vector2, w: float, paint: Dictionary) -> void:
	var tex := Livery.car_texture(paint)
	var h := w * 0.28
	for refl in [false, true]:
		var r := TextureRect.new()
		r.texture = tex
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		r.flip_v = refl
		r.modulate = Color(1, 1, 1, 0.15 if refl else 1.0)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_content.add_child(r)
		r.position = pos + Vector2(0, h - 6 if refl else 0)
		r.size = Vector2(w, h)
	var ids := campaign.team_driver_ids(campaign.player_team)
	if not ids.is_empty():
		var has_num := (paint.get("layers", []) as Array).any(func(l: Dictionary) -> bool: return l["kind"] == "number")
		if has_num:
			var col := "#FFFFFF"
			for l: Dictionary in paint["layers"]:
				if l["kind"] == "number":
					col = String(l["color"])
			var num := UiStyle.g_label(str(int(_driver(ids[0]).get("number", 0))), int(w * 0.06), Color(col), "black")
			num.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_content.add_child(num)
			num.position = pos + Vector2(w * 0.655, h * 0.5)


func _driver(id: String) -> Dictionary:
	for d: Dictionary in campaign.drivers():
		if d["id"] == id:
			return d
	return {}


# --- Pintura ----------------------------------------------------------------------------------------

func _build_paint() -> void:
	var paint := _paint()
	var left := _panel(Vector2(44, 150), 240)
	left.add_child(UiStyle.g_caption("Camadas · %d de %d%s" % [(paint["layers"] as Array).size() + 1, Livery.MAX_LAYERS + 1,
		"" if _target < 0 else " · " + String(livery.specials[_target]["name"])]))
	left.add_child(_layer_row(-1, "Base", "cor sólida · %s" % String(Livery.FINISH_NAMES.get(paint.get("finish", "gloss"), "")).to_lower(), String(paint["base"])))
	var layers: Array = paint["layers"]
	for i in layers.size():
		var l: Dictionary = layers[i]
		left.add_child(_layer_row(i, String(Livery.KIND_NAMES.get(l["kind"], l["kind"])), _layer_sub(l), String(l["color"])))
	var add := ScreenKit.glass_pill_button("+ Camada")
	add.disabled = layers.size() >= Livery.MAX_LAYERS
	add.pressed.connect(func() -> void:
		ScreenKit.popover(self, add, "Nova camada", [["stripe", "Faixa"], ["gradient", "Degradê"], ["pattern", "Hexágonos"], ["number", "Número"]], "",
			func(k: Variant) -> void:
				livery.add_layer(paint, String(k), String(paint.get("accent", "#FFFFFF")))
				_sel = (paint["layers"] as Array).size() - 1
				_refresh()))
	left.add_child(add)
	_car(Vector2(296, 250), 668, paint)
	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", 8)
	for t: Array in ICON_TOOLS:
		var b := ScreenKit.round_button(t[1], 52, t[2])
		b.disabled = _sel < 0
		b.pressed.connect(_tool.bind(t[0]))
		tools.add_child(b)
	ScreenKit.place(tools, _content, Control.PRESET_TOP_LEFT, Vector2(420, 540))
	var right := _panel(Vector2(1280 - 44 - 262, 150), 262)
	right.add_child(UiStyle.g_caption("Cor da base" if _sel < 0 else "Cor da camada"))
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	var cur := String(paint["base"]) if _sel < 0 else String(layers[_sel]["color"])
	for c: String in Livery.PALETTE + [String(campaign.team()["color"]), String(campaign.team().get("color2", "#FFFFFF"))]:
		grid.add_child(_swatch(c, c.to_upper() == cur.to_upper(), func() -> void:
			if _sel < 0:
				paint["base"] = c
			else:
				layers[_sel]["color"] = c
			_refresh()))
	right.add_child(grid)
	right.add_child(UiStyle.g_caption("Acabamento"))
	var fg := GridContainer.new()
	fg.columns = 4
	fg.add_theme_constant_override("h_separation", 6)
	fg.add_theme_constant_override("v_separation", 6)
	for f: String in Livery.FINISHES:
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.text = String(Livery.FINISH_NAMES[f])
		b.custom_minimum_size = Vector2(56, 48)
		b.clip_text = true
		var on: bool = paint.get("finish", "gloss") == f
		for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(s, UiStyle.g_box(UiStyle.G_LIGHT if on else Color(1, 1, 1, 0.06), 12, 2, 2))
		b.add_theme_color_override("font_color", UiStyle.G_INK if on else UiStyle.G_TEXT)
		b.add_theme_font_size_override("font_size", UiStyle.fs(11))
		b.pressed.connect(func() -> void: paint["finish"] = f; _refresh())
		fg.add_child(b)
	right.add_child(fg)


func _layer_sub(l: Dictionary) -> String:
	match String(l["kind"]):
		"stripe":
			return "%d° · largura %d%%" % [roundi(float(l["angle"])), roundi(float(l["width"]) * 100.0)]
		"gradient":
			return "da %s" % ("frente" if bool(l["mirror"]) else "traseira")
		"pattern":
			return "padrão · %d%%" % roundi(float(l["opacity"]) * 100.0)
	return "do piloto"


func _layer_row(i: int, title: String, sub: String, col: String) -> Button:
	var on := i == _sel
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 46)
	for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(s, UiStyle.g_box(UiStyle.G_LIGHT if on else Color(1, 1, 1, 0.04), 12, 8, 4))
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 8
	h.add_theme_constant_override("separation", 8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sw := Panel.new()
	sw.custom_minimum_size = Vector2(22, 22)
	sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var st := UiStyle.g_box(Color(col), 7, 0, 0)
	st.set_border_width_all(2)
	st.border_color = Color(1, 1, 1, 0.3)
	sw.add_theme_stylebox_override("panel", st)
	sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(sw)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -4)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(UiStyle.g_label(title, 13, UiStyle.G_INK if on else UiStyle.G_TEXT, "black"))
	v.add_child(UiStyle.g_label(sub, 11, UiStyle.G_INK_2 if on else UiStyle.G_TEXT_3, "bold"))
	h.add_child(v)
	b.add_child(h)
	b.pressed.connect(func() -> void: _sel = i; _refresh())
	return b


func _swatch(c: String, on: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(34, 34)
	var st := UiStyle.g_box(Color(c), 9, 0, 0)
	st.set_border_width_all(3 if on else 2)
	st.border_color = Color.WHITE if on else Color(1, 1, 1, 0.12)
	for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(s, st)
	b.pressed.connect(cb)
	return b


func _tool(kind: String) -> void:
	var layers: Array = _paint()["layers"]
	if _sel < 0 or _sel >= layers.size():
		return
	var l: Dictionary = layers[_sel]
	match kind:
		"left":
			l["offset"] = clampf(float(l["offset"]) - 0.1, -1.4, 1.4)
		"right":
			l["offset"] = clampf(float(l["offset"]) + 0.1, -1.4, 1.4)
		"rotate":
			l["angle"] = wrapf(float(l["angle"]) + 15.0, -75.0, 90.0)
		"mirror":
			l["mirror"] = not bool(l["mirror"])
		"wider":
			l["width"] = clampf(float(l["width"]) + 0.2, 0.3, 4.0)
			if l["kind"] == "pattern":
				l["opacity"] = clampf(float(l["opacity"]) + 0.04, 0.04, 0.5)
		"thinner":
			l["width"] = clampf(float(l["width"]) - 0.2, 0.3, 4.0)
			if l["kind"] == "pattern":
				l["opacity"] = clampf(float(l["opacity"]) - 0.04, 0.04, 0.5)
		"delete":
			layers.remove_at(_sel)
			_sel = -1
	_refresh()


func _generate() -> void:
	var t := campaign.team()
	var p := Livery.generate(String(t["color"]), String(t.get("color2", "#FFFFFF")), randi())
	if _target >= 0:
		livery.specials[_target]["paint"] = p
	else:
		livery.main = p
	_sel = -1
	_tab = "paint"
	_refresh()
	_toasts.push("Pintura gerada com as cores da equipe")


func _save() -> void:
	campaign.refresh_rating()
	campaign.save()
	_toasts.push("Pintura salva", "hot")


# --- Patrocínios ------------------------------------------------------------------------------------

func _build_sponsors() -> void:
	_car(Vector2(320, 270), 600, livery.main)
	var right := _panel(Vector2(1280 - 44 - 300, 150), 300)
	right.add_child(UiStyle.g_caption("Zonas do carro"))
	var total := 0.0
	for z: Dictionary in Sponsorship.zones():
		var c: Dictionary = campaign.sponsors.contracts.get(z["id"], {})
		var row := PanelContainer.new()
		var st := UiStyle.g_box(Color(1, 1, 1, 0.04), 12, 10, 6)
		if c.is_empty():
			st.bg_color = Color(0, 0, 0, 0)
			st.set_border_width_all(2)
			st.border_color = Color(1, 1, 1, 0.18)
		row.add_theme_stylebox_override("panel", st)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		if c.is_empty():
			h.add_child(ScreenKit.icon("plus", 18, UiStyle.G_TEXT_2))
		else:
			var plate := PanelContainer.new()
			plate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			plate.add_theme_stylebox_override("panel", UiStyle.g_box(Color.WHITE, 5, 8, 2))
			plate.add_child(UiStyle.g_label(String(c.get("brand", "")).to_upper(), 11, UiStyle.G_INK, "black"))
			h.add_child(plate)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", -3)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(UiStyle.g_label(String(z["name"]), 13, UiStyle.G_TEXT, "black"))
		v.add_child(UiStyle.g_label("livre · ver ofertas" if c.is_empty() else "visibilidade ×%s" % str(z["mult"]).replace(".", ","), 11, UiStyle.G_TEXT_3, "bold"))
		h.add_child(v)
		if not c.is_empty():
			total += float(c.get("per_race", 0.0))
			h.add_child(UiStyle.g_label("US$ %s mi" % ("%.1f" % float(c.get("per_race", 0.0))).replace(".", ","), 14, UiStyle.G_TEXT, "black"))
		row.add_child(h)
		right.add_child(row)
	var th := HBoxContainer.new()
	var tl := UiStyle.g_label("Total por corrida", 14, UiStyle.G_TEXT_2, "black")
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	th.add_child(tl)
	th.add_child(UiStyle.g_label("US$ %s mi" % ("%.1f" % total).replace(".", ","), 14, UiStyle.G_TEXT, "black"))
	right.add_child(th)
	var go := ScreenKit.glass_pill_button("Ofertas e contratos")
	go.pressed.connect(Session.open_campaign_sponsors)
	right.add_child(go)
	# pinos das zonas sobre o carro
	for z: Dictionary in Sponsorship.zones():
		var pin: Array = z.get("pin", [0.5, 0.5])
		var p := Vector2(320 + float(pin[0]) * 600, 270 + float(pin[1]) * 168)
		var has: bool = campaign.sponsors.contracts.has(z["id"])
		var chip := PanelContainer.new()
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_theme_stylebox_override("panel", UiStyle.g_box(Color(0.03, 0.035, 0.047, 0.9), 16, 10, 4))
		var ch := HBoxContainer.new()
		ch.add_theme_constant_override("separation", 6)
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(12, 12)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.RED if has else Color(1, 1, 1, 0.3), 6, 0, 0))
		ch.add_child(dot)
		ch.add_child(UiStyle.g_label(String(z["name"]), 12, UiStyle.G_TEXT, "black"))
		chip.add_child(ch)
		_content.add_child(chip)
		chip.position = p + Vector2(-110 if z["id"] == "rear_wing" else -10, -56)


# --- Capacete ----------------------------------------------------------------------------------------

func _build_helmet() -> void:
	var tex := Livery.helmet_texture(livery.helmet)
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(r)
	r.position = Vector2(300, 200)
	r.size = Vector2(440, 352)
	var right := _panel(Vector2(1280 - 44 - 360, 150), 360)
	for part: Array in [["base", "Cor do capacete"], ["stripe", "Cor do desenho"], ["visor", "Viseira"]]:
		right.add_child(UiStyle.g_caption(part[1]))
		var grid := GridContainer.new()
		grid.columns = 7
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		var cols: Array = Livery.PALETTE if part[0] != "visor" else ["#11141A", "#2B3A55", "#D4A017", "#C0C6CF", "#7B2CBF", "#E10600", "#00E1FF"]
		for c: String in cols:
			grid.add_child(_swatch(c, String(livery.helmet.get(part[0], "")).to_upper() == c.to_upper(), func() -> void:
				livery.helmet[part[0]] = c
				_refresh()))
		right.add_child(grid)
	right.add_child(UiStyle.g_caption("Desenho"))
	right.add_child(ScreenKit.segmented([["band", "Faixa"], ["crown", "Coroa"], ["split", "Metade"], ["stars", "Estrelas"]], String(livery.helmet.get("pattern", "band")),
		func(v: Variant) -> void: livery.helmet["pattern"] = String(v); _refresh()))


# --- Logo (equipe criada) -----------------------------------------------------------------------------

func _build_logo() -> void:
	var big := TeamEmblems.make_rect(campaign.player_team, 220)
	_content.add_child(big)
	big.position = Vector2(380, 230)
	var right := _panel(Vector2(1280 - 44 - 360, 150), 360)
	if campaign.mode != "created":
		return
	var ident: Dictionary = campaign.identity
	var emb: Dictionary = ident.get("emblem", {})
	right.add_child(UiStyle.g_caption("Forma"))
	var shapes: Array = []
	for s: String in CarArt.SHAPES:
		shapes.append([s, {"square": "Quadrado", "hex": "Hexágono", "circle": "Círculo", "shield": "Escudo", "diamond": "Losango"}.get(s, s)])
	right.add_child(ScreenKit.choice_tiles(shapes, String(emb.get("shape", "hex")), func(v: Variant) -> void:
		emb["shape"] = String(v)
		_apply_logo(emb)))
	for part: Array in [["color", "Cor principal"], ["color2", "Cor do contorno e das letras"]]:
		right.add_child(UiStyle.g_caption(part[1]))
		var grid := GridContainer.new()
		grid.columns = 7
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		for c: String in Livery.PALETTE:
			grid.add_child(_swatch(c, String(ident.get(part[0], "")).to_upper() == c.to_upper(), func() -> void:
				ident[part[0]] = c
				_apply_logo(emb)))
		right.add_child(grid)
	right.add_child(UiStyle.g_caption("Iniciais (até 3 letras)"))
	var le := LineEdit.new()
	le.text = String(emb.get("text", ident.get("short", "")))
	le.max_length = 3
	le.custom_minimum_size = Vector2(0, 48)
	le.text_submitted.connect(func(t: String) -> void:
		emb["text"] = t.to_upper()
		_apply_logo(emb))
	right.add_child(le)


func _apply_logo(emb: Dictionary) -> void:
	campaign.identity["emblem"] = emb
	var t := campaign.team()
	t["emblem"] = emb
	t["color"] = campaign.identity.get("color", t["color"])
	t["color2"] = campaign.identity.get("color2", t.get("color2", "#FFFFFF"))
	TeamEmblems.register_custom(t)
	_refresh()


# --- Especiais -------------------------------------------------------------------------------------------

func _build_specials() -> void:
	var v := _panel(Vector2(44, 150), 1280 - 88)
	v.add_child(UiStyle.g_caption("Pinturas especiais · até %d por temporada" % Livery.MAX_SPECIALS))
	var cal := Campaign.calendar()
	for i in livery.specials.size():
		var s: Dictionary = livery.specials[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var tex := TextureRect.new()
		tex.texture = Livery.car_texture(s["paint"])
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.custom_minimum_size = Vector2(300, 84)
		row.add_child(tex)
		var nv := VBoxContainer.new()
		nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nv.add_child(UiStyle.g_label(String(s["name"]), 18, UiStyle.G_TEXT, "black"))
		var r := int(s.get("round", -1))
		nv.add_child(UiStyle.g_label(String(cal[r]["grand_prix"]) if r >= 0 and r < cal.size() else "sem GP", 13, UiStyle.G_TEXT_2, "bold"))
		row.add_child(nv)
		var gp := ScreenKit.glass_pill_button("Trocar GP")
		gp.pressed.connect(func() -> void:
			var nr := int(s.get("round", campaign.round))
			nr = campaign.round if nr < campaign.round else nr + 1
			if nr >= cal.size():
				nr = campaign.round
			s["round"] = nr
			_refresh())
		row.add_child(gp)
		var ed := ScreenKit.glass_pill_button("Editar pintura")
		ed.pressed.connect(func() -> void: _target = i; _sel = -1; _tab = "paint"; _refresh())
		row.add_child(ed)
		var del := ScreenKit.round_button("close", 48, "Apagar")
		del.pressed.connect(func() -> void:
			livery.specials.remove_at(i)
			_target = -1
			_refresh())
		row.add_child(del)
		v.add_child(row)
	var add := CutButton.new()
	add.text = "NOVA ESPECIAL"
	add.disabled = livery.specials.size() >= Livery.MAX_SPECIALS
	add.custom_minimum_size = Vector2(260, 56)
	add.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	add.pressed.connect(func() -> void:
		livery.specials.append({"name": "Especial %d" % (livery.specials.size() + 1), "round": mini(campaign.round, cal.size() - 1),
			"paint": livery.main.duplicate(true)})
		_target = livery.specials.size() - 1
		_tab = "paint"
		_refresh())
	v.add_child(add)
	if _target >= 0:
		var back := ScreenKit.glass_pill_button("Voltar a editar a pintura principal")
		back.pressed.connect(func() -> void: _target = -1; _refresh())
		v.add_child(back)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.open_campaign_hub()
