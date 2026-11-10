class_name WorldHub
extends Control
## Painel do Campeonato Mundial F1 (mockup v29-2 aprovado, 2026-11-10): próximo GP com o botão de jogar, tabelas de
## pilotos e construtores, vencedores do calendário e motor/câmbio dos seus carros (limite de 4 na temporada).

const W := 1280.0
const H := 720.0

var world: WorldChampionship
var _tab := "drivers"
var _stage: Control
var _standings_box: VBoxContainer
var _tab_buttons: Dictionary = {}


func _ready() -> void:
	Tips.show_once.call_deferred(self, "world")
	world = Session.world
	if world == null:
		Session.go_to_title.call_deferred()
		return
	if world.season_over():
		Session.open_world_final.call_deferred()
		return
	var team := GameData.team_by_id(GameData.teams(), world.player_team)
	var color := Color(team["color"])
	var page := ScreenKit.garage_page(self, world.player_team)
	(page["backdrop"] as GarageBackdrop).set_glow(color)
	var layer: Control = page["layer"]
	_stage = Control.new()  # as posições do mockup são em 1280×720; em telas mais largas o painel fica centralizado
	_stage.set_anchors_preset(Control.PRESET_CENTER)
	_stage.offset_left = -W / 2.0
	_stage.offset_right = W / 2.0
	_stage.offset_top = -H / 2.0
	_stage.offset_bottom = H / 2.0
	layer.add_child(_stage)
	_top_bar(team)
	_stage.add_child(_gp_card(Rect2(40, 96, 560, 330)))
	_stage.add_child(_cars_card(Rect2(40, 440, 560, 244), team))
	_stage.add_child(_standings_card(Rect2(620, 96, 620, 436)))
	_stage.add_child(_strip_card(Rect2(620, 546, 620, 138)))
	layer.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(layer, "modulate:a", 1.0, 0.18)


# --- barra do topo -----------------------------------------------------------------------------

func _top_bar(team: Dictionary) -> void:
	var back := ScreenKit.round_button("back", 48, "Voltar ao menu")
	back.pressed.connect(Session.go_to_title)
	back.position = Vector2(18, 14)
	_stage.add_child(back)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -2)
	v.add_child(UiStyle.g_caption("Temporada %d · %s" % [world.season, String(team.get("name", ""))]))
	v.add_child(UiStyle.g_label("Campeonato Mundial F1", 26, Color("#F5C542"), "black"))
	v.position = Vector2(78, 8)
	_stage.add_child(v)
	var pills := HBoxContainer.new()
	pills.add_theme_constant_override("separation", 10)
	var stats := ScreenKit.glass_pill_button("Estatísticas", 150)
	stats.pressed.connect(Session.open_world_table.bind("stats", ""))
	stats.custom_minimum_size = Vector2(150, 46)
	pills.add_child(stats)
	var cal_n := WorldChampionship.calendar().size()
	pills.add_child(_pill("RD %d/%d" % [world.round + 1, cal_n], "cal", UiStyle.G_TEXT))
	var drivers := world.driver_ids_of(world.player_team)
	var best_pos := 99
	var pts := 0
	for id: String in drivers:
		best_pos = mini(best_pos, world.driver_position(id))
		pts += int(world.driver_points.get(id, 0))
	pills.add_child(_pill("%dº CONSTRUTORES · %d PTS" % [world.team_position(world.player_team), int(world.team_points.get(world.player_team, 0))], "trophy", Color("#F5C542")))
	pills.position = Vector2(W - 18 - 560, 14)
	pills.size = Vector2(560, 48)
	pills.alignment = BoxContainer.ALIGNMENT_END
	_stage.add_child(pills)


func _pill(text: String, icon_name: String, col: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.07), 23, 16, 0))
	p.custom_minimum_size = Vector2(0, 46)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(ScreenKit.icon(icon_name, 18, col))
	h.add_child(UiStyle.g_label(text, 15, UiStyle.G_TEXT, "black"))
	p.add_child(h)
	return p


# --- próximo GP ---------------------------------------------------------------------------------

