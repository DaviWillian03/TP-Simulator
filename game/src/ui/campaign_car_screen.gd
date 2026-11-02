extends Control
## Carro — árvore de P&D da campanha (mockups v9-1 e v9-2, inspirada no F1 2017).
## Esquerda: os 4 departamentos e a legenda. Centro: a árvore do departamento. Direita: categorias,
## o nó escolhido (custo, prazo, chance de acerto) e os projetos em andamento. Abas "carro atual ×
## carro do ano seguinte" (mesmo dinheiro e mesmos projetos) e modo Essencial × Avançado.

var campaign: Campaign
var dev: CarDevelopment
var _car := "cur"
var _dept := "aero"
var _selected := ""
var _layer: Control
var _tree: RdTreeView
var _rail: VBoxContainer
var _right: VBoxContainer
var _cash: Label
var _slots_chip: Label
var _toasts: ToastFeed


func _ready() -> void:
	campaign = Session.campaign
	if campaign == null:
		Session.open_campaign.call_deferred()
		return
	dev = campaign.dev
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
	titles.add_child(UiStyle.g_label("CARRO · DESENVOLVIMENTO", 26, UiStyle.G_TEXT, "black"))
	head.add_child(titles)
	var tabs := ScreenKit.segmented([["cur", "Carro %d" % campaign.season], ["next", "Carro %d" % (campaign.season + 1)]], _car, _on_car_tab)
	tabs.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(tabs)
	ScreenKit.place(head, _layer, Control.PRESET_TOP_LEFT, Vector2(44, 20))

	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", UiStyle.SP_M)
	var c1 := _chip("Caixa")
	_cash = c1.get_meta("value")
	chips.add_child(c1)
	var c2 := _chip("Projetos")
	_slots_chip = c2.get_meta("value")
	chips.add_child(c2)
	ScreenKit.place(chips, _layer, Control.PRESET_TOP_RIGHT, Vector2(-44, 26))

	ScreenKit.campaign_nav(_layer, "car")
	var mode := ScreenKit.segmented([["essential", "Essencial"], ["advanced", "Avançado"]], campaign.detail, _on_mode)
	ScreenKit.place(mode, _layer, Control.PRESET_TOP_RIGHT, Vector2(-44, 88))

	_rail = VBoxContainer.new()
	_rail.add_theme_constant_override("separation", 8)
	ScreenKit.place(_rail, _layer, Control.PRESET_TOP_LEFT, Vector2(44, 150), Vector2(196, 0))
	_legend()

	_tree = RdTreeView.new()
	_tree.dev = dev
	_tree.camp = campaign
	_tree.custom_minimum_size = Vector2(600, 560)
	ScreenKit.place(_tree, _layer, Control.PRESET_TOP_LEFT, Vector2(250, 140), Vector2(600, 560))
	_tree.node_pressed.connect(_on_node)

	_right = VBoxContainer.new()
	_right.add_theme_constant_override("separation", 6)
	ScreenKit.place(_right, _layer, Control.PRESET_TOP_RIGHT, Vector2(-44, 146), Vector2(384, 0))

	_toasts = ToastFeed.new()
	_toasts.custom_minimum_size = Vector2(380, 0)
	ScreenKit.place(_toasts, _layer, Control.PRESET_TOP_LEFT, Vector2(262, 146), Vector2(380, 0))
	_refresh()


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


func _legend() -> Control:
	var card := ScreenKit.g_card(Color(1, 1, 1, 0.05), 18, 14, 10)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	card.add_child(v)
	v.add_child(UiStyle.g_caption("Legenda"))
	for row: Array in [["Menor", "m"], ["Importante", "i"], ["Definitiva", "d"]]:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		var icon := LegendIcon.new()
		icon.kind = row[1]
		h.add_child(icon)
		h.add_child(UiStyle.g_label(row[0], 14, Color("#c3c9d3")))
		v.add_child(h)
	ScreenKit.place(card, _layer, Control.PRESET_BOTTOM_LEFT, Vector2(44, -26), Vector2(196, 0))
	return card


# --- atualização ----------------------------------------------------------------------------

