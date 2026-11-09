extends Control
## Carro · peças (mockups v15-2, v15-2b, v15-3 e v15-4 aprovados, 2026-11-04). Esquerda: o carro visto de cima com uma
## etiqueta por peça e as 4 características do carro escolhido. Direita: a peça tocada, com as abas
## **Usar** (unidades com anel de desgaste e o que fazer para o próximo GP) e **Desenvolver** (direções da próxima versão,
## custo, prazo, GP previsto e a chance de o upgrade funcionar pela equipe técnica e pela fábrica).
## Símbolos no lugar de texto longo sempre que der (pedido do usuário).

const PART_ICON := {"fwing": "p_fwing", "rwing": "p_rwing", "floor": "p_floor", "susp": "p_susp", "pu": "p_pu", "gearbox": "p_gear"}
const TRAIT_ROWS := [["straight", "t_straight", "#ffd24a", "reta"], ["slow", "t_slow", "#ff6a5a", "curvas lentas"],
	["fast", "t_fast", "#5c93ea", "curvas rápidas"], ["rel", "t_rel", "#3c9d5d", "confiabilidade"]]
const OK_COLOR := Color("#7fe0b1")
const BAD_COLOR := Color("#ff8a80")
const WARN := Color("#ffd24a")

var campaign: Campaign
var parts: CarParts
var _layer: Control
var _stage: PartsStage
var _panel: VBoxContainer
var _strip: HBoxContainer
var _cash: Label
var _slots_chip: Label
var _car := 0
var _part := "fwing"
var _tab := "use"
var _choice := ""  ## opção escolhida na aba Usar ou direção na aba Desenvolver
var _driver_tabs: PanelContainer


func _ready() -> void:
	campaign = Session.campaign
	if campaign == null:
		Session.open_campaign.call_deferred()
		return
	parts = campaign.my_parts()
	for a: String in OS.get_cmdline_user_args():  # (capturas) --part=<peça> --tab=dev
		if a.begins_with("--part="):
			_part = a.trim_prefix("--part=")
		elif a == "--tab=dev":
			_tab = "dev"
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
	titles.add_child(UiStyle.g_label("CARRO · PEÇAS", 26, UiStyle.G_TEXT, "black"))
	head.add_child(titles)
	ScreenKit.place(head, _layer, Control.PRESET_TOP_LEFT, Vector2(44, 20))

	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", UiStyle.SP_M)
	var tree_btn := ScreenKit.glass_pill_button("Árvore de P&D")
	tree_btn.icon = load("res://assets/icons/tree.svg")
	tree_btn.add_theme_constant_override("icon_max_width", 18)
	tree_btn.pressed.connect(Session.open_campaign_rd)
	chips.add_child(tree_btn)
	var c1 := _chip("money")
	c1.set_meta("frame_dup", true)  # a barra do topo da campanha já mostra o caixa
	_cash = c1.get_meta("value")
	chips.add_child(c1)
	var c2 := _chip("factory")
	_slots_chip = c2.get_meta("value")
	chips.add_child(c2)
	ScreenKit.place(chips, _layer, Control.PRESET_TOP_RIGHT, Vector2(-44, 24))
	ScreenKit.campaign_nav(_layer, "car")

	_stage = PartsStage.new()
	_stage.c1 = Color(team["color"])
	_stage.c2 = Color(team.get("color2", "#ffffff"))
	_stage.part_pressed.connect(_on_part)
	ScreenKit.place(_stage, _layer, Control.PRESET_TOP_LEFT, Vector2(44, 146), Vector2(808, 556))
	_stage.size = Vector2(808, 556)

	var ids := campaign.team_driver_ids(campaign.player_team)
	var opts: Array = []
	for i in ids.size():
		var d := _driver(ids[i])
		opts.append([i, "%s · %d" % [String(d.get("name", "")).get_slice(" ", String(d.get("name", "")).get_slice_count(" ") - 1), int(d.get("number", 0))]])
	_driver_tabs = ScreenKit.segmented(opts, _car, func(v: Variant) -> void: _car = int(v); _refresh())
	_stage.add_child(_driver_tabs)
	_driver_tabs.position = Vector2(16, 14)
	var hint := UiStyle.g_label("Toque numa peça", 12, UiStyle.G_TEXT_2, "bold")
	_stage.add_child(hint)
	hint.position = Vector2(808 - 130, 26)

	_strip = HBoxContainer.new()
	_strip.add_theme_constant_override("separation", 10)
	_stage.add_child(_strip)
	_strip.position = Vector2(16, 556 - 74)
	_strip.size = Vector2(808 - 32, 60)

	var panel_card := ScreenKit.g_card(Color(1, 1, 1, 0.07), 24, 18, 16)
	panel_card.clip_contents = true
	panel_card.custom_minimum_size = Vector2(372, 556)
	_panel = VBoxContainer.new()
	_panel.add_theme_constant_override("separation", 8)
	panel_card.add_child(_panel)
	ScreenKit.place(panel_card, _layer, Control.PRESET_TOP_LEFT, Vector2(1280 - 44 - 372, 146), Vector2(372, 556))
	_refresh()
	_show_pending.call_deferred()


