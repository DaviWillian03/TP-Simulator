class_name WorldResult
extends Control
## Resultado de cada GP do Campeonato Mundial F1 + estatísticas da temporada (mockups v30, aprovados em 2026-11-10).
## Três abas: RESULTADO (pódio, pole, melhor volta e do 4º em diante), CAMPEONATO (tabelas com quem subiu/desceu) e
## ESTATÍSTICAS (vitórias, poles, pódios e abandonos por piloto ou por equipe). CONTINUAR volta ao painel.

const W := 1280.0
const H := 720.0
const GOLD := Color("#F5C542")

var world: WorldChampionship
var _tab := "result"
var _stage: Control
var _body: Control
var _by_team := false
var _tabs_holder: Control


func _ready() -> void:
	world = Session.world
	if world == null:
		Session.go_to_title.call_deferred()
		return
	_tab = Session.world_result_tab
	if _tab == "result" and world.history.is_empty():
		_tab = "stats"
	var team := GameData.team_by_id(GameData.teams(), world.player_team)
	var page := ScreenKit.garage_page(self, world.player_team)
	(page["backdrop"] as GarageBackdrop).set_glow(Color(team["color"]))
	var layer: Control = page["layer"]
	_stage = Control.new()
	_stage.set_anchors_preset(Control.PRESET_CENTER)
	_stage.offset_left = -W / 2.0
	_stage.offset_right = W / 2.0
	_stage.offset_top = -H / 2.0
	_stage.offset_bottom = H / 2.0
	layer.add_child(_stage)
	_top_bar()
	_tabs_holder = Control.new()
	_tabs_holder.position = Vector2(30, 92)
	_stage.add_child(_tabs_holder)
	_body = Control.new()
	_body.size = Vector2(W, H)
	_stage.add_child(_body)
	var go := CutButton.new()
	go.text = "CONTINUAR"
	go.custom_minimum_size = Vector2(260, UiStyle.TOUCH_MAIN)
	go.size = go.custom_minimum_size
	go.position = Vector2(W - 30 - 260, H - 30 - UiStyle.TOUCH_MAIN)
	go.pressed.connect(_continue)
	_stage.add_child(go)
	_build_tabs()
	_show_tab()
	layer.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(layer, "modulate:a", 1.0, 0.18)


func _continue() -> void:
	if world.season_over():
		Session.open_world_final()
	else:
		Session.open_world_hub()


func _top_bar() -> void:
	var back := ScreenKit.round_button("back", 48, "Voltar ao painel")
	back.pressed.connect(_continue)
	back.position = Vector2(18, 14)
	_stage.add_child(back)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -2)
	var last: Dictionary = world.history.back() if not world.history.is_empty() else {}
	v.add_child(UiStyle.g_caption("Campeonato Mundial F1 · rodada %d" % int(last.get("round", world.round)) if not last.is_empty() else "Campeonato Mundial F1 · temporada %d" % world.season))
	v.add_child(UiStyle.g_label("Resultado do GP" if _tab == "result" else ("Campeonato" if _tab == "champ" else "Estatísticas"), 26, GOLD, "black"))
	v.position = Vector2(78, 8)
	v.name = "Heading"
	_stage.add_child(v)


func _build_tabs() -> void:
	for ch in _tabs_holder.get_children():
		ch.queue_free()
	var opts: Array = []
	if not world.history.is_empty():
		opts.append(["result", "Resultado"])
	opts.append_array([["champ", "Campeonato"], ["stats", "Estatísticas"]])
	var seg := ScreenKit.segmented(opts, _tab, func(v: String) -> void:
		_tab = v
		_show_tab())
	_tabs_holder.add_child(seg)
	if _tab == "stats":  # pilotos ou construtores
		var sw := ScreenKit.segmented([[false, "Pilotos"], [true, "Equipes"]], _by_team, func(v: bool) -> void:
			_by_team = v
			_show_tab())
		sw.position = Vector2(W - 60 - 220, 0)
		_tabs_holder.add_child(sw)


