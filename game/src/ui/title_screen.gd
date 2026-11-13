extends Control
## Tela inicial como painel (mockup design/mockups/v39-tela-inicial.html, aprovado em 2026-11-13): fundo vivo com a arte
## 3D da próxima pista (MenuBackdrop), carro ilustrado da equipe (CarHero; o 3D saiu em 2026-11-14), cartão da
## próxima corrida com contagem, posição no campeonato, os modos de jogo em lista e a faixa de notícias. Entrada animada:
## faixa diagonal na cor da equipe, carro e título deslizando, cartões em sequência e números contando.
## Tudo num palco 1280×720 no centro (vale para telas mais largas que 16:9).

const LOGO := preload("res://assets/branding/logo.svg")

var _stage: Control
var _saved: Campaign
var _team: Dictionary
var _accent := UiStyle.RED
var _next: Dictionary = {}  ## {id, gp, days, hours, rain, round}
var _anim: Array[Control] = []  ## entram em sequência
var _counters: Array = []  ## [Label, valor, formato]
var _ticker: HBoxContainer


func _ready() -> void:
	var latest_c := SaveSlots.latest("campaign")
	_saved = Campaign.load_saved(SaveSlots.campaign_path(latest_c)) if latest_c > 0 else null
	var team_id := _saved.player_team if _saved != null else Session.player_team
	_team = _saved.team() if _saved != null else GameData.team_by_id(GameData.teams(), team_id)
	if _team.is_empty():
		_team = GameData.teams()[0]
	_accent = UiStyle.team_accent(_team)
	_next = _next_race()
	var bg := MenuBackdrop.make(String(_next.get("id", "interlagos")))
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage = Control.new()
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	_stage.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_stage.offset_left = -640
	_stage.offset_right = 640
	_stage.offset_top = -360
	_stage.offset_bottom = 360
	_header()
	_team_block()
	_next_card()
	_champ_card()
	_modes()
	_build_ticker()
	if Session.debug_ui == "help":  # (captura) --ui=help abre a ajuda
		HelpSheet.open.call_deferred(self)
	else:
		Tips.show_once.call_deferred(self, "title")
	_intro()


# --- dados do painel --------------------------------------------------------------------------------

## Próxima corrida: a da campanha salva; sem campanha, a próxima do calendário real de 2026 pela data de hoje.
func _next_race() -> Dictionary:
	var cal := Campaign.calendar()
	if _saved != null and not _saved.season_over():
		var r := _saved.next_round()
		var c := GameData.circuit(String(r["id"]))
		return {"id": String(r["id"]), "gp": String(r.get("grand_prix", c.get("grand_prix", ""))), "days": _saved.days_to_event(),
			"hours": -1, "rain": float(c.get("rain_probability", 0.0)), "round": _saved.round + 1}
	var now := Time.get_unix_time_from_system()
	for i in cal.size():
		var r: Dictionary = cal[i]
		var t := Time.get_unix_time_from_datetime_string(String(r["date"]) + "T14:00:00")
		if t > now:
			var c := GameData.circuit(String(r["id"]))
			var left := int(t - now)
			return {"id": String(r["id"]), "gp": String(r["grand_prix"]), "days": left / 86400, "hours": (left % 86400) / 3600,
				"rain": float(c.get("rain_probability", 0.0)), "round": i + 1}
	var first: Dictionary = cal[0]
	return {"id": String(first["id"]), "gp": String(first["grand_prix"]), "days": -1, "hours": -1, "rain": 0.0, "round": 1}


# --- blocos -------------------------------------------------------------------------------------------

func _header() -> void:
	var logo := TextureRect.new()
	logo.texture = LOGO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.position = Vector2(30, 16)
	logo.size = Vector2(220, 68)
	_stage.add_child(logo)
	var gear := ScreenKit.round_button("gear", 48, "Configurações")
	gear.pressed.connect(Session.open_settings)
	gear.position = Vector2(1200, 26)
	_stage.add_child(gear)
	var help := ScreenKit.round_button("help", 48, "Ajuda")
	help.pressed.connect(func() -> void: HelpSheet.open(self))
	help.position = Vector2(1144, 26)
	_stage.add_child(help)


