extends Control
## Tela de corrida — direção Garagem (mockup v7): barra de topo, pista 3D grande com cantos
## arredondados, dois cartões dos seus carros e a torre de cronometragem à direita.
##
## A cada quadro, avança a simulação pelo tempo real × velocidade escolhida. A tabela e os
## painéis são atualizados algumas vezes por segundo (não a cada quadro) para poupar bateria.
## "Chamar p/ box" abre a tela do box (PitScreen) sem pausar; durante a parada, o mini-jogo de
## toque (PitTapOverlay) vale tempo no box.

const UI_REFRESH_S := 0.2
const SPEEDS := [1.0, 2.0, 4.0, 8.0]
const FAST_TIME := 4.0  ## a partir desta velocidade a câmera 3D vai para a vista geral
const PIT_MAX_SCALE := 2.0  ## com a tela do box aberta a corrida roda no máximo a 2×

var sim: RaceSim
var weekend: WeekendSim = null  ## Grande Prêmio em andamento (null = corrida rápida)
var time_scale := 2.0
var paused := false
var _audio: RaceAudio

var _layer: Control
var _track_holder: Panel
var _track_view: TrackView3D
var _standings: StandingsPanel
var _car_panels: Array[CarControlPanel] = []
var _toasts: ToastFeed
var _radar: RadarWidget
var _radio: RadioCard
var _drawer: DataDrawer
var _meta: Label
var _lap_label: Label
var _flag_pill: PanelContainer
var _flag_label: Label
var _speed_seg: PanelContainer
var _pause_btn: Button
var _refresh_timer := 0.0
var _results_shown := false
var _pit: PitScreen = null
var _tap: PitTapOverlay = null
var _scale_before_stop := 0.0  ## velocidade antes de a parada forçar 1×


func _ready() -> void:
	weekend = Session.weekend if Session.weekend != null and Session.weekend.is_race(Session.weekend.session_id()) else null
	if weekend != null:
		# Grande Prêmio: grid da classificação, acerto dos treinos, sprint ou corrida
		sim = weekend.make_race()
	else:
		var options := {"duration_pct": Session.duration_pct, "seed": Session.race_seed, "player_team": Session.player_team}
		options.merge(Session.sim_overrides, true)
		sim = RaceSim.new(
			TrackModel.new(GameData.circuit(Session.circuit_id)),
			TyreModel.new(GameData.tyres()),
			GameData.teams(), GameData.drivers(), options)
	if Session.debug_advance_s > 0.0:
		sim.advance(Session.debug_advance_s)
	if Session.debug_sc:
		sim.control.deploy_sc("teste de captura")
		sim.advance(40.0)
	_build_ui()
	_audio = RaceAudio.new()
	add_child(_audio)
	_audio.setup(sim)
	_audio.time_scale = time_scale
	_audio.set_paused(paused)
	if Session.debug_view_only:  # (capturas: só o 3D, base dos mockups de interface)
		_track_view.reparent(self)
		_track_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for c in get_children():
			if c != _track_view and c is CanvasItem:
				c.visible = false
	_drawer.visible = Session.debug_open_data
	_connect_sim_signals()
	_refresh_ui()
	if Session.debug_pit or Session.debug_tap:
		_debug_pit_state()
	_toasts.push("Luzes apagadas! %d voltas em %s." % [sim.total_laps, sim.track.short_name])
	if sim.is_over():  # (só acontece quando a corrida foi avançada antes de abrir a tela)
		_on_race_finished()


## Capturas: --pit abre a tela do box; --tap leva o 1º carro ao box e abre o mini-jogo.
func _debug_pit_state() -> void:
	var car := _car_panels[0].car
	if Session.debug_pit:
		_open_pit(car)
		return
	sim.request_pit(car, "hard")
	var guard := 0
	while not (car.in_pit and car.box_hold_s > 0.0) and guard < 6000:
		sim.advance(RaceSim.DT)
		guard += 1
	_on_pit_box_stop(car, car.box_hold_s)