func _show_tab() -> void:
	for ch in _body.get_children():
		ch.queue_free()
	_build_tabs()
	var head := _stage.get_node_or_null("Heading")
	if head != null:
		((head as VBoxContainer).get_child(1) as Label).text = "Resultado do GP" if _tab == "result" else ("Campeonato" if _tab == "champ" else "Estatísticas")
	match _tab:
		"result":
			_result_tab()
		"champ":
			_champ_tab()
		_:
			_stats_tab()


# --- helpers ------------------------------------------------------------------------------------

func _driver(id: String) -> Dictionary:
	for d: Dictionary in world.drivers():
		if d["id"] == id:
			return d
	return {}


func _team_color(team_id: String) -> Color:
	return Color(GameData.team_by_id(GameData.teams(), team_id).get("color", "#888888"))


func _avatar(id: String, size: int, ring_color := Color(0, 0, 0, 0)) -> Control:
	var d := _driver(id)
	var av := DriverPhotos.make_avatar(d, _team_color(String(d.get("team", ""))), size)
	av.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return av


func _card(r: Rect2, fill := Color("#171a21")) -> Panel:
	var c := Panel.new()
	c.position = r.position
	c.size = r.size
	c.clip_contents = true
	var st := UiStyle.g_box(fill, 22, 0, 0)
	st.shadow_color = Color(0, 0, 0, 0.35)
	st.shadow_size = 10
	c.add_theme_stylebox_override("panel", st)
	_body.add_child(c)
	return c


func _chip(text: String, icon_name: String, fill: Color, fg: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(fill, 15, 12, 4))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	if icon_name != "":
		h.add_child(ScreenKit.icon(icon_name, 16, fg))
	h.add_child(UiStyle.g_label(text, 13, fg, "black"))
	p.add_child(h)
	return p


func _row(parent: Control, y: float, w: float, h: float, pos_text: String, id: String, team_id: String, right_text: String, sub := "", arrow := "", arrow_col := UiStyle.G_TEXT_3) -> void:
	var mine := team_id == world.player_team
	var accent := UiStyle.team_accent(GameData.team_by_id(GameData.teams(), team_id))
	var p := Panel.new()
	p.position = Vector2(0, y)
	p.size = Vector2(w, h)
	var st := UiStyle.g_box(Color(accent, 0.22) if mine else Color(1, 1, 1, 0.05), 12, 0, 0)
	if mine:
		st.border_width_left = 4
		st.border_color = accent
	p.add_theme_stylebox_override("panel", st)
	parent.add_child(p)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	hb.position = Vector2(12, 0)
	hb.size = Vector2(w - 24, h)
	p.add_child(hb)
	var pl := UiStyle.g_label(pos_text, 15, UiStyle.G_TEXT_2, "black")
	pl.custom_minimum_size = Vector2(24, 0)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(pl)
	var is_driver := id != team_id
	if is_driver:
		hb.add_child(_avatar(id, int(h) - 10))
	else:
		var em := TeamEmblems.make_rect(team_id, int(h) - 14)
		em.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(em)
	var nm := VBoxContainer.new()
	nm.add_theme_constant_override("separation", -2)
	nm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var label := String(_driver(id).get("name", "")) if is_driver else String(GameData.team_by_id(GameData.teams(), id).get("name", id))
	nm.add_child(UiStyle.g_label(label, 15 if h >= 40 else 14, UiStyle.G_TEXT, "black"))
	if sub != "":
		nm.add_child(UiStyle.g_label(sub, 12, UiStyle.G_TEXT_3, "bold"))
	hb.add_child(nm)
	if arrow != "":
		var al := UiStyle.g_label(arrow, 13, arrow_col, "black")
		al.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(al)
	hb.add_child(UiStyle.hspacer())
	var rl := UiStyle.g_label(right_text, 17 if h >= 40 else 15, UiStyle.G_TEXT, "black")
	rl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(rl)


func _move(before: Dictionary, id: String, now: int) -> Array:
	var b := int(before.get(id, now))
	if b > now:
		return ["▲%d" % (b - now), Color("#7fe0b1")]
	if b < now:
		return ["▼%d" % (now - b), Color("#ff8a80")]
	return ["", UiStyle.G_TEXT_3]


# --- aba RESULTADO -------------------------------------------------------------------------------------

