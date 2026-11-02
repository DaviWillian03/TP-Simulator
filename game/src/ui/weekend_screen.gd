extends Control
## Painel do fim de semana — direção Garagem (mockup design/mockups/v4-1-garagem-fim-de-semana.html).
##
## Destaque: a próxima sessão (jogar ou simular). Acima, a progressão do evento; abaixo, a
## previsão por dia e o programa do treino (blocos que se acrescentam e tiram); à direita, os
## dois carros com o acerto, o comentário do piloto e o resultado da última sessão.

const SESSION_DESC := {
	"practice": "60 minutos. Seus pilotos seguem o programa abaixo; jogue para acompanhar ou simule para ver o resultado.",
	"quali": "Q1, Q2 e Q3 com eliminação. Você escolhe o pneu e o momento de sair para a volta rápida.",
	"sprint_quali": "SQ1, SQ2 e SQ3, mais curtas. Define o grid da sprint.",
	"sprint": "Cerca de 1/3 da distância, sem parada obrigatória. Pontos para os 8 primeiros.",
	"race": "A corrida que vale o fim de semana. Pontos para os 10 primeiros.",
}
const BLOCK_SHORT := {"aero": "Aero", "mech": "Mecânico", "race": "Corrida", "quali": "Volta rápida"}

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

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UiStyle.SP_L)
	var back := ScreenKit.round_button("back", 52, "Menu")
	back.pressed.connect(Session.go_to_title)
	head.add_child(back)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -2)
	titles.add_child(UiStyle.g_caption("Fim de semana · %s" % team.get("name", "")))
	titles.add_child(UiStyle.g_label(String(weekend.circuit["grand_prix"]).to_upper(), 30, UiStyle.G_TEXT, "black"))
	head.add_child(titles)
	ScreenKit.place(head, layer, Control.PRESET_TOP_LEFT, Vector2(44, 24))
	var day: String = "FIM" if weekend.is_over() else WeekendSim.DAYS[weekend.day_of(weekend.session_id())].to_upper()
	ScreenKit.place(UiStyle.g_label(day, 30, UiStyle.RED, "black"), layer, Control.PRESET_TOP_RIGHT, Vector2(-44, 34))

	var steps: Array = []
	for i in weekend.sessions.size():
		var id: String = weekend.sessions[i]
		var state := "done" if i < weekend.current else ("now" if i == weekend.current else "next")
		var letter: String = {"quali": "Q", "sprint_quali": "SQ", "sprint": "S", "race": "R"}.get(id, str(i + 1))
		steps.append([WeekendSim.SESSION_SHORT[id], letter, state])
	var bar := ScreenKit.step_bar(steps)
	layer.add_child(bar)
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 44
	bar.offset_right = -44
	bar.offset_top = 102
	bar.offset_bottom = 140

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", UiStyle.SP_M)
	ScreenKit.place(left, layer, Control.PRESET_TOP_LEFT, Vector2(44, 156), Vector2(700, 0))
	left.add_child(_final_card() if weekend.is_over() else _next_card())
	if not weekend.is_over():
		left.add_child(_forecast_row())
	if _practice_left():
		_program_holder = VBoxContainer.new()
		_program_holder.add_theme_constant_override("separation", UiStyle.SP_S)
		left.add_child(_program_holder)
		_build_program_editors()

	var cars := VBoxContainer.new()
	cars.add_theme_constant_override("separation", 12)
	ScreenKit.place(cars, layer, Control.PRESET_TOP_RIGHT, Vector2(-40, 156), Vector2(450, 0))
	for d: Dictionary in weekend.drivers:
		if d["team"] == weekend.player_team:
			cars.add_child(_car_card(d))
	layer.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(layer, "modulate:a", 1.0, 0.18)


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
	card.custom_minimum_size = Vector2(700, 212)
	var row := HBoxContainer.new()
	card.add_child(row)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 4)
	row.add_child(v)
	v.add_child(UiStyle.g_caption("Próxima sessão · agora", UiStyle.G_INK_2))
	v.add_child(UiStyle.g_label(_session_title(id).to_upper(), 44, UiStyle.G_INK, "black"))
	var kind := "practice" if weekend.is_practice(id) else id
	var desc := UiStyle.g_label(SESSION_DESC.get(kind, ""), UiStyle.FS_BODY, UiStyle.G_INK_2)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(440, 0)
	v.add_child(desc)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", UiStyle.SP_M)
	var play := CutButton.new()
	play.text = "JOGAR"
	play.custom_minimum_size = Vector2(150, UiStyle.TOUCH_MAIN)
	play.add_theme_font_size_override("font_size", 19)
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