func _team_block() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -6)
	v.position = Vector2(36, 104)
	v.add_child(UiStyle.g_caption("Sua equipe · campanha" if _saved != null else "Temporada 2026"))
	var name := String(_team.get("name", "")).to_upper()
	v.add_child(UiStyle.g_label(name, 54 if name.length() <= 12 else 40, UiStyle.G_TEXT, "black"))
	_stage.add_child(v)
	_anim.append(v)
	var car := CarHero.new()  # carro ilustrado (caricato), como antes: o 3D saiu a pedido do usuário (2026-11-14)
	_stage.add_child(car)
	car.position = Vector2(20, 250)
	car.custom_minimum_size = Vector2(620, 200)
	car.size = Vector2(620, 200)
	var drivers: Array = GameData.drivers().filter(func(d: Dictionary) -> bool: return String(d["team"]) == String(_team.get("id", "")))
	var c2 := Color(String(_team.get("color2", "#ffffff")))
	car.set_team(String(_team.get("id", "")), int(drivers[0]["number"]) if not drivers.is_empty() else 0, c2 if c2.get_luminance() > 0.35 else Color.WHITE, _team)
	_anim.append(car)


func _glass(r: Rect2) -> PanelContainer:
	var p := PanelContainer.new()
	var st := UiStyle.g_box(UiStyle.G_GLASS, 20, 16, 14)
	st.set_border_width_all(1)
	st.border_color = Color(1, 1, 1, 0.08)
	p.add_theme_stylebox_override("panel", st)
	p.position = r.position
	p.size = r.size
	p.custom_minimum_size = r.size
	_stage.add_child(p)
	_anim.append(p)
	return p


func _next_card() -> void:
	var r := Rect2(800, 92, 450, 250)
	var card := Button.new()
	card.focus_mode = Control.FOCUS_NONE
	card.clip_contents = true
	card.position = r.position
	card.size = r.size
	var st := UiStyle.g_box(UiStyle.G_GLASS, 20, 0, 0)
	for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
		card.add_theme_stylebox_override(s, st)
	_stage.add_child(card)
	_anim.append(card)
	card.pressed.connect(_continue)
	ScreenKit.press_feedback(card)
	var art := TextureRect.new()
	art.texture = CampaignHub.track_art(String(_next["id"]))
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(art)
	var shade := _Fade.new()
	card.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.position = Vector2(20, 112)
	var cap := HBoxContainer.new()
	cap.add_theme_constant_override("separation", 8)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.add_child(CampaignHub.flag_rect(String(GameData.circuit(String(_next["id"])).get("country_code", "")), 16))
	cap.add_child(UiStyle.g_caption("Próxima corrida · rodada %d" % int(_next["round"])))
	v.add_child(cap)
	var gp := UiStyle.g_label(String(_next["gp"]).to_upper(), 30, UiStyle.G_TEXT, "black")
	gp.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	gp.add_theme_constant_override("shadow_offset_y", 2)
	v.add_child(gp)
	var cd := HBoxContainer.new()
	cd.add_theme_constant_override("separation", 8)
	cd.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if int(_next["days"]) >= 0:
		cd.add_child(_count_box(int(_next["days"]), "dias"))
		if int(_next["hours"]) >= 0:
			cd.add_child(_count_box(int(_next["hours"]), "h"))
	cd.add_child(_count_box(roundi(float(_next["rain"]) * 100.0), "% chuva"))
	v.add_child(cd)
	card.add_child(v)
	var go := CutButton.new()
	go.text = "CONTINUAR" if _saved != null else "JOGAR"
	go.mouse_filter = Control.MOUSE_FILTER_IGNORE
	go.size = Vector2(170, 52)
	go.position = Vector2(r.size.x - 186, r.size.y - 68)
	card.add_child(go)


func _count_box(value: int, unit: String) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.12), 10, 10, 4))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var n := UiStyle.g_label("0", 22, UiStyle.G_TEXT, "black")
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(n)
	var u := UiStyle.g_label(unit, 10, UiStyle.G_TEXT_2, "black")
	u.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(u)
	p.add_child(v)
	_counters.append([n, value, "%02d" if unit in ["dias", "h"] else "%d"])
	return p


