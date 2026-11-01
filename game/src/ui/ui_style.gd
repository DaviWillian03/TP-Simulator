class_name UiStyle
extends RefCounted
## Tokens visuais da direção "Paddock" — estilo revista impressa
## (escolhida pelo usuário em design/mockups/03-paddock.html).
##
## Papel claro, tinta preta, um único vermelho de destaque, letras pesadas e fios grossos
## separando as áreas. Mudar cor, fonte ou espessura do jogo = mudar aqui.

# --- cores ---------------------------------------------------------------------------
const PAPER := Color("#efe9de")  ## fundo (papel)
const PAPER_2 := Color("#e6dfd2")  ## papel um pouco mais escuro (áreas secundárias)
const INK := Color("#141414")  ## tinta: texto, fios, botões ativos
const RED := Color("#E10600")  ## único destaque: líder, posição, voltas, box
const RULE := Color("#c9c1b2")  ## fio fino entre linhas da tabela
const MUTED := Color("#6d665a")
const BAR_BG := Color("#d8d0c1")
const WARN := RED

# --- formas e fontes -----------------------------------------------------------------
const RULE_THICK := 5  ## fio grosso sob o cabeçalho
const RULE_MID := 2  ## fio entre seções e contorno de botões
const HEAVY_FONT := preload("res://assets/fonts/ArchivoBlack-Regular.ttf")
const NARROW_FONT := preload("res://assets/fonts/ArchivoNarrow-Variable.ttf")

static var _body_font: FontVariation


## Archivo Narrow no peso 600 (a fonte é variável; o padrão dela seria 400).
static func body_font() -> FontVariation:
	if _body_font == null:
		_body_font = FontVariation.new()
		_body_font.base_font = NARROW_FONT
		var wght := TextServerManager.get_primary_interface().name_to_tag("wght")
		_body_font.variation_opentype = {wght: 600}
	return _body_font


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = 16
	for type: String in ["Button", "OptionButton"]:
		t.set_stylebox("normal", type, outline_box(Color(0, 0, 0, 0), INK))
		t.set_stylebox("hover", type, outline_box(PAPER_2, INK))
		t.set_stylebox("pressed", type, outline_box(INK, INK))
		t.set_stylebox("hover_pressed", type, outline_box(INK, INK))
		t.set_stylebox("disabled", type, outline_box(Color(0, 0, 0, 0), RULE))
		t.set_stylebox("focus", type, StyleBoxEmpty.new())
		t.set_color("font_color", type, INK)
		t.set_color("font_hover_color", type, INK)
		t.set_color("font_pressed_color", type, PAPER)
		t.set_color("font_hover_pressed_color", type, PAPER)
		t.set_color("font_disabled_color", type, RULE)
	t.set_stylebox("panel", "PanelContainer", box(PAPER))
	t.set_color("font_color", "Label", INK)
	t.set_stylebox("background", "ProgressBar", box(BAR_BG, 0, 0))
	t.set_stylebox("fill", "ProgressBar", box(INK, 0, 0))
	var track := box(BAR_BG, 3, 0)
	track.content_margin_left = 3
	track.content_margin_right = 3
	t.set_stylebox("scroll", "VScrollBar", track)
	for state: String in ["grabber", "grabber_highlight", "grabber_pressed"]:
		t.set_stylebox(state, "VScrollBar", box(INK, 3, 0))
	t.set_constant("separation", "HBoxContainer", 8)
	t.set_constant("separation", "VBoxContainer", 6)
	return t


## Caixa reta, sem borda.
static func box(color: Color, margin_h: int = 10, margin_v: int = 4) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = color
	b.content_margin_left = margin_h
	b.content_margin_right = margin_h
	b.content_margin_top = margin_v
	b.content_margin_bottom = margin_v
	return b


## Caixa com contorno de tinta (botões).
static func outline_box(fill: Color, border: Color, width: int = RULE_MID) -> StyleBoxFlat:
	var b := box(fill)
	b.border_color = border
	b.set_border_width_all(width)
	return b


