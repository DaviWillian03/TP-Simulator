class_name ScreenKit
extends RefCounted
## Peças repetidas nas telas do Grande Prêmio: página com fundo de papel, cabeçalho de revista,
## botões de pneu, barra de velocidade e barras de porcentagem. Tudo com as cores do UiStyle.

const COMPOUNDS := ["soft", "medium", "hard", "inter", "wet"]


## Fundo de papel + coluna principal com margens; devolve a coluna.
static func page(screen: Control) -> VBoxContainer:
	screen.theme = UiStyle.make_theme()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiStyle.PAPER
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(bg)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 16
	root.offset_top = 8
	root.offset_right = -16
	root.offset_bottom = -10
	root.add_theme_constant_override("separation", 10)
	screen.add_child(root)
	return root


## Cabeçalho: título grande, legenda em caixa alta e um destaque vermelho à direita.
## Devolve {"bar": HBox (para inserir botões), "right": Label}.
static func masthead(root: VBoxContainer, title: String, sub: String, right_text: String) -> Dictionary:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 14)
	bar.add_child(UiStyle.label(title.to_upper(), 34, UiStyle.INK, true))
	var cap := UiStyle.caption(sub)
	cap.size_flags_vertical = Control.SIZE_SHRINK_END
	cap.add_theme_constant_override("line_spacing", 0)
	var cap_box := MarginContainer.new()
	cap_box.add_theme_constant_override("margin_bottom", 8)
	cap_box.add_child(cap)
	bar.add_child(cap_box)
	bar.add_child(UiStyle.hspacer())
	var right := UiStyle.label(right_text.to_upper(), 30, UiStyle.RED, true)
	bar.add_child(right)
	root.add_child(bar)
	root.add_child(UiStyle.rule(UiStyle.RULE_THICK))
	return {"bar": bar, "right": right}


## Título de seção ("PROGRAMAÇÃO", "SEUS CARROS").
static func section(text: String) -> Label:
	return UiStyle.label(text.to_upper(), 20, UiStyle.INK, true)


## Botões de pausa e velocidade. on_change(speed: float) é chamado com 0 para pausa.
static func speed_bar(speeds: Array, current: float, on_change: Callable) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var group := ButtonGroup.new()
	var pause := UiStyle.compact(UiStyle.button("II", true, group), 14)
	pause.custom_minimum_size = Vector2(38, 34)
	pause.pressed.connect(on_change.bind(0.0))
	box.add_child(pause)
	for s: float in speeds:
		var b := UiStyle.compact(UiStyle.button("%d×" % int(s), true, group), 14)
		b.custom_minimum_size = Vector2(38, 34)
		b.button_pressed = is_equal_approx(s, current)
		b.pressed.connect(on_change.bind(s))
		box.add_child(b)
	return box


## Botões S/M/H/I/W (um grupo). Devolve {id: Button}.
static func tyre_buttons(parent: Container, tyres: TyreModel, selected: String) -> Dictionary:
	var group := ButtonGroup.new()
	var out := {}
	for id: String in COMPOUNDS:
		var c: Dictionary = tyres.compounds[id]
		var b := UiStyle.compact(UiStyle.button(c["letter"], true, group), 15)
		b.custom_minimum_size = Vector2(34, 34)
		b.add_theme_font_override("font", UiStyle.HEAVY_FONT)
		for k: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(k, Color(c["color"]))
		b.add_theme_color_override("font_outline_color", UiStyle.INK)
		b.add_theme_constant_override("outline_size", 3)
		b.tooltip_text = c["name"]
		b.button_pressed = id == selected
		parent.add_child(b)
		out[id] = b
	return out


## Linha "Aerodinâmica ▇▇▇▇░░░ 62%". Devolve {"bar": ProgressBar, "value": Label}.
static func percent_row(parent: Container, title: String) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var name := UiStyle.label(title, 13)
	name.custom_minimum_size = Vector2(96, 0)
	row.add_child(name)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = 1.0
	bar.step = 0.001
	bar.custom_minimum_size = Vector2(0, 12)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_theme_stylebox_override("background", UiStyle.box(UiStyle.BAR_BG, 0, 0))
	bar.add_theme_stylebox_override("fill", UiStyle.box(UiStyle.INK, 0, 0))
	row.add_child(bar)
	var value := UiStyle.label("", 13)
	value.custom_minimum_size = Vector2(40, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)
	parent.add_child(row)
	return {"bar": bar, "value": value}