func _result_tab() -> void:
	var h: Dictionary = world.history.back()
	var res: Array = h["results"]
	var gains: Dictionary = h.get("gains", {})
	var pts: Dictionary = h.get("points", {})
	var cir := GameData.circuit(String(h["circuit"]))
	var hero := _card(Rect2(30, 140, 640, 480), Color("#171a21").lerp(_team_color(world.team_of(String(res[0]))) if not res.is_empty() else Color.BLACK, 0.18))
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 8)
	chips.position = Vector2(18, 14)
	if String(h.get("pole", "")) != "":
		var pole_txt := "Pole: %s" % String(_driver(String(h["pole"])).get("name", "")).get_slice(" ", 1)
		if float(h.get("pole_time", 0.0)) > 0.0:
			pole_txt += " " + UiStyle.format_time(float(h["pole_time"])).replace(".", ",")
		chips.add_child(_chip(pole_txt, "trophy", GOLD, UiStyle.G_INK))
	var fl: Dictionary = h.get("fastest", {})
	if not fl.is_empty():
		chips.add_child(_chip("Melhor volta: %s %s" % [String(_driver(String(fl["id"])).get("name", "")).get_slice(" ", 1), UiStyle.format_time(float(fl["time"])).replace(".", ",")], "timer", Color(1, 1, 1, 0.1), UiStyle.G_TEXT))
	hero.add_child(chips)
	var cols := [[0, 230.0, 300.0, GOLD, 92], [1, 50.0, 250.0, Color("#C0C6D0"), 74], [2, 420.0, 220.0, Color("#C98A4B"), 74]]  # vencedor no centro, mais alto
	for c: Array in cols:
		var idx: int = c[0]
		if idx >= res.size():
			continue
		var id := String(res[idx])
		var x: float = c[1]
		var ph: float = c[2]
		var col: Color = c[3]
		var team_id := world.team_of(id)
		var block := Panel.new()
		block.position = Vector2(x, 480 - ph)
		block.size = Vector2(170, ph)
		block.add_theme_stylebox_override("panel", UiStyle.g_box(Color(_team_color(team_id), 0.3).lerp(Color("#232733"), 0.5), 18, 0, 0))
		hero.add_child(block)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 4)
		v.alignment = BoxContainer.ALIGNMENT_BEGIN
		v.position = Vector2(0, 10)
		v.size = Vector2(170, ph - 10)
		block.add_child(v)
		var posl := UiStyle.g_label(str(idx + 1), 30, col, "black")
		posl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(posl)
		var avc := CenterContainer.new()
		avc.add_child(_avatar(id, int(c[4])))
		v.add_child(avc)
		var nm := UiStyle.g_label(String(_driver(id).get("name", "")), 14, UiStyle.G_TEXT, "black")
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(nm)
		var pr := HBoxContainer.new()
		pr.alignment = BoxContainer.ALIGNMENT_CENTER
		pr.add_theme_constant_override("separation", 6)
		pr.add_child(TeamEmblems.make_rect(team_id, 18))
		pr.add_child(UiStyle.g_label("+%d pts" % int(pts.get(id, 0)), 12, UiStyle.G_TEXT_2, "bold"))
		v.add_child(pr)
	# do 4º em diante
	var right := _card(Rect2(690, 140, 560, 480))
	right.add_child(_caption_at("Do 4º ao %dº · posições ganhas na largada" % mini(res.size(), 13), Vector2(16, 12)))
	var y := 40.0
	for i in range(3, mini(res.size(), 13)):
		var id := String(res[i])
		var g := int(gains.get(id, 0))
		var arrow := "▲%d" % g if g > 0 else ("▼%d" % -g if g < 0 else "—")
		_row(right, y, 528, 40, str(i + 1), id, world.team_of(id), "+%d" % int(pts.get(id, 0)), "", arrow, Color("#7fe0b1") if g > 0 else (Color("#ff8a80") if g < 0 else UiStyle.G_TEXT_3))
		right.get_child(right.get_child_count() - 1).position.x = 16
		y += 43.0
	var gp := _chip("%s · fim de semana encerrado" % String(cir.get("grand_prix", "")), "flag", Color(1, 1, 1, 0.08), UiStyle.G_TEXT)
	gp.position = Vector2(W - 30 - 360, 98)
	_body.add_child(gp)


