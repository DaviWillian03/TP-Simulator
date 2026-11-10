extends Control
## Painel do fim de semana — direção Garagem (mockup design/mockups/v4-1-garagem-fim-de-semana.html).
##
## Destaque: a próxima sessão (jogar ou simular; treinos só simulados — v21). Acima, a progressão do evento; abaixo, a
## previsão por dia e o programa do treino (blocos que se acrescentam e tiram); à direita, os
## dois carros com o acerto, o engenheiro de corrida, a chance de bom acerto e o resultado da última sessão.
## Depois de um treino, abre a folha de resultado (acerto antes → depois, nota A–D e melhores voltas).

const SESSION_DESC := {
	"practice": "60 minutos, sempre simulados. Os pilotos seguem o programa; o acerto sai do diretor de engenharia de pista, dos engenheiros de corrida e dos pilotos — e um pouco de sorte.",
	"quali": "Q1, Q2 e Q3 com eliminação. Você escolhe o pneu e o momento de sair para a volta rápida.",
	"sprint_quali": "SQ1, SQ2 e SQ3, mais curtas. Define o grid da sprint.",
	"sprint": "Cerca de 1/3 da distância, sem parada obrigatória. Pontos para os 8 primeiros.",
	"race": "A corrida que vale o fim de semana. Pontos para os 10 primeiros.",
}
const BLOCK_SHORT := {"aero": "Aero", "mech": "Mecânico", "race": "Corrida", "quali": "Volta rápida"}
const GRADE_TEXT := {"A": "Ótimo acerto", "B": "Bom acerto", "C": "Acerto regular", "D": "Acerto ruim"}
const EVENT_ICON := {"ok": "check", "wet": "rain", "spin": "spin", "failure": "wrench"}

var weekend: WeekendSim
var _program_boxes: Dictionary = {}  # id do piloto -> {editor, chips, minutes, add}
var _program_holder: VBoxContainer


func _ready() -> void:
	weekend = Session.weekend
	if weekend == null:
		Session.go_to_title.call_deferred()
		return
	var page := ScreenKit.garage_page(self, weekend.player_team)
	var bd: GarageBackdrop = page["backdrop"]
	bd.floor_ratio = 1.0
	bd.show_lamps = false
	bd.cone_x = -1.0
	bd.glow_center = Vector2(0.3, 0.4)
	bd.glow_radius = Vector2(0.45, 0.5)
	bd.set_glow(UiStyle.team_color(weekend.player_team), 0.22)
	var layer: Control = page["layer"]
	var team := GameData.team_by_id(weekend.teams, weekend.player_team)

	# topo (mockup v26-3): a pista 3D com a bandeira e a previsão · os pneus do fim de semana · as sessões em blocos
	layer.add_child(_hero(Rect2(40, 18, 820, 196), team))
	layer.add_child(_tyre_card(Rect2(876, 18, 364, 196)))
	var tiles := HBoxContainer.new()
	tiles.add_theme_constant_override("separation", 10)
	for i in weekend.sessions.size():
		var id: String = weekend.sessions[i]
		var state := "done" if i < weekend.current else ("now" if i == weekend.current else "next")
		var letter: String = {"quali": "Q", "sprint_quali": "SQ", "sprint": "S", "race": "P" if CategoryRules.is_feeder(weekend.category) else "R"}.get(id, "T%d" % (i + 1))
		tiles.add_child(_session_tile(id, letter, state))
	tiles.position = Vector2(40, 226)
	tiles.size = Vector2(1200, 70)
	layer.add_child(tiles)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", UiStyle.SP_M)
	ScreenKit.scroll_column(left, layer, Vector2(40, 308), Vector2(720, 720 - 308 - 8))
	left.add_child(_final_card() if weekend.is_over() else _next_card())
	if _practice_left():
		_program_holder = VBoxContainer.new()
		_program_holder.add_theme_constant_override("separation", UiStyle.SP_S)
		left.add_child(_program_holder)
		_build_program_editors()

	var cars := VBoxContainer.new()
	cars.add_theme_constant_override("separation", 12)
	ScreenKit.scroll_column(cars, layer, Vector2(1280 - 40 - 456, 308), Vector2(456, 720 - 308 - 8))
	for d: Dictionary in weekend.drivers:
		if d["team"] == weekend.player_team:
			cars.add_child(_car_card(d))
	layer.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(layer, "modulate:a", 1.0, 0.18)
	if weekend.show_practice_report and not weekend.last_practice.is_empty():
		weekend.show_practice_report = false
		_open_practice_report()


# --- topo (v26-3) ------------------------------------------------------------------------

