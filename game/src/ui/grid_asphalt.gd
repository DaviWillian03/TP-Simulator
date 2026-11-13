class_name GridAsphalt
extends Control
## Fundo do grid de largada: asfalto com grão, as marcações brancas das posições (em perspectiva, escalonadas como no
## grid real), as faixas laterais com zebra e um brilho na cor da equipe atrás de cada cartão. Desenho em código,
## sempre centralizado na tela (vale para qualquer proporção do aparelho).

var glow_left := Color(0, 0, 0, 0)  ## cor da equipe do carro da esquerda (posição ímpar)
var glow_right := Color(0, 0, 0, 0)
var _grain: PackedVector2Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 2012
	for i in 900:
		_grain.append(Vector2(rng.randf(), rng.randf()))
	resized.connect(queue_redraw)


func set_glows(left: Color, right: Color) -> void:
	glow_left = left
	glow_right = right
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var cx := w / 2.0
	# asfalto: degradê vertical + grão
	var top := UiStyle.G_ASPHALT_TOP
	var bottom := UiStyle.G_ASPHALT_BOTTOM
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([top, top, bottom, bottom]))  # degradê contínuo (cor por vértice)
	for p in _grain:
		var y := p.y * h
		var a := 0.03 + 0.05 * (y / h)
		draw_rect(Rect2(p.x * w, y, 2, 2), Color(1, 1, 1, a))
	# perspectiva: ponto de fuga acima do centro
	var vp := Vector2(cx, h * 0.18)
	var half_bottom := 760.0  # meia largura da pista na base da tela
	var edge_l := Vector2(cx - half_bottom, h)
	var edge_r := Vector2(cx + half_bottom, h)
	# zebras nas bordas da pista
	for k in 14:
		var t0 := pow(k / 14.0, 1.6)
		var t1 := pow((k + 1) / 14.0, 1.6)
		var col := UiStyle.G_KERB_RED if k % 2 == 0 else UiStyle.G_KERB_WHITE
		col.a = 0.18 + 0.4 * t1
		for side: int in [-1, 1]:
			var e := edge_l if side < 0 else edge_r
			var a0 := vp.lerp(e, t0)
			var a1 := vp.lerp(e, t1)
			var off := Vector2(28.0 * side, 0)
			draw_colored_polygon(PackedVector2Array([a0, a1, a1 + off * t1, a0 + off * t0]), col)
	# marcações do grid: "⌐" brancos escalonados, da frente (embaixo) para trás (perto do horizonte)
	for r in 9:
		for side: int in [-1, 1]:
			var t := 1.0 - (r * 2 + (0 if side < 0 else 1)) / 18.0  # escalonado: o da direita um pouco atrás
			var tt := pow(t, 2.2)
			var y := lerpf(vp.y, h + 40.0, tt)
			var sc := lerpf(0.06, 1.15, tt)
			var x := cx + side * 330.0 * sc
			var col := Color(1, 1, 1, 0.08 + 0.30 * tt)
			var bw := 230.0 * sc
			var th := maxf(1.5, 7.0 * sc)
			draw_rect(Rect2(x - bw / 2.0, y, bw, th), col)
			draw_rect(Rect2(x - bw / 2.0, y - 38.0 * sc, th, 38.0 * sc + th), col)
			draw_rect(Rect2(x + bw / 2.0 - th, y - 38.0 * sc, th, 38.0 * sc + th), col)
	# linha central tracejada
	for k in 12:
		var t0 := pow(k / 12.0, 1.8)
		var t1 := pow((k + 0.45) / 12.0, 1.8)
		var a0 := vp.lerp(Vector2(cx, h), t0)
		var a1 := vp.lerp(Vector2(cx, h), t1)
		draw_line(a0, a1, Color(1, 1, 1, 0.05 + 0.12 * t1), maxf(1.0, 4.0 * t1))
	# brilho na cor da equipe atrás dos cartões
	_glow(Vector2(cx - 280, h * 0.62), glow_left)
	_glow(Vector2(cx + 280, h * 0.66), glow_right)
	# escurece as bordas (vinheta) para os cartões saltarem
	for i in 10:
		var a := 0.05 * (10 - i) / 10.0
		draw_rect(Rect2(0, 0, w, 60 - i * 6), Color(0, 0, 0, a))


func _glow(c: Vector2, col: Color) -> void:
	if col.a <= 0.0:
		return
	for i in 28:  # muitos círculos bem fracos: brilho suave, sem anéis
		var r := 360.0 - i * 12.0
		draw_circle(c, r, Color(col, 0.012))
