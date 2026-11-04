class_name TeamEmblems
extends RefCounted
## Emblema de cada equipe para a interface.
##
## Por padrão usa os emblemas ORIGINAIS do jogo (res://assets/emblems/<id>.svg).
## Imagens do próprio jogador substituem o emblema, nesta ordem:
##   1. user://import/emblems/<id>.png (ou .jpg/.webp) — colocada no aparelho;
##   2. res://local/emblems/<id>.png (ou .svg) — pasta LOCAL, ignorada pelo git: entra só no
##      APK pessoal de quem a preencheu, nunca no repositório (ver game/local/LEIA-ME.md).

const IMPORT_DIR := "user://import/emblems/"
const LOCAL_DIR := "res://local/emblems/"
const BUILTIN_DIR := "res://assets/emblems/"

static var use_local := true  ## false nos testes: ignora game/local/emblems (depende de quem roda)
static var _cache: Dictionary = {}
static var _custom: Dictionary = {}  ## emblemas gerados (equipe criada na campanha)


## Registra o emblema da equipe criada (forma + cores escolhidas na criação).
## Imagens importadas pelo jogador continuam tendo prioridade (ver get_texture).
static func register_custom(team: Dictionary) -> void:
	var id: String = team["id"]
	_cache.erase(id)
	var imported := _load_imported(id)
	_custom[id] = imported if imported != null else CarArt.emblem_texture(team.get("shape", "hex"), team["color"], team["color2"], team.get("short_name", ""))


static func get_texture(team_id: String) -> Texture2D:
	if _cache.has(team_id):
		return _cache[team_id]
	if _custom.has(team_id):
		return _custom[team_id]
	var tex: Texture2D = _load_imported(team_id)
	if tex == null and use_local:
		for ext: String in ["png", "svg", "webp", "jpg"]:
			if ResourceLoader.exists(LOCAL_DIR + team_id + "." + ext):
				tex = _framed(team_id, load(LOCAL_DIR + team_id + "." + ext))
				break
	if tex == null and (team_id.begins_with("f2_") or team_id.begins_with("f3_")):  # equipes da F2/F3 (3 categorias)
		tex = _series_texture(team_id)
	if tex == null:
		var path := BUILTIN_DIR + team_id + ".svg"
		tex = load(path) if ResourceLoader.exists(path) else null
	_cache[team_id] = tex
	return tex


## F2/F3: logo pessoal em game/local/series/<f2|f3>/<equipe>.png (fora do git); senão, emblema original gerado.
static func _series_texture(team_id: String) -> Texture2D:
	var cat := team_id.left(2)
	var base := team_id.substr(3)
	if use_local:
		for ext: String in ["png", "svg", "webp", "jpg"]:
			var p := "res://local/series/%s/%s.%s" % [cat, base, ext]
			if ResourceLoader.exists(p):
				return _framed_series(team_id, load(p))
	for c: String in ["F2", "F3"]:
		for t: Dictionary in Series.data()["series"][c]["teams"]:
			if t["base_id"] == base:
				return CarArt.emblem_texture(String(t.get("shape", "hex")), String(t["color"]), String(t["color2"]), String(t.get("short_name", "")))
	return null


## Logo pessoal da F2/F3 sobre o quadrado na cor da equipe (as logos são brancas ou coloridas).
static func _framed_series(team_id: String, tex: Texture2D) -> Texture2D:
	var base := team_id.substr(3)
	for c: String in ["F2", "F3"]:
		for t: Dictionary in Series.data()["series"][c]["teams"]:
			if t["base_id"] == base:
				return _framed_with(Color(t["color"]), tex)
	return tex


static func _load_imported(team_id: String) -> Texture2D:
	for ext: String in ["png", "jpg", "jpeg", "webp"]:
		var path := IMPORT_DIR + team_id + "." + ext
		if FileAccess.file_exists(path):
			var img := Image.load_from_file(path)
			if img != null and not img.is_empty():
				return ImageTexture.create_from_image(img)
	return null


