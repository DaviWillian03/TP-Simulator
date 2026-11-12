extends Control
## Configuração do Grande Prêmio (mockup v26-2 aprovado em 2026-11-09): o calendário em cartões grandes com a pista 3D,
## a bandeira, o clima e os pneus; embaixo, um painel com a equipe (emblemas), categoria, duração, clima, formato e a
## ação principal. As escolhas ficam no Session e são preservadas ao voltar.

const WEATHER := [["realistic", "Realista", "globe"], ["dry", "Seco", "sun"], ["rain", "Chuva", "rain"], ["variable", "Variável", "mixed"]]
const FORMATS := [["full", "Fim de semana"], ["race_only", "Só a corrida"]]
const MONTHS := ["", "JAN", "FEV", "MAR", "ABR", "MAI", "JUN", "JUL", "AGO", "SET", "OUT", "NOV", "DEZ"]
const CARD := Vector2(232, 340)

var _calendar: Array = []
var _cat := "F1"
var _season := Season.DEFAULT  ## 2026 | 2012 (mockup v37); F2/F3 são sempre 2026
var _page: Dictionary
var _rows: Dictionary = {}  # id do circuito -> cartão (Button) do carrossel
var _card_group := ButtonGroup.new()
var _scroll: ScrollContainer
var _laps: Label
var _teams: GridContainer
var _go: CutButton


