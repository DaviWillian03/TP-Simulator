extends Control
## Pessoal — pilotos, diretor técnico e engenheiros, mercado e negociação (mockups v10-1 e v10-2).
## Esquerda: seus dois pilotos e a equipe técnica. Direita: mercado (pilotos ou técnicos, com filtros).
## Tocar numa pessoa abre a negociação: salário e anos → a pessoa aceita, contrapropõe ou recusa.
## A troca só vale na virada de temporada (contratos assinados ficam "para o próximo ano").

const ROLE_SHORT := {"director": "DIRETOR\nTÉCNICO", "aero": "CHEFE DE\nAERODINÂMICA", "designer": "PROJETISTA-\nCHEFE",
	"trackside": "ENGENHARIA\nDE PISTA", "race1": "ENG. CORRIDA\nCARRO 1", "race2": "ENG. CORRIDA\nCARRO 2"}
const ROLE_COLOR := {"director": Color("#ffd24a"), "aero": Color("#5c93ea"), "designer": Color("#3c9d5d"), "trackside": Color("#ff6a5a"),
	"race1": Color("#5c93ea"), "race2": Color("#5c93ea")}

var campaign: Campaign
var pe: Personnel
var _layer: Control
var _kind := "driver"  ## aba do mercado
var _filter := "all"
var _role := ""  ## filtro de função (técnicos)
var _left: VBoxContainer
var _market_box: VBoxContainer
var _list: VBoxContainer
var _cash: Label
var _payroll: Label
var _toasts: ToastFeed
var _sheet: Control = null


func _ready() -> void:
	campaign = Session.campaign
	if campaign == null:
		Session.open_campaign.call_deferred()
		return
	pe = campaign.personnel
	var team := campaign.team()
	var page := ScreenKit.garage_page(self, campaign.player_team)
	(page["backdrop"] as GarageBackdrop).set_glow(Color(team["color"]), 0.16)
	_layer = page["layer"]

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UiStyle.SP_L)
	var back := ScreenKit.round_button("back", 52, "Voltar à sede")
	back.pressed.connect(Session.open_campaign_hub)
	head.add_child(back)
	head.add_child(TeamEmblems.make_rect(campaign.player_team, 46))
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -2)
	titles.add_child(UiStyle.g_caption("%s · %s" % [team["name"], campaign.date_text()]))
	titles.add_child(UiStyle.g_label("PESSOAL · CONTRATOS", 26, UiStyle.G_TEXT, "black"))
	head.add_child(titles)
	ScreenKit.place(head, _layer, Control.PRESET_TOP_LEFT, Vector2(44, 20))

	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", UiStyle.SP_M)
	var c1 := _chip("Caixa")
	_cash = c1.get_meta("value")
	chips.add_child(c1)
	var c2 := _chip("Folha por corrida")
	_payroll = c2.get_meta("value")
	chips.add_child(c2)
	ScreenKit.place(chips, _layer, Control.PRESET_TOP_RIGHT, Vector2(-44, 26))
	ScreenKit.campaign_nav(_layer, "staff")

	_left = VBoxContainer.new()
	_left.add_theme_constant_override("separation", 8)
	ScreenKit.scroll_column(_left, _layer, Vector2(44, 150), Vector2(600, 720 - 150 - 12))

	var market := PanelContainer.new()
	market.add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.05), 22, 18, 14))
	ScreenKit.place(market, _layer, Control.PRESET_TOP_RIGHT, Vector2(-44, 150), Vector2(520, 546))
	_market_box = VBoxContainer.new()
	_market_box.add_theme_constant_override("separation", 8)
	market.add_child(_market_box)

	_toasts = ToastFeed.new()
	_toasts.custom_minimum_size = Vector2(420, 0)
	ScreenKit.place(_toasts, _layer, Control.PRESET_TOP_LEFT, Vector2(670, 100), Vector2(420, 0))
	_refresh()
	if Session.debug_profile != "":  # (captura) abre a ficha de um piloto
		_open_profile.call_deferred(Session.debug_profile)


func _chip(caption: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_SURFACE_HOVER, 26, 18, 7))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var cap := UiStyle.g_caption(caption)
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(cap)
	var v := UiStyle.g_label("", 17, UiStyle.G_TEXT, "black")
	h.add_child(v)
	p.add_child(h)
	p.set_meta("value", v)
	return p


