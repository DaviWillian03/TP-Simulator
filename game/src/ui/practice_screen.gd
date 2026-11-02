extends Control
## Treino livre ao vivo — direção Garagem (mockup design/mockups/v4-2-garagem-treino.html).
##
## Só acompanhamento: as decisões foram o programa, no painel do fim de semana. À esquerda, a
## tabela de tempos; à direita, o programa de cada piloto andando (feito / agora / próximo), o
## acerto subindo e os avisos. "Simular resto" dá o mesmo resultado, de uma vez.

const UI_REFRESH_S := 0.25
const SPEEDS := [4.0, 8.0, 16.0, 32.0]
const BLOCK_SHORT := {"aero": "Aero", "mech": "Mecânico", "race": "Corrida", "quali": "Volta rápida"}

var weekend: WeekendSim
var p: PracticeSession
var time_scale := 16.0
var _table: TimingTable
var _clock: Label
var _panels: Array[Dictionary] = []
var _feed: VBoxContainer
var _end_card: PanelContainer
var _refresh := 0.0


func _ready() -> void:
	weekend = Session.weekend
	if weekend == null or not weekend.is_practice(weekend.session_id()):
		Session.go_to_title.call_deferred()
		return
	p = weekend.make_practice()
	if Session.debug_advance_s > 0.0:  # (capturas de tela)
		p.advance(Session.debug_advance_s)
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
	titles.add_child(UiStyle.g_caption("%s · acompanhamento" % weekend.circuit["grand_prix"]))
	titles.add_child(UiStyle.g_label(String(WeekendSim.SESSION_NAMES[weekend.session_id()]).to_upper(), 30, UiStyle.G_TEXT, "black"))
	head.add_child(titles)
	ScreenKit.place(head, layer, Control.PRESET_TOP_LEFT, Vector2(44, 24))

	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", UiStyle.SP_M)
	var speed_opts: Array = [[0.0, "II"]]
	for s: float in SPEEDS:
		speed_opts.append([s, "%d×" % int(s)])
	var speeds := ScreenKit.segmented(speed_opts, time_scale, func(s: float) -> void: time_scale = s)
	speeds.custom_minimum_size = Vector2(290, 0)
	tools.add_child(speeds)
	var rest := Button.new()
	rest.text = "SIMULAR RESTO"
	rest.focus_mode = Control.FOCUS_NONE
	rest.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MIN + 4)
	rest.add_theme_font_size_override("font_size", 15)
	rest.pressed.connect(func() -> void:
		p.run_to_end()
		_refresh_ui())
	ScreenKit.press_feedback(rest)
	tools.add_child(rest)
	_clock = UiStyle.g_label("", 34, UiStyle.G_TEXT, "black")
	_clock.custom_minimum_size = Vector2(110, 0)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tools.add_child(_clock)
	ScreenKit.place(tools, layer, Control.PRESET_TOP_RIGHT, Vector2(-40, 26))

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layer.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	scroll.offset_left = 44
	scroll.offset_right = 44 + 720
	scroll.offset_top = 104
	scroll.offset_bottom = -20
	_table = TimingTable.new()
	_table.me_color = UiStyle.team_color(weekend.player_team)
	_table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_table.setup([
		{"title": "Pos", "width": 46, "kind": "pos"},
		{"title": "Piloto", "width": 0, "kind": "team"},
		{"title": "Melhor", "width": 96, "align": "right"},
		{"title": "Dif.", "width": 80, "align": "right"},
		{"title": "Voltas", "width": 70, "align": "right"},
		{"title": "Fazendo agora", "width": 176},
	], p.cars.size(), "garage")
	scroll.add_child(_table)

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 14)
	ScreenKit.place(right, layer, Control.PRESET_TOP_RIGHT, Vector2(-40, 104), Vector2(430, 0))
	for car in p.cars:
		if car.is_player:
			right.add_child(_player_panel(car))
	var feed_card := ScreenKit.g_card(Color(1, 1, 1, 0.04), 20, 18, 12)
	_feed = VBoxContainer.new()
	_feed.add_theme_constant_override("separation", 2)
	feed_card.add_child(_feed)
	_feed.add_child(UiStyle.g_label("Os avisos do treino aparecem aqui.", 15, UiStyle.G_TEXT_3))
	right.add_child(feed_card)
	_end_card = _light_end_card()
	_end_card.visible = false
	right.add_child(_end_card)
	p.block_finished.connect(_on_block_finished)
	_refresh_ui()


func _player_panel(car: CarState) -> Control:
	var color := UiStyle.team_color(weekend.player_team)
	var card := ScreenKit.g_card(UiStyle.G_SURFACE, 20, 20, 12)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", UiStyle.SP_M)
	top.add_child(TeamEmblems.make_rect(car.team["id"], 28))
	top.add_child(UiStyle.g_label(car.display_name(), 20, UiStyle.G_TEXT, "black"))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	var pos := UiStyle.g_label("", 30, UiStyle.RED, "black")
	top.add_child(pos)
	v.add_child(top)
	var timeline := HBoxContainer.new()
	timeline.add_theme_constant_override("separation", 6)
	v.add_child(timeline)
	var bars := {}
	for row: Array in [["aero", "Aerodinâmica"], ["mech", "Mecânico"], ["balance", "Equilíbrio"]]:
		bars[row[0]] = ScreenKit.g_percent_row(v, row[1], color)
	var panel := {"car": car, "pos": pos, "timeline": timeline, "bars": bars}
	_panels.append(panel)
	return card


