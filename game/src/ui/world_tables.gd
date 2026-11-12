class_name WorldTables
extends PanelContainer
## Tabelas do Campeonato Mundial F1 (mockup v34, aprovado em 2026-11-10): classificação completa de pilotos e de construtores
## (rola arrastando) e estatísticas clicáveis (vitórias, poles, pódios, abandonos) com o ranking completo de cada uma.
## Usado na tela ampliada (`WorldTableScreen`) e nas abas Campeonato/Estatísticas do resultado de cada GP.

const GOLD := Color("#F5C542")
const VIOLET := Color("#C77DFF")
const MODE_NAMES := {"drivers": "Pilotos", "teams": "Construtores", "mates": "Companheiros", "stats": "Estatísticas"}
const STATS := [["wins", "Vitórias", "trophy"], ["poles", "Poles", "flag"], ["podiums", "Pódios", "up"], ["dnfs", "Abandonos", "lock"]]

var world: WorldChampionship
var modes: Array = ["drivers", "teams", "stats"]
var mode := "drivers"
var stat := ""  ## "" = os quatro quadros; senão o ranking completo dessa estatística
var by_team := false
var _col: VBoxContainer


func setup(p_world: WorldChampionship, p_modes: Array, p_mode: String, p_stat: String = "") -> void:
	world = p_world
	modes = p_modes
	mode = p_mode if p_modes.has(p_mode) else String(p_modes[0])
	stat = p_stat if mode == "stats" else ""
	add_theme_stylebox_override("panel", UiStyle.g_box(Color("#171a21"), 22, 24, 16))
	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 8)
	add_child(_col)
	_render()


static func stat_color(key: String) -> Color:
	return {"wins": GOLD, "poles": VIOLET, "podiums": UiStyle.G_UP, "dnfs": UiStyle.G_DOWN}.get(key, UiStyle.G_TEXT)


func _render() -> void:
	for c in _col.get_children():
		_col.remove_child(c)
		c.queue_free()
	_col.add_child(_head())
	match mode:
		"drivers", "teams":
			_col.add_child(_columns())
			_col.add_child(_table_list())
		"mates":
			_col.add_child(_mates_list())
		_:
			if stat == "":
				_col.add_child(_stat_grid())
			else:
				_col.add_child(_ranking_list())


func _ignore(n: Node) -> void:
	if n is Control and not n is Button:
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in n.get_children():
		_ignore(c)


# --- cabeça: abas, voltar, pilotos/equipes ----------------------------------------------------------

func _head() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	if mode == "stats" and stat != "":
		var back := ScreenKit.glass_pill_button("Estatísticas", 150)
		back.icon = load("res://assets/icons/back.svg")
		back.expand_icon = false
		back.add_theme_constant_override("icon_max_width", 20)
		back.pressed.connect(func() -> void:
			stat = ""
			_render())
		h.add_child(back)
		var opts: Array = []
		for s: Array in STATS:
			opts.append([s[0], s[1]])
		h.add_child(ScreenKit.segmented(opts, stat, func(v: String) -> void:
			stat = v
			_render()))
	elif modes.size() > 1:
		var opts2: Array = []
		for m: String in modes:
			opts2.append([m, MODE_NAMES[m]])
		h.add_child(ScreenKit.segmented(opts2, mode, func(v: String) -> void:
			mode = v
			stat = ""
			_render()))
	h.add_child(UiStyle.hspacer())
	if mode == "stats":
		h.add_child(ScreenKit.segmented([[false, "Pilotos"], [true, "Equipes"]], by_team, func(v: bool) -> void:
			by_team = v
			_render()))
	else:
		h.add_child(_chip("Após %d GP%s" % [world.round, "" if world.round == 1 else "s"]))
	return h


func _chip(text: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.1), 15, 12, 4))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	hb.add_child(ScreenKit.icon("trophy", 16, GOLD))
	hb.add_child(UiStyle.g_label(text, 13, UiStyle.G_TEXT, "black"))
	p.add_child(hb)
	return p


# --- classificação de pilotos / construtores -----------------------------------------------------------

func _columns() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.add_child(_fixed(UiStyle.g_caption(""), 26 + 38 + 24))
	var nm := UiStyle.g_caption("Piloto" if mode == "drivers" else "Equipe")
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(nm)
	for s: Array in STATS.slice(0, 3):
		var ic := ScreenKit.icon(String(s[2]), 15, stat_color(String(s[0])))
		var box := CenterContainer.new()
		box.custom_minimum_size = Vector2(62, 0)
		box.add_child(ic)
		h.add_child(box)
	var pts := UiStyle.g_caption("Pts")
	pts.custom_minimum_size = Vector2(90, 0)
	pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(pts)
	return h


