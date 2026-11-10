extends Control
## Campeonatos da campanha — F1, F2 e F3 (mockups v20 aprovados, 2026-11-04). Abas da categoria e Pilotos × Construtores.
## À esquerda o top 3 em destaque (líder grande, com foto ou logo); à direita a tabela com a grade de resultados por corrida
## (cores: vitória, pódio, pontos, sem pontos, abandono) e, nos construtores, as zonas de acesso e rebaixamento.

const C_WIN := Color("#ffd24a")
const C_SILVER := Color("#d6d9df")
const C_BRONZE := Color("#d08a4a")
const C_POINTS := Color("#3c9d5d")
const C_OUT := Color(1, 1, 1, 0.12)
const C_DNF := Color("#E10600")

var campaign: Campaign
var _layer: Control
var _cat := "F1"
var _kind := "drivers"
var _content: Control
var _tabs: Control


func _ready() -> void:
	campaign = Session.campaign
	if campaign == null:
		Session.open_campaign.call_deferred()
		return
	var page := ScreenKit.garage_page(self, campaign.player_team)
	(page["backdrop"] as GarageBackdrop).set_glow(UiStyle.team_color(campaign.player_team), 0.14)
	_layer = page["layer"]
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UiStyle.SP_L)
	var back := ScreenKit.round_button("back", 52, "Voltar à sede")
	back.pressed.connect(Session.open_campaign_hub)
	head.add_child(back)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -2)
	titles.add_child(UiStyle.g_caption("%s · após %d de %d rodadas" % [campaign.team()["name"], campaign.round, Campaign.calendar().size()]))
	titles.add_child(UiStyle.g_label("CAMPEONATOS", 30, UiStyle.G_TEXT, "black"))
	head.add_child(titles)
	ScreenKit.place(head, _layer, Control.PRESET_TOP_LEFT, Vector2(44, 20))
	ScreenKit.campaign_nav(_layer, "standings")
	_cat = campaign.category()  # campanha na F2/F3: abre na categoria da equipe
	for a: String in OS.get_cmdline_user_args():  # (capturas) --cat=F2 --kind=teams
		if a.begins_with("--cat="):
			_cat = a.trim_prefix("--cat=")
		elif a.begins_with("--kind="):
			_kind = a.trim_prefix("--kind=")
	_refresh()


func _refresh() -> void:
	if _tabs != null:
		_tabs.queue_free()
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 110)
	var cats: Array = [["F1", "F1"]]
	for c: String in ["F2", "F3"]:
		if campaign.series.has(c):
			cats.append([c, c])
	_tabs.add_child(ScreenKit.segmented(cats, _cat, func(v: Variant) -> void: _cat = String(v); _refresh()))
	_tabs.add_child(ScreenKit.segmented([["drivers", "Pilotos"], ["teams", "Construtores"]], _kind, func(v: Variant) -> void: _kind = String(v); _refresh()))
	ScreenKit.place(_tabs, _layer, Control.PRESET_TOP_LEFT, Vector2(44, 88))
	if _content != null:
		_content.queue_free()
	_content = Control.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_content)
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var rows := _rows()
	_podium(rows)
	_table(rows)


# --- dados da categoria ----------------------------------------------------------------------------------

