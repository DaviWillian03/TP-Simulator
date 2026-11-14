class_name Materials3D
extends RefCounted
## Materiais do 3D. Texturas reais do Poly Haven (CC0, tools/prepare_textures.py; 2026-11-14) no asfalto, grama, brita e
## concreto; o resto é gerado por código (ruído e imagens desenhadas). Todos funcionam no renderizador Compatibility.

const GRAIN_MEAN := 0.8  ## média do "grão" (tools/prepare_textures.py): a cor é dividida por isso para não escurecer

static var _tex_cache: Dictionary = {}


## Textura de game/assets/textures (cache por nome).
static func tex(name: String) -> Texture2D:
	if not _tex_cache.has(name):
		var path := "res://assets/textures/%s.jpg" % name
		_tex_cache[name] = load(path) if ResourceLoader.exists(path) else null
	return _tex_cache[name]


## Superfície com textura real em "grão" (grass, gravel, concrete) multiplicada pela cor do lugar.
static func textured(kind: String, color: Color, meters: float = 6.0) -> StandardMaterial3D:
	var t := tex(kind + "_d")
	if t == null:
		return ground(color)
	var m := StandardMaterial3D.new()
	m.albedo_texture = t
	m.albedo_color = Color(color.r / GRAIN_MEAN, color.g / GRAIN_MEAN, color.b / GRAIN_MEAN)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.roughness = 1.0
	m.metallic_specular = 0.1
	return _world(m, meters)


## Camada de detalhe em "grão" por cima de um material com UV próprio (chão do mapa, gramado em listras): de perto o
## chão deixa de ser uma mancha lisa. Usa o UV2 projetado pelo mundo, então não mexe no UV do material.
static func add_grain(m: StandardMaterial3D, kind: String = "grass", meters: float = 5.0) -> StandardMaterial3D:
	var t := tex(kind + "_d")
	if t == null:
		return m
	m.detail_enabled = true
	m.detail_albedo = t
	m.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	m.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
	m.uv2_triplanar = true
	m.uv2_world_triplanar = true
	m.uv2_scale = Vector3.ONE / meters
	var c := m.albedo_color
	m.albedo_color = Color(c.r / GRAIN_MEAN, c.g / GRAIN_MEAN, c.b / GRAIN_MEAN, c.a)
	return m


## Textura de ruído gerada na hora (síncrona) e colorida por um gradiente.
## (NoiseTexture2D gera em segundo plano e pode não estar pronta no primeiro quadro.)
static func _noise_tex(seed_value: int, freq: float, ramp: Gradient, size: int = 256) -> Texture2D:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = freq
	noise.fractal_octaves = 4
	var img := noise.get_seamless_image(size, size)
	if ramp != null:
		img.convert(Image.FORMAT_RGBA8)
		for y in size:
			for x in size:
				img.set_pixel(x, y, ramp.sample(img.get_pixel(x, y).r))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _normal_tex(seed_value: int, freq: float, strength: float) -> Texture2D:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = freq
	var img := noise.get_seamless_image(256, 256)
	img.convert(Image.FORMAT_RGBA8)
	img.bump_map_to_normal_map(strength)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _ramp(colors: Array) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(range(colors.size()).map(func(i: int) -> float: return float(i) / (colors.size() - 1)))
	g.colors = PackedColorArray(colors)
	return g


## Material com textura projetada pelo mundo (não depende de UV): tamanho fixo em metros.
static func _world(mat: StandardMaterial3D, meters: float) -> StandardMaterial3D:
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE / meters
	return mat


static func grass(dry_tint: Color = Color("#4a7d2c")) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _noise_tex(11, 0.02, _ramp([dry_tint.darkened(0.12), dry_tint, dry_tint.lightened(0.07), dry_tint.darkened(0.05)]))
	m.roughness = 1.0
	m.metallic_specular = 0.12  # sem o brilho esbranquiçado do céu no gramado visto de longe
	return _world(m, 40.0)


## Gramado aparado em listras (claro/escuro a cada 6 m ao longo da pista; usa o UV das faixas da pista).
static func mowed_grass() -> StandardMaterial3D:
	var img := Image.create(8, 64, false, Image.FORMAT_RGBA8)
	var light := Color("#4f8a2e")
	var dark := Color("#427a27")
	var noise := FastNoiseLite.new()
	noise.seed = 3
	noise.frequency = 0.25
	for y in 64:
		for x in 8:
			var base := light if y < 32 else dark
			img.set_pixel(x, y, base.lightened(noise.get_noise_2d(x, y) * 0.05))
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.roughness = 1.0
	m.metallic_specular = 0.12
	return m


