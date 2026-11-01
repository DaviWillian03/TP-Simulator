class_name ToastFeed
extends VBoxContainer
## Avisos curtos e não intrusivos sobre a corrida. Somem sozinhos e não bloqueiam toques.

const MAX_VISIBLE := 4
const LIFETIME_S := 4.5


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 6)


func push(text: String, accent: Color = UiStyle.ACCENT_2) -> void:
	var p := PanelContainer.new()
	var style := UiStyle.box(Color(0.07, 0.11, 0.19, 0.92), 8, accent, 0)
	style.border_width_left = 4
	p.add_theme_stylebox_override("panel", style)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UiStyle.label(text, 14)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	add_child(p)
	while get_child_count() > MAX_VISIBLE:
		var old := get_child(0)
		remove_child(old)
		old.queue_free()
	var tw := p.create_tween()
	tw.tween_interval(LIFETIME_S)
	tw.tween_property(p, "modulate:a", 0.0, 0.5)
	tw.tween_callback(p.queue_free)
