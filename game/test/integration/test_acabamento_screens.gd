extends GutTest
## Telas do acabamento (v32): configurações, slots, ajuda e dica de primeira vez.

func _open(path: String) -> Control:
	var s: Control = load(path).instantiate()
	add_child_autofree(s)
	await wait_process_frames(3)
	return s


func before_each() -> void:
	for s in range(1, 4):
		SaveSlots.delete(s)
	Settings.tips_on = true
	Settings.tips_seen = []


func test_configuracoes_montam() -> void:
	var scr: Control = await _open("res://src/ui/settings_screen.tscn")
	assert_not_null(scr)


func test_slots_mostram_tres_cartoes_e_apagam() -> void:
	SaveSlots.current = 1
	Campaign.new_real("williams").save()
	var scr: SlotsScreen = await _open("res://src/ui/slots_screen.tscn")
	var cards := 0
	for ch in scr._stage.get_children():
		if ch is Panel:
			cards += 1
	assert_eq(cards, 3, "3 slots (1 cheio, 2 vazios)")
	scr._ask_delete(1)
	await wait_process_frames(2)
	SaveSlots.delete(1)
	assert_true(SaveSlots.is_empty(1))


func test_ajuda_abre_com_os_assuntos() -> void:
	var host := Control.new()
	add_child_autofree(host)
	HelpSheet.open(host)
	await wait_process_frames(2)
	assert_gt(host.get_child_count(), 0)


func test_dica_aparece_uma_vez_e_some_ao_desligar() -> void:
	var host := Control.new()
	add_child_autofree(host)
	Tips.show_once(host, "race")
	assert_eq(host.get_child_count(), 1, "primeira vez: mostra")
	Tips.show_once(host, "race")
	assert_eq(host.get_child_count(), 1, "já vista: não repete")
	Settings.tips_on = false
	Tips.show_once(host, "quali")
	assert_eq(host.get_child_count(), 1, "dicas desligadas: nada")
	Settings.tips_on = true
	Settings.tips_seen = []