func _ready() -> void:
	_calendar = GameData.load_json(GameData.DATA_DIR + "calendar_2026.json")["rounds"]
	_cat = GameData.category_of(Session.player_team)
	Session.category = _cat
	_season = Session.gp_season if _cat == "F1" and Season.is_ready(Session.gp_season) else Season.DEFAULT
	TeamEmblems.use_season(_season)
	if GameData.team_by_id(_cat_teams(), Session.player_team).is_empty():
		Session.player_team = String(_cat_teams()[0]["id"])
	if _season != Season.DEFAULT:  # calendário daquele ano primeiro (pistas sem traçado aparecem apagadas)
		_calendar = []
		for r: Dictionary in Season.calendar(_season):
			var e: Dictionary = r.duplicate()
			e["sprint"] = false
			_calendar.append(e)
	if CategoryRules.is_feeder(_cat):  # F2/F3: só as etapas da categoria (decisão de 2026-11-08)
		var rounds := CategoryRules.rounds(_cat)
		var list: Array = []
		for i in _calendar.size():
			if rounds.has(i):
				var r: Dictionary = (_calendar[i] as Dictionary).duplicate()
				r["stage"] = list.size() + 1
				list.append(r)
		_calendar = list
	# pistas das temporadas extras (2012: Sepang, Bahrein, Hockenheim…) entram no Grande Prêmio para qualquer temporada ou
	# categoria (pedido de 2026-11-12); no Mundial cada uma fica só no calendário da sua temporada
	var have := {}
	for r: Dictionary in Campaign.calendar():  # só pistas que não existem em 2026 (na F2/F3 as etapas continuam as da categoria)
		have[String(r["id"])] = true
	if _season != Season.DEFAULT:  # 2012: as pistas de 2026 que não estavam no calendário entram depois, sem sprint
		var in_year := {}
		for r: Dictionary in _calendar:
			in_year[String(r["id"])] = true
		for r: Dictionary in Campaign.calendar():
			if not in_year.has(String(r["id"])):
				var e: Dictionary = r.duplicate()
				e["sprint"] = false
				e["other_year"] = true
				_calendar.append(e)
		have.merge(in_year)
	for sid: String in Season.ids():
		for r2: Dictionary in Season.calendar(sid):
			var cid := String(r2["id"])
			if have.has(cid) or bool(r2.get("missing", false)) or not FileAccess.file_exists(GameData.DATA_DIR + "circuits/%s.json" % cid):
				continue
			have[cid] = true
			var extra: Dictionary = r2.duplicate()
			extra["sprint"] = false
			_calendar.append(extra)
	_page = ScreenKit.garage_page(self, Session.player_team)
	var bd: GarageBackdrop = _page["backdrop"]
	bd.floor_ratio = 1.0
	bd.show_lamps = false
	bd.cone_x = -1.0
	bd.set_glow(UiStyle.team_color(Session.player_team), 0.22)
	var layer: Control = _page["layer"]

	# cabeçalho
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UiStyle.SP_L)
	var back := ScreenKit.round_button("back", 48, "Voltar")
	back.pressed.connect(Session.go_to_title)
	head.add_child(back)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -4)
	if _cat == "F1":  # F1: o ano escolhe grid, regras e calendário (mockup v37)
		titles.add_theme_constant_override("separation", 4)
		titles.add_child(UiStyle.g_caption("Grande Prêmio"))
		var years: Array = []
		for sid: String in Season.ids():
			if Season.is_ready(sid):
				years.append([sid, sid])
		var yseg := ScreenKit.segmented(years, _season, _change_season)
		yseg.custom_minimum_size = Vector2(170, 0)
		yseg.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		titles.add_child(yseg)
	else:
		titles.add_child(UiStyle.g_caption(String(CategoryRules.of(_cat)["name"]) + " · temporada 2026"))
		titles.add_child(UiStyle.g_label("GRANDE PRÊMIO", 30, UiStyle.SECTION["drivers"], "black"))
	head.add_child(titles)
	ScreenKit.place(head, layer, Control.PRESET_TOP_LEFT, Vector2(40, 18))
	var cat_seg := ScreenKit.segmented([["F1", "F1"], ["F2", "F2"], ["F3", "F3"]], _cat, _change_category)  # categoria (v23-2)
	cat_seg.custom_minimum_size = Vector2(240, 0)
	if _season != Season.DEFAULT:  # 2012 só tem a F1 daquele ano: F2/F3 apagados
		for b: Button in cat_seg.get_child(0).get_children():
			if String(b.get_meta("value")) != "F1":
				b.disabled = true
				b.modulate.a = 0.3
	ScreenKit.place(cat_seg, layer, Control.PRESET_TOP_RIGHT, Vector2(-40, 22))

	# calendário em cartões grandes
	_scroll = DragScroll.new()
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 16)
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	_scroll.add_child(cards)
	ScreenKit.place(_scroll, layer, Control.PRESET_TOP_LEFT, Vector2(0, 84), Vector2(1280, CARD.y + 16))
	var start_pad := Control.new()
	start_pad.custom_minimum_size = Vector2(24, 0)
	cards.add_child(start_pad)
	for r: Dictionary in _calendar:
		cards.add_child(_card(r))
	var end_pad := Control.new()
	end_pad.custom_minimum_size = Vector2(24, 0)
	cards.add_child(end_pad)

	# painel: equipe · categoria e duração · clima e formato · LARGAR
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.g_box(Color("#171a21"), 22, 22, 16))
	ScreenKit.place(panel, layer, Control.PRESET_BOTTOM_LEFT, Vector2(40, -18), Vector2(1200, 0))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 30)
	panel.add_child(row)
	var tcol := VBoxContainer.new()
	tcol.add_theme_constant_override("separation", 10)
	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", 6)
	th.add_child(ScreenKit.icon("car", 18, UiStyle.G_TEXT_3))
	th.add_child(UiStyle.g_caption("Equipe"))
	tcol.add_child(th)
	_teams = GridContainer.new()
	_teams.columns = 6
	_teams.add_theme_constant_override("h_separation", 8)
	_teams.add_theme_constant_override("v_separation", 8)
	tcol.add_child(_teams)
	row.add_child(tcol)
	_fill_teams()
	var mid := VBoxContainer.new()
	mid.add_theme_constant_override("separation", 8)
	mid.add_child(UiStyle.g_caption("Duração"))
	mid.add_child(ScreenKit.segmented([[0.25, "25%"], [0.5, "50%"], [1.0, "100%"]], Session.duration_pct, func(v: float) -> void:
		Session.duration_pct = v
		_refresh_laps()))
	_laps = UiStyle.g_label("", UiStyle.FS_SMALL, UiStyle.G_TEXT_2, "bold")
	mid.add_child(_laps)
	mid.add_child(UiStyle.g_caption("Sessões"))
	mid.add_child(ScreenKit.segmented(FORMATS, Session.gp_format, func(v: String) -> void:
		Session.gp_format = v
		_refresh_cta()))
	row.add_child(mid)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(UiStyle.g_caption("Clima"))
	right.add_child(ScreenKit.choice_tiles(WEATHER, Session.gp_weather, func(v: String) -> void: Session.gp_weather = v))
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(fill)
	_go = CutButton.new()
	_go.custom_minimum_size = Vector2(0, 60)
	_go.add_theme_font_size_override("font_size", UiStyle.fs(20))
	_go.pressed.connect(Session.start_gp)
	right.add_child(_go)
	row.add_child(right)
	_refresh_cta()

	var first := ""
	for r: Dictionary in _calendar:
		if not bool(r.get("missing", false)):
			first = String(r["id"])
			break
	var keep := _rows.has(Session.circuit_id) and not (_rows[Session.circuit_id] as Button).disabled
	_select(Session.circuit_id if keep else first)
	_center_selected.call_deferred()
	layer.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(layer, "modulate:a", 1.0, 0.18)


