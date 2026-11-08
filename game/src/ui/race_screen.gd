extends Control
## Tela de corrida — direção Garagem (mockup v14, estilo Motorsport Manager): a pista 3D ocupa a
## tela toda; por cima, a barra de topo, os dois cartões dos seus pilotos na vertical à esquerda e a
## torre de cronometragem à direita. O radar de chuva fica em DADOS > Clima (não tampa a pista).
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
var _track_holder: Control
var _track_view: TrackView3D
var _standings: StandingsPanel
var _car_panels: Array[CarControlPanel] = []
var _toasts: ToastFeed
var _weather_btn: Button
var _radio: RadioCard
var _drawer: DataDrawer
var _meta: Label
var _flag_pill: PanelContainer
var _flag_label: Label
var _speed_seg: PanelContainer
var _pause_btn: Button
var _refresh_timer := 0.0
var _results_shown := false
var _pit: PitScreen = null
var _tap: PitTapOverlay = null
var _scale_before_stop := 0.0  ## velocidade antes de a parada forçar 1×
var _champ: ChampionshipLive = null  ## campeonato ao vivo (só na campanha)
var _champ_card: ChampionshipCard
var _champ_lap := -1  ## volta do líder na última checagem
var _champ_shown_lap := -99  ## volta do último pop-up (no máximo 1 a cada CHAMP_EVERY voltas)
var _champ_last := {}  ## última ordem mostrada/considerada: {drivers: [...], teams: [...]}
var _champ_title := {}  ## último estado de "título em jogo": {drivers: id, teams: id}
const CHAMP_EVERY := 3
const CHAMP_TOP := 5
var _plan_box: VBoxContainer  ## avisos "hora de parar" da estratégia do jogador
var _plan_banners: Dictionary = {}  ## CarState -> {node, lap}
var _start_lights: StartLights = null  ## semáforo antes da largada (a corrida espera as luzes apagarem)


func _ready() -> void:
	weekend = Session.weekend if Session.weekend != null and Session.weekend.is_race(Session.weekend.session_id()) else null
	if weekend != null:
		# Grande Prêmio: grid da classificação, acerto dos treinos, sprint ou corrida
		sim = Session.pending_race if Session.pending_race != null else weekend.make_race()
		Session.pending_race = null
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
	if Session.debug_open_data:
		_drawer.open_tab(Session.debug_data_tab)
	_connect_sim_signals()
	_refresh_ui()
	if Session.debug_pit or Session.debug_tap:
		_debug_pit_state()
	if sim.time_s < 0.5 and Session.debug_advance_s <= 0.0 and not sim.is_over():
		_begin_start_lights()
	else:
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


const LEFT_W := CarControlPanel.WIDTH + 24.0  ## coluna dos seus pilotos (cartão + margens)
const TOWER_W := 266.0
const SIDE_TOP := 78.0


