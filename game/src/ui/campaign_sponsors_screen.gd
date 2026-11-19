extends Control
## Patrocínios (mockup v42-4, 2026-11-19): à esquerda o patrocinador PRINCIPAL (com a vaga livre: as 3 ofertas para
## escolher); à direita as 3 vagas SECUNDÁRIAS (livre: "ver 3 ofertas") e o resumo do ano com o progresso das metas.
## Oferta = valor fixo por corrida + bônus por metas; não cumprir só perde o bônus. Marcas fictícias.

var campaign: Campaign
var sp: Sponsorship
var _layer: Control
var _stats: Dictionary = {}


func _ready() -> void:
	campaign = Session.campaign
	if campaign == null:
		Session.open_campaign.call_deferred()
		return
	sp = campaign.sponsors
	_stats = Sponsorship.season_stats(campaign)
	var page := ScreenKit.garage_page(self, campaign.player_team)
	(page["backdrop"] as GarageBackdrop).set_glow(UiStyle.SECTION["spons"], 0.16)
	_layer = page["layer"]
	var R := CampaignFrame.CONTENT
	var gap := 16.0
	var lw := 560.0
	var free_main := not sp.contracts.has("main")
	var main_h := R.size.y if free_main else 300.0
	_panel(Rect2(R.position, Vector2(lw, main_h)), _main())
	var rx := R.position.x + lw + gap
	var rw := R.size.x - lw - gap
	if free_main:  # escolhendo o principal: secundários em cima, resumo embaixo, à direita
		_panel(Rect2(Vector2(rx, R.position.y), Vector2(rw, 330)), _secondaries())
		_panel(Rect2(Vector2(rx, R.position.y + 330 + gap), Vector2(rw, R.size.y - 330 - gap)), _summary())
	else:  # principal assinado: resumo embaixo dele, secundários na coluna inteira
		_panel(Rect2(Vector2(R.position.x, R.position.y + main_h + gap), Vector2(lw, R.size.y - main_h - gap)), _summary())
		_panel(Rect2(Vector2(rx, R.position.y), Vector2(rw, R.size.y)), _secondaries())
	CampaignFrame.apply(_layer, "spons", true)


func _panel(r: Rect2, content: Control) -> void:
	var p := PanelContainer.new()
	p.clip_contents = true
	p.add_theme_stylebox_override("panel", ScreenKit.glass_box(18, 16, 14))
	p.position = r.position
	p.size = r.size
	p.custom_minimum_size = r.size
	p.add_child(content)
	_layer.add_child(p)


func _money(v: float, digits := 1) -> String:
	return "US$ %s mi" % ProjectNotes.num(v, digits)


func _scroll(inner: Control) -> DragScroll:
	var s := DragScroll.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_child(inner)
	return s


# --- principal --------------------------------------------------------------------------------------

func _main() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	var c: Dictionary = sp.contracts.get("main", {})
	if c.is_empty():
		v.add_child(UiStyle.g_caption("Patrocinador principal · escolha 1 de 3 ofertas"))
		var list := VBoxContainer.new()
		list.add_theme_constant_override("separation", 10)
		for o: Dictionary in sp.offers_for(campaign, "main"):
			list.add_child(_offer_card("main", o))
		var note := UiStyle.g_label("Metas mais ousadas pagam mais. Não cumprir = só perde o bônus. Sem escolha, o diretor comercial assina a oferta equilibrada antes da corrida.", 12, UiStyle.G_TEXT_3, "bold")
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(note)
		v.add_child(_scroll(list))
	else:
		v.add_child(UiStyle.g_caption("Patrocinador principal · %d" % campaign.season))
		v.add_child(_contract_card("main", c, true))
		var note := UiStyle.g_label("Os contratos valem até o fim do ano. Na temporada seguinte chegam 3 ofertas novas para cada vaga.", 12, UiStyle.G_TEXT_3, "bold")
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(note)
	return v


## Cartão de oferta: marca, tipo, fixo por corrida e as metas com o bônus; botão ASSINAR.
func _offer_card(slot_id: String, o: Dictionary) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_GLASS_TILE, 14, 14, 10))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", -3)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_child(UiStyle.g_caption("%s · %s" % [String(o["kind_name"]), String(o["category"])]))
	var bl := UiStyle.g_label(String(o["brand"]), 19, UiStyle.G_TEXT, "black")
	bl.clip_text = true
	names.add_child(bl)
	names.add_child(UiStyle.g_label("%s por corrida · %s no ano" % [_money(float(o["per_race"]), 2), _money(float(o["per_race"]) * Campaign.calendar().size(), 0)], 13, UiStyle.G_TEXT, "black"))
	h.add_child(names)
	var go := CutButton.new()
	go.text = "ASSINAR"
	go.custom_minimum_size = Vector2(120, 44)
	go.add_theme_font_size_override("font_size", UiStyle.fs(14))
	go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	go.pressed.connect(_on_accept.bind(slot_id, String(o["key"])))
	h.add_child(go)
	v.add_child(h)
	var goals: Array = o["goals"]
	if goals.is_empty():
		v.add_child(_goal_line("Sem metas", "—", UiStyle.G_TEXT_3))
	for g: Dictionary in goals:
		v.add_child(_goal_line(Sponsorship.goal_text(g), "+ %s" % _money(float(g["bonus"])), UiStyle.G_UP))
	return p