## Caixa com contorno de tinta e margens internas (cartões das telas).
static func card(fill: Color = UiStyle.PAPER) -> PanelContainer:
	var p := PanelContainer.new()
	var st := UiStyle.outline_box(fill, UiStyle.INK, UiStyle.RULE_MID)
	st.content_margin_left = 12
	st.content_margin_right = 12
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", st)
	return p


## Relógio mm:ss.
static func clock(seconds: float) -> String:
	var s := maxi(0, ceili(seconds))
	return "%02d:%02d" % [floori(s / 60.0), s % 60]


# === Garagem ===========================================================================
# Peças da direção Garagem (tela inicial e configuração do GP já migradas).

## Página da Garagem: tema, fundo e uma camada para posicionar os elementos por âncoras.
static func garage_page(screen: Control, team_id: String) -> Dictionary:
	screen.theme = UiStyle.make_garage_theme()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiStyle.G_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(bg)
	var backdrop := GarageBackdrop.new()
	backdrop.glow_color = UiStyle.team_color(team_id)
	screen.add_child(backdrop)
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(layer)
	return {"backdrop": backdrop, "layer": layer}


## Posiciona um elemento por âncora e deslocamento (referência 1280×720).
## Degradê escuro no topo de uma tela com pista/cenário claro atrás: a barra de topo continua legível.
static func top_shade(layer: Control, height: float = 96.0) -> void:
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(0.03, 0.04, 0.055, 0.95), Color(0.03, 0.04, 0.055, 0.82), Color(0.03, 0.04, 0.055, 0.0)])
	grad.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	var shade := TextureRect.new()
	shade.texture = gt
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	shade.offset_bottom = height


## Título com a bandeira do país ao fundo, translúcida (dá para ler o nome por cima).
## Devolve {"box": Control, "title": Label, "sub": Label}.
static func flag_title(title: String, size: int, country_code: String) -> Dictionary:
	var box := PanelContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.clip_contents = true
	box.add_theme_stylebox_override("panel", UiStyle.g_box(Color(0, 0, 0, 0), 10, 10, 2))
	var path := "res://assets/flags/%s.svg" % country_code
	if country_code != "" and ResourceLoader.exists(path):
		var flag := TextureRect.new()
		flag.texture = load(path)
		flag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		flag.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		flag.modulate = Color(1, 1, 1, 0.3)
		flag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(flag)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -2)
	titles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := UiStyle.g_label(title, size, UiStyle.G_TEXT, "black")
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))  # legível sobre qualquer bandeira
	t.add_theme_constant_override("shadow_offset_y", 2)
	titles.add_child(t)
	var sub := UiStyle.g_caption("", UiStyle.G_TEXT_2)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	sub.add_theme_constant_override("shadow_offset_y", 1)
	titles.add_child(sub)
	box.add_child(titles)
	return {"box": box, "title": t, "sub": sub}


## Botão redondo escuro translúcido (para ficar legível sobre a pista).
static func glass_round_button(icon_name: String, size: int, tooltip: String = "") -> Button:
	var b := round_button(icon_name, size, tooltip)
	for st: String in ["normal", "hover"]:
		b.add_theme_stylebox_override(st, UiStyle.g_box(UiStyle.G_GLASS, size / 2, 0, 0))
	return b


## Pílula escura translúcida com texto (botões da barra de topo).
static func glass_pill_button(text: String, min_w: float = 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(min_w, 44)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for st: String in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, UiStyle.g_box(UiStyle.G_GLASS, 22, 16, 0))
	b.add_theme_font_size_override("font_size", UiStyle.fs(14))
	press_feedback(b)
	return b


## Coloca uma coluna dentro de uma lista que rola na vertical arrastando o dedo
## (para colunas que, com a letra maior, passam do fim da tela).
static func scroll_column(node: Control, parent: Control, offset: Vector2, size: Vector2) -> DragScroll:
	var sc := DragScroll.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(node)
	place(sc, parent, Control.PRESET_TOP_LEFT, offset, size)
	return sc


