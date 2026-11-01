extends Control
## Tela de corrida: liga a simulação à interface (pista, tabela, painéis e avisos).
##
## A cada quadro, avança a simulação pelo tempo real × velocidade escolhida.
## A tabela e os painéis são atualizados algumas vezes por segundo (não a cada quadro)
## para economizar bateria no celular.

const UI_REFRESH_S := 0.2
const SPEEDS := [1.0, 2.0, 4.0, 8.0]

var sim: RaceSim
var time_scale := 2.0
var paused := false

var _track_view: TrackView
var _standings: StandingsPanel
var _car_panels: Array[CarControlPanel] = []
var _toasts: ToastFeed
var _radar: RadarWidget
var _radio: RadioCard
var _drawer: DataDrawer
var _meta: Label
var _lap_label: Label
var _watermark: Label
var _refresh_timer := 0.0
var _results_shown := false


func _ready() -> void:
	theme = UiStyle.make_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
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
	_drawer.visible = Session.debug_open_data
	_connect_sim_signals()
	_refresh_ui()
	_toasts.push("Luzes apagadas! %d voltas em %s." % [sim.total_laps, sim.track.short_name])
	if sim.is_over():  # (só acontece quando a corrida foi avançada antes de abrir a tela)
		_on_race_finished()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = UiStyle.PAPER
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 16
	root.offset_top = 10
	root.offset_right = -16
	root.offset_bottom = -10
	root.add_theme_constant_override("separation", 0)
	add_child(root)
	root.add_child(_build_masthead())
	root.add_child(UiStyle.rule(UiStyle.RULE_THICK))

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 0)
	root.add_child(body)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 0)
	body.add_child(left)
	var map_row := HBoxContainer.new()
	map_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_row.add_theme_constant_override("separation", 0)
	left.add_child(map_row)
	var track_holder := Control.new()
	track_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track_holder.clip_contents = true
	map_row.add_child(track_holder)
	map_row.add_child(UiStyle.rule(UiStyle.RULE_MID, true))

	_watermark = UiStyle.label("", 130, Color(0, 0, 0, 0), true)
	_watermark.add_theme_color_override("font_outline_color", Color(UiStyle.INK, 0.14))
	_watermark.add_theme_constant_override("outline_size", 4)
	_watermark.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_watermark.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_watermark.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_watermark.offset_right = -14
	_watermark.offset_bottom = 10
	track_holder.add_child(_watermark)
	_track_view = TrackView.new()
	_track_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	track_holder.add_child(_track_view)
	_track_view.setup(sim)
	_toasts = ToastFeed.new()
	_toasts.position = Vector2(6, 12)
	_toasts.custom_minimum_size = Vector2(380, 0)
	track_holder.add_child(_toasts)
	_radar = RadarWidget.new()
	_radar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_radar.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_radar.offset_right = -12
	_radar.offset_top = 12
	track_holder.add_child(_radar)
	_radar.setup(sim)
	_radio = RadioCard.new()
	_radio.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_radio.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_radio.offset_left = 8
	_radio.offset_bottom = -10
	track_holder.add_child(_radio)
	_radio.answered.connect(func(id: int, option: int) -> void:
		sim.radio.answer(id, option)
		_refresh_ui())
	_drawer = DataDrawer.new()
	_drawer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_drawer.visible = false
	track_holder.add_child(_drawer)
	_drawer.setup(sim)
	_drawer.closed.connect(func() -> void: _drawer.visible = false)

	left.add_child(UiStyle.rule(UiStyle.RULE_MID))
	var panels := HBoxContainer.new()
	panels.add_theme_constant_override("separation", 16)
	var panels_margin := MarginContainer.new()
	panels_margin.add_theme_constant_override("margin_top", 10)
	panels_margin.add_theme_constant_override("margin_right", 14)
	panels_margin.add_child(panels)
	left.add_child(panels_margin)
	for car in sim.cars:
		if car.is_player:
			var p := CarControlPanel.new()
			panels.add_child(p)
			p.setup(sim, car)
			_car_panels.append(p)

	var tower_margin := MarginContainer.new()
	tower_margin.add_theme_constant_override("margin_left", 12)
	tower_margin.add_theme_constant_override("margin_top", 8)
	_standings = StandingsPanel.new()
	tower_margin.add_child(_standings)
	body.add_child(tower_margin)
	_standings.setup(sim)


