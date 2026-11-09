extends Control
## Agenda da campanha em cartões verticais (mockup v26-6): arte 3D da pista, bandeira, data, pneus do fim de semana e
## a afinidade do carro com a pista. À esquerda, as corridas já feitas com o melhor resultado da equipe.
## O cartão do próximo GP tem o botão IR (mesma ação do CONTINUAR).

const CARD_W := 196.0
const GAP := 14.0

var campaign: Campaign
var _row: HBoxContainer


func _ready() -> void:
	campaign = Session.campaign
	if campaign == null:
		Session.open_campaign.call_deferred()
		return
	var page := ScreenKit.garage_page(self, campaign.player_team)
	var layer: Control = page["layer"]
	var R := CampaignFrame.CONTENT
	var cal := Campaign.calendar()
	# feitas
	var done := VBoxContainer.new()
	done.add_theme_constant_override("separation", 10)
	var dh := HBoxContainer.new()
	dh.add_theme_constant_override("separation", 6)
	dh.add_child(ScreenKit.icon("check", 18, UiStyle.G_UP))
	dh.add_child(UiStyle.g_caption("%d feitas" % mini(campaign.round, cal.size())))
	done.add_child(dh)
	for i in range(maxi(0, campaign.round - 6), mini(campaign.round, cal.size())):
		done.add_child(_done_row(cal[i], i))
	ScreenKit.place(done, layer, Control.PRESET_TOP_LEFT, Vector2(R.position.x, R.position.y + 10), Vector2(96, 0))
	# próximas, em cartões que deslizam para o lado
	var scroll := DragScroll.new()
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", int(GAP))
	scroll.add_child(_row)
	ScreenKit.place(scroll, layer, Control.PRESET_TOP_LEFT, Vector2(R.position.x + 108, R.position.y - 4), Vector2(R.size.x - 108, R.size.y + 8))
	for i in range(campaign.round, cal.size()):
		_row.add_child(_card(cal[i], i == campaign.round))
	CampaignFrame.apply(layer, "calendar", true)


func _done_row(rd: Dictionary, i: int) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var art := TextureRect.new()
	art.texture = CampaignHub.track_art(rd["id"])
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.custom_minimum_size = Vector2(52, 34)
	h.add_child(art)
	var best := 0
	for hrow: Dictionary in campaign.history:
		if int(hrow.get("round", -1)) == i + 1 or (int(hrow.get("round", -1)) == i and not hrow.has("circuit")) or String(hrow.get("circuit", "")) == String(rd["id"]):
			var res: Array = hrow.get("results", [])
			for id: String in campaign.team_driver_ids(campaign.player_team):
				var p := res.find(id)
				if p >= 0 and (best == 0 or p + 1 < best):
					best = p + 1
	var l := UiStyle.g_label("P%d" % best if best > 0 else "—", 18, Color("#F5C542") if best == 1 else UiStyle.G_TEXT, "black")
	h.add_child(l)
	return h


