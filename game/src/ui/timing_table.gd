class_name TimingTable
extends PanelContainer
## Tabela no estilo "folha de cronometragem" (direção escolhida pelo usuário): grade completa,
## cabeçalho em tinta, fio separando cada piloto e quadrado da posição na cor da equipe.
##
## Colunas: {"title", "width" (0 = ocupa o resto), "align" ("left"/"right"/"center"),
##           "kind" ("text"/"pos"/"tyre"), "heavy" (bool)}

const ROW_H := 25

var columns: Array = []
var _rows: Array = []  # [{panel, cells: [Control]}]
var _body: VBoxContainer
var _header: PanelContainer


func setup(cols: Array, rows: int) -> void:
	columns = cols
	add_theme_stylebox_override("panel", UiStyle.sheet_box())
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 0)
	add_child(_body)
	_header = PanelContainer.new()
	_header.add_theme_stylebox_override("panel", UiStyle.box(UiStyle.INK, 0, 0))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 0)
	h.custom_minimum_size = Vector2(0, 24)
	_header.add_child(h)
	for i in columns.size():
		if i > 0:
			h.add_child(UiStyle.vsep(Color("#3d3d3d")))
		var cap := UiStyle.caption(columns[i]["title"], UiStyle.PAPER)
		cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cap.horizontal_alignment = _align(columns[i])
		h.add_child(_wrap(cap, columns[i]))
	_body.add_child(_header)
	set_row_count(rows)


func set_row_count(n: int) -> void:
	while _rows.size() < n:
		_rows.append(_make_row())
	for i in _rows.size():
		_rows[i]["panel"].visible = i < n


func row_count() -> int:
	return _rows.size()


func _make_row() -> Dictionary:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.row_box(UiStyle.PAPER))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 0)
	h.custom_minimum_size = Vector2(0, ROW_H)
	panel.add_child(h)
	var cells: Array = []
	for i in columns.size():
		if i > 0:
			h.add_child(UiStyle.vsep())
		var col: Dictionary = columns[i]
		var cell: Control
		match col.get("kind", "text"):
			"pos":
				cell = UiStyle.pos_cell(float(col["width"]))
				h.add_child(cell)
			"tyre":
				var box := HBoxContainer.new()
				box.add_theme_constant_override("separation", 5)
				box.add_child(TyreBadge.new())
				box.add_child(UiStyle.label("", 13))
				cell = box
				h.add_child(_wrap(box, col))
			_:
				var l := UiStyle.label("", 13, UiStyle.INK, bool(col.get("heavy", false)))
				l.horizontal_alignment = _align(col)
				l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				l.clip_text = true
				cell = l
				h.add_child(_wrap(l, col))
		cells.append(cell)
	_body.add_child(panel)
	return {"panel": panel, "cells": cells}


func _wrap(node: Control, col: Dictionary) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 6)
	m.add_theme_constant_override("margin_right", 6)
	var w := float(col.get("width", 0))
	if w > 0.0:
		m.custom_minimum_size = Vector2(w, 0)
	else:
		m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(node)
	return m


func _align(col: Dictionary) -> HorizontalAlignment:
	match col.get("align", "left"):
		"right":
			return HORIZONTAL_ALIGNMENT_RIGHT
		"center":
			return HORIZONTAL_ALIGNMENT_CENTER
	return HORIZONTAL_ALIGNMENT_LEFT


## style: "normal", "me" (carro do jogador: linha em tinta) ou "out" (abandono: apagado).
func set_row_style(r: int, style: String) -> void:
	var row: Dictionary = _rows[r]
	row["panel"].add_theme_stylebox_override("panel", UiStyle.row_box(UiStyle.INK if style == "me" else UiStyle.PAPER))
	var color := UiStyle.PAPER if style == "me" else (UiStyle.MUTED if style == "out" else UiStyle.INK)
	for i in columns.size():
		var cell: Control = row["cells"][i]
		if cell is Label:
			cell.add_theme_color_override("font_color", color)
		elif cell is HBoxContainer:
			cell.get_child(1).add_theme_color_override("font_color", color)


func set_text(r: int, c: int, text: String) -> void:
	(_rows[r]["cells"][c] as Label).text = text


func set_pos(r: int, c: int, text: String, team_color: Color) -> void:
	UiStyle.set_pos_cell(_rows[r]["cells"][c], text, team_color)


func set_tyre(r: int, c: int, letter: String, color: Color, extra: String) -> void:
	var box: HBoxContainer = _rows[r]["cells"][c]
	(box.get_child(0) as TyreBadge).set_compound(letter, color)
	(box.get_child(1) as Label).text = extra
