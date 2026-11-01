class_name StandingsPanel
extends VBoxContainer
## Tabela de posições no estilo da transmissão: posição, emblema da equipe, SOBRENOME,
## diferença para o líder, pneu atual e quanto ele está gasto.

const ROW_H := 23

var sim: RaceSim
var _rows: Array[Dictionary] = []


func setup(p_sim: RaceSim) -> void:
	sim = p_sim
	custom_minimum_size = Vector2(296, 0)
	add_theme_constant_override("separation", 0)
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
		"gap": _cell(UiStyle.label("", 13, UiStyle.INK), 50, true),
		"tyre": _cell(UiStyle.label("", 14), 16, true),
		"wear": _cell(UiStyle.label("", 11, UiStyle.MUTED), 34, true),
		"team": "",
	}
	row["name"].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row["name"].clip_text = true
	for key: String in ["pos", "emblem", "name", "gap", "tyre", "wear"]:
		h.add_child(row[key])
	_rows.append(row)
	return bg


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


func refresh() -> void:
	var order := sim.standings()
	for i in order.size():
		var car := order[i]
		var row := _rows[i]
		var ink := UiStyle.PAPER if car.is_player else UiStyle.INK
		row["bg"].add_theme_stylebox_override("panel", _row_box(car.is_player))
		row["pos"].text = str(i + 1)
		row["pos"].add_theme_color_override("font_color", UiStyle.RED if i == 0 and not car.is_player else ink)
		if row["team"] != car.team["id"]:
			row["team"] = car.team["id"]
			row["emblem"].texture = TeamEmblems.get_texture(car.team["id"])
		row["name"].text = surname(car.display_name())
		row["name"].add_theme_color_override("font_color", ink)
		row["gap"].text = _gap_text(car, i)
		row["gap"].add_theme_color_override("font_color", ink)
		var compound: Dictionary = sim.tyres.compounds[car.tyre]
		row["tyre"].text = compound["letter"]
		UiStyle.tyre_letter(row["tyre"], Color(compound["color"]))
		# a coluna de desgaste também mostra o estado especial do carro (no box, desclassificado)
		var state := "DSQ" if car.disqualified else ("BOX" if car.in_pit else "")
		row["wear"].text = state if state != "" else "%d%%" % roundi(clampf(car.tyre_wear, 0.0, 1.0) * 100.0)
		var hot := state != "" or car.tyre_wear >= 0.7
		row["wear"].add_theme_color_override("font_color", UiStyle.RED if hot else (ink if car.is_player else UiStyle.MUTED))


func _gap_text(car: CarState, index: int) -> String:
	if index == 0:
		return "Líder"
	var behind := sim.laps_behind_leader(car)
	if behind > 0:
		return "+%d V" % behind
	return "+%.1f" % sim.gap_to_leader_s(car)
