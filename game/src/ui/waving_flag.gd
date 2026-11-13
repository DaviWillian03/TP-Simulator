class_name WavingFlag
extends TextureRect
## Bandeira de um país tremulando (shader de onda: desloca a imagem e escurece as dobras). Usada no fundo do pódio e do
## grid de largada. country_code = ISO de 2 letras (assets/flags/<cc>.svg, flag-icons, MIT).

const SHADER := """
shader_type canvas_item;
uniform float amp = 0.018;
uniform float freq = 9.0;
uniform float speed = 2.2;
uniform float shade = 0.28;
uniform float alpha = 1.0;
uniform float fade = 0.0;  // 1 = some para baixo (funde com o fundo), medido na altura do retângulo
uniform float rect_h = 720.0;
varying float ly;
void vertex() {
	ly = VERTEX.y;
}
void fragment() {
	float ph = UV.x * freq - TIME * speed;
	float w = sin(ph);
	vec2 uv = UV + vec2(0.0, w * amp * (0.3 + UV.x));
	vec4 c = texture(TEXTURE, clamp(uv, vec2(0.0), vec2(1.0)));
	float light = 1.0 - shade * 0.5 + shade * 0.5 * cos(ph);
	float f = 1.0 - smoothstep(rect_h * 0.25, rect_h, ly);
	COLOR = vec4(c.rgb * light, c.a * alpha * mix(1.0, f, fade));
}
"""

static var _shader: Shader


static func make(country_code: String, alpha: float = 1.0, amp: float = 0.018, fade: float = 0.0) -> WavingFlag:
	var f := WavingFlag.new()
	var path := "res://assets/flags/%s.svg" % country_code
	if ResourceLoader.exists(path):
		f.texture = load(path)
	f.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	f.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("alpha", alpha)
	m.set_shader_parameter("amp", amp)
	m.set_shader_parameter("fade", fade)
	f.material = m
	return f


func _ready() -> void:
	resized.connect(func() -> void: (material as ShaderMaterial).set_shader_parameter("rect_h", size.y))
	(material as ShaderMaterial).set_shader_parameter("rect_h", maxf(size.y, 1.0))


func set_alpha(a: float) -> void:
	(material as ShaderMaterial).set_shader_parameter("alpha", a)
