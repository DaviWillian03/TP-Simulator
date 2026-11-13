class_name MenuBackdrop
extends Control
## Fundo vivo dos menus (mockup v39, 2026-11-13): a arte 3D da pista (renderizada do cenário com o mapa real) em tela
## cheia, desfocada, num voo lento e contínuo (aproxima e desliza, ida e volta), com véu escuro em degradê para o texto
## ler bem. Leve no celular: é uma imagem só, sem cena 3D rodando atrás.

const BLUR := """
shader_type canvas_item;
uniform float radius = 3.5;
void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE * radius;
	vec4 c = texture(TEXTURE, UV) * 0.2;
	c += texture(TEXTURE, UV + vec2(px.x, 0.0)) * 0.1;
	c += texture(TEXTURE, UV - vec2(px.x, 0.0)) * 0.1;
	c += texture(TEXTURE, UV + vec2(0.0, px.y)) * 0.1;
	c += texture(TEXTURE, UV - vec2(0.0, px.y)) * 0.1;
	c += texture(TEXTURE, UV + px) * 0.1;
	c += texture(TEXTURE, UV - px) * 0.1;
	c += texture(TEXTURE, UV + vec2(px.x, -px.y)) * 0.1;
	c += texture(TEXTURE, UV + vec2(-px.x, px.y)) * 0.1;
	COLOR = vec4(c.rgb * 0.62, 1.0);
}
"""

static var _shader: Shader
var _art: TextureRect


static func make(circuit_id: String) -> MenuBackdrop:
	var b := MenuBackdrop.new()
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.clip_contents = true
	b._art = TextureRect.new()
	b._art.texture = CampaignHub.track_art(circuit_id)
	b._art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	b._art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	b._art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b._art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS  # imagem ampliada: filtro suave (sem quadriculado)
	if _shader == null:
		_shader = Shader.new()
		_shader.code = BLUR
	var m := ShaderMaterial.new()
	m.shader = _shader
	b._art.material = m
	b.add_child(b._art)
	var veil := _Veil.new()
	b.add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.resized.connect(b._layout)
	return b


func _layout() -> void:
	_art.size = size * 1.25
	_art.pivot_offset = _art.size / 2.0
	_art.position = -(size * 0.125)


## Troca a pista com fade (configuração do Grande Prêmio, v40): a arte antiga fica embaixo e a nova aparece por cima.
func set_circuit(circuit_id: String) -> void:
	var tex := CampaignHub.track_art(circuit_id)
	if tex == _art.texture:
		return
	var old := TextureRect.new()
	for p: String in ["texture", "expand_mode", "stretch_mode", "texture_filter", "material", "size", "pivot_offset", "position", "scale"]:
		old.set(p, _art.get(p))
	old.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(old)
	move_child(old, 0)
	_art.texture = tex
	_art.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_art, "modulate:a", 1.0, 0.35)
	tw.tween_callback(old.queue_free)


func _ready() -> void:
	_layout()
	var tw := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_art, "scale", Vector2(1.12, 1.12), 18.0).from(Vector2.ONE)
	tw.parallel().tween_property(_art, "position:x", -(size.x * 0.125) - 60.0, 18.0)
	tw.tween_property(_art, "scale", Vector2.ONE, 18.0)
	tw.parallel().tween_property(_art, "position:x", -(size.x * 0.125) + 40.0, 18.0)


## Véu: escuro à esquerda (texto e carro) e embaixo (faixa de notícias), mais leve no meio.
class _Veil:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var d := UiStyle.G_PODIUM_SHADE
		var l := Color(d, 0.88)
		var m := Color(d, 0.25)
		var r := Color(d, 0.55)
		var w := size.x
		var h := size.y
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w * 0.5, 0), Vector2(w * 0.5, h), Vector2(0, h)]),
			PackedColorArray([l, m, m, l]))
		draw_polygon(PackedVector2Array([Vector2(w * 0.5, 0), Vector2(w, 0), Vector2(w, h), Vector2(w * 0.5, h)]),
			PackedColorArray([m, r, r, m]))
		var t := Color(d, 0.0)
		var b := Color(d, 0.85)
		draw_polygon(PackedVector2Array([Vector2(0, h * 0.6), Vector2(w, h * 0.6), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([t, t, b, b]))
