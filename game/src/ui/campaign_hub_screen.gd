extends Control
## Sede da campanha — direção Garagem (mockup design/mockups/v6-1-campanha-sede.html).
## Topo: data, caixa e humor da diretoria. Destaque: o próximo evento (avançar o tempo e jogar).
## Abaixo: objetivo e paciência da diretoria, finanças simples. À direita: construtores e o carro.
## As abas Pilotos, Carro, Fábrica e Finanças são camadas futuras (aparecem apagadas).

var campaign: Campaign
var _hero: PanelContainer
var _date: Label
var _count_days: Label


func _ready() -> void:
	campaign = Session.campaign
	if campaign == null:
		Session.open_campaign.call_deferred()
		return
	if campaign.season_over() or campaign.state != "active":
		Session.open_campaign_report.call_deferred()
		return
	var team := campaign.team()
	var color := Color(team["color"])
	var page := ScreenKit.garage_page(self, campaign.player_team)
	(page["backdrop"] as GarageBackdrop).set_glow(color)
	var layer: Control = page["layer"]

	# topo
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UiStyle.SP_L)
	var back := ScreenKit.round_button("back", 52, "Menu")
	back.pressed.connect(Session.go_to_title)
	head.add_child(back)
	head.add_child(TeamEmblems.make_rect(campaign.player_team, 48))
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -2)
	titles.add_child(UiStyle.g_caption("Sede · temporada %d" % campaign.season))
	titles.add_child(UiStyle.g_label(String(team["name"]).to_upper(), 28, UiStyle.G_TEXT, "black"))
	head.add_child(titles)
	ScreenKit.place(head, layer, Control.PRESET_TOP_LEFT, Vector2(44, 22))
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", UiStyle.SP_M)
	var date_box := _chip("Hoje", campaign.date_text(), 20)
	_date = date_box.get_meta("value")
	chips.add_child(date_box)
	chips.add_child(_chip("Caixa", "US$ %d mi" % int(campaign.budget_musd), 16))
	chips.add_child(_chip("Diretoria", campaign.trust_label(), 16))
	ScreenKit.place(chips, layer, Control.PRESET_TOP_RIGHT, Vector2(-44, 26))

	# abas
	var nav := PanelContainer.new()
	nav.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_SURFACE, 26, 4, 4))
	var nh := HBoxContainer.new()
	nh.add_theme_constant_override("separation", 4)
	nav.add_child(nh)
	for t: Array in [["Início", true, true], ["Campeonatos", true, false], ["Pilotos", false, false], ["Carro", false, false], ["Fábrica", false, false], ["Finanças", false, false]]:
		var b := Button.new()
		b.text = t[0]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MIN)
		ScreenKit._selectable_styles(b, UiStyle.R_PILL - 4)
		b.add_theme_stylebox_override("normal", UiStyle.g_box(UiStyle.G_LIGHT if t[2] else Color(0, 0, 0, 0), UiStyle.R_PILL - 4, 20, 0))
		b.add_theme_color_override("font_color", UiStyle.G_INK if t[2] else UiStyle.G_TEXT)
		b.add_theme_color_override("font_disabled_color", UiStyle.G_TEXT_OFF)
		b.add_theme_font_size_override("font_size", UiStyle.FS_BODY)
		b.disabled = not t[1]
		if t[0] == "Campeonatos":
			b.pressed.connect(Session.open_campaign_standings)
		nh.add_child(b)
	ScreenKit.place(nav, layer, Control.PRESET_TOP_LEFT, Vector2(44, 88))

	# coluna esquerda
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", UiStyle.SP_M)
	ScreenKit.place(left, layer, Control.PRESET_TOP_LEFT, Vector2(44, 152), Vector2(560, 0))
	left.clip_contents = false
	left.add_child(_event_card())
	left.add_child(_objective_card(color))
	left.add_child(_finance_card())

	# construtores
	var table := ScreenKit.g_card(UiStyle.G_SURFACE, 20, 20, 14)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	table.add_child(tv)
	tv.add_child(UiStyle.g_caption("Construtores · após %d de %d" % [campaign.round, Campaign.calendar().size()]))
	var rows := campaign.team_standings()
	for i in rows.size():
		var mine: bool = rows[i][0] == campaign.player_team
		if i >= 6 and not mine:
			continue
		tv.add_child(_standing_row(i + 1, rows[i][0], int(rows[i][1]), mine))
	ScreenKit.place(table, layer, Control.PRESET_TOP_RIGHT, Vector2(-44, 96), Vector2(400, 0))

	var car := CarHero.new()
	layer.add_child(car)
	car.custom_minimum_size = Vector2(560, 157)
	car.anchor_left = 0.775
	car.anchor_right = 0.775
	car.anchor_top = 0.86
	car.anchor_bottom = 0.86
	car.offset_left = -300
	car.offset_right = 260
	car.offset_top = -157
	car.offset_bottom = 0
	var first := 0
	for d: Dictionary in campaign.drivers():
		if d["team"] == campaign.player_team:
			first = int(d["number"])
			break
	var c2 := Color(team.get("color2", "#ffffff"))
	car.set_team(campaign.player_team, first, c2 if c2.get_luminance() > 0.35 else Color.WHITE, team)
	layer.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(layer, "modulate:a", 1.0, 0.18)


