class_name StandingsPanel
extends PanelContainer
## Tabela de posições no estilo "folha de cronometragem" (escolhida pelo usuário):
## grade completa com fio separando cada piloto, quadrado da posição na cor da equipe,
## emblema, SOBRENOME, diferença para o líder, pneu (círculo) e desgaste.

const ROW_H := 23
const W_POS := 26.0
const W_GAP := 56.0
const W_TYRE := 27.0
const W_WEAR := 40.0

var sim: RaceSim
var _rows: Array[Dictionary] = []
var _status_panel: PanelContainer
var _status: Label


func setup(p_sim: RaceSim) -> void:
	sim = p_sim
	custom_minimum_size = Vector2(300, 0)
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	add_theme_stylebox_override("panel", UiStyle.sheet_box())
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	add_child(v)
	# faixa de status no topo, como "PIT EXIT CLOSED" na transmissão
	_status_panel = PanelContainer.new()
	_status = UiStyle.label("", 14, UiStyle.PAPER, true)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_panel.add_child(_status)
	v.add_child(_status_panel)
	for i in sim.cars.size():
		v.add_child(_make_row())


func _make_row() -> PanelContainer:
	var bg := PanelContainer.new()
	bg.add_theme_stylebox_override("panel", UiStyle.row_box(UiStyle.PAPER))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 0)
	h.custom_minimum_size = Vector2(0, ROW_H)
	bg.add_child(h)

	var pos := UiStyle.pos_cell(W_POS)
	h.add_child(pos)
	h.add_child(UiStyle.vsep())
	var name_box := HBoxContainer.new()
	name_box.add_theme_constant_override("separation", 5)
	name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var emblem := TeamEmblems.make_rect("", 18)
	name_box.add_child(emblem)
	var name_label := UiStyle.label("", 13, UiStyle.INK, true)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_box.add_child(name_label)
	var pen := _penalty_tag()
	name_box.add_child(pen)
	h.add_child(_pad(name_box, 0.0))
	h.add_child(UiStyle.vsep())
	var gap := UiStyle.label("", 13)
	gap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(_pad(gap, W_GAP))
	h.add_child(UiStyle.vsep())
	var tyre := TyreBadge.new()
	var tyre_box := CenterContainer.new()
	tyre_box.custom_minimum_size = Vector2(W_TYRE, 0)
	tyre_box.add_child(tyre)
	h.add_child(tyre_box)
	h.add_child(UiStyle.vsep())
	var wear := UiStyle.label("", 11, UiStyle.MUTED)
	wear.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	wear.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(_pad(wear, W_WEAR))

	_rows.append({"bg": bg, "pos": pos, "emblem": emblem, "name": name_label, "pen": pen,
		"gap": gap, "tyre": tyre, "wear": wear, "team": ""})
	return bg


func _pad(node: Control, width: float) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 5)
	m.add_theme_constant_override("margin_right", 5)
	if width > 0.0:
		m.custom_minimum_size = Vector2(width, 0)
	else:
		m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(node)
	return m


func _penalty_tag() -> Label:
	var l := UiStyle.label("", 10, Color.WHITE, true)
	l.add_theme_stylebox_override("normal", UiStyle.box(UiStyle.RED, 3, 0))
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.visible = false
	return l


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
	var style := UiStyle.box(bg, 6, 4)
	style.border_color = UiStyle.INK
	style.border_width_bottom = 1
	_status_panel.add_theme_stylebox_override("panel", style)


func refresh() -> void:
	_refresh_status()
	var order := sim.standings()
	for i in order.size():
		var car := order[i]
		var row := _rows[i]
		var ink := UiStyle.PAPER if car.is_player else (UiStyle.MUTED if car.retired else UiStyle.INK)
		row["bg"].add_theme_stylebox_override("panel", UiStyle.row_box(UiStyle.INK if car.is_player else UiStyle.PAPER))
		# quadrado da posição na cor da equipe (abandono fica cinza)
		UiStyle.set_pos_cell(row["pos"], "–" if car.retired else str(i + 1), UiStyle.BAR_BG if car.retired else car.team_color())
		if row["team"] != car.team["id"]:
			row["team"] = car.team["id"]
			row["emblem"].texture = TeamEmblems.get_texture(car.team["id"])
		row["emblem"].modulate.a = 0.35 if car.retired else 1.0
		row["name"].text = surname(car.display_name())
		row["name"].add_theme_color_override("font_color", ink)
		row["pen"].visible = car.penalty_pending_s > 0.0 or car.drive_through
		row["pen"].text = "DT" if car.drive_through else "+%ds" % int(car.penalty_pending_s)
		row["gap"].text = "ABANDONO" if car.retired else _gap_text(car, i)
		row["gap"].add_theme_font_size_override("font_size", 10 if car.retired else 13)
		row["gap"].add_theme_color_override("font_color", ink)
		var compound: Dictionary = sim.tyres.compounds[car.tyre]
		row["tyre"].set_compound("" if car.retired else compound["letter"], Color(compound["color"]))
		# a coluna de desgaste também mostra o estado especial do carro (no box, rodou, desclassificado)
		var state := "DSQ" if car.disqualified else ("" if car.retired else ("BOX" if car.in_pit else ("RODOU" if car.stall_s > 0.0 else "")))
		row["wear"].text = state if state != "" or car.retired else "%d%%" % roundi(clampf(car.tyre_wear, 0.0, 1.0) * 100.0)
		var hot := state != "" or car.tyre_wear >= 0.7
		row["wear"].add_theme_color_override("font_color", UiStyle.RED if hot and not car.is_player else (ink if car.is_player else UiStyle.MUTED))


func _gap_text(car: CarState, index: int) -> String:
	if index == 0:
		return "Líder"
	var behind := sim.laps_behind_leader(car)
	if behind > 0:
		return "+%d V" % behind
	return "+%.1f" % sim.gap_to_leader_s(car)