## Um bloco do programa na linha do tempo: feito (✓, barra verde), agora (claro, barra vermelha
## proporcional ao tempo do bloco) ou próximo (apagado, com a duração).
func _timeline_tile(block: String, state: String, progress: float) -> PanelContainer:
	var tile := PanelContainer.new()
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.custom_minimum_size = Vector2(0, 46)
	var st := UiStyle.g_box(UiStyle.G_LIGHT if state == "now" else UiStyle.G_SURFACE_HOVER, 12, 10, 4)
	if state != "next":
		st.border_width_bottom = 4
		st.border_color = UiStyle.RED if state == "now" else Color("#3c9d5d")
	tile.add_theme_stylebox_override("panel", st)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -3)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	tile.add_child(v)
	var ink := UiStyle.G_INK if state == "now" else (Color("#cfe8d6") if state == "done" else UiStyle.G_TEXT_2)
	v.add_child(UiStyle.g_label(BLOCK_SHORT[block], 13, ink, "bold"))
	var sub := "✓ feito" if state == "done" else ("%d%% feito" % roundi(progress * 100) if state == "now" else "%d min" % int(PracticeSession.BLOCKS[block]["minutes"]))
	v.add_child(UiStyle.g_label(sub, 12, ink))
	return tile


func _process(delta: float) -> void:
	if p == null:
		return
	if not p.is_over():
		p.advance(delta * time_scale)
	_refresh -= delta
	if _refresh <= 0.0:
		_refresh = UI_REFRESH_S
		_refresh_ui()


func _refresh_ui() -> void:
	_clock.text = "FIM" if p.is_over() else ScreenKit.clock(p.time_left_s())
	var order := p.standings()
	var lead := order[0].best_lap_time
	for i in order.size():
		var car := order[i]
		_table.set_row_style(i, "me" if car.is_player else "normal")
		_table.set_pos(i, 0, str(i + 1), car.team_color())
		_table.set_team(i, 1, car.team["id"], StandingsPanel.surname(car.display_name()))
		_table.set_text(i, 2, UiStyle.format_time(car.best_lap_time))
		_table.set_text(i, 3, "—" if i == 0 or car.best_lap_time == INF else "+%.3f" % (car.best_lap_time - lead))
		_table.set_text(i, 4, str(car.laps_done))
		_table.set_text(i, 5, p.status_of(car))
	for panel: Dictionary in _panels:
		var car: CarState = panel["car"]
		var setup: CarSetup = p.setups[car.driver["id"]]
		(panel["pos"] as Label).text = "P%d" % (order.find(car) + 1)
		for key: String in panel["bars"]:
			var value: float = setup.get(key)
			panel["bars"][key]["bar"].value = value
			panel["bars"][key]["value"].text = "%d%%" % roundi(value * 100)
		_refresh_timeline(panel)
	_end_card.visible = p.is_over()


func _refresh_timeline(panel: Dictionary) -> void:
	var car: CarState = panel["car"]
	var tl: HBoxContainer = panel["timeline"]
	var prog: Array = p.programs[car.driver["id"]]
	var plan: Dictionary = p._plan[car]
	var remaining: int = (plan["queue"] as Array).size()
	var running: bool = plan["block"] != ""
	var done := prog.size() - remaining - (1 if running else 0)
	var key := "%d-%s-%d" % [done, plan["block"], int(p.time_s / 30.0)]
	if tl.get_meta("key", "") == key:
		return
	tl.set_meta("key", key)
	for c in tl.get_children():
		c.queue_free()
	for k in prog.size():
		var state := "done" if k < done else ("now" if k == done and running else "next")
		var progress := 0.0
		if state == "now":
			var full := float(PracticeSession.BLOCKS[prog[k]]["minutes"]) * 60.0
			progress = clampf(1.0 - (float(plan["block_end"]) - p.time_s) / full, 0.0, 1.0)
		tl.add_child(_timeline_tile(prog[k], state, progress))


func _on_block_finished(car: CarState, _block: String, text: String) -> void:
	if not car.is_player and not text.begins_with("Problema"):
		return
	if _feed.get_child_count() > 0 and (_feed.get_child(0) as Label).text.begins_with("Os avisos"):
		_feed.get_child(0).queue_free()
	var problem := text.begins_with("Problema") or text.contains("rodou")
	var l := UiStyle.g_label("%s — %s" % [car.code(), text], 15, Color("#ffb4a8") if problem else Color("#c3c9d3"))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feed.add_child(l)
	_feed.move_child(l, 0)
	while _feed.get_child_count() > 3:
		var old := _feed.get_child(_feed.get_child_count() - 1)
		_feed.remove_child(old)
		old.queue_free()


func _light_end_card() -> PanelContainer:
	var card := PanelContainer.new()
	var st := UiStyle.g_box(UiStyle.G_LIGHT, 20, 24, 16)
	st.border_width_left = 7
	st.border_color = UiStyle.RED
	card.add_theme_stylebox_override("panel", st)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	v.add_child(UiStyle.g_label("TREINO ENCERRADO", 24, UiStyle.G_INK, "black"))
	var t := UiStyle.g_label("O acerto conquistado vale para a classificação e a corrida.", 15, UiStyle.G_INK_2)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var go := CutButton.new()
	go.text = "CONTINUAR"
	go.pressed.connect(func() -> void:
		weekend.finish_practice(p)
		Session.go_to_weekend())
	v.add_child(go)
	return card


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.go_to_weekend()