static func place(node: Control, parent: Control, preset: Control.LayoutPreset, offset: Vector2, min_size := Vector2.ZERO) -> Control:
	parent.add_child(node)
	if min_size != Vector2.ZERO:
		node.custom_minimum_size = min_size
	node.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE)
	# presos à direita/embaixo crescem para dentro da tela quando o conteúdo aumenta
	if node.anchor_left >= 0.5:
		node.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	if node.anchor_top >= 0.5:
		node.grow_vertical = Control.GROW_DIRECTION_BEGIN
	node.offset_left += offset.x
	node.offset_right += offset.x
	node.offset_top += offset.y
	node.offset_bottom += offset.y
	return node


## Retorno imediato ao toque: o controle encolhe 3% enquanto está pressionado.
static func press_feedback(b: BaseButton) -> void:
	b.resized.connect(func() -> void: b.pivot_offset = b.size / 2.0)
	b.button_down.connect(func() -> void: b.create_tween().tween_property(b, "scale", Vector2(0.97, 0.97), 0.06))
	b.button_up.connect(func() -> void: b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.1))


static func icon(name: String, size: int = 22, color: Color = UiStyle.G_TEXT) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load("res://assets/icons/%s.svg" % name)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(size, size)
	t.modulate = color
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## Botão redondo só com ícone (voltar, trocar equipe, fechar).
static func round_button(icon_name: String, size: int = UiStyle.TOUCH_MIN + 4, tooltip: String = "") -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(size, size)
	b.tooltip_text = tooltip
	for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
		var fill: Color = {"normal": UiStyle.G_SURFACE_HOVER, "hover": UiStyle.G_SURFACE_PRESS}.get(s, Color(1, 1, 1, 0.24))
		b.add_theme_stylebox_override(s, UiStyle.g_box(fill, size / 2, 0, 0))
	b.icon = load("res://assets/icons/%s.svg" % icon_name)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", int(size * 0.5))
	for k: String in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color"]:
		b.add_theme_color_override(k, UiStyle.G_TEXT)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	press_feedback(b)
	return b


## Bloco de modo de jogo. kind "main" (claro, faixa vermelha: a ação mais importante da tela)
## ou "alt" (superfície escura). O bloco inteiro é o botão.
static func mode_tile(title: String, sub: String, kind: String = "alt") -> Button:
	var main := kind == "main"
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 112 if main else 84)
	var fills := {"normal": UiStyle.G_LIGHT if main else UiStyle.G_SURFACE, "hover": UiStyle.G_LIGHT if main else UiStyle.G_SURFACE_HOVER,
		"pressed": UiStyle.G_LIGHT_PRESS if main else UiStyle.G_SURFACE_PRESS}
	for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
		var st := UiStyle.g_box(fills.get(s, fills["pressed"]), UiStyle.R_TILE, 20, 0)
		if main:
			st.border_width_left = 7
			st.border_color = UiStyle.RED
		b.add_theme_stylebox_override(s, st)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", UiStyle.SP_L)
	b.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 20 + (7 if main else 0)
	row.offset_right = -20
	var texts := VBoxContainer.new()
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 2)
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := UiStyle.g_label(title.to_upper(), UiStyle.FS_TITLE if main else UiStyle.FS_H2, UiStyle.G_INK if main else UiStyle.G_TEXT, "black")
	var s2 := UiStyle.g_label(sub, UiStyle.FS_SMALL + 1, UiStyle.G_INK_2 if main else UiStyle.G_TEXT_2)
	s2.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	for l: Label in [t, s2]:
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		texts.add_child(l)
	row.add_child(texts)
	var go := PanelContainer.new()
	var d := 54 if main else UiStyle.TOUCH_MIN
	go.custom_minimum_size = Vector2(d, d)
	go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	go.mouse_filter = Control.MOUSE_FILTER_IGNORE
	go.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.RED if main else UiStyle.G_SURFACE_HOVER, d / 2, 0, 0))
	go.add_child(icon("chevron", 28 if main else 24, Color.WHITE))
	row.add_child(go)
	press_feedback(b)
	return b


