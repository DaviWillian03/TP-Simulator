class_name GarageBackdrop
extends Control
## Fundo da direção Garagem: parede com painéis de portão, chão, faixas de luz no teto, cone de
## luz e um brilho na cor da equipe atrás do destaque. Tudo desenhado com polígonos e uma
## textura de gradiente (barato no renderizador Compatibility; sem desfoque nem shader).

var floor_ratio := 0.653  ## altura da linha do chão (1.0 = só parede)
var glow_center := Vector2(0.64, 0.66)  ## centro do brilho (fração da tela)
var glow_radius := Vector2(0.46, 0.40)  ## raio do brilho (fração da tela)
var glow_color := Color("#1868DB")
var glow_strength := 0.42
var show_lamps := true
var cone_x := 0.585  ## centro do cone de luz (fração da largura); < 0 = sem cone

var _glow_tex: GradientTexture2D
var _halo_tex: GradientTexture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_glow()


func set_glow(color: Color, strength: float = -1.0) -> void:
	glow_color = color
	if strength >= 0.0:
		glow_strength = strength
	_build_glow()
	queue_redraw()


func _build_glow() -> void:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color(glow_color, glow_strength), Color(glow_color, glow_strength * 0.35), Color(glow_color, 0.0)])
	_glow_tex = GradientTexture2D.new()
	_glow_tex.gradient = g
	_glow_tex.fill = GradientTexture2D.FILL_RADIAL
	_glow_tex.fill_from = Vector2(0.5, 0.5)
	_glow_tex.fill_to = Vector2(1.0, 0.5)
	_glow_tex.width = 256
	_glow_tex.height = 256
	if _halo_tex == null:
		var h := Gradient.new()
		h.colors = PackedColorArray([Color(0.94, 0.96, 1.0, 0.28), Color(0.94, 0.96, 1.0, 0.0)])
		_halo_tex = GradientTexture2D.new()
		_halo_tex.gradient = h
		_halo_tex.fill = GradientTexture2D.FILL_RADIAL
		_halo_tex.fill_from = Vector2(0.5, 0.5)
		_halo_tex.fill_to = Vector2(1.0, 0.5)


func _draw() -> void:
	var fy := size.y * floor_ratio
	_vgrad(Rect2(0, 0, size.x, fy), UiStyle.G_WALL_TOP, UiStyle.G_WALL_BOTTOM)
	var y := 46.0
	while y < fy:
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(1, 1, 1, 0.035), 1.0)
		y += 46.0
	if floor_ratio < 1.0:
		_vgrad(Rect2(0, fy, size.x, size.y - fy), UiStyle.G_FLOOR_TOP, UiStyle.G_FLOOR_BOTTOM)
	var c := glow_center * size
	var r := glow_radius * size
	draw_texture_rect(_glow_tex, Rect2(c - r, r * 2.0), false)
	if cone_x >= 0.0:
		var cx := cone_x * size.x
		var top := 0.105 * size.x
		var bottom := 0.24 * size.x
		draw_polygon(PackedVector2Array([Vector2(cx - top, 0), Vector2(cx + top, 0), Vector2(cx + bottom, size.y), Vector2(cx - bottom, size.y)]),
			PackedColorArray([Color(1, 1, 1, 0.055), Color(1, 1, 1, 0.055), Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0)]))
	if show_lamps:
		_lamp(0.4375 * size.x, 380.0, 1.0)
		_lamp(0.79 * size.x, 170.0, 0.6)


func _lamp(x: float, w: float, alpha: float) -> void:
	# halo: a mesma textura de gradiente radial, achatada (substitui um desfoque)
	draw_texture_rect(_halo_tex, Rect2(x - 70, -60, w + 140, 130), false, Color(1, 1, 1, alpha))
	draw_rect(Rect2(x, 0, w, 6), Color(UiStyle.G_LIGHT, alpha))


func _vgrad(r: Rect2, a: Color, b: Color) -> void:
	draw_polygon(PackedVector2Array([r.position, r.position + Vector2(r.size.x, 0), r.end, r.position + Vector2(0, r.size.y)]),
		PackedColorArray([a, a, b, b]))
