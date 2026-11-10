class_name UiStyle
extends RefCounted
## Fonte central do estilo do jogo. Mudar cor, fonte, raio ou espaçamento = mudar aqui.
##
## Em migração (2026-11-02): a direção **Garagem** (design/mockups/v3-1-*) substitui a Paddock.
## Já migradas: tela inicial, configuração do GP, painel do fim de semana e treino ao vivo.
## As demais telas ainda usam os tokens Paddock abaixo (legado) até serem refeitas.

# === Paddock (legado: telas ainda não migradas) ======================================

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
## Fonte do jogo inteiro: Kanit (OFL; escolha do usuário — estilo de jogo mobile, sempre em caixa alta).
const HEAVY_FONT := preload("res://assets/fonts/Kanit-Bold.ttf")
const NARROW_FONT := preload("res://assets/fonts/Kanit-Medium.ttf")

static var _body_font: FontVariation


## Texto corrido das telas antigas (Kanit Medium).
static func body_font() -> FontVariation:
	if _body_font == null:
		_body_font = FontVariation.new()
		_body_font.base_font = NARROW_FONT
	return _body_font


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = fs(16)
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
	l.add_theme_font_size_override("font_size", fs(size))
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
	b.add_theme_font_size_override("font_size", fs(font_size))
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


# === Garagem (direção atual) ===========================================================
# Ambiente escuro de box, o carro da equipe sob a luz; a cor da equipe tinge os destaques.
# Vermelho = marca e ação principal; cor da equipe = seleção; cinzas claros = conteúdo.

const G_BG := Color("#0b0c0f")
const G_WALL_TOP := Color("#1b1e24")
const G_WALL_BOTTOM := Color("#111318")
const G_FLOOR_TOP := Color("#181a1f")
const G_FLOOR_BOTTOM := Color("#0a0b0d")
const G_SURFACE := Color(1, 1, 1, 0.06)  ## peça sobre o fundo (botões secundários, cartões)
const G_SURFACE_HOVER := Color(1, 1, 1, 0.10)
const G_SURFACE_PRESS := Color(1, 1, 1, 0.16)
const G_LIGHT := Color("#f3f4f6")  ## destaque claro: ação principal e item selecionado
const G_LIGHT_PRESS := Color("#d6d9df")
const G_TEXT := Color("#eef0f3")
const G_TEXT_2 := Color("#a8b0bd")  ## descrição
const G_TEXT_3 := Color("#8f98a7")  ## legenda em caixa alta
const G_TEXT_OFF := Color("#6c7380")  ## indisponível
const G_INK := Color("#11141a")  ## texto sobre o claro
const G_INK_2 := Color("#4b5260")
const G_RED_PRESS := Color("#b30500")
const G_GLASS := Color(0.043, 0.051, 0.071, 0.86)  ## painel escuro translúcido sobre a pista em tela cheia
const G_OFF := Color(1, 1, 1, 0.04)
const G_FRAME := Color(0.039, 0.047, 0.063, 0.82)  ## barra do topo e barra de ícones da campanha (v26)
## Cor de destaque de cada seção da campanha (v26): o ícone e o título da seção usam a mesma cor.
const SECTION := {"home": Color("#f3f4f6"), "champ": Color("#E10600"), "drivers": Color("#4C8DFF"), "car": Color("#FF8A1F"),
	"hq": Color("#2FD38A"), "cal": Color("#ff4d4d"), "staff": Color("#A66BFF"), "spons": Color("#22C7E8"),
	"money": Color("#F5C542"), "hist": Color("#F5C542"), "board": Color("#FF5C8A")}  ## fundo de controle desabilitado
## Treino simulado (mockup v21): partes do medidor "chance de bom acerto" e as notas do resultado
const G_DIRECTOR := Color("#ffd24a")
const G_ENGINEER := Color("#5c93ea")
const G_DRIVER := Color("#3c9d5d")
const G_LUCK := Color("#8f98a7")
const G_UP := Color("#7fe0b1")  ## melhora
const G_DOWN := Color("#ff8a80")  ## piora / problema
const G_GRADE := {"A": Color("#3c9d5d"), "B": Color("#5c93ea"), "C": Color("#ffd24a"), "D": Color("#ff8a80")}

const R_TILE := 16  ## blocos de modo, cartões
const R_CHIP := 14  ## opções em bloco (clima)
const R_PILL := 26  ## pílulas e segmentados (meia altura)
const SP_XS := 4
const SP_S := 8
const SP_M := 12
const SP_L := 16
const SP_XL := 24
const SP_XXL := 44  ## margem lateral das telas
const TOUCH_MIN := 44  ## menor alvo de toque (px na referência 1280×720)
const TOUCH_MAIN := 56  ## ação principal

## Pesos da Kanit: "black" = Bold (títulos e números), "bold" = SemiBold (nomes e botões), "semi" = Medium (texto).
const G_BLACK := preload("res://assets/fonts/Kanit-Bold.ttf")
const G_BOLD := preload("res://assets/fonts/Kanit-SemiBold.ttf")
const G_SEMI := preload("res://assets/fonts/Kanit-Medium.ttf")
const FS_DISPLAY := 50
const FS_TITLE := 34
const FS_H2 := 24
const FS_BODY := 16
const FS_SMALL := 14
const FS_CAPTION := 12  ## menor texto permitido nas telas novas (antes da escala)
## Escala global do texto (pedido do usuário: letras maiores no celular). Textos até 22 px
## crescem 20%; acima disso (títulos) ganham só o mesmo acréscimo fixo, para não estourar o layout.
const TEXT_SCALE := 1.2  ## (padrão; o valor em uso vem de Settings.text_scale())
const _BIG_FROM := 22