func _build_ui() -> void:
	# fundo da Garagem na cor da equipe que o jogador gerencia (aparece só se a pista falhar)
	var page := ScreenKit.garage_page(self, _my_team_id())
	_layer = page["layer"]

	# pista 3D em tela cheia, atrás de todo o resto
	_track_holder = Control.new()
	_layer.add_child(_track_holder)
	_track_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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

	ScreenKit.top_shade(_layer)
	_build_top_bar()

	_champ_card = ChampionshipCard.new()
	_champ_card.position = Vector2(300, 86)
	_layer.add_child(_champ_card)
	_setup_championship()
	_toasts = ToastFeed.new()
	_toasts.position = Vector2(LEFT_W + 14.0, SIDE_TOP + 6.0)
	_toasts.custom_minimum_size = Vector2(440, 0)
	_layer.add_child(_toasts)
	_plan_box = VBoxContainer.new()  # avisos da estratégia (v22-3), acima dos avisos rápidos
	_plan_box.add_theme_constant_override("separation", 8)
	_plan_box.position = Vector2(LEFT_W + 14.0, SIDE_TOP + 6.0)
	_plan_box.custom_minimum_size = Vector2(470, 0)
	_layer.add_child(_plan_box)

	# cartões dos seus pilotos: coluna vertical à esquerda
	var cards := VBoxContainer.new()
	cards.add_theme_constant_override("separation", 12)
	ScreenKit.place(cards, _layer, Control.PRESET_TOP_LEFT, Vector2(12, SIDE_TOP))
	for car in sim.cars:
		if car.is_player:
			var p := CarControlPanel.new()
			cards.add_child(p)
			p.setup(sim, car)
			p.pit_pressed.connect(_open_pit)
			p.orders_pressed.connect(_open_orders)
			p.focus_pressed.connect(_on_driver_pressed)  # tocar no cartão segue o piloto, como a linha da torre
			_car_panels.append(p)

	# torre: tocar numa linha segue aquele carro; tocar de novo volta à vista geral
	_standings = StandingsPanel.new()
	ScreenKit.place(_standings, _layer, Control.PRESET_TOP_RIGHT, Vector2(-12, SIDE_TOP), Vector2(TOWER_W, 720.0 - SIDE_TOP - 8.0))
	_standings.setup(sim)
	_standings.driver_pressed.connect(_on_driver_pressed)

	# rádio: faixa baixa no centro da área livre (contêineres alinham no rodapé sem esticar)
	var radio_area := MarginContainer.new()
	radio_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	radio_area.add_theme_constant_override("margin_left", int(LEFT_W))
	radio_area.add_theme_constant_override("margin_right", int(TOWER_W + 24.0))
	radio_area.add_theme_constant_override("margin_bottom", 12)
	_layer.add_child(radio_area)
	radio_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var radio_col := VBoxContainer.new()
	radio_col.alignment = BoxContainer.ALIGNMENT_END
	radio_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	radio_area.add_child(radio_col)
	var radio_row := HBoxContainer.new()
	radio_row.alignment = BoxContainer.ALIGNMENT_CENTER
	radio_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	radio_col.add_child(radio_row)
	_radio = RadioCard.new()
	_radio.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	radio_row.add_child(_radio)
	_radio.answered.connect(func(id: int, option: int) -> void:
		sim.radio.answer(id, option)
		_refresh_ui())

	# DADOS: painel sobre a área livre (não cobre os seus pilotos nem a torre)
	_drawer = DataDrawer.new()
	_layer.add_child(_drawer)
	_drawer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_drawer.offset_left = LEFT_W
	_drawer.offset_right = -(TOWER_W + 24.0)
	_drawer.offset_top = SIDE_TOP
	_drawer.offset_bottom = -12
	_drawer.visible = false
	_drawer.setup(sim)
	_drawer.closed.connect(func() -> void: _drawer.visible = false)


func _my_team_id() -> String:
	for car in sim.cars:
		if car.is_player:
			return String(car.team["id"])
	return Session.player_team


func _glass_pill(radius: int = 22, margin: int = 16) -> StyleBoxFlat:
	return UiStyle.g_box(UiStyle.G_GLASS, radius, margin, 0)


