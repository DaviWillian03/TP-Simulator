class_name HqCampus
extends Control
## Sede da equipe em isometria (mockup v26-5): um prédio por instalação, na cor da instalação, com o nível em cima.
## Desenhada em código (polígonos), leve no celular. Toque num prédio emite `picked(id)`.

signal picked(id: String)

## [id, x, y, largura, profundidade, altura] na grade da sede (0..18 × 0..14)
const LAYOUT := {"factory": [1.0, 1.0, 7.0, 3.6, 1.8], "wind": [10.0, 1.0, 6.5, 2.4, 1.6], "design": [6.0, 6.5, 3.6, 3.6, 4.2],
	"sim": [1.0, 7.0, 3.4, 3.2, 2.2], "drivers": [11.5, 6.0, 4.6, 3.0, 1.4], "hosp": [11.5, 11.0, 5.0, 2.2, 1.1]}

var colors: Dictionary = {}  ## id -> Color


static func default_colors() -> Dictionary:
	return {"factory": Color("#FF8A1F"), "wind": Color("#22C7E8"), "design": Color("#4C8DFF"), "sim": Color("#A66BFF"),
		"drivers": Color("#2FD38A"), "hosp": Color("#F5C542")}
var levels: Dictionary = {}  ## id -> [nível, máximo]; vazio = sem selos
var icons: Dictionary = {}  ## id -> nome do ícone (selos)
var selected := ""
var unit := 30.0  ## tamanho de uma unidade da grade em px
var origin := Vector2(430, 150)
var _polys: Dictionary = {}  ## id -> PackedVector2Array do contorno (toque)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS if picked.get_connections().size() > 0 else Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	_badges()


## Ajusta origem e unidade para o campus caber no tamanho dado (chão de −1..19 × −1..15: ~31,2 × 18,6 unidades).
func fit(area: Vector2) -> void:
	unit = minf(area.x / 31.6, area.y / 19.0)
	origin = Vector2((area.x - 31.2 * unit) / 2.0 + 13.86 * unit, (area.y - 18.6 * unit) / 2.0 + 1.6 * unit)
	queue_redraw()
	if is_inside_tree():
		_place_badges.call_deferred()


func p(x: float, y: float, z := 0.0) -> Vector2:
	return origin + Vector2((x - y) * 0.866 * unit, (x + y) * 0.5 * unit - z * unit)


func _draw() -> void:
	_polys.clear()
	var ground := PackedVector2Array([p(-1, -1), p(19, -1), p(19, 15), p(-1, 15)])
	draw_colored_polygon(ground, Color("#1f3b2f"))
	draw_colored_polygon(PackedVector2Array([p(-1, 15), p(19, 15), p(19, 15, -0.6), p(-1, 15, -0.6)]), Color("#132219"))
	draw_colored_polygon(PackedVector2Array([p(19, -1), p(19, 15), p(19, 15, -0.6), p(19, -1, -0.6)]), Color("#0e1912"))
	var road := Color("#3a3f48")
	draw_colored_polygon(PackedVector2Array([p(-0.5, 5), p(18.5, 5), p(18.5, 5.8), p(-0.5, 5.8)]), road)
	draw_colored_polygon(PackedVector2Array([p(9.9, 5.8), p(10.7, 5.8), p(10.7, 14.5), p(9.9, 14.5)]), road)
	draw_colored_polygon(PackedVector2Array([p(1, 11.2), p(9, 11.2), p(9, 14), p(1, 14)]), Color("#2b4a3a"))
	for i in 6:
		var x0 := 1.5 + i * 1.2
		draw_colored_polygon(PackedVector2Array([p(x0, 12), p(x0 + 0.6, 12), p(x0 + 0.6, 13.4), p(x0, 13.4)]), Color("#e8edf3"))
	var ids := LAYOUT.keys()
	ids.sort_custom(func(a: String, b: String) -> bool: return LAYOUT[a][0] + LAYOUT[a][1] < LAYOUT[b][0] + LAYOUT[b][1])
	for id: String in ids:
		var b: Array = LAYOUT[id]
		var col: Color = colors.get(id, Color("#8f98a7"))
		if selected != "" and id != selected:
			col = col.darkened(0.4)
		_box(id, b[0], b[1], b[2], b[3], b[4], col)
		if id == selected:
			var o := PackedVector2Array([p(b[0] - 0.3, b[1] - 0.3), p(b[0] + b[2] + 0.3, b[1] - 0.3), p(b[0] + b[2] + 0.3, b[1] + b[3] + 0.3), p(b[0] - 0.3, b[1] + b[3] + 0.3), p(b[0] - 0.3, b[1] - 0.3)])
			draw_polyline(o, Color.WHITE, 3.0, true)


