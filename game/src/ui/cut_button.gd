class_name CutButton
extends Button
## Ação principal da direção Garagem: bloco vermelho com o canto superior direito cortado
## (o "recorte esportivo" usado só nas ações que levam à pista). Estados: normal, pressionado
## (mais escuro e levemente menor) e desabilitado (cinza, sem corte vermelho).

const CUT := 18.0
const RADIUS := 14.0

var _bg: _Shape


func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(0, UiStyle.TOUCH_MAIN + 4)
	for s: String in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var e := StyleBoxEmpty.new()
		e.content_margin_left = 24
		e.content_margin_right = 24
		add_theme_stylebox_override(s, e)
	add_theme_font_override("font", UiStyle.G_BLACK)
	add_theme_font_size_override("font_size", UiStyle.fs(22))
	for k: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		add_theme_color_override(k, Color.WHITE)
	add_theme_color_override("font_disabled_color", UiStyle.G_TEXT_OFF)
	for k: String in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color"]:
		add_theme_color_override(k, Color.WHITE)
	icon = load("res://assets/icons/chevron.svg")
	icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_theme_constant_override("icon_max_width", 26)
	add_theme_constant_override("h_separation", 12)
	_bg = _Shape.new()
	_bg.show_behind_parent = true
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ScreenKit.press_feedback(self)
	for sig: String in ["button_down", "button_up", "mouse_entered", "mouse_exited"]:
		connect(sig, _bg.queue_redraw)


func _notification(what: int) -> void:
	# o fundo é um nó filho: redesenha junto com o botão (inclui ligar/desligar — antes ficava cinza
	# depois de o botão voltar a ficar ativo, ex.: carro saindo do pit lane)
	if (what == NOTIFICATION_RESIZED or what == NOTIFICATION_DRAW) and _bg:
		_bg.queue_redraw()


class _Shape:
	extends Control

	func _draw() -> void:
		var b: Button = get_parent()
		var c := UiStyle.RED
		if b.disabled:
			c = UiStyle.G_OFF
		elif b.is_pressed() or b.button_pressed:
			c = UiStyle.G_RED_PRESS
		var w := size.x
		var h := size.y
		var r := CutButton.RADIUS
		var k := CutButton.CUT
		var pts := PackedVector2Array([Vector2(r, 0), Vector2(w - k, 0), Vector2(w, k), Vector2(w, h - r)])
		for i in range(0, 5):  # canto inferior direito arredondado
			var a := deg_to_rad(90.0 * i / 4.0)
			pts.append(Vector2(w - r + r * cos(a), h - r + r * sin(a)))
		for i in range(0, 5):  # inferior esquerdo
			var a := deg_to_rad(90.0 + 90.0 * i / 4.0)
			pts.append(Vector2(r + r * cos(a), h - r + r * sin(a)))
		for i in range(0, 5):  # superior esquerdo
			var a := deg_to_rad(180.0 + 90.0 * i / 4.0)
			pts.append(Vector2(r + r * cos(a), r + r * sin(a)))
		draw_colored_polygon(pts, c)