func _money(v: float) -> String:
	return ("%.1f" % v).replace(".", ",")


# --- atualização ------------------------------------------------------------------------------

func _refresh() -> void:
	_cash.text = "US$ %d mi" % int(campaign.budget_musd)
	_payroll.text = "US$ %s mi" % _money(pe.payroll_per_race(campaign))
	_build_left()
	_build_market()


func _build_left() -> void:
	for c in _left.get_children():
		_left.remove_child(c)
		c.queue_free()
	_left.add_child(UiStyle.g_caption("Seus pilotos · temporada %d" % campaign.season))
	for d in pe.player_drivers(campaign):
		_left.add_child(_driver_card(d))
	for id: String in pe.pending:
		var p := pe.person(id, campaign)
		if p.get("kind", "") == "driver" and not pe.is_mine(campaign, id):
			var l := UiStyle.g_label("Contratado para %d: %s (US$ %s mi/ano até %d)" % [campaign.season + 1, p["name"], _money(float(pe.pending[id]["salary"])), int(pe.pending[id]["until"])], 13, Color("#7fe0b1"), "bold")
			_left.add_child(l)
	var seats := pe.open_driver_seats(campaign)
	if seats > 0:
		_left.add_child(UiStyle.g_label("%d vaga%s de piloto para %d: contrate no mercado (ou entra um piloto automático)." % [seats, "" if seats == 1 else "s", campaign.season + 1], 13, Color("#ffd24a"), "bold"))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 4)
	_left.add_child(gap)
	_left.add_child(UiStyle.g_caption("Equipe técnica"))
	for role: String in Personnel.ROLES:
		_left.add_child(_staff_row(role))


func _driver_card(d: Dictionary) -> Control:
	var id: String = d["id"]
	var c := pe.contract_of(id)
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 88)
	for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(s, UiStyle.g_box(Color(Color(campaign.team()["color"]), 0.22) if s == "normal" else Color(1, 1, 1, 0.12), 20, 18, 0))
	ScreenKit.press_feedback(b)
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 14)
	b.add_child(h)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 18
	h.offset_right = -18
	var av := DriverPhotos.make_avatar(d, Color(campaign.team()["color"]), 56)
	h.add_child(av)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 1)
	var name_row := HBoxContainer.new()
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_theme_constant_override("separation", 8)
	var nm := UiStyle.g_label(String(d["name"]), 21, UiStyle.G_TEXT, "black")
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_child(nm)
	var num := UiStyle.g_label("#%d" % int(d["number"]), 15, UiStyle.G_TEXT_3, "bold")
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_child(num)
	v.add_child(name_row)
	var sub := UiStyle.g_label("Contrato até %d · US$ %s mi/ano" % [int(c.get("until", campaign.season)), _money(float(c.get("salary", 0.0)))], 13, UiStyle.G_TEXT_2, "bold")
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(sub)
	var tags := HBoxContainer.new()
	tags.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tags.add_theme_constant_override("separation", 6)
	if pe.dismissed.has(id):
		tags.add_child(_tag("será dispensado", "bad"))
	elif pe.pending.has(id):
		tags.add_child(_tag("renovado até %d" % int(pe.pending[id]["until"]), "ok"))
	elif int(c.get("until", 0)) <= campaign.season:
		tags.add_child(_tag("vence este ano", "warn"))
	v.add_child(tags)
	h.add_child(v)
	h.add_child(UiStyle.hspacer())
	var rt := VBoxContainer.new()
	rt.alignment = BoxContainer.ALIGNMENT_CENTER
	rt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rt.add_theme_constant_override("separation", -4)
	var big := UiStyle.g_label(str(int(d["rating"])), 34, UiStyle.G_TEXT, "black")
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rt.add_child(big)
	var cap := UiStyle.g_caption("Nota")
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rt.add_child(cap)
	h.add_child(rt)
	b.pressed.connect(_open_profile.bind(id))
	return b