func _build_ui() -> void:
	# fundo da Garagem na cor da equipe que o jogador gerencia (imersão)
	var page := ScreenKit.garage_page(self, _my_team_id())
	_layer = page["layer"]
	_build_top_bar()

	# pista 3D: cantos arredondados (o recorte vale para os filhos)
	_track_holder = Panel.new()
	_track_holder.add_theme_stylebox_override("panel", UiStyle.g_box(Color.BLACK, 22, 0, 0))
	_track_holder.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	ScreenKit.place(_track_holder, _layer, Control.PRESET_TOP_LEFT, Vector2(16, 58), Vector2(916, 462))
	_track_view = TrackView3D.new()
	_track_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_track_holder.add_child(_track_view)
	_track_view.setup(sim)
	if Session.debug_camera.size() > 0:  # (opções de desenvolvimento para capturas)
		_track_view.yaw = Session.debug_camera.get("yaw", _track_view.yaw)
		_track_view.pitch = Session.debug_camera.get("pitch", _track_view.pitch)
		_track_view.distance = Session.debug_camera.get("dist", _track_view.distance)
		for i in int(Session.debug_camera.get("mode", 0)):
			_track_view.cycle_camera()
		if Session.debug_camera.has("dist"):
			_track_view.distance = Session.debug_camera["dist"]
		_track_view.snap_camera = true  # captura: câmera já no alvo, sem deslizar

	_toasts = ToastFeed.new()
	_toasts.position = Vector2(14, 14)
	_toasts.custom_minimum_size = Vector2(380, 0)
	_track_holder.add_child(_toasts)
	_radar = RadarWidget.new()
	_radar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_radar.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_radar.offset_right = -14
	_radar.offset_top = 14
	_track_holder.add_child(_radar)
	_radar.setup(sim)
	_radio = RadioCard.new()
	_radio.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_radio.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_radio.offset_left = 14
	_radio.offset_bottom = -14
	_track_holder.add_child(_radio)
	_radio.answered.connect(func(id: int, option: int) -> void:
		sim.radio.answer(id, option)
		_refresh_ui())
	_drawer = DataDrawer.new()
	_drawer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_drawer.visible = false
	_track_holder.add_child(_drawer)
	_drawer.setup(sim)
	_drawer.closed.connect(func() -> void: _drawer.visible = false)

	# cartões dos seus carros
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 16)
	ScreenKit.place(cards, _layer, Control.PRESET_TOP_LEFT, Vector2(16, 530))
	for car in sim.cars:
		if car.is_player:
			var p := CarControlPanel.new()
			p.custom_minimum_size = Vector2(450, 178)
			cards.add_child(p)
			p.setup(sim, car)
			p.pit_pressed.connect(_open_pit)
			p.orders_pressed.connect(_open_orders)
			_car_panels.append(p)

	# torre: tocar numa linha segue aquele carro; tocar de novo volta à vista geral
	_standings = StandingsPanel.new()
	ScreenKit.place(_standings, _layer, Control.PRESET_TOP_RIGHT, Vector2(-16, 58), Vector2(320, 650))
	_standings.setup(sim)
	_standings.driver_pressed.connect(_on_driver_pressed)


func _my_team_id() -> String:
	for car in sim.cars:
		if car.is_player:
			return String(car.team["id"])
	return Session.player_team


func _build_top_bar() -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 14)
	ScreenKit.place(bar, _layer, Control.PRESET_TOP_LEFT, Vector2(16, 6), Vector2(1248, 48))
	var title := UiStyle.g_label(("SPRINT · " if sim.sprint else "") + sim.track.grand_prix.to_upper(), 24, UiStyle.G_TEXT, "black")
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_child(title)
	_meta = UiStyle.g_caption("")
	_meta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_child(_meta)
	bar.add_child(UiStyle.hspacer())

	_flag_pill = PanelContainer.new()
	_flag_pill.visible = false
	_flag_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_flag_label = UiStyle.g_label("", 14, UiStyle.G_INK, "black")
	_flag_pill.add_child(_flag_label)
	bar.add_child(_flag_pill)

	_pause_btn = Button.new()
	_pause_btn.toggle_mode = true
	_pause_btn.text = "II"
	_pause_btn.focus_mode = Control.FOCUS_NONE
	_pause_btn.custom_minimum_size = Vector2(UiStyle.TOUCH_MIN, 40)
	_pause_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ScreenKit._selectable_styles(_pause_btn, 20)
	_pause_btn.add_theme_stylebox_override("normal", UiStyle.g_box(UiStyle.G_SURFACE, 20, 10, 0))
	_pause_btn.toggled.connect(func(on: bool) -> void:
		paused = on
		if _audio != null:
			_audio.set_paused(on))
	_pause_btn.button_pressed = Session.debug_pause
	bar.add_child(_pause_btn)
	_speed_seg = ScreenKit.segmented(SPEEDS.map(func(s: float) -> Array: return [s, "%d×" % int(s)]), time_scale, set_time_scale)
	_speed_seg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for b: Control in (_speed_seg.get_child(0) as Control).get_children():
		b.custom_minimum_size = Vector2(46, 34)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar.add_child(_speed_seg)

	# som da corrida: liga/desliga (vale até fechar o jogo)
	var snd := ScreenKit.round_button("mute" if RaceAudio.muted else "sound", 40, "Som")
	snd.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	snd.pressed.connect(func() -> void:
		_audio.set_muted(not RaceAudio.muted)
		snd.icon = load("res://assets/icons/%s.svg" % ("mute" if RaceAudio.muted else "sound")))
	bar.add_child(snd)

	var data := Button.new()
	data.text = "Dados"
	data.focus_mode = Control.FOCUS_NONE
	data.custom_minimum_size = Vector2(84, 40)
	data.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
		data.add_theme_stylebox_override(s, UiStyle.g_box(UiStyle.G_SURFACE_HOVER if s != "pressed" else UiStyle.G_SURFACE_PRESS, 20, 16, 0))
	data.add_theme_font_size_override("font_size", UiStyle.fs(14))
	data.pressed.connect(func() -> void:
		_drawer.visible = not _drawer.visible
		_drawer.refresh())
	ScreenKit.press_feedback(data)
	bar.add_child(data)

	_lap_label = UiStyle.g_label("", 30, UiStyle.RED, "black")
	_lap_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_lap_label.custom_minimum_size = Vector2(96, 0)
	_lap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bar.add_child(_lap_label)
	var menu := ScreenKit.round_button("back", 40, "Menu")
	menu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	menu.pressed.connect(Session.go_to_title)
	bar.add_child(menu)