## Separador: fio de tinta horizontal (ou vertical).
static func rule(thickness: int = RULE_MID, vertical: bool = false) -> ColorRect:
	var r := ColorRect.new()
	r.color = INK
	r.custom_minimum_size = Vector2(thickness, 0) if vertical else Vector2(0, thickness)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func label(text: String, size: int = 16, color: Color = INK, heavy: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if heavy:
		l.add_theme_font_override("font", HEAVY_FONT)
	return l


## Rótulo pequeno em caixa alta com espaçamento (ex.: "PNEU", "BATERIA").
static func caption(text: String, color: Color = INK) -> Label:
	var l := label(text.to_upper(), 10, color)
	var f := FontVariation.new()
	f.base_font = body_font()
	f.spacing_glyph = 2
	l.add_theme_font_override("font", f)
	return l


static func button(text: String, toggle: bool = false, group: ButtonGroup = null) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	b.toggle_mode = toggle
	b.button_group = group
	b.custom_minimum_size = Vector2(0, 38)  # alvo de toque confortável no celular
	b.focus_mode = Control.FOCUS_NONE
	return b


## Botão em destaque (vermelho cheio), ex.: LARGAR, CHAMAR P/ BOX.
static func accent(b: Button) -> Button:
	b.add_theme_stylebox_override("normal", outline_box(RED, RED))
	b.add_theme_stylebox_override("hover", outline_box(RED.lightened(0.1), RED))
	b.add_theme_stylebox_override("pressed", outline_box(INK, INK))
	b.add_theme_stylebox_override("hover_pressed", outline_box(INK, INK))
	b.add_theme_stylebox_override("disabled", outline_box(BAR_BG, BAR_BG))
	for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, Color.WHITE)
	b.add_theme_font_override("font", HEAVY_FONT)
	return b


## Margens internas menores, para linhas com muitos botões.
static func compact(b: Button, font_size: int = 13) -> Button:
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var base: StyleBoxFlat
		if b.has_theme_stylebox_override(state):
			base = b.get_theme_stylebox(state).duplicate()
		else:
			base = {
				"normal": outline_box(Color(0, 0, 0, 0), INK), "hover": outline_box(PAPER_2, INK),
				"pressed": outline_box(INK, INK), "hover_pressed": outline_box(INK, INK),
				"disabled": outline_box(Color(0, 0, 0, 0), RULE),
			}[state]
		base.content_margin_left = 3
		base.content_margin_right = 3
		b.add_theme_stylebox_override(state, base)
	b.add_theme_font_size_override("font_size", font_size)
	return b


## Etiqueta vermelha levemente torta, como um selo colado na página (avisos).
static func stamp(text: String, size: int = 15) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(RED, 12, 5))
	p.add_child(label(text.to_upper(), size, Color.WHITE, true))
	p.rotation_degrees = -1.5
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## Cor do texto com bom contraste sobre um fundo (preto em cores claras, branco nas escuras).
static func contrast_text(bg: Color) -> Color:
	return INK if bg.get_luminance() > 0.5 else Color.WHITE


# --- folha de cronometragem (tabelas) -------------------------------------------------

## Fundo de uma linha da tabela, com fio de tinta embaixo separando cada piloto.
static func row_box(bg: Color) -> StyleBoxFlat:
	var b := box(bg, 0, 0)
	b.border_color = INK
	b.border_width_bottom = 1
	return b


## Separador vertical fino entre colunas.
static func vsep(color: Color = RULE) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.custom_minimum_size = Vector2(1, 0)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## Quadrado da posição: fundo na cor da equipe, número com contraste.
static func pos_cell(width: float) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(width, 0)
	p.add_theme_stylebox_override("panel", box(PAPER_2, 0, 0))
	var l := label("", 14, INK, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


static func set_pos_cell(cell: PanelContainer, text: String, bg: Color) -> void:
	cell.add_theme_stylebox_override("panel", box(bg, 0, 0))
	var l: Label = cell.get_child(0)
	l.text = text
	l.add_theme_color_override("font_color", contrast_text(bg))


## Contorno grosso da tabela inteira.
static func sheet_box() -> StyleBoxFlat:
	var b := box(PAPER, 0, 0)
	b.border_color = INK
	b.set_border_width_all(RULE_MID)
	return b


static func hspacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


## Letra do pneu na cor do composto, com contorno de tinta (o duro é branco no papel).
static func tyre_letter(l: Label, color: Color) -> void:
	l.add_theme_font_override("font", HEAVY_FONT)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", 3)


static func format_time(seconds: float) -> String:
	if seconds == INF or seconds <= 0.0:
		return "—"
	var m := floori(seconds / 60.0)
	return "%d:%06.3f" % [m, seconds - m * 60]