func _build_top_bar() -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE  # a barra não bloqueia o toque na pista
	ScreenKit.place(bar, _layer, Control.PRESET_TOP_LEFT, Vector2(12, 6), Vector2(1256, 60))
	var menu := ScreenKit.glass_round_button("back", 44, "Menu")
	menu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	menu.pressed.connect(Session.go_to_title)
	bar.add_child(menu)

	# nome do GP com a bandeira do país ao fundo (o contador de voltas fica só na torre)
	var cat_tag := "" if sim.category == "F1" else sim.category + (" · SPRINT · " if sim.sprint else " · PRINCIPAL · ")
	var head := ScreenKit.flag_title((cat_tag if cat_tag != "" else ("SPRINT · " if sim.sprint else "")) + sim.track.grand_prix.to_upper(), 20, sim.track.country_code)
	_meta = head["sub"]
	bar.add_child(head["box"])

	# pausa + velocidades numa pílula escura
	var speed_pill := PanelContainer.new()
	speed_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	speed_pill.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_GLASS, 24, 3, 3))
	var sh := HBoxContainer.new()
	sh.add_theme_constant_override("separation", 3)
	speed_pill.add_child(sh)
	_pause_btn = Button.new()
	_pause_btn.toggle_mode = true
	_pause_btn.text = "II"
	_pause_btn.focus_mode = Control.FOCUS_NONE
	_pause_btn.custom_minimum_size = Vector2(UiStyle.TOUCH_MIN, 40)
	ScreenKit._selectable_styles(_pause_btn, 20)
	_pause_btn.toggled.connect(func(on: bool) -> void:
		paused = on
		if _audio != null:
			_audio.set_paused(on))
	_pause_btn.button_pressed = Session.debug_pause
	sh.add_child(_pause_btn)
	_speed_seg = ScreenKit.segmented(SPEEDS.map(func(s: float) -> Array: return [s, "%d×" % int(s)]), time_scale, set_time_scale)
	_speed_seg.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	for b: Control in (_speed_seg.get_child(0) as Control).get_children():
		b.custom_minimum_size = Vector2(46, 40)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sh.add_child(_speed_seg)
	bar.add_child(speed_pill)

	# selo do clima: resume pista e previsão; tocar abre DADOS > Clima (onde está o radar)
	_weather_btn = Button.new()
	_weather_btn.focus_mode = Control.FOCUS_NONE
	_weather_btn.custom_minimum_size = Vector2(0, 44)
	_weather_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_weather_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_weather_btn.add_theme_constant_override("icon_max_width", 22)
	_weather_btn.add_theme_font_size_override("font_size", UiStyle.fs(13))
	for st: String in ["normal", "hover", "pressed", "hover_pressed"]:
		_weather_btn.add_theme_stylebox_override(st, _glass_pill())
	_weather_btn.pressed.connect(func() -> void: _drawer.open_tab(3))
	ScreenKit.press_feedback(_weather_btn)
	bar.add_child(_weather_btn)

	_flag_pill = PanelContainer.new()
	_flag_pill.visible = false
	_flag_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_flag_label = UiStyle.g_label("", 14, UiStyle.G_INK, "black")
	_flag_pill.add_child(_flag_label)
	bar.add_child(_flag_pill)

	var data := ScreenKit.glass_pill_button("Dados", 84)
	data.pressed.connect(func() -> void:
		_drawer.visible = not _drawer.visible
		_drawer.refresh())
	bar.add_child(data)

	# som da corrida: liga/desliga (vale até fechar o jogo)
	var snd := ScreenKit.glass_round_button("mute" if RaceAudio.muted else "sound", 44, "Som")
	snd.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	snd.pressed.connect(func() -> void:
		_audio.set_muted(not RaceAudio.muted)
		snd.icon = load("res://assets/icons/%s.svg" % ("mute" if RaceAudio.muted else "sound")))
	bar.add_child(snd)



func _connect_sim_signals() -> void:
	sim.overtake.connect(_on_overtake)
	sim.pit_stop.connect(_on_pit_stop)
	sim.plan_stop_due.connect(_on_plan_due)
	if Session.debug_ui == "plan":  # (captura) --ui=plan mostra o aviso da estratégia
		for c in sim.cars:
			if c.is_player:
				_on_plan_due.call_deferred(c, c.laps_done + 1, "hard", true)
				break
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


## Cinco luzes vermelhas acendem uma a uma; depois de uma espera curta e variável, apagam e a corrida começa.
func _begin_start_lights() -> void:
	_start_lights = StartLights.new()
	_layer.add_child(_start_lights)
	_start_lights.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_start_lights.position.y = SIDE_TOP + 8.0
	_start_lights.light_on.connect(func(_i: int) -> void: _audio.light_on())
	_start_lights.lights_out.connect(func() -> void:
		_audio.lights_out()
		_toasts.push("Luzes apagadas! %d voltas em %s." % [sim.total_laps, sim.track.short_name], "hot"))
	_start_lights.finished.connect(func() -> void: _start_lights = null)
	_start_lights.start(sim.rng.randf_range(0.4, 1.6))


func _process(delta: float) -> void:
	if _start_lights != null and not _start_lights.is_out():
		pass  # grid parado esperando as luzes apagarem
	elif not paused and not sim.is_over():
		sim.advance(delta * time_scale)
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = UI_REFRESH_S
		_refresh_ui()


func _refresh_ui() -> void:
	_update_plan_banners()
	var rain := sim.weather.rain_label()
	_meta.text = sim.track.short_name
	_weather_btn.text = " " + RadarWidget.chip_text(sim)
	_weather_btn.icon = load("res://assets/icons/%s.svg" % ("rain" if sim.weather.rain_now() > WeatherModel.RAIN_THRESHOLD else ("mixed" if rain != "sem chuva" else "sun")))
	_refresh_flag()
	_check_championship()
	# com o cartão do campeonato na tela, os avisos da corrida descem para não ficar por baixo dele
	var champ_on := _champ_card != null and _champ_card.visible and _champ_card.modulate.a > 0.05
	_toasts.position.y = SIDE_TOP + 6.0 + (_champ_card.size.y + 10.0 if champ_on else 0.0)
	_standings.followed = _track_view.followed if _track_view.cam_mode == TrackView3D.CamMode.CAR else null
	_standings.refresh()
	_drawer.refresh()
	var question := {}
	for p in _car_panels:
		var q := sim.radio.pending_for(p.car)
		if not q.is_empty() and (question.is_empty() or int(q["id"]) < int(question["id"])):
			question = q
	_radio.show_message(question)
	var order := sim.standings()
	var following := _track_view.followed if _track_view.cam_mode == TrackView3D.CamMode.CAR else null
	for p in _car_panels:
		p.refresh(order.find(p.car) + 1)
		p.set_followed(p.car == following)