func _session_title(id: String) -> String:
	if weekend.is_race(id):
		var laps := maxi(3, roundi(weekend.track.laps * weekend.duration_pct / (RaceSim.SPRINT_DISTANCE if id == "sprint" else 1.0)))
		return "%s · %d voltas" % [WeekendSim.SESSION_NAMES[id], laps]
	return WeekendSim.SESSION_NAMES[id]


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
	v.add_child(UiStyle.g_label("VENCEDOR: %s" % _driver_name(winner_id).to_upper(), 34, UiStyle.G_INK, "black"))
	for d: Dictionary in weekend.drivers:
		if d["team"] == weekend.player_team:
			var pos: int = weekend.results["race"].find(d["id"]) + 1
			v.add_child(UiStyle.g_label("%s · %dº na corrida · %d pontos" % [d["name"], pos, weekend.points[d["id"]]], 18, UiStyle.G_INK_2, "bold"))
	var again := CutButton.new()
	again.text = "NOVO GRANDE PRÊMIO"
	again.custom_minimum_size = Vector2(300, UiStyle.TOUCH_MAIN)
	again.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	again.pressed.connect(Session.open_gp_setup)
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
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 10)
	chips.custom_minimum_size = Vector2(0, 52)
	editor.add_child(chips)
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
		b.add_theme_font_size_override("font_size", UiStyle.FS_SMALL + 1)
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
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.tooltip_text = "Tocar para tirar do programa"
		for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(s, UiStyle.g_box(UiStyle.G_LIGHT if s in ["normal", "hover"] else UiStyle.G_LIGHT_PRESS, 14, 8, 0))
		for k: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(k, UiStyle.G_INK)
		b.add_theme_font_size_override("font_size", UiStyle.FS_SMALL)
		b.pressed.connect(_remove_block.bind(driver_id, i))
		ScreenKit.press_feedback(b)
		chips.add_child(b)
	if prog.is_empty():
		chips.add_child(UiStyle.g_label("Programa vazio: o piloto fica na garagem.", UiStyle.FS_BODY, UiStyle.G_TEXT_3))
	var used := PracticeSession.program_minutes(prog)
	(box["minutes"] as Label).text = "%d / 60 min · toque num bloco para tirar" % used
	for b: Button in (box["add"] as HBoxContainer).get_children():
		var id: String = ["aero", "mech", "race", "quali"][b.get_index()]
		b.disabled = used + int(PracticeSession.BLOCKS[id]["minutes"]) > 60


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
	top.add_child(TeamEmblems.make_rect(d["team"], 28))
	top.add_child(UiStyle.g_label(d["name"], 21, UiStyle.G_TEXT, "black"))
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


## Resultado do piloto na última sessão concluída ("TL1 · 3º").
func _last_result(driver_id: String) -> String:
	for i in range(weekend.current - 1, -1, -1):
		var id: String = weekend.sessions[i]
		if weekend.results.has(id):
			return "%s · %dº" % [WeekendSim.SESSION_SHORT[id], weekend.results[id].find(driver_id) + 1]
	return ""


func _on_simulate() -> void:
	weekend.simulate_current()
	Session.go_to_weekend()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.go_to_title()
