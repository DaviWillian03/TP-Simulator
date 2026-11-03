class_name StandingsPanel
extends PanelContainer
## Torre de posições da corrida no estilo da transmissão da F1 (pedido do usuário, 2026-11-03).
##
## Cabeçalho com a volta. Uma linha tocável por piloto, com colunas FIXAS (nada cobre nada):
## posição na cor da equipe · emblema · seta verde/vermelha (ou bandeira quadriculada) · SIGLA de 3 letras ·
## diferença (ou NO BOX / FORA) · pneu · idade do pneu (rivais) ou barra de vida (seus carros) · extras na ponta
## direita, só para quem tem: volta mais rápida e investigação/punição, alinhados (cabem os dois). Tocar na linha segue o carro dele na pista.

signal driver_pressed(car: CarState)

const ROW_H := 25
const HEAD_H := 30

var sim: RaceSim
var interval_mode := true  ## true: diferença para o carro da frente; false: para o líder
var followed: CarState = null  ## carro em foco na câmera (linha destacada)
var _rows: Array[Dictionary] = []
var _row_cars: Array[CarState] = []
var _seg_front: Button
var _seg_leader: Button
var _lap_label: Label
var _prev_pos: Dictionary = {}  ## CarState -> posição na atualização anterior
var _arrow: Dictionary = {}  ## CarState -> [direção (+1 ganhou / -1 perdeu), até quando (ms)]
const ARROW_MS := 4000


func setup(p_sim: RaceSim) -> void:
	sim = p_sim
	custom_minimum_size.x = 266.0  # (a altura vem de quem posiciona a torre)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_GLASS, 20, 0, 0))
	clip_contents = true
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	add_child(v)
	v.add_child(_header())
	var scroll := DragScroll.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 0)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for i in sim.cars.size():
		var row := _make_row(i)
		_rows.append(row)
		_row_cars.append(null)
		list.add_child(row["button"])


func _header() -> Control:
	var h := HBoxContainer.new()
	h.custom_minimum_size = Vector2(0, HEAD_H)
	h.add_theme_constant_override("separation", 6)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 12)
	m.add_theme_constant_override("margin_right", 8)
	m.add_child(h)
	_lap_label = UiStyle.g_label("VOLTA –", 20, UiStyle.G_TEXT, "black")
	_lap_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_lap_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(_lap_label)
	var seg := PanelContainer.new()
	seg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	seg.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_SURFACE_HOVER, 14, 2, 2))
	var sh := HBoxContainer.new()
	sh.add_theme_constant_override("separation", 2)
	seg.add_child(sh)
	var group := ButtonGroup.new()
	_seg_front = _seg_button("À FRENTE", group, true)
	_seg_leader = _seg_button("LÍDER", group, false)
	_seg_front.pressed.connect(func() -> void:
		interval_mode = true
		refresh())
	_seg_leader.pressed.connect(func() -> void:
		interval_mode = false
		refresh())
	sh.add_child(_seg_front)
	sh.add_child(_seg_leader)
	h.add_child(seg)
	return m


func _seg_button(text: String, group: ButtonGroup, on: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.button_group = group
	b.button_pressed = on
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 26)
	ScreenKit._selectable_styles(b, 12)
	b.add_theme_font_size_override("font_size", UiStyle.fs(11))
	return b


func _make_row(index: int) -> Dictionary:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, ROW_H)
	b.tooltip_text = "Tocar para seguir este carro"
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 3)
	b.add_child(h)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 5
	h.offset_right = -6
	var pos := UiStyle.pos_cell(26.0)
	pos.custom_minimum_size = Vector2(26, 21)
	pos.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(pos.get_child(0) as Label).add_theme_font_override("font", UiStyle.G_BLACK)
	(pos.get_child(0) as Label).add_theme_font_size_override("font_size", UiStyle.fs(13))
	h.add_child(pos)
	var emblem := TeamEmblems.make_rect("", 20)
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(emblem)
	# seta de posição ganha/perdida; depois da bandeirada o mesmo lugar mostra a bandeira quadriculada
	var mark := Control.new()
	mark.custom_minimum_size = Vector2(14, 16)
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var arrow := StatusIcon.new()
	arrow.kind = "up"
	arrow.modulate.a = 0.0
	mark.add_child(arrow)
	arrow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var icons := {}
	var flag := StatusIcon.new()
	flag.kind = "finished"
	flag.visible = false
	mark.add_child(flag)
	flag.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icons["finished"] = flag
	h.add_child(mark)
	var name_l := UiStyle.g_label("", 14, UiStyle.G_TEXT, "black")
	name_l.custom_minimum_size = Vector2(40, 0)
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(name_l)
	icons["camera"] = StatusIcon.new()  # (foco agora é a borda da linha; mantido por compatibilidade)
	var gap := UiStyle.g_label("", 12, UiStyle.G_TEXT_2, "bold")
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.custom_minimum_size = Vector2(46, 0)
	gap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(gap)
	var tyre := TyreBadge.new()
	tyre.custom_minimum_size = Vector2(20, 20)
	h.add_child(tyre)
	var tail := Control.new()
	tail.custom_minimum_size = Vector2(28, 0)
	tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var age := UiStyle.g_label("", 12, UiStyle.G_TEXT_2)
	age.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	age.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tail.add_child(age)
	age.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var life := LifeBar.new()
	life.visible = false
	tail.add_child(life)
	life.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.add_child(tail)
	# extras na ponta direita, alinhados à direita: só aparecem para quem tem (volta mais rápida,
	# investigação/punição). Um ícone sozinho fica sempre na mesma coluna; cabem dois ao mesmo tempo.
	var extras := HBoxContainer.new()
	extras.alignment = BoxContainer.ALIGNMENT_END
	extras.add_theme_constant_override("separation", 2)
	extras.custom_minimum_size = Vector2(34, 16)
	extras.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	extras.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for kind: String in ["fastest", "investigation", "penalty"]:
		var ic := StatusIcon.new()
		ic.kind = kind
		ic.visible = false
		extras.add_child(ic)
		icons[kind] = ic
	h.add_child(extras)
	b.pressed.connect(func() -> void:
		if _row_cars[index] != null:
			driver_pressed.emit(_row_cars[index]))
	return {"button": b, "pos": pos, "emblem": emblem, "arrow": arrow, "name": name_l, "icons": icons, "gap": gap,
		"tyre": tyre, "age": age, "life": life}


