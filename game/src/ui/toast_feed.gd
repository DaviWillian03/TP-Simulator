class_name ToastFeed
extends VBoxContainer
## Avisos curtos e não intrusivos ("selos" na página). Somem sozinhos e não bloqueiam toques.

const MAX_VISIBLE := 3
const LIFETIME_S := 4.5


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 8)


## kind: "hot" (vermelho cheio, eventos do jogador) ou "note" (contorno de tinta, informativo).
func push(text: String, kind: String = "note") -> void:
	var p: PanelContainer
	if kind == "hot":
		p = UiStyle.stamp(text, 14)
	else:
		p = PanelContainer.new()
		p.add_theme_stylebox_override("panel", UiStyle.outline_box(UiStyle.PAPER, UiStyle.INK))
		p.add_child(UiStyle.label(text, 13))
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	add_child(p)
	while get_child_count() > MAX_VISIBLE:
		var old := get_child(0)
		remove_child(old)
		old.queue_free()
	var tw := p.create_tween()
	tw.tween_interval(LIFETIME_S)
	tw.tween_property(p, "modulate:a", 0.0, 0.5)
	tw.tween_callback(p.queue_free)