static func ground(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _noise_tex(17, 0.03, _ramp([color.darkened(0.15), color, color.lightened(0.1)]))
	m.roughness = 1.0
	m.metallic_specular = 0.15
	return _world(m, 30.0)


## Chão com o mapa real da pista (textura gerada por tools/make_landuse.py; UV pela posição na caixa do mapa).
static func land(tex: Texture2D) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.roughness = 1.0
	m.metallic_specular = 0.1
	return add_grain(m, "grass", 4.0)


## Asfalto real (Poly Haven) com relevo; sem a textura, o ruído antigo.
static func asphalt(pit: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var t := tex("asphalt_pit" if pit else "asphalt")
	if t == null:
		m.albedo_texture = _noise_tex(5, 0.4, _ramp([Color("#1f2125"), Color("#2b2d32"), Color("#26282c"), Color("#34363b")]), 128)
	else:
		m.albedo_texture = t
		m.albedo_color = Color(1.35, 1.35, 1.38) if not pit else Color.WHITE  # o asfalto da foto é quase preto visto de cima
		m.set_meta("dry_color", m.albedo_color)
		var n := tex("asphalt_nor")
		if n != null:
			m.normal_enabled = true
			m.normal_texture = n
			m.normal_scale = 0.7
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.roughness = 0.9
	return _world(m, 5.0)


## Pista molhada: mais escura e mais lisa (reflete o céu).
static func set_wet(m: StandardMaterial3D, wetness: float) -> void:
	m.roughness = lerpf(0.9, 0.18, wetness)
	var dry: Color = m.get_meta("dry_color", Color.WHITE)  # cor seca do asfalto (a textura real é clareada)
	m.albedo_color = dry.lerp(Color(dry.r * 0.55, dry.g * 0.57, dry.b * 0.62), wetness)
	m.metallic = lerpf(0.0, 0.25, wetness)


static func flat(color: Color, roughness: float = 0.8) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m


static func vertex_color(roughness: float = 0.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = roughness
	return m


static func water() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("#2b5468")
	m.roughness = 0.08
	m.metallic = 0.35
	m.normal_enabled = true
	m.normal_texture = _normal_tex(23, 0.05, 4.0)
	m.normal_scale = 0.6
	return _world(m, 25.0)


## Fachada com janelas (desenhada em código). À noite as janelas acendem (emissão).
static func facade(base: Color, night: bool) -> StandardMaterial3D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(base)
	var glow := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	glow.fill(Color.BLACK)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(base.to_rgba32())
	for y in range(4, 64, 10):
		for x in range(3, 64, 8):
			img.fill_rect(Rect2i(x, y, 5, 6), base.darkened(0.45))
			if rng.randf() < 0.45:
				glow.fill_rect(Rect2i(x, y, 5, 6), Color("#ffcf73"))
	img.generate_mipmaps()  # sem mipmaps as janelas "tremem" (moiré) de longe
	glow.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.roughness = 0.7
	if night:
		m.emission_enabled = true
		m.emission_texture = ImageTexture.create_from_image(glow)
		m.emission_energy_multiplier = 2.5
	return _world(m, 22.0)


# --- detalhes (2026-11-14) ---------------------------------------------------------------------------------

static var _ad_atlas: Texture2D

const AD_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform sampler2D atlas : source_color, filter_linear_mipmap;
uniform float night = 0.0;
varying float v_row;
void vertex() {
	v_row = floor(COLOR.r * 8.0 + 0.5);
}
void fragment() {
	vec2 uv = vec2(UV.x, (v_row + UV.y) / 8.0);
	vec3 c = texture(atlas, uv).rgb;
	ALBEDO = c * mix(1.0, 0.55, night);
	EMISSION = c * 0.6 * night;  // placas iluminadas à noite
	ROUGHNESS = 0.6;
}
"""


## Placas de publicidade: atlas com 8 marcas FICTÍCIAS desenhadas em código (fundo, faixa, símbolo geométrico e
## blocos que imitam letras). Nenhum logo real. A linha do atlas vem da cor da instância (DetailKit.billboard).
static func ad_boards(night: bool) -> ShaderMaterial:
	if _ad_atlas == null:
		_ad_atlas = _make_ad_atlas()
	var sh := Shader.new()
	sh.code = AD_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("atlas", _ad_atlas)
	m.set_shader_parameter("night", 1.0 if night else 0.0)
	return m


static func _make_ad_atlas() -> Texture2D:
	var w := 512
	var h := 112
	var img := Image.create(w, h * 8, false, Image.FORMAT_RGBA8)
	var looks := [  # fundo, tinta, destaque
		[Color("#d71920"), Color("#ffffff"), Color("#ffd200")], [Color("#0b3d91"), Color("#ffffff"), Color("#36b3ff")],
		[Color("#111111"), Color("#f5c400"), Color("#ffffff")], [Color("#ffffff"), Color("#1d1d1f"), Color("#e10600")],
		[Color("#00843d"), Color("#ffffff"), Color("#c8f000")], [Color("#ff7a00"), Color("#1d1d1f"), Color("#ffffff")],
		[Color("#5b2a86"), Color("#ffffff"), Color("#ff4fa0")], [Color("#16a3a3"), Color("#ffffff"), Color("#0b2a3d")],
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for r in 8:
		var y0 := r * h
		var lk: Array = looks[r]
		img.fill_rect(Rect2i(0, y0, w, h), lk[0])
		img.fill_rect(Rect2i(0, y0 + h - 14, w, 14), lk[2])  # faixa de baixo
		# símbolo: círculo, losango ou divisas
		var cx := 64
		var cy := y0 + h / 2 - 6
		for yy in range(-40, 41):
			for xx in range(-40, 41):
				var inside := false
				match r % 3:
					0: inside = xx * xx + yy * yy < 36 * 36 and xx * xx + yy * yy > 22 * 22
					1: inside = absi(xx) + absi(yy) < 38
					_: inside = absi(yy - absi(xx) * 0.6) < 9 or absi(yy + 18 - absi(xx) * 0.6) < 9
				if inside and cy + yy > y0 and cy + yy < y0 + h - 14:
					img.set_pixel(cx + xx, cy + yy, lk[2] if r % 3 != 1 else lk[1])
		# "palavra": blocos de altura de letra com espaços (lido como texto de longe, sem ser marca real)
		var x := 128
		var letters := rng.randi_range(5, 8)
		for k in letters:
			var lw := rng.randi_range(22, 34)
			img.fill_rect(Rect2i(x, y0 + 30, lw, 46), lk[1])
			if rng.randf() < 0.45:  # recorte para variar a "letra"
				img.fill_rect(Rect2i(x + lw / 3, y0 + 44, lw / 3, 18), lk[0])
			x += lw + 8
			if x > w - 40:
				break
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


const BUILDING_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform float night = 0.0;
// UV.x = metros ao longo das paredes, UV.y = altura (m); UV2.x = altura do prédio, UV2.y = 1 parede / 0 telhado
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
	vec3 c = COLOR.rgb;
	if (UV2.y > 0.5) {
		float floor_i = floor(UV.y / 3.4);
		vec2 cell = vec2(fract(UV.x / 3.2), fract(UV.y / 3.4));
		bool win = cell.x > 0.22 && cell.x < 0.78 && cell.y > 0.32 && cell.y < 0.82 && UV.y > 2.2 && UV.y < UV2.x - 0.9;
		if (win) {
			c = mix(c, vec3(0.16, 0.2, 0.26), 0.72);
			float lit = step(0.55, hash(vec2(floor(UV.x / 3.2), floor_i)));
			EMISSION = vec3(1.0, 0.78, 0.45) * lit * night * 0.9;
		}
		c *= mix(0.62, 1.0, smoothstep(0.0, 4.5, UV.y));  // sombra de canto junto ao chão
	}
	ALBEDO = c;
	ROUGHNESS = 0.85;
}
"""


## Prédios reais com janelas (andares de 3,4 m) e base escurecida; à noite parte das janelas acende.
static func building(night: bool) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = BUILDING_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("night", 1.0 if night else 0.0)
	return m


static var _crowd_tex: Texture2D


## Público das arquibancadas: atlas 32×64 de "torcedores" (1 pixel = 1 pessoa; cores de camisa, ~30% cadeiras vazias),
## repetido ao longo de cada fileira. Filtro "nearest": de perto cada pessoa é um ponto de cor.
static func crowd(night: bool) -> StandardMaterial3D:
	if _crowd_tex == null:
		var img := Image.create(32, 64, false, Image.FORMAT_RGBA8)
		var rng := RandomNumberGenerator.new()
		rng.seed = 77
		for y in 64:
			for x in 32:
				var c: Color = DetailKit.CROWD[rng.randi() % DetailKit.CROWD.size()]
				if rng.randf() > 0.7:
					c = Color("#3a3f46")  # cadeira vazia
				img.set_pixel(x, y, c.darkened(rng.randf_range(0.0, 0.2)))
		_crowd_tex = ImageTexture.create_from_image(img)
	var m := StandardMaterial3D.new()
	m.albedo_texture = _crowd_tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.texture_repeat = true
	m.uv1_scale = Vector3(1.0 / 32.0, 1.0, 1.0)  # u em pessoas: 32 por repetição do atlas
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.9
	if night:
		m.albedo_color = Color(0.62, 0.66, 0.78)
	return m
