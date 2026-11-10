extends Control
## Sede da campanha na F2/F3 (mockup design/mockups/v23-3-sede-f2.html; decisões de 2026-11-08): operação da equipe
## (engenharia, mecânicos, simulador — o chassi é igual para todos), dinheiro (caixa, pilotos pagantes, patrocínio,
## custos) e pessoal enxuto (chefe de engenharia + engenheiros de corrida, com mercado próprio). Embaixo, a próxima
## etapa; no fim do ano, o resumo da temporada e o começo do ano seguinte.

var campaign: Campaign
var _layer: Control


func _ready() -> void:
	campaign = Session.campaign
	if campaign == null or not campaign.is_feeder():
		Session.open_campaign.call_deferred()
		return
	var f := campaign.feeder
	var team := campaign.my_series().team(campaign.player_team)
	var color := Color(team.get("color", "#E10600"))
	var page := ScreenKit.garage_page(self, campaign.player_team)
	(page["backdrop"] as GarageBackdrop).set_glow(color, 0.22)
	_layer = page["layer"]

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UiStyle.SP_L)
	var back := ScreenKit.round_button("back", 52, "Menu")
	back.pressed.connect(Session.go_to_title)
	head.add_child(back)
	head.add_child(TeamEmblems.make_rect(campaign.player_team, 52))
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -2)
	titles.add_child(UiStyle.g_caption("Sede · %s · %s %d" % [String(CategoryRules.of(f.cat)["name"]), campaign.date_text(), campaign.season]))
	titles.add_child(UiStyle.g_label(String(team.get("name", "")).to_upper(), 30, UiStyle.G_TEXT, "black"))
	head.add_child(titles)
	var pill := PanelContainer.new()
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pill.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_SURFACE_HOVER, 14, 14, 6))
	pill.add_child(UiStyle.g_label("%dº nas equipes · %d pts" % [campaign.feeder_position(), campaign._feeder_points()], UiStyle.FS_SMALL, UiStyle.G_TEXT, "black"))
	head.add_child(pill)
	ScreenKit.place(head, _layer, Control.PRESET_TOP_LEFT, Vector2(44, 22))
	var stand := ScreenKit.light_button("CAMPEONATOS")
	stand.custom_minimum_size = Vector2(190, UiStyle.TOUCH_MIN + 4)
	stand.pressed.connect(Session.open_campaign_standings)
	ScreenKit.place(stand, _layer, Control.PRESET_TOP_RIGHT, Vector2(-44, 26))

	_layer.add_child(_operation_card())
	_layer.add_child(_money_card())
	_layer.add_child(_staff_card())
	_bottom()
	if campaign.state == "bankrupt":
		_show_sheet("Sem dinheiro", "O caixa ficou negativo: a equipe não consegue seguir na temporada.", [])


func _glass(pos: Vector2, w: float) -> Array:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(Color(0.03, 0.035, 0.047, 0.78), 22, 16, 14))
	p.position = pos
	p.custom_minimum_size = Vector2(w, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UiStyle.SP_S)
	p.add_child(v)
	return [p, v]


func _operation_card() -> Control:
	var f := campaign.feeder
	var g := _glass(Vector2(44, 104), 560)
	var v: VBoxContainer = g[1]
	v.add_child(UiStyle.g_caption("Operação da equipe · %d" % f.operation_score(campaign.my_series().teams)))
	var icons := {"eng": "p_gear", "mech": "wrench", "sim": "clock"}
	for a: String in FeederCareer.AREAS:
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_SURFACE, 16, 14, 10))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		row.add_child(h)
		h.add_child(ScreenKit.icon(icons[a], 26, UiStyle.G_DIRECTOR))
		var tv := VBoxContainer.new()
		tv.add_theme_constant_override("separation", 0)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UiStyle.g_label(FeederCareer.AREA_NAMES[a], UiStyle.FS_BODY, UiStyle.G_TEXT, "black"))
		tv.add_child(UiStyle.g_label(FeederCareer.AREA_DESC[a], UiStyle.FS_CAPTION, UiStyle.G_TEXT_2, "bold"))
		var pips := HBoxContainer.new()
		pips.add_theme_constant_override("separation", 4)
		for i in FeederCareer.MAX_LEVEL:
			var p := ColorRect.new()
			p.custom_minimum_size = Vector2(30, 8)
			p.color = UiStyle.G_DIRECTOR if i < int(f.levels[a]) else Color(1, 1, 1, 0.12)
			pips.add_child(p)
		tv.add_child(pips)
		h.add_child(tv)
		var cost := f.upgrade_cost(a)
		var b := ScreenKit.light_button("MÁXIMO" if cost < 0.0 else "NÍVEL %d · US$ %s mi" % [int(f.levels[a]) + 1, _m(cost)])
		b.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MIN)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.add_theme_font_size_override("font_size", UiStyle.fs(13))
		b.disabled = cost < 0.0 or f.cash < cost
		b.pressed.connect(_upgrade.bind(a))
		h.add_child(b)
		v.add_child(row)
	return g[0]


