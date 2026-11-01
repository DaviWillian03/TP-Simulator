class_name StandingsPanel
extends PanelContainer
## Tabela de posições: piloto, diferença para o líder, pneu atual e quanto ele está gasto.

const ROW_H := 23

var sim: RaceSim
var _rows: Array[Dictionary] = []


func setup(p_sim: RaceSim) -> void:
	sim = p_sim
	custom_minimum_size = Vector2(280, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	add_child(v)
	var head := HBoxContainer.new()
	head.add_child(_cell(UiStyle.label("POS", 11, UiStyle.MUTED), 30))
	head.add_child(_cell(UiStyle.label("PILOTO", 11, UiStyle.MUTED), 70))
	head.add_child(_cell(UiStyle.label("DIF.", 11, UiStyle.MUTED), 78, true))
	head.add_child(_cell(UiStyle.label("PNEU", 11, UiStyle.MUTED), 70, true))
	v.add_child(head)
	for i in sim.cars.size():
		v.add_child(_make_row())


func _make_row() -> PanelContainer:
	var bg := PanelContainer.new()
	bg.add_theme_stylebox_override("panel", _row_box(Color(0, 0, 0, 0)))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.custom_minimum_size = Vector2(0, ROW_H)
	bg.add_child(h)
	var row := {
		"bg": bg,
		"pos": _cell(UiStyle.label("", 14, UiStyle.MUTED, true), 24),
		"stripe": ColorRect.new(),
		"code": _cell(UiStyle.label("", 14, UiStyle.TEXT, true), 42),
		"gap": _cell(UiStyle.label("", 13, UiStyle.TEXT), 74, true),
		"tyre": _cell(UiStyle.label("", 14, UiStyle.TEXT, true), 18, true),
		"wear": _cell(UiStyle.label("", 12, UiStyle.MUTED), 40, true),
		"tag": _cell(UiStyle.label("", 11, UiStyle.ACCENT_2, true), 28),
	}
	row["stripe"].custom_minimum_size = Vector2(4, 16)
	row["stripe"].size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for key: String in ["pos", "stripe", "code", "gap", "tyre", "wear", "tag"]:
		h.add_child(row[key])
	_rows.append(row)
	return bg


func _cell(l: Label, width: float, right: bool = false) -> Label:
	l.custom_minimum_size = Vector2(width, 0)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if right:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return l


func _row_box(c: Color) -> StyleBoxFlat:
	var b := UiStyle.box(c, 4, c, 0)
	b.content_margin_top = 0
	b.content_margin_bottom = 0
	b.content_margin_left = 4
	b.content_margin_right = 4
	return b


func refresh() -> void:
	var order := sim.standings()
	for i in order.size():
		var car := order[i]
		var row := _rows[i]
		row["pos"].text = str(i + 1)
		row["stripe"].color = car.team_color()
		row["code"].text = car.code()
		row["code"].add_theme_color_override("font_color", Color.WHITE if car.is_player else UiStyle.TEXT)
		row["gap"].text = _gap_text(car, i)
		var compound: Dictionary = sim.tyres.compounds[car.tyre]
		row["tyre"].text = compound["letter"]
		row["tyre"].add_theme_color_override("font_color", Color(compound["color"]))
		row["wear"].text = "%d%%" % roundi(clampf(car.tyre_wear, 0.0, 1.0) * 100.0)
		row["wear"].add_theme_color_override("font_color", UiStyle.WARN if car.tyre_wear >= 0.7 else UiStyle.MUTED)
		row["tag"].text = "DSQ" if car.disqualified else ("BOX" if car.in_pit else ("FIM" if car.finished else ""))
		row["bg"].add_theme_stylebox_override("panel", _row_box(UiStyle.PLAYER_ROW if car.is_player else Color(0, 0, 0, 0)))


func _gap_text(car: CarState, index: int) -> String:
	if index == 0:
		return "Líder"
	var behind := sim.laps_behind_leader(car)
	if behind > 0:
		return "+%d volta%s" % [behind, "" if behind == 1 else "s"]
	return "+%.1f s" % sim.gap_to_leader_s(car)