func _fixed(c: Control, w: float) -> Control:
	c.custom_minimum_size.x = w
	return c


func _scroller(content: VBoxContainer) -> DragScroll:
	var sc := DragScroll.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.custom_minimum_size = Vector2(0, 120)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 5)
	sc.add_child(content)
	return sc


func _driver(id: String) -> Dictionary:
	for d: Dictionary in world.drivers():
		if d["id"] == id:
			return d
	return {}


func _ids_of(id: String) -> Array:
	return [id] if mode == "drivers" or by_team == false and not _is_team(id) else world.driver_ids_of(id)


func _is_team(id: String) -> bool:
	return not GameData.team_by_id(world.teams(), id).is_empty()


func _sum(src: Dictionary, ids: Array) -> int:
	var n := 0
	for i: String in ids:
		n += int(src.get(i, 0))
	return n


func _table_list() -> Control:
	var rows: Array = world.driver_standings() if mode == "drivers" else world.team_standings()
	var box := VBoxContainer.new()
	var lead := int(rows[0][1]) if not rows.is_empty() else 0
	for i in rows.size():
		box.add_child(_table_row(i + 1, String(rows[i][0]), int(rows[i][1]), lead))
	return _scroller(box)


func _identity(id: String, size: int) -> Array:
	## [ícone/foto, nome, subtítulo (Control), id da equipe]
	var team_id := world.team_of(id) if _is_driver(id) else id
	var team := GameData.team_by_id(world.teams(), team_id)
	var face: Control
	var name_text := ""
	var sub := HBoxContainer.new()
	sub.add_theme_constant_override("separation", 5)
	if _is_driver(id):
		var d := _driver(id)
		face = DriverPhotos.make_avatar(d, Color(team.get("color", "#888888")), size)
		name_text = String(d.get("name", id))
		sub.add_child(TeamEmblems.make_rect(team_id, 14))
		sub.add_child(UiStyle.g_label(String(team.get("name", team_id)), 12, UiStyle.G_TEXT_3, "bold"))
	else:
		face = TeamEmblems.make_rect(id, size)
		name_text = String(team.get("name", id))
		var names: Array[String] = []
		for did: String in world.driver_ids_of(id):
			var full := String(_driver(did).get("name", did))
			names.append(full.get_slice(" ", full.get_slice_count(" ") - 1))
		sub.add_child(UiStyle.g_label(" · ".join(names), 12, UiStyle.G_TEXT_3, "bold"))
	face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return [face, name_text, sub, team_id]


func _is_driver(id: String) -> bool:
	return not _is_team(id)


func _row_panel(team_id: String, height: float) -> PanelContainer:
	var mine := team_id == world.player_team
	var accent := UiStyle.team_accent(GameData.team_by_id(world.teams(), team_id))
	var p := PanelContainer.new()
	var st := UiStyle.g_box(Color(accent, 0.22) if mine else Color(1, 1, 1, 0.05), 14, 12, 0)
	if mine:
		st.border_width_left = 4
		st.border_color = accent
	p.add_theme_stylebox_override("panel", st)
	p.custom_minimum_size = Vector2(0, height)
	return p


func _name_block(ident: Array) -> VBoxContainer:
	var nm := VBoxContainer.new()
	nm.add_theme_constant_override("separation", -2)
	nm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var l := UiStyle.g_label(String(ident[1]), 16, UiStyle.G_TEXT, "black")
	l.clip_text = true
	nm.add_child(l)
	nm.add_child(ident[2])
	return nm


func _table_row(pos: int, id: String, pts: int, lead: int) -> Control:
	var ident := _identity(id, 38)
	var p := _row_panel(String(ident[3]), 52)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var pl := UiStyle.g_label(str(pos), 16, UiStyle.G_TEXT_2, "black")
	pl.custom_minimum_size = Vector2(26, 0)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(pl)
	h.add_child(ident[0])
	h.add_child(_name_block(ident))
	var ids: Array = [id] if mode == "drivers" else world.driver_ids_of(id)
	for s: Array in STATS.slice(0, 3):
		var src: Dictionary = {"wins": world.wins, "poles": world.poles, "podiums": world.podiums}[String(s[0])]
		var v := UiStyle.g_label(str(_sum(src, ids)), 16, stat_color(String(s[0])), "black")
		v.custom_minimum_size = Vector2(62, 0)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(v)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", -3)
	pv.custom_minimum_size = Vector2(90, 0)
	pv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pt := UiStyle.g_label(str(pts), 20, UiStyle.G_TEXT, "black")
	pt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pv.add_child(pt)
	var gap := UiStyle.g_label("LÍDER" if pos == 1 else "−%d" % (lead - pts), 11, UiStyle.G_TEXT_3, "bold")
	gap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pv.add_child(gap)
	h.add_child(pv)
	p.add_child(h)
	return p