func _goal_line(text: String, value: String, col: Color) -> HBoxContainer:
	var h := HBoxContainer.new()
	var l := UiStyle.g_label(text, 13, UiStyle.G_TEXT_2, "bold")
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	h.add_child(UiStyle.g_label(value, 13, col, "black"))
	return h


## Contrato assinado: marca, fixo e metas com a barra de progresso.
func _contract_card(slot_id: String, c: Dictionary, big: bool) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_GLASS_TILE, 14, 14, 10))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	var h := HBoxContainer.new()
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", -3)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if slot_id != "main":
		names.add_child(UiStyle.g_caption(String(Sponsorship.slot(slot_id)["name"])))
	names.add_child(UiStyle.g_label(String(c["brand"]), 22 if big else 16, UiStyle.G_TEXT, "black"))
	h.add_child(names)
	h.add_child(UiStyle.g_label("%s / corrida" % _money(float(c["per_race"]), 2), 16 if big else 14, UiStyle.G_TEXT, "black"))
	v.add_child(h)
	for g: Dictionary in c.get("goals", []):
		v.add_child(_progress_row(g, true))
	if (c.get("goals", []) as Array).is_empty():
		v.add_child(UiStyle.g_label("Contrato garantido: sem metas.", 12, UiStyle.G_TEXT_3, "bold"))
	return p


## Meta com progresso: texto, barra e "6/10" (✔ quando paga).
func _progress_row(g: Dictionary, with_bonus: bool, brand := "") -> Control:
	var pr := Sponsorship.progress(campaign, g, _stats)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var txt := Sponsorship.goal_text(g) + ("  + %s" % _money(float(g["bonus"])) if with_bonus else "")
	if brand != "":
		txt = "%s · %s" % [brand, txt]
	var l := UiStyle.g_label(txt, 12, UiStyle.G_TEXT_2, "bold")
	l.custom_minimum_size = Vector2(330 if brand != "" else 250, 0)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.add_child(l)
	var bar := _Bar.new()
	bar.value = 1.0 if bool(g.get("paid", false)) else float(pr["frac"])
	bar.color = UiStyle.G_UP if bool(g.get("paid", false)) or float(pr["frac"]) >= 1.0 else UiStyle.G_DIRECTOR
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(bar)
	var right := "✔" if bool(g.get("paid", false)) else String(pr["text"])
	var rl := UiStyle.g_label(right, 12, UiStyle.G_UP if bool(g.get("paid", false)) else UiStyle.G_TEXT, "black")
	rl.custom_minimum_size = Vector2(64, 0)
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(rl)
	return h


# --- secundários --------------------------------------------------------------------------------------

func _secondaries() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.add_child(UiStyle.g_caption("Secundários · %d vagas" % (Sponsorship.slots().size() - 1)))
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	for z: Dictionary in Sponsorship.slots():
		if z["id"] == "main":
			continue
		var c: Dictionary = sp.contracts.get(z["id"], {})
		if c.is_empty():
			var b := ScreenKit.glass_pill_button("+ %s · vaga livre · ver 3 ofertas" % String(z["name"]))
			b.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MIN)
			b.pressed.connect(_open_offers.bind(String(z["id"])))
			list.add_child(b)
		else:
			list.add_child(_contract_card(z["id"], c, false))
	v.add_child(_scroll(list))
	return v


func _open_offers(slot_id: String) -> void:
	var sh := ScreenKit.sheet("Vaga %s · 3 ofertas" % String(Sponsorship.slot(slot_id)["name"]).to_lower(), 760)
	var body: VBoxContainer = sh["body"]
	for o: Dictionary in sp.offers_for(campaign, slot_id):
		body.add_child(_offer_card(slot_id, o))
	add_child(sh["root"])


# --- resumo do ano ----------------------------------------------------------------------------------------

func _summary() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.add_child(UiStyle.g_caption("No ano · progresso das metas"))
	var sm := sp.year_summary(campaign)
	v.add_child(_goal_line("Fixo que ainda entra (%d corridas)" % campaign.races_left_in_season(), _money(float(sm["guaranteed"])), UiStyle.G_TEXT))
	v.add_child(_goal_line("Bônus já ganho", _money(float(sm["secured"])), UiStyle.G_UP))
	v.add_child(_goal_line("Bônus em jogo", _money(float(sm["goal"])), UiStyle.G_TEXT))
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	for z: Dictionary in Sponsorship.slots():
		var c: Dictionary = sp.contracts.get(z["id"], {})
		for g: Dictionary in c.get("goals", []):
			if not bool(g.get("paid", false)):
				list.add_child(_progress_row(g, false, String(c["brand"])))
	if list.get_child_count() == 0:
		list.add_child(UiStyle.g_label("Nenhuma meta em aberto.", 12, UiStyle.G_TEXT_3, "bold"))
	v.add_child(_scroll(list))
	return v


func _on_accept(slot_id: String, key: String) -> void:
	var r := sp.accept(campaign, slot_id, key)
	if r["ok"]:
		campaign.save()
	Session.open_campaign_sponsors()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.open_campaign_hub()


class _Bar:
	extends Control
	var value := 0.5
	var color := Color.WHITE

	func _init() -> void:
		custom_minimum_size = Vector2(0, 8)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_style_box(UiStyle.g_box(Color(1, 1, 1, 0.1), 4, 0, 0), Rect2(Vector2.ZERO, size))
		if value > 0.0:
			draw_style_box(UiStyle.g_box(color, 4, 0, 0), Rect2(Vector2.ZERO, Vector2(size.x * clampf(value, 0.04, 1.0), size.y)))
