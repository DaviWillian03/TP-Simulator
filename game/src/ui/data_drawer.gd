class_name DataDrawer
extends PanelContainer
## Menu DADOS: informações completas da corrida, abertas por cima do mapa sem pausar.
## Abas: Todos (todos os pilotos), Meus pilotos (detalhes) e Voltas (tempos recentes).
## Tabelas no estilo Garagem (TimingTable "garage"), linhas do jogador na cor da equipe.

signal closed

const LAP_ROWS := 12

var sim: RaceSim
var _tab := 0
var _tabs: PanelContainer
var _body: VBoxContainer
var _table: TimingTable


func setup(p_sim: RaceSim) -> void:
	sim = p_sim
	add_theme_stylebox_override("panel", UiStyle.g_box(Color(0.05, 0.06, 0.08, 0.96), 22, 18, 14))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	head.add_child(UiStyle.g_label("DADOS DA CORRIDA", 22, UiStyle.G_TEXT, "black"))
	var tabs := ScreenKit.segmented([[0, "Todos"], [1, "Meus pilotos"], [2, "Voltas"]], 0, _select)
	_tabs = tabs
	head.add_child(tabs)
	head.add_child(UiStyle.hspacer())
	var close := ScreenKit.round_button("close", UiStyle.TOUCH_MIN, "Fechar")
	close.pressed.connect(func() -> void: closed.emit())
	head.add_child(close)
	v.add_child(head)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)
	_build()


func _select(i: int) -> void:
	_tab = i
	_build()
	refresh()


func _build() -> void:
	for c in _body.get_children():
		c.queue_free()
	_table = TimingTable.new()
	_table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(_table)
	_table.me_color = _my_color()
	match _tab:
		0:
			_table.setup([
				{"title": "Pos", "width": 30, "kind": "pos"},
				{"title": "Piloto", "width": 0, "heavy": true},
				{"title": "Equipe", "width": 110},
				{"title": "Últ. volta", "width": 76, "align": "right"},
				{"title": "Melhor", "width": 76, "align": "right"},
				{"title": "Intervalo", "width": 70, "align": "right"},
				{"title": "Pneu", "width": 64, "kind": "tyre"},
				{"title": "Paradas", "width": 58, "align": "right"},
				{"title": "Punição", "width": 58, "align": "right"},
				{"title": "Estado", "width": 76},
			], sim.cars.size(), "garage")
		1:
			_table.setup([
				{"title": "Piloto", "width": 0, "heavy": true},
				{"title": "Pos", "width": 34, "kind": "pos"},
				{"title": "Pneus usados", "width": 120},
				{"title": "Pneu atual", "width": 84, "kind": "tyre"},
				{"title": "Dano", "width": 70},
				{"title": "Punições", "width": 70, "align": "right"},
				{"title": "Licença", "width": 62, "align": "right"},
				{"title": "Confiança", "width": 76},
			], 2, "garage")
		2:
			var cols := [{"title": "Volta", "width": 60, "align": "right"}]
			for car in _focus_cars():
				cols.append({"title": car.code(), "width": 0, "align": "right", "heavy": car.is_player})
			_table.setup(cols, LAP_ROWS, "garage")


func _my_color() -> Color:
	for car in sim.cars:
		if car.is_player:
			return car.team_color()
	return UiStyle.RED


## Pilotos do jogador + o líder (para comparar tempos de volta).
func _focus_cars() -> Array[CarState]:
	var out: Array[CarState] = []
	for car in sim.cars:
		if car.is_player:
			out.append(car)
	var lead := sim.leader()
	if not out.has(lead):
		out.append(lead)
	return out


func refresh() -> void:
	if not visible:
		return
	match _tab:
		0:
			_refresh_all()
		1:
			_refresh_mine()
		2:
			_refresh_laps()


func _refresh_all() -> void:
	var order := sim.standings()
	var prev_gap := 0.0
	for i in order.size():
		var car := order[i]
		var gap := sim.gap_to_leader_s(car)
		var behind := sim.laps_behind_leader(car)
		var interval := "—" if i == 0 else ("+%.1f" % (gap - prev_gap) if behind == 0 else "+%d V" % behind)
		prev_gap = gap
		var c: Dictionary = sim.tyres.compounds[car.tyre]
		var state := "Abandonou" if car.retired else ("Box" if car.in_pit else ("Rodou" if car.stall_s > 0.0 else ("Chegou" if car.finished else "Na pista")))
		_table.set_row_style(i, "me" if car.is_player else ("out" if car.retired else "normal"))
		_table.set_pos(i, 0, "–" if car.retired else str(i + 1), UiStyle.BAR_BG if car.retired else car.team_color())
		_table.set_text(i, 1, car.display_name())
		_table.set_text(i, 2, car.team["name"])
		_table.set_text(i, 3, UiStyle.format_time(car.last_lap_time))
		_table.set_text(i, 4, UiStyle.format_time(car.best_lap_time))
		_table.set_text(i, 5, interval)
		_table.set_tyre(i, 6, "" if car.retired else c["letter"], Color(c["color"]), "%d v" % car.tyre_laps)
		_table.set_text(i, 7, str(car.pit_stops))
		_table.set_text(i, 8, "+%ds" % int(car.penalty_pending_s) if car.penalty_pending_s > 0.0 else "—")
		_table.set_text(i, 9, state)


func _refresh_mine() -> void:
	var mine: Array[CarState] = []
	for car in sim.cars:
		if car.is_player:
			mine.append(car)
	var order := sim.standings()
	for i in mine.size():
		var car := mine[i]
		var used: Array[String] = []
		for comp: String in car.compounds_used:
			used.append(sim.tyres.compounds[comp]["letter"])
		var conf := "neutra"
		if car.confidence != 0 and car.laps_done < car.confidence_until_lap:
			conf = "alta" if car.confidence > 0 else "baixa"
		var c: Dictionary = sim.tyres.compounds[car.tyre]
		_table.set_row_style(i, "out" if car.retired else "normal")
		_table.set_text(i, 0, car.display_name())
		_table.set_pos(i, 1, "–" if car.retired else str(order.find(car) + 1), car.team_color())
		_table.set_text(i, 2, " → ".join(used))
		_table.set_tyre(i, 3, c["letter"], Color(c["color"]), "%d v · %d%%" % [car.tyre_laps, roundi(clampf(car.tyre_wear, 0.0, 1.0) * 100.0)])
		_table.set_text(i, 4, "asa %d%%" % roundi(car.damage_wing * 100.0) if car.damage_wing > 0.0 else "—")
		_table.set_text(i, 5, "%d s" % int(car.penalties_total_s))
		_table.set_text(i, 6, "%d pts" % car.license_points)
		_table.set_text(i, 7, conf)


func _refresh_laps() -> void:
	var focus := _focus_cars()
	var last := 0
	for car in focus:
		last = maxi(last, car.lap_times.size())
	for r in LAP_ROWS:
		var lap := last - r  # mais recente em cima
		_table.set_text(r, 0, str(lap) if lap >= 1 else "")
		for k in focus.size():
			if k + 1 >= _table.columns.size():
				break
			var times := focus[k].lap_times
			_table.set_text(r, k + 1, UiStyle.format_time(times[lap - 1]) if lap >= 1 and lap <= times.size() else "")