## [{id, name, sub, color, team_id, points, results: [pos | -1 abandono | 0 não correu], mine}]
func _rows() -> Array:
	var out: Array = []
	if _cat == "F1":
		var drivers := {}
		for d: Dictionary in campaign.drivers():
			drivers[d["id"]] = d
		if _kind == "drivers":
			for r: Array in campaign.driver_standings():
				var d: Dictionary = drivers.get(r[0], {})
				var t := GameData.team_by_id(campaign.teams(), String(d.get("team", "")))
				out.append({"id": r[0], "name": String(d.get("name", r[0])), "sub": String(t.get("name", "")), "color": Color(t.get("color", "#888888")),
					"team_id": String(d.get("team", "")), "points": int(r[1]), "results": _f1_results([r[0]]), "mine": d.get("team", "") == campaign.player_team, "driver": d})
		else:
			for r: Array in campaign.team_standings():
				var t := GameData.team_by_id(campaign.teams(), String(r[0]))
				var ids: Array = campaign.drivers().filter(func(d: Dictionary) -> bool: return d["team"] == r[0]).map(func(d: Dictionary) -> String: return d["id"])
				out.append({"id": r[0], "name": String(t.get("name", r[0])), "sub": "", "color": Color(t.get("color", "#888888")), "team_id": r[0],
					"points": int(r[1]), "results": _f1_results(ids), "mine": r[0] == campaign.player_team})
		return out
	var s: Series = campaign.series[_cat]
	var people := {}
	for p: Dictionary in campaign.personnel.feeder():
		people[p["id"]] = p
	if _kind == "drivers":
		for r: Array in s.driver_standings():
			var p: Dictionary = people.get(r[0], {"id": r[0], "name": r[0]})
			var t := s.team(String(s.seat_of.get(r[0], "")))
			out.append({"id": r[0], "name": String(p.get("name", r[0])), "sub": String(t.get("name", "")), "color": Color(t.get("color", "#888888")),
				"team_id": String(t.get("id", "")), "points": int(r[1]), "results": s.driver_results(r[0]), "mine": false, "driver": p})
	else:
		for r: Array in s.team_standings():
			var t := s.team(String(r[0]))
			out.append({"id": r[0], "name": String(t.get("name", r[0])), "sub": "", "color": Color(t.get("color", "#888888")), "team_id": r[0],
				"points": int(r[1]), "results": s.team_results(r[0]), "mine": false})
	return out


## Melhor posição de um conjunto de pilotos em cada GP da F1 já disputado.
func _f1_results(ids: Array) -> Array:
	var out: Array = []
	for h: Dictionary in campaign.history:
		var res: Array = h.get("results", [])
		var best := 0
		for id: String in ids:
			var p := res.find(id) + 1
			if p > 0:
				best = p if best == 0 else mini(best, p)
		out.append(best)
	return out


func _total_rounds() -> int:
	if _cat == "F1":
		return Campaign.calendar().size()
	return (campaign.series[_cat] as Series).rounds.size()


# --- top 3 -------------------------------------------------------------------------------------------------

func _podium(rows: Array) -> void:
	if rows.is_empty():
		return
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	ScreenKit.place(col, _content, Control.PRESET_TOP_LEFT, Vector2(44, 150), Vector2(300, 0))
	var r0: Dictionary = rows[0]
	var lead := PanelContainer.new()
	lead.custom_minimum_size = Vector2(300, 220)
	lead.clip_contents = true
	var st := UiStyle.g_box((r0["color"] as Color).darkened(0.15), 22, 14, 14)
	lead.add_theme_stylebox_override("panel", st)
	var stack := Control.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lead.add_child(stack)
	var big := UiStyle.g_label("1", 170, Color(1, 1, 1, 0.12), "black")
	big.position = Vector2(196, 40)
	stack.add_child(big)
	var cap := UiStyle.g_caption("Líder", Color.WHITE)
	cap.position = Vector2(0, 0)
	stack.add_child(cap)
	var pic: Control = DriverPhotos.make_avatar(r0["driver"], r0["color"], 120) if r0.has("driver") else TeamEmblems.make_rect(String(r0["team_id"]), 110)
	pic.position = Vector2(0, 34)
	stack.add_child(pic)
	var nm := UiStyle.g_label(String(r0["name"]).replace(" ", "\n"), 20, Color.WHITE, "black")
	nm.add_theme_constant_override("line_spacing", -8)
	nm.position = Vector2(132, 40)
	stack.add_child(nm)
	var sub := UiStyle.g_label(String(r0["sub"]) if r0["sub"] != "" else _move_note(String(r0["id"]), 0, rows.size()), 12, Color(1, 1, 1, 0.85), "bold")
	sub.position = Vector2(132, 112)
	sub.custom_minimum_size = Vector2(140, 0)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(sub)
	var pts := UiStyle.g_label("%d pts" % int(r0["points"]), 30, Color.WHITE, "black")
	pts.position = Vector2(132, 142)
	stack.add_child(pts)
	col.add_child(lead)
	if rows.size() >= 3:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		for i in [1, 2]:
			var r: Dictionary = rows[i]
			var c := PanelContainer.new()
			c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			c.add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.07), 18, 8, 10))
			var v := VBoxContainer.new()
			v.alignment = BoxContainer.ALIGNMENT_CENTER
			v.add_theme_constant_override("separation", 4)
			var n := UiStyle.g_caption("%dº" % (i + 1))
			n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(n)
			var p2: Control = DriverPhotos.make_avatar(r["driver"], r["color"], 64) if r.has("driver") else TeamEmblems.make_rect(String(r["team_id"]), 56)
			p2.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			v.add_child(p2)
			var l := UiStyle.g_label(String(r["name"]).get_slice(" ", String(r["name"]).get_slice_count(" ") - 1) if r.has("driver") else String(r["name"]), 14, UiStyle.G_TEXT, "black")
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.clip_text = true
			v.add_child(l)
			var pl := UiStyle.g_label("%d pts" % int(r["points"]), 12, UiStyle.G_TEXT_2, "bold")
			pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(pl)
			c.add_child(v)
			h.add_child(c)
		col.add_child(h)
	if _kind == "teams":
		var how := PanelContainer.new()
		how.add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.07), 18, 14, 10))
		var hv := VBoxContainer.new()
		hv.add_child(UiStyle.g_caption("Como funciona"))
		how.add_child(hv)
		col.add_child(how)


