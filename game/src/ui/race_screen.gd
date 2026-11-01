extends Control
## Tela de corrida: liga a simulação à interface (pista, tabela, painéis e avisos).
##
## A cada quadro, avança a simulação pelo tempo real × velocidade escolhida.
## A tabela e os painéis são atualizados algumas vezes por segundo (não a cada quadro)
## para economizar bateria no celular.

const LOGO := preload("res://assets/branding/logo.svg")
const UI_REFRESH_S := 0.2
const SPEEDS := [1.0, 2.0, 4.0, 8.0]

var sim: RaceSim
var time_scale := 2.0
var paused := false

var _track_view: TrackView
var _standings: StandingsPanel
var _car_panels: Array[CarControlPanel] = []
var _toasts: ToastFeed
var _lap_label: Label
var _refresh_timer := 0.0
var _results_shown := false


func _ready() -> void:
	theme = UiStyle.make_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	sim = RaceSim.new(
		TrackModel.new(GameData.circuit(Session.circuit_id)),
		TyreModel.new(GameData.tyres()),
		GameData.teams(), GameData.drivers(),
		{"duration_pct": Session.duration_pct, "seed": Session.race_seed, "player_team": Session.player_team})
	if Session.debug_advance_s > 0.0:
		sim.advance(Session.debug_advance_s)
	_build_ui()
	_connect_sim_signals()
	_refresh_ui()
	_toasts.push("Luzes apagadas! %d voltas em %s." % [sim.total_laps, sim.track.short_name], UiStyle.GOOD)
	if sim.is_over():  # (só acontece quando a corrida foi avançada antes de abrir a tela)
		_on_race_finished()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = UiStyle.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 8
	root.offset_top = 6
	root.offset_right = -8
	root.offset_bottom = -8
	add_child(root)
	root.add_child(_build_top_bar())

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(left)

	var track_holder := Control.new()
	track_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	track_holder.clip_contents = true
	left.add_child(track_holder)
	_track_view = TrackView.new()
	_track_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	track_holder.add_child(_track_view)
	_track_view.setup(sim)
	_toasts = ToastFeed.new()
	_toasts.position = Vector2(10, 10)
	_toasts.custom_minimum_size = Vector2(360, 0)
	track_holder.add_child(_toasts)

	var panels := HBoxContainer.new()
	left.add_child(panels)
	for car in sim.cars:
		if car.is_player:
			var p := CarControlPanel.new()
			panels.add_child(p)
			p.setup(sim, car)
			_car_panels.append(p)

	_standings = StandingsPanel.new()
	body.add_child(_standings)
	_standings.setup(sim)


func _build_top_bar() -> Control:
	var bar := HBoxContainer.new()
	bar.custom_minimum_size = Vector2(0, 44)
	var logo := TextureRect.new()
	logo.texture = LOGO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	logo.custom_minimum_size = Vector2(110, 40)
	bar.add_child(logo)
	bar.add_child(UiStyle.label("%s · %s" % [sim.track.grand_prix, sim.track.short_name], 17, UiStyle.TEXT, true))
	bar.add_child(UiStyle.hspacer())
	_lap_label = UiStyle.label("", 18, UiStyle.ACCENT_2, true)
	bar.add_child(_lap_label)
	bar.add_child(UiStyle.hspacer())
	var group := ButtonGroup.new()
	var pause := UiStyle.button("II", true)
	pause.custom_minimum_size = Vector2(48, 40)
	pause.toggled.connect(func(on: bool) -> void: paused = on)
	bar.add_child(pause)
	for s: float in SPEEDS:
		var b := UiStyle.button("%d×" % int(s), true, group)
		b.custom_minimum_size = Vector2(48, 40)
		b.button_pressed = is_equal_approx(s, time_scale)
		b.pressed.connect(func() -> void: time_scale = s)
		bar.add_child(b)
	var menu := UiStyle.button("Menu")
	menu.pressed.connect(Session.go_to_title)
	bar.add_child(menu)
	return bar


