class_name RdTreeView
extends Control
## Árvore de um departamento (mockup v9-1, inspirada no F1 2017): centro com o nome e o progresso,
## quatro braços (categorias) com nós hexagonais (menor), quadrados (importante) e quadrados
## grandes (definitiva). Estados: feito (cor do braço + visto), em pesquisa (anel com os dias),
## aberto (contorno claro) e bloqueado (apagado com cadeado). Tocar num nó o seleciona.

signal node_pressed(id: String)

const K := 0.83  ## escala das distâncias do JSON (cabe em 600×560)
const ARM_COLORS := [Color("#ffd24a"), Color("#3c9d5d"), Color("#5c93ea"), Color("#ff6a5a")]
const DIRS := [[Vector2(0, -1), Vector2(1, 0)], [Vector2(1, 0), Vector2(0, 1)], [Vector2(0, 1), Vector2(-1, 0)], [Vector2(-1, 0), Vector2(0, -1)]]
const HUB_R := 64.0
const TOUCH_R := 26.0

var dev: CarDevelopment
var camp: Campaign
var car := "cur"
var dept := "aero"
var selected := ""
var _pos: Dictionary = {}  # id -> Vector2


func show_department(p_car: String, p_dept: String) -> void:
	car = p_car
	dept = p_dept
	queue_redraw()


func select(id: String) -> void:
	selected = id
	queue_redraw()


func node_position(id: String) -> Vector2:
	_layout()
	return _pos.get(id, Vector2.ZERO)


func _layout() -> void:
	_pos.clear()
	var c := size / 2.0
	var dep := CarDevelopment.department(dept)
	for a in dep["arms"].size():
		var dir: Vector2 = DIRS[a][0]
		var lat: Vector2 = DIRS[a][1]
		var nodes: Array = dep["arms"][a]["nodes"]
		for i in nodes.size():
			var n: Dictionary = nodes[i]
			_pos[CarDevelopment.node_id(dept, a, i)] = c + (dir * float(n["d"]) + lat * float(n["l"])) * K


func _gui_input(e: InputEvent) -> void:
	var mb := e as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	_layout()
	var best := ""
	var best_d := TOUCH_R
	for id: String in _pos:
		var d: float = (_pos[id] as Vector2).distance_to(mb.position)
		if d < best_d:
			best_d = d
			best = id
	if best != "":
		selected = best
		queue_redraw()
		node_pressed.emit(best)


func _draw() -> void:
	if dev == null or camp == null:
		return
	_layout()
	var c := size / 2.0
	var dep := CarDevelopment.department(dept)
	var locked := not dev.dept_available(dept, camp)
	var hub_color := Color(dep["color"]) if not locked else Color("#4b5260")
	# diagonais (outros departamentos), como na árvore do F1 2017
	for d: Vector2 in [Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1)]:
		draw_line(c + d * HUB_R, c + d * 150.0, Color(1, 0.42, 0.35, 0.4), 2.0, true)
	draw_arc(c, 94.0, 0.0, TAU, 64, Color(hub_color, 0.28), 10.0, true)
	draw_circle(c, HUB_R, Color("#0f1116"), true, -1.0, true)
	draw_arc(c, HUB_R, 0.0, TAU, 64, hub_color, 3.0, true)
	var total := 0
	var count := 0
	for id: String in CarDevelopment.all_node_ids(dept):
		total += 1
		if dev.is_done(car, id):
			count += 1
	var title: String = String(dep["name"]).to_upper()
	var font := UiStyle.G_BLACK
	draw_string(font, c + Vector2(-HUB_R, -2), title, HORIZONTAL_ALIGNMENT_CENTER, HUB_R * 2.0, UiStyle.fs(15), UiStyle.G_TEXT)
	draw_string(UiStyle.G_BOLD, c + Vector2(-HUB_R, 17), "%d / %d · %d%%" % [count, total, roundi(100.0 * count / maxf(total, 1))] if not locked else "motor do fornecedor",
		HORIZONTAL_ALIGNMENT_CENTER, HUB_R * 2.0, UiStyle.fs(12), UiStyle.G_TEXT_2)
	for a in dep["arms"].size():
		var arm_col: Color = ARM_COLORS[a] if not locked else Color("#4b5260")
		var nodes: Array = dep["arms"][a]["nodes"]
		for i in nodes.size():
			var id := CarDevelopment.node_id(dept, a, i)
			var parent: int = int(nodes[i]["p"])
			var from: Vector2 = (c + (DIRS[a][0] as Vector2) * HUB_R) if parent < 0 else _pos[CarDevelopment.node_id(dept, a, parent)]
			var st := dev.node_state(car, id, camp)
			var lit := st == "done" or st == "now"
			draw_line(from, _pos[id], arm_col if lit else Color(1, 1, 1, 0.28), 3.0 if lit else 2.0, true)
		for i in nodes.size():
			var id := CarDevelopment.node_id(dept, a, i)
			_draw_node(_pos[id], String(nodes[i]["k"]), dev.node_state(car, id, camp), arm_col, id == selected, id)