func _move_note(_id: String, index: int, count: int) -> String:
	if _cat == "F2":
		return "sobe para a F1 se terminar assim" if index == 0 else ("desce para a F3" if index == count - 1 else "")
	if _cat == "F3":
		return "sobe para a F2 se terminar assim" if index == 0 else ""
	return "líder do campeonato"


# --- tabela ------------------------------------------------------------------------------------------------

func _table(rows: Array) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.05), 22, 14, 10))
	ScreenKit.place(card, _content, Control.PRESET_TOP_LEFT, Vector2(360, 150), Vector2(1280 - 44 - 360, 720 - 150 - 16))
	card.custom_minimum_size = Vector2(1280 - 44 - 360, 720 - 150 - 16)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 4)
	card.add_child(outer)
	var head := HBoxContainer.new()
	var hl := UiStyle.g_caption("Pos · %s" % ("piloto" if _kind == "drivers" else "equipe"))
	hl.custom_minimum_size = Vector2(250, 0)
	head.add_child(hl)
	var leg := HBoxContainer.new()
	leg.add_theme_constant_override("separation", 10)
	leg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	leg.alignment = BoxContainer.ALIGNMENT_END
	for e: Array in [["vitória", C_WIN], ["pódio", C_BRONZE], ["pontos", C_POINTS], ["sem pontos", C_OUT], ["abandono", C_DNF]]:
		var d := HBoxContainer.new()
		d.add_theme_constant_override("separation", 4)
		var sq := ColorRect.new()
		sq.color = e[1]
		sq.custom_minimum_size = Vector2(11, 11)
		sq.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		d.add_child(sq)
		d.add_child(UiStyle.g_label(e[0], 11, UiStyle.G_TEXT_2, "bold"))
		leg.add_child(d)
	head.add_child(leg)
	var pc := UiStyle.g_caption("Pts")
	pc.custom_minimum_size = Vector2(54, 0)
	pc.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(pc)
	outer.add_child(head)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 0)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var scroll := DragScroll.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	outer.add_child(scroll)
	var n := rows.size()
	var total := _total_rounds()
	for i in n:
		var r: Dictionary = rows[i]
		var zone := ""
		if _kind == "teams":
			if i == 0 and _cat != "F1":
				zone = "up"
			elif i == n - 1 and _cat != "F3":
				zone = "down"
		if zone == "down":
			list.add_child(_zone_bar("Rebaixamento para a %s" % ("F2" if _cat == "F1" else "F3"), false))
		list.add_child(_row(i, r, total, zone))
		if zone == "up":
			list.add_child(_zone_bar("Acesso para a %s · o campeão sobe no fim do ano" % ("F1" if _cat == "F2" else "F2"), true))