func _money_card() -> Control:
	var f := campaign.feeder
	var g := _glass(Vector2(624, 104), 612)
	var v: VBoxContainer = g[1]
	v.add_child(UiStyle.g_caption("Dinheiro"))
	var big := HBoxContainer.new()
	big.add_theme_constant_override("separation", 30)
	for t: Array in [["US$ %s mi" % _m(f.cash), "em caixa", UiStyle.G_TEXT if f.cash >= 0.0 else UiStyle.G_DOWN],
			["+ %s mi" % _m(f.pay_income_year(campaign.my_feeder_drivers())), "pilotos pagantes / ano", UiStyle.G_UP]]:
		var bv := VBoxContainer.new()
		bv.add_theme_constant_override("separation", -2)
		bv.add_child(UiStyle.g_label(t[0], 30, t[2], "black"))
		bv.add_child(UiStyle.g_caption(t[1]))
		big.add_child(bv)
	v.add_child(big)
	var up := "F2" if f.cat == "F3" else "F1"
	for kv: Array in [["Patrocínio", "US$ %s mi / ano" % _m(float(f.econ()["sponsor_year"]))],
			["Salários do pessoal", "US$ %s mi / ano" % _m(f.payroll_year())], ["Custo por etapa", "US$ %s mi" % _m(float(f.econ()["cost_round"]))],
			["Verba de entrada se subir para a %s" % up, "US$ %s mi" % _m(float(f.econ()["entry_up"]))]]:
		var h := HBoxContainer.new()
		var k := UiStyle.g_label(kv[0], UiStyle.FS_SMALL, Color("#c3c9d3"), "bold")
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(k)
		h.add_child(UiStyle.g_label(kv[1], UiStyle.FS_SMALL, UiStyle.G_TEXT, "black"))
		v.add_child(h)
	return g[0]


func _staff_card() -> Control:
	var f := campaign.feeder
	var g := _glass(Vector2(624, 386), 612)
	var v: VBoxContainer = g[1]
	v.add_child(UiStyle.g_caption("Pessoal · toque para trocar"))
	var drivers := campaign.my_feeder_drivers()
	for role: String in f.staff_roles():
		var p: Dictionary = f.staff.get(role, {})
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 48)
		for st: String in ["normal", "hover", "pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(st, UiStyle.g_box(UiStyle.G_SURFACE if st == "normal" else UiStyle.G_SURFACE_HOVER, 14, 0, 0))
		var h := HBoxContainer.new()
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_theme_constant_override("separation", 10)
		b.add_child(h)
		h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		h.offset_left = 12
		h.offset_right = -12
		h.add_child(ScreenKit.icon("shield" if role == "chief" else "headset", 22, UiStyle.G_ENGINEER))
		var tv := VBoxContainer.new()
		tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tv.alignment = BoxContainer.ALIGNMENT_CENTER
		tv.add_theme_constant_override("separation", -4)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UiStyle.g_label(String(p.get("name", "Vaga")), UiStyle.FS_SMALL + 1, UiStyle.G_TEXT, "black"))
		var sub := FeederCareer.role_name(role)
		if role != "chief":
			var i := int(role.substr(3)) - 1
			if i < drivers.size():
				sub += " · " + String(drivers[i]["name"]).get_slice(" ", String(drivers[i]["name"]).get_slice_count(" ") - 1)
		tv.add_child(UiStyle.g_label(sub, UiStyle.FS_CAPTION, UiStyle.G_TEXT_2, "bold"))
		h.add_child(tv)
		h.add_child(UiStyle.g_label(str(int(p.get("skill", 0))), 20, UiStyle.G_TEXT, "black"))
		for l in h.find_children("*", "Control", true, false):
			(l as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.pressed.connect(_open_hire.bind(role))
		ScreenKit.press_feedback(b)
		v.add_child(b)
	return g[0]


func _bottom() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UiStyle.SP_M)
	var info := PanelContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_stylebox_override("panel", UiStyle.g_box(Color(0.03, 0.035, 0.047, 0.78), 18, 16, 10))
	var ih := HBoxContainer.new()
	ih.add_theme_constant_override("separation", 12)
	ih.add_child(ScreenKit.icon("flag", 22, UiStyle.G_TEXT))
	var iv := VBoxContainer.new()
	iv.add_theme_constant_override("separation", -2)
	var go := CutButton.new()
	go.custom_minimum_size = Vector2(320, UiStyle.TOUCH_MAIN)
	if campaign.season_over():
		iv.add_child(UiStyle.g_caption("Temporada %d encerrada" % campaign.season))
		iv.add_child(UiStyle.g_label("%dº nas equipes · %d pontos" % [campaign.feeder_position(), campaign._feeder_points()], 18, UiStyle.G_TEXT, "black"))
		go.text = "FIM DE TEMPORADA"
		go.pressed.connect(_close_season)
	else:
		var rounds := campaign.feeder_rounds()
		var r := campaign.next_round()
		var c := GameData.circuit(String(r["id"]))
		var days := campaign.days_to_event()
		iv.add_child(UiStyle.g_caption("Próxima etapa · %d de %d" % [rounds.find(campaign.round) + 1, rounds.size()]))
		iv.add_child(UiStyle.g_label("%s · %s · sprint + principal" % [c.get("short_name", r["id"]), "hoje" if days <= 0 else "em %d dia%s" % [days, "" if days == 1 else "s"]], 18, UiStyle.G_TEXT, "black"))
		go.text = "IR PARA O FIM DE SEMANA"
		go.pressed.connect(_go_weekend)
	ih.add_child(iv)
	info.add_child(ih)
	row.add_child(info)
	row.add_child(go)
	_layer.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	row.offset_left = 44
	row.offset_right = -44
	row.offset_top = -88
	row.offset_bottom = -24


