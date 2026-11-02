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
	if tex == null:
		for ext: String in ["png", "svg", "webp", "jpg"]:
			if ResourceLoader.exists(LOCAL_DIR + team_id + "." + ext):
				tex = load(LOCAL_DIR + team_id + "." + ext)
				break
	if tex == null:
		var path := BUILTIN_DIR + team_id + ".svg"
		tex = load(path) if ResourceLoader.exists(path) else null
	_cache[team_id] = tex
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


## TextureRect pronto para usar numa linha da interface.
static func make_rect(team_id: String, px: int) -> TextureRect:
	var r := TextureRect.new()
	r.texture = get_texture(team_id)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(px, px)
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return r