func _hero(r: Rect2, team: Dictionary) -> Control:
	var p := Panel.new()
	p.clip_contents = true
	p.position = r.position
	p.size = r.size
	p.add_theme_stylebox_override("panel", UiStyle.g_box(Color("#171a21"), 22, 0, 0))
	var art := TextureRect.new()
	art.texture = CampaignHub.track_art(String(weekend.circuit.get("id", "")))
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(art)
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(0.03, 0.04, 0.055, 0.35), Color(0.03, 0.04, 0.055, 0.92)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_to = Vector2(0, 1)
	var shade := TextureRect.new()
	shade.texture = gt
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(shade)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	var back := ScreenKit.round_button("back", 48, "Menu")
	back.pressed.connect(Session.go_to_title)
	top.add_child(back)
	top.add_child(TeamEmblems.make_rect(weekend.player_team, 40))
	var cap := UiStyle.g_caption("Fim de semana · %s" % team.get("name", ""), UiStyle.G_TEXT)
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(cap)
	top.position = Vector2(16, 14)
	p.add_child(top)
	var nh := HBoxContainer.new()
	nh.add_theme_constant_override("separation", 14)
	nh.add_child(CampaignHub.flag_rect(String(weekend.circuit.get("country_code", "")), 36))
	var name := CampaignHub.gp_short(String(weekend.circuit["grand_prix"])).to_upper()
	var nl := UiStyle.g_label(name, 46 if name.length() <= 14 else 36, UiStyle.G_TEXT, "black")
	nl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	nl.add_theme_constant_override("shadow_offset_y", 2)
	nh.add_child(nl)
	nh.position = Vector2(22, r.size.y - 74)
	p.add_child(nh)
	var days := HBoxContainer.new()
	days.add_theme_constant_override("separation", 8)
	var today := -1 if weekend.is_over() else weekend.day_of(weekend.session_id())
	for d in 3:
		var pr: float = weekend.forecast[d]
		var box := PanelContainer.new()
		var st := UiStyle.g_box(Color(0.04, 0.05, 0.07, 0.8), 14, 10, 6)
		if d == today:
			st.border_color = UiStyle.RED
			st.set_border_width_all(2)
		box.add_theme_stylebox_override("panel", st)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		var ic := ScreenKit.icon("sun" if pr < 0.2 else ("mixed" if pr < 0.5 else "rain"), 24, Color("#F5C542") if pr < 0.2 else Color("#9fd2ff"))
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(ic)
		var dl := UiStyle.g_label("%s · %d%%" % [String(WeekendSim.DAYS[d]).substr(0, 3).to_lower(), roundi(pr * 100)], 13, UiStyle.G_TEXT, "black")
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(dl)
		box.add_child(v)
		days.add_child(box)
	ScreenKit.place(days, p, Control.PRESET_BOTTOM_RIGHT, Vector2(-18, -16))
	return p


## Pneus do fim de semana do 1º piloto: um círculo por jogo (cheio = novo).
func _tyre_card(r: Rect2) -> Control:
	var p := PanelContainer.new()
	p.position = r.position
	p.size = r.size
	p.add_theme_stylebox_override("panel", UiStyle.g_box(Color("#171a21"), 22, 18, 14))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.add_child(ScreenKit.icon("tyre", 16, UiStyle.G_TEXT_3))
	h.add_child(UiStyle.g_caption("Pneus do fim de semana"))
	v.add_child(h)
	var mine := _my_drivers()
	if weekend.tyre_alloc == null or mine.is_empty():
		return p
	var stock := weekend.tyre_alloc.race_stock(String(mine[0]["id"]))
	var tyres: Dictionary = GameData.tyres()["compounds"]
	for k: String in ["soft", "medium", "hard"]:
		if not tyres.has(k):
			continue
		var n := int(stock[k]["new"])
		var u := int(stock[k]["used"])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var tb := TyreBadge.new()
		tb.custom_minimum_size = Vector2(30, 30)
		tb.set_compound(String(tyres[k]["letter"]), Color(tyres[k]["color"]))
		row.add_child(tb)
		var col := Color(tyres[k]["color"])
		for i in n + u:
			var dot := Panel.new()
			var ds := StyleBoxFlat.new()
			ds.set_corner_radius_all(10)
			ds.bg_color = col if i < n else Color(0, 0, 0, 0)
			ds.border_color = col
			ds.set_border_width_all(2)
			dot.add_theme_stylebox_override("panel", ds)
			dot.custom_minimum_size = Vector2(18, 18)
			dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(dot)
		var fill := Control.new()
		fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(fill)
		row.add_child(UiStyle.g_label(str(n + u), 18, UiStyle.G_TEXT, "black"))
		v.add_child(row)
	return p