func _draw_node(p: Vector2, kind: String, state: String, col: Color, sel: bool, id: String) -> void:
	var fill := col if state == "done" else Color("#0b0c0f")
	var stroke := col if state in ["done", "now"] else (Color("#eef0f3") if state == "open" else Color("#4b5260"))
	var ink := Color("#11141a") if state == "done" else Color("#eef0f3")
	if sel:
		draw_arc(p, 31.0 if kind == "d" else 26.0, 0.0, TAU, 40, Color.WHITE, 2.4, true)
	match kind:
		"m":
			var pts := PackedVector2Array()
			for k in 6:
				pts.append(p + Vector2(16.0, 0.0).rotated(deg_to_rad(60.0 * k + 30.0)))
			draw_colored_polygon(pts, fill)
			pts.append(pts[0])
			draw_polyline(pts, stroke, 2.4, true)
		"i":
			_rounded_square(p, 15.0, 6.0, fill, stroke, 2.4)
		_:
			_rounded_square(p, 21.0, 8.0, fill, stroke, 2.4)
			_rounded_square(p, 15.0, 5.0, Color(0, 0, 0, 0), Color(stroke, 0.7), 1.4)
	match state:
		"done":
			draw_polyline(PackedVector2Array([p + Vector2(-6, 0), p + Vector2(-2, 4), p + Vector2(6, -4)]), ink, 3.0, true)
		"now":
			var pr := dev.project_of(car, id)
			var frac := 1.0 - float(pr.get("days_left", 1)) / maxf(float(pr.get("days_total", 1)), 1.0)
			var r := 28.0 if kind == "d" else 22.0
			draw_arc(p, r, 0.0, TAU, 48, Color(1, 1, 1, 0.14), 4.0, true)
			draw_arc(p, r, -PI / 2.0, -PI / 2.0 + TAU * clampf(frac, 0.02, 1.0), 48, col, 4.0, true)
			draw_string(UiStyle.G_BLACK, p + Vector2(-16, 5), "%dd" % int(pr.get("days_left", 0)), HORIZONTAL_ALIGNMENT_CENTER, 32.0, UiStyle.fs(13), ink)
		"lock":
			draw_rect(Rect2(p + Vector2(-4.5, -1), Vector2(9, 7)), stroke)
			draw_arc(p + Vector2(0, -1), 3.0, PI, TAU, 10, stroke, 1.6, true)
		_:
			draw_circle(p, 2.6, ink, true, -1.0, true)


func _rounded_square(p: Vector2, half: float, radius: float, fill: Color, stroke: Color, width: float) -> void:
	var st := StyleBoxFlat.new()
	st.bg_color = fill
	st.set_corner_radius_all(int(radius))
	st.border_color = stroke
	st.set_border_width_all(int(ceilf(width)) if stroke.a > 0.0 else 0)
	st.anti_aliasing = true
	draw_style_box(st, Rect2(p - Vector2(half, half), Vector2(half, half) * 2.0))