func _caption_at(text: String, pos: Vector2) -> Label:
	var l := UiStyle.g_caption(text)
	l.position = pos
	return l


# --- aba CAMPEONATO -----------------------------------------------------------------------------------------

func _champ_tab() -> void:
	var last: Dictionary = world.history.back() if not world.history.is_empty() else {}
	var bd: Dictionary = last.get("before_drivers", {})
	var bt: Dictionary = last.get("before_teams", {})
	var pts: Dictionary = last.get("points", {})
	var left := _card(Rect2(30, 140, 640, 480))
	left.add_child(_caption_at("Pilotos · após %d GP%s" % [world.round, "" if world.round == 1 else "s"], Vector2(16, 12)))
	var rows := world.driver_standings()
	var y := 38.0
	var shown := 0
	for i in rows.size():
		var id := String(rows[i][0])
		var mine := world.team_of(id) == world.player_team
		if shown >= 7 and not mine:
			continue
		if y > 440.0:
			break
		var mv := _move(bd, id, i + 1)
		var gained := int(pts.get(id, 0))
		_row(left, y, 608, 46, str(i + 1), id, world.team_of(id), "%d" % int(rows[i][1]) + ("  +%d" % gained if gained > 0 else ""), "", String(mv[0]), mv[1])
		left.get_child(left.get_child_count() - 1).position.x = 16
		y += 50.0
		shown += 1
	var right := _card(Rect2(690, 140, 560, 480))
	right.add_child(_caption_at("Construtores", Vector2(16, 12)))
	var trows := world.team_standings()
	y = 38.0
	for i in mini(trows.size(), 11):
		var id := String(trows[i][0])
		var mv := _move(bt, id, i + 1)
		_row(right, y, 528, 36, str(i + 1), id, id, str(int(trows[i][1])), "", String(mv[0]), mv[1])
		right.get_child(right.get_child_count() - 1).position.x = 16
		y += 39.0


# --- aba ESTATÍSTICAS ------------------------------------------------------------------------------------------

func _stats_tab() -> void:
	var defs := [["wins", "Vitórias", "trophy", GOLD], ["poles", "Poles", "flag", Color("#C77DFF")],
		["podiums", "Pódios", "up", Color("#7fe0b1")], ["dnfs", "Abandonos", "lock", Color("#ff8a80")]]
	for i in 4:
		var d: Array = defs[i]
		_stat_block(Rect2(30 + (i % 2) * 630, 140 + (i / 2) * 240, 590, 226), String(d[0]), String(d[1]), String(d[2]), d[3])


func _stat_block(r: Rect2, stat: String, title: String, icon_name: String, col: Color) -> void:
	var c := _card(r)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.position = Vector2(16, 10)
	head.add_child(ScreenKit.icon(icon_name, 20, col))
	head.add_child(UiStyle.g_label(title, 15, UiStyle.G_TEXT, "black"))
	c.add_child(head)
	var rows := world.stat_table(stat, _by_team)
	if rows.is_empty():
		var none := UiStyle.g_label("Ninguém ainda.", 14, UiStyle.G_TEXT_3, "bold")
		none.position = Vector2(16, 50)
		c.add_child(none)
		return
	var mx := float((rows[0] as Array)[1])
	var y := 42.0
	for i in mini(5, rows.size()):
		var id := String(rows[i][0])
		var n := int(rows[i][1])
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		hb.position = Vector2(16, y)
		hb.size = Vector2(r.size.x - 32, 34)
		c.add_child(hb)
		if _by_team:
			var em := TeamEmblems.make_rect(id, 28)
			em.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hb.add_child(em)
		else:
			hb.add_child(_avatar(id, 32))
		var nl := UiStyle.g_label(String(GameData.team_by_id(GameData.teams(), id).get("name", id)) if _by_team else String(_driver(id).get("name", "")), 14, UiStyle.G_TEXT, "black")
		nl.custom_minimum_size = Vector2(170, 0)
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
		cnt.custom_minimum_size = Vector2(28, 0)
		cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cnt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(cnt)
		y += 36.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_continue()
