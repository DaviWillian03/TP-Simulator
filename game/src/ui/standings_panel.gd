class_name StandingsPanel
extends VBoxContainer
## Tabela de posições no estilo da transmissão: posição, emblema da equipe, SOBRENOME,
## diferença para o líder, pneu atual e quanto ele está gasto.

const ROW_H := 23

var sim: RaceSim
var _rows: Array[Dictionary] = []
var _status_panel: PanelContainer
var _status: Label


func setup(p_sim: RaceSim) -> void:
	sim = p_sim
	custom_minimum_size = Vector2(296, 0)
	add_theme_constant_override("separation", 0)
	# faixa de status no topo, como "PIT EXIT CLOSED" na transmissão
	_status_panel = PanelContainer.new()
	_status = UiStyle.label("", 14, UiStyle.PAPER, true)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_panel.add_child(_status)
	add_child(_status_panel)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 4)
	add_child(gap)
	for i in sim.cars.size():
		add_child(_make_row())


func _make_row() -> PanelContainer:
	var bg := PanelContainer.new()
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.custom_minimum_size = Vector2(0, ROW_H)
	bg.add_child(h)
	var row := {
		"bg": bg,
		"pos": _cell(UiStyle.label("", 15, UiStyle.INK, true), 26),
		"emblem": TeamEmblems.make_rect("", 20),
		"name": _cell(UiStyle.label("", 13, UiStyle.INK, true), 0),
		"pen": _penalty_tag(),
		"gap": _cell(UiStyle.label("", 13, UiStyle.INK), 50, true),
		"tyre": _cell(UiStyle.label("", 14), 16, true),
		"wear": _cell(UiStyle.label("", 11, UiStyle.MUTED), 34, true),
		"team": "",
	}
	row["name"].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row["name"].clip_text = true
	for key: String in ["pos", "emblem", "name", "pen", "gap", "tyre", "wear"]:
		h.add_child(row[key])
	_rows.append(row)
	return bg


func _penalty_tag() -> Label:
	var l := UiStyle.label("", 10, Color.WHITE, true)
	l.add_theme_stylebox_override("normal", UiStyle.box(UiStyle.RED, 3, 0))
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.visible = false
	return l


func _cell(l: Label, width: float, right: bool = false) -> Label:
	l.custom_minimum_size = Vector2(width, 0)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if right:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return l


func _row_box(player: bool) -> StyleBoxFlat:
	var b := UiStyle.box(UiStyle.INK if player else Color(0, 0, 0, 0), 4, 0)
	b.border_color = UiStyle.RULE
	b.border_width_bottom = 1
	return b


static func surname(full_name: String) -> String:
	return full_name.get_slice(" ", full_name.get_slice_count(" ") - 1).to_upper()


func _refresh_status() -> void:
	var text := sim.control.status_text()
	var bg := UiStyle.INK
	var fg := UiStyle.PAPER
	if sim.control.flag == RaceControl.Flag.SC or sim.control.flag == RaceControl.Flag.VSC:
		bg = Color("#F5C400")
		fg = UiStyle.INK
	elif sim.control.flag == RaceControl.Flag.RED:
		bg = UiStyle.RED
	elif sim.weather.wetness >= 0.08 or sim.weather.rain_now() > WeatherModel.RAIN_THRESHOLD:
		var rain := sim.weather.rain_label()
		text = "PISTA %s%s" % [sim.weather.surface_label().to_upper(), "" if rain == "sem chuva" else " · " + rain.to_upper()]
	_status_panel.visible = text != ""
	_status.text = text
	_status.add_theme_color_override("font_color", fg)
	_status_panel.add_theme_stylebox_override("panel", UiStyle.box(bg, 6, 4))


func refresh() -> void:
	_refresh_status()
	var order := sim.standings()
	for i in order.size():
		var car := order[i]
		var row := _rows[i]
		var ink := UiStyle.PAPER if car.is_player else (UiStyle.MUTED if car.retired else UiStyle.INK)
		row["bg"].add_theme_stylebox_override("panel", _row_box(car.is_player))
		row["pos"].text = "–" if car.retired else str(i + 1)
		row["emblem"].modulate.a = 0.35 if car.retired else 1.0
		row["pen"].visible = car.penalty_pending_s > 0.0 or car.drive_through
		row["pen"].text = "DT" if car.drive_through else "+%ds" % int(car.penalty_pending_s)
		row["pos"].add_theme_color_override("font_color", UiStyle.RED if i == 0 and not car.is_player else ink)
		if row["team"] != car.team["id"]:
			row["team"] = car.team["id"]
			row["emblem"].texture = TeamEmblems.get_texture(car.team["id"])
		row["name"].text = surname(car.display_name())
		row["name"].add_theme_color_override("font_color", ink)
		row["gap"].text = "ABANDONO" if car.retired else _gap_text(car, i)
		row["gap"].add_theme_color_override("font_color", ink)
		var compound: Dictionary = sim.tyres.compounds[car.tyre]
		row["tyre"].text = "" if car.retired else compound["letter"]
		UiStyle.tyre_letter(row["tyre"], Color(compound["color"]))
		# a coluna de desgaste também mostra o estado especial do carro (no box, rodou, desclassificado)
		var state := "DSQ" if car.disqualified else ("" if car.retired else ("BOX" if car.in_pit else ("RODOU" if car.stall_s > 0.0 else "")))
		row["wear"].text = state if state != "" or car.retired else "%d%%" % roundi(clampf(car.tyre_wear, 0.0, 1.0) * 100.0)
		var hot := state != "" or car.tyre_wear >= 0.7
		row["wear"].add_theme_color_override("font_color", UiStyle.RED if hot else (ink if car.is_player else UiStyle.MUTED))


func _gap_text(car: CarState, index: int) -> String:
	if index == 0:
		return "Líder"
	var behind := sim.laps_behind_leader(car)
	if behind > 0:
		return "+%d V" % behind
	return "+%.1f" % sim.gap_to_leader_s(car)