static func surname(full_name: String) -> String:
	return full_name.get_slice(" ", full_name.get_slice_count(" ") - 1).to_upper()


func refresh() -> void:
	var order := sim.standings()
	_lap_label.text = "FIM" if sim.chequered else "VOLTA %d/%d" % [sim.leader_lap(), sim.total_laps]
	for i in _rows.size():
		var car := order[i]
		_row_cars[i] = car
		var row: Dictionary = _rows[i]
		var retired := car.retired
		var b: Button = row["button"]
		var mine := car.is_player
		var focus := car == followed
		var fill := Color(UiStyle.team_color_from(sim_teams(), car.team["id"]), 0.28) if mine else (Color(1, 1, 1, 0.12) if focus else Color(0, 0, 0, 0))
		for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
			var st := UiStyle.g_box(fill if s == "normal" else Color(1, 1, 1, 0.1), 0, 0, 0)
			st.border_color = Color(1, 1, 1, 0.06)
			st.border_width_bottom = 1
			if focus:
				st.border_width_left = 4
				st.border_color = Color(UiStyle.G_LIGHT)
				st.border_width_bottom = 1
			b.add_theme_stylebox_override(s, st)
		UiStyle.set_pos_cell(row["pos"], "–" if retired else str(i + 1), Color(1, 1, 1, 0.18) if retired else car.team_color())
		(row["pos"] as PanelContainer).add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.18) if retired else car.team_color(), 7, 0, 0))
		(row["pos"].get_child(0) as Label).add_theme_color_override("font_color", UiStyle.G_TEXT_2 if retired else UiStyle.contrast_text(car.team_color()))
		var emblem: TextureRect = row["emblem"]
		emblem.texture = TeamEmblems.get_texture(car.team["id"])
		emblem.modulate.a = 0.4 if retired else 1.0
		var name_l: Label = row["name"]
		name_l.text = car.code()
		name_l.add_theme_color_override("font_color", UiStyle.G_TEXT_OFF if retired else UiStyle.G_TEXT)
		var icons: Dictionary = row["icons"]
		icons["fastest"].visible = sim.fastest_lap_car == car and not retired
		var penalty := (car.penalty_pending_s > 0.0 or car.drive_through) and not retired
		icons["penalty"].visible = penalty
		icons["investigation"].visible = not penalty and not car.investigation.is_empty() and not retired
		icons["finished"].visible = car.finished and not car.disqualified  # recebeu a bandeirada
		# seta de posição: verde ao ganhar, vermelha ao perder (some depois de alguns segundos)
		var now := Time.get_ticks_msec()
		var p := i + 1
		if _prev_pos.has(car) and int(_prev_pos[car]) != p and not retired:
			_arrow[car] = [1 if p < int(_prev_pos[car]) else -1, now + ARROW_MS]
		_prev_pos[car] = p
		var arrow: StatusIcon = row["arrow"]
		var arr: Array = _arrow.get(car, [0, 0])
		var show_arrow := int(arr[1]) > now and not retired
		arrow.kind = "up" if int(arr[0]) > 0 else "down"
		arrow.modulate.a = 1.0 if show_arrow and not car.finished else 0.0
		arrow.queue_redraw()
		var gap: Label = row["gap"]
		gap.text = "DSQ" if car.disqualified else ("FORA" if retired else ("NO BOX" if car.in_pit else ("RODOU" if car.stall_s > 0.0 else _gap_text(car, i, order))))
		var special := car.in_pit or car.stall_s > 0.0
		gap.add_theme_color_override("font_color", UiStyle.G_TEXT_OFF if retired or car.disqualified else (UiStyle.RED if car.in_pit else (Color("#ffd24a") if car.stall_s > 0.0 else UiStyle.G_TEXT_2)))
		gap.add_theme_font_override("font", UiStyle.G_BLACK if special else UiStyle.G_BOLD)
		var compound: Dictionary = sim.tyres.compounds[car.tyre]
		var tyre: TyreBadge = row["tyre"]
		tyre.visible = not retired
		tyre.set_compound(compound["letter"], Color(compound["color"]))
		var age: Label = row["age"]
		var life: LifeBar = row["life"]
		age.visible = not retired and not mine
		life.visible = not retired and mine
		age.text = "%dv" % car.tyre_laps
		if mine:
			life.set_life(1.0 - clampf(car.tyre_wear, 0.0, 1.0))


