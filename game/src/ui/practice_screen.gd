extends Control
## Treino livre ao vivo ("jogar"): segue a mesma estrutura da classificação (mockup m3-c) —
## tabela de tempos à esquerda; à direita, para cada carro do jogador, o programa em andamento
## e o acerto subindo a cada bloco concluído. Simular resto = mesmo resultado, de uma vez.

const UI_REFRESH_S := 0.25
const SPEEDS := [4.0, 8.0, 16.0, 32.0]

var weekend: WeekendSim
var p: PracticeSession
var time_scale := 16.0
var _table: TimingTable
var _clock: Label
var _panels: Array[Dictionary] = []
var _end_card: PanelContainer
var _toasts: ToastFeed
var _refresh := 0.0


func _ready() -> void:
	weekend = Session.weekend
	if weekend == null or not weekend.is_practice(weekend.session_id()):
		Session.go_to_title.call_deferred()
		return
	p = weekend.make_practice()
	if Session.debug_advance_s > 0.0:  # (capturas de tela)
		p.advance(Session.debug_advance_s)
	var root := ScreenKit.page(self)
	var id := weekend.session_id()
	var head := ScreenKit.masthead(root, WeekendSim.SESSION_NAMES[id],
		"%s · 60 min · programas em andamento" % weekend.circuit["grand_prix"], "")
	_clock = head["right"]
	var speeds := ScreenKit.speed_bar(SPEEDS, time_scale, func(s: float) -> void: time_scale = s)
	head["bar"].add_child(speeds)
	head["bar"].move_child(speeds, 2)
	var rest := UiStyle.compact(UiStyle.button("Simular resto"), 12)
	rest.custom_minimum_size = Vector2(110, 34)
	rest.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rest.pressed.connect(func() -> void:
		p.run_to_end()
		_refresh_ui())
	head["bar"].add_child(rest)
	head["bar"].move_child(rest, 3)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	_table = TimingTable.new()
	_table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_table.size_flags_stretch_ratio = 1.55
	_table.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_table.setup([
		{"title": "Pos", "width": 30, "kind": "pos"},
		{"title": "Piloto", "width": 0, "heavy": true},
		{"title": "Melhor", "width": 82, "align": "right"},
		{"title": "Dif.", "width": 70, "align": "right"},
		{"title": "Voltas", "width": 52, "align": "right"},
		{"title": "Programa", "width": 150},
	], p.cars.size())
	body.add_child(_table)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	body.add_child(right)
	for car in p.cars:
		if car.is_player:
			right.add_child(_player_panel(car))
	_end_card = ScreenKit.card()
	var ev := VBoxContainer.new()
	ev.add_theme_constant_override("separation", 6)
	_end_card.add_child(ev)
	ev.add_child(UiStyle.label("TREINO ENCERRADO", 16, UiStyle.RED, true))
	ev.add_child(UiStyle.label("O acerto conquistado vale para a classificação e a corrida.", 13))
	var go := UiStyle.accent(UiStyle.button("Continuar"))
	go.custom_minimum_size = Vector2(0, 40)
	go.pressed.connect(func() -> void:
		weekend.finish_practice(p)
		Session.go_to_weekend())
	ev.add_child(go)
	_end_card.visible = false
	right.add_child(_end_card)

	_toasts = ToastFeed.new()
	_toasts.position = Vector2(24, 560)
	add_child(_toasts)
	p.block_finished.connect(func(car: CarState, _block: String, text: String) -> void:
		if car.is_player:
			_toasts.push("%s — %s" % [car.code(), text], "hot"))
	_refresh_ui()


func _player_panel(car: CarState) -> Control:
	var card := ScreenKit.card()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	card.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	top.add_child(TeamEmblems.make_rect(car.team["id"], 20))
	top.add_child(UiStyle.label(car.display_name(), 17, UiStyle.INK, true))
	top.add_child(UiStyle.hspacer())
	var pos := UiStyle.label("", 24, UiStyle.RED, true)
	top.add_child(pos)
	v.add_child(top)
	var status := UiStyle.label("", 13)
	v.add_child(status)
	var bars := {}
	for row: Array in [["aero", "Aerodinâmica"], ["mech", "Mecânico"], ["balance", "Equilíbrio"]]:
		bars[row[0]] = ScreenKit.percent_row(v, row[1])
	var prog := UiStyle.label("", 12, UiStyle.MUTED)
	prog.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(prog)
	var panel := {"car": car, "pos": pos, "status": status, "bars": bars, "prog": prog}
	_panels.append(panel)
	return card


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
	_clock.text = "ENCERRADO" if p.is_over() else ScreenKit.clock(p.time_left_s())
	var order := p.standings()
	var lead := order[0].best_lap_time
	for i in order.size():
		var car := order[i]
		_table.set_row_style(i, "me" if car.is_player else "normal")
		_table.set_pos(i, 0, str(i + 1), car.team_color())
		_table.set_text(i, 1, StandingsPanel.surname(car.display_name()))
		_table.set_text(i, 2, UiStyle.format_time(car.best_lap_time))
		_table.set_text(i, 3, "—" if i == 0 or car.best_lap_time == INF else "+%.3f" % (car.best_lap_time - lead))
		_table.set_text(i, 4, str(car.laps_done))
		_table.set_text(i, 5, p.status_of(car))
	for panel: Dictionary in _panels:
		var car: CarState = panel["car"]
		var setup: CarSetup = p.setups[car.driver["id"]]
		(panel["pos"] as Label).text = "P%d" % (order.find(car) + 1)
		(panel["status"] as Label).text = "%s · %d voltas" % [p.status_of(car), car.laps_done]
		for key: String in panel["bars"]:
			var value: float = setup.get(key)
			panel["bars"][key]["bar"].value = value
			panel["bars"][key]["value"].text = "%d%%" % roundi(value * 100)
		var names: Array[String] = []
		for b: String in p.programs[car.driver["id"]]:
			names.append(PracticeSession.BLOCKS[b]["name"])
		(panel["prog"] as Label).text = "Programa: %s · Ritmo de corrida %d%% · Volta rápida %d%%" % [
			" → ".join(names), roundi(setup.race_prep * 100), roundi(setup.quali_prep * 100)]
	_end_card.visible = p.is_over()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.go_to_weekend()