# --- campeonato ao vivo (pop-ups "se terminar assim", só na campanha) ---------------------------

func _setup_championship() -> void:
	var camp: Campaign = Session.campaign
	if weekend == null or not weekend.campaign or camp == null:
		return
	var team_of := {}
	for d: Dictionary in camp.drivers():
		team_of[d["id"]] = d["team"]
	var rem := camp.remaining_after_current()
	var races := int(rem["races"]) + (1 if sim.sprint else 0)  # na sprint, a corrida do domingo ainda vem
	_champ = ChampionshipLive.new()
	_champ.setup(camp.driver_points, camp.team_points, team_of, weekend.points_sprint if sim.sprint else weekend.points_race,
		races, int(rem["sprints"]), weekend.points_race, weekend.points_sprint)
	_champ_last = {"drivers": _champ.before_order("drivers", CHAMP_TOP), "teams": _champ.before_order("teams", CHAMP_TOP)}


func _check_championship() -> void:
	if _champ == null or sim.is_over():
		return
	var lap := sim.leader_lap()
	if lap == _champ_lap or lap < 1:
		return
	_champ_lap = lap
	var order: Array = []
	var out := {}
	for c in sim.standings():
		order.append(c.driver["id"])
		if c.retired or c.disqualified:
			out[c.driver["id"]] = true
	var proj := _champ.project(order, out)
	var lap_text := "volta %d de %d" % [lap, sim.total_laps]
	# título em jogo: aparece na hora (sem esperar o intervalo) quando muda
	for kind: String in ["drivers", "teams"]:
		var cl := _champ.clinch(proj[kind], kind)
		var who := String(cl.get("id", ""))
		if who != String(_champ_title.get(kind, "")):
			_champ_title[kind] = who
			if who != "":
				_show_title(kind, cl, lap_text)
				_champ_shown_lap = lap
				return
	if lap - _champ_shown_lap < CHAMP_EVERY:
		return
	for kind: String in ["drivers", "teams"]:
		var top: Array = (proj[kind] as Array).slice(0, CHAMP_TOP).map(func(r: Array) -> String: return r[0])
		if top != _champ_last[kind]:
			var before: Array = _champ_last[kind]
			_champ_last[kind] = top
			_champ_shown_lap = lap
			_show_standings(kind, proj[kind], before)
			return


func _champ_drivers() -> Dictionary:
	var out := {}
	for d: Dictionary in Session.campaign.drivers():
		out[d["id"]] = d
	return out


func _show_standings(kind: String, rows: Array, before: Array) -> void:
	var colors := {}
	for t: Dictionary in Session.campaign.teams():
		colors[t["id"]] = Color(t["color"])
	var mine: Array = []
	for c in sim.cars:
		if c.is_player:
			mine.append(c.driver["id"] if kind == "drivers" else c.team["id"])
	var names := _champ_drivers()
	var lead := int(rows[0][2]) - int(rows[1][2]) if rows.size() > 1 else 0
	var leader: String = String(names.get(rows[0][0], {}).get("name", rows[0][0])) if kind == "drivers" else String(GameData.team_by_id(Session.campaign.teams(), rows[0][0]).get("name", ""))
	var left := _champ.max_remaining() * (2 if kind == "teams" else 1)
	var msg := "%s lidera por %d ponto%s · ainda restam %d em disputa" % [leader.get_slice(" ", leader.get_slice_count(" ") - 1) if kind == "drivers" else leader, lead, "" if lead == 1 else "s", left]
	_champ_card.show_standings(kind, rows, before, names, colors, mine, msg)


