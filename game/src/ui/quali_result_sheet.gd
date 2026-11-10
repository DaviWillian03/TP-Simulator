class_name QualiResultSheet
extends Control
## Resultado entre as partes da classificação (mockups v28, aprovados em 2026-11-10). A sessão para e mostra:
## - fim do Q1/Q2: quem passa e, em vermelho, os eliminados (com a distância para o corte);
## - fim do Q3: a pole em destaque e o grid do 2º ao 10º.
## Só continua quando o jogador toca em CONTINUAR (sinal `confirmed`).

signal confirmed

const POLE_GOLD := Color("#F5C542")


## `order`: quem segue (melhor primeiro); `out`: eliminados (melhor primeiro); `seg`: índice da parte que acabou.
static func make(sim: QualiSim, seg: int, order: Array, out: Array, circuit_name: String, last: bool) -> QualiResultSheet:
	var s := QualiResultSheet.new()
	s._build(sim, seg, order, out, circuit_name, last)
	return s


func _build(sim: QualiSim, seg: int, order: Array, out: Array, gp: String, last: bool) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.027, 0.04, 0.68)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.g_box(Color(0.067, 0.075, 0.098, 0.97), 26, 26, 20))
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 60
	panel.offset_right = -60
	panel.offset_top = 30
	panel.offset_bottom = -30
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	var seg_name := String(sim.segments[seg]["name"])
	var next_name := String(sim.segments[seg + 1]["name"]) if seg + 1 < sim.segments.size() else ""
	# cabeça
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	head.add_child(UiStyle.g_label("FIM DO %s" % seg_name, 34, UiStyle.G_TEXT, "black"))
	if not last:
		head.add_child(_chip("%d passam para o %s" % [order.size(), next_name], Color("#3c9d5d"), Color.WHITE))
		head.add_child(_chip("%d eliminados" % out.size(), Color(0.88, 0.02, 0.0, 0.3), Color("#ffb4a8")))
	head.add_child(UiStyle.hspacer())
	head.add_child(_chip("%s · %s" % [seg_name, gp], Color(1, 1, 1, 0.1), UiStyle.G_TEXT, "timer"))
	v.add_child(head)
	# corpo
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 22)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(body)
	if last:
		_pole_body(body, sim, seg, order)
	else:
		_cut_body(body, sim, seg, order, out)
	# rodapé: a confirmação é obrigatória
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	var note := UiStyle.g_label(("O %s só começa quando você confirmar." % next_name) if not last else "A tabela vira o grid de largada.", 14, UiStyle.G_TEXT_2, "bold")
	note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	foot.add_child(ScreenKit.icon("bell" if not last else "flag", 16, UiStyle.G_TEXT_2))
	foot.add_child(note)
	foot.add_child(UiStyle.hspacer())
	var go := CutButton.new()
	go.text = ("CONTINUAR · %s" % next_name) if not last else "CONTINUAR"
	go.custom_minimum_size = Vector2(300, UiStyle.TOUCH_MAIN + 2)
	go.pressed.connect(func() -> void:
		confirmed.emit()
		queue_free())
	foot.add_child(go)
	v.add_child(foot)
	modulate = Color(1, 1, 1, 0)
	ready.connect(func() -> void: create_tween().tween_property(self, "modulate:a", 1.0, 0.15))


# --- Q1 / Q2 -------------------------------------------------------------------------------

func _cut_body(body: HBoxContainer, sim: QualiSim, seg: int, order: Array, out: Array) -> void:
	var lead: float = sim.best[order[0]][seg] if not order.is_empty() else 0.0
	var half := ceili(order.size() / 2.0)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 14)
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for c in 2:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 6)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for i in range(c * half, mini((c + 1) * half, order.size())):
			col.add_child(_row(sim, order[i], i + 1, float(sim.best[order[i]][seg]), lead))
		cols.add_child(col)
	body.add_child(cols)
	# eliminados em vermelho
	var cut_time: float = sim.best[order[order.size() - 1]][seg] if not order.is_empty() else 0.0
	var box := PanelContainer.new()
	var st := UiStyle.g_box(Color(0.88, 0.02, 0.0, 0.14), 20, 14, 12)
	st.set_border_width_all(2)
	st.border_color = Color(0.88, 0.02, 0.0, 0.55)
	box.add_theme_stylebox_override("panel", st)
	box.custom_minimum_size = Vector2(372, 0)
	var ov := VBoxContainer.new()
	ov.add_theme_constant_override("separation", 8)
	box.add_child(ov)
	ov.add_child(UiStyle.g_caption("Eliminados · largam de P%d a P%d" % [order.size() + 1, order.size() + out.size()], Color("#ff8a80")))
	for i in out.size():
		var car: CarState = out[i]
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 12)
		var av := DriverPhotos.make_avatar(car.driver, car.team_color(), 46)
		av.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(av)
		var tv := VBoxContainer.new()
		tv.add_theme_constant_override("separation", -2)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var full := car.display_name()
		tv.add_child(UiStyle.g_label(full.get_slice(" ", full.get_slice_count(" ") - 1), 17, UiStyle.G_TEXT, "black"))
		var t: float = sim.best[car][seg]
		var detail := "P%d · %s" % [order.size() + i + 1, UiStyle.format_time(t).replace(".", ",")]
		if t < INF:
			detail += " · +%s do corte" % ("%.3f" % (t - cut_time)).replace(".", ",")
		else:
			detail += " · sem tempo"
		tv.add_child(UiStyle.g_label(detail, 12, Color("#ffb4a8"), "bold"))
		r.add_child(tv)
		r.add_child(TeamEmblems.make_rect(String(car.team["id"]), 30))
		ov.add_child(r)
	body.add_child(box)