## Bloco de sessão: quadrado colorido com a letra, nome e situação (feita ✓ / agora / próxima).
func _session_tile(id: String, letter: String, state: String) -> Control:
	var now := state == "now"
	var col := UiStyle.SECTION["staff"] if id in ["quali", "sprint_quali"] else (UiStyle.RED if id in ["race", "sprint"] else UiStyle.SECTION["drivers"])
	if state == "done":
		col = Color("#8f98a7")
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_LIGHT if now else Color("#171a21"), 18, 10, 8))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var sq := PanelContainer.new()
	sq.custom_minimum_size = Vector2(48, 48)
	sq.add_theme_stylebox_override("panel", UiStyle.g_box(col, 14, 0, 0))
	var l := UiStyle.g_label(letter, 18, Color.WHITE, "black")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sq.add_child(l)
	h.add_child(sq)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -3)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var nm := UiStyle.g_label(weekend.session_short(id).to_upper(), 15, UiStyle.G_INK if now else UiStyle.G_TEXT, "black")
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(nm)
	var sub := "agora" if now else ("feita" if state == "done" else String(WeekendSim.DAYS[weekend.day_of(id)]).to_lower())
	v.add_child(UiStyle.g_label(sub, 12, UiStyle.G_INK_2 if now else UiStyle.G_TEXT_2, "bold"))
	h.add_child(v)
	if state == "done":
		h.add_child(ScreenKit.icon("check", 22, UiStyle.G_UP))
	p.add_child(h)
	return p


# --- próxima sessão ---------------------------------------------------------------------

func _light_card() -> PanelContainer:
	var card := PanelContainer.new()
	var st := UiStyle.g_box(UiStyle.G_LIGHT, 20, 30, 18)
	st.border_width_left = 7
	st.border_color = UiStyle.RED
	card.add_theme_stylebox_override("panel", st)
	return card


func _next_card() -> Control:
	var id := weekend.session_id()
	var card := _light_card()
	card.custom_minimum_size = Vector2(720, 212)
	var row := HBoxContainer.new()
	card.add_child(row)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 4)
	row.add_child(v)
	v.add_child(UiStyle.g_caption("Próxima sessão · agora", UiStyle.G_INK_2))
	v.add_child(UiStyle.g_label(_session_title(id).to_upper(), 44, UiStyle.G_INK, "black"))
	var kind := "practice" if weekend.is_practice(id) else id
	var desc := UiStyle.g_label(_session_desc(kind), UiStyle.FS_BODY, UiStyle.G_INK_2)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(440, 0)
	v.add_child(desc)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", UiStyle.SP_M)
	if weekend.is_practice(id):  # treino é sempre simulado (decisão de 2026-11-08)
		v.add_child(_practice_tiles())
		var run := CutButton.new()
		run.text = "SIMULAR %s" % weekend.session_name(id).to_upper()
		run.custom_minimum_size = Vector2(360, UiStyle.TOUCH_MAIN)
		run.add_theme_font_size_override("font_size", UiStyle.fs(19))
		run.pressed.connect(_on_simulate)
		acts.add_child(run)
	else:
		var play := CutButton.new()
		play.text = "JOGAR"
		play.custom_minimum_size = Vector2(150, UiStyle.TOUCH_MAIN)
		play.add_theme_font_size_override("font_size", UiStyle.fs(19))
		play.pressed.connect(Session.play_session)
		acts.add_child(play)
		var sim := ScreenKit.light_button("SIMULAR")
		sim.pressed.connect(_on_simulate)
		acts.add_child(sim)
	v.add_child(acts)
	var trk := TrackOutline.new()
	trk.line_color = UiStyle.G_INK
	trk.line_width = 6.0
	trk.pad = 8.0
	trk.custom_minimum_size = Vector2(150, 130)
	trk.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	trk.set_circuit(weekend.circuit)
	row.add_child(trk)
	return card


## Treino: diretor de engenharia de pista da equipe e chance de chuva no dia (mockup v21).
## Descrição da sessão (F2/F3: o formato da categoria; mockup v23-4).
func _session_desc(kind: String) -> String:
	if CategoryRules.is_feeder(weekend.category):
		var rev := int(CategoryRules.of(weekend.category)["reverse_top"])
		match kind:
			"practice":
				return "%d minutos, simulados. Depois: classificação de sessão única, sprint com os %d primeiros invertidos e corrida principal." % [weekend.practice_minutes(), rev]
			"quali":
				return "Sessão única de %d minutos: a melhor volta define o grid da principal; a sprint inverte os %d primeiros." % [int(CategoryRules.of(weekend.category)["quali_min"]), rev]
			"sprint":
				return "Sprint sem parada obrigatória, com os %d primeiros da classificação invertidos." % rev
			"race":
				return "Corrida principal: %s." % ("parada obrigatória usando os dois compostos" if bool(CategoryRules.of(weekend.category)["compound_rule"]) else "sem parada obrigatória")
	return SESSION_DESC.get(kind, "")