func sim_teams() -> Array:
	return Session.campaign.teams() if Session.campaign != null else GameData.teams()


func _gap_text(car: CarState, index: int, order: Array[CarState]) -> String:
	if index == 0:
		return "Líder"
	var behind := sim.laps_behind_leader(car)
	if behind > 0:
		return "+%d V" % behind
	if interval_mode:
		var ahead := order[index - 1]
		if not ahead.retired and sim.laps_behind_leader(ahead) == 0:
			return "+%.1f" % maxf(0.0, sim.gap_to_leader_s(car) - sim.gap_to_leader_s(ahead))
	return "+%.1f" % sim.gap_to_leader_s(car)


## Ícone de status ao lado do nome: forma própria para cada caso (não depende só da cor).
class StatusIcon:
	extends Control

	var kind := "fastest"

	func _init() -> void:
		custom_minimum_size = Vector2(16, 16)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2.0
		match kind:
			"fastest":  # relógio roxo
				draw_arc(c + Vector2(0, 1), 6.0, 0.0, TAU, 20, Color("#c77dff"), 2.0, true)
				draw_line(c + Vector2(0, 1), c + Vector2(0, -2.5), Color("#c77dff"), 1.8, true)
				draw_line(c + Vector2(0, 1), c + Vector2(2.5, 2.5), Color("#c77dff"), 1.8, true)
				draw_line(c + Vector2(-2, -6.5), c + Vector2(2, -6.5), Color("#c77dff"), 1.8, true)
			"investigation":  # triângulo amarelo com "!"
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -7), c + Vector2(7.5, 6), c + Vector2(-7.5, 6)]), Color("#ffd24a"))
				draw_line(c + Vector2(0, -2.5), c + Vector2(0, 1.5), Color("#11141a"), 1.8, true)
				draw_circle(c + Vector2(0, 3.8), 1.0, Color("#11141a"))
			"penalty":  # círculo vermelho com "!"
				draw_circle(c, 7.0, Color("#E10600"), true, -1.0, true)
				draw_line(c + Vector2(0, -3.5), c + Vector2(0, 1.0), Color.WHITE, 1.8, true)
				draw_circle(c + Vector2(0, 3.8), 1.0, Color.WHITE)
			"finished":  # bandeira quadriculada: já recebeu a bandeirada
				draw_line(c + Vector2(-6, -7), c + Vector2(-6, 7.5), Color(UiStyle.G_LIGHT), 1.6, true)
				var cell := 3.0
				for row in 3:
					for col in 4:
						var on := (row + col) % 2 == 0
						draw_rect(Rect2(c + Vector2(-5.2 + col * cell, -7 + row * cell), Vector2(cell, cell)), Color.WHITE if on else Color("#11141a"))
				draw_rect(Rect2(c + Vector2(-5.2, -7), Vector2(4 * cell, 3 * cell)), Color(UiStyle.G_LIGHT), false, 1.0)
			"up":  # ganhou posição: triângulo verde
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -5), c + Vector2(5, 3), c + Vector2(-5, 3)]), Color("#39d36b"))
			"down":  # perdeu posição: triângulo vermelho
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, 5), c + Vector2(5, -3), c + Vector2(-5, -3)]), Color("#ff4d3d"))
			"camera":  # em foco
				draw_rect(Rect2(c + Vector2(-7, -3.5), Vector2(14, 9)), Color(UiStyle.G_LIGHT), false, 1.6)
				draw_circle(c + Vector2(0, 1), 2.4, Color(UiStyle.G_LIGHT), false, 1.6, true)


## Barra de vida do pneu: começa cheia e vai esvaziando; muda de cor perto do fim.
class LifeBar:
	extends Control

	var life := 1.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_life(v: float) -> void:
		if not is_equal_approx(v, life):
			life = v
			queue_redraw()

	func _draw() -> void:
		var h := 8.0
		var y := (size.y - h) / 2.0
		draw_rect(Rect2(0, y, size.x, h), Color(1, 1, 1, 0.12))
		var col := Color("#f3f4f6") if life > 0.4 else (Color("#F5C400") if life > 0.2 else Color("#ff6b5e"))
		draw_rect(Rect2(0, y, size.x * clampf(life, 0.0, 1.0), h), col)