func _driver(id: String) -> Dictionary:
	for d: Dictionary in campaign.drivers():
		if d["id"] == id:
			return d
	return {}


func _chip(icon_name: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_SURFACE_HOVER, 26, 16, 8))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.add_child(ScreenKit.icon(icon_name, 18, UiStyle.G_TEXT_2))
	var v := UiStyle.g_label("", 17, UiStyle.G_TEXT, "black")
	h.add_child(v)
	p.add_child(h)
	p.set_meta("value", v)
	return p


# --- atualização -----------------------------------------------------------------------------------

func _refresh() -> void:
	_cash.text = "US$ %s mi" % _money(campaign.budget_musd)
	_slots_chip.text = "%d / %d" % [campaign.dev.busy(), campaign.dev.slots()]
	_stage.selected = _part
	var rows: Array = []
	for pid: String in CarParts.part_ids():
		rows.append(_callout_row(pid))
	_stage.set_callouts(rows)
	_fill_strip()
	_fill_panel()


func _callout_row(pid: String) -> Dictionary:
	var p := CarParts.part(pid)
	var u := parts.unit_on(pid, _car)
	var s := parts.spec(pid, int(u.get("spec", 0)))
	var latest := parts.latest_spec(pid)
	var sub := "Spec %s" % s.get("v", "A")
	if not bool(s.get("revealed", true)):
		sub += " · em teste"
	var st := parts.stock(pid).size()
	sub += " · %d no estoque" % st if st > 0 else ""
	var alert := ""
	var kind := ""
	if not parts.research_of(pid).is_empty():
		alert = "PESQUISA"
		kind = "warn"
	if latest > int(u.get("spec", 0)) and not parts.stock(pid, latest).is_empty():
		alert = "NOVA"
		kind = ""
	elif float(u.get("wear", 0.0)) >= CarParts.WEAR_SOFT:
		alert = "DESGASTE"
		kind = "warn"
	elif bool(s.get("revealed", true)) and s.get("outcome", "") == "bad":
		alert = "FALHOU"
		kind = ""
	return {"id": pid, "title": p["name"], "sub": sub, "color": p["color"], "alert": alert, "alert_kind": kind}


## Valor exibido de uma característica: nota + desvio de fábrica + peças conhecidas do carro escolhido.
func _trait_value(k: String) -> float:
	var t: Dictionary = campaign.team().get("car_traits", {})
	if k == "rel":
		return float(t.get("rel", CarParts.REL_NEUTRAL)) + parts.known_trait_delta(_car, "rel")
	return campaign.base_rating + campaign.dev.rating_bonus() + float(t.get(k, 0.0)) + parts.known_trait_delta(_car, k)


