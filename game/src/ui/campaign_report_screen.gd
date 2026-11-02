extends Control
## Relatório da diretoria no fim da temporada — direção Garagem (mockup
## design/mockups/v6-3-campanha-relatorio.html). Veredito grande, números da temporada e o que
## muda no próximo ano; demissão e falência usam a mesma tela com outro texto e outra ação.

const VERDICTS := {
	"met": ["META\nCUMPRIDA", "A diretoria renova a confiança e libera mais orçamento."],
	"failed": ["META\nNÃO CUMPRIDA", "A diretoria perdeu paciência. Mais um resultado assim e o cargo estará em risco."],
	"fired": ["VOCÊ FOI\nDEMITIDO", "A diretoria encerrou o seu contrato. A campanha acaba aqui."],
	"bankrupt": ["EQUIPE\nFALIDA", "O caixa ficou negativo e os credores assumiram a equipe. A campanha acaba aqui."],
}

var campaign: Campaign
var report: Dictionary


func _ready() -> void:
	campaign = Session.campaign
	if campaign == null:
		Session.open_campaign.call_deferred()
		return
	if campaign.seasons.is_empty() or int(campaign.seasons.back()["season"]) != campaign.season:
		campaign.close_season()
		campaign.save()
	report = campaign.seasons.back()
	var verdict: String = report["verdict"]
	var bad := verdict in ["fired", "bankrupt"]
	var color := Color("#b30500") if bad else UiStyle.team_color(campaign.player_team)
	var page := ScreenKit.garage_page(self, campaign.player_team)
	var bd: GarageBackdrop = page["backdrop"]
	bd.glow_center = Vector2(0.3, 0.45)
	bd.set_glow(color, 0.3)
	var layer: Control = page["layer"]

	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -2)
	titles.add_child(UiStyle.g_caption("%s · fim da temporada %d" % [campaign.team()["name"], campaign.season]))
	titles.add_child(UiStyle.g_label("RELATÓRIO DA DIRETORIA", 28, UiStyle.G_TEXT, "black"))
	ScreenKit.place(titles, layer, Control.PRESET_TOP_LEFT, Vector2(44, 28))

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	ScreenKit.place(left, layer, Control.PRESET_TOP_LEFT, Vector2(44, 108), Vector2(620, 0))
	left.add_child(UiStyle.g_caption("Veredito"))
	var big := UiStyle.g_label(VERDICTS[verdict][0], 68, UiStyle.G_TEXT if not bad else Color("#ffb4a8"), "black")
	big.add_theme_constant_override("line_spacing", -14)
	left.add_child(big)
	var text := ""
	match verdict:
		"met":
			text = "Vocês terminaram em %dº entre os construtores; a meta era o top %d. %s" % [report["position"], report["goal"], VERDICTS[verdict][1]]
		"failed":
			text = "Vocês terminaram em %dº entre os construtores; a meta era o top %d. %s" % [report["position"], report["goal"], VERDICTS[verdict][1]]
		_:
			text = VERDICTS[verdict][1]
	var desc := UiStyle.g_label(text, 18, Color("#c3c9d3"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(540, 0)
	left.add_child(desc)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 14)
	left.add_child(gap)
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 14)
	for s: Array in [["Posição final", "%dº" % report["position"]], ["Pontos", str(report["points"])],
			["Melhor corrida", "%dº" % report["best"] if int(report["best"]) < 99 else "—"]]:
		var card := ScreenKit.g_card(Color(1, 1, 1, 0.06), 20, 18, 12)
		card.custom_minimum_size = Vector2(170, 0)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		v.add_child(UiStyle.g_caption(s[0]))
		v.add_child(UiStyle.g_label(s[1], 38, UiStyle.G_TEXT, "black"))
		card.add_child(v)
		stats.add_child(card)
	left.add_child(stats)

	var right := ScreenKit.g_card(Color(1, 1, 1, 0.06), 22, 24, 20)
	ScreenKit.place(right, layer, Control.PRESET_TOP_RIGHT, Vector2(-44, 96), Vector2(520, 0))
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 0)
	right.add_child(rv)
	rv.add_child(UiStyle.g_caption("Próxima temporada · %d" % (campaign.season + 1) if not bad else "Resumo da campanha"))
	var rows: Array = []
	if bad:
		rows = [["Temporadas disputadas", str(campaign.seasons.size())], ["Melhor posição", "%dº" % _best_position()],
			["Caixa final", "US$ %d mi" % int(report["budget"])], ["Confiança final", "%d%%" % int(report["trust"])]]
	else:
		rows = [["Prêmio da temporada", "US$ %d mi" % int(report["prize"])], ["Orçamento", "US$ %d mi" % int(report["budget"])],
			["Confiança da diretoria", campaign.trust_label()], ["Nova meta", "Top %d dos construtores" % report["next_goal"]]]
	for r: Array in rows:
		var h := HBoxContainer.new()
		h.custom_minimum_size = Vector2(0, 44)
		var k := UiStyle.g_label(r[0], 17, UiStyle.G_TEXT, "bold")
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		k.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(k)
		var val := UiStyle.g_label(r[1], 17, UiStyle.G_TEXT, "black")
		val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(val)
		rv.add_child(h)
		var line := ColorRect.new()
		line.color = Color(1, 1, 1, 0.07)
		line.custom_minimum_size = Vector2(0, 1)
		rv.add_child(line)
	var note := UiStyle.g_label("Se a meta não for cumprida, a confiança cai. Com a confiança zerada ou o caixa negativo, o resultado é demissão ou falência." if not bad
		else "Uma nova campanha pode ser criada a qualquer momento: com outra origem, outra equipe ou outro objetivo.", 14, UiStyle.G_TEXT_2)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(0, 70)
	rv.add_child(note)

	var go := CutButton.new()
	go.text = "NOVA CAMPANHA" if bad else "INICIAR TEMPORADA %d" % (campaign.season + 1)
	go.custom_minimum_size = Vector2(380, UiStyle.TOUCH_MAIN + 4)
	go.pressed.connect(Session.finish_season_report)
	ScreenKit.place(go, layer, Control.PRESET_BOTTOM_RIGHT, Vector2(-44, -30))
	if not bad:
		var council := ScreenKit.light_button("CONSELHO DE REGRAS")
		council.custom_minimum_size = Vector2(300, UiStyle.TOUCH_MAIN + 4)
		council.add_theme_font_size_override("font_size", 16)
		council.pressed.connect(Session.open_campaign_council)
		ScreenKit.place(council, layer, Control.PRESET_BOTTOM_RIGHT, Vector2(-44 - 380 - 16, -30))
	layer.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(layer, "modulate:a", 1.0, 0.18)


func _best_position() -> int:
	var best := 99
	for s: Dictionary in campaign.seasons:
		best = mini(best, int(s["position"]))
	return best


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.open_campaign_hub()