func _zone_bar(text: String, up: bool) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(Color(0.22, 0.83, 0.42, 0.16) if up else Color(0.88, 0.02, 0.0, 0.18), 7, 10, 3))
	p.add_child(UiStyle.g_label(text.to_upper(), 11, Color("#7fe0b1") if up else Color("#ff8a80"), "black"))
	return p


func _row(i: int, r: Dictionary, total: int, zone: String) -> Control:
	var p := PanelContainer.new()
	var st := UiStyle.g_box(Color(0.07, 0.28, 0.96, 0.25) if bool(r["mine"]) else Color(0, 0, 0, 0), 10, 4, 4)
	if zone != "":
		st.border_width_left = 4
		st.border_color = C_POINTS if zone == "up" else C_DNF
	p.add_theme_stylebox_override("panel", st)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var pos := PanelContainer.new()
	pos.custom_minimum_size = Vector2(34, 26)
	pos.add_theme_stylebox_override("panel", UiStyle.g_box(r["color"], 7, 0, 0))
	var pl := UiStyle.g_label(str(i + 1), 14, Color.WHITE if (r["color"] as Color).get_luminance() < 0.6 else UiStyle.G_INK, "black")
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pos.add_child(pl)
	pos.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(pos)
	var em := TeamEmblems.make_rect(String(r["team_id"]), 22)
	h.add_child(em)
	var name := String(r["name"])
	if r.has("driver"):
		name = name.get_slice(" ", name.get_slice_count(" ") - 1).to_upper()
	var nl := UiStyle.g_label(name, 15, UiStyle.G_TEXT, "black")
	nl.clip_text = true
	nl.custom_minimum_size = Vector2(122 if r["sub"] != "" else 196, 0)
	h.add_child(nl)
	if r["sub"] != "":  # largura fixa: a grade de resultados fica alinhada em todas as linhas
		var sl := UiStyle.g_label(String(r["sub"]), 11, UiStyle.G_TEXT_3, "bold")
		sl.clip_text = true
		sl.custom_minimum_size = Vector2(66, 0)
		sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(sl)
	var grid := ResultGrid.new()
	grid.results = r["results"]
	grid.total = total
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(grid)
	var pts := UiStyle.g_label(str(int(r["points"])), 17, UiStyle.G_TEXT, "black")
	pts.custom_minimum_size = Vector2(52, 0)
	pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(pts)
	p.add_child(h)
	p.custom_minimum_size = Vector2(0, 36)
	return p


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.open_campaign_hub()


## Quadradinhos de resultado por corrida (vitória, pódio, pontos, sem pontos, abandono; tracejado = ainda não correu).
class ResultGrid:
	extends Control
	var results: Array = []
	var total := 22

	func _init() -> void:
		custom_minimum_size = Vector2(0, 24)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var cell := minf(22.0, (size.x - 3.0 * (total - 1)) / maxf(total, 1))
		var font := UiStyle.G_BLACK
		var fs := UiStyle.fs(10)
		for i in total:
			var r := Rect2(i * (cell + 3.0), (size.y - cell) * 0.5, cell, cell)
			if i >= results.size():
				var sb := StyleBoxFlat.new()
				sb.bg_color = Color(0, 0, 0, 0)
				sb.set_border_width_all(1)
				sb.border_color = Color(1, 1, 1, 0.15)
				sb.set_corner_radius_all(5)
				draw_style_box(sb, r)
				continue
			var v := int(results[i])
			var c := C_OUT
			var ink := Color("#c3c9d3")
			var txt := str(v)
			if v < 0:
				c = C_DNF
				ink = Color.WHITE
				txt = "✕"
			elif v == 0:
				txt = "–"
			elif v == 1:
				c = C_WIN
				ink = UiStyle.G_INK
			elif v == 2:
				c = C_SILVER
				ink = UiStyle.G_INK
			elif v == 3:
				c = C_BRONZE
				ink = UiStyle.G_INK
			elif v <= 10:
				c = C_POINTS
				ink = Color.WHITE
			draw_style_box(UiStyle.g_box(c, 5, 0, 0), r)
			var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			draw_string(font, r.position + Vector2((cell - w) * 0.5, cell * 0.5 + fs * 0.36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)