func _fill_strip() -> void:
	for c in _strip.get_children():
		c.queue_free()
	for row: Array in TRAIT_ROWS:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", UiStyle.g_box(Color(0, 0, 0, 0.45), 14, 12, 6))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		h.add_child(ScreenKit.icon(row[1], 26, Color(row[2])))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", -4)
		v.add_child(UiStyle.g_label("%d" % roundi(_trait_value(row[0])), 22, UiStyle.G_TEXT, "black"))
		v.add_child(UiStyle.g_label(row[3], 11, UiStyle.G_TEXT_2, "bold"))
		h.add_child(v)
		card.add_child(h)
		_strip.add_child(card)


func _on_part(pid: String) -> void:
	if pid != _part:
		_part = pid
		_choice = ""
	_refresh()


func _clear(n: Node) -> void:
	for c in n.get_children():
		c.queue_free()


func _fill_panel() -> void:
	_clear(_panel)
	var p := CarParts.part(_part)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var sq := PanelContainer.new()
	sq.custom_minimum_size = Vector2(46, 46)
	sq.add_theme_stylebox_override("panel", UiStyle.g_box(Color(p["color"]), 14, 9, 9))
	sq.add_child(ScreenKit.icon(PART_ICON[_part], 26, UiStyle.G_INK))
	head.add_child(sq)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", -2)
	tv.add_child(UiStyle.g_caption(String(p["area"])))
	tv.add_child(UiStyle.g_label(String(p["name"]).to_upper(), 22, UiStyle.G_TEXT, "black"))
	head.add_child(tv)
	_panel.add_child(head)
	var tabs := ScreenKit.segmented([["use", "Usar"], ["dev", "Desenvolver"]], _tab, func(v: Variant) -> void: _tab = String(v); _choice = ""; _refresh())
	_panel.add_child(tabs)
	if _tab == "use":
		_fill_use()
	else:
		_fill_dev()


# --- aba Usar ------------------------------------------------------------------------------------------

func _fill_use() -> void:
	_panel.add_child(UiStyle.g_caption("Unidades · desgaste"))
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	var shown := 0
	var ids := campaign.team_driver_ids(campaign.player_team)
	var ordered: Array = []
	for car in 2:
		var u := parts.unit_on(_part, car)
		if not u.is_empty():
			ordered.append(u)
	var stock := parts.stock(_part)
	stock.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["spec"]) > int(b["spec"]))
	ordered.append_array(stock)
	for u: Dictionary in ordered:
		if shown >= 4:
			break
		flow.add_child(_unit_tile(u, ids))
		shown += 1
	_panel.add_child(flow)
	var nxt := campaign.next_round()
	var cap := HBoxContainer.new()
	cap.add_theme_constant_override("separation", 6)
	cap.add_child(ScreenKit.icon("flag", 14, UiStyle.G_TEXT_3))
	cap.add_child(UiStyle.g_caption(("%s · %s" % [_gp_short(nxt), campaign.date_text(Campaign._day_of(String(nxt["date"])))]) if not nxt.is_empty() else "Fim da temporada"))
	_panel.add_child(cap)
	var opts := _use_options(ids)
	if opts.is_empty():
		_panel.add_child(UiStyle.g_label("Nada a trocar: os dois carros já estão com a melhor unidade.", 13, UiStyle.G_TEXT_2))
	else:
		if _choice == "" or not opts.any(func(o: Dictionary) -> bool: return o["id"] == _choice):
			_choice = opts[0]["id"]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		for o: Dictionary in opts.slice(0, 3):
			row.add_child(_option_tile(o))
		_panel.add_child(row)
	var q := parts.queued(_part)
	var info := HBoxContainer.new()
	info.add_theme_constant_override("separation", 8)
	info.add_child(ScreenKit.icon("clock", 16, UiStyle.G_TEXT_2))
	var qtext := "Fábrica livre para esta peça."
	if not q.is_empty():
		qtext = "%d na fila · próxima pronta em %d dias" % [q.size(), int(q[0]["days_left"])]
	var ql := UiStyle.g_label(qtext, 12, UiStyle.G_TEXT_2, "bold")
	ql.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(ql)
	_panel.add_child(info)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.add_child(spacer)
	var go := CutButton.new()
	go.text = "CONFIRMAR"
	go.disabled = opts.is_empty()
	go.pressed.connect(_confirm_use.bind(opts))
	_panel.add_child(go)