# --- duelo de companheiros (mockup v35) ------------------------------------------------------------

func _mates_list() -> Control:
	var box := VBoxContainer.new()
	for row: Array in world.team_standings():
		var duel := world.teammate_duel(String(row[0]))
		if not duel.is_empty():
			box.add_child(_mate_card(String(row[0]), duel))
	var sc := _scroller(box)
	box.add_theme_constant_override("separation", 8)
	return sc


func _mate_side(id: String, team_color: Color, right: bool) -> Control:
	var d := _driver(id)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.custom_minimum_size = Vector2(250, 0)
	var face := DriverPhotos.make_avatar(d, team_color, 52)
	face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nm := UiStyle.g_label(String(d.get("name", id)), 17, UiStyle.G_TEXT, "black")
	nm.clip_text = true
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(nm)
	var st := HBoxContainer.new()
	st.add_theme_constant_override("separation", 10)
	st.alignment = BoxContainer.ALIGNMENT_END if right else BoxContainer.ALIGNMENT_BEGIN
	for kv: Array in [["trophy", world.wins, "wins"], ["up", world.podiums, "podiums"], ["lock", world.dnfs, "dnfs"]]:
		var m := HBoxContainer.new()
		m.add_theme_constant_override("separation", 3)
		m.add_child(ScreenKit.icon(String(kv[0]), 13, stat_color(String(kv[2]))))
		m.add_child(UiStyle.g_label(str(int((kv[1] as Dictionary).get(id, 0))), 12, UiStyle.G_TEXT_2, "black"))
		st.add_child(m)
	v.add_child(st)
	if right:
		h.add_child(v)
		h.add_child(face)
	else:
		h.add_child(face)
		h.add_child(v)
	return h


func _mate_row(x: int, y: int, col: Color, icon_name: String, label: String) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	for side in 2:
		if side == 1:
			var bar := ProgressBar.new()
			bar.show_percentage = false
			bar.max_value = maxf(1.0, float(x + y))
			bar.value = x if x + y > 0 else 0.5
			bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			bar.custom_minimum_size = Vector2(0, 10)
			bar.add_theme_stylebox_override("background", UiStyle.g_box(Color(1, 1, 1, 0.32 if x + y > 0 else 0.12), 5, 0, 0))
			bar.add_theme_stylebox_override("fill", UiStyle.g_box(col if x + y > 0 else Color(1, 1, 1, 0.12), 5, 0, 0))
			h.add_child(bar)
		var n := UiStyle.g_label(str(x if side == 0 else y), 19, UiStyle.G_TEXT, "black")
		n.custom_minimum_size = Vector2(46, 0)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if side == 0:
			h.add_child(n)
		else:
			h.add_child(n)
	var lb := HBoxContainer.new()
	lb.add_theme_constant_override("separation", 5)
	lb.custom_minimum_size = Vector2(104, 0)
	lb.add_child(ScreenKit.icon(icon_name, 14, UiStyle.G_TEXT_3))
	lb.add_child(UiStyle.g_label(label, 12, UiStyle.G_TEXT_3, "black"))
	h.add_child(lb)
	return h


func _mate_card(team_id: String, duel: Dictionary) -> Control:
	var team := GameData.team_by_id(world.teams(), team_id)
	var accent := UiStyle.team_accent(team)
	var p := _row_panel(team_id, 124)
	(p.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_right = 16
	p.set_meta("team", team_id)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	h.add_child(_mate_side(String(duel["a"]), Color(team.get("color", "#888888")), false))
	var mid := VBoxContainer.new()
	mid.add_theme_constant_override("separation", 4)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mid.add_child(_mate_row(int(duel["quali"][0]), int(duel["quali"][1]), accent, "flag", "Quali"))
	mid.add_child(_mate_row(int(duel["race"][0]), int(duel["race"][1]), accent, "cal", "Corrida"))
	mid.add_child(_mate_row(int(duel["points"][0]), int(duel["points"][1]), accent, "trophy", "Pontos"))
	h.add_child(mid)
	var gap := float(duel["gap"])
	var fast := String(duel["a"] if gap >= 0.0 else duel["b"])
	var gl := UiStyle.g_label("—" if int(duel["gap_n"]) == 0 else "%s +%s s" % [String(_driver(fast).get("code", fast)), String.num(absf(gap), 3).replace(".", ",")], 13, UiStyle.G_TEXT_2, "black")
	gl.custom_minimum_size = Vector2(104, 0)
	gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gl.tooltip_text = "Vantagem média na classificação"
	h.add_child(gl)
	h.add_child(_mate_side(String(duel["b"]), Color(team.get("color", "#888888")), true))
	p.add_child(h)
	return p


# --- estatísticas: quadros clicáveis e ranking completo ----------------------------------------------

## Todos (pilotos ou equipes) com a contagem da estatística, do maior ao menor; quem tem zero entra no fim, na ordem do campeonato.
func ranking(key: String) -> Array:
	var rows: Array = world.stat_table(key, by_team)
	var seen := {}
	for r: Array in rows:
		seen[r[0]] = true
	var order: Array = world.team_standings() if by_team else world.driver_standings()
	for r: Array in order:
		if not seen.has(r[0]):
			rows.append([r[0], 0])
	return rows


func _stat_grid() -> Control:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 14)
	g.size_flags_vertical = Control.SIZE_EXPAND_FILL
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for s: Array in STATS:
		g.add_child(_stat_tile(String(s[0]), String(s[1]), String(s[2])))
	return g


