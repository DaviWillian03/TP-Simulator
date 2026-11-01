class_name TeamEmblems
extends RefCounted
## Emblema de cada equipe para a interface.
##
## Por padrão usa os emblemas ORIGINAIS do jogo (res://assets/emblems/<id>.svg).
## Se o jogador colocar uma imagem em user://import/emblems/<id>.png (ou .jpg), ela é usada
## no lugar — é assim que logos reais podem aparecer, por conta do próprio jogador.

const IMPORT_DIR := "user://import/emblems/"
const BUILTIN_DIR := "res://assets/emblems/"

static var _cache: Dictionary = {}


static func get_texture(team_id: String) -> Texture2D:
	if _cache.has(team_id):
		return _cache[team_id]
	var tex: Texture2D = _load_imported(team_id)
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
