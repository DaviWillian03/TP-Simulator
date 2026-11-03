extends Control
## Classificação ao vivo — a pista 3D em tela cheia (mockup v14), com os carros andando de verdade:
## volta de saída, volta lançada e volta de entrada. À esquerda, os cartões dos seus pilotos
## (escolha do pneu e botão de sair para a volta rápida); à direita, a tabela da parte atual com
## a linha vermelha da zona de eliminação. Q1/Q2/Q3 (ou SQ1/SQ2/SQ3 na sprint).
##
## O relógio roda pelo tempo real × velocidade; a simulação (QualiSim) é a mesma de sempre, a tela
## só desenha onde cada carro está na volta dele.

const UI_REFRESH_S := 0.2
const SPEEDS := [2.0, 4.0, 8.0, 16.0]
const LEFT_W := CarControlPanel.WIDTH + 24.0
const TOWER_W := 384.0
const SIDE_TOP := 78.0

var weekend: WeekendSim
var q: QualiSim
var time_scale := 4.0
var _view: TrackView3D
var _table: TimingTable
var _sub: Label
var _info_card: PanelContainer
var _clock: Label
var _clock_caption: Label
var _panels: Array[Dictionary] = []  # {car, pos, status, tyres: {id: Button}, go: Button, bar, lap}
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
	var layer: Control = page["layer"]

	# pista 3D em tela cheia, atrás de todo o resto
	var holder := Control.new()
	layer.add_child(holder)
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view = TrackView3D.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.add_child(_view)
	_view.setup(q)
	if Session.debug_camera.size() > 0:  # (capturas)
		_view.yaw = Session.debug_camera.get("yaw", _view.yaw)
		_view.pitch = Session.debug_camera.get("pitch", _view.pitch)
		_view.distance = Session.debug_camera.get("dist", _view.distance)
		_view.snap_camera = true
	ScreenKit.top_shade(layer)
	_build_top_bar(layer)

	# cartões dos seus pilotos: coluna vertical à esquerda
	var cards := VBoxContainer.new()
	cards.add_theme_constant_override("separation", 12)
	ScreenKit.place(cards, layer, Control.PRESET_TOP_LEFT, Vector2(12, SIDE_TOP))
	for car in q.cars:
		if car.is_player:
			cards.add_child(_player_panel(car))

	# tabela da parte atual, à direita
	var tower := PanelContainer.new()
	tower.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_GLASS, 20, 8, 6))
	ScreenKit.place(tower, layer, Control.PRESET_TOP_RIGHT, Vector2(-12, SIDE_TOP), Vector2(TOWER_W, 720.0 - SIDE_TOP - 8.0))
	var scroll := DragScroll.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tower.add_child(scroll)
	_table = TimingTable.new()
	_table.row_h = clampi(560 / q.cars.size(), 22, 26)  # 22 ou 24 carros cabem sem rolar
	_table.me_color = UiStyle.team_color(weekend.player_team)
	_table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_table.setup([
		{"title": "Pos", "width": 32, "kind": "pos"},
		{"title": "Piloto", "width": 0, "kind": "team"},
		{"title": "Melhor", "width": 76, "align": "right"},
		{"title": "Dif.", "width": 62, "align": "right"},
		{"title": "Pn", "width": 28, "kind": "tyre"},
	], q.cars.size(), "garage")
	scroll.add_child(_table)

	# faixa baixa no centro da área livre: pista evoluindo (ou o fim da classificação)
	var area := MarginContainer.new()
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_theme_constant_override("margin_left", int(LEFT_W))
	area.add_theme_constant_override("margin_right", int(TOWER_W + 24.0))
	area.add_theme_constant_override("margin_bottom", 12)
	layer.add_child(area)
	area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_END
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(col)
	_info_card = PanelContainer.new()
	_info_card.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_GLASS, 18, 18, 10))
	var iv := VBoxContainer.new()
	iv.add_theme_constant_override("separation", 2)
	_info_card.add_child(iv)
	_evolution = UiStyle.g_label("", 13, Color("#c3c9d3"))
	_evolution.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	iv.add_child(_evolution)
	_cut_info = UiStyle.g_label("", 13, Color("#ffb4a8"), "bold")
	_cut_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	iv.add_child(_cut_info)
	col.add_child(_info_card)
	_end_card = _build_end_card()
	_end_card.visible = false
	col.add_child(_end_card)

	_toasts = ToastFeed.new()
	_toasts.position = Vector2(LEFT_W + 14.0, SIDE_TOP + 6.0)
	_toasts.custom_minimum_size = Vector2(440, 0)
	layer.add_child(_toasts)
	q.session_event.connect(func(t: String) -> void: _toasts.push(t))
	q.segment_finished.connect(_on_segment_finished)
	q.lap_completed.connect(_on_lap)
	_refresh_ui()


