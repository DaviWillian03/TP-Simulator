class_name UiStyle
extends RefCounted
## Paleta, tema e pequenos construtores de interface usados por todas as telas.

const BG := Color("#0B1220")
const PANEL := Color("#121C30")
const PANEL_2 := Color("#18243C")
const LINE := Color("#26344F")
const TEXT := Color("#E8EEF8")
const MUTED := Color("#8D9AB3")
const ACCENT := Color("#FF6A1A")
const ACCENT_2 := Color("#FFC400")
const GOOD := Color("#3DDC84")
const WARN := Color("#FF4D4D")
const PLAYER_ROW := Color("#2A2140")

const BOLD_FONT := preload("res://assets/fonts/Inter-ExtraBold.otf")


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 16
	for type: String in ["Button", "OptionButton"]:
		t.set_stylebox("normal", type, box(PANEL_2, 8, LINE))
		t.set_stylebox("hover", type, box(Color("#22304D"), 8, LINE))
		t.set_stylebox("pressed", type, box(Color("#3A1F14"), 8, ACCENT, 2))
		t.set_stylebox("hover_pressed", type, box(Color("#4A2818"), 8, ACCENT, 2))
		t.set_stylebox("disabled", type, box(PANEL, 8, PANEL))
		t.set_stylebox("focus", type, StyleBoxEmpty.new())
		t.set_color("font_color", type, TEXT)
		t.set_color("font_hover_color", type, Color.WHITE)
		t.set_color("font_pressed_color", type, Color.WHITE)
		t.set_color("font_hover_pressed_color", type, Color.WHITE)
		t.set_color("font_disabled_color", type, Color("#55617A"))
	t.set_stylebox("panel", "PanelContainer", box(PANEL, 10, LINE))
	t.set_color("font_color", "Label", TEXT)
	t.set_stylebox("background", "ProgressBar", box(Color("#0E1626"), 4, LINE))
	t.set_stylebox("fill", "ProgressBar", box(ACCENT, 4, ACCENT, 0))
	t.set_constant("separation", "HBoxContainer", 8)
	t.set_constant("separation", "VBoxContainer", 6)
	return t


static func box(color: Color, radius: int, border: Color, border_width: int = 1) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = color
	b.set_corner_radius_all(radius)
	b.border_color = border
	b.set_border_width_all(border_width)
	b.content_margin_left = 10
	b.content_margin_right = 10
	b.content_margin_top = 6
	b.content_margin_bottom = 6
	return b


static func label(text: String, size: int = 16, color: Color = TEXT, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_font_override("font", BOLD_FONT)
	return l


static func button(text: String, toggle: bool = false, group: ButtonGroup = null) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = toggle
	b.button_group = group
	b.custom_minimum_size = Vector2(0, 40)  # alvo de toque confortável no celular
	b.focus_mode = Control.FOCUS_NONE
	return b


## Versão compacta do botão (margens internas menores) para linhas com muitos botões.
static func compact(b: Button, font_size: int = 13) -> Button:
	var styles := {
		"normal": box(PANEL_2, 8, LINE),
		"hover": box(Color("#22304D"), 8, LINE),
		"pressed": box(Color("#3A1F14"), 8, ACCENT, 2),
		"hover_pressed": box(Color("#4A2818"), 8, ACCENT, 2),
		"disabled": box(PANEL, 8, PANEL),
	}
	for state: String in styles:
		var s: StyleBoxFlat = styles[state]
		s.content_margin_left = 4
		s.content_margin_right = 4
		b.add_theme_stylebox_override(state, s)
	b.add_theme_font_size_override("font_size", font_size)
	return b


static func panel(color: Color = PANEL, radius: int = 10) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(color, radius, LINE))
	return p


static func hspacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


static func format_time(seconds: float) -> String:
	if seconds == INF or seconds <= 0.0:
		return "—"
	var m := floori(seconds / 60.0)
	return "%d:%06.3f" % [m, seconds - m * 60]
