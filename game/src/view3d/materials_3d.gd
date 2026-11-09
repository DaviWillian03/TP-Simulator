class_name Materials3D
extends RefCounted
## Materiais do 3D com texturas geradas por código (ruído procedural e imagens desenhadas),
## sem arquivos externos. Todos funcionam no renderizador Compatibility (celular).


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


static func asphalt() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _noise_tex(5, 0.4, _ramp([Color("#1f2125"), Color("#2b2d32"), Color("#26282c"), Color("#34363b")]), 128)
	m.roughness = 0.9
	return _world(m, 6.0)


## Pista molhada: mais escura e mais lisa (reflete o céu).
static func set_wet(m: StandardMaterial3D, wetness: float) -> void:
	m.roughness = lerpf(0.9, 0.18, wetness)
	m.albedo_color = Color.WHITE.lerp(Color(0.55, 0.57, 0.62), wetness)
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