func _show_title(kind: String, cl: Dictionary, lap_text: String) -> void:
	var names := _champ_drivers()
	if kind == "drivers":
		var d: Dictionary = names.get(cl["id"], {})
		var rival := String(names.get(cl["rival"], {}).get("name", ""))
		_champ_card.show_title(String(d.get("name", "")), d, UiStyle.team_color_from(Session.campaign.teams(), String(d.get("team", ""))), lap_text,
			"Vantagem projetada de %d pontos; restam %d em disputa." % [int(cl["lead"]), int(cl["left"])],
			"%s não alcança mais, se a corrida terminar assim." % rival.get_slice(" ", rival.get_slice_count(" ") - 1), false)
	else:
		var t := GameData.team_by_id(Session.campaign.teams(), String(cl["id"]))
		var rt := GameData.team_by_id(Session.campaign.teams(), String(cl["rival"]))
		_champ_card.show_title(String(t.get("name", "")), {}, Color(t.get("color", "#888888")), lap_text,
			"Vantagem projetada de %d pontos; restam %d em disputa." % [int(cl["lead"]), int(cl["left"])],
			"%s não alcança mais nos construtores." % String(rt.get("name", "")), true, String(cl["id"]))


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


## Estratégia do jogador: a volta planejada chegou. Só avisa; a parada acontece se o jogador mandar para o box.
func _on_plan_due(car: CarState, lap: int, compound: String, fresh: bool) -> void:
	_close_plan_banner(car)
	var c: Dictionary = sim.tyres.compounds[compound]
	var card := PanelContainer.new()
	var st := UiStyle.g_box(UiStyle.G_LIGHT, 18, 16, 10)
	st.border_width_left = 6
	st.border_color = UiStyle.RED
	card.add_theme_stylebox_override("panel", st)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	card.add_child(h)
	var badge := TyreBadge.new()
	badge.custom_minimum_size = Vector2(40, 40)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.set_compound(c["letter"], Color(c["color"]))
	h.add_child(badge)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UiStyle.g_caption("Plano · volta %d" % lap, UiStyle.G_INK_2))
	v.add_child(UiStyle.g_label("%s: hora de parar" % _surname(car), 18, UiStyle.G_INK, "black"))
	var sub := UiStyle.g_label("Plano: %s %s. Toque em P/ BOX para decidir." % [c["name"], "novo" if fresh else "usado"], UiStyle.FS_CAPTION, UiStyle.G_INK_2, "bold")
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(sub)
	h.add_child(v)
	var later := ScreenKit.light_button("DEPOIS")
	later.custom_minimum_size = Vector2(100, UiStyle.TOUCH_MIN)
	later.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	later.pressed.connect(_close_plan_banner.bind(car))
	h.add_child(later)
	_plan_box.add_child(card)
	_plan_banners[car] = {"node": card, "lap": lap}


func _close_plan_banner(car: CarState) -> void:
	if _plan_banners.has(car):
		(_plan_banners[car]["node"] as Control).queue_free()
		_plan_banners.erase(car)


## O aviso some quando o carro vai para o box ou quando a volta planejada passa.
func _update_plan_banners() -> void:
	for car: CarState in _plan_banners.keys():
		if car.pit_requested or car.in_pit or car.retired or car.finished or car.laps_done >= int(_plan_banners[car]["lap"]):
			_close_plan_banner(car)


func _on_pit_stop(car: CarState, compound: String, stationary: float) -> void:
	if car.is_player:
		_toasts.push("Box: %s coloca %s (%.1f s parado)" % [_surname(car), sim.tyres.compounds[compound]["name"], stationary])


func _on_fastest_lap(car: CarState, lap_time: float) -> void:
	if sim.leader_lap() > 3:
		_toasts.push("Volta mais rápida: %s — %s" % [_surname(car), UiStyle.format_time(lap_time)])


func _on_incident(car: CarState, kind: String, text: String) -> void:
	var important := car.is_player or kind in ["crash", "failure", "issue", "contact", "investigation", "cleared"] or sim.standings().find(car) < 5
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
	_radio.visible = false
	_drawer.visible = false
	# pódio animado primeiro (com a torcida); o botão dele abre a tabela completa
	var order := sim.standings()
	var top3: Array[CarState] = []
	for car in order:
		if top3.size() < 3 and car.finished and not car.disqualified:
			top3.append(car)
	if top3.is_empty() or Session.debug_skip_podium:
		_layer.add_child(_build_results())
		return
	var podium := PodiumView.new()
	_layer.add_child(podium)
	podium.setup(top3, ("Sprint · " if sim.sprint else "") + sim.track.grand_prix)
	podium.done.connect(func() -> void: _layer.add_child(_build_results()))


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

