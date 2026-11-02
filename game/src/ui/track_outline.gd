class_name TrackOutline
extends Control
## Desenho do traçado (linha grossa de tinta) para a escolha do circuito.

var points := PackedVector2Array()


func set_circuit(circuit: Dictionary) -> void:
	points.clear()
	for p: Array in circuit.get("points", []):
		points.append(Vector2(float(p[0]), float(p[1])))
	queue_redraw()


func _draw() -> void:
	if points.size() < 2:
		return
	var r := Rect2(points[0], Vector2.ZERO)
	for p in points:
		r = r.expand(p)
	var pad := 18.0
	var k := minf((size.x - pad * 2) / maxf(r.size.x, 1.0), (size.y - pad * 2) / maxf(r.size.y, 1.0))
	var off := (size - r.size * k) / 2.0
	var line := PackedVector2Array()
	for p in points:
		line.append((p - r.position) * k + off)
	line.append(line[0])
	draw_polyline(line, UiStyle.INK, 6.0, true)