func _champ_card() -> void:
	var card := _glass(Rect2(800, 356, 220, 150))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	card.add_child(h)
	var pos := 0
	var pts := 0
	var total := 11
	if _saved != null:
		pos = _saved.team_position(_saved.player_team)
		pts = int(_saved.team_points.get(_saved.player_team, 0))
		total = _saved.teams().size()
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", -4)
	rv.add_child(UiStyle.g_caption("Campeonato"))
	if pos > 0:
		var big := UiStyle.g_label("0º", 40, UiStyle.G_TEXT, "black")
		rv.add_child(big)
		_counters.append([big, pos, "%dº"])
		var pl := UiStyle.g_label("0 pts", 18, _accent.lightened(0.25), "black")
		rv.add_child(pl)
		_counters.append([pl, pts, "%d pts"])
	else:
		rv.add_child(UiStyle.g_label("—", 40, UiStyle.G_TEXT_2, "black"))
		rv.add_child(UiStyle.g_label("sem campanha", 13, UiStyle.G_TEXT_2, "bold"))
	var bar := _PosBar.new(pos, total, _accent)
	bar.custom_minimum_size = Vector2(10, 110)
	h.add_child(bar)
	h.add_child(rv)


func _modes() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.position = Vector2(1034, 356)
	v.size = Vector2(216, 0)
	_stage.add_child(v)
	var hist_ok := _saved != null
	var list := [["trophy", "Campanha", UiStyle.RED, func() -> void: Session.open_slots("campaign"), true],
		["play", "Grande Prêmio", UiStyle.G_GLASS, _gp_pressed, true],
		["globe", "Mundial F1", UiStyle.G_GLASS, func() -> void: Session.open_slots("world"), true],
		["crown", "História", UiStyle.G_GLASS, _open_history, hist_ok],
		["plus", "Nova equipe", UiStyle.G_GLASS, Session.open_team_creator, true]]
	for m: Array in list:
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.text = "  " + String(m[1])
		b.icon = load("res://assets/icons/%s.svg" % m[0])
		b.add_theme_constant_override("icon_max_width", 20)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(216, 50)
		b.add_theme_font_override("font", UiStyle.G_BLACK)
		b.add_theme_font_size_override("font_size", UiStyle.fs(15))
		var fill: Color = m[2]
		for s: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			var st := UiStyle.g_box(fill if s != "pressed" else fill.lightened(0.1), 12, 14, 0)
			st.set_border_width_all(1)
			st.border_color = Color(1, 1, 1, 0.08)
			b.add_theme_stylebox_override(s, st)
		for k: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(k, UiStyle.G_TEXT)
		b.add_theme_color_override("font_disabled_color", UiStyle.G_TEXT_OFF)
		b.disabled = not bool(m[4])
		b.pressed.connect(m[3])
		ScreenKit.press_feedback(b)
		v.add_child(b)
		_anim.append(b)


func _build_ticker() -> void:
	var bar := PanelContainer.new()
	var st := UiStyle.g_box(Color(UiStyle.G_PODIUM_SHADE, 0.9), 0, 0, 0)
	st.border_width_top = 2
	st.border_color = _accent
	bar.add_theme_stylebox_override("panel", st)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.clip_contents = true
	add_child(bar)
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -46
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(holder)
	_ticker = HBoxContainer.new()
	_ticker.add_theme_constant_override("separation", 28)
	_ticker.position = Vector2(20, 10)
	holder.add_child(_ticker)
	var tag := PanelContainer.new()
	tag.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.RED, 6, 10, 2))
	tag.add_child(UiStyle.g_label("NOTÍCIAS", 12, Color.WHITE, "black"))
	_ticker.add_child(tag)
	for t: String in _news():
		_ticker.add_child(UiStyle.g_label(t + "   ●", 14, UiStyle.G_TEXT, "bold"))


func _news() -> Array:
	var out: Array = []
	var gp := String(_next["gp"])
	if int(_next["days"]) >= 0:
		out.append("%s em %d dias" % [gp, int(_next["days"])])
	out.append("Chance de chuva em %s: %d%%" % [gp.replace("GP de ", "").replace("GP do ", "").replace("GP da ", ""), roundi(float(_next["rain"]) * 100.0)])
	if _saved != null:
		out.append("%s é %dª no campeonato" % [String(_team.get("name", "")), _saved.team_position(_saved.player_team)])
		out.append("Orçamento da equipe: US$ %d mi" % int(_saved.budget_musd))
	out.append("Temporada 2012 disponível no Grande Prêmio e no Mundial")
	out.append("17 pistas com o mapa real em volta")
	return out


