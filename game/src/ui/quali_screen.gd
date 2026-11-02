extends Control
## Classificação ao vivo (mockup m3-c): tabela da parte atual com a linha vermelha da zona de
## eliminação; para cada carro do jogador, a escolha do pneu e o botão de sair para a volta
## rápida; aviso da pista evoluindo. Q1/Q2/Q3 (ou SQ1/SQ2/SQ3 na sprint).

const UI_REFRESH_S := 0.25
const SPEEDS := [2.0, 4.0, 8.0, 16.0]

var weekend: WeekendSim
var q: QualiSim
var time_scale := 4.0
var _table: TimingTable
var _sub: Label
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
	var root := ScreenKit.page(self)
	var head := ScreenKit.masthead(root, "Classificação", "", "")
	_sub = head["bar"].get_child(1).get_child(0)
	_clock = head["right"]
	var speeds := ScreenKit.speed_bar(SPEEDS, time_scale, func(s: float) -> void: time_scale = s)
	head["bar"].add_child(speeds)
	head["bar"].move_child(speeds, 2)
	var rest := UiStyle.compact(UiStyle.button("Simular resto"), 12)
	rest.custom_minimum_size = Vector2(110, 34)
	rest.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rest.pressed.connect(_simulate_rest)
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
		{"title": "Pn", "width": 40, "kind": "tyre"},
		{"title": "Situação", "width": 126},
	], q.cars.size())
	body.add_child(_table)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	body.add_child(right)
	for car in q.cars:
		if car.is_player:
			right.add_child(_player_panel(car))
	var info := ScreenKit.card()
	var iv := VBoxContainer.new()
	iv.add_theme_constant_override("separation", 3)
	info.add_child(iv)
	iv.add_child(UiStyle.label("PISTA EVOLUINDO", 15, UiStyle.INK, true))
	_evolution = UiStyle.label("", 13)
	_evolution.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	iv.add_child(_evolution)
	_cut_info = UiStyle.label("", 14, UiStyle.RED, true)
	_cut_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	iv.add_child(_cut_info)
	right.add_child(info)
	_end_card = _build_end_card()
	_end_card.visible = false
	right.add_child(_end_card)

	_toasts = ToastFeed.new()
	_toasts.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_toasts.position = Vector2(24, 560)
	add_child(_toasts)
	q.session_event.connect(func(t: String) -> void: _toasts.push(t))
	q.segment_finished.connect(_on_segment_finished)
	q.lap_completed.connect(_on_lap)
	_refresh_ui()


func _player_panel(car: CarState) -> Control:
	var card := ScreenKit.card()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
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
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var tyres := ScreenKit.tyre_buttons(row, q.tyres, q.ai_compound(car))
	var go := UiStyle.accent(UiStyle.button("Sair para volta rápida"))
	go.custom_minimum_size = Vector2(0, 40)
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.add_theme_font_size_override("font_size", 14)
	row.add_child(go)
	v.add_child(row)
	var panel := {"car": car, "pos": pos, "status": status, "tyres": tyres, "go": go}
	go.pressed.connect(_send_out.bind(panel))
	_panels.append(panel)
	return card


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
	_sub.text = ("%s · %s · %s" % [weekend.circuit["grand_prix"], seg["name"],
		("%d avançam" % adv) if adv > 0 else "disputa da pole"]).to_upper()
	_clock.text = "%s · %s" % [seg["name"], "BANDEIRA VERMELHA" if q.is_red_flag() else ScreenKit.clock(q.time_left_s())]
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
		_table.set_pos(i, 0, str(i + 1), UiStyle.BAR_BG if out else car.team_color())
		_table.set_text(i, 1, StandingsPanel.surname(car.display_name()))
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
	var card := ScreenKit.card()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)
	v.add_child(UiStyle.label("CLASSIFICAÇÃO ENCERRADA", 16, UiStyle.RED, true))
	v.add_child(UiStyle.label("A tabela mostra o grid de largada.", 13))
	var go := UiStyle.accent(UiStyle.button("Continuar"))
	go.custom_minimum_size = Vector2(0, 40)
	go.pressed.connect(func() -> void:
		weekend.finish_quali(q)
		Session.go_to_weekend())
	v.add_child(go)
	return card


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.go_to_weekend()