## Limpa o cache (após importar ou remover imagens).
static func clear_cache() -> void:
	_cache.clear()
	_custom.clear()


## TextureRect pronto para usar numa linha da interface.
static func make_rect(team_id: String, px: int) -> TextureRect:
	var r := TextureRect.new()
	r.texture = get_texture(team_id)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(px, px)
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return r


# --- logos pessoais (pasta local): quadradinho na cor da equipe ---------------------------

const FRAME_PX := 128
const FRAME_RADIUS := 26
const FRAME_PAD := 0.17
const FRAME_PAD_WIDE := 0.08


## Logos brancas (as da navegação da F1) somem em fundo claro e ficam minúsculas quando são
## largas. Compomos cada uma sobre um quadrado arredondado na cor da equipe (ou da cor de
## destaque, se a principal for clara — ou a `emblem_bg` do JSON, se existir), como na transmissão. Imagens coloridas ficam como estão.
static func _framed(team_id: String, tex: Texture2D) -> Texture2D:
	return _framed_with(_frame_color(GameData.team_by_id(GameData.teams(), team_id)), tex, true)


static func _framed_with(bg: Color, tex: Texture2D, only_white: bool = false) -> Texture2D:
	var img := tex.get_image() if tex != null else null
	if img == null or img.is_empty() or (only_white and not _is_white_logo(img)):
		return tex
	img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var out := Image.create(FRAME_PX, FRAME_PX, false, Image.FORMAT_RGBA8)
	var r := float(FRAME_RADIUS)
	for y in FRAME_PX:
		for x in FRAME_PX:
			var dx := maxf(maxf(r - x, x - (FRAME_PX - 1 - r)), 0.0)
			var dy := maxf(maxf(r - y, y - (FRAME_PX - 1 - r)), 0.0)
			var d := sqrt(dx * dx + dy * dy)
			out.set_pixel(x, y, Color(bg, clampf(r + 0.5 - d, 0.0, 1.0)))
	var bb := img.get_used_rect()
	if bb.size.x > 0 and bb.size.y > 0:
		img = img.get_region(bb)
	var wide := float(img.get_width()) / maxf(img.get_height(), 1.0) > 1.6  # logos largas: menos margem
	var box := int(FRAME_PX * (1.0 - 2.0 * (FRAME_PAD_WIDE if wide else FRAME_PAD)))
	var k := float(box) / maxf(img.get_width(), img.get_height())
	img.resize(maxi(1, roundi(img.get_width() * k)), maxi(1, roundi(img.get_height() * k)), Image.INTERPOLATE_LANCZOS)
	out.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i((FRAME_PX - img.get_width()) / 2, (FRAME_PX - img.get_height()) / 2))
	out.generate_mipmaps()
	return ImageTexture.create_from_image(out)


static func _frame_color(team: Dictionary) -> Color:
	if team.has("emblem_bg"):  # fundo escolhido à mão (ex.: laranja da McLaren, azul-marinho da Racing Bulls)
		return Color(team["emblem_bg"])
	for key: String in ["color", "color2"]:
		var c := Color(team.get(key, "#555555"))
		if c.get_luminance() < 0.5:
			return c
	return Color("#1b1d22")


## A maior parte dos pixels visíveis é quase branca e sem cor?
static func _is_white_logo(img: Image) -> bool:
	var src := img.duplicate()
	src.decompress()
	var seen := 0
	var white := 0
	for y in range(0, src.get_height(), 8):
		for x in range(0, src.get_width(), 8):
			var c: Color = src.get_pixel(x, y)
			if c.a > 0.5:
				seen += 1
				if c.get_luminance() > 0.85 and (maxf(c.r, maxf(c.g, c.b)) - minf(c.r, minf(c.g, c.b))) < 0.08:
					white += 1
	return seen > 0 and float(white) / seen > 0.6
