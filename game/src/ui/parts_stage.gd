class_name PartsStage
extends Control
## Palco da tela Carro · peças (mockup v15-2 aprovado): carro visto de cima (arte original, cores da equipe), com uma
## etiqueta por peça ligada por uma linha ao ponto da peça no carro. Tocar na etiqueta escolhe a peça (`part_pressed`).
## O desenho é feito em código (polígonos) para trocar de cor com a equipe sem imagem.

signal part_pressed(part_id: String)

const CAR_SIZE := Vector2(680, 260)
## Etiquetas: posição no palco e ponto da peça no carro (coordenadas do desenho 680 × 260).
const SPOTS := {
	"fwing": {"at": Vector2(548, 56), "pin": Vector2(637, 70)},
	"rwing": {"at": Vector2(18, 70), "pin": Vector2(42, 92)},
	"floor": {"at": Vector2(256, 56), "pin": Vector2(250, 66)},
	"susp": {"at": Vector2(552, 420), "pin": Vector2(566, 170)},
	"pu": {"at": Vector2(256, 428), "pin": Vector2(290, 140)},
	"gearbox": {"at": Vector2(18, 404), "pin": Vector2(84, 130)},
}

var c1 := Color("#1347F5")
var c2 := Color.WHITE
var selected := ""
var car_origin := Vector2(64, 150)
var _labels: Dictionary = {}  ## peça -> Button


func _ready() -> void:
	clip_contents = true


## Cria/atualiza as etiquetas: rows = [{id, title, sub, color, alert, alert_kind}]
func set_callouts(rows: Array) -> void:
	for r: Dictionary in rows:
		var b: Button = _labels.get(r["id"])
		if b == null:
			b = _make_callout(r["id"])
			_labels[r["id"]] = b
		_fill_callout(b, r)
	queue_redraw()


func _make_callout(pid: String) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MIN + 4)
	b.position = SPOTS[pid]["at"]
	for s: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(s, StyleBoxEmpty.new())
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.name = "Panel"
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(h)
	var dot := PanelContainer.new()
	dot.name = "Dot"
	dot.custom_minimum_size = Vector2(30, 30)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ic := ScreenKit.icon("p_" + ("gear" if pid == "gearbox" else pid), 18, UiStyle.G_INK)
	ic.name = "Icon"
	dot.add_child(ic)
	h.add_child(dot)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -3)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := UiStyle.g_label("", 14, UiStyle.G_TEXT, "black")
	t.name = "Title"
	top.add_child(t)
	var al := PanelContainer.new()
	al.name = "Alert"
	al.mouse_filter = Control.MOUSE_FILTER_IGNORE
	al.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var al_l := UiStyle.g_label("", 10, Color.WHITE, "black")
	al_l.name = "L"
	al.add_child(al_l)
	top.add_child(al)
	v.add_child(top)
	var sub := UiStyle.g_label("", 12, UiStyle.G_TEXT_2, "bold")
	sub.name = "Sub"
	v.add_child(sub)
	h.add_child(v)
	b.add_child(panel)
	b.pressed.connect(func() -> void: part_pressed.emit(pid))
	panel.resized.connect(func() -> void: b.custom_minimum_size = panel.size; b.size = panel.size)
	ScreenKit.press_feedback(b)
	add_child(b)
	return b


