class_name ScreenTransition
extends CanvasLayer
## Transição entre telas (nova direção dos menus, 2026-11-13): duas faixas diagonais na cor da equipe entram pela
## esquerda, cobrem a tela, a troca de cena acontece por baixo e elas saem pela direita. Fica num CanvasLayer acima de
## tudo e sobrevive à troca de cena (é filho do Session, que é autoload).

const IN_S := 0.22
const OUT_S := 0.26


static func play(host: Node, color: Color, swap: Callable) -> void:
	var t := ScreenTransition.new()
	t.layer = 120
	host.add_child(t)
	t._run(color, swap)


func _run(color: Color, swap: Callable) -> void:
	var vp := get_viewport().get_visible_rect().size
	var w := vp.x * 1.7
	var bands: Array[Panel] = []
	for k in 2:
		var p := Panel.new()
		p.mouse_filter = Control.MOUSE_FILTER_STOP  # bloqueia toques durante a troca
		var st := StyleBoxFlat.new()
		st.bg_color = color if k == 0 else UiStyle.G_PODIUM_SHADE
		p.add_theme_stylebox_override("panel", st)
		p.size = Vector2(w, vp.y * 2.8)
		p.rotation_degrees = 16
		p.position = Vector2(-w - vp.y * 0.6 - k * 90.0, -vp.y * 1.0)
		add_child(p)
		bands.append(p)
	var cover_x := -vp.y * 0.35
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	for k in bands.size():
		tw.tween_property(bands[k], "position:x", cover_x - k * 40.0, IN_S).set_delay(k * 0.04)
	tw.chain().tween_callback(swap)
	tw.chain().tween_interval(0.05)
	var out := tw.chain().set_parallel(true).set_ease(Tween.EASE_OUT)
	for k in bands.size():
		out.tween_property(bands[k], "position:x", vp.x + vp.y * 0.6, OUT_S).set_delay((1 - k) * 0.04)
	tw.chain().tween_callback(queue_free)
