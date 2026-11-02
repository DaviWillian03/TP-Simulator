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
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if kind == "hot":  # evento que mexe com os seus carros: selo vermelho
		p.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.RED, 12, 14, 7))
		var l := UiStyle.g_label(text.to_upper(), 14, Color.WHITE, "black")
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(l)
	else:  # informativo: cartão escuro
		p.add_theme_stylebox_override("panel", UiStyle.g_box(Color(0.05, 0.06, 0.08, 0.9), 12, 14, 7))
		var l := UiStyle.g_label(text, 14, UiStyle.G_TEXT, "bold")
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(l)
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