func _gp_card(r: Rect2) -> Control:
	var rd := world.next_round()
	var circuit := GameData.circuit(rd["id"])
	var c := _card(r)
	var art := TextureRect.new()
	art.texture = CampaignHub.track_art(rd["id"])
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(art)
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.035, 0.05, 0.42)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(shade)
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 8)
	chips.add_child(_chip("Próximo GP", "flag", UiStyle.RED, Color.WHITE))
	chips.add_child(_chip(_date_text(String(rd["date"])), "cal", Color(0.04, 0.05, 0.07, 0.8), UiStyle.G_TEXT))
	chips.add_child(_chip("%d%%" % roundi(float(circuit.get("rain_probability", 0)) * 100.0), "rain", Color(0.04, 0.05, 0.07, 0.8), UiStyle.G_TEXT))
	if bool(rd.get("sprint", false)):
		chips.add_child(_chip("Sprint", "", UiStyle.SECTION["staff"], Color.WHITE))
	chips.position = Vector2(20, 16)
	c.add_child(chips)
	var nh := HBoxContainer.new()
	nh.add_theme_constant_override("separation", 12)
	nh.add_child(CampaignHub.flag_rect(String(circuit.get("country_code", "")), 30))
	var gp_name := CampaignHub.gp_short(String(rd["grand_prix"])).to_upper()
	var nm := UiStyle.g_label(gp_name, 40 if gp_name.length() <= 12 else 32, UiStyle.G_TEXT, "black")
	nm.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	nm.add_theme_constant_override("shadow_offset_y", 2)
	nh.add_child(nm)
	nh.position = Vector2(20, r.size.y - 144)
	c.add_child(nh)
	var go := CutButton.new()
	go.text = "JOGAR FIM DE SEMANA"
	go.custom_minimum_size = Vector2(r.size.x - 40, UiStyle.TOUCH_MAIN)
	go.size = go.custom_minimum_size
	go.position = Vector2(20, r.size.y - 76)
	go.pressed.connect(Session.play_world_round)
	c.add_child(go)
	return c


func _date_text(iso: String) -> String:
	var meses := ["JAN", "FEV", "MAR", "ABR", "MAI", "JUN", "JUL", "AGO", "SET", "OUT", "NOV", "DEZ"]
	var p := iso.split("-")
	return "%d %s" % [int(p[2]), meses[int(p[1]) - 1]] if p.size() == 3 else iso


# --- seus carros: motor e câmbio -------------------------------------------------------------------

func _cars_card(r: Rect2, team: Dictionary) -> Control:
	var c := _card(r)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.position = Vector2(20, 14)
	v.size = Vector2(r.size.x - 40, r.size.y - 28)
	c.add_child(v)
	v.add_child(UiStyle.g_caption("Seus carros · motor e câmbio (limite: %d na temporada)" % int(CarParts.LIMITS["pu"])))
	var ids := world.driver_ids_of(world.player_team)
	for i in mini(ids.size(), 2):
		v.add_child(_car_row(i, String(ids[i]), team))
	return c


func _car_row(car: int, driver_id: String, team: Dictionary) -> Control:
	var d: Dictionary = {}
	for dd: Dictionary in world.drivers():
		if dd["id"] == driver_id:
			d = dd
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var av := DriverPhotos.make_avatar(d, Color(team["color"]), 52)
	av.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(av)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", -2)
	names.custom_minimum_size = Vector2(150, 0)
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	names.add_child(NameFlag.make(String(d.get("name", "")).get_slice(" ", String(d.get("name", "")).get_slice_count(" ") - 1), String(d.get("nationality", "")), 18))
	names.add_child(UiStyle.g_label("P%d · %d PTS" % [world.driver_position(driver_id), int(world.driver_points.get(driver_id, 0))], 13, UiStyle.G_TEXT_2, "bold"))
	row.add_child(names)
	var grid := VBoxContainer.new()
	grid.add_theme_constant_override("separation", 4)
	grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for pid: String in ["pu", "gearbox"]:
		grid.add_child(_dots_row("Motor" if pid == "pu" else "Câmbio", world.parts.used_count(world.player_team, car, pid), int(CarParts.LIMITS[pid])))
	row.add_child(grid)
	var pen := world.parts.penalty_for(world.player_team, car)
	if int(pen["places"]) > 0:
		var parts_txt := ", ".join((pen["parts"] as Array).map(func(x: Dictionary) -> String: return "%dº %s" % [int(x["n"]), "motor" if x["part"] == "pu" else "câmbio"]))
		var warn := _chip("%s: −%s no grid" % [parts_txt, "fundo" if bool(pen["back"]) else str(int(pen["places"]))], "", Color(0.88, 0.02, 0.0, 0.25), Color("#ff8a80"))
		warn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(warn)
	return row


