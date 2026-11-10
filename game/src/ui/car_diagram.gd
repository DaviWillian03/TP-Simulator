class_name CarDiagram
extends Control
## Carro da equipe visto de cima (nariz para cima), genérico e sem marcas: mostra o estado de cada peça (asa dianteira, asa
## traseira, assoalho, suspensão, motor/câmbio) e das rodas (cor = vida do pneu). Peça com problema ganha uma exclamação:
## amarela (desgaste) ou vermelha (dano / mau funcionamento). Mesmo desenho no cartão do piloto (pequeno) e na folha.

const BASE := Vector2(300, 420)
const NAMES := {"front_wing": "Asa dianteira", "rear_wing": "Asa traseira", "floor": "Assoalho", "susp": "Suspensão", "pu": "Motor / câmbio"}
const MARK_AT := {"front_wing": Vector2(150, 29), "susp": Vector2(94, 104), "floor": Vector2(226, 262), "pu": Vector2(150, 268), "rear_wing": Vector2(150, 369)}

var car: CarState
var mark_radius := 15.0  ## no cartão pequeno o marcador é maior em relação ao carro
var _sig := ""


func setup(p_car: CarState, p_mark_radius: float = 15.0) -> void:
	car = p_car
	mark_radius = p_mark_radius
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	refresh()


## Cor do estado de uma peça (0 ok, 1 desgaste, 2 dano) e do pneu (vida).
static func state_color(state: int) -> Color:
	return [Color(1, 1, 1, 0.28), UiStyle.G_WARN, UiStyle.G_BAD][clampi(state, 0, 2)]


static func wheel_state(c: CarState) -> int:
	if c.punctured:
		return 2
	return 0 if c.tyre_wear < 0.5 else (1 if c.tyre_wear < 0.75 else 2)


## Redesenha só quando algo mudou (o cartão chama isto a cada quadro).
func refresh() -> void:
	if car == null:
		return
	var s := "%d%d%d%d%d|%d" % [car.part_state("front_wing"), car.part_state("rear_wing"), car.part_state("floor"),
		car.part_state("susp"), car.part_state("pu"), wheel_state(car)]
	if s != _sig:
		_sig = s
		queue_redraw()


func _box(rect: Rect2, state: int, radius: int, width: int = 4) -> void:
	var sb := StyleBoxFlat.new()
	var edge := state_color(state)
	sb.bg_color = Color(edge, 0.16 if state == 0 else 0.30) if state > 0 else Color(1, 1, 1, 0.10)
	sb.border_color = edge
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(radius)
	draw_style_box(sb, rect)


func _draw() -> void:
	if car == null:
		return
	var k := minf(size.x / BASE.x, size.y / BASE.y)
	if k <= 0.0:
		return
	draw_set_transform((size - BASE * k) / 2.0, 0.0, Vector2(k, k))
	var body := UiStyle.team_accent(car.team)
	var wc := state_color(wheel_state(car))
	if wheel_state(car) == 0:
		wc = UiStyle.G_UP
	var sus := state_color(car.part_state("susp"))
	for d: Array in [[Vector2(60, 92), Vector2(128, 112)], [Vector2(60, 120), Vector2(128, 126)], [Vector2(240, 92), Vector2(172, 112)], [Vector2(240, 120), Vector2(172, 126)]]:
		draw_line(d[0], d[1], sus if car.part_state("susp") > 0 else Color(1, 1, 1, 0.20), 5.0, true)
	for r: Rect2 in [Rect2(14, 66, 46, 70), Rect2(240, 66, 46, 70), Rect2(10, 238, 50, 86), Rect2(240, 238, 50, 86)]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = UiStyle.G_BG
		sb.border_color = wc
		sb.set_border_width_all(4)
		sb.set_corner_radius_all(9)
		draw_style_box(sb, r)
	draw_colored_polygon(PackedVector2Array([Vector2(136, 52), Vector2(164, 52), Vector2(162, 118), Vector2(138, 118)]), body)
	draw_colored_polygon(PackedVector2Array([Vector2(104, 120), Vector2(196, 120), Vector2(210, 212), Vector2(188, 296), Vector2(112, 296), Vector2(90, 212)]), body)
	var cover := StyleBoxFlat.new()
	cover.bg_color = Color(0, 0, 0, 0.45)
	cover.set_corner_radius_all(14)
	draw_style_box(cover, Rect2(132, 150, 36, 150))
	var cockpit := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		cockpit.append(Vector2(150 + cos(a) * 13.0, 178 + sin(a) * 20.0))
	draw_colored_polygon(cockpit, UiStyle.G_INK)
	var fl := car.part_state("floor")
	var fc := state_color(fl)
	for ln: Array in [[Vector2(78, 150), Vector2(108, 150)], [Vector2(222, 150), Vector2(192, 150)], [Vector2(70, 180), Vector2(106, 186)], [Vector2(230, 180), Vector2(194, 186)]]:
		draw_line(ln[0], ln[1], fc if fl > 0 else Color(1, 1, 1, 0.20), 5.0, true)
	var dif := PackedVector2Array([Vector2(96, 300), Vector2(82, 322), Vector2(218, 322), Vector2(204, 300)])
	draw_colored_polygon(dif, Color(fc, 0.30) if fl > 0 else Color(1, 1, 1, 0.10))
	draw_polyline(PackedVector2Array([dif[0], dif[1], dif[2], dif[3], dif[0]]), fc, 3.0, true)
	_box(Rect2(124, 236, 52, 64), car.part_state("pu"), 12)
	_box(Rect2(38, 14, 224, 30), car.part_state("front_wing"), 8)
	_box(Rect2(52, 352, 196, 34), car.part_state("rear_wing"), 8)
	for part: String in MARK_AT:
		var st := car.part_state(part)
		if st > 0:
			_mark(MARK_AT[part], state_color(st))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Exclamação desenhada (não é texto): círculo com barra e ponto.
func _mark(at: Vector2, col: Color) -> void:
	var r := mark_radius
	draw_circle(at, r + 3.0, UiStyle.G_BG, true, -1.0, true)
	draw_circle(at, r, col, true, -1.0, true)
	var bar := StyleBoxFlat.new()
	bar.bg_color = UiStyle.G_INK
	bar.set_corner_radius_all(int(r * 0.18) + 1)
	draw_style_box(bar, Rect2(at.x - r * 0.14, at.y - r * 0.55, r * 0.28, r * 0.72))
	draw_circle(at + Vector2(0, r * 0.42), r * 0.17, UiStyle.G_INK, true, -1.0, true)
