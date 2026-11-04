extends GutTest
## Integração: estúdio de design (abas, camadas, gerar pintura, especiais).

var camp: Campaign


func before_each() -> void:
	camp = Campaign.new_real("williams")
	Session.campaign = camp
	Session.player_team = "williams"


func after_all() -> void:
	Session.campaign = null


func _open() -> Control:
	var screen: Control = load("res://src/ui/campaign_studio_screen.tscn").instantiate()
	add_child_autofree(screen)
	await wait_process_frames(2)
	return screen


func test_abas_montam_sem_erro() -> void:
	var screen: Control = await _open()
	for t: Array in screen.TABS:
		screen._tab = t[0]
		screen._refresh()
		await wait_process_frames(1)
		assert_not_null(screen._content, t[0])


func test_ferramentas_mexem_na_camada_e_gerar_troca_a_pintura() -> void:
	var screen: Control = await _open()
	screen._sel = 0
	var l: Dictionary = camp.livery.main["layers"][0]
	var a := float(l["angle"])
	screen._tool("rotate")
	assert_ne(float(l["angle"]), a)
	var before: Dictionary = camp.livery.main
	screen._generate()
	assert_ne(camp.livery.main, before)


func test_nova_especial_copia_a_pintura_e_edita_ela() -> void:
	var screen: Control = await _open()
	screen._tab = "specials"
	screen._refresh()
	camp.livery.specials.append({"name": "Especial 1", "round": 0, "paint": camp.livery.main.duplicate(true)})
	screen._target = 0
	screen._sel = -1
	screen._tab = "paint"
	screen._refresh()
	assert_eq(screen._paint(), camp.livery.specials[0]["paint"])