func _unit_tile(u: Dictionary, ids: Array) -> Control:
	var s := parts.spec(_part, int(u["spec"]))
	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(78, 0)
	tile.add_theme_stylebox_override("panel", UiStyle.g_box(Color(0, 0, 0, 0.28), 14, 2, 8))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var ring := WearRing.new()
	ring.letter = String(s.get("v", "A"))
	ring.life = 100.0 - float(u["wear"])
	ring.unknown = not bool(s.get("revealed", true))
	ring.failed = bool(s.get("revealed", true)) and s.get("outcome", "") == "bad"
	ring.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ring)
	var loc := HBoxContainer.new()
	loc.alignment = BoxContainer.ALIGNMENT_CENTER
	loc.add_theme_constant_override("separation", 5)
	var car := int(u["car"])
	if car >= 0 and car < ids.size():
		var d := _driver(ids[car])
		loc.add_child(DriverPhotos.make_avatar(d, Color(campaign.team()["color"]), 18))
		loc.add_child(UiStyle.g_label(Campaign.driver_code(String(d.get("name", ""))), 12, UiStyle.G_TEXT, "black"))
	else:
		loc.add_child(ScreenKit.icon("box", 15, UiStyle.G_TEXT_2))
		loc.add_child(UiStyle.g_label("estoque", 11, UiStyle.G_TEXT, "black"))
	v.add_child(loc)
	var sub := "%d%% · %d GP" % [roundi(100.0 - float(u["wear"])), int(u["races"])] if int(u["races"]) > 0 else "nova"
	var sl := UiStyle.g_label(sub, 11, UiStyle.G_TEXT_2, "bold")
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sl)
	tile.add_child(v)
	return tile


## Opções para o próximo GP: instalar a melhor unidade do estoque num carro, acelerar a fila, ou fabricar.
func _use_options(ids: Array) -> Array:
	var out: Array = []
	var best := parts.best_stock_unit(_part)
	if not best.is_empty():
		var letter := String(parts.spec(_part, int(best["spec"]))["v"])
		for car in mini(2, ids.size()):
			var cur := parts.unit_on(_part, car)
			if parts._unit_value(best, CarParts.NEUTRAL) > parts._unit_value(cur, CarParts.NEUTRAL) + 0.01 or float(cur.get("wear", 0.0)) >= CarParts.WEAR_SOFT:
				out.append({"id": "install%d" % car, "kind": "install", "uid": int(best["uid"]), "car": car, "letter": letter, "driver": ids[car], "cost": 0.0})
	if not parts.queued(_part).is_empty():
		out.append({"id": "rush", "kind": "rush", "letter": String(parts.spec(_part, int(parts.queued(_part)[0]["spec"]))["v"]), "cost": parts.rush_cost(_part)})
	var latest := parts.latest_spec(_part)
	var installed_latest := 0
	for car in 2:
		if int(parts.unit_on(_part, car).get("spec", -1)) == latest:
			installed_latest += 1
	var have := parts.stock(_part, latest).size() + parts.queued(_part).filter(func(q: Dictionary) -> bool: return int(q["spec"]) == latest).size()
	var bad: bool = bool(parts.spec(_part, latest)["revealed"]) and parts.spec(_part, latest)["outcome"] == "bad"
	if not bad and installed_latest + have < 2:
		out.append({"id": "make1", "kind": "make", "n": 1, "letter": String(parts.spec(_part, latest)["v"]), "cost": parts.unit_cost(_part)})
	if out.size() < 3 and int(CarParts.part(_part).get("wear", 0)) > 0:
		out.append({"id": "spare", "kind": "make", "n": 1, "letter": String(parts.spec(_part, latest if not bad else 0)["v"]), "cost": parts.unit_cost(_part), "spare": true})
	return out