func _box(id: String, x: float, y: float, w: float, d: float, h: float, col: Color) -> void:
	var left := PackedVector2Array([p(x, y + d), p(x + w, y + d), p(x + w, y + d, h), p(x, y + d, h)])
	var right := PackedVector2Array([p(x + w, y), p(x + w, y + d), p(x + w, y + d, h), p(x + w, y, h)])
	var top := PackedVector2Array([p(x, y, h), p(x + w, y, h), p(x + w, y + d, h), p(x, y + d, h)])
	draw_colored_polygon(left, col.darkened(0.22))
	draw_colored_polygon(right, col.darkened(0.42))
	draw_colored_polygon(top, col.lightened(0.18))
	var n := maxi(int(w * 1.2), 2)
	for i in n:
		var fx := x + (i + 0.3) * w / n
		var ww := w / n * 0.45
		draw_colored_polygon(PackedVector2Array([p(fx, y + d, h * 0.35), p(fx + ww, y + d, h * 0.35), p(fx + ww, y + d, h * 0.7), p(fx, y + d, h * 0.7)]), Color(0.78, 0.92, 1.0, 0.55))
	_polys[id] = PackedVector2Array([p(x, y + d), p(x + w, y + d), p(x + w, y), p(x + w, y, h), p(x, y, h), p(x, y + d, h)])


## Topo central do prédio (para os selos de nível).
func roof_center(id: String) -> Vector2:
	var b: Array = LAYOUT[id]
	return p(b[0] + b[2] / 2.0, b[1] + b[3] / 2.0, b[4])


func _badges() -> void:
	for c in get_children():
		c.queue_free()
	if levels.is_empty():
		return
	for id: String in LAYOUT:
		if not levels.has(id):
			continue
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 4)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var chip := PanelContainer.new()
		chip.add_theme_stylebox_override("panel", UiStyle.g_box(colors.get(id, Color.GRAY), 9, 5, 4))
		chip.add_child(ScreenKit.icon(String(icons.get(id, "hq")), 18, UiStyle.G_INK))
		if id == selected:
			chip.get_theme_stylebox("panel").border_color = Color.WHITE
			(chip.get_theme_stylebox("panel") as StyleBoxFlat).set_border_width_all(3)
		h.add_child(chip)
		var lv: Array = levels[id]
		var l := UiStyle.g_label(str(lv[0]), 22, UiStyle.G_TEXT, "black")
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		l.add_theme_constant_override("shadow_offset_y", 2)
		h.add_child(l)
		var m := UiStyle.g_label("/%d" % int(lv[1]), 13, Color("#c3c9d3"), "black")
		m.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		h.add_child(m)
		h.set_meta("id", id)
		add_child(h)
	_place_badges.call_deferred()


func _place_badges() -> void:
	for h in get_children():
		if h.has_meta("id"):
			var c := roof_center(String(h.get_meta("id")))
			(h as Control).reset_size()
			(h as Control).position = c - Vector2((h as Control).size.x / 2.0, 46)


func refresh() -> void:
	queue_redraw()
	_badges()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT \
			or event is InputEventScreenTouch and event.pressed:
		var pos: Vector2 = event.position
		var ids := LAYOUT.keys()
		ids.sort_custom(func(a: String, b: String) -> bool: return LAYOUT[a][0] + LAYOUT[a][1] > LAYOUT[b][0] + LAYOUT[b][1])
		for id: String in ids:  # da frente para trás
			if _polys.has(id) and Geometry2D.is_point_in_polygon(pos, _polys[id]):
				picked.emit(id)
				accept_event()
				return
