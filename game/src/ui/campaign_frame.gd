class_name CampaignFrame
extends RefCounted
## Moldura das telas da campanha (mockups v26 aprovados em 2026-11-09): barra fixa no topo (início, equipe, título da
## seção, dinheiro, diretoria, avisos e CONTINUAR) e barra de ícones à esquerda no lugar das 10 abas escritas.
## Telas antigas: o cabeçalho delas (y < 76) é absorvido pela barra do topo e o conteúdo é encaixado na área livre
## (escala ~0,98). Telas novas (mosaico, agenda, equipe, sede) usam a área livre direto: CONTENT.

const TOP_H := 76.0
const RAIL_W := 84.0
const CONTENT := Rect2(100, 92, 1164, 612)  ## área útil das telas novas (referência 1280×720)
const LEGACY_SCALE := 0.98  ## telas antigas: 44..1236 → 96..1264

## Itens da barra: [chave, ícone, rótulo curto]. A cor vem de UiStyle.SECTION.
const ITEMS := [["home", "home", "Início"], ["champ", "trophy", "Tabela"], ["drivers", "users", "Pilotos"], ["car", "car", "Carro"],
	["hq", "hq", "Sede"], ["cal", "cal", "Agenda"], ["staff", "person", "Pessoal"], ["spons", "hand", "Patroc."],
	["money", "money", "Caixa"], ["hist", "crown", "História"], ["board", "gavel", "Regras"]]
const FEEDER_ITEMS := ["home", "champ", "cal", "hist"]
## chaves antigas das telas (campaign_nav) → item da barra
const LEGACY := {"hub": "home", "standings": "champ", "history": "hist", "staff": "staff", "car": "car", "studio": "car",
	"factory": "hq", "sponsors": "spons", "finance": "money", "council": "board", "team": "drivers", "hq": "hq", "calendar": "cal"}
const TITLES := {"home": "INÍCIO", "champ": "TABELA", "drivers": "EQUIPE", "car": "CARRO", "hq": "SEDE", "cal": "AGENDA",
	"staff": "PESSOAL", "spons": "PATROCÍNIOS", "money": "CAIXA", "hist": "HISTÓRIA", "board": "REGRAS"}


## Monta a moldura sobre a tela que contém `layer`. native=false: tela antiga (absorve o cabeçalho e encaixa o conteúdo).
static func apply(layer: Control, active: String, native := false, title := "") -> Control:
	var screen := layer.get_parent() as Control
	var key: String = LEGACY.get(active, active)
	var extras: Array[Control] = []
	if not native:
		for c in layer.get_children():
			if not (c is Control) or (c as Control).anchor_top != 0.0 or (c as Control).offset_top >= 70.0:
				continue
			var ctl := c as Control
			if ctl.anchor_left >= 0.5:
				extras.append(ctl)  # botões da própria tela (ex.: Árvore de P&D) vão para a barra do topo
			else:
				if title == "":
					title = _title_in(ctl)
				ctl.visible = false  # escondido (não liberado): a tela pode ainda atualizar algum rótulo dele
		for e in extras:
			layer.remove_child(e)
			_drop_duplicates(e)
		layer.scale = Vector2(LEGACY_SCALE, LEGACY_SCALE)
		var tx := CONTENT.position.x - 4.0 - 44.0 * LEGACY_SCALE
		var ty := 88.0 - 88.0 * LEGACY_SCALE
		layer.offset_left = tx
		layer.offset_right = tx
		layer.offset_top = ty
		layer.offset_bottom = ty
	if title == "":
		title = TITLES.get(key, "")
	var frame := Control.new()
	frame.name = "CampaignFrame"
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(frame)
	screen.move_child(frame, layer.get_index())  # abaixo do conteúdo: folhas e avisos da tela cobrem a moldura
	frame.add_child(_rail(key))
	frame.add_child(_top(key, title, extras))
	return frame


## Tira dos botões da tela o que a barra do topo já mostra (caixa, diretoria, notícias).
static func _drop_duplicates(n: Control) -> void:
	for c in n.get_children():
		if c is Control and _is_duplicate(c as Control):
			(c as Control).visible = false


static func _is_duplicate(c: Control) -> bool:
	if c.has_meta("frame_dup") or (c is Button and (c as Button).text.begins_with("NOTÍCIAS")):
		return true
	for l in c.find_children("*", "Label", true, false):
		var t := (l as Label).text.strip_edges()
		if t.begins_with("US$") or t.to_upper() in ["CAIXA", "DIRETORIA"]:
			return true
	return false


static func _title_in(n: Node) -> String:
	var best := ""
	var best_size := 0
	for c in n.find_children("*", "Label", true, false):
		var l := c as Label
		var s := l.get_theme_font_size("font_size")
		if s > best_size and l.text.strip_edges() != "":
			best_size = s
			best = l.text
	return best.to_upper()


static func section_color(key: String) -> Color:
	return UiStyle.SECTION.get(key, UiStyle.G_TEXT)


# --- barra do topo ---------------------------------------------------------------------------------------------