## F2/F3: regras da categoria no destaque do treino (jogos de pneus, sprint e principal).
func _feeder_tiles() -> Control:
	var r := CategoryRules.of(weekend.category)
	var dry: Dictionary = r["dry"]
	var parts: Array = []
	for k: String in ["hard", "medium", "soft"]:
		if dry.has(k):
			parts.append("%d %s" % [int(dry[k]), String(weekend.tyres.compounds[k]["name"]).to_lower() + ("s" if int(dry[k]) > 1 else "")])
	var total := 0
	for k: String in dry:
		total += int(dry[k])
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	for t: Array in [["%d jogos secos" % total, " + ".join(parts)], ["Sprint", "sem parada · %d primeiros invertidos" % int(r["reverse_top"])],
			["Principal", "parada obrigatória · 2 compostos" if bool(r["compound_rule"]) else "sem parada obrigatória"]]:
		var tile := PanelContainer.new()
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.add_theme_stylebox_override("panel", UiStyle.g_box(Color("#e3e6eb"), 14, 12, 8))
		var tv := VBoxContainer.new()
		tv.add_theme_constant_override("separation", -2)
		tv.add_child(UiStyle.g_label(t[0], UiStyle.FS_BODY, UiStyle.G_INK, "black"))
		var cap := UiStyle.g_label(t[1], UiStyle.FS_CAPTION, UiStyle.G_INK_2, "bold")
		cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tv.add_child(cap)
		tile.add_child(tv)
		h.add_child(tile)
	return h


func _practice_tiles() -> Control:
	if CategoryRules.is_feeder(weekend.category):
		return _feeder_tiles()
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var sk := _skills_of(_my_drivers()[0]["id"]) if not _my_drivers().is_empty() else {}
	var dname := String(sk.get("director_name", ""))
	var p: float = weekend.forecast[weekend.day_of(weekend.session_id())]
	for t: Array in [["shield", str(roundi(float(sk.get("director", 0)))), "Diretor de engenharia de pista" + (" · " + dname if dname != "" else "")],
			["rain", "%d%%" % roundi(p * 100), "chance de chuva · %s" % String(WeekendSim.DAYS[weekend.day_of(weekend.session_id())]).to_lower()]]:
		var tile := PanelContainer.new()
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.add_theme_stylebox_override("panel", UiStyle.g_box(Color("#e3e6eb"), 14, 12, 8))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", UiStyle.SP_S)
		row.add_child(ScreenKit.icon(t[0], 22, UiStyle.G_INK))
		var tv := VBoxContainer.new()
		tv.add_theme_constant_override("separation", -4)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UiStyle.g_label(t[1], 20, UiStyle.G_INK, "black"))
		var cap := UiStyle.g_label(t[2], UiStyle.FS_CAPTION, UiStyle.G_INK_2, "bold")
		cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tv.add_child(cap)
		row.add_child(tv)
		tile.add_child(row)
		h.add_child(tile)
	return h


func _my_drivers() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for d: Dictionary in weekend.drivers:
		if d["team"] == weekend.player_team:
			out.append(d)
	return out


func _skills_of(driver_id: String) -> Dictionary:
	var team := GameData.team_by_id(weekend.teams, weekend.player_team)
	return (team.get("practice_skills", {}) as Dictionary).get(driver_id, {})


func _session_title(id: String) -> String:
	if weekend.is_race(id):
		var laps := maxi(3, roundi(weekend.track.laps * weekend.duration_pct / (RaceSim.SPRINT_DISTANCE if id == "sprint" else 1.0)))
		if CategoryRules.is_feeder(weekend.category):
			laps = int(weekend.race_context()["total_laps"])
		return "%s · %d voltas" % [weekend.session_name(id), laps]
	return weekend.session_name(id)