func _option_tile(o: Dictionary) -> Button:
	var on: bool = o["id"] == _choice
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_stretch_ratio = 1.0
	b.custom_minimum_size = Vector2(104, 104)
	b.clip_contents = true
	var st := UiStyle.g_box(UiStyle.G_LIGHT if on else Color(0, 0, 0, 0.28), 14, 4, 8)
	st.set_border_width_all(3 if on else 0)
	st.border_color = Color(campaign.team()["color"])
	for s: String in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		b.add_theme_stylebox_override(s, st)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vis := HBoxContainer.new()
	vis.alignment = BoxContainer.ALIGNMENT_CENTER
	vis.add_theme_constant_override("separation", 3)
	vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := Color(CarParts.part(_part)["color"])
	var ink := UiStyle.G_INK if on else UiStyle.G_TEXT
	var label := ""
	match o["kind"]:
		"install":
			vis.add_child(_spec_badge(o["letter"], col))
			vis.add_child(ScreenKit.icon("arrow", 14, ink))
			vis.add_child(DriverPhotos.make_avatar(_driver(o["driver"]), Color(campaign.team()["color"]), 32))
			var nm := String(_driver(o["driver"]).get("name", ""))
			label = "%s no %s" % [o["letter"], nm.get_slice(" ", nm.get_slice_count(" ") - 1)]
		"rush":
			vis.add_child(ScreenKit.icon("bolt", 28, WARN))
			vis.add_child(_spec_badge(o["letter"], col))
			label = "Acelerar fila"
		_:
			vis.add_child(ScreenKit.icon("factory", 26, ink))
			vis.add_child(_spec_badge(o["letter"], col))
			label = "Reserva" if bool(o.get("spare", false)) else "Fabricar"
	v.add_child(vis)
	var l := UiStyle.g_label(label, 12, ink, "black")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var price := PanelContainer.new()
	price.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var free := float(o["cost"]) <= 0.0
	price.add_theme_stylebox_override("panel", UiStyle.g_box(Color(0.22, 0.83, 0.42, 0.18) if free else Color(1, 0.7, 0.66, 0.18), 7, 7, 1))
	price.add_child(UiStyle.g_label("grátis" if free else "US$ %s mi" % _money(float(o["cost"])), 11,
		(Color("#2a8a4c") if on else OK_COLOR) if free else (Color("#c0392b") if on else Color("#ffb4a8")), "black"))
	v.add_child(price)
	b.add_child(v)
	b.pressed.connect(func() -> void: _choice = o["id"]; _refresh())
	ScreenKit.press_feedback(b)
	return b