func _build_top_bar(layer: Control) -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE  # a barra não bloqueia o toque na pista
	ScreenKit.place(bar, layer, Control.PRESET_TOP_LEFT, Vector2(12, 6), Vector2(1256, 60))
	var back := ScreenKit.glass_round_button("back", 44, "Voltar ao fim de semana")
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(Session.go_to_weekend)
	bar.add_child(back)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -2)
	titles.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	titles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := UiStyle.g_label(String(WeekendSim.SESSION_NAMES[weekend.session_id()]).to_upper(), 20, UiStyle.G_TEXT, "black")
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titles.add_child(title)
	_sub = UiStyle.g_caption("", UiStyle.G_TEXT_2)
	_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titles.add_child(_sub)
	bar.add_child(titles)

	var speed_pill := PanelContainer.new()
	speed_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	speed_pill.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_GLASS, 24, 3, 3))
	var speed_opts: Array = []
	for s: float in SPEEDS:
		speed_opts.append([s, "%d×" % int(s)])
	var speeds := ScreenKit.segmented(speed_opts, time_scale, func(s: float) -> void: time_scale = s)
	speeds.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	for b: Control in (speeds.get_child(0) as Control).get_children():
		b.custom_minimum_size = Vector2(50, 40)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	speed_pill.add_child(speeds)
	bar.add_child(speed_pill)
	var rest := ScreenKit.glass_pill_button("SIMULAR RESTO")
	rest.pressed.connect(_simulate_rest)
	bar.add_child(rest)

	bar.add_child(UiStyle.hspacer())
	var clock := VBoxContainer.new()
	clock.add_theme_constant_override("separation", -6)
	clock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	clock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clock = UiStyle.g_label("", 30, UiStyle.G_TEXT, "black")
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_clock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clock.add_child(_clock)
	_clock_caption = UiStyle.g_caption("Tempo restante")
	_clock_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_clock_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clock.add_child(_clock_caption)
	bar.add_child(clock)


## Cartão compacto de um dos seus pilotos (mesma linguagem do cartão da corrida).
func _player_panel(car: CarState) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size.x = CarControlPanel.WIDTH
	card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	card.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_GLASS, 20, 12, 10))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 7)
	card.add_child(v)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	var photo := Control.new()
	photo.custom_minimum_size = Vector2(CarControlPanel.PHOTO, CarControlPanel.PHOTO)
	photo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	photo.add_child(DriverPhotos.make_avatar(car.driver, car.team_color(), CarControlPanel.PHOTO))
	var logo := TeamEmblems.make_rect(String(car.team["id"]), 26)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	photo.add_child(logo)
	logo.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	logo.grow_vertical = Control.GROW_DIRECTION_BEGIN
	logo.offset_left = -4
	logo.offset_bottom = 3
	# tocar na foto segue esse carro na pista (de novo: volta à vista geral)
	var cam := Button.new()
	cam.flat = true
	cam.focus_mode = Control.FOCUS_NONE
	for st: String in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		cam.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	cam.tooltip_text = "Seguir na pista"
	photo.add_child(cam)
	cam.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cam.pressed.connect(func() -> void: _toasts.push("Câmera: " + _view.follow(car)))
	head.add_child(photo)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", -2)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var full := car.display_name()
	var surname := UiStyle.g_label(full.get_slice(" ", full.get_slice_count(" ") - 1), 18, UiStyle.G_TEXT, "black")
	surname.clip_text = true
	surname.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	names.add_child(surname)
	var pos_row := HBoxContainer.new()
	pos_row.add_theme_constant_override("separation", 6)
	var pos := UiStyle.g_label("P–", 17, UiStyle.RED, "black")
	pos_row.add_child(pos)
	var num := UiStyle.g_label("#%d" % int(car.driver["number"]), 12, UiStyle.G_TEXT_3, "bold")
	num.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pos_row.add_child(num)
	names.add_child(pos_row)
	var status := UiStyle.g_label("", 12, UiStyle.G_TEXT_2, "bold")
	status.clip_text = true
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	names.add_child(status)
	head.add_child(names)
	v.add_child(head)

	var lap := UiStyle.g_label("", 12, Color("#c3c9d3"))
	lap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(lap)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 8)
	bar.add_theme_stylebox_override("background", UiStyle.g_box(Color(1, 1, 1, 0.12), 4, 0, 0))
	bar.add_theme_stylebox_override("fill", UiStyle.g_box(Color("#c77dff"), 4, 0, 0))
	v.add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var tyres := _tyre_tiles(row, car)
	v.add_child(row)
	var go := CutButton.new()
	go.custom_minimum_size = Vector2(0, 48)
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.clip_text = true
	for st: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var e := StyleBoxEmpty.new()
		e.content_margin_left = 12
		e.content_margin_right = 8
		go.add_theme_stylebox_override(st, e)
	go.add_theme_constant_override("icon_max_width", 18)
	go.add_theme_constant_override("h_separation", 6)
	go.add_theme_font_size_override("font_size", UiStyle.fs(13))
	v.add_child(go)
	var panel := {"car": car, "pos": pos, "status": status, "tyres": tyres, "go": go, "bar": bar, "lap": lap, "row": row}
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
		badge.custom_minimum_size = Vector2(26, 26)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.set_compound(c["letter"], Color(c["color"]))
		b.add_child(badge)
		badge.anchor_left = 0.5
		badge.anchor_right = 0.5
		badge.anchor_top = 0.5
		badge.anchor_bottom = 0.5
		badge.offset_left = -13
		badge.offset_right = 13
		badge.offset_top = -13
		badge.offset_bottom = 13
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
	_sub.text = "%s · %s" % [weekend.circuit["grand_prix"], ("%d avançam" % adv) if adv > 0 else "disputa da pole"]
	if q.is_over():
		_clock.text = "FIM"
		_clock_caption.text = "CLASSIFICAÇÃO ENCERRADA"
	elif q.is_red_flag():
		_clock.text = "BANDEIRA VERMELHA"
		_clock_caption.text = "RELÓGIO PARADO"
	else:
		_clock.text = "%s %s" % [seg["name"], ScreenKit.clock(q.time_left_s())]
		_clock_caption.text = "TEMPO RESTANTE"
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
	_table.set_cut_line(adv - 1 if adv > 0 and adv < active and not q.is_over() else -1)
	_cut_info.text = "" if adv <= 0 or q.is_over() else "Linha vermelha: zona de eliminação (%dº–%dº)" % [adv + 1, active]
	_evolution.text = "Pista evoluindo: +%s s nesta parte. Quem sair no fim ganha até %s s de borracha, mas arrisca tráfego, bandeira vermelha ou chuva." % [
		String.num(q.track_evolution_s(), 2).replace(".", ","), String.num(QualiSim.EVOLUTION_S + QualiSim.SEGMENT_EVOLUTION_S * q.segment, 1).replace(".", ",")]
	if q.weather.wetness > 0.1:
		_evolution.text += " Pista %s." % q.weather.surface_label().to_lower()
	for p: Dictionary in _panels:
		_refresh_panel(p, order)
	_end_card.visible = q.is_over()
	_info_card.visible = not q.is_over()


