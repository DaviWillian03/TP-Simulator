extends Control
## Histórico da campanha (mockups design/mockups/v24-1..3; decisões de 2026-11-08). Três abas:
## - Lendas: os 15 maiores campeões aposentados (data/legends.json) + quem se aposentou com destaque na campanha.
## - Pilotos atuais: o grid da F1 com os números até o fim de 2025 + o que a campanha somou (em verde).
## - Campeonatos: campeões de pilotos e construtores de cada temporada concluída.

const LEGEND_DIR := "res://local/legends/"  ## fotos pessoais das lendas (fora do git), como as dos pilotos

var campaign: Campaign
var _tab := "legends"
var _body: Control
var _layer: Control


func _ready() -> void:
	campaign = Session.campaign
	if campaign == null:
		Session.open_campaign.call_deferred()
		return
	for a: String in OS.get_cmdline_user_args():  # (capturas) --tab=legends|current|seasons
		if a.begins_with("--tab="):
			_tab = a.trim_prefix("--tab=")
	var page := ScreenKit.garage_page(self, campaign.player_team)
	(page["backdrop"] as GarageBackdrop).set_glow(Color("#2a2f3d"), 0.3)
	_layer = page["layer"]
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UiStyle.SP_L)
	var back := ScreenKit.round_button("back", 52, "Voltar à sede")
	back.pressed.connect(Session.open_campaign_hub)
	head.add_child(back)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -2)
	titles.add_child(UiStyle.g_caption("%s · temporada %d" % [String(campaign.team().get("name", "")), campaign.season]))
	titles.add_child(UiStyle.g_label("HISTÓRICO", 30, UiStyle.G_TEXT, "black"))
	head.add_child(titles)
	ScreenKit.place(head, _layer, Control.PRESET_TOP_LEFT, Vector2(44, 22))
	var seg := ScreenKit.segmented([["legends", "Lendas"], ["current", "Pilotos atuais"], ["seasons", "Campeonatos"]], _tab, func(v: String) -> void:
		_tab = v
		_refresh())
	seg.custom_minimum_size = Vector2(420, 0)
	ScreenKit.place(seg, _layer, Control.PRESET_TOP_RIGHT, Vector2(-44, 26))
	ScreenKit.campaign_nav(_layer, "history")
	_refresh()


func _refresh() -> void:
	if _body != null:
		_body.queue_free()
	var holder := VBoxContainer.new()
	holder.add_theme_constant_override("separation", UiStyle.SP_M)
	_body = ScreenKit.scroll_column(holder, _layer, Vector2(44, 150), Vector2(1280 - 88, 720 - 150 - 16))
	match _tab:
		"current":
			_build_current(holder)
		"seasons":
			_build_seasons(holder)
		_:
			_build_legends(holder)


# --- Lendas --------------------------------------------------------------------------------------

func legends_list() -> Array:
	var list: Array = (GameData.load_json(GameData.DATA_DIR + "legends.json")["legends"] as Array).duplicate(true)
	list.append_array(campaign.legend_adds)
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["titles"]) != int(b["titles"]):
			return int(a["titles"]) > int(b["titles"])
		return int(a["wins"]) > int(b["wins"]))
	return list


func _build_legends(holder: VBoxContainer) -> void:
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 14)
	holder.add_child(grid)
	var list := legends_list()
	for i in list.size():
		grid.add_child(_legend_card(list[i], i + 1))