## Emblemas das equipes da categoria; a escolhida tem contorno branco.
func _fill_teams() -> void:
	for c in _teams.get_children():
		c.queue_free()
	for t: Dictionary in _cat_teams():
		var id := String(t["id"])
		var on := id == Session.player_team
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(58, 58)
		b.tooltip_text = String(t.get("name", id))
		for st: String in ["normal", "hover", "pressed", "hover_pressed"]:
			var box := UiStyle.g_box(Color(UiStyle.team_color(id), 0.22 if st == "normal" else 0.34), 16, 0, 0)
			if on:
				box.border_color = Color.WHITE
				box.set_border_width_all(3)
			b.add_theme_stylebox_override(st, box)
		var cc := CenterContainer.new()
		cc.set_anchors_preset(Control.PRESET_FULL_RECT)
		cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var e := TeamEmblems.make_rect(id, 40)
		e.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cc.add_child(e)
		b.add_child(cc)
		b.pressed.connect(func() -> void:
			Session.player_team = id
			_on_team_changed(id))
		ScreenKit.press_feedback(b)
		_teams.add_child(b)


func _gap(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


# --- calendário -------------------------------------------------------------------------

func _card(r: Dictionary) -> Button:
	var circuit := GameData.circuit(r["id"]) if FileAccess.file_exists(GameData.DATA_DIR + "circuits/%s.json" % r["id"]) else {}
	var b := Button.new()
	b.toggle_mode = true
	b.button_group = _card_group
	b.focus_mode = Control.FOCUS_NONE
	b.clip_contents = true
	b.custom_minimum_size = CARD
	var off := UiStyle.g_box(Color("#171a21"), 22, 0, 0)
	var on := UiStyle.g_box(Color("#171a21"), 22, 0, 0)
	on.border_color = Color.WHITE
	on.set_border_width_all(4)
	b.add_theme_stylebox_override("normal", off)
	b.add_theme_stylebox_override("hover", off)
	b.add_theme_stylebox_override("pressed", on)
	b.add_theme_stylebox_override("hover_pressed", on)
	var art := TextureRect.new()
	art.texture = CampaignHub.track_art(r["id"])
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(art)
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(0.03, 0.04, 0.055, 0.0), Color(0.03, 0.04, 0.055, 0.94)])
	grad.offsets = PackedFloat32Array([0.35, 1.0])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_to = Vector2(0, 1)
	var shade := TextureRect.new()
	shade.texture = gt
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(shade)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var date: String = r["date"]
	var cap := ("%s · %d" % [_cat, int(r["stage"])]) if r.has("stage") else "%s %s" % [date.substr(8, 2), MONTHS[int(date.substr(5, 2))]]
	top.add_child(_chip(cap, Color(0.06, 0.07, 0.09, 0.82), Color.WHITE))
	if r.get("sprint", false) and _cat == "F1":
		top.add_child(_chip("Sprint", UiStyle.SECTION["staff"], Color.WHITE))
	if r.get("night", false):
		top.add_child(_chip("Noite", Color("#26324a"), Color("#ffd36b")))
	top.position = Vector2(12, 12)
	b.add_child(top)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(CampaignHub.flag_rect(String(circuit.get("country_code", "")), 24))
	var nm := CampaignHub.gp_short(String(r["grand_prix"])).to_upper()
	var l := UiStyle.g_label(nm, 24 if nm.length() <= 11 else 19, UiStyle.G_TEXT, "black")
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_y", 2)
	v.add_child(l)
	var ic := HBoxContainer.new()
	ic.add_theme_constant_override("separation", 6)
	var rain := float(circuit.get("rain_probability", 0.0))
	ic.add_child(ScreenKit.icon("rain" if rain >= 0.3 else "sun", 20, Color("#9fd2ff") if rain >= 0.3 else Color("#F5C542")))
	var tyres: Dictionary = GameData.tyres()["compounds"]
	var pair: Array = r.get("compounds", ["soft", "medium", "hard"]) if _season != Season.DEFAULT and not r.has("other_year") else ["soft", "medium", "hard"]
	for k: String in pair:
		var tb := TyreBadge.new()
		tb.custom_minimum_size = Vector2(22, 22)
		tb.set_compound(String(tyres[k]["letter"]), Color(tyres[k]["color"]))
		ic.add_child(tb)
	v.add_child(ic)
	v.position = Vector2(16, CARD.y - 110)
	b.add_child(v)
	var ring := Panel.new()  # contorno do cartão escolhido (por cima da arte)
	var rb := StyleBoxFlat.new()
	rb.bg_color = Color(0, 0, 0, 0)
	rb.border_color = Color.WHITE
	rb.set_border_width_all(4)
	rb.set_corner_radius_all(22)
	ring.add_theme_stylebox_override("panel", rb)
	ring.set_anchors_preset(Control.PRESET_FULL_RECT)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.visible = false
	b.add_child(ring)
	b.toggled.connect(func(pressed: bool) -> void:
		ring.visible = pressed
		if pressed:
			_select(r["id"]))
	ScreenKit.press_feedback(b)
	if bool(r.get("missing", false)) or not FileAccess.file_exists(GameData.DATA_DIR + "circuits/%s.json" % r["id"]):
		b.disabled = true  # pista daquele ano ainda sem traçado (2012: Valência, Coreia, Índia)
		b.modulate = Color(1, 1, 1, 0.35)
	_rows[r["id"]] = b
	return b


