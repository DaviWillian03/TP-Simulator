class_name TyreBadge
extends Control
## Pneu estilizado: borracha com banda de rodagem, faixa lateral na cor do composto (com brilho), aro e a letra no meio.

var letter := ""
var ring := Color.WHITE


func _init() -> void:
	custom_minimum_size = Vector2(19, 19)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_compound(p_letter: String, p_color: Color) -> void:
	if p_letter == letter and p_color == ring:
		return
	letter = p_letter
	ring = p_color
	queue_redraw()


func _draw() -> void:
	if letter == "":
		return
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 0.5
	# borracha escura
	draw_circle(c, r, Color("#0b0d11"), true, -1.0, true)
	# banda de rodagem: pontinhos claros em volta (só quando há tamanho para vê-los)
	if r >= 9.0:
		var n := 24
		for i in n:
			var a := TAU * i / n
			var d := Vector2(cos(a), sin(a))
			draw_line(c + d * r * 0.88, c + d * (r - 0.4), Color(1, 1, 1, 0.16), maxf(1.0, r * 0.1), true)
	# faixa lateral na cor do composto (como o desenho nos pneus de verdade)
	var band_r := r * 0.70
	var band_w := maxf(2.0, r * 0.24)
	draw_arc(c, band_r, 0.0, TAU, 56, ring, band_w, true)
	draw_arc(c, band_r, PI * 1.08, PI * 1.62, 20, Color(1, 1, 1, 0.38), maxf(1.0, band_w * 0.34), true)  # brilho
	draw_arc(c, band_r - band_w * 0.5, 0.0, TAU, 56, Color(0, 0, 0, 0.35), 1.0, true)  # sombra interna da faixa
	# aro (roda) com a letra
	var rim_r := r * 0.52
	draw_circle(c, rim_r, Color("#1a1d24"), true, -1.0, true)
	draw_arc(c, rim_r, 0.0, TAU, 40, Color(1, 1, 1, 0.2), maxf(1.0, r * 0.06), true)
	var font := UiStyle.HEAVY_FONT
	var fs := maxi(8, roundi(r * 0.86))
	var w := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, c + Vector2(-w / 2.0, fs * 0.33), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
