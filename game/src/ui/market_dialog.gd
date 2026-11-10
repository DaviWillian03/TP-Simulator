class_name MarketDialog
extends Control
## Janela de decisão do mercado (mockups v27-1 e v27-2): proposta de rival por alguém da sua equipe (cobrir, aceitar a
## multa, deixar ir) ou pedido de renovação (aceitar, recusar, depois). A campanha fica parada até você decidir.

signal resolved(text: String)

var campaign: Campaign
var decision: Dictionary


func setup(camp: Campaign, d: Dictionary) -> void:
	campaign = camp
	decision = d
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.027, 0.04, 0.74)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	var st := UiStyle.g_box(Color("#171a21"), 24, 24, 20)
	st.shadow_color = Color(0, 0, 0, 0.6)
	st.shadow_size = 24
	panel.add_theme_stylebox_override("panel", st)
	panel.custom_minimum_size = Vector2(900, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	panel.add_child(v)
	var pe: Personnel = camp.personnel
	var id: String = d["id"]
	var who: Dictionary = pe.person(id, camp)
	var c: Dictionary = pe.contract_of(id)
	var offer: bool = d["kind"] == "offer"
	var rival := GameData.team_by_id(camp.teams(), String(d["team"]))
	var first := String(who.get("name", "")).get_slice(" ", String(who.get("name", "")).get_slice_count(" ") - 1)
	# topo: etiqueta e prazo
	var head := HBoxContainer.new()
	head.add_child(_chip("MERCADO · PROPOSTA" if offer else "RENOVAÇÃO", "hand" if offer else "person", Color("#3c9d5d") if offer else UiStyle.SECTION["staff"], Color.WHITE))
	head.add_child(UiStyle.hspacer())
	head.add_child(_chip("decida agora" if offer else "contrato acaba em %d" % int(c.get("until", camp.season)), "timer" if offer else "cal", Color(1, 1, 1, 0.08), UiStyle.G_TEXT))
	v.add_child(head)
	# quem e para onde
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	if who.get("kind", "") == "driver":
		var dd := {"id": id, "name": who["name"], "code": who.get("code", "")}
		row.add_child(DriverPhotos.make_avatar(dd, UiStyle.team_color(camp.player_team), 92))
	else:
		var sq := PanelContainer.new()
		sq.custom_minimum_size = Vector2(92, 92)
		sq.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.SECTION["staff"], 46, 0, 0))
		var ic := ScreenKit.icon("person", 46, Color.WHITE)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sq.add_child(ic)
		row.add_child(sq)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var title := ("A %s QUER %s" % [String(rival.get("name", "")).to_upper(), first.to_upper()]) if offer else ("%s QUER RENOVAR" % first.to_upper())
	var tl := UiStyle.g_label(title, 30, UiStyle.G_TEXT, "black")
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(tl)
	var role := "piloto · nota %d" % int(who.get("rating", 0)) if who.get("kind", "") == "driver" else "%s · nota %d" % [String(Personnel.ROLE_NAMES.get(who.get("role", ""), "técnico")).to_lower(), int(who.get("rating", 0))]
	tv.add_child(UiStyle.g_label(("para %d · %s" % [camp.season + 1, role]) if offer else "\"Quero continuar aqui. Mas o meu valor subiu.\"", 15, UiStyle.G_TEXT_2, "bold"))
	row.add_child(tv)
	if offer:
		row.add_child(TeamEmblems.make_rect(camp.player_team, 56))
		var ar := UiStyle.g_label("→", 22, UiStyle.G_TEXT_3, "black")
		ar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(ar)
		row.add_child(TeamEmblems.make_rect(String(d["team"]), 56))
	v.add_child(row)
	# comparação
	var cmp := HBoxContainer.new()
	cmp.add_theme_constant_override("separation", 16)
	cmp.add_child(_col("Hoje", "US$ %s mi" % _m(float(c.get("salary", 0.0))), "por ano · contrato até %d" % int(c.get("until", camp.season)), Color(1, 1, 1, 0.05), UiStyle.G_TEXT_3))
	if offer:
		cmp.add_child(_col("Proposta da %s" % rival.get("name", ""), "US$ %s mi" % _m(float(d["salary"])), "por ano · %d anos" % int(d["years"]), Color(0.88, 0.02, 0.0, 0.14), Color("#ff8a80")))
		cmp.add_child(_col("Multa para você", "US$ %s mi" % _m(float(d["fee"])), "se aceitar liberá-lo", Color(0.235, 0.616, 0.365, 0.16), UiStyle.G_UP))
	else:
		cmp.add_child(_col("Pedido", "US$ %s mi" % _m(float(d["salary"])), "por ano · até %d" % (camp.season + int(d["years"])), Color(0.65, 0.42, 1.0, 0.16), Color("#c9a7ff")))
	v.add_child(cmp)
	# opções
	var opts := HBoxContainer.new()
	opts.add_theme_constant_override("separation", 12)
	var raise := float(d["salary"]) - float(c.get("salary", 0.0))
	for o: Array in TransferMarket.options_for(d):
		var code: String = o[0]
		var desc := ""
		var tag := ""
		var tag_kind := ""
		var icon_name := "check"
		match code:
			"cover":
				desc = "Iguala os US$ %s mi/ano e ele fica até %d." % [_m(float(d["salary"])), maxi(int(c.get("until", camp.season)), camp.season) + (int(d["years"]) if int(c.get("until", 0)) <= camp.season else 1)]
				tag = "+%s mi/ano na folha" % _m(maxf(raise, 0.0))
			"fee":
				icon_name = "money"
				desc = "Recebe US$ %s mi agora; ele fica até o fim do ano e vai na virada." % _m(float(d["fee"]))
				tag = "+%s mi no caixa" % _m(float(d["fee"]))
				tag_kind = "ok"
			"let_go":
				icon_name = "timer"
				desc = "Recusa a multa; ele sai quando o contrato acabar (%d)." % int(c.get("until", camp.season))
				tag = "sem custo"
			"accept":
				desc = "Renova até %d por US$ %s mi/ano." % [camp.season + int(d["years"]), _m(float(d["salary"]))]
			"refuse":
				icon_name = "lock"
				desc = "Ele perde confiança e sai quando o contrato acabar."
				if who.get("kind", "") == "driver":
					tag = "−2 ritmo e regularidade · 3 corridas"
					tag_kind = "bad"
			"later":
				icon_name = "timer"
				desc = "Ele pergunta de novo em algumas semanas (só uma vez)."
		var short: String = {"cover": "COBRIR", "fee": "ACEITAR A MULTA", "let_go": "DEIXAR IR"}.get(code, String(o[1]).to_upper())
		opts.add_child(_option(code, short, desc, icon_name, tag, tag_kind, code in ["cover", "accept"]))
	v.add_child(opts)
	if offer:
		v.add_child(UiStyle.g_label("A campanha fica parada até você decidir.", 13, UiStyle.G_TEXT_2, "bold"))