func _legend_card(l: Dictionary, rank: int) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(286, 170)
	card.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_SURFACE, 20, 14, 12))
	var root := Control.new()
	card.add_child(root)
	var rk := UiStyle.g_label(str(rank), 48, Color(1, 1, 1, 0.08), "black")
	rk.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	rk.offset_left = -70
	rk.offset_top = -12
	rk.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(rk)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	top.add_child(_legend_face(l, 52))
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", -4)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nm := UiStyle.g_label(String(l["name"]), 17, UiStyle.G_TEXT, "black")
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tv.add_child(nm)
	var sub := "%s · %s" % [l.get("nationality", ""), l.get("years", "")]
	if bool(l.get("from_campaign", false)):
		sub += " · campanha"
	tv.add_child(UiStyle.g_label(sub, UiStyle.FS_CAPTION, UiStyle.G_TEXT_2, "bold"))
	top.add_child(tv)
	v.add_child(top)
	var crowns := HBoxContainer.new()
	crowns.add_theme_constant_override("separation", 2)
	for i in int(l["titles"]):
		crowns.add_child(ScreenKit.icon("crown", 16, UiStyle.G_DIRECTOR))
	if int(l["titles"]) == 0:
		crowns.add_child(UiStyle.g_label("sem título", UiStyle.FS_CAPTION, UiStyle.G_TEXT_3, "bold"))
	v.add_child(crowns)
	var nums := HBoxContainer.new()
	nums.add_theme_constant_override("separation", 14)
	for kv: Array in [["wins", "VIT"], ["poles", "POLES"], ["podiums", "PÓD"], ["starts", "GPS"]]:
		var nv := VBoxContainer.new()
		nv.add_theme_constant_override("separation", -4)
		nv.add_child(UiStyle.g_label(str(int(l[kv[0]])), 20, UiStyle.G_TEXT, "black"))
		nv.add_child(UiStyle.g_caption(kv[1]))
		nums.add_child(nv)
	v.add_child(nums)
	return card


func _legend_face(l: Dictionary, size: int) -> Control:
	var id := String(l.get("id", ""))
	if bool(l.get("from_campaign", false)):
		return DriverPhotos.make_avatar({"id": id, "name": l["name"]}, Color("#3a3f4b"), size)
	var tex := DriverPhotos.circle_texture(LEGEND_DIR + id + ".png", Color("#3a3f4b"))
	if tex != null:
		var r := TextureRect.new()
		r.texture = tex
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		r.custom_minimum_size = Vector2(size, size)
		r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return r
	return DriverPhotos.make_avatar({"id": "", "name": l["name"]}, Color("#3a3f4b"), size)


# --- Pilotos atuais ---------------------------------------------------------------------------------

const CUR_COLS := [["starts", "LARGADAS"], ["wins", "VITÓRIAS"], ["podiums", "PÓDIOS"], ["poles", "POLES"], ["titles", "TÍTULOS"]]


func current_rows() -> Array:
	var rows: Array = []
	for d: Dictionary in campaign.drivers():
		rows.append({"d": d, "c": campaign.career_of(d), "add": campaign.career_log.get(d["id"], {})})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["c"]["titles"]) != int(b["c"]["titles"]):
			return int(a["c"]["titles"]) > int(b["c"]["titles"])
		return int(a["c"]["wins"]) > int(b["c"]["wins"]))
	return rows