func _refresh() -> void:
	_cash.text = "US$ %d mi" % int(campaign.budget_musd)
	_slots_chip.text = "%d / %d" % [dev.projects.size(), dev.slots()]
	_build_rail()
	_tree.dev = dev
	_tree.show_department(_car, _dept)
	_tree.select(_selected)
	_build_right()


func _build_rail() -> void:
	for c in _rail.get_children():
		_rail.remove_child(c)
		c.queue_free()
	for id: String in CarDevelopment.DEPT_ORDER:
		var dep := CarDevelopment.department(id)
		var on := id == _dept
		var locked := not dev.dept_available(id, campaign)
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 84)
		for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(s, UiStyle.g_box(UiStyle.G_LIGHT if on else UiStyle.G_SURFACE_HOVER, 18, 14, 0))
		ScreenKit.press_feedback(b)
		var h := HBoxContainer.new()
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_theme_constant_override("separation", 12)
		b.add_child(h)
		h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		h.offset_left = 14
		var total := 0
		var count := 0
		for nid: String in CarDevelopment.all_node_ids(id):
			total += 1
			if dev.is_done(_car, nid):
				count += 1
		var ring := Donut.new()
		ring.custom_minimum_size = Vector2(44, 44)
		ring.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.frac = float(count) / maxf(total, 1)
		ring.color = Color(dep["color"])
		ring.track = Color(0.47, 0.5, 0.58, 0.35)
		ring.text = "" if locked else str(roundi(100.0 * ring.frac))
		ring.text_color = UiStyle.G_INK if on else UiStyle.G_TEXT
		ring.locked = locked
		h.add_child(ring)
		var names := VBoxContainer.new()
		names.alignment = BoxContainer.ALIGNMENT_CENTER
		names.mouse_filter = Control.MOUSE_FILTER_IGNORE
		names.add_theme_constant_override("separation", -2)
		var n := UiStyle.g_label(String(dep["name"]), 17, UiStyle.G_INK if on else (UiStyle.G_TEXT_OFF if locked else UiStyle.G_TEXT), "black")
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sub := UiStyle.g_label("Motor do fornecedor" if locked else "%d / %d nós" % [count, total], 12, UiStyle.G_INK_2 if on else UiStyle.G_TEXT_2)
		sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
		names.add_child(n)
		names.add_child(sub)
		h.add_child(names)
		b.pressed.connect(_on_dept.bind(id))
		_rail.add_child(b)


func _build_right() -> void:
	for c in _right.get_children():
		_right.remove_child(c)
		c.queue_free()
	var dep := CarDevelopment.department(_dept)
	var title := String(dep["name"]).to_upper() + (" · %d" % (campaign.season + 1) if _car == "next" else "")
	_right.add_child(UiStyle.g_label(title, 30, UiStyle.G_TEXT, "black"))
	var desc := UiStyle.g_label(String(dep["desc"]) + ("\nMesmo dinheiro e mesmos projetos do carro atual." if _car == "next" else ""), 13, UiStyle.G_TEXT_2)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_right.add_child(desc)
	for a in dep["arms"].size():
		var arm: Dictionary = dep["arms"][a]
		var total: int = arm["nodes"].size()
		var count := 0
		for i in total:
			if dev.is_done(_car, CarDevelopment.node_id(_dept, a, i)):
				count += 1
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 32)
		row.add_theme_constant_override("separation", 10)
		var ring := Donut.new()
		ring.custom_minimum_size = Vector2(26, 26)
		ring.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ring.frac = float(count) / maxf(total, 1)
		ring.color = RdTreeView.ARM_COLORS[a]
		ring.track = Color(0.47, 0.5, 0.58, 0.35)
		row.add_child(ring)
		var nm := UiStyle.g_label(String(arm["name"]), 15, UiStyle.G_TEXT, "bold")
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(nm)
		row.add_child(UiStyle.g_label("%d/%d" % [count, total], 13, UiStyle.G_TEXT_2))
		_right.add_child(row)
	if _selected != "":
		_right.add_child(_node_card())
	elif campaign.detail == "essential":
		_right.add_child(_director_card())
	else:
		_right.add_child(_hint_card())
	_right.add_child(UiStyle.g_caption("Projetos em andamento · %d de %d" % [dev.projects.size(), dev.slots()]))
	_right.add_child(_slots_row())