func _connect_sim_signals() -> void:
	sim.overtake.connect(_on_overtake)
	sim.pit_stop.connect(_on_pit_stop)
	sim.pit_box_stop.connect(_on_pit_box_stop)
	sim.fastest_lap.connect(_on_fastest_lap)
	sim.race_finished.connect(_on_race_finished)
	sim.incident.connect(_on_incident)
	sim.flag_changed.connect(_on_flag_changed)
	sim.penalty.connect(_on_penalty)
	sim.team_order_result.connect(_on_team_order)
	sim.radio_message.connect(_on_radio_message)


func set_time_scale(s: float) -> void:
	# com o box aberto ou o carro parado a corrida fica em 1×/2× (o jogador precisa agir)
	if (_pit != null or _tap != null) and s > PIT_MAX_SCALE:
		s = PIT_MAX_SCALE
	if _tap != null:
		s = 1.0
	time_scale = s
	if _audio != null:
		_audio.time_scale = s
	if _pit != null:
		_pit.current_scale = s
	_sync_speed()
	var label := _track_view.set_fast_time(s >= FAST_TIME)
	if label != "":
		_toasts.push("Câmera: " + label)


## Os botões de velocidade acompanham o valor real (ele pode ser limitado pelo box).
func _sync_speed() -> void:
	for b: Button in (_speed_seg.get_child(0) as Control).get_children():
		b.set_pressed_no_signal(is_equal_approx(float(b.get_meta("value")), time_scale))
		b.disabled = (_pit != null or _tap != null) and float(b.get_meta("value")) > PIT_MAX_SCALE


func _process(delta: float) -> void:
	if not paused and not sim.is_over():
		sim.advance(delta * time_scale)
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = UI_REFRESH_S
		_refresh_ui()


func _refresh_ui() -> void:
	_lap_label.text = "FIM" if sim.chequered else "%d/%d" % [sim.leader_lap(), sim.total_laps]
	var rain := sim.weather.rain_label()
	_meta.text = "%s · %d voltas · %s" % [sim.track.short_name, sim.total_laps, ("pista " + sim.weather.surface_label()) if rain == "sem chuva" else rain]
	_refresh_flag()
	_standings.followed = _track_view.followed if _track_view.cam_mode == TrackView3D.CamMode.CAR else null
	_standings.refresh()
	_radar.refresh()
	_drawer.refresh()
	var question := {}
	for p in _car_panels:
		var q := sim.radio.pending_for(p.car)
		if not q.is_empty() and (question.is_empty() or int(q["id"]) < int(question["id"])):
			question = q
	_radio.show_message(question)
	var order := sim.standings()
	for p in _car_panels:
		p.refresh(order.find(p.car) + 1)


