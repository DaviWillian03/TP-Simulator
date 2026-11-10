extends GutTest
## Integração: telas da campanha do redesenho v26 (mosaico, agenda, equipe, sede 3D) e a moldura.

var camp: Campaign


func before_each() -> void:
	camp = Campaign.new_real("mercedes")
	camp.budget_musd = 150.0
	Session.campaign = camp
	Session.player_team = "mercedes"


func after_all() -> void:
	Session.campaign = null


func _open(scene: String) -> Control:
	var screen: Control = load(scene).instantiate()
	add_child_autofree(screen)
	await wait_process_frames(2)
	return screen


func _rail_items(screen: Node) -> Array:
	var out := []
	for b in screen.find_children("*", "Button", true, false):
		if (b as Button).tooltip_text in ["Início", "Tabela", "Pilotos", "Carro", "Sede", "Agenda", "Pessoal", "Patroc.", "Caixa", "História", "Regras"]:
			out.append((b as Button).tooltip_text)
	return out


func test_inicio_em_mosaico_tem_moldura_e_onze_icones() -> void:
	var screen: Control = await _open("res://src/ui/campaign_hub_screen.tscn")
	assert_eq(_rail_items(screen).size(), 11)
	assert_not_null(screen.find_child("CampaignFrame", true, false))


func test_agenda_mostra_um_cartao_por_corrida_restante() -> void:
	camp.round = 3
	var screen: Control = await _open("res://src/ui/campaign_calendar_screen.tscn")
	assert_eq(screen._row.get_child_count(), Campaign.calendar().size() - 3)


func test_equipe_abre_com_os_dois_pilotos() -> void:
	var screen: Control = await _open("res://src/ui/campaign_team_screen.tscn")
	var names := []
	for l in screen.find_children("*", "Label", true, false):
		names.append((l as Label).text)
	for id: String in camp.team_driver_ids("mercedes"):
		for d: Dictionary in camp.drivers():
			if d["id"] == id:
				assert_true(names.has(String(d["name"]).to_upper()), d["name"])


func test_sede_troca_de_predio_e_construir_paga_a_obra() -> void:
	var screen: Control = await _open("res://src/ui/campaign_hq_screen.tscn")
	screen._on_pick("sim")
	assert_eq(screen._campus.selected, "sim")
	var before := camp.budget_musd
	screen._on_pick("wind")
	assert_true(camp.dev.start_upgrade(camp, "wind"))
	assert_lt(camp.budget_musd, before)
	screen._on_pick("design")  # atalho para a árvore de P&D, sem nível
	assert_false(screen._campus.levels.has("design"))


func test_continuar_avanca_ate_o_gp() -> void:
	var day := camp.day
	CampaignFrame.continue_campaign.call()
	await wait_process_frames(1)
	assert_true(camp.event_ready() or camp.day > day)


func test_decisao_de_mercado_abre_no_inicio_e_bloqueia_o_continuar() -> void:
	var tm: TransferMarket = camp.personnel.transfers
	var id: String = camp.personnel.player_drivers(camp)[0]["id"]
	tm._add_decision(camp, {"kind": "offer", "id": id, "team": "ferrari", "salary": 9.0, "years": 2, "fee": 5.0, "ends_now": false})
	camp.events.unseen.clear()
	var screen: Control = await _open("res://src/ui/campaign_hub_screen.tscn")
	await wait_process_frames(2)
	var dlgs := screen.find_children("*", "MarketDialog", true, false)
	assert_eq(dlgs.size(), 1, "a proposta aparece ao abrir o Início")
	var day := camp.day
	CampaignFrame.continue_campaign()
	assert_eq(camp.day, day, "com decisão aberta o CONTINUAR não avança")
	var before := camp.budget_musd
	var dlg: MarketDialog = dlgs[0]
	for b in dlg.find_children("*", "Button", true, false):
		if (b as Button).find_children("*", "Label", true, false).any(func(l: Label) -> bool: return l.text == "ACEITAR A MULTA"):
			(b as Button).pressed.emit()
	assert_almost_eq(camp.budget_musd, before + 5.0, 0.01)
	assert_true(tm.decisions.is_empty())