func _light_card() -> PanelContainer:
	var card := PanelContainer.new()
	var st := UiStyle.g_box(UiStyle.G_LIGHT, 20, 16, 12)
	st.content_margin_left = 22
	st.border_width_left = 7
	st.border_color = UiStyle.RED
	card.add_theme_stylebox_override("panel", st)
	return card


func _fact(value: String, caption: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", UiStyle.g_box(Color("#e3e6eb"), 12, 10, 6))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -2)
	v.add_child(UiStyle.g_label(value, 17, UiStyle.G_INK, "black"))
	v.add_child(UiStyle.g_label(caption, 12, UiStyle.G_INK_2))
	p.add_child(v)
	return p


func _node_card() -> Control:
	var info := CarDevelopment.node_info(_selected)
	var pi := dev.project_info(_car, _selected, campaign)
	var card := _light_card()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	card.add_child(v)
	var kind_name: String = info["kind"]["name"]
	v.add_child(UiStyle.g_caption("Nó %s · %s" % [kind_name.to_lower(), info["arm_name"]], UiStyle.G_INK_2))
	v.add_child(UiStyle.g_label(String(info["node"]["n"]), 21, UiStyle.G_INK, "black"))
	var fx := UiStyle.g_label(CarDevelopment.node_effect_text(info), 14, UiStyle.G_INK_2)
	fx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(fx)
	var state := dev.node_state(_car, _selected, campaign)
	if state == "done":
		var res: String = (dev.done[_car] as Dictionary).get(_selected, "full")
		v.add_child(UiStyle.g_label("Concluído" + (" · resultado parcial (metade do efeito)" if res == "partial" else " · resultado total"), 15, Color("#2a6b3f"), "black"))
		return card
	var facts := HBoxContainer.new()
	facts.add_theme_constant_override("separation", 8)
	if state == "now":
		var pr := dev.project_of(_car, _selected)
		facts.add_child(_fact("%d dias" % int(pr["days_left"]), "faltam"))
		facts.add_child(_fact("US$ %.1f mi" % float(pr["cost"]), "já pago"))
	else:
		facts.add_child(_fact("US$ %.1f mi" % float(pi["cost"]), "custo"))
		facts.add_child(_fact("%d dias" % int(pi["days"]), "prazo"))
		facts.add_child(_fact("%d%%" % roundi(float(pi["success"]) * 100.0), "chance de acerto"))
	v.add_child(facts)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var go := CutButton.new()
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.custom_minimum_size = Vector2(0, 48)
	go.add_theme_font_size_override("font_size", 15)
	if state == "now":
		go.text = "CANCELAR PROJETO"
		go.pressed.connect(_on_cancel.bind(_selected))
	else:
		go.text = "INICIAR PROJETO"
		go.disabled = not pi["ok"]
		if not pi["ok"]:
			go.text = {"cash": "SEM CAIXA", "slots": "SEM VAGA DE PROJETO", "locked": "BLOQUEADO", "engine": "MOTOR DO FORNECEDOR"}.get(pi["reason"], "INDISPONÍVEL")
		go.pressed.connect(_on_start.bind(_selected))
	row.add_child(go)
	var sug := Button.new()
	sug.text = "Sugerir"
	sug.focus_mode = Control.FOCUS_NONE
	sug.custom_minimum_size = Vector2(96, 48)
	for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
		sug.add_theme_stylebox_override(s, UiStyle.g_box(Color("#e3e6eb"), 14, 10, 0))
	for k: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		sug.add_theme_color_override(k, UiStyle.G_INK)
	sug.add_theme_font_size_override("font_size", 15)
	sug.pressed.connect(_on_suggest)
	ScreenKit.press_feedback(sug)
	row.add_child(sug)
	v.add_child(row)
	return card


func _hint_card() -> Control:
	var card := _light_card()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)
	v.add_child(UiStyle.g_label("Escolha um nó", 21, UiStyle.G_INK, "black"))
	var t := UiStyle.g_label("Toque num nó aberto da árvore para ver custo, prazo e chance de acerto. Cada nó pago vira dias de projeto na fábrica.", 14, UiStyle.G_INK_2)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var sug := ScreenKit.light_button("SUGERIR UM NÓ")
	sug.custom_minimum_size = Vector2(0, 48)
	sug.add_theme_font_size_override("font_size", 15)
	sug.pressed.connect(_on_suggest)
	v.add_child(sug)
	return card