func _row(sim: QualiSim, car: CarState, pos: int, t: float, lead: float) -> PanelContainer:
	var mine := car.is_player
	var accent := UiStyle.team_accent(car.team)
	var p := PanelContainer.new()
	var st := UiStyle.g_box(Color(accent, 0.2) if mine else Color(1, 1, 1, 0.05), 12, 12, 0)
	if mine:
		st.border_width_left = 4
		st.border_color = accent
	p.add_theme_stylebox_override("panel", st)
	p.custom_minimum_size = Vector2(0, 40)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var pl := UiStyle.g_label(str(pos), 15, UiStyle.G_TEXT_2, "black")
	pl.custom_minimum_size = Vector2(26, 0)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_child(pl)
	h.add_child(TeamEmblems.make_rect(String(car.team["id"]), 26))
	h.add_child(UiStyle.g_label(car.code(), 15, UiStyle.G_TEXT, "black"))
	h.add_child(UiStyle.hspacer())
	h.add_child(UiStyle.g_label(UiStyle.format_time(t).replace(".", ","), 15, UiStyle.G_TEXT, "black"))
	var gap := UiStyle.g_label("—" if pos == 1 else "+" + ("%.3f" % (t - lead)).replace(".", ","), 13, UiStyle.G_TEXT_3, "bold")
	gap.custom_minimum_size = Vector2(66, 0)
	gap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(gap)
	p.add_child(h)
	return p


# --- Q3: a pole em destaque ---------------------------------------------------------------------

func _pole_body(body: HBoxContainer, sim: QualiSim, seg: int, order: Array) -> void:
	if order.is_empty():
		return
	var pole: CarState = order[0]
	var accent := UiStyle.team_accent(pole.team)
	var t0: float = sim.best[pole][seg]
	var hero := PanelContainer.new()
	hero.custom_minimum_size = Vector2(470, 0)
	var hs := UiStyle.g_box(Color(accent, 0.55).lerp(Color(0.06, 0.07, 0.09), 0.35), 24, 22, 20)
	hero.add_theme_stylebox_override("panel", hs)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 8)
	hero.add_child(hv)
	var tag := _chip("Pole position", POLE_GOLD, UiStyle.G_INK, "trophy")
	tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	hv.add_child(tag)
	var avc := CenterContainer.new()
	avc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	avc.add_child(DriverPhotos.make_avatar(pole.driver, accent, 170))
	hv.add_child(avc)
	var full := pole.display_name()
	hv.add_child(UiStyle.g_label(full.get_slice(" ", full.get_slice_count(" ") - 1), 50, UiStyle.G_TEXT, "black"))
	var tr := HBoxContainer.new()
	tr.add_theme_constant_override("separation", 12)
	tr.add_child(TeamEmblems.make_rect(String(pole.team["id"]), 34))
	tr.add_child(UiStyle.g_label(UiStyle.format_time(t0).replace(".", ","), 36, UiStyle.G_TEXT, "black"))
	if order.size() > 1:
		var gap := float(sim.best[order[1]][seg]) - t0
		tr.add_child(_chip("+%s sobre o 2º" % ("%.3f" % gap).replace(".", ","), Color(POLE_GOLD, 0.25), POLE_GOLD))
	hv.add_child(tr)
	body.add_child(hero)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_child(UiStyle.g_caption("Grid · do 2º ao %dº" % mini(order.size(), 10)))
	for i in range(1, mini(order.size(), 10)):
		var row := _row(sim, order[i], i + 1, float(sim.best[order[i]][seg]), t0)
		if i == 1:  # primeira fila: um pouco maior e com faixa dourada
			row.custom_minimum_size = Vector2(0, 46)
			var st: StyleBoxFlat = row.get_theme_stylebox("panel").duplicate()
			st.border_width_left = 4
			st.border_color = POLE_GOLD
			row.add_theme_stylebox_override("panel", st)
		list.add_child(row)
	body.add_child(list)


static func _chip(text: String, fill: Color, fg: Color, icon_name: String = "") -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(fill, 15, 12, 4))
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	if icon_name != "":
		h.add_child(ScreenKit.icon(icon_name, 16, fg))
	h.add_child(UiStyle.g_label(text, 13, fg, "black"))
	p.add_child(h)
	return p