func _forecast_row() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	for day in 3:
		var p: float = weekend.forecast[day]
		var card := ScreenKit.g_card(UiStyle.G_SURFACE, 16, 16, 12)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", UiStyle.SP_M)
		row.add_child(ScreenKit.icon("sun" if p < 0.2 else ("mixed" if p < 0.5 else "rain"), 30, Color("#dfe3ea")))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", -2)
		v.add_child(UiStyle.g_caption(WeekendSim.DAYS[day]))
		v.add_child(UiStyle.g_label("%d%% chuva" % roundi(p * 100), 21, UiStyle.G_TEXT, "black"))
		row.add_child(v)
		card.add_child(row)
		h.add_child(card)
	return h


func _final_card() -> Control:
	var card := _light_card()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)
	v.add_child(UiStyle.g_caption("Fim de semana encerrado", UiStyle.G_INK_2))
	var winner_id: String = weekend.results["race"][0]
	var win_row := HBoxContainer.new()
	win_row.add_theme_constant_override("separation", UiStyle.SP_M)
	for d: Dictionary in weekend.drivers:
		if d["id"] == winner_id:
			win_row.add_child(DriverPhotos.make_avatar(d, UiStyle.team_color(String(d["team"])), 52))
	win_row.add_child(UiStyle.g_label("VENCEDOR: %s" % _driver_name(winner_id).to_upper(), 34, UiStyle.G_INK, "black"))
	v.add_child(win_row)
	for d: Dictionary in weekend.drivers:
		if d["team"] == weekend.player_team:
			var pos: int = weekend.results["race"].find(d["id"]) + 1
			v.add_child(UiStyle.g_label("%s · %dº na corrida · %d pontos" % [d["name"], pos, weekend.points[d["id"]]], 18, UiStyle.G_INK_2, "bold"))
	var again := CutButton.new()
	again.text = "VOLTAR AO PAINEL" if weekend.world else ("VOLTAR À SEDE" if weekend.campaign else "NOVO GRANDE PRÊMIO")
	again.custom_minimum_size = Vector2(300, UiStyle.TOUCH_MAIN)
	again.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	again.pressed.connect(Session.finish_campaign_weekend if weekend.campaign else Session.open_gp_setup)
	v.add_child(again)
	return card


func _driver_name(id: String) -> String:
	for d: Dictionary in weekend.drivers:
		if d["id"] == id:
			return d["name"]
	return id


# --- programa do treino -----------------------------------------------------------------

func _practice_left() -> bool:
	for i in range(weekend.current, weekend.sessions.size()):
		if weekend.is_practice(weekend.sessions[i]):
			return true
	return false


func _build_program_editors() -> void:
	var mine: Array[Dictionary] = []
	for d: Dictionary in weekend.drivers:
		if d["team"] == weekend.player_team:
			mine.append(d)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UiStyle.SP_M)
	var cap := UiStyle.g_caption("Programa do treino")
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(cap)
	var opts: Array = []
	for d in mine:
		opts.append([d["id"], String(d["name"]).get_slice(" ", String(d["name"]).get_slice_count(" ") - 1)])
	var seg := ScreenKit.segmented(opts, mine[0]["id"], _show_program)
	seg.custom_minimum_size = Vector2(260, 0)
	head.add_child(seg)
	_program_holder.add_child(head)
	for d in mine:
		_program_holder.add_child(_program_editor(d["id"]))
	_show_program(mine[0]["id"])


func _show_program(driver_id: String) -> void:
	for id: String in _program_boxes:
		(_program_boxes[id]["editor"] as Control).visible = id == driver_id


func _program_editor(driver_id: String) -> VBoxContainer:
	var editor := VBoxContainer.new()
	editor.add_theme_constant_override("separation", UiStyle.SP_S)
	# blocos do programa: a faixa desliza para o lado quando há muitos
	var strip := DragScroll.new()
	strip.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	strip.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	strip.custom_minimum_size = Vector2(0, 52)
	editor.add_child(strip)
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 10)
	chips.custom_minimum_size = Vector2(0, 52)
	strip.add_child(chips)
	var add := HBoxContainer.new()
	add.add_theme_constant_override("separation", 10)
	for id: String in ["aero", "mech", "race", "quali"]:
		var b := Button.new()
		b.text = "+ " + BLOCK_SHORT[id]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 48)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for s: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			var st := UiStyle.g_box(UiStyle.G_SURFACE if s in ["hover", "pressed", "hover_pressed"] else Color(0, 0, 0, 0), 14, 8, 0)
			st.border_color = Color(1, 1, 1, 0.08 if s == "disabled" else 0.2)
			st.set_border_width_all(2)
			b.add_theme_stylebox_override(s, st)
		b.add_theme_color_override("font_color", UiStyle.G_TEXT_2)
		b.add_theme_font_size_override("font_size", UiStyle.fs(UiStyle.FS_SMALL + 1))
		b.pressed.connect(_add_block.bind(driver_id, id))
		ScreenKit.press_feedback(b)
		add.add_child(b)
	editor.add_child(add)
	var minutes := UiStyle.g_caption("")
	editor.add_child(minutes)
	_program_boxes[driver_id] = {"editor": editor, "chips": chips, "minutes": minutes, "add": add}
	_refresh_program(driver_id)
	return editor