func _director_card() -> Control:
	var card := _light_card()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)
	v.add_child(UiStyle.g_caption("Diretor técnico decide", UiStyle.G_INK_2))
	v.add_child(UiStyle.g_label("Foco do desenvolvimento", 21, UiStyle.G_INK, "black"))
	var t := UiStyle.g_label("O diretor escolhe e paga os projetos dentro do teto de gasto. Toque num nó para assumir.", 14, UiStyle.G_INK_2)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var focus := HBoxContainer.new()
	focus.add_theme_constant_override("separation", 6)
	for o: Array in [["balanced", "Equilibrado"], ["aero", "Aero"], ["chassis", "Chassi"], ["durability", "Durab."]]:
		var b := Button.new()
		b.text = o[1]
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MIN)
		var on: bool = dev.focus == o[0]
		for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(s, UiStyle.g_box(UiStyle.G_INK if on else Color("#e3e6eb"), 12, 6, 0))
		for k: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(k, Color.WHITE if on else UiStyle.G_INK)
		b.add_theme_font_size_override("font_size", 13)
		b.pressed.connect(_on_focus.bind(o[0]))
		ScreenKit.press_feedback(b)
		focus.add_child(b)
	v.add_child(focus)
	var facts := HBoxContainer.new()
	facts.add_theme_constant_override("separation", 8)
	facts.add_child(_fact("US$ %d mi" % int(CarDevelopment.AUTO_CAP_MUSD), "teto por mês"))
	facts.add_child(_fact("%d%%" % roundi(CarDevelopment.AUTO_NEXT_SHARE * 100.0), "para o carro %d" % (campaign.season + 1)))
	facts.add_child(_fact("Auto", "fila de projetos"))
	v.add_child(facts)
	return card


func _slots_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var shown := 0
	for p: Dictionary in dev.projects:
		row.add_child(_slot_button(p))
		shown += 1
	while shown < mini(dev.slots(), 3):
		var free := PanelContainer.new()
		free.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		free.custom_minimum_size = Vector2(0, 62)
		var st := UiStyle.g_box(Color(0, 0, 0, 0), 14, 8, 6)
		st.set_border_width_all(2)
		st.border_color = Color(1, 1, 1, 0.18)
		free.add_theme_stylebox_override("panel", st)
		var l := UiStyle.g_label("+ Livre", 13, UiStyle.G_TEXT_3, "bold")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		free.add_child(l)
		row.add_child(free)
		shown += 1
	if dev.slots() > 3:
		row.add_child(UiStyle.g_label("+%d" % (dev.slots() - 3), 14, UiStyle.G_TEXT_2, "black"))
	return row


func _slot_button(p: Dictionary) -> Button:
	var info := CarDevelopment.node_info(p["id"])
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 62)
	for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(s, UiStyle.g_box(UiStyle.G_SURFACE_HOVER, 14, 8, 6))
	ScreenKit.press_feedback(b)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", -1)
	b.add_child(v)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 8
	v.offset_right = -8
	v.offset_top = 5
	var tag := "'%s " % str(campaign.season + 1).right(2) if p["car"] == "next" else ""
	var n := UiStyle.g_label(tag + String(info["node"]["n"]), 12, UiStyle.G_TEXT, "black")
	n.clip_text = true
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(n)
	var sub := UiStyle.g_label("%s · %d dias" % [CarDevelopment.department(info["dept"])["name"], int(p["days_left"])], 11, UiStyle.G_TEXT_2)
	sub.clip_text = true
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(sub)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.value = 100.0 * (1.0 - float(p["days_left"]) / maxf(float(p["days_total"]), 1.0))
	bar.custom_minimum_size = Vector2(0, 6)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", UiStyle.g_box(Color(1, 1, 1, 0.12), 3, 0, 0))
	bar.add_theme_stylebox_override("fill", UiStyle.g_box(RdTreeView.ARM_COLORS[int(info["arm"])], 3, 0, 0))
	v.add_child(bar)
	b.pressed.connect(_on_slot.bind(p))
	return b


