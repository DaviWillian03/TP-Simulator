class_name TrackView
extends Control
## Desenha o circuito (traço de tinta no papel) e os carros (bolinhas nas cores da equipe).

const MARGIN := 30.0
const TRACK_W := 9.0
const CAR_RADIUS := 6.0
const PLAYER_RADIUS := 7.5
const PIT_OFFSET_PX := 12.0

var sim: RaceSim
var _scale := 1.0
var _offset := Vector2.ZERO
var _track_pts := PackedVector2Array()
var _pit_pts := PackedVector2Array()


func setup(p_sim: RaceSim) -> void:
	sim = p_sim
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
	_track_pts.append(_track_pts[1])  # fecha a junção sem "dente" no traço grosso
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
	_draw_rain()
	draw_polyline(_pit_pts, Color(UiStyle.INK, 0.25), 3.0, true)
	draw_polyline(_track_pts, UiStyle.INK, TRACK_W, true)
	# linha de chegada: traço vermelho atravessando a pista
	var p0 := to_screen(sim.track.position_at(0.0))
	var n0 := _inside_normal(0.0)
	draw_line(p0 - n0 * 10.0, p0 + n0 * 10.0, UiStyle.RED, 4.0)
	# carros: de trás para frente, para o líder ficar por cima
	var order := sim.standings()
	for i in range(order.size() - 1, -1, -1):
		if not order[i].retired:
			_draw_car(order[i])
	if sim.control.flag == RaceControl.Flag.SC:
		_draw_safety_car(order[0])


## Chuva: traços diagonais azuis, mais densos/fortes conforme a intensidade.
func _draw_rain() -> void:
	var r := sim.weather.rain_now()
	var wet := sim.weather.wetness
	if r <= WeatherModel.RAIN_THRESHOLD and wet < 0.08:
		return
	if wet >= 0.08:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.12, 0.43, 0.9, 0.04 + 0.06 * wet))
	if r <= WeatherModel.RAIN_THRESHOLD:
		return
	var col := Color(0.12, 0.43, 0.9, 0.10 + 0.18 * r)
	var step := lerpf(34.0, 16.0, r)
	var slant := Vector2(-0.36, 1.0) * 14.0
	var offset := fposmod(sim.time_s * 60.0, step)
	var x := -size.y * 0.4 + offset
	while x < size.x + size.y * 0.4:
		var y := 0.0
		while y < size.y:
			var p := Vector2(x + y * 0.36, y + fposmod(x * 7.0, 23.0))
			draw_line(p, p + slant, col, 1.5)
			y += step * 1.7
		x += step


## Safety car: losango amarelo "SC" um pouco à frente do líder.
func _draw_safety_car(lead: CarState) -> void:
	var d := sim.render_distance(lead) + 70.0
	var pos := to_screen(sim.track.position_at(fposmod(d, sim.track.length_m) / sim.track.length_m))
	var pts := PackedVector2Array([pos + Vector2(0, -11), pos + Vector2(11, 0), pos + Vector2(0, 11), pos + Vector2(-11, 0)])
	draw_colored_polygon(pts, Color("#F5C400"))
	pts.append(pts[0])
	draw_polyline(pts, UiStyle.INK, 2.0, true)
	draw_string(UiStyle.HEAVY_FONT, pos + Vector2(-8, 4), "SC", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UiStyle.INK)


func _draw_car(car: CarState) -> void:
	var d := sim.render_distance(car)
	var frac := fposmod(d, sim.track.length_m) / sim.track.length_m
	var pos := to_screen(sim.track.position_at(frac))
	if car.in_pit:
		pos += _inside_normal(frac) * PIT_OFFSET_PX
	elif car.stall_s > 0.0:
		pos -= _inside_normal(frac) * PIT_OFFSET_PX  # rodou: fora do traçado
	elif d < 0.0:
		# no grid de largada, os carros ficam em duas filas
		pos += _inside_normal(frac) * (4.0 if car.grid_position % 2 == 0 else -4.0)
	var r := PLAYER_RADIUS if car.is_player else CAR_RADIUS
	if car.is_player:
		draw_circle(pos, r + 4.0, UiStyle.PAPER, true, -1.0, true)
		draw_circle(pos, r + 4.0, UiStyle.INK, false, 2.0, true)
	draw_circle(pos, r + 1.5, car.team_color2(), true, -1.0, true)
	draw_circle(pos, r, car.team_color(), true, -1.0, true)
	if car.is_player:
		var font := UiStyle.HEAVY_FONT
		var at := pos + Vector2(10, -10)
		draw_string_outline(font, at, car.code(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 6, UiStyle.PAPER)
		draw_string(font, at, car.code(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiStyle.INK)