func _tag(text: String, kind: String) -> PanelContainer:
	var fill: Color = {"ok": Color(0.235, 0.616, 0.365, 0.25), "warn": Color(1, 0.82, 0.29, 0.22), "bad": Color(0.88, 0.02, 0.0, 0.25)}.get(kind, Color(1, 1, 1, 0.1))
	var fg: Color = {"ok": Color("#7fe0b1"), "warn": Color("#ffd24a"), "bad": Color("#ffb4a8")}.get(kind, Color("#c3c9d3"))
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", UiStyle.g_box(fill, 10, 9, 2))
	var l := UiStyle.g_label(text, 12, fg, "bold")
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	return p


func _effect_text(role: String, skill: float) -> String:
	var days := 0.0
	var success := 0.0
	if role == "trackside":
		return "35% do acerto sorteado nos treinos (os dois carros)"
	if role.begins_with("race"):
		return "30%% do acerto sorteado nos treinos (carro %s)" % role.substr(4)
	if role == "director":
		days = maxf(skill - 50.0, 0.0) / 600.0
		success = maxf(skill - 50.0, 0.0) * 0.05
		return "−%d%% nos dias de todos os projetos" % roundi(days * 100.0)
	days = maxf(skill - 50.0, 0.0) / 500.0
	success = maxf(skill - 50.0, 0.0) * 0.13
	return "+%d pts de acerto · −%d%% dias" % [roundi(success), roundi(days * 100.0)]


func _staff_row(role: String) -> Control:
	var id: String = pe.staff.get(role, "")
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 50)
	row.add_theme_constant_override("separation", 10)
	var rl := UiStyle.g_label(String(ROLE_SHORT[role]).replace("\n", " "), 11, UiStyle.G_TEXT_3, "bold")
	rl.custom_minimum_size = Vector2(112, 0)
	rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(rl)
	var who := VBoxContainer.new()
	who.alignment = BoxContainer.ALIGNMENT_CENTER
	who.custom_minimum_size = Vector2(150, 0)
	who.add_theme_constant_override("separation", -2)
	if id == "":
		who.add_child(UiStyle.g_label("VAGO", 15, UiStyle.G_TEXT_OFF, "black"))
		who.add_child(UiStyle.g_label("sem efeito nos projetos", 12, UiStyle.G_TEXT_3))
	else:
		var p := pe.person(id)
		var c := pe.contract_of(id)
		who.add_child(UiStyle.g_label(String(p["name"]), 16, UiStyle.G_TEXT, "black"))
		var sub := "até %d · US$ %s mi" % [int(c.get("until", 0)), _money(float(c.get("salary", 0.0)))]
		var next := ""
		for pid: String in pe.pending:
			if pe.person(pid).get("role", "") == role:
				next = "→ %s (%d)" % [pe.person(pid)["name"], campaign.season + 1]
		who.add_child(UiStyle.g_label(next if next != "" else sub, 12, Color("#7fe0b1") if next != "" else UiStyle.G_TEXT_2, "bold"))
	row.add_child(who)
	var fx := UiStyle.g_label("" if id == "" else _effect_text(role, float(pe.person(id)["skill"])), 11, Color("#c3c9d3"))
	fx.custom_minimum_size = Vector2(118, 0)
	fx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fx.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(fx)
	var skill := 0
	if id != "":
		skill = int(pe.person(id)["skill"])
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.value = skill
	bar.custom_minimum_size = Vector2(60, 8)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_theme_stylebox_override("background", UiStyle.g_box(Color(1, 1, 1, 0.12), 4, 0, 0))
	bar.add_theme_stylebox_override("fill", UiStyle.g_box(ROLE_COLOR[role], 4, 0, 0))
	row.add_child(bar)
	var sv := UiStyle.g_label(str(skill) if id != "" else "—", 17, UiStyle.G_TEXT, "black")
	sv.custom_minimum_size = Vector2(28, 0)
	sv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(sv)
	var go := Button.new()
	go.text = "CONTRATAR" if id == "" else "TROCAR"
	go.focus_mode = Control.FOCUS_NONE
	go.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MIN)
	for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
		go.add_theme_stylebox_override(s, UiStyle.g_box(UiStyle.G_SURFACE_HOVER, 12, 10, 0))
	go.add_theme_font_size_override("font_size", UiStyle.fs(12))
	go.pressed.connect(_on_swap.bind(role))
	ScreenKit.press_feedback(go)
	row.add_child(go)
	return row