# --- ações ----------------------------------------------------------------------------------

func _on_car_tab(value: String) -> void:
	_car = value
	_selected = ""
	_refresh()


func _on_dept(id: String) -> void:
	_dept = id
	_selected = ""
	_refresh()


func _on_node(id: String) -> void:
	_selected = id
	_build_right()


func _on_slot(p: Dictionary) -> void:
	_car = p["car"]
	_dept = String(p["id"]).get_slice(".", 0)
	_selected = p["id"]
	_refresh()


func _on_mode(value: String) -> void:
	campaign.detail = value
	if value == "essential":
		dev.tick(campaign, 0)  # o diretor já preenche as vagas livres
	campaign.save()
	_selected = ""
	_refresh()


func _on_focus(value: String) -> void:
	dev.focus = value
	campaign.save()
	_build_right()


func _on_start(id: String) -> void:
	if dev.start_project(campaign, _car, id):
		campaign.save()
		_toasts.push("Projeto iniciado: %s" % CarDevelopment.node_info(id)["node"]["n"], "hot")
	_refresh()


func _on_cancel(id: String) -> void:
	if dev.cancel_project(campaign, _car, id):
		campaign.save()
		_toasts.push("Projeto cancelado (metade do dinheiro devolvida).")
	_refresh()


func _on_suggest() -> void:
	var rec := dev.recommended(_car, campaign, _dept)
	if rec.is_empty():
		rec = dev.recommended(_car, campaign)
	if rec.is_empty():
		_toasts.push("Nada novo para sugerir agora.")
		return
	_selected = rec[0]
	_dept = String(rec[0]).get_slice(".", 0)
	_toasts.push("Sugestão do diretor técnico.")
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.open_campaign_hub()


# --- peças gráficas -----------------------------------------------------------------------------

## Anel de progresso (0..1) com texto opcional ou cadeado.
class Donut:
	extends Control

	var frac := 0.0
	var color := Color.WHITE
	var track := Color(1, 1, 1, 0.2)
	var text := ""
	var text_color := Color.WHITE
	var locked := false

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0 - 3.0
		draw_arc(c, r, 0.0, TAU, 40, track, 4.0, true)
		if frac > 0.0 and not locked:
			draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * clampf(frac, 0.0, 1.0), 40, color, 4.0, true)
		if locked:
			draw_rect(Rect2(c + Vector2(-6, -2), Vector2(12, 9)), UiStyle.G_TEXT_2)
			draw_arc(c + Vector2(0, -2), 4.0, PI, TAU, 10, UiStyle.G_TEXT_2, 2.0, true)
		elif text != "":
			draw_string(UiStyle.G_BLACK, Vector2(0, c.y + 4.0), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 11, text_color)


## Ícones da legenda (hexágono, quadrado, quadrado grande).
class LegendIcon:
	extends Control

	var kind := "m"

	func _init() -> void:
		custom_minimum_size = Vector2(24, 24)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER

	func _draw() -> void:
		var c := size / 2.0
		var col := Color("#eef0f3")
		if kind == "m":
			var pts := PackedVector2Array()
			for k in 7:
				pts.append(c + Vector2(10.0, 0.0).rotated(deg_to_rad(60.0 * k + 30.0)))
			draw_polyline(pts, col, 2.0, true)
		else:
			var half := 8.0 if kind == "i" else 10.0
			var st := StyleBoxFlat.new()
			st.bg_color = Color(0, 0, 0, 0)
			st.set_corner_radius_all(3)
			st.border_color = col
			st.set_border_width_all(2)
			draw_style_box(st, Rect2(c - Vector2(half, half), Vector2(half, half) * 2.0))
			if kind == "d":
				st.set_border_width_all(1)
				draw_style_box(st, Rect2(c - Vector2(5, 5), Vector2(10, 10)))
