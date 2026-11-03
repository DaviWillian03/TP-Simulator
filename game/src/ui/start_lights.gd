class_name StartLights
extends PanelContainer
## Semáforo da largada: cinco pares de luzes vermelhas acendem um a um (como na F1) e, depois de uma espera
## curta e imprevisível, apagam todas juntas — é a largada. Some sozinho em seguida.

signal light_on(index: int)
signal lights_out
signal finished

const COUNT := 5
const STEP_S := 0.8  ## intervalo entre as luzes
const LAMP := 30.0

var _lamps: Array[Control] = []
var _lit := 0
var _out := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", UiStyle.g_box(Color(0.02, 0.025, 0.03, 0.92), 18, 16, 12))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(h)
	for i in COUNT:
		var col := VBoxContainer.new()  # cada coluna tem duas lâmpadas, como no pórtico real
		col.add_theme_constant_override("separation", 6)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for k in 2:
			var lamp := _Lamp.new()
			lamp.custom_minimum_size = Vector2(LAMP, LAMP)
			col.add_child(lamp)
			_lamps.append(lamp)
		h.add_child(col)
	# centraliza sob a âncora (o pai define a âncora no topo central)
	resized.connect(func() -> void:
		offset_left = -size.x / 2.0
		offset_right = size.x / 2.0)


## hold_s: espera depois da quinta luz (sorteada pela tela; na F1 varia de largada para largada).
func start(hold_s: float) -> void:
	var tw := create_tween()
	for i in COUNT:
		tw.tween_interval(STEP_S)
		tw.tween_callback(_light.bind(i))
	tw.tween_interval(hold_s)
	tw.tween_callback(_all_out)
	tw.tween_interval(0.7)
	tw.tween_property(self, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func() -> void:
		finished.emit()
		queue_free())


func is_out() -> bool:
	return _out


func lit_count() -> int:
	return _lit


func _light(i: int) -> void:
	_lit = i + 1
	for k in 2:
		(_lamps[i * 2 + k] as _Lamp).on = true
		_lamps[i * 2 + k].queue_redraw()
	light_on.emit(i)


func _all_out() -> void:
	_out = true
	_lit = 0
	for l in _lamps:
		(l as _Lamp).on = false
		l.queue_redraw()
	lights_out.emit()


class _Lamp:
	extends Control
	var on := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0
		draw_circle(c, r, Color("#1a1c20"), true, -1.0, true)
		if on:
			draw_circle(c, r * 1.25, Color(1.0, 0.1, 0.05, 0.25), true, -1.0, true)  # brilho
			draw_circle(c, r - 2.0, UiStyle.RED, true, -1.0, true)
			draw_circle(c + Vector2(-r * 0.3, -r * 0.3), r * 0.25, Color(1, 0.6, 0.55, 0.8), true, -1.0, true)
		else:
			draw_circle(c, r - 2.0, Color("#2a1012"), true, -1.0, true)