## Modo ainda não implementado: texto apagado, cadeado e etiqueta. Não é botão (não parece tocável).
static func locked_row(title: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.custom_minimum_size = Vector2(0, 46)
	h.add_theme_constant_override("separation", UiStyle.SP_M)
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(8, 0)
	h.add_child(pad)
	var lock := icon("lock", 20, UiStyle.G_TEXT_OFF)
	lock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(lock)
	var l := UiStyle.g_label(title.to_upper(), 18, UiStyle.G_TEXT_OFF, "black")
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	var tag := PanelContainer.new()
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_SURFACE, 14, 10, 3))
	tag.add_child(UiStyle.g_caption("Em desenvolvimento", UiStyle.G_TEXT_OFF))
	h.add_child(tag)
	return h


## Pílula da equipe: emblema (respeita a importação do jogador), nome e sobrenomes dos pilotos.
static func team_pill(team_id: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_SURFACE_HOVER, 30, 10, 6))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UiStyle.SP_M)
	p.add_child(h)
	update_team_pill(p, team_id)
	return p


static func update_team_pill(p: PanelContainer, team_id: String) -> void:
	var h: HBoxContainer = p.get_child(0)
	for c in h.get_children():
		c.queue_free()
	var team := GameData.any_team(team_id)
	var emb := TeamEmblems.make_rect(team_id, 32)
	emb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(emb)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", -2)
	v.add_child(UiStyle.g_label(team.get("name", ""), 17, UiStyle.G_TEXT, "black"))
	var names: Array[String] = []
	for d: Dictionary in GameData.category_drivers(GameData.category_of(team_id)):
		if d["team"] == team_id:
			names.append(String(d["name"]).get_slice(" ", String(d["name"]).get_slice_count(" ") - 1))
	v.add_child(UiStyle.g_label(" · ".join(names), 13, UiStyle.G_TEXT_2))
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(6, 0)
	h.add_child(v)
	h.add_child(pad)


## Controle segmentado em pílula. options: [[valor, texto], ...]. on_change(valor).
static func segmented(options: Array, selected: Variant, on_change: Callable) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_SURFACE, UiStyle.R_PILL, 4, 4))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	p.add_child(h)
	var group := ButtonGroup.new()
	for opt: Array in options:
		var b := Button.new()
		b.text = opt[1]
		b.toggle_mode = true
		b.button_group = group
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MIN)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_selectable_styles(b, UiStyle.R_PILL - 2)
		b.button_pressed = opt[0] == selected
		b.set_meta("value", opt[0])
		b.pressed.connect(on_change.bind(opt[0]))
		h.add_child(b)
	return p


## Opções em bloco com ícone e texto (ex.: clima). options: [[valor, texto, ícone], ...].
static func choice_tiles(options: Array, selected: Variant, on_change: Callable) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UiStyle.SP_S)
	var group := ButtonGroup.new()
	for opt: Array in options:
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 60)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_selectable_styles(b, UiStyle.R_CHIP)
		b.add_theme_stylebox_override("normal", UiStyle.g_box(UiStyle.G_SURFACE, UiStyle.R_CHIP, 10, 0))
		b.add_theme_stylebox_override("hover", UiStyle.g_box(UiStyle.G_SURFACE_HOVER, UiStyle.R_CHIP, 10, 0))
		var v := VBoxContainer.new()
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_theme_constant_override("separation", 2)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(v)
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var ic := icon(opt[2], 22)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(ic)
		var l := UiStyle.g_label(opt[1], 13, UiStyle.G_TEXT_2)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l)
		b.set_meta("value", opt[0])
		var paint := func() -> void:
			var on := b.button_pressed
			ic.modulate = UiStyle.G_INK if on else UiStyle.G_TEXT
			l.add_theme_color_override("font_color", UiStyle.G_INK if on else UiStyle.G_TEXT_2)
		b.toggled.connect(func(_on: bool) -> void: paint.call())
		b.button_pressed = opt[0] == selected
		paint.call()
		b.pressed.connect(on_change.bind(opt[0]))
		h.add_child(b)
	return h


