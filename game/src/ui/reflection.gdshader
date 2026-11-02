shader_type canvas_item;
// Reflexo do carro no chão da garagem: a imagem já vem espelhada (flip_v); a opacidade
// começa fraca junto das rodas e some em ~45% da altura. Funciona no renderizador Compatibility.

uniform float strength = 0.16;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float fade = clamp(1.0 - (1.0 - UV.y) / 0.45, 0.0, 1.0);
	COLOR = vec4(c.rgb, c.a * strength * fade);
}