func _connect_sim_signals() -> void:
	sim.overtake.connect(_on_overtake)
	sim.pit_stop.connect(_on_pit_stop)
	sim.fastest_lap.connect(_on_fastest_lap)
	sim.tyre_warning.connect(_on_tyre_warning)
	sim.race_finished.connect(_on_race_finished)


func _process(delta: float) -> void:
	if not paused and not sim.is_over():
		sim.advance(delta * time_scale)
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = UI_REFRESH_S
		_refresh_ui()


func _refresh_ui() -> void:
	_lap_label.text = "BANDEIRADA" if sim.chequered else "VOLTA %d / %d" % [sim.leader_lap(), sim.total_laps]
	_standings.refresh()
	var order := sim.standings()
	for p in _car_panels:
		p.refresh(order.find(p.car) + 1)


# --- avisos (pop-ups não intrusivos) -------------------------------------------------

func _on_overtake(att: CarState, def: CarState, zone: String) -> void:
	var order := sim.standings()
	var new_pos := order.find(att) + 1
	if att.is_player or def.is_player or new_pos == 1:
		var accent := UiStyle.GOOD if att.is_player else (UiStyle.WARN if def.is_player else UiStyle.ACCENT_2)
		_toasts.push("%s passa %s (%s) — agora P%d" % [att.code(), def.code(), zone, new_pos], accent)


func _on_pit_stop(car: CarState, compound: String, stationary: float) -> void:
	if car.is_player:
		_toasts.push("Box: %s coloca %s (parado %.1f s)" % [car.code(), sim.tyres.compounds[compound]["name"], stationary])


func _on_fastest_lap(car: CarState, lap_time: float) -> void:
	if sim.leader_lap() > 3:
		_toasts.push("Volta mais rápida: %s — %s" % [car.code(), UiStyle.format_time(lap_time)], Color("#B36BFF"))


func _on_tyre_warning(car: CarState) -> void:
	_toasts.push("Rádio %s: \"Os pneus estão acabando!\" (%d%%)" % [car.code(), roundi(car.tyre_wear * 100.0)], UiStyle.WARN)


func _on_race_finished() -> void:
	if _results_shown:
		return
	_results_shown = true
	_refresh_ui()
	add_child(_build_results())


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:  # botão "voltar" do Android
		Session.go_to_title()


# --- resultado final -----------------------------------------------------------------

func _build_results() -> Control:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	var panel := UiStyle.panel(UiStyle.PANEL, 12)
	center.add_child(panel)
	var v := VBoxContainer.new()
	panel.add_child(v)
	v.add_child(UiStyle.label("RESULTADO · %s" % sim.track.grand_prix.to_upper(), 20, UiStyle.ACCENT_2, true))

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(760, 470)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 18)
	scroll.add_child(grid)
	for h: String in ["POS", "PILOTO", "EQUIPE", "TEMPO / DIF.", "PARADAS", "MELHOR VOLTA"]:
		grid.add_child(UiStyle.label(h, 12, UiStyle.MUTED, true))
	var order := sim.standings()
	for i in order.size():
		var car := order[i]
		var color := Color.WHITE if car.is_player else UiStyle.TEXT
		var pos := "DSQ" if car.disqualified else str(i + 1)
		var gap: String
		if i == 0:
			gap = UiStyle.format_time(car.finish_time)
		elif sim.laps_behind_leader(car) > 0:
			gap = "+%d volta(s)" % sim.laps_behind_leader(car)
		else:
			gap = "+%.3f s" % sim.gap_to_leader_s(car)
		var best := UiStyle.format_time(car.best_lap_time)
		if car == sim.fastest_lap_car:
			best += "  ★"
		for text: String in [pos, "%s  %s" % [car.code(), car.display_name()], car.team["name"], gap, str(car.pit_stops), best]:
			grid.add_child(UiStyle.label(text, 14, color, car.is_player))

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	var again := UiStyle.button("Correr de novo")
	again.pressed.connect(Session.restart_race)
	buttons.add_child(again)
	var menu := UiStyle.button("Menu")
	menu.pressed.connect(Session.go_to_title)
	buttons.add_child(menu)
	v.add_child(buttons)
	return shade
