class_name DriverPhotos
extends RefCounted
## Rostos dos pilotos. Fotos pessoais do usuário ficam em game/local/drivers/<id>_face.png (pasta
## ignorada pelo git; ver tools/prepare_portraits.py). Sem foto (F2/F3, equipe criada, ou pasta
## vazia) usa um círculo na cor da equipe com as iniciais. O avatar é um círculo na cor da equipe.

const LOCAL_DIR := "res://local/drivers/"
const AVATAR_PX := 160

static var use_local := true  ## false nos testes: independe das fotos de quem roda
static var _cache: Dictionary = {}


static func has_photo(driver_id: String) -> bool:
	return use_local and ResourceLoader.exists(LOCAL_DIR + driver_id + "_face.png")


## Círculo com o rosto sobre a cor da equipe (textura pronta, em cache), ou null sem foto.
static func avatar_texture(driver_id: String, team_color: Color) -> Texture2D:
	if not has_photo(driver_id):
		return null
	var key := "%s:%s" % [driver_id, team_color.to_html(false)]
	if _cache.has(key):
		return _cache[key]
	var face: Image = (load(LOCAL_DIR + driver_id + "_face.png") as Texture2D).get_image()
	face.decompress()
	face.convert(Image.FORMAT_RGBA8)
	face.resize(AVATAR_PX, AVATAR_PX, Image.INTERPOLATE_LANCZOS)
	var out := Image.create(AVATAR_PX, AVATAR_PX, false, Image.FORMAT_RGBA8)
	var r := AVATAR_PX / 2.0
	for y in AVATAR_PX:
		for x in AVATAR_PX:
			var d := Vector2(x + 0.5 - r, y + 0.5 - r).length()
			var a := clampf(r - d, 0.0, 1.0)
			if a > 0.0:
				var f := face.get_pixel(x, y)
				var c := team_color.lerp(f, f.a)  # rosto por cima da cor da equipe
				out.set_pixel(x, y, Color(c, a))
	out.generate_mipmaps()
	var tex := ImageTexture.create_from_image(out)
	_cache[key] = tex
	return tex


## Foto do rosto sem recorte (retrato grande do grid de largada), ou null sem foto.
static func portrait_texture(driver_id: String) -> Texture2D:
	if not has_photo(driver_id):
		return null
	return load(LOCAL_DIR + driver_id + "_face.png") as Texture2D


## Avatar redondo do piloto: foto se houver; senão iniciais sobre a cor da equipe.
static func make_avatar(driver: Dictionary, team_color: Color, size: int = 40) -> Control:
	var tex := avatar_texture(String(driver.get("id", "")), team_color)
	if tex != null:
		var r := TextureRect.new()
		r.texture = tex
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		r.custom_minimum_size = Vector2(size, size)
		r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return r
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(size, size)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", UiStyle.g_box(team_color, size / 2, 0, 0))
	var l := UiStyle.g_label(initials(String(driver.get("name", "?"))), maxi(11, int(size * 0.36)), UiStyle.contrast_text(team_color), "black")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


static func initials(full_name: String) -> String:
	var parts := full_name.strip_edges().split(" ", false)
	if parts.is_empty():
		return "?"
	if parts.size() == 1:
		return parts[0].left(2).to_upper()
	return (parts[0].left(1) + parts[parts.size() - 1].left(1)).to_upper()