## Selo de bandeira na barra de topo (some com a pista liberada).
func _refresh_flag() -> void:
	var f := sim.control.flag
	_flag_pill.visible = f != RaceControl.Flag.GREEN
	if not _flag_pill.visible:
		return
	var red := f == RaceControl.Flag.RED
	var fill := UiStyle.RED if red else Color("#ffd24a")
	_flag_pill.add_theme_stylebox_override("panel", UiStyle.g_box(fill, 20, 16, 8))
	_flag_label.add_theme_color_override("font_color", Color.WHITE if red else UiStyle.G_INK)
	_flag_label.text = {RaceControl.Flag.SC: "SAFETY CAR", RaceControl.Flag.VSC: "VIRTUAL SC", RaceControl.Flag.RED: "BANDEIRA VERMELHA"}[f]


# --- câmera pela torre ----------------------------------------------------------------

func _on_driver_pressed(car: CarState) -> void:
	_toasts.push("Câmera: " + _track_view.follow(car))
	_refresh_ui()


# --- ordens de equipe (popover do botão EQUIPE) ---------------------------------------

func _open_orders(car: CarState, anchor: Control) -> void:
	var opts := [
		[CarState.TeamOrder.FREE, "Liberado"],
		[CarState.TeamOrder.HOLD, "Não brigar com o companheiro"],
		[CarState.TeamOrder.LET_BY, "Deixar o companheiro passar"],
	]
	ScreenKit.popover(self, anchor, "Ordem de equipe · %s" % car.code(), opts, car.team_order,
		func(o: int) -> void:
			sim.set_team_order(car, o)
			_refresh_ui())


# --- tela do box -----------------------------------------------------------------------

func _open_pit(car: CarState) -> void:
	if _pit != null or car.finished or car.retired or car.in_pit:
		return
	_pit = PitScreen.new()
	_pit.current_scale = minf(time_scale, PIT_MAX_SCALE)
	_pit.setup(sim, car, _track_view, _track_holder)
	_pit.closed.connect(_on_pit_closed)
	_pit.speed_requested.connect(set_time_scale)
	_layer.add_child(_pit)
	set_time_scale(minf(time_scale, PIT_MAX_SCALE))


func _on_pit_closed() -> void:
	_pit = null
	_sync_speed()
	_refresh_ui()


## O carro do jogador parou no box: abre o mini-jogo de toque (a corrida fica em 1×).
func _on_pit_box_stop(car: CarState, hold_s: float) -> void:
	if not car.is_player or _tap != null or hold_s <= 0.0:
		return
	_scale_before_stop = time_scale
	_tap = PitTapOverlay.new()
	_tap.setup(sim, car)
	_tap.finished.connect(_on_tap_finished)
	_layer.add_child(_tap)
	set_time_scale(1.0)


func _on_tap_finished() -> void:
	_tap = null
	set_time_scale(_scale_before_stop if _scale_before_stop > 0.0 else time_scale)
	_sync_speed()


# --- avisos (pop-ups não intrusivos) -------------------------------------------------

func _surname(car: CarState) -> String:
	return StandingsPanel.surname(car.display_name())


func _on_overtake(att: CarState, def: CarState, zone: String) -> void:
	var order := sim.standings()
	var new_pos := order.find(att) + 1
	if att.is_player or def.is_player:
		_toasts.push("%s passa %s! P%d" % [_surname(att), _surname(def), new_pos], "hot")
	elif new_pos == 1:
		_toasts.push("%s assume a liderança (%s)" % [_surname(att), zone])


func _on_pit_stop(car: CarState, compound: String, stationary: float) -> void:
	if car.is_player:
		_toasts.push("Box: %s coloca %s (%.1f s parado)" % [_surname(car), sim.tyres.compounds[compound]["name"], stationary])


func _on_fastest_lap(car: CarState, lap_time: float) -> void:
	if sim.leader_lap() > 3:
		_toasts.push("Volta mais rápida: %s — %s" % [_surname(car), UiStyle.format_time(lap_time)])


func _on_incident(car: CarState, kind: String, text: String) -> void:
	var important := car.is_player or kind in ["crash", "failure", "contact", "investigation", "cleared"] or sim.standings().find(car) < 5
	if important:
		_toasts.push(text, "hot" if car.is_player or kind == "crash" else "note")


func _on_flag_changed(_flag: int, text: String) -> void:
	_toasts.push(text, "hot")


func _on_penalty(car: CarState, kind: String, reason: String) -> void:
	_toasts.push("Punição para %s: %s (%s)" % [_surname(car), kind, reason], "hot" if car.is_player else "note")


func _on_team_order(car: CarState, _obeyed: bool, text: String) -> void:
	if car.is_player:
		_toasts.push("Rádio — " + text)