func _on_swap(role: String) -> void:
	_kind = "staff"
	_role = role
	_filter = "all"
	_build_market()


# --- mercado ------------------------------------------------------------------------------------

func _build_market() -> void:
	for c in _market_box.get_children():
		_market_box.remove_child(c)
		c.queue_free()
	_market_box.add_child(UiStyle.g_caption("Mercado · negocia a qualquer hora, troca na virada"))
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	var tabs := ScreenKit.segmented([["driver", "Pilotos"], ["staff", "Técnicos"]], _kind, _on_kind)
	top.add_child(tabs)
	_market_box.add_child(top)
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 6)
	var opts: Array = []
	if _kind == "driver":
		opts = [["all", "Todos"], ["free", "Livres"], ["feeder", "F2/F3 e outras"], ["teams", "Outras equipes"]]
	else:
		opts = [["", "Todos"], ["director", "Diretor"], ["aero", "Aero"], ["designer", "Projeto"], ["trackside", "Pista"], ["race", "Eng. corrida"]]
	for o: Array in opts:
		var on: bool = (_role == o[0]) if _kind == "staff" else (_filter == o[0])
		var b := Button.new()
		b.text = o[1]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 36)
		for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(s, UiStyle.g_box(UiStyle.G_LIGHT if on else Color(1, 1, 1, 0.08), 18, 12, 0))
		for k: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(k, UiStyle.G_INK if on else Color("#c3c9d3"))
		b.add_theme_font_size_override("font_size", UiStyle.fs(13))
		b.pressed.connect(_on_filter.bind(o[0]))
		ScreenKit.press_feedback(b)
		chips.add_child(b)
	_market_box.add_child(chips)
	var scroll := DragScroll.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_market_box.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 0)
	scroll.add_child(_list)
	var rows := pe.market(campaign, _kind, "all" if _kind == "staff" else _filter, _role if _kind == "staff" else "")
	for e in rows:
		_list.add_child(_market_row(e))
	if rows.is_empty():
		_list.add_child(UiStyle.g_label("Ninguém neste filtro.", 14, UiStyle.G_TEXT_3))


func _market_row(e: Dictionary) -> Control:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 52)
	for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
		var st := UiStyle.g_box(Color(0, 0, 0, 0) if s == "normal" else Color(1, 1, 1, 0.1), 10, 4, 0)
		st.border_color = Color(1, 1, 1, 0.07)
		st.border_width_bottom = 1
		b.add_theme_stylebox_override(s, st)
	ScreenKit.press_feedback(b)
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 10)
	b.add_child(h)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 6
	h.offset_right = -6
	var team_id: String = e["team"]
	var color := UiStyle.team_color_from(campaign.teams(), team_id) if GameData.team_by_id(campaign.teams(), team_id).size() > 0 else Color("#6a7487")
	if bool(e.get("mine", false)):
		color = UiStyle.team_color(campaign.player_team)
	elif team_id == "":
		color = Color("#3c9d5d")
	var av := DriverPhotos.make_avatar(e, color, 34) if e["kind"] == "driver" else DriverPhotos.make_avatar({"id": e["id"], "name": e["name"]}, color, 34)
	h.add_child(av)
	var nv := VBoxContainer.new()
	nv.alignment = BoxContainer.ALIGNMENT_CENTER
	nv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nv.add_theme_constant_override("separation", -3)
	var nm := UiStyle.g_label(String(e["name"]), 15, UiStyle.G_TEXT, "black")
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nm.clip_text = true
	nv.add_child(nm)
	var where := ""
	if e["kind"] == "staff":
		where = "%s · %s" % [String(Personnel.ROLE_NAMES[e["role"]]).replace("Diretor de engenharia de pista", "Eng. de pista"), _team_label(team_id, e)]
	else:
		where = "%s · %s" % [_team_label(team_id, e), e["nationality"]]
	var sub := UiStyle.g_label(where, 11, UiStyle.G_TEXT_2, "bold")
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub.clip_text = true
	nv.add_child(sub)
	h.add_child(nv)
	var ct := VBoxContainer.new()
	ct.alignment = BoxContainer.ALIGNMENT_CENTER
	ct.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ct.add_theme_constant_override("separation", -3)
	var l1 := "Livre" if team_id == "" and not bool(e["mine"]) else ("Sua equipe" if bool(e["mine"]) else "Contrato até %d" % int(e["until"]))
	var l2 := "pede US$ %s mi" % _money(float(e["ask"])) if float(e["buyout"]) <= 0.0 else "multa US$ %s mi" % _money(float(e["buyout"]))
	for t: String in [l1, l2]:
		var l := UiStyle.g_label(t, 11, UiStyle.G_TEXT_2, "bold")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ct.add_child(l)
	h.add_child(ct)
	var r := UiStyle.g_label(str(int(e["rating"])), 17, UiStyle.G_TEXT, "black")
	r.custom_minimum_size = Vector2(34, 0)
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(r)
	b.pressed.connect((_open_profile if e["kind"] == "driver" else _open_sheet).bind(e["id"]))
	return b