func _build_current(holder: VBoxContainer) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_SURFACE, 20, 14, 6))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	card.add_child(v)
	var head := HBoxContainer.new()
	head.custom_minimum_size = Vector2(0, 34)
	var hc := UiStyle.g_caption("#")
	hc.custom_minimum_size = Vector2(34, 0)
	head.add_child(hc)
	var hp := UiStyle.g_caption("Piloto")
	hp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hp)
	for col: Array in CUR_COLS:
		var l := UiStyle.g_caption(col[1])
		l.custom_minimum_size = Vector2(110, 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		head.add_child(l)
	v.add_child(head)
	for r: Dictionary in current_rows():
		v.add_child(_current_row(r))
	holder.add_child(card)


func _current_row(r: Dictionary) -> Control:
	var d: Dictionary = r["d"]
	var col := UiStyle.team_color_from(campaign.teams(), String(d["team"]))
	var h := HBoxContainer.new()
	h.custom_minimum_size = Vector2(0, 48)
	h.add_theme_constant_override("separation", 0)
	var n := UiStyle.g_label(str(int(d["number"])), UiStyle.FS_SMALL, UiStyle.G_TEXT_3, "black")
	n.custom_minimum_size = Vector2(34, 0)
	n.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(n)
	var who := HBoxContainer.new()
	who.add_theme_constant_override("separation", 10)
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	who.add_child(DriverPhotos.make_avatar(d, col, 34))
	var nm := UiStyle.g_label(String(d["name"]), UiStyle.FS_BODY, UiStyle.G_TEXT, "black")
	nm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	who.add_child(nm)
	var pill := PanelContainer.new()
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pill.add_theme_stylebox_override("panel", UiStyle.g_box(Color(col, 0.22), 10, 8, 2))
	pill.add_child(UiStyle.g_label(String(GameData.team_by_id(campaign.teams(), String(d["team"])).get("name", "")), UiStyle.FS_CAPTION, UiStyle.G_TEXT, "black"))
	who.add_child(pill)
	h.add_child(who)
	var add: Dictionary = r["add"]
	for c: Array in CUR_COLS:
		var cv := VBoxContainer.new()
		cv.custom_minimum_size = Vector2(110, 0)
		cv.alignment = BoxContainer.ALIGNMENT_CENTER
		cv.add_theme_constant_override("separation", -4)
		var val := UiStyle.g_label(str(int(r["c"][c[0]])), UiStyle.FS_BODY, UiStyle.G_TEXT, "black")
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cv.add_child(val)
		var plus := int(add.get(c[0], 0))
		if plus > 0:
			var p := UiStyle.g_label("+%d campanha" % plus, UiStyle.FS_CAPTION, UiStyle.G_UP, "black")
			p.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			cv.add_child(p)
		h.add_child(cv)
	return h


# --- Campeonatos ------------------------------------------------------------------------------------

func _build_seasons(holder: VBoxContainer) -> void:
	if campaign.champions.is_empty():
		var l := UiStyle.g_label("Nenhuma temporada concluída.", UiStyle.FS_BODY, UiStyle.G_TEXT_2, "bold")
		holder.add_child(l)
		return
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 16)
	holder.add_child(grid)
	var list := campaign.champions.duplicate()
	list.reverse()  # mais recente primeiro
	for ch: Dictionary in list:
		grid.add_child(_season_card(ch))


func _season_card(ch: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(560, 0)
	card.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_SURFACE, 22, 18, 16))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	card.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	top.add_child(UiStyle.g_label(str(int(ch["season"])), 34, UiStyle.G_TEXT, "black"))
	var mine := int(ch.get("my_position", 0))
	var tag := PanelContainer.new()
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_SURFACE_HOVER, 10, 8, 3))
	tag.add_child(UiStyle.g_label("sua equipe: %dº" % mine if mine > 0 else "você estava na %s" % String(ch.get("my_category", "base")), UiStyle.FS_CAPTION, UiStyle.G_TEXT, "black"))
	top.add_child(tag)
	v.add_child(top)
	var d := {}
	for x: Dictionary in campaign.drivers():
		if x["id"] == ch["driver"]:
			d = x
	if d.is_empty():
		d = {"id": ch["driver"], "name": ch["driver_name"]}
	var dcol := UiStyle.team_color_from(campaign.teams(), String(ch.get("driver_team", "")))
	v.add_child(_champ_row(DriverPhotos.make_avatar(d, dcol, 64), "Campeão de pilotos", String(ch["driver_name"]),
		"%d pontos · %s" % [int(ch["driver_points"]), String(GameData.team_by_id(campaign.teams(), String(ch.get("driver_team", ""))).get("name", ""))]))
	var em := TeamEmblems.make_rect(String(ch["team"]), 64)
	v.add_child(_champ_row(em, "Campeã de construtores", String(ch["team_name"]), "%d pontos" % int(ch["team_points"])))
	if String(ch.get("second", "")) != "":
		v.add_child(UiStyle.g_label("Vice: %s · 3º: %s" % [ch["second"], ch.get("third", "")], UiStyle.FS_SMALL, Color("#c3c9d3"), "bold"))
	return card


func _champ_row(pic: Control, cap: String, name: String, sub: String) -> Control:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiStyle.g_box(Color(0, 0, 0, 0.25), 16, 12, 10))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	box.add_child(h)
	h.add_child(pic)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", -2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UiStyle.g_caption(cap))
	tv.add_child(UiStyle.g_label(name, 18, UiStyle.G_TEXT, "black"))
	tv.add_child(UiStyle.g_label(sub, UiStyle.FS_CAPTION, UiStyle.G_TEXT_2, "bold"))
	h.add_child(tv)
	h.add_child(ScreenKit.icon("crown", 30, UiStyle.G_DIRECTOR))
	return box