# --- animação -------------------------------------------------------------------------------------------

## Entrada: duas faixas diagonais na cor da equipe varrem a tela, depois o título/carro e os cartões entram um a um
## (deslizando e aparecendo) e os números contam até o valor. A faixa de notícias rola sem parar.
func _intro() -> void:
	for k in 2:
		var s := Panel.new()
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		s.add_theme_stylebox_override("panel", UiStyle.g_box(Color(_accent, 0.95 if k == 0 else 0.5), 0, 0, 0))
		s.size = Vector2(160 if k == 0 else 60, 1100)
		s.rotation_degrees = 18
		s.position = Vector2(-300 - k * 120, -200)
		add_child(s)
		var tw := s.create_tween()
		tw.tween_property(s, "position:x", size.x + 300.0, 0.55).set_delay(0.05 * k).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tw.tween_callback(s.queue_free)
	for i in _anim.size():
		var c := _anim[i]
		c.modulate.a = 0.0
		var final_x := c.position.x
		c.position.x = final_x + (40.0 if c.position.x > 640 else -40.0)
		var tw := c.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(c, "modulate:a", 1.0, 0.35).set_delay(0.3 + i * 0.06)
		tw.tween_property(c, "position:x", final_x, 0.45).set_delay(0.3 + i * 0.06)
	for e: Array in _counters:
		var lbl: Label = e[0]
		var fmt: String = e[2]
		var tw := create_tween()
		tw.tween_method(func(v: float) -> void: lbl.text = fmt % roundi(v), 0.0, float(e[1]), 0.9).set_delay(0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	if _ticker == null:
		return
	_ticker.position.x -= 60.0 * delta
	if _ticker.position.x < -_ticker.size.x:
		_ticker.position.x = get_viewport_rect().size.x


# --- ações ------------------------------------------------------------------------------------------------

func _continue() -> void:
	if _saved != null:
		Session.open_slots("campaign")
	else:
		_gp_pressed()


func _open_history() -> void:
	if _saved == null:
		return
	Session.campaign = _saved
	Session.player_team = _saved.player_team
	Session.open_campaign_history()


## Grande Prêmio: com um fim de semana salvo, pergunta se continua ou começa outro.
func _gp_pressed() -> void:
	var w := SaveSlots.load_weekend("gp")
	if w == null:
		Session.open_team_select("gp")
		return
	var sh := ScreenKit.sheet("Grande Prêmio em andamento", 680)
	var body: VBoxContainer = sh["body"]
	var where := String(w.circuit.get("grand_prix", ""))
	var nxt := "fim de semana encerrado" if w.is_over() else "próxima sessão: %s" % w.session_name(w.session_id())
	body.add_child(UiStyle.g_label("%s · %s" % [where, nxt], 18, UiStyle.G_TEXT_2, "bold"))
	var go := CutButton.new()
	go.text = "CONTINUAR"
	go.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MAIN)
	go.pressed.connect(func() -> void:
		(sh["root"] as Control).queue_free()
		Session.resume_weekend("gp"))
	body.add_child(go)
	var fresh := ScreenKit.light_button("Novo Grande Prêmio")
	fresh.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MAIN)
	fresh.pressed.connect(func() -> void:
		SaveSlots.delete_weekend("gp")
		Session.open_team_select("gp"))
	body.add_child(fresh)
	add_child(sh["root"])


## Degradê escuro de baixo para cima no cartão da próxima corrida (o texto lê bem sobre a arte).
class _Fade:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var a := Color(UiStyle.G_PODIUM_SHADE, 0.05)
		var b := Color(UiStyle.G_PODIUM_SHADE, 0.95)
		draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]), PackedColorArray([a, a, b, b]))


## Barra vertical da posição no campeonato: cheia para o líder, vazia para o último.
class _PosBar:
	extends Control

	var pos := 0
	var total := 11
	var col := Color.WHITE

	func _init(p: int, t: int, c: Color) -> void:
		pos = p
		total = maxi(t, 1)
		col = c
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_rect(Rect2(0, 0, size.x, size.y), Color(1, 1, 1, 0.1))
		if pos <= 0:
			return
		var f := 1.0 - float(pos - 1) / total
		draw_rect(Rect2(0, size.y * (1.0 - f), size.x, size.y * f), col)
