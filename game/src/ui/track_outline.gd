class_name TrackOutline
extends Control
## Desenho do traçado. Padrão: linha de tinta (telas antigas). Na Garagem: linha clara com
## brilho em camadas (sem desfoque), grade de mapa ao fundo e ponto vermelho na largada.

var points := PackedVector2Array()
var line_color := UiStyle.INK
var line_width := 6.0
var glow_color := Color(0, 0, 0, 0)  ## alfa 0 = sem brilho
var grid := false
var start_dot := false
var pad := 18.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_circuit(circuit: Dictionary) -> void:
	points.clear()
	for p: Array in circuit.get("points", []):
		points.append(Vector2(float(p[0]), float(p[1])))
	queue_redraw()


func _draw() -> void:
	if grid:  # grade de mapa recortada numa elipse (some nas bordas, sem formar uma caixa)
		var c := size / 2.0
		var rx := size.x * 0.55
		var ry := size.y * 0.55
		var x := fposmod(c.x, 40.0)
		while x <= size.x:
			var t := (x - c.x) / rx
			if absf(t) < 1.0:
				var dy := ry * sqrt(1.0 - t * t)
				draw_line(Vector2(x, c.y - dy), Vector2(x, c.y + dy), Color(1, 1, 1, 0.05 * (1.0 - absf(t))), 1.0)
			x += 40.0
		var y := fposmod(c.y, 40.0)
		while y <= size.y:
			var t := (y - c.y) / ry
			if absf(t) < 1.0:
				var dx := rx * sqrt(1.0 - t * t)
				draw_line(Vector2(c.x - dx, y), Vector2(c.x + dx, y), Color(1, 1, 1, 0.05 * (1.0 - absf(t))), 1.0)
			y += 40.0
	if points.size() < 2:
		return
	var r := Rect2(points[0], Vector2.ZERO)
	for p in points:
		r = r.expand(p)
	var k := minf((size.x - pad * 2) / maxf(r.size.x, 1.0), (size.y - pad * 2) / maxf(r.size.y, 1.0))
	var off := (size - r.size * k) / 2.0
	var line := PackedVector2Array()
	for p in points:
		line.append((p - r.position) * k + off)
	line.append(line[0])
	if glow_color.a > 0.0:
		for i in range(4, 0, -1):
			_round_line(line, Color(glow_color, glow_color.a * 0.22), line_width + i * 7.0)
	_round_line(line, line_color, line_width)
	if start_dot:
		draw_circle(line[0], line_width * 0.95, UiStyle.RED)


## Linha com junções redondas (as linhas grossas do Godot fazem pontas nas curvas fechadas).
func _round_line(line: PackedVector2Array, color: Color, width: float) -> void:
	draw_polyline(line, color, width, true)
	if width >= 5.0 and color.a >= 0.99:  # (em camadas translúcidas os círculos se somariam)
		for p in line:
			draw_circle(p, width / 2.0, color)