## Estados de um item selecionável: normal (superfície), pressionado, selecionado (claro).
static func _selectable_styles(b: Button, radius: int) -> void:
	b.add_theme_stylebox_override("normal", UiStyle.g_box(Color(0, 0, 0, 0), radius, 10, 0))
	b.add_theme_stylebox_override("hover", UiStyle.g_box(UiStyle.G_SURFACE, radius, 10, 0))
	b.add_theme_stylebox_override("pressed", UiStyle.g_box(UiStyle.G_LIGHT, radius, 10, 0))
	b.add_theme_stylebox_override("hover_pressed", UiStyle.g_box(UiStyle.G_LIGHT, radius, 10, 0))
	b.add_theme_stylebox_override("disabled", UiStyle.g_box(Color(0, 0, 0, 0), radius, 10, 0))
	b.add_theme_color_override("font_color", UiStyle.G_TEXT_2)
	b.add_theme_color_override("font_hover_color", UiStyle.G_TEXT)
	b.add_theme_color_override("font_pressed_color", UiStyle.G_INK)
	b.add_theme_color_override("font_hover_pressed_color", UiStyle.G_INK)
	b.add_theme_font_size_override("font_size", UiStyle.fs(UiStyle.FS_BODY))


## Número grande com legenda (dados do circuito).
static func stat(value: String, caption_text: String) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.add_child(UiStyle.g_label(value, 40, UiStyle.G_TEXT, "black"))
	v.add_child(UiStyle.g_caption(caption_text))
	return v


## Etiqueta em pílula (ex.: rodada e data), com ícone opcional.
static func badge(text: String, fill: Color, icon_name: String = "") -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(fill, 14, 12, 4))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	p.add_child(h)
	var fg := UiStyle.contrast_text(fill)
	if icon_name != "":
		h.add_child(icon(icon_name, 16, fg))
	var l := UiStyle.g_caption(text, fg)
	l.add_theme_font_size_override("font_size", UiStyle.fs(13))
	h.add_child(l)
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return p


## Folha sobreposta (seleção de equipe, corrida rápida). Fecha pelo X ou tocando fora.
## Devolve {"root": camada a adicionar na tela, "body": VBox para o conteúdo}.
static func sheet(title: String, width: float = 860.0) -> Dictionary:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.add_child(center)
	var panel := PanelContainer.new()
	var st := UiStyle.g_box(Color("#17191e"), 22, 28, 22)
	st.shadow_color = Color(0, 0, 0, 0.45)
	st.shadow_size = 18
	panel.add_theme_stylebox_override("panel", st)
	panel.custom_minimum_size = Vector2(width, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UiStyle.SP_L)
	panel.add_child(v)
	var head := HBoxContainer.new()
	var t := UiStyle.g_label(title.to_upper(), UiStyle.FS_H2 + 4, UiStyle.G_TEXT, "black")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var close := round_button("close", UiStyle.TOUCH_MIN, "Fechar")
	head.add_child(close)
	v.add_child(head)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", UiStyle.SP_M)
	v.add_child(body)
	close.pressed.connect(dim.queue_free)
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and not panel.get_global_rect().has_point(e.global_position):
			dim.queue_free())
	dim.modulate = Color(1, 1, 1, 0)
	dim.ready.connect(func() -> void: dim.create_tween().tween_property(dim, "modulate:a", 1.0, 0.12))
	return {"root": dim, "body": body}


## Folha de escolha da equipe (tela inicial e configuração do GP). Grava em Session.player_team
## e chama on_pick(id_da_equipe).
static func open_team_picker(screen: Control, on_pick: Callable) -> void:
	var s := sheet("Escolha sua equipe", 980)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", UiStyle.SP_M)
	grid.add_theme_constant_override("v_separation", UiStyle.SP_M)
	(s["body"] as VBoxContainer).add_child(grid)
	var group := ButtonGroup.new()
	for t: Dictionary in GameData.category_teams(Session.category):
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(300, 68)
		_selectable_styles(b, UiStyle.R_TILE)
		b.add_theme_stylebox_override("normal", UiStyle.g_box(UiStyle.G_SURFACE, UiStyle.R_TILE, 10, 0))
		var pill := team_pill(t["id"])
		pill.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(pill)
		pill.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
		pill.offset_left = 12
		var paint := func() -> void:
			for l in pill.find_children("*", "Label", true, false):
				(l as Label).add_theme_color_override("font_color", UiStyle.G_INK if b.button_pressed else UiStyle.G_TEXT)
		b.toggled.connect(func(_on: bool) -> void: paint.call())
		b.button_pressed = t["id"] == Session.player_team
		paint.call_deferred()
		var id: String = t["id"]
		b.pressed.connect(func() -> void:
			Session.player_team = id
			on_pick.call(id)
			(s["root"] as Control).queue_free())
		grid.add_child(b)
	screen.add_child(s["root"])