func _chip(caption: String, value: String, size: int) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_SURFACE_HOVER, 26, 18, 7))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -3)
	v.add_child(UiStyle.g_caption(caption))
	var l := UiStyle.g_label(value, size, UiStyle.G_TEXT, "black")
	v.add_child(l)
	p.add_child(v)
	p.set_meta("value", l)
	return p


## Cartão claro do próximo evento: contagem de dias, avançar o tempo ou entrar no fim de semana.
func _event_card() -> Control:
	var r := campaign.next_round()
	var circuit := GameData.circuit(r["id"])
	var card := PanelContainer.new()
	var st := UiStyle.g_box(UiStyle.G_LIGHT, 22, 28, 20)
	st.border_width_left = 7
	st.border_color = UiStyle.RED
	card.add_theme_stylebox_override("panel", st)
	_hero = card
	var row := HBoxContainer.new()
	card.add_child(row)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 4)
	row.add_child(v)
	var days := campaign.days_to_event()
	var ready := campaign.event_ready()
	v.add_child(UiStyle.g_caption("O fim de semana começa agora" if ready else "Próximo evento · em %d dia%s" % [days, "" if days == 1 else "s"], UiStyle.G_INK_2))
	v.add_child(UiStyle.g_label(String(r["grand_prix"]).to_upper(), 38, UiStyle.G_INK, "black"))
	var date: String = r["date"]
	var weekend := "fim de semana sprint" if r.get("sprint", false) else "fim de semana normal"
	v.add_child(UiStyle.g_label("%s · RD %d de %d · %s" % [circuit.get("short_name", ""), int(r["round"]), Campaign.calendar().size(), weekend], UiStyle.FS_BODY, UiStyle.G_INK_2))
	var facts := HBoxContainer.new()
	facts.add_theme_constant_override("separation", 10)
	for f: Array in [[str(days), "dia" if days == 1 else "dias"], ["%d%%" % roundi(float(circuit.get("rain_probability", 0)) * 100), "chance de chuva"]]:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UiStyle.g_box(Color("#e3e6eb"), 12, 14, 6))
		var fv := VBoxContainer.new()
		fv.add_theme_constant_override("separation", -2)
		fv.add_child(UiStyle.g_label(f[0], 22, UiStyle.G_INK, "black"))
		fv.add_child(UiStyle.g_label(f[1], 12, UiStyle.G_INK_2))
		p.add_child(fv)
		facts.add_child(p)
	v.add_child(facts)
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", UiStyle.SP_M)
	var go := CutButton.new()
	go.text = "JOGAR O FIM DE SEMANA" if ready else "AVANÇAR ATÉ O EVENTO"
	go.custom_minimum_size = Vector2(290, UiStyle.TOUCH_MAIN)
	go.add_theme_font_size_override("font_size", 17)
	go.pressed.connect(_on_advance)
	acts.add_child(go)
	if not ready:
		var one := ScreenKit.light_button("+1 DIA")
		one.pressed.connect(_on_one_day)
		acts.add_child(one)
	v.add_child(acts)
	var trk := TrackOutline.new()
	trk.line_color = UiStyle.G_INK
	trk.line_width = 5.0
	trk.pad = 8.0
	trk.custom_minimum_size = Vector2(110, 110)
	trk.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	trk.set_circuit(circuit)
	row.add_child(trk)
	return card


func _on_advance() -> void:
	if campaign.event_ready():
		Session.play_campaign_round()
		return
	campaign.advance_to_event()
	campaign.save()
	Session.open_campaign_hub()


func _on_one_day() -> void:
	campaign.advance_days(1)
	campaign.save()
	Session.open_campaign_hub()