func _dots_row(label: String, used: int, limit: int) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	var l := UiStyle.g_label(label, 12, UiStyle.G_TEXT_2, "black")
	l.custom_minimum_size = Vector2(62, 0)
	h.add_child(l)
	for k in maxi(limit, used):
		var dot := PanelContainer.new()
		dot.custom_minimum_size = Vector2(14, 14)
		var col := Color(1, 1, 1, 0.14)
		if k < used:
			col = UiStyle.RED if k >= limit else Color("#F5C542")
		dot.add_theme_stylebox_override("panel", UiStyle.g_box(col, 7, 0, 0))
		h.add_child(dot)
	return h


# --- tabelas ------------------------------------------------------------------------------------------

func _standings_card(r: Rect2) -> Control:
	var c := _card(r)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	tabs.position = Vector2(20, 16)
	tabs.size = Vector2(r.size.x - 40, 40)
	var seg := ScreenKit.segmented([["drivers", "Pilotos"], ["teams", "Construtores"]], _tab, _set_tab)
	tabs.add_child(seg)
	tabs.add_child(UiStyle.hspacer())
	tabs.add_child(_chip("Após %d GP%s" % [world.round, "" if world.round == 1 else "s"], "trophy", Color(1, 1, 1, 0.1), UiStyle.G_TEXT))
	var expand := ScreenKit.round_button("expand", 44, "Ampliar o campeonato")
	expand.pressed.connect(func() -> void: Session.open_world_table(_tab, ""))
	tabs.add_child(expand)
	c.add_child(tabs)
	# todos os pilotos/equipes, rolando com o dedo (antes só o topo aparecia)
	var scroll := DragScroll.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.position = Vector2(20, 66)
	scroll.size = Vector2(r.size.x - 40, r.size.y - 78)
	_standings_box = VBoxContainer.new()
	_standings_box.add_theme_constant_override("separation", 4)
	_standings_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_standings_box)
	c.add_child(scroll)
	_fill_standings()
	return c


func _set_tab(v: String) -> void:
	_tab = v
	_fill_standings()


func _fill_standings() -> void:
	for ch in _standings_box.get_children():
		_standings_box.remove_child(ch)
		ch.queue_free()
	var rows: Array = world.driver_standings() if _tab == "drivers" else world.team_standings()
	for i in rows.size():
		_standings_box.add_child(_standing_row(i + 1, String(rows[i][0]), int(rows[i][1])))