func _refresh_panel(p: Dictionary, order: Array[CarState]) -> void:
	var car: CarState = p["car"]
	(p["pos"] as Label).text = "P%d" % (order.find(car) + 1)
	var state := q.status_of(car)
	var garage := state == "Garagem"
	var running := state in ["Volta de saída", "Volta lançada", "Volta de entrada"]
	(p["status"] as Label).text = state
	var lap: Label = p["lap"]
	var bar: ProgressBar = p["bar"]
	bar.visible = running
	(p["row"] as Control).visible = garage
	if garage:
		lap.text = "%d jogo(s) de macios novos" % q.new_softs[car]
		if car.last_lap_time > 0.0:
			lap.text += " · última: %s" % UiStyle.format_time(car.last_lap_time)
	elif running:
		bar.value = q.render_distance(car) / q.track.length_m * 100.0
		var c: Dictionary = q.tyres.compounds[car.tyre]
		lap.text = "%s · %d%% da volta" % [c["name"], roundi(bar.value)]
		var flying := state == "Volta lançada"
		bar.add_theme_stylebox_override("fill", UiStyle.g_box(Color("#c77dff") if flying else Color("#8f98a7"), 4, 0, 0))
	else:
		lap.text = state
	var go: Button = p["go"]
	go.disabled = not q.can_go_out(car)
	if garage:
		go.text = "SAIR PARA VOLTA RÁPIDA" if q.time_left_s() > 0.0 else "TEMPO ESGOTADO"
	elif running:
		go.text = "EM ANDAMENTO"
	else:
		go.text = state.to_upper()


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
	var st := UiStyle.g_box(UiStyle.G_LIGHT, 20, 24, 14)
	st.border_width_left = 7
	st.border_color = UiStyle.RED
	card.add_theme_stylebox_override("panel", st)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	card.add_child(h)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UiStyle.g_label("CLASSIFICAÇÃO ENCERRADA", 20, UiStyle.G_INK, "black"))
	v.add_child(UiStyle.g_label("A tabela mostra o grid de largada.", 14, UiStyle.G_INK_2))
	h.add_child(v)
	var go := CutButton.new()
	go.text = "CONTINUAR"
	go.custom_minimum_size = Vector2(190, UiStyle.TOUCH_MAIN)
	go.pressed.connect(func() -> void:
		weekend.finish_quali(q)
		Session.go_to_weekend())
	h.add_child(go)
	return card


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.go_to_weekend()