func _add_block(driver_id: String, block: String) -> void:
	var prog: Array = weekend.program_of(driver_id).duplicate()
	prog.append(block)
	weekend.set_program(driver_id, prog)
	_refresh_program(driver_id)


func _remove_block(driver_id: String, index: int) -> void:
	var prog: Array = weekend.program_of(driver_id).duplicate()
	prog.remove_at(index)
	weekend.set_program(driver_id, prog)
	_refresh_program(driver_id)


func _refresh_program(driver_id: String) -> void:
	var box: Dictionary = _program_boxes[driver_id]
	var chips: HBoxContainer = box["chips"]
	for c in chips.get_children():
		c.queue_free()
	var prog := weekend.program_of(driver_id)
	for i in prog.size():
		var b := Button.new()
		b.text = "%s  %d min" % [PracticeSession.BLOCKS[prog[i]]["name"], int(PracticeSession.BLOCKS[prog[i]]["minutes"])]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 52)
		b.tooltip_text = "Tocar para tirar do programa"
		for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(s, UiStyle.g_box(UiStyle.G_LIGHT if s in ["normal", "hover"] else UiStyle.G_LIGHT_PRESS, 14, 8, 0))
		for k: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(k, UiStyle.G_INK)
		b.add_theme_font_size_override("font_size", UiStyle.fs(UiStyle.FS_SMALL))
		b.pressed.connect(_remove_block.bind(driver_id, i))
		ScreenKit.press_feedback(b)
		chips.add_child(b)
	if prog.is_empty():
		chips.add_child(UiStyle.g_label("Programa vazio: o piloto fica na garagem.", UiStyle.FS_BODY, UiStyle.G_TEXT_3))
	var used := PracticeSession.program_minutes(prog)
	(box["minutes"] as Label).text = "%d / %d min · toque num bloco para tirar" % [used, weekend.practice_minutes()]
	for b: Button in (box["add"] as HBoxContainer).get_children():
		var id: String = ["aero", "mech", "race", "quali"][b.get_index()]
		b.disabled = used + int(PracticeSession.BLOCKS[id]["minutes"]) > weekend.practice_minutes()


# --- seus carros ------------------------------------------------------------------------

func _car_card(d: Dictionary) -> Control:
	var setup: CarSetup = weekend.setups[d["id"]]
	var color := UiStyle.team_color(weekend.player_team)
	var card := ScreenKit.g_card(UiStyle.G_SURFACE, 20, 20, 11)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	card.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", UiStyle.SP_M)
	top.add_child(DriverPhotos.make_avatar(d, color, 44))
	top.add_child(UiStyle.g_label(d["name"], 21, UiStyle.G_TEXT, "black"))
	top.add_child(TeamEmblems.make_rect(d["team"], 24))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	var n := UiStyle.g_label(str(int(d["number"])), 32, Color(0, 0, 0, 0), "black")
	n.add_theme_color_override("font_outline_color", color.lightened(0.25))
	n.add_theme_constant_override("outline_size", 3)
	top.add_child(n)
	v.add_child(top)
	for row: Array in [["Aerodinâmica", setup.aero], ["Mecânico", setup.mech], ["Equilíbrio", setup.balance]]:
		var r := ScreenKit.g_percent_row(v, row[0], color)
		r["bar"].value = row[1]
		r["value"].text = "%d%%" % roundi(row[1] * 100)
	if _practice_left():
		v.add_child(_engineer_row(d))
		v.add_child(_chance_meter(d))
	var q := HBoxContainer.new()
	q.add_theme_constant_override("separation", 10)
	q.add_child(UiStyle.g_label("“", 26, color.lightened(0.25), "black"))
	var quote := UiStyle.g_label(setup.feedback(), 14, Color("#c3c9d3"))
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	q.add_child(quote)
	v.add_child(q)
	var last := _last_result(d["id"])
	if last != "":
		var tag := PanelContainer.new()
		tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		tag.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_SURFACE_HOVER, 12, 10, 4))
		tag.add_child(UiStyle.g_caption(last, UiStyle.G_TEXT_2))
		v.add_child(tag)
	return card


