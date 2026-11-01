class_name DataDrawer
extends PanelContainer
## Menu DADOS: informações completas da corrida, abertas por cima do mapa sem pausar.
## Abas: Todos (todos os pilotos), Meus pilotos (detalhes) e Voltas (tempos recentes).

signal closed

const COLS := ["Pos", "Piloto", "Equipe", "Últ. volta", "Melhor", "Intervalo", "Pneu", "Paradas", "Punição", "Estado"]
const LAP_ROWS := 12

var sim: RaceSim
var _tab := 0
var _tab_group := ButtonGroup.new()
var _body: VBoxContainer
var _cells: Array = []  # linhas de Labels da aba atual


func setup(p_sim: RaceSim) -> void:
	sim = p_sim
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.PAPER, 4, 8))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	add_child(v)
	var head := HBoxContainer.new()
	head.add_child(UiStyle.label("DADOS DA CORRIDA", 22, UiStyle.INK, true))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(10, 0)
	head.add_child(gap)
	for i in 3:
		var b := UiStyle.compact(UiStyle.button(["Todos", "Meus pilotos", "Voltas"][i], true, _tab_group), 13)
		b.custom_minimum_size = Vector2(0, 32)
		b.add_theme_font_override("font", UiStyle.HEAVY_FONT)
		b.button_pressed = i == 0
		b.pressed.connect(_select.bind(i))
		head.add_child(b)
	head.add_child(UiStyle.hspacer())
	var close := UiStyle.compact(UiStyle.button("Fechar ✕"), 13)
	close.custom_minimum_size = Vector2(90, 32)
	close.pressed.connect(func() -> void: closed.emit())
	head.add_child(close)
	v.add_child(head)
	v.add_child(UiStyle.rule(3))
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
	_cells.clear()
	match _tab:
		0:
			_make_grid(COLS, sim.cars.size(), [26, 150, 110, 70, 70, 66, 60, 52, 60, 0])
		1:
			_make_grid(["Piloto", "Pos", "Pneus usados", "Voltas no pneu", "Dano", "Punições", "Licença", "Confiança"], 2, [150, 40, 130, 90, 70, 70, 60, 0])
		2:
			var heads := ["Volta"]
			for car in _focus_cars():
				heads.append(car.code())
			_make_grid(heads, LAP_ROWS, [60, 90, 90, 90])


func _make_grid(headers: Array, rows: int, widths: Array) -> void:
	var grid := GridContainer.new()
	grid.columns = headers.size()
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 2)
	_body.add_child(grid)
	for i in headers.size():
		var h := UiStyle.caption(headers[i], UiStyle.MUTED)
		h.custom_minimum_size = Vector2(widths[i] if i < widths.size() else 0, 0)
		grid.add_child(h)
	for r in rows:
		var line: Array[Label] = []
		for c in headers.size():
			var l := UiStyle.label("", 13, UiStyle.INK, c == 1 and _tab == 0)
			grid.add_child(l)
			line.append(l)
		_cells.append(line)


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
		var row: Array = _cells[i]
		var gap := sim.gap_to_leader_s(car)
		var interval := "—" if i == 0 else ("+%.1f" % (gap - prev_gap) if sim.laps_behind_leader(car) == 0 else "+%d V" % sim.laps_behind_leader(car))
		prev_gap = gap
		var c: Dictionary = sim.tyres.compounds[car.tyre]
		var state := "Abandonou" if car.retired else ("Box" if car.in_pit else ("Rodou" if car.stall_s > 0.0 else ("Chegou" if car.finished else "Na pista")))
		var texts := ["–" if car.retired else str(i + 1), car.display_name(), car.team["name"],
			UiStyle.format_time(car.last_lap_time), UiStyle.format_time(car.best_lap_time), interval,
			"%s · %d v" % [c["letter"], car.tyre_laps], str(car.pit_stops),
			"+%ds" % int(car.penalty_pending_s) if car.penalty_pending_s > 0.0 else "—", state]
		var color := UiStyle.RED if car.is_player else (UiStyle.MUTED if car.retired else UiStyle.INK)
		for k in texts.size():
			row[k].text = texts[k]
			row[k].add_theme_color_override("font_color", color)


func _refresh_mine() -> void:
	var mine: Array[CarState] = []
	for car in sim.cars:
		if car.is_player:
			mine.append(car)
	var order := sim.standings()
	for i in mine.size():
		var car := mine[i]
		var row: Array = _cells[i]
		var used: Array[String] = []
		for comp: String in car.compounds_used:
			used.append(sim.tyres.compounds[comp]["letter"])
		var conf := "neutra"
		if car.confidence != 0 and car.laps_done < car.confidence_until_lap:
			conf = "alta" if car.confidence > 0 else "baixa"
		var texts := [car.display_name(), str(order.find(car) + 1), " → ".join(used), str(car.tyre_laps),
			"asa %d%%" % roundi(car.damage_wing * 100.0) if car.damage_wing > 0.0 else "—",
			"%d s" % int(car.penalties_total_s), "%d pts" % car.license_points, conf]
		for k in texts.size():
			row[k].text = texts[k]


func _refresh_laps() -> void:
	var focus := _focus_cars()
	var last := 0
	for car in focus:
		last = maxi(last, car.lap_times.size())
	for r in LAP_ROWS:
		var lap := last - r  # mais recente em cima
		var row: Array = _cells[r]
		row[0].text = str(lap) if lap >= 1 else ""
		for k in focus.size():
			if k + 1 >= row.size():
				break
			var times := focus[k].lap_times
			row[k + 1].text = UiStyle.format_time(times[lap - 1]) if lap >= 1 and lap <= times.size() else ""