func _fill_callout(b: Button, r: Dictionary) -> void:
	var on: bool = r["id"] == selected
	var panel: PanelContainer = b.get_node("Panel")
	var st := UiStyle.g_box(UiStyle.G_LIGHT if on else Color(0.04, 0.047, 0.063, 0.92), 14, 8, 6)
	st.content_margin_right = 12
	st.set_border_width_all(3 if on else 1)
	st.border_color = c1 if on else Color(1, 1, 1, 0.1)
	panel.add_theme_stylebox_override("panel", st)
	var dot: PanelContainer = panel.get_node("HBoxContainer/Dot") if panel.has_node("HBoxContainer/Dot") else _find(panel, "Dot")
	dot.add_theme_stylebox_override("panel", UiStyle.g_box(Color(r["color"]), 15, 6, 6))
	var t: Label = _find(panel, "Title")
	t.text = r["title"]
	t.add_theme_color_override("font_color", UiStyle.G_INK if on else UiStyle.G_TEXT)
	var sub: Label = _find(panel, "Sub")
	sub.text = r["sub"]
	sub.add_theme_color_override("font_color", UiStyle.G_INK_2 if on else UiStyle.G_TEXT_2)
	var al: PanelContainer = _find(panel, "Alert")
	al.visible = String(r.get("alert", "")) != ""
	if al.visible:
		var yellow: bool = r.get("alert_kind", "") == "warn"
		al.add_theme_stylebox_override("panel", UiStyle.g_box(Color("#ffd24a") if yellow else UiStyle.RED, 6, 6, 1))
		var l: Label = _find(al, "L")
		l.text = r["alert"]
		l.add_theme_color_override("font_color", UiStyle.G_INK if yellow else Color.WHITE)


func _find(n: Node, nm: String) -> Node:
	return n.find_child(nm, true, false)


func _draw() -> void:
	# fundo do palco: cartão escuro com brilho da cor da equipe atrás do carro
	draw_style_box(UiStyle.g_box(Color(1, 1, 1, 0.035), 24), Rect2(Vector2.ZERO, size))
	var glow := Color(c1, 0.16)
	for i in 6:
		var k := 1.0 - i * 0.15
		draw_set_transform(car_origin + CAR_SIZE * 0.5, 0.0, Vector2(1.0, 0.55) * k)
		draw_circle(Vector2.ZERO, 380.0, Color(glow, glow.a * 0.35))
	draw_set_transform(Vector2.ZERO)
	_draw_car(car_origin)
	# linhas e pinos
	for pid: String in _labels:
		var b: Button = _labels[pid]
		var pin: Vector2 = car_origin + SPOTS[pid]["pin"]
		var from := b.position + Vector2(22, b.size.y * 0.5)
		draw_line(from, pin, Color(1, 1, 1, 0.5), 2.0, true)
	for pid: String in _labels:
		var pin: Vector2 = car_origin + SPOTS[pid]["pin"]
		var on := pid == selected
		if on:
			draw_circle(pin, 15.0, Color(UiStyle.RED, 0.3))
		draw_circle(pin, 8.0, Color.WHITE)
		draw_circle(pin, 5.0, UiStyle.RED if on else Color("#0b0c0f"))


# --- desenho do carro (mesma arte do mockup, bico para a direita) --------------------------------

func _q(p0: Vector2, c: Vector2, p1: Vector2, n: int = 8) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(1, n + 1):
		var t := float(i) / n
		out.append(p0.lerp(c, t).lerp(c.lerp(p1, t), t))
	return out


func _poly(o: Vector2, pts: PackedVector2Array, col: Color) -> void:
	var moved := PackedVector2Array()
	for p in pts:
		moved.append(o + p)
	draw_colored_polygon(moved, col)