func _standing_row(pos: int, id: String, pts: int) -> Control:
	var team_id := world.team_of(id) if _tab == "drivers" else id
	var mine := team_id == world.player_team
	var team := GameData.team_by_id(GameData.teams(), team_id)
	var accent := UiStyle.team_accent(team)
	var p := PanelContainer.new()
	var st := UiStyle.g_box(Color(accent, 0.22) if mine else Color(1, 1, 1, 0.05), 14, 12, 0)
	if mine:
		st.border_width_left = 4
		st.border_color = accent
	p.add_theme_stylebox_override("panel", st)
	p.custom_minimum_size = Vector2(0, 46)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var pl := UiStyle.g_label(str(pos), 15, UiStyle.G_TEXT_2, "black")
	pl.custom_minimum_size = Vector2(24, 0)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_child(pl)
	var wins := 0
	var pods := 0
	var label := ""
	var team_name := String(team.get("name", id))
	if _tab == "drivers":
		var d: Dictionary = {}
		for dd: Dictionary in world.drivers():
			if dd["id"] == id:
				d = dd
		var av := DriverPhotos.make_avatar(d, Color(team["color"]), 38)
		av.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(av)
		label = String(d.get("name", ""))  # nome e sobrenome
		wins = int(world.wins.get(id, 0))
		pods = int(world.podiums.get(id, 0))
	else:
		var em := TeamEmblems.make_rect(id, 34)
		em.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(em)
		label = team_name
		for did: String in world.driver_ids_of(id):
			wins += int(world.wins.get(did, 0))
			pods += int(world.podiums.get(did, 0))
	var nm := VBoxContainer.new()
	nm.add_theme_constant_override("separation", -2)
	nm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nm.add_child(UiStyle.g_label(label, 15, UiStyle.G_TEXT, "black"))
	if _tab == "drivers":
		var sub := HBoxContainer.new()
		sub.add_theme_constant_override("separation", 5)
		sub.add_child(TeamEmblems.make_rect(team_id, 14))
		sub.add_child(UiStyle.g_label(team_name, 12, UiStyle.G_TEXT_3, "bold"))
		nm.add_child(sub)
	h.add_child(nm)
	h.add_child(UiStyle.hspacer())
	for kv: Array in [["trophy", wins, Color("#F5C542")], ["up", pods, Color("#7fe0b1")]]:
		var m := HBoxContainer.new()
		m.add_theme_constant_override("separation", 3)
		m.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		m.add_child(ScreenKit.icon(String(kv[0]), 13, kv[2]))
		m.add_child(UiStyle.g_label(str(int(kv[1])), 12, UiStyle.G_TEXT_2, "black"))
		h.add_child(m)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", -3)
	pv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pv.custom_minimum_size = Vector2(64, 0)
	var pt_l := UiStyle.g_label(str(pts), 19, UiStyle.G_TEXT, "black")
	pt_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pv.add_child(pt_l)
	var rows: Array = world.driver_standings() if _tab == "drivers" else world.team_standings()
	var gap := UiStyle.g_label("LÍDER" if pos == 1 else "−%d" % (int(rows[0][1]) - pts), 11, UiStyle.G_TEXT_3, "bold")
	gap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pv.add_child(gap)
	h.add_child(pv)
	p.add_child(h)
	return p


# --- vencedores e calendário ------------------------------------------------------------------------------

func _strip_card(r: Rect2) -> Control:
	var c := _card(r)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.position = Vector2(20, 14)
	v.size = Vector2(r.size.x - 40, r.size.y - 28)
	c.add_child(v)
	v.add_child(UiStyle.g_caption("Vencedores · calendário"))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var cal := WorldChampionship.calendar()
	var first := clampi(world.round - 6, 0, maxi(cal.size() - 10, 0))
	for i in range(first, mini(first + 10, cal.size())):
		var rd: Dictionary = cal[i]
		var code := String(GameData.circuit(rd["id"]).get("country_code", "")).to_upper()
		var top := "·"
		var now := i == world.round
		if i < world.history.size():
			var res: Array = world.history[i]["results"]
			top = _code_of(String(res[0])) if not res.is_empty() else "·"
		elif now:
			top = code
		h.add_child(_round_tile(top, code if not now else "HOJE", now))
	v.add_child(h)
	return c


func _code_of(driver_id: String) -> String:
	for d: Dictionary in world.drivers():
		if d["id"] == driver_id:
			return String(d["code"])
	return "·"


func _round_tile(top: String, bottom: String, now: bool) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(52, 50)
	p.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_LIGHT if now else Color(1, 1, 1, 0.06), 10, 2, 2))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -2)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var ink := UiStyle.G_INK if now else UiStyle.G_TEXT
	var a := UiStyle.g_label(top, 14, ink, "black")
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(a)
	var b := UiStyle.g_label(bottom, 12, UiStyle.G_INK_2 if now else UiStyle.G_TEXT_3, "bold")
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(b)
	p.add_child(v)
	return p


# --- peças comuns ---------------------------------------------------------------------------------------------

func _card(r: Rect2) -> Control:
	var c := Panel.new()  # Panel (não PanelContainer): os filhos ficam onde eu os coloco, sem esticar para o cartão inteiro
	c.position = r.position
	c.custom_minimum_size = r.size
	c.size = r.size
	c.clip_contents = true
	var st := UiStyle.g_box(Color("#171a21"), 22, 0, 0)
	st.shadow_color = Color(0, 0, 0, 0.35)
	st.shadow_size = 10
	c.add_theme_stylebox_override("panel", st)
	return c


func _chip(text: String, icon_name: String, fill: Color, fg: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(fill, 15, 12, 4))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	if icon_name != "":
		h.add_child(ScreenKit.icon(icon_name, 16, fg))
	h.add_child(UiStyle.g_label(text, 13, fg, "black"))
	p.add_child(h)
	return p


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.go_to_title()