func _chip(text: String, bg: Color, fg: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(bg, 9, 7, 1))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UiStyle.g_caption(text, fg)
	l.add_theme_font_size_override("font_size", UiStyle.fs(11))
	p.add_child(l)
	return p


func _center_selected() -> void:
	var b: Button = _rows.get(Session.circuit_id)
	if b:
		_scroll.scroll_horizontal = int(maxf(0.0, b.position.x - _scroll.size.x / 2.0 + b.size.x / 2.0))


# --- circuito escolhido -----------------------------------------------------------------

func _select(circuit_id: String) -> void:
	Session.circuit_id = circuit_id
	var b: Button = _rows[circuit_id]
	if not b.button_pressed:
		b.button_pressed = true
		return  # o sinal "toggled" chama _select de novo
	_refresh_laps()


func _refresh_laps() -> void:
	var c := GameData.circuit(Session.circuit_id)
	if _cat != "F1":
		var tm := TrackModel.new(c)
		_laps.text = "%d voltas na sprint · %d na principal" % [maxi(3, roundi(CategoryRules.race_laps(_cat, tm, true) * Session.duration_pct)),
			maxi(3, roundi(CategoryRules.race_laps(_cat, tm, false) * Session.duration_pct))]
		return
	var laps := int(c.get("laps", 0))
	_laps.text = "%d voltas na corrida" % maxi(3, roundi(laps * Session.duration_pct))


func _cat_teams() -> Array:
	return Season.teams(_season) if _season != Season.DEFAULT else GameData.category_teams(_cat)


## Troca o ano (só F1): grid, cores, logos, fotos e calendário daquela temporada.
func _change_season(sid: String) -> void:
	if sid == _season:
		return
	Session.gp_season = sid
	get_tree().change_scene_to_file.call_deferred(Session.GP_SETUP_SCENE)


## Troca de categoria: a equipe passa a ser a primeira da categoria nova e a tela recarrega com o calendário dela.
func _change_category(cat: String) -> void:
	if cat == _cat:
		return
	Session.category = cat
	Session.player_team = String(GameData.category_teams(cat)[0]["id"])
	get_tree().change_scene_to_file.call_deferred(Session.GP_SETUP_SCENE)


func _refresh_cta() -> void:
	_go.text = "COMEÇAR CORRIDA" if Session.gp_format == "race_only" else "COMEÇAR FIM DE SEMANA"


func _on_team_changed(team_id: String) -> void:
	(_page["backdrop"] as GarageBackdrop).set_glow(UiStyle.team_color(team_id), 0.22)
	_fill_teams()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:  # botão "voltar" do Android
		Session.go_to_title()
