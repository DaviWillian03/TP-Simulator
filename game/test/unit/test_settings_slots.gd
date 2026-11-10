extends GutTest
## Configurações, slots de save com versão e migração do save antigo (v32).

var _backup := {}


func before_each() -> void:
	SaveSlots.current = 1
	for s in range(1, 4):
		SaveSlots.delete(s)


func after_all() -> void:
	for s in range(1, 4):
		SaveSlots.delete(s)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.PATH))


func test_slots_vazios_e_primeiro_livre() -> void:
	assert_true(SaveSlots.is_empty(1))
	assert_eq(SaveSlots.first_free(), 1)
	var c := Campaign.new_real("williams")
	SaveSlots.ensure(1)
	assert_true(c.save(SaveSlots.campaign_path(1)))
	assert_false(SaveSlots.is_empty(1))
	assert_eq(SaveSlots.first_free(), 2)
	assert_eq(SaveSlots.latest("campaign"), 1)
	assert_eq(String(SaveSlots.summary(1)["kind"]), "campaign")
	assert_eq(String(SaveSlots.summary(1)["team"]), "williams")


func test_campanha_e_mundial_em_slots_diferentes() -> void:
	SaveSlots.current = 2
	var c := Campaign.new_real("ferrari")
	assert_true(c.save())  # grava no slot atual
	SaveSlots.current = 3
	var w := WorldChampionship.start("mclaren")
	assert_true(w.save())
	assert_true(SaveSlots.has_campaign(2))
	assert_true(SaveSlots.has_world(3))
	assert_eq(String(SaveSlots.summary(3)["kind"]), "world")
	assert_not_null(WorldChampionship.load_saved())
	SaveSlots.current = 2
	assert_not_null(Campaign.load_saved())
	SaveSlots.delete(2)
	assert_null(Campaign.load_saved())


func test_save_de_versao_mais_nova_e_recusado_e_o_antigo_entra() -> void:
	assert_true(SaveSlots.compatible({"save_version": SaveSlots.VERSION}))
	assert_true(SaveSlots.compatible({}), "sem campo = versão 1 (antes dos slots)")
	assert_false(SaveSlots.compatible({"save_version": SaveSlots.VERSION + 1}))
	var c := Campaign.new_real("haas")
	var d := c.to_dict()
	assert_eq(int(d["save_version"]), SaveSlots.VERSION)
	d["save_version"] = SaveSlots.VERSION + 5
	SaveSlots.ensure(1)
	var f := FileAccess.open(SaveSlots.campaign_path(1), FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	assert_null(Campaign.load_saved(), "save de uma versão futura não é carregado (não corrompe)")


func test_migra_o_save_antigo_para_o_slot_1() -> void:
	var legacy := "user://campaign.json"
	var c := Campaign.new_real("alpine")
	var f := FileAccess.open(legacy, FileAccess.WRITE)
	f.store_string(JSON.stringify(c.to_dict()))
	f.close()
	SaveSlots.migrate_legacy()
	assert_false(FileAccess.file_exists(legacy), "o arquivo antigo saiu")
	assert_true(SaveSlots.has_campaign(1))
	assert_eq(Campaign.load_saved().player_team, "alpine")


func test_configuracoes_gravam_e_voltam() -> void:
	Settings.master = 0.5
	Settings.text_size = "large"
	Settings.start_speed = 4
	Settings.tips_on = false
	Settings.save_all()
	Settings.master = 0.1
	Settings.text_size = "normal"
	Settings.load_all()
	assert_almost_eq(Settings.master, 0.5, 0.001)
	assert_eq(Settings.text_size, "large")
	assert_almost_eq(Settings.text_scale(), 1.4, 0.001)
	assert_eq(Settings.start_speed, 4)
	assert_false(Settings.tips_on)
	Settings.text_size = "normal"
	Settings.tips_on = true
	Settings.start_speed = 2
	Settings.master = 0.8
	Settings.save_all()


func test_tamanho_da_letra_muda_a_escala() -> void:
	Settings.text_size = "normal"
	var a := UiStyle.fs(16)
	Settings.text_size = "large"
	assert_gt(UiStyle.fs(16), a)
	Settings.text_size = "normal"