func _spec_badge(letter: String, col: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(32, 32)
	p.add_theme_stylebox_override("panel", UiStyle.g_box(Color(col, 0.22), 10, 0, 0))
	var l := UiStyle.g_label(letter, 16, col, "black")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


func _confirm_use(opts: Array) -> void:
	for o: Dictionary in opts:
		if o["id"] != _choice:
			continue
		match o["kind"]:
			"install":
				parts.install(int(o["uid"]), int(o["car"]))
			"rush":
				parts.rush(campaign, _part)
			"make":
				var latest := parts.latest_spec(_part)
				var bad: bool = bool(parts.spec(_part, latest)["revealed"]) and parts.spec(_part, latest)["outcome"] == "bad"
				parts.order_units(campaign, _part, 0 if bad else latest, int(o.get("n", 1)))
	_choice = ""
	campaign.refresh_rating()
	campaign.save()
	_refresh()


# --- aba Desenvolver ------------------------------------------------------------------------------------

func _fill_dev() -> void:
	var p := CarParts.part(_part)
	if not parts.can_develop(campaign, _part):
		_panel.add_child(_note("lock", "Motor do fornecedor (%s): só quem fabrica o próprio motor desenvolve a unidade de potência." % campaign.team().get("power_unit", "")))
		return
	var r := parts.research_of(_part)
	if not r.is_empty():
		_research_card(r)
		return
	# peça revelada ruim (ou abaixo do prometido): corrigir
	var latest := parts.latest_spec(_part)
	var ls := parts.spec(_part, latest)
	var fix := parts.fix_info(campaign, _part, latest)
	if fix["ok"] and not bool(ls.get("fixed", false)):
		var fb := ScreenKit.glass_pill_button("Corrigir a %s · US$ %s mi · %d dias" % [ls["v"], _money(float(fix["cost"])), int(fix["days"])])
		fb.icon = load("res://assets/icons/wrench.svg")
		fb.add_theme_constant_override("icon_max_width", 18)
		fb.pressed.connect(func() -> void:
			if parts.start_fix(campaign, _part, latest):
				campaign.save()
			_refresh())
		_panel.add_child(fb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	if _choice == "":
		_choice = String(p["dirs"][0]["id"])
	row.add_theme_constant_override("separation", 6)
	for d: Dictionary in p["dirs"]:
		row.add_child(_dir_tile(d))
	_panel.add_child(row)
	_panel.add_child(_odds_box(_choice))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.add_child(spacer)
	var info := parts.research_info(campaign, _part, _choice)
	var go := CutButton.new()
	go.text = "INICIAR PESQUISA"
	go.disabled = not info["ok"]
	if not info["ok"]:
		go.text = {"slots": "SEM VAGA", "cash": "SEM CAIXA"}.get(info["reason"], "INDISPONÍVEL")
	go.pressed.connect(func() -> void:
		if parts.start_research(campaign, _part, _choice):
			campaign.save()
		_refresh())
	_panel.add_child(go)


func _note(icon_name: String, text: String) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.add_child(ScreenKit.icon(icon_name, 22, UiStyle.G_TEXT_2))
	var l := UiStyle.g_label(text, 13, UiStyle.G_TEXT_2)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size = Vector2(290, 0)
	h.add_child(l)
	return h


func _dir_tile(d: Dictionary) -> Button:
	var on: bool = d["id"] == _choice
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 172)
	var st := UiStyle.g_box(UiStyle.G_LIGHT if on else Color(0, 0, 0, 0.28), 14, 8, 8)
	st.set_border_width_all(3 if on else 0)
	st.border_color = Color(campaign.team()["color"])
	for s: String in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		b.add_theme_stylebox_override(s, st)
	var ink := UiStyle.G_INK if on else UiStyle.G_TEXT
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 6
	v.offset_right = -6
	v.offset_top = 6
	v.offset_bottom = -6
	v.add_theme_constant_override("separation", 3)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := UiStyle.g_label(d["name"], 12, ink, "black")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.clip_text = true
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(t)
	var fx := parts.promised_fx(campaign, _part, d["id"])
	for k: String in fx:
		var h := HBoxContainer.new()
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon_name: String = {"straight": "t_straight", "slow": "t_slow", "fast": "t_fast", "rel": "t_rel"}[k]
		h.add_child(ScreenKit.icon(icon_name, 16, ink))
		var sp := Control.new()
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(sp)
		var val := float(fx[k])
		var good := val > 0.0
		var c := (Color("#2a8a4c") if on else OK_COLOR) if good else (Color("#c0392b") if on else BAD_COLOR)
		h.add_child(UiStyle.g_label("%s %s" % ["▲" if good else "▼", _num(absf(val))], 12, c, "black"))
		v.add_child(h)
	var sep := HSeparator.new()
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(sep)
	var days := parts.research_days(campaign, _part, d["id"])
	var gp := campaign.race_after(days + parts.unit_days(campaign, _part))
	for m: Array in [["money", "%s mi" % _money(parts.research_cost(_part, d["id"]))], ["clock", "%d dias" % days], ["flag", _gp_short(gp) if not gp.is_empty() else "2027"]]:
		var h2 := HBoxContainer.new()
		h2.add_theme_constant_override("separation", 5)
		h2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h2.add_child(ScreenKit.icon(m[0], 13, ink))
		h2.add_child(UiStyle.g_label(m[1], 12, ink, "black"))
		v.add_child(h2)
	b.add_child(v)
	b.pressed.connect(func() -> void: _choice = d["id"]; _refresh())
	ScreenKit.press_feedback(b)
	return b


func _odds_box(dir_id: String) -> Control:
	var card := ScreenKit.g_card(Color(0, 0, 0, 0.28), 14, 12, 8)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)
	v.add_child(UiStyle.g_caption("Chance de o upgrade funcionar"))
	var who := HBoxContainer.new()
	who.add_theme_constant_override("separation", 8)
	var dept := String(CarParts.part(_part)["dept"])
	var role := "aero" if dept == "aero" else "designer"
	var person := campaign.personnel.staff_of(campaign, campaign.player_team, role)
	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.06), 12, 8, 4))
	var ph := HBoxContainer.new()
	ph.add_theme_constant_override("separation", 6)
	ph.add_child(UiStyle.g_label("%d" % int(person.get("skill", 60)), 18, UiStyle.G_TEXT, "black"))
	var nm := String(person.get("name", "vaga"))
	var pl := UiStyle.g_label("%s\n%s" % [nm.get_slice(" ", nm.get_slice_count(" ") - 1), {"aero": "aerodinâmica", "designer": "projetista"}[role]], 11, UiStyle.G_TEXT_2, "bold")
	ph.add_child(pl)
	pc.add_child(ph)
	who.add_child(pc)
	var fac := "wind" if dept == "aero" else "parts"
	var fc := PanelContainer.new()
	fc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fc.add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.06), 12, 8, 4))
	var fh := HBoxContainer.new()
	fh.add_theme_constant_override("separation", 6)
	fh.add_child(ScreenKit.icon("factory", 22, WARN))
	var fv := VBoxContainer.new()
	fv.add_theme_constant_override("separation", 0)
	fv.add_child(UiStyle.g_label("Túnel" if fac == "wind" else "Fábrica", 13, UiStyle.G_TEXT, "black"))
	var dots := HBoxContainer.new()
	dots.add_theme_constant_override("separation", 3)
	for i in 5:
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(9, 9)
		dot.color = WARN if i < campaign.dev.level_of(fac) else Color(1, 1, 1, 0.18)
		dots.add_child(dot)
	fv.add_child(dots)
	fh.add_child(fv)
	fc.add_child(fh)
	who.add_child(fc)
	v.add_child(who)
	var odds := parts.outcome_odds(campaign, _part, dir_id)
	var meter := OddsMeter.new()
	meter.odds = odds
	v.add_child(meter)
	var leg := HBoxContainer.new()
	for e: Array in [["check", OK_COLOR, "%d%% acerta" % roundi(float(odds["good"]) * 100.0)], ["minus", WARN, "%d%% menor" % roundi(float(odds["small"]) * 100.0)],
			["close", BAD_COLOR, "%d%% piora" % roundi(float(odds["bad"]) * 100.0)]]:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 3)
		h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(ScreenKit.icon(e[0], 13, e[1]))
		h.add_child(UiStyle.g_label(e[2], 11, e[1], "black"))
		leg.add_child(h)
	v.add_child(leg)
	return card


