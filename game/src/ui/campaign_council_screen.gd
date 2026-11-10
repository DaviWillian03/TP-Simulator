extends Control
## Conselho de regras (mockup v13-2). No fim da temporada, 3 propostas (pontuação, sprints e pneus) vão a voto: todas as
## equipes votam (a IA pelo interesse), o jogador só vota, sem lobby; maioria simples, empate barra; valem na temporada
## seguinte. Fora da janela do fim de temporada a tela só mostra as regras em vigor.

var campaign: Campaign
var regs: Regulations
var _layer: Control
var _left: VBoxContainer


func _ready() -> void:
	campaign = Session.campaign
	if campaign == null:
		Session.open_campaign.call_deferred()
		return
	regs = campaign.regs
	var team := campaign.team()
	var page := ScreenKit.garage_page(self, campaign.player_team)
	(page["backdrop"] as GarageBackdrop).set_glow(Color(team["color"]), 0.16)
	_layer = page["layer"]
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UiStyle.SP_L)
	var back := ScreenKit.round_button("back", 52, "Voltar")
	back.pressed.connect(_back)
	head.add_child(back)
	head.add_child(TeamEmblems.make_rect(campaign.player_team, 46))
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -2)
	titles.add_child(UiStyle.g_caption("%s · %s" % [team["name"], "fim da temporada %d" % campaign.season if regs.vote_open(campaign) else "temporada %d" % campaign.season]))
	titles.add_child(UiStyle.g_label("CONSELHO DE REGRAS", 26, UiStyle.G_TEXT, "black"))
	head.add_child(titles)
	ScreenKit.place(head, _layer, Control.PRESET_TOP_LEFT, Vector2(44, 20))
	ScreenKit.campaign_nav(_layer, "council")

	_left = VBoxContainer.new()
	_left.add_theme_constant_override("separation", 10)
	# coluna das propostas rola (4 propostas: 3 esportivas + 1 técnica) e não invade o painel da direita
	ScreenKit.scroll_column(_left, _layer, Vector2(44, 150), Vector2(1280 - 88 - 400 - 20, 720 - 150 - 8))

	var right := ScreenKit.g_card(Color(1, 1, 1, 0.06), 22, 22, 16)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 2)
	right.add_child(rv)
	rv.add_child(UiStyle.g_caption("Regras em vigor"))
	for line: Array in regs.rule_lines(campaign.season):
		var r := HBoxContainer.new()
		r.custom_minimum_size = Vector2(0, 30)
		var k := UiStyle.g_label(String(line[0]), 13, UiStyle.G_TEXT_2, "bold")
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		k.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(k)
		var v := UiStyle.g_label(String(line[1]), 13, UiStyle.G_TEXT, "black")
		v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(v)
		rv.add_child(r)
	if regs.vote_open(campaign):
		var done := CutButton.new()
		done.text = "CONFIRMAR VOTOS E FECHAR"
		done.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MAIN + 2)
		done.add_theme_font_size_override("font_size", UiStyle.fs(16))
		done.pressed.connect(_confirm)
		rv.add_child(done)
	ScreenKit.place(right, _layer, Control.PRESET_TOP_RIGHT, Vector2(-44, 150), Vector2(400, 0))
	_refresh()


func _back() -> void:
	if regs.vote_open(campaign):
		Session.open_campaign_report()
	else:
		Session.open_campaign_hub()


func _confirm() -> void:
	campaign.save()
	Session.open_campaign_report()


func _refresh() -> void:
	for c in _left.get_children():
		_left.remove_child(c)
		c.queue_free()
	if not regs.vote_open(campaign):
		_left.add_child(UiStyle.g_caption("Votação"))
		var l := UiStyle.g_label("Votação das regras de %d abre ao fim da temporada." % [campaign.season + 1], 16, Color("#c3c9d3"))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(640, 0)
		_left.add_child(l)
		if not regs.history.is_empty():
			_left.add_child(UiStyle.g_caption("Votações anteriores"))
			for h: Dictionary in regs.history.slice(-6):
				_left.add_child(UiStyle.g_label("%d · %s — %s (%d × %d)" % [int(h["season"]), String(h["title"]).capitalize(), "aprovada" if h["passed"] else "rejeitada", int(h["yes"]), int(h["no"])], 14, UiStyle.G_TEXT_2, "bold"))
		return
	regs.open_vote(campaign)
	_left.add_child(UiStyle.g_caption("Votação · regras de %d · todas as equipes votam, maioria simples" % (campaign.season + 1)))
	for p: Dictionary in regs.proposals:
		_left.add_child(_proposal(p))


func _proposal(p: Dictionary) -> Control:
	var id: String = p["id"]
	var card := ScreenKit.g_card(Color(1, 1, 1, 0.06), 22, 20, 14)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	var title := UiStyle.g_label(String(p["title"]), 18, UiStyle.G_TEXT, "black")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # título longo quebra a linha em vez de alargar o cartão
	title.custom_minimum_size = Vector2(200, 0)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(title)
	for o: Array in [["y", "SIM"], ["n", "NÃO"], ["w", "ABSTER"]]:
		var b := Button.new()
		b.text = o[1]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MIN)
		var on: bool = regs.player_votes.get(id, "w") == o[0]
		for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(s, UiStyle.g_box(UiStyle.G_LIGHT if on else Color(1, 1, 1, 0.1), 14, 12, 0))
		for k: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(k, UiStyle.G_INK if on else UiStyle.G_TEXT)
		b.add_theme_font_override("font", UiStyle.G_BLACK)
		b.add_theme_font_size_override("font_size", UiStyle.fs(14))
		b.pressed.connect(_on_vote.bind(id, o[0]))
		ScreenKit.press_feedback(b)
		top.add_child(b)
	v.add_child(top)
	var desc := UiStyle.g_label(String(p["desc"]), 14, Color("#c3c9d3"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(desc)
	var row := HFlowContainer.new()  # bolinhas dos votos quebram a linha se não couberem
	row.add_theme_constant_override("h_separation", 5)
	row.add_theme_constant_override("v_separation", 5)
	for t: Dictionary in campaign.teams():
		var vote: String = regs.player_votes.get(id, "w") if t["id"] == campaign.player_team else (regs.votes[id] as Dictionary).get(t["id"], "w")
		row.add_child(_dot(t, vote, t["id"] == campaign.player_team))
	var tally := regs.tally(id)
	var tl := UiStyle.g_label("%d sim · %d não · %d abst. · %s" % [tally["y"], tally["n"], tally["w"], "aprovada" if tally["passed"] else "rejeitada"], 13, UiStyle.G_TEXT_2, "bold")
	tl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(8, 0)
	row.add_child(sp)
	row.add_child(tl)
	v.add_child(row)
	return card


func _dot(t: Dictionary, vote: String, mine: bool) -> Control:
	var fill := {"y": Color("#3c9d5d"), "n": Color("#e0443a"), "w": Color(1, 1, 1, 0.16)}[vote] as Color
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(30, 30)
	var st := UiStyle.g_box(fill, 15, 0, 0)
	if mine:
		st.set_border_width_all(3)
		st.border_color = Color.WHITE
	p.add_theme_stylebox_override("panel", st)
	p.tooltip_text = String(t["name"])
	var l := UiStyle.g_label(String(t.get("short_name", t["name"])).left(2), 11, Color.WHITE, "black")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


func _on_vote(id: String, vote: String) -> void:
	regs.cast(id, vote)
	campaign.save()
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_back()
