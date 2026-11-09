class_name RingGauge
extends Control
## Anel de progresso com o valor no meio (mockups v26: posição dos pilotos, notas do carro, meta da diretoria).
## value 0..1; o centro mostra `text` (e `sub` embaixo) ou um ícone.

var value := 0.0:
	set(v):
		value = clampf(v, 0.0, 1.0)
		queue_redraw()
var color := Color("#4C8DFF")
var width := 6.0
var _main: Label
var _sub: Label


static func make(p_value: float, size: int, p_color: Color, text := "", sub := "", icon_name := "", p_width := 6.0) -> RingGauge:
	var r := RingGauge.new()
	r.value = p_value
	r.color = p_color
	r.width = p_width
	r.custom_minimum_size = Vector2(size, size)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", -4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_child(v)
	if icon_name != "":
		var ic := ScreenKit.icon(icon_name, int(size * 0.38), p_color)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(ic)
	if text != "":
		r._main = UiStyle.g_label(text, maxi(14, int(size * (0.3 if sub == "" else 0.27))), UiStyle.G_TEXT, "black")
		r._main.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(r._main)
	if sub != "":
		r._sub = UiStyle.g_label(sub, 12, UiStyle.G_TEXT_2, "bold")
		r._sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(r._sub)
	return r


func _draw() -> void:
	var c := size / 2.0
	var rad := minf(size.x, size.y) / 2.0 - width / 2.0 - 1.0
	draw_arc(c, rad, 0.0, TAU, 64, Color(1, 1, 1, 0.12), width, true)
	if value > 0.001:
		draw_arc(c, rad, -PI / 2.0, -PI / 2.0 + TAU * value, maxi(8, int(64 * value)), color, width, true)