func _objective_card(color: Color) -> Control:
	var card := ScreenKit.g_card(UiStyle.G_SURFACE, 20, 20, 14)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	card.add_child(v)
	v.add_child(UiStyle.g_caption("Objetivo da diretoria · temporada %d" % campaign.season))
	var goal := campaign.season_goal()
	var total := campaign.teams().size()
	var pos := campaign.team_position(campaign.player_team)
	v.add_child(UiStyle.g_label("Terminar no top %d dos construtores" % goal, 24, UiStyle.G_TEXT, "black"))
	# barra: posição atual dentro da escala (1º ... último); marca = meta
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = float(total - 1)
	bar.value = maxf(float(total - pos), 0.4)  # (último colocado: sobra um traço, a barra não parece quebrada)
	bar.custom_minimum_size = Vector2(0, 12)
	bar.add_theme_stylebox_override("background", UiStyle.g_box(Color(1, 1, 1, 0.1), 6, 0, 0))
	bar.add_theme_stylebox_override("fill", UiStyle.g_box(color.lightened(0.15) if pos <= goal else Color("#8f98a7"), 6, 0, 0))
	v.add_child(bar)
	var marks := HBoxContainer.new()
	var l := UiStyle.g_label("Hoje: %dº · %d pts" % [pos, int(campaign.team_points.get(campaign.player_team, 0))], 13, UiStyle.G_TEXT_2)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	marks.add_child(l)
	marks.add_child(UiStyle.g_label("Meta: %dº ou melhor" % goal, 13, UiStyle.G_TEXT_2))
	v.add_child(marks)
	var pat := HBoxContainer.new()
	pat.add_theme_constant_override("separation", UiStyle.SP_M)
	var pl := UiStyle.g_caption("Confiança da diretoria")
	pl.custom_minimum_size = Vector2(190, 0)
	pat.add_child(pl)
	var tb := ProgressBar.new()
	tb.show_percentage = false
	tb.max_value = 100.0
	tb.value = campaign.trust
	tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tb.custom_minimum_size = Vector2(0, 10)
	tb.add_theme_stylebox_override("background", UiStyle.g_box(Color(1, 1, 1, 0.1), 5, 0, 0))
	tb.add_theme_stylebox_override("fill", UiStyle.g_box(Color("#5c93ea") if campaign.trust >= 40.0 else Color("#ffb4a8"), 5, 0, 0))
	pat.add_child(tb)
	pat.add_child(UiStyle.g_label(campaign.trust_label(), 15, UiStyle.G_TEXT, "black"))
	v.add_child(pat)
	return card


func _finance_card() -> Control:
	var card := ScreenKit.g_card(UiStyle.G_SURFACE, 20, 20, 12)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 34)
	card.add_child(h)
	for f: Array in [["Orçamento", "US$ %d mi" % int(campaign.budget_musd)], ["Custo por rodada", "US$ %.1f mi" % campaign.cost_per_race()],
			["Patrocínio por rodada", "US$ %.1f mi" % campaign.sponsor_per_race()]]:
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", -2)
		v.add_child(UiStyle.g_caption(f[0]))
		v.add_child(UiStyle.g_label(f[1], 20, UiStyle.G_TEXT, "black"))
		h.add_child(v)
	return card


func _standing_row(pos: int, team_id: String, pts: int, mine: bool) -> Control:
	var p := PanelContainer.new()
	var fill := Color(UiStyle.team_color_from(campaign.teams(), team_id), 0.3) if mine else Color(0, 0, 0, 0)
	var st := UiStyle.g_box(fill, 10, 6, 6)
	if not mine:
		st.border_color = Color(1, 1, 1, 0.07)
		st.border_width_bottom = 1
	p.add_theme_stylebox_override("panel", st)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)
	var n := UiStyle.g_label(str(pos), 15, UiStyle.G_TEXT_2, "black")
	n.custom_minimum_size = Vector2(24, 0)
	h.add_child(n)
	h.add_child(TeamEmblems.make_rect(team_id, 20))
	var name := UiStyle.g_label(String(GameData.team_by_id(campaign.teams(), team_id).get("name", team_id)), 16, UiStyle.G_TEXT, "bold")
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.clip_text = true
	h.add_child(name)
	var pl := UiStyle.g_label(str(pts), 17, UiStyle.G_TEXT, "black")
	pl.custom_minimum_size = Vector2(44, 0)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(pl)
	return p


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.go_to_title()