func _team_label(team_id: String, e: Dictionary) -> String:
	if bool(e.get("mine", false)):
		return String(campaign.team()["name"])
	if team_id == "":
		return "Agente livre" if e["kind"] == "driver" else "Disponível"
	var t := GameData.team_by_id(campaign.teams(), team_id)
	return String(t["name"]) if not t.is_empty() else String(e.get("category", team_id))


func _on_kind(value: String) -> void:
	_kind = value
	_filter = "all"
	_role = ""
	_build_market()


func _on_filter(value: String) -> void:
	if _kind == "staff":
		_role = value
	else:
		_filter = value
	_build_market()


# --- negociação ----------------------------------------------------------------------------------

## Pilotos abrem a ficha primeiro ("Negociar" leva à folha de contrato); técnicos vão direto à negociação.
func _open_profile(id: String) -> void:
	if _sheet != null:
		return
	var sheet := DriverSheet.new()
	sheet.setup(campaign, id)
	sheet.closed.connect(func() -> void: _sheet = null)
	sheet.negotiate.connect(func(pid: String) -> void:
		_sheet = null
		_open_sheet(pid))
	_layer.add_child(sheet)
	_sheet = sheet


func _open_sheet(id: String) -> void:
	if _sheet != null:
		return
	var sheet := NegotiationSheet.new()
	sheet.setup(campaign, id)
	sheet.closed.connect(_on_sheet_closed)
	_layer.add_child(sheet)
	_sheet = sheet


func _on_sheet_closed(message: String) -> void:
	_sheet = null
	if message != "":
		campaign.save()
		_toasts.push(message, "hot")
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.open_campaign_hub()


