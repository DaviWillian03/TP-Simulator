extends Control
## Classificação ao vivo — direção Garagem (mesmo layout do treino, mockup v4-2; antes: m3-c): tabela da parte atual com a linha vermelha da zona de
## eliminação; para cada carro do jogador, a escolha do pneu e o botão de sair para a volta
## rápida; aviso da pista evoluindo. Q1/Q2/Q3 (ou SQ1/SQ2/SQ3 na sprint).

const UI_REFRESH_S := 0.25
const SPEEDS := [2.0, 4.0, 8.0, 16.0]

var weekend: WeekendSim
var q: QualiSim
var time_scale := 4.0
var _table: TimingTable
var _sub: Label
var _info_card: PanelContainer
var _clock: Label
var _panels: Array[Dictionary] = []  # {car, pos, status, tyres: {id: Button}, go: Button}
var _evolution: Label
var _cut_info: Label
var _end_card: PanelContainer
var _toasts: ToastFeed
var _refresh := 0.0


func _ready() -> void:
	weekend = Session.weekend
	if weekend == null or not weekend.is_quali(weekend.session_id()):
		Session.go_to_title.call_deferred()
		return
	q = weekend.make_quali()
	if Session.debug_advance_s > 0.0:  # (capturas de tela)
		q.advance(Session.debug_advance_s)
	var page := ScreenKit.garage_page(self, weekend.player_team)
	var bd: GarageBackdrop = page["backdrop"]
	bd.floor_ratio = 1.0
	bd.show_lamps = false
	bd.cone_x = -1.0
	bd.set_glow(UiStyle.team_color(weekend.player_team), 0.12)
	var layer: Control = page["layer"]

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UiStyle.SP_L)
	var back := ScreenKit.round_button("back", 52, "Voltar ao fim de semana")
	back.pressed.connect(Session.go_to_weekend)
	head.add_child(back)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -2)
	_sub = UiStyle.g_caption("")
	titles.add_child(_sub)
	titles.add_child(UiStyle.g_label(String(WeekendSim.SESSION_NAMES[weekend.session_id()]).to_upper(), 30, UiStyle.G_TEXT, "black"))
	head.add_child(titles)
	ScreenKit.place(head, layer, Control.PRESET_TOP_LEFT, Vector2(44, 24))

	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", UiStyle.SP_M)
	var speed_opts: Array = []
	for s: float in SPEEDS:
		speed_opts.append([s, "%d×" % int(s)])
	var speeds := ScreenKit.segmented(speed_opts, time_scale, func(s: float) -> void: time_scale = s)
	speeds.custom_minimum_size = Vector2(250, 0)
	tools.add_child(speeds)
	var rest := Button.new()
	rest.text = "SIMULAR RESTO"
	rest.focus_mode = Control.FOCUS_NONE
	rest.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MIN + 4)
	rest.add_theme_font_size_override("font_size", UiStyle.fs(15))
	rest.pressed.connect(_simulate_rest)
	ScreenKit.press_feedback(rest)
	tools.add_child(rest)
	_clock = UiStyle.g_label("", 26, UiStyle.G_TEXT, "black")
	_clock.custom_minimum_size = Vector2(190, 0)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tools.add_child(_clock)
	ScreenKit.place(tools, layer, Control.PRESET_TOP_RIGHT, Vector2(-40, 30))

	var scroll := DragScroll.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layer.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	scroll.offset_left = 44
	scroll.offset_right = 44 + 720
	scroll.offset_top = 96
	scroll.offset_bottom = -14
	_table = TimingTable.new()
	_table.row_h = clampi(588 / q.cars.size(), 22, 26)  # 22 ou 24 carros cabem sem rolar
	_table.me_color = UiStyle.team_color(weekend.player_team)
	_table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_table.setup([
		{"title": "Pos", "width": 46, "kind": "pos"},
		{"title": "Piloto", "width": 0, "kind": "team"},
		{"title": "Melhor", "width": 96, "align": "right"},
		{"title": "Dif.", "width": 80, "align": "right"},
		{"title": "Pn", "width": 52, "kind": "tyre"},
		{"title": "Situação", "width": 160},
	], q.cars.size(), "garage")
	scroll.add_child(_table)

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 12)
	ScreenKit.place(right, layer, Control.PRESET_TOP_RIGHT, Vector2(-40, 96), Vector2(430, 0))
	for car in q.cars:
		if car.is_player:
			right.add_child(_player_panel(car))
	_info_card = ScreenKit.g_card(Color(1, 1, 1, 0.04), 20, 18, 12)
	var iv := VBoxContainer.new()
	iv.add_theme_constant_override("separation", 4)
	_info_card.add_child(iv)
	iv.add_child(UiStyle.g_caption("Pista evoluindo"))
	_evolution = UiStyle.g_label("", 14, Color("#c3c9d3"))
	_evolution.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	iv.add_child(_evolution)
	_cut_info = UiStyle.g_label("", 14, Color("#ffb4a8"), "bold")
	_cut_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	iv.add_child(_cut_info)
	right.add_child(_info_card)
	_end_card = _build_end_card()
	_end_card.visible = false
	right.add_child(_end_card)

	_toasts = ToastFeed.new()
	_toasts.custom_minimum_size = Vector2(430, 0)
	ScreenKit.place(_toasts, layer, Control.PRESET_BOTTOM_RIGHT, Vector2(-40, -110), Vector2(430, 0))
	q.session_event.connect(func(t: String) -> void: _toasts.push(t))
	q.segment_finished.connect(_on_segment_finished)
	q.lap_completed.connect(_on_lap)
	_refresh_ui()


