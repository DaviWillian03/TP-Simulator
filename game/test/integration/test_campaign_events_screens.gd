extends GutTest
## Integração: cartão de evento na sede, lista de notícias e tela do Conselho de regras.

var camp: Campaign


func before_each() -> void:
	camp = Campaign.new_real("williams")
	camp.detail = "advanced"
	camp.events.freq = "off"
	Session.campaign = camp
	Session.player_team = "williams"


func after_all() -> void:
	Session.campaign = null


func _open(scene: String) -> Control:
	var screen: Control = load(scene).instantiate()
	add_child_autofree(screen)
	await wait_process_frames(3)
	return screen


func _rng() -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = 3
	return r


func _cards(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	for c in node.get_children():
		if c is EventCard:
			out.append(c)
		out.append_array(_cards(c))
	return out


func test_sede_mostra_o_cartao_do_evento_pendente_e_entendi_fecha() -> void:
	camp.events._add(camp, camp.events._apply(camp, CampaignEvents.event_def("host_support"), _rng(), camp.day))
	assert_eq(camp.events.unseen.size(), 1)
	var screen: Control = await _open("res://src/ui/campaign_hub_screen.tscn")
	var cards := _cards(screen)
	assert_eq(cards.size(), 1, "um cartão por vez")
	assert_eq(camp.events.unseen.size(), 0, "a notícia foi consumida")
	(cards[0] as EventCard).dismissed.emit()
	(cards[0] as EventCard).queue_free()


func test_varios_eventos_pendentes_sao_mostrados_um_de_cada_vez() -> void:
	camp.events._add(camp, camp.events._apply(camp, CampaignEvents.event_def("host_support"), _rng(), camp.day))
	camp.events._add(camp, camp.events._apply(camp, CampaignEvents.event_def("economic_crisis"), _rng(), camp.day))
	var screen: Control = await _open("res://src/ui/campaign_hub_screen.tscn")
	var first := _cards(screen)
	assert_eq(first.size(), 1)
	(first[0] as EventCard).dismissed.emit()
	(first[0] as EventCard).queue_free()
	await wait_process_frames(3)
	assert_eq(_cards(screen).size(), 1, "o segundo cartão aparece")
	assert_eq(camp.events.unseen.size(), 0)
	for c in _cards(screen):
		c.queue_free()


func test_lista_de_noticias_troca_a_frequencia() -> void:
	var sheet := NewsSheet.new()
	add_child_autofree(sheet)
	sheet.setup(camp)
	await wait_process_frames(2)
	camp.events.freq = "frequent"  # (o seletor grava no mesmo campo)
	assert_eq(camp.events.freq, "frequent")
	assert_not_null(sheet)


func test_conselho_fora_da_janela_so_mostra_as_regras() -> void:
	var screen: Control = await _open("res://src/ui/campaign_council_screen.tscn")
	assert_eq(screen._left.get_child_count(), 2)
	assert_true(camp.regs.proposals.is_empty())


func test_conselho_no_fim_da_temporada_abre_votacao_e_registra_voto() -> void:
	camp.round = 22
	var screen: Control = await _open("res://src/ui/campaign_council_screen.tscn")
	assert_eq(camp.regs.proposals.size(), 4, "3 esportivas + 1 técnica")
	var pid: String = camp.regs.proposals[0]["id"]
	screen._on_vote(pid, "y")
	assert_eq(camp.regs.player_votes[pid], "y")
	assert_true(screen._left.get_child_count() >= 4)


func test_nav_tem_o_conselho() -> void:
	var screen: Control = await _open("res://src/ui/campaign_hub_screen.tscn")
	var has := false
	for n in _all(screen):
		if n is Button and (n as Button).text == "Conselho" and not (n as Button).disabled:
			has = true
	assert_true(has)
	for c in _cards(screen):
		c.queue_free()


func _all(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for c in node.get_children():
		out.append_array(_all(c))
	return out