func _upgrade(area: String) -> void:
	if campaign.feeder_upgrade(area) != "":
		campaign.save()
	get_tree().reload_current_scene()


func _go_weekend() -> void:
	campaign.advance_to_event()
	Session.play_campaign_round()


func _open_hire(role: String) -> void:
	var f := campaign.feeder
	var sh := ScreenKit.sheet("Trocar %s" % FeederCareer.role_name(role), 820)
	var body: VBoxContainer = sh["body"]
	var cur: Dictionary = f.staff.get(role, {})
	body.add_child(UiStyle.g_label("Atual: %s · nota %d · US$ %s mi/ano" % [cur.get("name", "—"), int(cur.get("skill", 0)), _m(float(cur.get("salary", 0.0)))], UiStyle.FS_BODY, UiStyle.G_TEXT_2, "bold"))
	for p: Dictionary in f.candidates(role, campaign.season):
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		var tv := VBoxContainer.new()
		tv.add_theme_constant_override("separation", -2)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UiStyle.g_label("%s · %s" % [p["name"], p.get("nationality", "")], UiStyle.FS_BODY, UiStyle.G_TEXT, "black"))
		tv.add_child(UiStyle.g_label("nota %d · US$ %s mi/ano · taxa US$ %s mi" % [int(p["skill"]), _m(float(p["salary"])), _m(float(p["fee"]))], UiStyle.FS_SMALL, UiStyle.G_TEXT_2, "bold"))
		h.add_child(tv)
		var b := ScreenKit.light_button("CONTRATAR")
		b.custom_minimum_size = Vector2(160, UiStyle.TOUCH_MIN + 4)
		b.disabled = f.cash < float(p["fee"]) or String(p["name"]) == String(cur.get("name", ""))
		b.pressed.connect(func() -> void:
			if f.hire(role, p):
				campaign.save()
			get_tree().reload_current_scene())
		h.add_child(b)
		body.add_child(h)
	add_child(sh["root"])


func _close_season() -> void:
	var rep := campaign.feeder_close_season()
	campaign.save()
	var lines: Array = ["%dº nas equipes da %s · %d pontos · prêmio US$ %s mi" % [int(rep["position"]), rep["category"], int(rep["points"]), _m(float(rep["prize"]))]]
	var title := "Fim da temporada %d" % int(rep["season"])
	if rep["promoted"]:
		title = "Campeã! A equipe sobe para a %s" % ("F2" if rep["category"] == "F3" else "F1")
		lines.append("O acesso é automático e vem com verba de entrada para a nova categoria.")
	elif rep["relegated"]:
		title = "Última da F2: a equipe desce para a F3"
	_show_sheet(title, "\n".join(lines), [["COMEÇAR %d" % (int(rep["season"]) + 1), _start_next]])


func _start_next() -> void:
	campaign.feeder_start_next_season()
	campaign.save()
	if campaign.is_feeder():
		get_tree().reload_current_scene()
	else:
		Session.open_campaign_hub()  # subiu para a F1: a sede da F1


func _show_sheet(title: String, text: String, actions: Array) -> void:
	var sh := ScreenKit.sheet(title, 760)
	var body: VBoxContainer = sh["body"]
	var l := UiStyle.g_label(text, UiStyle.FS_BODY, UiStyle.G_TEXT_2, "bold")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(l)
	for a: Array in actions:
		var b := CutButton.new()
		b.text = a[0]
		b.custom_minimum_size = Vector2(300, UiStyle.TOUCH_MAIN)
		b.size_flags_horizontal = Control.SIZE_SHRINK_END
		b.pressed.connect(a[1])
		body.add_child(b)
	add_child(sh["root"])


static func _m(v: float) -> String:
	return String.num(v, 1).replace(".", ",")
