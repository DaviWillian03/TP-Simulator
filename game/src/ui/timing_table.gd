class_name TimingTable
extends PanelContainer
## Tabela no estilo "folha de cronometragem" (direção escolhida pelo usuário): grade completa,
## cabeçalho em tinta, fio separando cada piloto e quadrado da posição na cor da equipe.
##
## Colunas: {"title", "width" (0 = ocupa o resto), "align" ("left"/"right"/"center"),
##           "kind" ("text"/"pos"/"tyre"), "heavy" (bool)}

const ROW_H := 25
const ROW_H_GARAGE := 36

## "paddock" (legado: papel e tinta) ou "garage" (direção atual: linhas escuras, separadores
## claros e finos, quadrado da posição arredondado, carros do jogador na cor da equipe).
var style := "paddock"
var me_color := Color("#1868DB")  ## destaque das linhas do jogador (garage)

var row_h := ROW_H_GARAGE  ## altura da linha (garage); tabelas de 24 carros usam menos
var columns: Array = []
var _rows: Array = []  # [{panel, cells: [Control]}]
var _body: VBoxContainer
var _header: PanelContainer


func setup(cols: Array, rows: int, p_style: String = "paddock") -> void:
	columns = cols
	style = p_style
	if style == "garage":
		add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.04), 20, 0, 6))
	else:
		add_theme_stylebox_override("panel", UiStyle.sheet_box())
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 0)
	add_child(_body)
	_header = PanelContainer.new()
	_header.add_theme_stylebox_override("panel", _garage_line(Color(0, 0, 0, 0), 0.08, 40) if _garage() else UiStyle.box(UiStyle.INK, 0, 0))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 0)
	h.custom_minimum_size = Vector2(0, 24)
	_header.add_child(h)
	for i in columns.size():
		if i > 0 and not _garage():
			h.add_child(UiStyle.vsep(Color("#3d3d3d")))
		var cap := UiStyle.g_caption(columns[i]["title"]) if _garage() else UiStyle.caption(columns[i]["title"], UiStyle.PAPER)
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
	panel.add_theme_stylebox_override("panel", _garage_line(Color(0, 0, 0, 0), 0.07, 0) if _garage() else UiStyle.row_box(UiStyle.PAPER))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 0)
	h.custom_minimum_size = Vector2(0, row_h if _garage() else ROW_H)
	panel.add_child(h)
	var cells: Array = []
	for i in columns.size():
		if i > 0 and not _garage():
			h.add_child(UiStyle.vsep())
		var col: Dictionary = columns[i]
		var cell: Control
		match col.get("kind", "text"):
			"pos":
				cell = UiStyle.pos_cell(float(col["width"]))
				if _garage():
					cell.custom_minimum_size = Vector2(float(col["width"]), mini(26, row_h - 6))
					cell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
					var m := MarginContainer.new()
					m.add_theme_constant_override("margin_left", 12)
					m.add_child(cell)
					h.add_child(m)
					(cell.get_child(0) as Label).add_theme_font_override("font", UiStyle.G_BLACK)
				else:
					h.add_child(cell)
			"team":  # emblema + nome (garage)
				var box := HBoxContainer.new()
				box.add_theme_constant_override("separation", 10)
				box.add_child(TextureRect.new())
				var nl := UiStyle.g_label("", 16 if row_h >= 32 else 14, UiStyle.G_TEXT, "black")
				nl.clip_text = true
				nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				box.add_child(nl)
				cell = box
				h.add_child(_wrap(box, col))
			"tyre":
				var box := HBoxContainer.new()
				box.add_theme_constant_override("separation", 5)
				box.add_child(TyreBadge.new())
				box.add_child(UiStyle.label("", 13))
				cell = box
				h.add_child(_wrap(box, col))
			_:
				var l := UiStyle.g_label("", 16 if row_h >= 32 else 14, UiStyle.G_TEXT_2) if _garage() else UiStyle.label("", 13, UiStyle.INK, bool(col.get("heavy", false)))
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
func set_row_style(r: int, row_style: String) -> void:
	var row: Dictionary = _rows[r]
	if _garage():
		var bg := Color(me_color, 0.24) if row_style == "me" else Color(0, 0, 0, 0)
		row["panel"].add_theme_stylebox_override("panel", _garage_line(bg, 0.07, 0))
		var fg := UiStyle.G_TEXT_OFF if row_style == "out" else UiStyle.G_TEXT_2
		for cell: Control in row["cells"]:
			if cell is Label:
				cell.add_theme_color_override("font_color", UiStyle.G_TEXT if row_style == "me" else fg)
			elif cell is HBoxContainer and cell.get_child_count() > 1 and cell.get_child(1) is Label:
				cell.get_child(1).add_theme_color_override("font_color", UiStyle.G_TEXT_OFF if row_style == "out" else UiStyle.G_TEXT)
		return
	row["panel"].add_theme_stylebox_override("panel", UiStyle.row_box(UiStyle.INK if row_style == "me" else UiStyle.PAPER))
	var color := UiStyle.PAPER if row_style == "me" else (UiStyle.MUTED if row_style == "out" else UiStyle.INK)
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
	if _garage():  # quadrado com cantos arredondados na direção Garagem
		(_rows[r]["cells"][c] as PanelContainer).add_theme_stylebox_override("panel", UiStyle.g_box(team_color, 7, 0, 0))


func set_tyre(r: int, c: int, letter: String, color: Color, extra: String) -> void:
	var box: HBoxContainer = _rows[r]["cells"][c]
	(box.get_child(0) as TyreBadge).set_compound(letter, color)
	(box.get_child(1) as Label).text = extra


## Linha vermelha grossa embaixo da linha r (ex.: zona de eliminação da classificação).
## r < 0 tira a linha.
func set_cut_line(r: int) -> void:
	for i in _rows.size():
		var panel: PanelContainer = _rows[i]["panel"]
		var st: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate()
		st.border_color = UiStyle.RED if i == r else UiStyle.INK
		st.border_width_bottom = 4 if i == r else 1
		panel.add_theme_stylebox_override("panel", st)



## Emblema + nome numa coluna "team".
func set_team(r: int, c: int, team_id: String, text: String) -> void:
	var box: HBoxContainer = _rows[r]["cells"][c]
	var em: TextureRect = box.get_child(0)
	em.texture = TeamEmblems.get_texture(team_id)
	em.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	em.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	em.custom_minimum_size = Vector2(20, 20)
	em.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	(box.get_child(1) as Label).text = text


func _garage() -> bool:
	return style == "garage"


## Linha da tabela garage: fundo e separador fino claro embaixo.
func _garage_line(bg: Color, line_alpha: float, height: int) -> StyleBoxFlat:
	var b := UiStyle.g_box(bg, 0, 0, 0)
	b.border_color = Color(1, 1, 1, line_alpha)
	b.border_width_bottom = 1
	if height > 0:
		b.content_margin_top = 0
	return b