## Tamanho de fonte já com a escala global. Toda tela passa por aqui.
static func fs(size: int) -> int:
	var k := Settings.text_scale()
	if size <= _BIG_FROM:
		return roundi(size * k)
	return size + roundi(_BIG_FROM * (k - 1.0))

## Soma das folgas da área segura (câmera frontal/recortes) por eixo, em unidades de UI.
static func safe_insets_size() -> Vector2:
	return SafeArea.size()


static var _g_caption_font: FontVariation


static func make_garage_theme() -> Theme:
	var t := Theme.new()
	t.default_font = G_SEMI
	t.default_font_size = fs(FS_BODY)
	t.set_color("font_color", "Label", G_TEXT)
	for type: String in ["Button"]:
		t.set_stylebox("normal", type, g_box(G_SURFACE, R_PILL))
		t.set_stylebox("hover", type, g_box(G_SURFACE_HOVER, R_PILL))
		t.set_stylebox("pressed", type, g_box(G_SURFACE_PRESS, R_PILL))
		t.set_stylebox("hover_pressed", type, g_box(G_SURFACE_PRESS, R_PILL))
		t.set_stylebox("disabled", type, g_box(G_OFF, R_PILL))
		t.set_stylebox("focus", type, StyleBoxEmpty.new())
		t.set_color("font_color", type, G_TEXT)
		t.set_color("font_hover_color", type, G_TEXT)
		t.set_color("font_pressed_color", type, G_TEXT)
		t.set_color("font_hover_pressed_color", type, G_TEXT)
		t.set_color("font_disabled_color", type, G_TEXT_OFF)
		t.set_font("font", type, G_BOLD)
	t.set_stylebox("panel", "PanelContainer", StyleBoxEmpty.new())
	var bar := g_box(Color(1, 1, 1, 0.08), 3, 0, 0)
	t.set_stylebox("scroll", "HScrollBar", bar)
	t.set_stylebox("scroll", "VScrollBar", bar)
	for state: String in ["grabber", "grabber_highlight", "grabber_pressed"]:
		t.set_stylebox(state, "HScrollBar", g_box(Color(1, 1, 1, 0.3), 3, 0, 0))
		t.set_stylebox(state, "VScrollBar", g_box(Color(1, 1, 1, 0.3), 3, 0, 0))
	return t


## Caixa arredondada sem contorno.
static func g_box(fill: Color, radius: int = R_TILE, margin_h: int = SP_L, margin_v: int = SP_S) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = fill
	b.set_corner_radius_all(radius)
	b.content_margin_left = margin_h
	b.content_margin_right = margin_h
	b.content_margin_top = margin_v
	b.content_margin_bottom = margin_v
	b.anti_aliasing = true
	return b


## Texto da Garagem. weight: "black" (títulos, números), "bold" (nomes, botões), "semi" (texto).
static func g_label(text: String, size: int = FS_BODY, color: Color = G_TEXT, weight: String = "semi") -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fs(size))
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_override("font", {"black": G_BLACK, "bold": G_BOLD}.get(weight, G_SEMI))
	return l


## Legenda em caixa alta com espaçamento (nunca menor que FS_CAPTION).
static func g_caption(text: String, color: Color = G_TEXT_3) -> Label:
	if _g_caption_font == null:
		_g_caption_font = FontVariation.new()
		_g_caption_font.base_font = G_BOLD
		_g_caption_font.spacing_glyph = 3
	var l := g_label(text.to_upper(), FS_CAPTION, color)
	l.add_theme_font_override("font", _g_caption_font)
	return l


## Cor de destaque da equipe nos cartões (botões e realces). Se a cor principal for cinza ou escura
## demais (Haas, Audi, Cadillac), usa a secundária; se ainda faltar brilho, clareia.
static func team_accent(team: Dictionary) -> Color:
	var c := Color(String(team.get("color", "#e10600")))
	var c2 := Color(String(team.get("color2", team.get("color", "#e10600"))))
	if (c.s < 0.3 or c.v < 0.35) and c2.s >= 0.3:
		c = c2
	elif c.v < 0.35:
		c = c2 if c2.v > c.v else c.lightened(0.6)
	return c


## Vidro do cartão tingido com a cor da equipe. Alfa menor que o G_GLASS: a pista aparece por baixo.
static func team_glass(accent: Color, alpha: float = 0.78) -> Color:
	var base := Color(G_GLASS.r, G_GLASS.g, G_GLASS.b).lerp(accent.darkened(0.45), 0.32)
	return Color(base, alpha)


## Texto legível sobre uma cor (escuro sobre cor clara, branco sobre escura).
static func ink_on(fill: Color) -> Color:
	return G_INK if fill.get_luminance() > 0.55 else Color.WHITE


## Cor da equipe (destaques de seleção, brilho atrás do carro).
static func team_color(team_id: String) -> Color:
	var t := GameData.any_team(team_id)
	if t.is_empty() and Session.campaign != null:  # equipe criada na campanha
		t = Session.campaign.team()
	return Color(t.get("color", "#1868DB"))



## Cor de uma equipe numa lista de equipes (inclui a equipe criada na campanha).
static func team_color_from(team_list: Array, team_id: String) -> Color:
	return Color(GameData.team_by_id(team_list, team_id).get("color", "#1868DB"))
