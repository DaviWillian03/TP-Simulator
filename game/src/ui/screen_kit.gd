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