## Engenheiro de corrida do carro (nome + nota).
func _engineer_row(d: Dictionary) -> Control:
	var sk := _skills_of(d["id"])
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiStyle.g_box(Color(0, 0, 0, 0.25), 14, 10, 6))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(ScreenKit.icon("headset", 26, UiStyle.G_ENGINEER))
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", -4)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ename := String(sk.get("engineer_name", ""))
	tv.add_child(UiStyle.g_label(ename if ename != "" else "Vaga aberta", UiStyle.FS_SMALL + 1, UiStyle.G_TEXT, "black"))
	tv.add_child(UiStyle.g_label("engenheiro de corrida", UiStyle.FS_CAPTION, UiStyle.G_TEXT_2, "bold"))
	row.add_child(tv)
	row.add_child(UiStyle.g_label(str(roundi(float(sk.get("engineer", 0)))), 22, UiStyle.G_TEXT, "black"))
	box.add_child(row)
	return box


## Medidor "chance de bom acerto": diretor 35 + engenheiro 30 + piloto 15 + sorte 20 (a sorte entra pela média).
func _chance_meter(d: Dictionary) -> Control:
	var sk := _skills_of(d["id"])
	var ab := PracticeSession.setup_ability(sk, d)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	var top := HBoxContainer.new()
	var cap := UiStyle.g_caption("Chance de bom acerto")
	cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(cap)
	top.add_child(UiStyle.g_label("%d%%" % roundi(PracticeSession.setup_chance(sk, d) * 100), 22, UiStyle.G_TEXT, "black"))
	v.add_child(top)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 0)
	bar.custom_minimum_size = Vector2(0, 10)
	var used := 0.0
	for part: Array in [["director", UiStyle.G_DIRECTOR], ["engineer", UiStyle.G_ENGINEER], ["driver", UiStyle.G_DRIVER], ["luck", UiStyle.G_LUCK]]:
		var seg := ColorRect.new()
		seg.color = part[1]
		seg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		seg.size_flags_stretch_ratio = maxf(float(ab[part[0]]), 0.001)
		used += float(ab[part[0]])
		bar.add_child(seg)
	var rest := ColorRect.new()
	rest.color = Color(1, 1, 1, 0.1)
	rest.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rest.size_flags_stretch_ratio = maxf(1.0 - used, 0.001)
	bar.add_child(rest)
	v.add_child(bar)
	var leg := HBoxContainer.new()
	leg.add_theme_constant_override("separation", 10)
	for part: Array in [["shield", UiStyle.G_DIRECTOR, "Diretor 35"], ["headset", UiStyle.G_ENGINEER, "Engenheiro 30"],
			["person", UiStyle.G_DRIVER, "Piloto 15"], ["dice", UiStyle.G_LUCK, "Sorte 20"]]:
		var it := HBoxContainer.new()
		it.add_theme_constant_override("separation", 3)
		it.add_child(ScreenKit.icon(part[0], 14, part[1]))
		it.add_child(UiStyle.g_label(part[2], UiStyle.FS_CAPTION, Color("#c3c9d3"), "bold"))
		leg.add_child(it)
	v.add_child(leg)
	return v


# --- resultado do treino (mockup v21-2) ----------------------------------------------------

func _open_practice_report() -> void:
	var rep: Dictionary = weekend.last_practice
	var sh := ScreenKit.sheet("Resultado do treino", 1080)
	var body: VBoxContainer = sh["body"]
	body.add_child(UiStyle.g_caption("%s · simulado" % weekend.session_name(String(rep.get("session", "fp1")))))
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", UiStyle.SP_L)
	body.add_child(cols)
	for d: Dictionary in _my_drivers():
		if (rep["drivers"] as Dictionary).has(d["id"]):
			cols.add_child(_report_card(d, rep["drivers"][d["id"]]))
	cols.add_child(_report_times(rep["times"]))
	var next := CutButton.new()
	next.text = "CONTINUAR"
	next.custom_minimum_size = Vector2(300, UiStyle.TOUCH_MAIN)
	next.size_flags_horizontal = Control.SIZE_SHRINK_END
	next.pressed.connect((sh["root"] as Control).queue_free)
	body.add_child(next)
	add_child(sh["root"])
	_report_root = sh["root"]


var _report_root: Control