func _build_masthead() -> Control:
	var bar := HBoxContainer.new()
	bar.custom_minimum_size = Vector2(0, 58)
	bar.add_theme_constant_override("separation", 14)
	var title := UiStyle.label(sim.track.grand_prix.to_upper(), 36, UiStyle.INK, true)
	title.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	bar.add_child(title)
	_meta = UiStyle.caption("")
	_meta.add_theme_font_size_override("font_size", 12)
	_meta.size_flags_vertical = Control.SIZE_SHRINK_END
	bar.add_child(_meta)
	var speeds := HBoxContainer.new()
	speeds.add_theme_constant_override("separation", 4)
	speeds.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pause := UiStyle.compact(UiStyle.button("II", true), 14)
	pause.custom_minimum_size = Vector2(38, 34)
	pause.toggled.connect(func(on: bool) -> void: paused = on)
	speeds.add_child(pause)
	var group := ButtonGroup.new()
	for s: float in SPEEDS:
		var b := UiStyle.compact(UiStyle.button("%d×" % int(s), true, group), 14)
		b.custom_minimum_size = Vector2(38, 34)
		b.button_pressed = is_equal_approx(s, time_scale)
		b.pressed.connect(func() -> void: time_scale = s)
		speeds.add_child(b)
	bar.add_child(speeds)
	var data := UiStyle.compact(UiStyle.button("Dados"), 13)
	data.custom_minimum_size = Vector2(70, 34)
	data.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	data.pressed.connect(func() -> void:
		_drawer.visible = not _drawer.visible
		_drawer.refresh())
	bar.add_child(data)
	bar.add_child(UiStyle.hspacer())
	var menu := UiStyle.compact(UiStyle.button("Menu"), 13)
	menu.custom_minimum_size = Vector2(64, 34)
	menu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	menu.pressed.connect(Session.go_to_title)
	bar.add_child(menu)
	_lap_label = UiStyle.label("", 36, UiStyle.RED, true)
	_lap_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	bar.add_child(_lap_label)
	return bar


func _connect_sim_signals() -> void:
	sim.overtake.connect(_on_overtake)
	sim.pit_stop.connect(_on_pit_stop)
	sim.fastest_lap.connect(_on_fastest_lap)
	sim.race_finished.connect(_on_race_finished)
	sim.incident.connect(_on_incident)
	sim.flag_changed.connect(_on_flag_changed)
	sim.penalty.connect(_on_penalty)
	sim.team_order_result.connect(_on_team_order)
	sim.radio_message.connect(_on_radio_message)


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
	var best := 99
	for p in _car_panels:
		var pos := order.find(p.car) + 1
		p.refresh(pos)
		best = mini(best, pos)
	_watermark.text = "P%d" % best


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
	var important := car.is_player or kind in ["crash", "failure", "contact"] or sim.standings().find(car) < 5
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
	add_child(_build_results())


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:  # botão "voltar" do Android
		Session.go_to_title()


# --- resultado final -----------------------------------------------------------------

func _build_results() -> Control:
	var shade := ColorRect.new()
	shade.color = Color(UiStyle.INK, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	var panel := PanelContainer.new()
	var style := UiStyle.outline_box(UiStyle.PAPER, UiStyle.INK, UiStyle.RULE_MID)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	var head := HBoxContainer.new()
	head.add_child(UiStyle.label("RESULTADO", 30, UiStyle.INK, true))
	head.add_child(UiStyle.hspacer())
	head.add_child(UiStyle.label(sim.track.grand_prix.to_upper(), 20, UiStyle.RED, true))
	v.add_child(head)
	v.add_child(UiStyle.rule(UiStyle.RULE_THICK))

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(860, 440)
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
	], sim.cars.size())
	var order := sim.standings()
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

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	var again := UiStyle.accent(UiStyle.button("Correr de novo"))
	again.custom_minimum_size = Vector2(170, 40)
	again.pressed.connect(Session.restart_race)
	buttons.add_child(again)
	var menu := UiStyle.button("Menu")
	menu.custom_minimum_size = Vector2(100, 40)
	menu.pressed.connect(Session.go_to_title)
	buttons.add_child(menu)
	v.add_child(buttons)
	return shade