static func _top(key: String, title: String, extras: Array[Control]) -> Control:
	var c: Campaign = Session.campaign
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_FRAME, 0, 18, 0))
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.custom_minimum_size = Vector2(0, TOP_H)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UiStyle.SP_M)
	h.alignment = BoxContainer.ALIGNMENT_BEGIN
	bar.add_child(h)
	var home := ScreenKit.round_button("home", 48, "Menu")
	home.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	home.pressed.connect(Session.go_to_title)
	h.add_child(home)
	if c != null:
		var emb := TeamEmblems.make_rect(c.player_team, 44)
		emb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(emb)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", -4)
	tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if c != null:
		tv.add_child(UiStyle.g_caption("%s · %s" % [String(c.team()["name"]), c.date_text()]))
	var tl := UiStyle.g_label(title, 26, section_color(key) if key != "home" else UiStyle.G_TEXT, "black")
	tv.add_child(tl)
	h.add_child(tv)
	# botões da própria tela: área que encolhe (corta) para nunca empurrar o título nem o CONTINUAR para fora
	var slot := Control.new()
	slot.clip_contents = true
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.custom_minimum_size = Vector2(0, TOP_H)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UiStyle.SP_S)
	row.alignment = BoxContainer.ALIGNMENT_END
	row.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	row.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	slot.add_child(row)
	for e in extras:
		e.set_anchors_preset(Control.PRESET_TOP_LEFT)
		e.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(e)
	h.add_child(slot)
	if c != null:
		h.add_child(_pill([ScreenKit.icon("money", 22, section_color("money")), UiStyle.g_label("%d mi" % int(c.budget_musd), 17, UiStyle.G_TEXT, "black")]))
		var trust := ProgressBar.new()
		trust.show_percentage = false
		trust.max_value = 100.0
		trust.value = c.trust
		trust.custom_minimum_size = Vector2(54, 8)
		trust.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var tcol := UiStyle.G_UP if c.trust >= 40.0 else UiStyle.G_DOWN
		trust.add_theme_stylebox_override("background", UiStyle.g_box(Color(1, 1, 1, 0.12), 4, 0, 0))
		trust.add_theme_stylebox_override("fill", UiStyle.g_box(tcol, 4, 0, 0))
		var tp := _pill([ScreenKit.icon("smile", 22, tcol), trust])
		tp.tooltip_text = "Diretoria: " + c.trust_label()
		h.add_child(tp)
		var bell := ScreenKit.round_button("bell", 48, "Notícias")
		bell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bell.pressed.connect(func() -> void:
			Session.campaign_open_news = true
			Session.open_campaign_hub())
		var unseen := c.events.unseen.size() + c.personnel.transfers.decisions.size()
		if unseen > 0:
			var dot := PanelContainer.new()
			dot.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.RED, 10, 5, 0))
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			dot.add_child(UiStyle.g_label(str(unseen), 12, Color.WHITE, "black"))
			dot.position = Vector2(30, -2)
			bell.add_child(dot)
		h.add_child(bell)
	var go := CutButton.new()
	go.text = "CONTINUAR"
	go.custom_minimum_size = Vector2(168, 52)
	go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	go.add_theme_font_size_override("font_size", UiStyle.fs(18))
	go.pressed.connect(continue_campaign)
	h.add_child(go)
	return bar


static func _pill(items: Array) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_SURFACE, 23, 14, 0))
	p.custom_minimum_size = Vector2(0, 46)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	for it: Control in items:
		it.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(it)
	p.add_child(h)
	return p


## Ação principal da campanha: avança até o próximo GP (com a preparação recomendada das peças) ou joga o fim de semana.
static func continue_campaign() -> void:
	var c: Campaign = Session.campaign
	if c == null:
		return
	if c.is_feeder():
		Session.open_campaign_hub()
		return
	if c.season_over() or c.state != "active":
		Session.open_campaign_report()
		return
	if not c.personnel.transfers.decisions.is_empty():  # decisão de mercado aberta: a campanha para até você decidir
		Session.open_campaign_hub()
		return
	var r := c.next_round()
	if not r.is_empty():
		c.my_parts().auto_prepare(Campaign.track_profile(r["id"]))
		c.refresh_rating()
	if c.event_ready():
		Session.play_campaign_round()
		return
	c.advance_to_event()
	c.save()
	Session.open_campaign_hub()


# --- barra de ícones -------------------------------------------------------------------------------------------

static func _rail(active: String) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_FRAME, 0, 6, 4))
	p.position = Vector2(0, TOP_H)
	p.size = Vector2(RAIL_W, 720 - TOP_H)
	p.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	p.offset_top = TOP_H
	p.offset_right = RAIL_W
	var scroll := DragScroll.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	p.add_child(scroll)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)
	var feeder := Session.campaign != null and Session.campaign.is_feeder()
	for it: Array in ITEMS:
		var k: String = it[0]
		if feeder and not FEEDER_ITEMS.has(k):
			continue
		v.add_child(_rail_item(k, it[1], it[2], k == active))
	return p


static func _rail_item(key: String, icon_name: String, label: String, on: bool) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(72, 55)
	b.tooltip_text = label
	for s: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		b.add_theme_stylebox_override(s, UiStyle.g_box(UiStyle.G_SURFACE_HOVER if on else (UiStyle.G_SURFACE if s.begins_with("pressed") else Color(0, 0, 0, 0)), 14, 0, 0))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic := ScreenKit.icon(icon_name, 22, section_color(key) if key != "home" else UiStyle.G_TEXT)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ic)
	var l := UiStyle.g_label(label, 12, UiStyle.G_TEXT if on else UiStyle.G_TEXT_2, "black" if on else "bold")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	b.add_child(v)
	if not on:
		b.pressed.connect(open_section.bind(key))
	ScreenKit.press_feedback(b)
	return b


static func open_section(key: String) -> void:
	match key:
		"home":
			Session.open_campaign_hub()
		"champ":
			Session.open_campaign_standings()
		"drivers":
			Session.open_campaign_team()
		"car":
			Session.open_campaign_car()
		"hq":
			Session.open_campaign_hq()
		"cal":
			Session.open_campaign_calendar()
		"staff":
			Session.open_campaign_staff()
		"spons":
			Session.open_campaign_sponsors()
		"money":
			Session.open_campaign_finance()
		"hist":
			Session.open_campaign_history()
		"board":
			Session.open_campaign_council()