func _card(rd: Dictionary, is_next: bool) -> Control:
	var circuit := GameData.circuit(rd["id"])
	var card := PanelContainer.new()
	card.clip_contents = true
	card.custom_minimum_size = Vector2(CARD_W, CampaignFrame.CONTENT.size.y - 6)
	var box := UiStyle.g_box(Color("#171a21"), 22, 0, 0)
	if is_next:
		box.border_color = Color.WHITE
		box.set_border_width_all(4)
	card.add_theme_stylebox_override("panel", box)
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(root)
	var h := card.custom_minimum_size.y
	var art := TextureRect.new()
	art.texture = CampaignHub.track_art(rd["id"])
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.position = Vector2.ZERO
	art.size = Vector2(CARD_W, h * 0.52)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(art)
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(0.09, 0.1, 0.13, 0.0), Color(0.09, 0.1, 0.13, 1.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_to = Vector2(0, 1)
	var fade := TextureRect.new()
	fade.texture = gt
	fade.stretch_mode = TextureRect.STRETCH_SCALE
	fade.position = Vector2(0, h * 0.32)
	fade.size = Vector2(CARD_W, h * 0.2 + 2)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade)
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 6)
	chips.position = Vector2(12, 12)
	chips.add_child(_chip(str(int(rd["round"])), Color(0.06, 0.07, 0.09, 0.82)))
	if campaign.regs.is_sprint(rd["id"]):
		chips.add_child(_chip("SPRINT", UiStyle.SECTION["staff"]))
	if bool(rd.get("night", false)):
		chips.add_child(_chip("NOITE", Color(0.06, 0.07, 0.09, 0.82)))
	root.add_child(chips)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.position = Vector2(14, h * 0.47)
	v.size = Vector2(CARD_W - 28, h * 0.5)
	v.add_child(CampaignHub.flag_rect(String(circuit.get("country_code", "")), 28))
	var short := CampaignHub.gp_short(String(rd["grand_prix"])).to_upper()
	var nm := UiStyle.g_label(short, 21 if short.length() <= 10 else 17, UiStyle.G_TEXT, "black")
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.custom_minimum_size = Vector2(CARD_W - 28, 0)
	v.add_child(nm)
	var dh := HBoxContainer.new()
	dh.add_theme_constant_override("separation", 6)
	dh.add_child(ScreenKit.icon("cal", 16, UiStyle.G_TEXT_2))
	dh.add_child(UiStyle.g_label(campaign.date_text(Campaign._day_of(String(rd["date"]))).get_slice(", ", 1).to_lower(), 14, UiStyle.G_TEXT_2, "bold"))
	v.add_child(dh)
	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", 6)
	var tyres: Dictionary = GameData.tyres()["compounds"]
	for k: String in ["soft", "medium", "hard"]:
		var tb := TyreBadge.new()
		tb.custom_minimum_size = Vector2(28, 28)
		tb.set_compound(String(tyres[k]["letter"]), Color(tyres[k]["color"]))
		th.add_child(tb)
	var wear := float(circuit.get("tyre_wear_factor", 1.0))
	th.add_child(_wear_chip(wear))
	v.add_child(th)
	var fit := campaign.track_fit(rd["id"])
	var fcol := UiStyle.G_UP if fit > 0.35 else (UiStyle.G_DOWN if fit < -0.35 else Color("#F5C542"))
	var fh := HBoxContainer.new()
	fh.add_theme_constant_override("separation", 8)
	var sq := PanelContainer.new()
	sq.add_theme_stylebox_override("panel", UiStyle.g_box(fcol, 10, 7, 6))
	sq.add_child(ScreenKit.icon("car", 20, UiStyle.G_INK))
	fh.add_child(sq)
	var fl := UiStyle.g_label("forte" if fit > 0.35 else ("fraco" if fit < -0.35 else "neutro"), 15, fcol, "black")
	fl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fh.add_child(fl)
	v.add_child(fh)
	root.add_child(v)
	if is_next:
		var go := CutButton.new()
		go.text = "IR"
		go.add_theme_font_size_override("font_size", UiStyle.fs(17))
		go.position = Vector2(14, h - 66)
		go.size = Vector2(CARD_W - 28, 52)
		go.pressed.connect(CampaignFrame.continue_campaign)
		root.add_child(go)
	return card


func _chip(text: String, fill: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(fill, 14, 10, 3))
	p.add_child(UiStyle.g_label(text, 13, Color.WHITE, "black"))
	return p


## Desgaste da pista: 1 a 3 "gotas" (baixo/médio/alto).
func _wear_chip(f: float) -> Control:
	var n := 1 if f < 0.92 else (2 if f < 1.12 else 3)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 2)
	h.tooltip_text = "desgaste de pneus"
	for i in 3:
		var dot := ColorRect.new()
		dot.color = Color("#ff8a5a") if i < n else Color(1, 1, 1, 0.15)
		dot.custom_minimum_size = Vector2(6, 16)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(dot)
	h.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.custom_minimum_size = Vector2(26, 0)
	return h