## Barra de porcentagem da Garagem (acerto do carro): trilho escuro, preenchimento na cor da equipe.
## Devolve {"bar": ProgressBar, "value": Label}.
static func g_percent_row(parent: Container, title: String, color: Color) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UiStyle.SP_M)
	var name_l := UiStyle.g_label(title, UiStyle.FS_SMALL, Color("#c3c9d3"))
	name_l.custom_minimum_size = Vector2(100, 0)
	row.add_child(name_l)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = 1.0
	bar.step = 0.001
	bar.custom_minimum_size = Vector2(0, 9)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_theme_stylebox_override("background", UiStyle.g_box(Color(1, 1, 1, 0.08), 5, 0, 0))
	bar.add_theme_stylebox_override("fill", UiStyle.g_box(color.lightened(0.1), 5, 0, 0))
	row.add_child(bar)
	var value := UiStyle.g_label("", UiStyle.FS_BODY, UiStyle.G_TEXT, "black")
	value.custom_minimum_size = Vector2(48, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)
	parent.add_child(row)
	return {"bar": bar, "value": value}


## Indicador de etapas (sessões do fim de semana). items: [[rótulo, letra, estado]] com estado
## "done" (verde, ✓), "now" (vermelho, com halo) ou "next" (apagado). Não usa só cor: a feita
## leva ✓ e a atual tem halo e texto em destaque.
static func step_bar(items: Array) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 0)
	for i in items.size():
		var it: Array = items[i]
		if i > 0:
			var ln := ColorRect.new()
			ln.custom_minimum_size = Vector2(0, 3)
			ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ln.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			ln.color = Color("#2a6b3f") if items[i - 1][2] == "done" else Color(1, 1, 1, 0.08)
			var m := MarginContainer.new()
			m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			m.add_theme_constant_override("margin_left", 12)
			m.add_theme_constant_override("margin_right", 12)
			m.add_child(ln)
			h.add_child(m)
		var state: String = it[2]
		var dot := PanelContainer.new()
		dot.custom_minimum_size = Vector2(34, 34)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var fill: Color = {"done": Color("#2a6b3f"), "now": UiStyle.RED}.get(state, UiStyle.G_SURFACE_HOVER)
		var st := UiStyle.g_box(fill, 17, 0, 0)
		if state == "now":
			st.shadow_color = Color(UiStyle.RED, 0.3)
			st.shadow_size = 6
		dot.add_theme_stylebox_override("panel", st)
		var mark := UiStyle.g_label("✓" if state == "done" else String(it[1]), 13, Color.WHITE if state != "next" else Color("#c3c9d3"), "black")
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		dot.add_child(mark)
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 10)
		cell.add_child(dot)
		var l := UiStyle.g_label(String(it[0]), 15, UiStyle.G_TEXT if state == "now" else UiStyle.G_TEXT_3, "bold")
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cell.add_child(l)
		h.add_child(cell)
	return h


## Botão secundário sobre um cartão claro (ex.: SIMULAR ao lado de JOGAR).
static func light_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MAIN)
	for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
		var fill := Color("#e3e6eb") if s in ["normal", "hover"] else Color("#cdd1d8")
		b.add_theme_stylebox_override(s, UiStyle.g_box(fill, 14, 26, 0))
	for k: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(k, UiStyle.G_INK)
	b.add_theme_font_override("font", UiStyle.G_BLACK)
	b.add_theme_font_size_override("font_size", UiStyle.fs(19))
	press_feedback(b)
	return b


## Cartão escuro (superfície) com margens internas.
static func g_card(fill: Color = UiStyle.G_SURFACE, radius: int = 20, mh: int = 20, mv: int = 16) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(fill, radius, mh, mv))
	return p