func _rrect(o: Vector2, r: Rect2, radius: float, col: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(int(radius))
	sb.anti_aliasing = true
	draw_style_box(sb, Rect2(o + r.position, r.size))


func _tyre(o: Vector2, r: Rect2) -> void:
	_rrect(o, r, 12, Color("#121316"))
	_rrect(o, Rect2(r.position + Vector2(8, 6), Vector2(r.size.x - 16, 3)), 1, Color("#2b2f36"))
	_rrect(o, Rect2(r.position + Vector2(8, r.size.y - 9), Vector2(r.size.x - 16, 3)), 1, Color("#2b2f36"))


func _body() -> PackedVector2Array:
	var p := PackedVector2Array([Vector2(70, 116), Vector2(150, 110), Vector2(192, 96)])
	p.append_array(_q(Vector2(192, 96), Vector2(232, 72), Vector2(300, 70)))
	p.append(Vector2(392, 74))
	p.append_array(_q(Vector2(392, 74), Vector2(424, 78), Vector2(446, 98)))
	p.append_array([Vector2(476, 112), Vector2(560, 118), Vector2(652, 124), Vector2(664, 130)])
	var half := p.duplicate()
	var out := PackedVector2Array(half)
	for i in range(half.size() - 2, -1, -1):  # espelha a metade de cima
		out.append(Vector2(half[i].x, 260.0 - half[i].y))
	return out


func _draw_car(o: Vector2) -> void:
	var shadow := PackedVector2Array()
	for i in 40:
		var a := TAU * i / 40.0
		shadow.append(Vector2(340 + cos(a) * 330, 132 + sin(a) * 56))
	_poly(o, shadow, Color(0, 0, 0, 0.4))
	var arm := Color("#3a3f48")
	for seg: Array in [[150, 98, 142, 62], [175, 100, 160, 62], [150, 162, 142, 198], [175, 160, 160, 198],
			[520, 118, 572, 64], [556, 120, 592, 64], [520, 142, 572, 196], [556, 140, 592, 196]]:
		draw_line(o + Vector2(seg[0], seg[1]), o + Vector2(seg[2], seg[3]), arm, 5.0, true)
	_tyre(o, Rect2(100, 18, 96, 52))
	_tyre(o, Rect2(100, 190, 96, 52))
	_tyre(o, Rect2(546, 24, 76, 44))
	_tyre(o, Rect2(546, 192, 76, 44))
	# assoalho
	var floor_pts := PackedVector2Array([Vector2(176, 60), Vector2(430, 72), Vector2(470, 96), Vector2(470, 164), Vector2(430, 188),
		Vector2(176, 200), Vector2(160, 180), Vector2(160, 80)])
	_poly(o, floor_pts, Color("#15171b"))
	_rrect(o, Rect2(56, 112, 60, 36), 6, Color("#1d2026"))
	# carroceria com luz em cima e sombra embaixo
	var body := _body()
	_poly(o, body, c1)
	var top := PackedVector2Array()
	for p in body:
		if p.y <= 130.0:
			top.append(p)
	_poly(o, top, Color(1, 1, 1, 0.12))
	_poly(o, PackedVector2Array([Vector2(96, 125), Vector2(340, 116), Vector2(446, 120), Vector2(446, 140), Vector2(340, 144), Vector2(96, 135)]), Color(c2, 0.9))
	for side: float in [1.0, -1.0]:  # entradas de ar dos sidepods
		var y0 := 130.0 - 50.0 * side
		var y1 := 130.0 - 32.0 * side
		_poly(o, PackedVector2Array([Vector2(380, y0), Vector2(428, y1), Vector2(396, y1)]), Color("#0d0e11"))
	# cockpit, piloto e halo
	var ck := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		ck.append(Vector2(478 + cos(a) * 34, 130 + sin(a) * 15))
	_poly(o, ck, Color("#0d0e11"))
	draw_circle(o + Vector2(470, 130), 9.0, c2)
	var halo := PackedVector2Array([o + Vector2(444, 130)])
	for p in _q(Vector2(444, 130), Vector2(476, 100), Vector2(510, 130), 10):
		halo.append(o + p)
	draw_polyline(halo, Color("#d9dde3"), 5.0, true)
	draw_line(o + Vector2(508, 130), o + Vector2(530, 130), Color("#d9dde3"), 4.0, true)
	# asa traseira
	_rrect(o, Rect2(20, 70, 44, 120), 5, c1)
	_rrect(o, Rect2(26, 70, 10, 120), 0, Color(c2, 0.85))
	_rrect(o, Rect2(16, 64, 52, 8), 3, Color("#1d2026"))
	_rrect(o, Rect2(16, 188, 52, 8), 3, Color("#1d2026"))
	# asa dianteira (três elementos)
	_rrect(o, Rect2(632, 30, 10, 200), 4, c1)
	_rrect(o, Rect2(645, 36, 8, 188), 4, c2)
	_rrect(o, Rect2(656, 44, 6, 172), 3, c1)
	_rrect(o, Rect2(628, 24, 38, 8), 3, Color("#1d2026"))
	_rrect(o, Rect2(628, 228, 38, 8), 3, Color("#1d2026"))