func _report_card(d: Dictionary, s: Dictionary) -> Control:
	var card := ScreenKit.g_card(UiStyle.G_SURFACE, 18, 14, 12)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(330, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	top.add_child(DriverPhotos.make_avatar(d, UiStyle.team_color(weekend.player_team), 44))
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", -4)
	tv.add_child(UiStyle.g_label(d["name"], 19, UiStyle.G_TEXT, "black"))
	var ename := String((s.get("skills", {}) as Dictionary).get("engineer_name", ""))
	tv.add_child(UiStyle.g_label("com " + ename if ename != "" else "sem engenheiro de corrida", UiStyle.FS_CAPTION, UiStyle.G_TEXT_2, "bold"))
	top.add_child(tv)
	v.add_child(top)
	var gcol: Color = UiStyle.G_GRADE[s["grade"]]
	var gb := PanelContainer.new()
	gb.add_theme_stylebox_override("panel", UiStyle.g_box(Color(gcol, 0.14), 14, 12, 8))
	var gr := HBoxContainer.new()
	gr.add_theme_constant_override("separation", 12)
	gr.add_child(UiStyle.g_label(s["grade"], 30, gcol, "black"))
	var gt := VBoxContainer.new()
	gt.add_theme_constant_override("separation", -4)
	gt.add_child(UiStyle.g_label(GRADE_TEXT[s["grade"]], UiStyle.FS_BODY, UiStyle.G_TEXT, "black"))
	gt.add_child(UiStyle.g_label("sorteio do treino: %d%%" % roundi(float(s["draw"]) * 100), UiStyle.FS_CAPTION, Color("#c3c9d3"), "bold"))
	gr.add_child(gt)
	gb.add_child(gr)
	v.add_child(gb)
	for k: Array in [["aero", "Aerodinâmica"], ["mech", "Mecânico"], ["balance", "Equilíbrio"]]:
		var a := roundi(float(s["before"][k[0]]) * 100)
		var b := roundi(float(s["after"][k[0]]) * 100)
		var r := ScreenKit.g_percent_row(v, k[1], UiStyle.G_ENGINEER)
		r["bar"].value = float(s["after"][k[0]])
		r["value"].text = "%d → %d%%" % [a, b]
		r["value"].add_theme_color_override("font_color", UiStyle.G_UP if b > a else UiStyle.G_TEXT_2)
	var shown := 0
	for e: Dictionary in s["events"]:
		if e["kind"] == "ok" and shown > 0:
			continue
		if shown >= 2:
			break
		var er := HBoxContainer.new()
		er.add_theme_constant_override("separation", 8)
		er.add_child(ScreenKit.icon(EVENT_ICON.get(e["kind"], "check"), 16, UiStyle.G_UP if e["kind"] == "ok" else UiStyle.G_DOWN))
		var el := UiStyle.g_label(e["text"], UiStyle.FS_CAPTION, Color("#c3c9d3"), "bold")
		el.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		el.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		er.add_child(el)
		v.add_child(er)
		shown += 1
	return card


func _report_times(times: Array) -> Control:
	var card := ScreenKit.g_card(UiStyle.G_SURFACE, 18, 14, 12)
	card.custom_minimum_size = Vector2(260, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	card.add_child(v)
	v.add_child(UiStyle.g_caption("Melhores voltas"))
	var best := float(times[0]["best"]) if not times.is_empty() else 0.0
	var rows := 0
	for i in times.size():
		var t: Dictionary = times[i]
		var mine := String(t["team"]) == weekend.player_team
		if i >= 8 and not mine:
			continue
		if rows >= 10:
			break
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 26)
		row.add_theme_constant_override("separation", 8)
		var col := UiStyle.G_TEXT if mine else Color("#c3c9d3")
		row.add_child(UiStyle.g_label("%2d" % (i + 1), UiStyle.FS_SMALL, UiStyle.G_TEXT_3, "black"))
		var code := UiStyle.g_label(String(t["code"]), UiStyle.FS_SMALL, col, "black")
		code.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(code)
		var tm := float(t["best"])
		var txt := "—" if tm == INF else (UiStyle.format_time(tm) if i == 0 else "+%.3f" % (tm - best))
		row.add_child(UiStyle.g_label(txt, UiStyle.FS_SMALL, UiStyle.team_color(weekend.player_team).lightened(0.3) if mine else col, "bold"))
		v.add_child(row)
		rows += 1
	return card


## Resultado do piloto na última sessão concluída ("TL1 · 3º").
func _last_result(driver_id: String) -> String:
	for i in range(weekend.current - 1, -1, -1):
		var id: String = weekend.sessions[i]
		if weekend.results.has(id):
			return "%s · %dº" % [weekend.session_short(id), weekend.results[id].find(driver_id) + 1]
	return ""


func _on_simulate() -> void:
	weekend.show_practice_report = weekend.is_practice(weekend.session_id())
	weekend.simulate_current()
	Session.go_to_weekend()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.go_to_title()