## Popover claro ancorado acima de um botão: lista de opções; fecha tocando fora ou escolhendo.
## options: [[valor, texto], ...]. on_pick(valor). Devolve a camada (para o chamador guardar).
static func popover(screen: Control, anchor: Control, title: String, options: Array, selected: Variant, on_pick: Callable) -> Control:
	var catcher := Control.new()
	catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	catcher.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			catcher.queue_free())
	var panel := PanelContainer.new()
	var st := UiStyle.g_box(UiStyle.G_LIGHT, 16, 12, 12)
	st.shadow_color = Color(0, 0, 0, 0.5)
	st.shadow_size = 14
	panel.add_theme_stylebox_override("panel", st)
	panel.custom_minimum_size = Vector2(280, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	v.add_child(UiStyle.g_caption(title, UiStyle.G_INK_2))
	for o: Array in options:
		var b := Button.new()
		b.text = o[1]
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MIN)
		var on: bool = o[0] == selected
		for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(s, UiStyle.g_box(UiStyle.G_INK if on else Color("#e3e6eb"), 12, 14, 0))
		for k: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(k, Color.WHITE if on else UiStyle.G_INK)
		b.add_theme_font_size_override("font_size", UiStyle.fs(UiStyle.FS_BODY))
		var val: Variant = o[0]
		b.pressed.connect(func() -> void:
			on_pick.call(val)
			catcher.queue_free())
		v.add_child(b)
	catcher.add_child(panel)
	screen.add_child(catcher)
	var r := anchor.get_global_rect()
	panel.reset_size()
	panel.position = Vector2(clampf(r.position.x, 8.0, screen.size.x - 288.0), maxf(8.0, r.position.y - panel.size.y - 8.0))
	return catcher


## Abas da sede da campanha (Início · Campeonatos · Pessoal · Carro · Fábrica · Patrocínios · Finanças).
## active: "hub", "standings", "staff", "car", "factory", "sponsors" ou "finance".
static func campaign_nav(layer: Control, active: String, y: float = 88.0) -> PanelContainer:
	var nav := PanelContainer.new()
	nav.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_SURFACE, 26, 4, 4))
	var nh := HBoxContainer.new()
	nh.add_theme_constant_override("separation", 4)
	nav.add_child(nh)
	var items := [["Início", "hub"], ["Campeonatos", "standings"], ["Histórico", "history"], ["Pessoal", "staff"], ["Carro", "car"], ["Design", "studio"], ["Fábrica", "factory"], ["Patrocínios", "sponsors"], ["Finanças", "finance"], ["Conselho", "council"]]
	if Session.campaign != null and Session.campaign.is_feeder():  # F2/F3: a sede reúne operação, dinheiro e pessoal
		items = items.slice(0, 3)
	for t: Array in items:
		var on: bool = t[1] == active
		var b := Button.new()
		b.text = t[0]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MIN)
		_selectable_styles(b, UiStyle.R_PILL - 4)
		b.add_theme_stylebox_override("normal", UiStyle.g_box(UiStyle.G_LIGHT if on else Color(0, 0, 0, 0), UiStyle.R_PILL - 4, 20, 0))
		b.add_theme_color_override("font_color", UiStyle.G_INK if on else UiStyle.G_TEXT)
		b.add_theme_color_override("font_disabled_color", UiStyle.G_TEXT_OFF)
		b.add_theme_font_size_override("font_size", UiStyle.fs(UiStyle.FS_BODY))
		b.disabled = t[1] == ""
		if t[1] != "" and not on:
			match t[1]:
				"hub":
					b.pressed.connect(Session.open_campaign_hub)
				"standings":
					b.pressed.connect(Session.open_campaign_standings)
				"history":
					b.pressed.connect(Session.open_campaign_history)
				"staff":
					b.pressed.connect(Session.open_campaign_staff)
				"car":
					b.pressed.connect(Session.open_campaign_car)
				"factory":
					b.pressed.connect(Session.open_campaign_factory)
				"studio":
					b.pressed.connect(Session.open_campaign_studio)
				"sponsors":
					b.pressed.connect(Session.open_campaign_sponsors)
				"finance":
					b.pressed.connect(Session.open_campaign_finance)
				"council":
					b.pressed.connect(Session.open_campaign_council)
		nh.add_child(b)
	# com a letra maior as abas podem passar da largura da tela: a faixa desliza para o lado
	var strip := DragScroll.new()
	strip.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	strip.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE  # a parte vazia da faixa não bloqueia o que está ao lado
	nav.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	strip.add_child(nav)
	place(strip, layer, Control.PRESET_TOP_LEFT, Vector2(44, y), Vector2(1280 - 88, UiStyle.TOUCH_MIN + 8))
	return nav