func _research_card(r: Dictionary) -> void:
	var d := CarParts.direction(_part, r["dir"])
	var card := ScreenKit.g_card(Color(0, 0, 0, 0.28), 14, 14, 12)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	v.add_child(UiStyle.g_caption("Correção em andamento" if int(r["fix"]) >= 0 else "Pesquisa em andamento"))
	v.add_child(UiStyle.g_label("Spec %s · %s" % [CarParts.letter(parts.spec_list(_part).size()) if int(r["fix"]) < 0 else parts.spec(_part, int(r["fix"]))["v"], d.get("name", "")], 18, UiStyle.G_TEXT, "black"))
	var bar := OddsMeter.new()  # barra de progresso: feito (verde) · falta (cinza)
	var done := 1.0 - float(r["days_left"]) / maxf(float(r["days_total"]), 1.0)
	bar.odds = {"good": done, "small": 0.0, "bad": 0.0}
	bar.rest = Color(1, 1, 1, 0.12)
	v.add_child(bar)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.add_child(ScreenKit.icon("clock", 16, UiStyle.G_TEXT_2))
	h.add_child(UiStyle.g_label("faltam %d dias" % int(r["days_left"]), 13, UiStyle.G_TEXT, "black"))
	v.add_child(h)
	v.add_child(UiStyle.g_label("O resultado real só aparece depois da primeira corrida com a peça.", 12, UiStyle.G_TEXT_2))
	(v.get_child(v.get_child_count() - 1) as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(card)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.add_child(spacer)
	var cancel := ScreenKit.glass_pill_button("Cancelar (devolve metade)")
	cancel.pressed.connect(func() -> void:
		parts.cancel_research(campaign, _part)
		campaign.save()
		_refresh())
	_panel.add_child(cancel)


# --- avisos -----------------------------------------------------------------------------------------

func _show_pending() -> void:
	PartsDialogs.show_pending(self, campaign, _refresh)


# --- textos -----------------------------------------------------------------------------------------

static func _money(v: float) -> String:
	return ("%.1f" % v).replace(".", ",") if absf(v) < 10.0 else "%d" % roundi(v)


static func _num(v: float) -> String:
	return ("%.1f" % v).replace(".", ",").trim_suffix(",0")


static func _gp_short(r: Dictionary) -> String:
	if r.is_empty():
		return ""
	var g := String(r.get("grand_prix", ""))
	for pre: String in ["GP da ", "GP do ", "GP de ", "GP dos ", "GP das ", "GP "]:
		if g.begins_with(pre):
			return g.trim_prefix(pre)
	return g


## Anel de vida da unidade (100 = nova) com a letra da especificação no meio.
class WearRing:
	extends Control
	var letter := "A"
	var life := 100.0
	var unknown := false  ## spec ainda não testada na pista
	var failed := false

	func _init() -> void:
		custom_minimum_size = Vector2(48, 48)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		draw_arc(c, 20, 0, TAU, 48, Color(0.5, 0.5, 0.5, 0.25), 5, true)
		var col := Color("#3c9d5d") if life > 60.0 else (Color("#ffd24a") if life > 30.0 else UiStyle.RED)
		draw_arc(c, 20, -PI / 2, -PI / 2 + TAU * clampf(life / 100.0, 0.0, 1.0), 48, col, 5, true)
		var f := UiStyle.G_BLACK
		var fs := UiStyle.fs(20)
		var txt := letter + ("?" if unknown else "")
		var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, c + Vector2(-w * 0.5, fs * 0.36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, BAD_COLOR if failed else UiStyle.G_TEXT)


## Barra de chances: acerta (verde) · ganho menor (amarelo) · piora (vermelho).
class OddsMeter:
	extends Control
	var odds := {"good": 0.6, "small": 0.3, "bad": 0.1}
	var rest := Color(0, 0, 0, 0)  ## cor do que sobra (barra de progresso)

	func _init() -> void:
		custom_minimum_size = Vector2(0, 10)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var x := 0.0
		for e: Array in [["good", Color("#3c9d5d")], ["small", Color("#ffd24a")], ["bad", UiStyle.RED]]:
			var w := size.x * float(odds[e[0]])
			draw_rect(Rect2(x, 0, w, size.y), e[1])
			x += w
		if x < size.x:
			draw_rect(Rect2(x, 0, size.x - x, size.y), rest)