## Folha de negociação (mockup v10-2): salário e anos, interesse da pessoa, efeito na equipe e resposta.
class NegotiationSheet:
	extends Control

	signal closed(message: String)

	var camp: Campaign
	var pe: Personnel
	var id := ""
	var person: Dictionary = {}
	var salary := 1.0
	var years := 3
	var replace_id := ""
	var _salary_label: Label
	var _years_label: Label
	var _interest: ProgressBar
	var _effect_labels: Dictionary = {}
	var _reply: PanelContainer
	var _reply_title: Label
	var _reply_text: Label
	var _accept_btn: Button
	var _propose_btn: CutButton
	var _counter := 0.0
	var _replace_box: HBoxContainer

	func setup(p_camp: Campaign, p_id: String) -> void:
		camp = p_camp
		pe = camp.personnel
		id = p_id
		person = pe.person(id, camp)
		salary = maxf(pe.ask_for(id, camp), 0.3)
		set_anchors_preset(Control.PRESET_FULL_RECT)
		var dim := ColorRect.new()
		dim.color = Color(0.02, 0.025, 0.03, 0.72)
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(dim)
		var center := CenterContainer.new()
		center.set_anchors_preset(Control.PRESET_FULL_RECT)
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(center)
		var panel := PanelContainer.new()
		var st := UiStyle.g_box(Color("#17191e"), 24, 28, 22)
		st.shadow_color = Color(0, 0, 0, 0.55)
		st.shadow_size = 24
		panel.add_theme_stylebox_override("panel", st)
		panel.custom_minimum_size = Vector2(780, 0)
		center.add_child(panel)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 10)
		panel.add_child(v)
		v.add_child(UiStyle.g_caption("Negociação · %s" % ("piloto" if person["kind"] == "driver" else String(Personnel.ROLE_NAMES[person["role"]]).to_lower())))
		v.add_child(_header())
		var cols := HBoxContainer.new()
		cols.add_theme_constant_override("separation", 22)
		v.add_child(cols)
		cols.add_child(_left_column())
		cols.add_child(_right_column())
		_replace_box = HBoxContainer.new()
		_replace_box.add_theme_constant_override("separation", 8)
		v.add_child(_replace_box)
		v.add_child(_buttons())
		_build_replace_choice()
		_update()

	func _header() -> Control:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 16)
		var color := Color("#6a7487")
		if person["kind"] == "driver":
			h.add_child(DriverPhotos.make_avatar(person, color, 64))
		else:
			h.add_child(DriverPhotos.make_avatar({"id": id, "name": person["name"]}, color, 64))
		var n := VBoxContainer.new()
		n.add_theme_constant_override("separation", -2)
		n.add_child(UiStyle.g_label(String(person["name"]).to_upper(), 28, UiStyle.G_TEXT, "black"))
		var c := pe.contract_of(id)
		var where := "Agente livre" if c.get("team", "") == "" else ("Sua equipe" if pe.is_mine(camp, id) else String(GameData.team_by_id(camp.teams(), c["team"]).get("name", c["team"])))
		n.add_child(UiStyle.g_label("%s · %s · nota %d · contrato até %d" % [where, person["nationality"], int(person["rating"]), int(c.get("until", camp.season))], 14, UiStyle.G_TEXT_2, "bold"))
		h.add_child(n)
		h.add_child(UiStyle.hspacer())
		var ask := VBoxContainer.new()
		ask.add_theme_constant_override("separation", -4)
		var cap := UiStyle.g_caption("Pede")
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		ask.add_child(cap)
		var a := UiStyle.g_label("US$ %s mi" % ("%.1f" % pe.ask_for(id, camp)).replace(".", ","), 28, UiStyle.G_TEXT, "black")
		a.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		ask.add_child(a)
		h.add_child(ask)
		return h

	func _stepper(text_label: Label, minus: Callable, plus: Callable) -> Control:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.07), 14, 12, 6))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		p.add_child(h)
		h.add_child(_round("−", minus))
		text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h.add_child(text_label)
		h.add_child(_round("+", plus))
		return p

	func _round(text: String, cb: Callable) -> Button:
		var b := Button.new()
		b.text = text
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(UiStyle.TOUCH_MIN, UiStyle.TOUCH_MIN)
		for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(s, UiStyle.g_box(Color(1, 1, 1, 0.12 if s == "normal" else 0.22), 22, 0, 0))
		b.add_theme_font_size_override("font_size", UiStyle.fs(22))
		b.pressed.connect(cb)
		ScreenKit.press_feedback(b)
		return b

	func _left_column() -> Control:
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", 8)
		v.add_child(UiStyle.g_caption("Sua proposta"))
		_salary_label = UiStyle.g_label("", 22, UiStyle.G_TEXT, "black")
		v.add_child(_stepper(_salary_label, _on_salary.bind(-1), _on_salary.bind(1)))
		_years_label = UiStyle.g_label("", 22, UiStyle.G_TEXT, "black")
		v.add_child(_stepper(_years_label, _on_years.bind(-1), _on_years.bind(1)))
		v.add_child(UiStyle.g_caption("Interesse da pessoa"))
		_interest = ProgressBar.new()
		_interest.show_percentage = false
		_interest.max_value = 1.0
		_interest.step = 0.01
		_interest.custom_minimum_size = Vector2(0, 14)
		_interest.add_theme_stylebox_override("background", UiStyle.g_box(Color(1, 1, 1, 0.12), 7, 0, 0))
		_interest.add_theme_stylebox_override("fill", UiStyle.g_box(Color("#3c9d5d"), 7, 0, 0))
		v.add_child(_interest)
		var marks := HBoxContainer.new()
		for t: Array in [["recusa", HORIZONTAL_ALIGNMENT_LEFT], ["contraproposta", HORIZONTAL_ALIGNMENT_CENTER], ["aceita", HORIZONTAL_ALIGNMENT_RIGHT]]:
			var l := UiStyle.g_label(t[0], 12, UiStyle.G_TEXT_2)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			l.horizontal_alignment = t[1]
			marks.add_child(l)
		v.add_child(marks)
		return v

	func _right_column() -> Control:
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", 6)
		v.add_child(UiStyle.g_caption("Efeito na equipe"))
		for k: Array in [["payroll", "Folha por corrida"], ["start", "Entra na equipe"], ["fee", "Multa pela rescisão"]]:
			var row := HBoxContainer.new()
			row.custom_minimum_size = Vector2(0, 32)
			var l := UiStyle.g_label(k[1], 14, Color("#c3c9d3"))
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(l)
			var val := UiStyle.g_label("", 15, UiStyle.G_TEXT, "black")
			row.add_child(val)
			_effect_labels[k[0]] = val
			v.add_child(row)
		_reply = PanelContainer.new()
		var rst := UiStyle.g_box(Color(1, 0.82, 0.29, 0.14), 14, 16, 10)
		rst.border_width_left = 6
		rst.border_color = Color("#ffd24a")
		_reply.add_theme_stylebox_override("panel", rst)
		var rv := VBoxContainer.new()
		rv.add_theme_constant_override("separation", 0)
		_reply.add_child(rv)
		_reply_title = UiStyle.g_label("", 17, UiStyle.G_TEXT, "black")
		rv.add_child(_reply_title)
		_reply_text = UiStyle.g_label("", 14, Color("#e3e6eb"))
		_reply_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_reply_text.custom_minimum_size = Vector2(300, 0)
		rv.add_child(_reply_text)
		_reply.visible = false
		v.add_child(_reply)
		return v

	func _buttons() -> Control:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		var cancel := Button.new()
		cancel.text = "CANCELAR"
		cancel.focus_mode = Control.FOCUS_NONE
		cancel.custom_minimum_size = Vector2(150, UiStyle.TOUCH_MAIN)
		for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
			cancel.add_theme_stylebox_override(s, UiStyle.g_box(Color(1, 1, 1, 0.1), 14, 20, 0))
		cancel.add_theme_font_override("font", UiStyle.G_BLACK)
		cancel.add_theme_font_size_override("font_size", UiStyle.fs(16))
		cancel.pressed.connect(func() -> void: closed.emit(""); queue_free())
		ScreenKit.press_feedback(cancel)
		h.add_child(cancel)
		if pe.is_mine(camp, id) and not pe.dismissed.has(id):
			var dis := Button.new()
			dis.text = "DISPENSAR NA VIRADA"
			dis.focus_mode = Control.FOCUS_NONE
			dis.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MAIN)
			for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
				dis.add_theme_stylebox_override(s, UiStyle.g_box(Color(0.88, 0.02, 0.0, 0.22), 14, 18, 0))
			dis.add_theme_font_override("font", UiStyle.G_BLACK)
			dis.add_theme_font_size_override("font_size", UiStyle.fs(14))
			dis.pressed.connect(_on_dismiss)
			ScreenKit.press_feedback(dis)
			h.add_child(dis)
		h.add_child(UiStyle.hspacer())
		_accept_btn = ScreenKit.light_button("ACEITAR CONTRA")
		_accept_btn.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MAIN)
		_accept_btn.add_theme_font_size_override("font_size", UiStyle.fs(16))
		_accept_btn.visible = false
		_accept_btn.pressed.connect(_on_accept_counter)
		h.add_child(_accept_btn)
		_propose_btn = CutButton.new()
		_propose_btn.text = "PROPOR"
		_propose_btn.custom_minimum_size = Vector2(190, UiStyle.TOUCH_MAIN)
		_propose_btn.add_theme_font_size_override("font_size", UiStyle.fs(18))
		_propose_btn.pressed.connect(_on_propose)
		h.add_child(_propose_btn)
		return h

	func _build_replace_choice() -> void:
		if person["kind"] != "driver" or pe.is_mine(camp, id) or pe.open_driver_seats(camp) > 0:
			return
		var cap := UiStyle.g_label("Sem vaga: quem sai?", 14, Color("#ffd24a"), "bold")
		_replace_box.add_child(cap)
		var mine := pe.player_drivers(camp)
		replace_id = mine[0]["id"]
		for d: Dictionary in mine:
			var b := Button.new()
			b.text = String(d["name"])
			b.toggle_mode = true
			b.button_pressed = d["id"] == replace_id
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MIN)
			ScreenKit._selectable_styles(b, 14)
			b.add_theme_stylebox_override("normal", UiStyle.g_box(Color(1, 1, 1, 0.08), 14, 12, 0))
			b.add_theme_font_size_override("font_size", UiStyle.fs(14))
			var did: String = d["id"]
			b.pressed.connect(func() -> void:
				replace_id = did
				for o in _replace_box.get_children():
					if o is Button:
						(o as Button).set_pressed_no_signal(o == b))
			_replace_box.add_child(b)

	func _step() -> float:
		return 0.1 if salary < 5.0 else 0.5

	func _on_salary(dir: int) -> void:
		salary = clampf(snappedf(salary + dir * _step(), 0.1), 0.1, 30.0)
		_reply.visible = false
		_accept_btn.visible = false
		_update()

	func _on_years(dir: int) -> void:
		years = clampi(years + dir, 1, Personnel.MAX_YEARS)
		_reply.visible = false
		_accept_btn.visible = false
		_update()

	func _update() -> void:
		_salary_label.text = "US$ %s mi" % ("%.1f" % salary).replace(".", ",")
		_years_label.text = "%d ano%s" % [years, "" if years == 1 else "s"]
		var ev := pe.evaluate(camp, id, salary, years)
		_interest.value = float(ev["interest"])
		var tint := Color("#e0443a") if ev["result"] == "refuse" else (Color("#ffd24a") if ev["result"] == "counter" else Color("#3c9d5d"))
		_interest.add_theme_stylebox_override("fill", UiStyle.g_box(tint, 7, 0, 0))
		var current := float(pe.contract_of(id).get("salary", 0.0)) if pe.is_mine(camp, id) else 0.0
		var delta := (salary - current) / float(maxi(Campaign.calendar().size(), 1))
		(_effect_labels["payroll"] as Label).text = "%s US$ %s mi" % ["+" if delta >= 0 else "−", ("%.2f" % absf(delta)).replace(".", ",")]
		(_effect_labels["start"] as Label).text = "virada de %d → %d" % [camp.season, camp.season + 1]
		var fee := pe.buyout_cost(id, camp)
		(_effect_labels["fee"] as Label).text = "—" if fee <= 0.0 else "US$ %s mi" % ("%.1f" % fee).replace(".", ",")
		var info := pe.can_negotiate(camp, id)
		_propose_btn.disabled = not info["ok"]
		if not info["ok"]:
			_propose_btn.text = "JÁ ASSINADO" if info["reason"] == "pending" else "SEM CAIXA"

	func _on_propose() -> void:
		var ev := pe.evaluate(camp, id, salary, years)
		_reply.visible = true
		_accept_btn.visible = false
		match ev["result"]:
			"accept":
				var res := pe.sign(camp, id, salary, years, replace_id)
				if res["ok"]:
					closed.emit(String(res["text"]))
					queue_free()
				else:
					_reply_title.text = "Não deu"
					_reply_text.text = String(res["text"])
			"counter":
				_counter = float(ev["counter"])
				_reply_title.text = "Contraproposta"
				_reply_text.text = String(ev["text"])
				_accept_btn.text = "ACEITAR CONTRA (US$ %s mi)" % ("%.1f" % _counter).replace(".", ",")
				_accept_btn.visible = true
			_:
				_reply_title.text = "Recusa"
				_reply_text.text = String(ev["text"])

	func _on_accept_counter() -> void:
		salary = _counter
		_update()
		_on_propose()

	func _on_dismiss() -> void:
		var fee := pe.dismiss(camp, id)
		closed.emit("%s sai na virada (multa US$ %s mi)." % [person["name"], ("%.1f" % fee).replace(".", ",")])
		queue_free()