func _stat_tile(key: String, title: String, icon_name: String) -> Button:
	var col := stat_color(key)
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 150)
	b.set_meta("stat", key)
	for st: String in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		b.add_theme_stylebox_override(st, UiStyle.g_box(Color(1, 1, 1, 0.06 if st == "normal" else 0.10), 20, 0, 0))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	b.add_child(v)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 16
	v.offset_right = -16
	v.offset_top = 12
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.add_child(ScreenKit.icon(icon_name, 22, col))
	head.add_child(UiStyle.g_label(title, 16, UiStyle.G_TEXT, "black"))
	head.add_child(UiStyle.hspacer())
	head.add_child(ScreenKit.icon("chevron", 18, UiStyle.G_TEXT_2))
	v.add_child(head)
	var rows := ranking(key)
	var mx := maxf(1.0, float(rows[0][1])) if not rows.is_empty() else 1.0
	var shown := 0
	for r: Array in rows:
		if shown >= 3 or int(r[1]) <= 0:
			break
		v.add_child(_bar_row(String(r[0]), int(r[1]), mx, col, 32, 14))
		shown += 1
	if shown == 0:
		v.add_child(UiStyle.g_label("Ninguém ainda", 14, UiStyle.G_TEXT_3, "bold"))
	_ignore(b)
	b.pressed.connect(func() -> void:
		stat = key
		_render())
	ScreenKit.press_feedback(b)
	return b


func _bar_row(id: String, n: int, mx: float, col: Color, face_size: int, font: int) -> Control:
	var ident := _identity_for_stat(id, face_size)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	hb.add_child(ident[0])
	var nl := UiStyle.g_label(String(ident[1]), font, UiStyle.G_TEXT, "black")
	nl.custom_minimum_size = Vector2(150, 0)
	nl.clip_text = true
	nl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(nl)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.min_value = 0.0
	bar.max_value = mx
	bar.value = n
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.custom_minimum_size = Vector2(0, 8)
	bar.add_theme_stylebox_override("background", UiStyle.g_box(Color(1, 1, 1, 0.1), 4, 0, 0))
	bar.add_theme_stylebox_override("fill", UiStyle.g_box(col, 4, 0, 0))
	hb.add_child(bar)
	var cnt := UiStyle.g_label(str(n), 18, UiStyle.G_TEXT, "black")
	cnt.custom_minimum_size = Vector2(30, 0)
	cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cnt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(cnt)
	return hb


func _identity_for_stat(id: String, size: int) -> Array:
	return _identity(id, size)


func _ranking_list() -> Control:
	var col := stat_color(stat)
	var rows := ranking(stat)
	var mx := maxf(1.0, float(rows[0][1])) if not rows.is_empty() else 1.0
	var box := VBoxContainer.new()
	for i in rows.size():
		var id := String(rows[i][0])
		var ident := _identity(id, 38)
		var p := _row_panel(String(ident[3]), 54)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		var pl := UiStyle.g_label(str(i + 1), 16, UiStyle.G_TEXT_2, "black")
		pl.custom_minimum_size = Vector2(26, 0)
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(pl)
		h.add_child(ident[0])
		var nb := _name_block(ident)
		nb.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		nb.custom_minimum_size = Vector2(250, 0)
		h.add_child(nb)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.min_value = 0.0
		bar.max_value = mx
		bar.value = int(rows[i][1])
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.custom_minimum_size = Vector2(0, 10)
		bar.add_theme_stylebox_override("background", UiStyle.g_box(Color(1, 1, 1, 0.1), 5, 0, 0))
		bar.add_theme_stylebox_override("fill", UiStyle.g_box(col, 5, 0, 0))
		h.add_child(bar)
		var cnt := UiStyle.g_label(str(int(rows[i][1])), 22, UiStyle.G_TEXT, "black")
		cnt.custom_minimum_size = Vector2(44, 0)
		cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cnt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(cnt)
		p.add_child(h)
		box.add_child(p)
	return _scroller(box)