func _on_radio_message(m: Dictionary) -> void:
	if m["kind"] == "info":
		_toasts.push("Rádio — " + m["text"])
	_refresh_ui()


func _on_race_finished() -> void:
	if _results_shown:
		return
	_results_shown = true
	_refresh_ui()
	_layer.add_child(_build_results())


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:  # botão "voltar" do Android
		Session.go_to_title()


# --- resultado final -----------------------------------------------------------------

## Grande Prêmio: registra o resultado e os pontos e volta ao painel do fim de semana.
func _continue_weekend() -> void:
	weekend.finish_race(sim)
	Session.go_to_weekend()


func _build_results() -> Control:
	var order := sim.standings()
	var winner := order[0]
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.66)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	var panel := PanelContainer.new()
	var st := UiStyle.g_box(Color("#17191e"), 22, 26, 20)
	st.shadow_color = Color(0, 0, 0, 0.45)
	st.shadow_size = 18
	panel.add_theme_stylebox_override("panel", st)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	head.add_child(DriverPhotos.make_avatar(winner.driver, winner.team_color(), 56))
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -2)
	titles.add_child(UiStyle.g_caption("Resultado da sprint" if sim.sprint else "Resultado final"))
	titles.add_child(UiStyle.g_label("%s venceu" % winner.display_name(), 24, UiStyle.G_TEXT, "black"))
	head.add_child(titles)
	head.add_child(UiStyle.hspacer())
	head.add_child(UiStyle.g_label(sim.track.grand_prix.to_upper(), 20, UiStyle.RED, "black"))
	v.add_child(head)

	var scroll := DragScroll.new()
	scroll.custom_minimum_size = Vector2(900, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var table := TimingTable.new()
	table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(table)
	table.setup([
		{"title": "Pos", "width": 34, "kind": "pos"},
		{"title": "Piloto", "width": 0, "heavy": true},
		{"title": "Equipe", "width": 120},
		{"title": "Tempo / dif.", "width": 210, "align": "right"},
		{"title": "Paradas", "width": 62, "align": "right"},
		{"title": "Melhor volta", "width": 104, "align": "right"},
		{"title": "Pts", "width": 38, "align": "right"},
	], sim.cars.size(), "garage")
	table.me_color = winner.team_color() if winner.is_player else _my_color()
	for i in order.size():
		var car := order[i]
		var pos := "DSQ" if car.disqualified else ("–" if car.retired else str(i + 1))
		var gap: String
		if car.retired:
			gap = "Abandono (%s)" % car.retire_reason
		elif i == 0:
			gap = UiStyle.format_time(car.finish_time)
		elif sim.laps_behind_leader(car) > 0:
			gap = "+%d volta(s)" % sim.laps_behind_leader(car)
		else:
			gap = "+%.3f s" % sim.gap_to_leader_s(car)
		if car.penalty_pending_s > 0.0 and car.finished:
			gap += "  (inclui +%ds)" % int(car.penalty_pending_s)
		var best := UiStyle.format_time(car.best_lap_time)
		if car == sim.fastest_lap_car:
			best = "★ " + best
		var out := car.retired or car.disqualified
		table.set_row_style(i, "me" if car.is_player else ("out" if out else "normal"))
		table.set_pos(i, 0, pos, UiStyle.BAR_BG if out else car.team_color())
		table.set_text(i, 1, car.display_name())
		table.set_text(i, 2, car.team["name"])
		table.set_text(i, 3, gap)
		table.set_text(i, 4, str(car.pit_stops))
		table.set_text(i, 5, best)
		var pts := 0 if out else (weekend.points_for(i + 1, sim.sprint) if weekend != null else RaceSim.points_for(i + 1, sim.sprint))
		table.set_text(i, 6, str(pts) if pts > 0 else "")

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 12)
	var menu := ScreenKit.light_button("Menu")
	menu.custom_minimum_size = Vector2(130, UiStyle.TOUCH_MAIN)
	menu.pressed.connect(Session.go_to_title)
	buttons.add_child(menu)
	var main := CutButton.new()
	main.text = "CONTINUAR" if weekend != null else "CORRER DE NOVO"
	main.custom_minimum_size = Vector2(230, UiStyle.TOUCH_MAIN)
	main.pressed.connect(_continue_weekend if weekend != null else Session.restart_race)
	buttons.add_child(main)
	v.add_child(buttons)
	return shade


func _my_color() -> Color:
	for car in sim.cars:
		if car.is_player:
			return car.team_color()
	return UiStyle.RED

