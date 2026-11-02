extends GutTest
## Emblemas: originais por padrão; imagem importada pelo jogador tem prioridade.

const TEAM := "haas"
var _path := TeamEmblems.IMPORT_DIR + TEAM + ".png"


func before_all() -> void:
	TeamEmblems.use_local = false  # o resultado não pode depender das logos pessoais de quem roda


func after_all() -> void:
	TeamEmblems.use_local = true
	TeamEmblems.clear_cache()


func after_each() -> void:
	if FileAccess.file_exists(_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_path))
	TeamEmblems.clear_cache()


func test_todas_as_equipes_tem_emblema_original() -> void:
	TeamEmblems.clear_cache()
	for t: Dictionary in GameData.teams():
		assert_not_null(TeamEmblems.get_texture(t["id"]), t["id"])


func test_imagem_importada_substitui_o_emblema() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TeamEmblems.IMPORT_DIR))
	var img := Image.create(37, 37, false, Image.FORMAT_RGBA8)
	img.fill(Color.MAGENTA)
	assert_eq(img.save_png(_path), OK)
	TeamEmblems.clear_cache()
	var tex := TeamEmblems.get_texture(TEAM)
	assert_true(tex is ImageTexture, "usa a imagem importada")
	assert_eq(tex.get_width(), 37)


func test_sem_importacao_volta_ao_original() -> void:
	TeamEmblems.clear_cache()
	assert_false(TeamEmblems.get_texture(TEAM) is ImageTexture)