func _player_panel(car: CarState) -> Control:
	var color := car.team_color()
	var card := ScreenKit.g_card(UiStyle.G_SURFACE, 20, 18, 12)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", UiStyle.SP_M)
	top.add_child(DriverPhotos.make_avatar(car.driver, color, 40))
	top.add_child(UiStyle.g_label(car.display_name(), 19, UiStyle.G_TEXT, "black"))
	top.add_child(TeamEmblems.make_rect(car.team["id"], 24))
	top.add_child(UiStyle.hspacer())
	var pos := UiStyle.g_label("", 28, UiStyle.RED, "black")
	top.add_child(pos)
	v.add_child(top)
	var status := UiStyle.g_label("", 14, Color("#c3c9d3"))
	v.add_child(status)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var tyres := _tyre_tiles(row, car)
	v.add_child(row)
	var go := CutButton.new()
	go.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MAIN)
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.add_theme_font_size_override("font_size", UiStyle.fs(17))
	v.add_child(go)
	var panel := {"car": car, "pos": pos, "status": status, "tyres": tyres, "go": go}
	go.pressed.connect(_send_out.bind(panel))
	_panels.append(panel)
	return card


## Escolha do pneu da volta rápida: um bloco por composto (círculo do pneu sobre fundo escuro/claro).
func _tyre_tiles(row: HBoxContainer, car: CarState) -> Dictionary:
	var group := ButtonGroup.new()
	var out := {}
	var selected := q.ai_compound(car)
	for id: String in ScreenKit.COMPOUNDS:
		var c: Dictionary = q.tyres.compounds[id]
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(UiStyle.TOUCH_MIN, UiStyle.TOUCH_MIN)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.tooltip_text = c["name"]
		for st: String in ["normal", "hover"]:
			b.add_theme_stylebox_override(st, UiStyle.g_box(UiStyle.G_SURFACE_HOVER, 12, 0, 0))
		for st: String in ["pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(st, UiStyle.g_box(UiStyle.G_LIGHT, 12, 0, 0))
		var badge := TyreBadge.new()
		badge.custom_minimum_size = Vector2(30, 30)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.set_compound(c["letter"], Color(c["color"]))
		b.add_child(badge)
		badge.anchor_left = 0.5
		badge.anchor_right = 0.5
		badge.anchor_top = 0.5
		badge.anchor_bottom = 0.5
		badge.offset_left = -15
		badge.offset_right = 15
		badge.offset_top = -15
		badge.offset_bottom = 15
		b.button_pressed = id == selected
		ScreenKit.press_feedback(b)
		row.add_child(b)
		out[id] = b
	return out


func _send_out(panel: Dictionary) -> void:
	var compound := "soft"
	for id: String in panel["tyres"]:
		if (panel["tyres"][id] as Button).button_pressed:
			compound = id
	if q.send_out(panel["car"], compound):
		_toasts.push("%s saiu para a volta rápida." % (panel["car"] as CarState).code(), "hot")
	_refresh_ui()


func _process(delta: float) -> void:
	if q == null:
		return
	if not q.is_over():
		q.advance(delta * time_scale)
	_refresh -= delta
	if _refresh <= 0.0:
		_refresh = UI_REFRESH_S
		_refresh_ui()


func _refresh_ui() -> void:
	var seg: Dictionary = q.segments[q.segment]
	var adv: int = seg["advance"]
	_sub.text = "%s · %s · %s" % [weekend.circuit["grand_prix"], seg["name"],
		("%d avançam" % adv) if adv > 0 else "disputa da pole"]
	_clock.text = "%s %s" % [seg["name"], "BANDEIRA VERMELHA" if q.is_red_flag() else ScreenKit.clock(q.time_left_s())]
	_clock.add_theme_font_size_override("font_size", UiStyle.fs(20 if q.is_red_flag() else 30))
	if q.is_over():
		_clock.text = "ENCERRADA"
	var order := q.standings()
	var active := q.active_cars().size()
	var lead_best := q.best_in_segment(order[0])
	for i in order.size():
		var car := order[i]
		var out: bool = q.eliminated_in[car] >= 0
		var b := q.best_in_segment(car)
		_table.set_row_style(i, "me" if car.is_player else ("out" if out else "normal"))
		_table.set_pos(i, 0, str(i + 1), Color(1, 1, 1, 0.18) if out else car.team_color())
		_table.set_team(i, 1, car.team["id"], StandingsPanel.surname(car.display_name()))
		_table.set_text(i, 2, UiStyle.format_time(b))
		_table.set_text(i, 3, "—" if i == 0 or b == INF or out else "+%.3f" % (b - lead_best))
		var c: Dictionary = q.tyres.compounds[car.tyre] if q.run_tyre.has(car) else {}
		_table.set_tyre(i, 4, c.get("letter", ""), Color(c.get("color", "#00000000")), "")
		_table.set_text(i, 5, q.status_of(car))
	_table.set_cut_line(adv - 1 if adv > 0 and adv < active and not q.is_over() else -1)
	_cut_info.text = "" if adv <= 0 or q.is_over() else "Linha vermelha: zona de eliminação (%dº–%dº)" % [adv + 1, active]
	_evolution.text = "A pista já melhorou %s s nesta parte. Quem sair no fim ganha até %s s de borracha — mas arrisca tráfego, bandeira vermelha ou chuva." % [
		String.num(q.track_evolution_s(), 2).replace(".", ","), String.num(QualiSim.EVOLUTION_S + QualiSim.SEGMENT_EVOLUTION_S * q.segment, 1).replace(".", ",")]
	if q.weather.wetness > 0.1:
		_evolution.text += " Pista %s." % q.weather.surface_label().to_lower()
	for p: Dictionary in _panels:
		var car: CarState = p["car"]
		var pos := order.find(car) + 1
		(p["pos"] as Label).text = "P%d" % pos
		var status := q.status_of(car)
		if status == "Garagem":
			status += " · %d jogo(s) de macios novos" % q.new_softs[car]
		elif car.last_lap_time > 0.0 and status == "Volta de entrada":
			status += " · última: %s" % UiStyle.format_time(car.last_lap_time)
		(p["status"] as Label).text = status
		var go: Button = p["go"]
		go.disabled = not q.can_go_out(car)
		match q.status_of(car):
			"Garagem":
				go.text = "SAIR PARA VOLTA RÁPIDA" if q.time_left_s() > 0.0 else "TEMPO ESGOTADO"
			"Volta de saída", "Volta lançada", "Volta de entrada":
				go.text = "VOLTA EM ANDAMENTO"
			_:
				go.text = q.status_of(car).to_upper()
	_end_card.visible = q.is_over()
	_info_card.visible = not q.is_over()


func _on_lap(car: CarState, lap_time: float, valid: bool) -> void:
	if car.is_player and valid:
		_toasts.push("%s: %s (%s)" % [car.code(), UiStyle.format_time(lap_time), q.segment_name()], "hot")


func _on_segment_finished(index: int, eliminated: Array) -> void:
	var seg_name: String = q.segments[index]["name"]
	if eliminated.is_empty():
		var pole: CarState = q.segment_order()[0]
		_toasts.push("Pole position: %s." % pole.display_name(), "hot")
		return
	var codes: Array[String] = []
	for car: CarState in eliminated:
		codes.append(car.code())
	_toasts.push("Fim do %s. Eliminados: %s." % [seg_name, ", ".join(codes)])


func _simulate_rest() -> void:
	q.auto_player = true  # a IA da equipe decide as saídas dos seus carros até o fim
	q.run_to_end()
	_refresh_ui()


func _build_end_card() -> PanelContainer:
	var card := PanelContainer.new()
	var st := UiStyle.g_box(UiStyle.G_LIGHT, 20, 24, 16)
	st.border_width_left = 7
	st.border_color = UiStyle.RED
	card.add_theme_stylebox_override("panel", st)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	v.add_child(UiStyle.g_label("CLASSIFICAÇÃO ENCERRADA", 22, UiStyle.G_INK, "black"))
	var t := UiStyle.g_label("A tabela mostra o grid de largada.", 15, UiStyle.G_INK_2)
	v.add_child(t)
	var go := CutButton.new()
	go.text = "CONTINUAR"
	go.pressed.connect(func() -> void:
		weekend.finish_quali(q)
		Session.go_to_weekend())
	v.add_child(go)
	return card


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.go_to_weekend()