func _option(code: String, title: String, desc: String, icon_name: String, tag: String, tag_kind: String, primary: bool) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 156)
	var fill := UiStyle.G_LIGHT if primary else Color(1, 1, 1, 0.06)
	for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(s, UiStyle.g_box(fill if s == "normal" else fill.lightened(0.06) if not primary else UiStyle.G_LIGHT_PRESS, 18, 0, 0))
	var ink := UiStyle.G_INK if primary else UiStyle.G_TEXT
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for k: String in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + k, 14)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(ScreenKit.icon(icon_name, 22, ink if icon_name != "money" else UiStyle.SECTION["money"]))
	h.add_child(UiStyle.g_label(title, 17, ink, "black"))
	v.add_child(h)
	var dl := UiStyle.g_label(desc, 13, UiStyle.G_INK_2 if primary else UiStyle.G_TEXT_2, "bold")
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(dl)
	if tag != "":
		var fg := {"ok": UiStyle.G_UP, "bad": UiStyle.G_DOWN}.get(tag_kind, UiStyle.G_INK_2 if primary else UiStyle.G_TEXT_2) as Color
		var t := _chip(tag, "", Color(fg, 0.18), fg)
		t.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		v.add_child(t)
	m.add_child(v)
	b.add_child(m)
	b.pressed.connect(func() -> void:
		var text := campaign.personnel.transfers.resolve(campaign, int(decision["uid"]), code)
		campaign.save()
		resolved.emit(text)
		queue_free())
	ScreenKit.press_feedback(b)
	return b


func _col(cap: String, big: String, small: String, fill: Color, cap_col: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", UiStyle.g_box(fill, 18, 16, 12))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.add_child(UiStyle.g_caption(cap, cap_col))
	v.add_child(UiStyle.g_label(big, 26, UiStyle.G_TEXT, "black"))
	v.add_child(UiStyle.g_label(small, 13, UiStyle.G_TEXT_2, "bold"))
	p.add_child(v)
	return p


func _chip(text: String, icon_name: String, fill: Color, fg: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(fill, 15, 12, 4))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	if icon_name != "":
		h.add_child(ScreenKit.icon(icon_name, 16, fg))
	h.add_child(UiStyle.g_label(text, 13, fg, "black"))
	p.add_child(h)
	return p


static func _m(v: float) -> String:
	return ("%.1f" % v).replace(".", ",")
