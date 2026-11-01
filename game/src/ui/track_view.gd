class_name TrackView
extends Control
## Desenha o circuito e os carros (bolinhas nas cores da equipe) a partir do estado da RaceSim.

const MARGIN := 28.0
const CAR_RADIUS := 6.5
const PLAYER_RADIUS := 8.0
const PIT_OFFSET_PX := 14.0

var sim: RaceSim
var _scale := 1.0
var _offset := Vector2.ZERO
var _track_pts := PackedVector2Array()
var _pit_pts := PackedVector2Array()
var _font: Font


func setup(p_sim: RaceSim) -> void:
	sim = p_sim
	_font = UiStyle.BOLD_FONT
	resized.connect(_recompute)
	_recompute()


func _recompute() -> void:
	if sim == null or size.x <= 0.0:
		return
	var b := sim.track.bounds()
	var avail := size - Vector2(MARGIN, MARGIN) * 2.0
	_scale = minf(avail.x / b.size.x, avail.y / b.size.y)
	_offset = Vector2(MARGIN, MARGIN) + (avail - b.size * _scale) / 2.0 - b.position * _scale
	_track_pts.clear()
	for p in sim.track.points:
		_track_pts.append(to_screen(p))
	_track_pts.append(_track_pts[0])
	# pit lane: linha paralela, do lado de dentro, entre a entrada e a saída
	_pit_pts.clear()
	var entry := sim.track.pit_entry_frac
	var span := 1.0 - entry + sim.track.pit_exit_frac
	for i in 41:
		var f := entry + span * i / 40.0
		_pit_pts.append(to_screen(sim.track.position_at(f)) + _inside_normal(f) * PIT_OFFSET_PX)
	queue_redraw()


func to_screen(p: Vector2) -> Vector2:
	return p * _scale + _offset


## Vetor para o lado de dentro da curva (à esquerda do sentido de corrida em pistas anti-horárias).
func _inside_normal(frac: float) -> Vector2:
	var d := sim.track.direction_at(frac)
	return Vector2(d.y, -d.x)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if sim == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("#0D1A17"))
	# pit lane, bordas e asfalto
	draw_polyline(_pit_pts, Color("#3A4A66"), 4.0, true)
	draw_polyline(_track_pts, Color("#C9D4E8"), 16.0, true)
	draw_polyline(_track_pts, Color("#2B3954"), 12.0, true)
	# linha de chegada
	var p0 := to_screen(sim.track.position_at(0.0))
	var n0 := _inside_normal(0.0)
	draw_line(p0 - n0 * 9.0, p0 + n0 * 9.0, Color.WHITE, 3.0)
	# pontos de freada onde se ultrapassa
	for z: Dictionary in sim.track.overtaking_zones:
		var zp := to_screen(sim.track.position_at(float(z["braking_frac"])))
		draw_circle(zp, 3.0, UiStyle.ACCENT_2, true, -1.0, true)

	# carros: de trás para frente, para o líder ficar por cima
	var order := sim.standings()
	for i in range(order.size() - 1, -1, -1):
		_draw_car(order[i])


func _draw_car(car: CarState) -> void:
	var d := sim.render_distance(car)
	var frac := fposmod(d, sim.track.length_m) / sim.track.length_m
	var pos := to_screen(sim.track.position_at(frac))
	if car.in_pit:
		pos += _inside_normal(frac) * PIT_OFFSET_PX
	elif d < 0.0:
		# no grid de largada, os carros ficam em duas filas
		pos += _inside_normal(frac) * (4.0 if car.grid_position % 2 == 0 else -4.0)
	var r := PLAYER_RADIUS if car.is_player else CAR_RADIUS
	if car.is_player:
		draw_circle(pos, r + 4.0, Color(1, 1, 1, 0.9), false, 2.0, true)
	draw_circle(pos, r + 1.5, car.team_color2(), true, -1.0, true)
	draw_circle(pos, r, car.team_color(), true, -1.0, true)
	if car.is_player:
		draw_string_outline(_font, pos + Vector2(-14, -14), car.code(), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, UiStyle.BG)
		draw_string(_font, pos + Vector2(-14, -14), car.code(), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
