extends Control
## Painel do fim de semana (mockup m3-b): programação das sessões (jogar ou simular),
## previsão do tempo por dia e, para cada carro do jogador, o acerto atual, o comentário do
## piloto e o programa montado para o próximo treino.

const TIMES := {
	"normal": {"fp1": "Sexta 12:30", "fp2": "Sexta 16:00", "fp3": "Sábado 11:30", "quali": "Sábado 15:00", "race": "Domingo 14:00"},
	"sprint": {"fp1": "Sexta 12:30", "sprint_quali": "Sexta 16:30", "sprint": "Sábado 11:00", "quali": "Sábado 15:00", "race": "Domingo 14:00"},
}

var weekend: WeekendSim
var _program_boxes: Dictionary = {}  # id do piloto -> {chips: HBox, minutes: Label}


func _ready() -> void:
	weekend = Session.weekend
	if weekend == null:
		Session.go_to_title.call_deferred()
		return
	var root := ScreenKit.page(self)
	var team := GameData.team_by_id(weekend.teams, weekend.player_team)
	var day: String = "Fim" if weekend.is_over() else WeekendSim.DAYS[weekend.day_of(weekend.session_id())]
	var head := ScreenKit.masthead(root, weekend.circuit["grand_prix"],
		"%s · fim de semana · %s" % [weekend.circuit["short_name"], team.get("name", "")], day)
	var menu := UiStyle.compact(UiStyle.button("Menu"), 13)
	menu.custom_minimum_size = Vector2(70, 34)
	menu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	menu.pressed.connect(Session.go_to_title)
	head["bar"].add_child(menu)
	head["bar"].move_child(menu, 3)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.6
	left.add_theme_constant_override("separation", 8)
	body.add_child(left)
	left.add_child(ScreenKit.section("Programação"))
	for id: String in weekend.sessions:
		left.add_child(_session_card(id))
	if weekend.is_over():
		left.add_child(_final_card())
	else:
		left.add_child(ScreenKit.section("Previsão do tempo"))
		left.add_child(_forecast_row())

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	body.add_child(right)
	right.add_child(ScreenKit.section("Seus carros"))
	for d: Dictionary in weekend.drivers:
		if d["team"] == weekend.player_team:
			right.add_child(_car_card(d))


# --- programação ------------------------------------------------------------------------

func _session_card(id: String) -> Control:
	var index := weekend.sessions.find(id)
	var done := index < weekend.current
	var now := index == weekend.current
	var fill := UiStyle.PAPER_2 if done else (UiStyle.INK if now else UiStyle.PAPER)
	var text_color := UiStyle.PAPER if now else UiStyle.INK
	var card := ScreenKit.card(fill)
	card.custom_minimum_size = Vector2(0, 58)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	card.add_child(h)
	var code := UiStyle.label(WeekendSim.SESSION_SHORT[id], 18, text_color, true)
	code.custom_minimum_size = Vector2(112, 0)
	code.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(code)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 2)
	v.add_child(UiStyle.label(_session_title(id), 16, text_color, true))
	var sub: String
	if done:
		sub = "Concluído · " + weekend.summaries.get(id, "")
	elif now:
		sub = "Agora"
	else:
		sub = TIMES["sprint" if weekend.sprint_weekend else "normal"].get(id, "")
	v.add_child(UiStyle.label(sub, 12, text_color))
	h.add_child(v)
	if done:
		var ok := UiStyle.caption("✓ Concluído")
		ok.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(ok)
	elif now:
		var play := UiStyle.accent(UiStyle.button("Jogar"))
		play.custom_minimum_size = Vector2(84, 34)
		play.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		play.pressed.connect(Session.play_session)
		h.add_child(play)
		var sim := UiStyle.button("Simular")
		sim.custom_minimum_size = Vector2(84, 34)
		sim.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		for state: String in ["normal", "hover"]:
			sim.add_theme_stylebox_override(state, UiStyle.outline_box(UiStyle.INK, UiStyle.PAPER))
		sim.add_theme_color_override("font_color", UiStyle.PAPER)
		sim.add_theme_color_override("font_hover_color", UiStyle.PAPER)
		sim.add_theme_font_size_override("font_size", 13)
		sim.pressed.connect(_on_simulate)
		h.add_child(sim)
	return card


func _session_title(id: String) -> String:
	match id:
		"quali":
			return "Classificação Q1 · Q2 · Q3"
		"sprint_quali":
			return "Classificação sprint SQ1 · SQ2 · SQ3"
		"race", "sprint":
			var laps := maxi(3, roundi(weekend.track.laps * weekend.duration_pct / (RaceSim.SPRINT_DISTANCE if id == "sprint" else 1.0)))
			return "%s · %d voltas" % [WeekendSim.SESSION_NAMES[id], laps]
	return WeekendSim.SESSION_NAMES[id]


func _forecast_row() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	for day in 3:
		var card := ScreenKit.card()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		var cap := UiStyle.caption(WeekendSim.DAYS[day])
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(cap)
		var pct := UiStyle.label("%d%%" % roundi(weekend.forecast[day] * 100), 22, UiStyle.INK, true)
		pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(pct)
		var sub := UiStyle.label("chance de chuva", 11)
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(sub)
		card.add_child(v)
		h.add_child(card)
	return h


## Fim do fim de semana: pontos dos pilotos do jogador e o vencedor.
func _final_card() -> Control:
	var card := ScreenKit.card()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	card.add_child(v)
	v.add_child(UiStyle.label("FIM DE SEMANA ENCERRADO", 18, UiStyle.RED, true))
	var winner_id: String = weekend.results["race"][0]
	var lines: Array[String] = ["Vencedor: %s" % _driver_name(winner_id)]
	for d: Dictionary in weekend.drivers:
		if d["team"] == weekend.player_team:
			var pos: int = weekend.results["race"].find(d["id"]) + 1
			lines.append("%s: %dº na corrida · %d pontos" % [d["name"], pos, weekend.points[d["id"]]])
	v.add_child(UiStyle.label("\n".join(lines), 14))
	var again := UiStyle.accent(UiStyle.button("Novo Grande Prêmio"))
	again.custom_minimum_size = Vector2(220, 40)
	again.size_flags_horizontal = Control.SIZE_SHRINK_END
	again.pressed.connect(Session.open_gp_setup)
	v.add_child(again)
	return card


func _driver_name(id: String) -> String:
	for d: Dictionary in weekend.drivers:
		if d["id"] == id:
			return d["name"]
	return id


# --- seus carros ------------------------------------------------------------------------

func _car_card(d: Dictionary) -> Control:
	var setup: CarSetup = weekend.setups[d["id"]]
	var card := ScreenKit.card()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	card.add_child(v)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	name_row.add_child(TeamEmblems.make_rect(d["team"], 20))
	name_row.add_child(UiStyle.label(d["name"], 17, UiStyle.INK, true))
	v.add_child(name_row)
	v.add_child(UiStyle.caption("Acerto do carro", UiStyle.MUTED))
	for row: Array in [["Aerodinâmica", setup.aero], ["Mecânico", setup.mech], ["Equilíbrio", setup.balance]]:
		var r := ScreenKit.percent_row(v, row[0])
		r["bar"].value = row[1]
		r["value"].text = "%d%%" % roundi(row[1] * 100)
	var prep := UiStyle.label("Ritmo de corrida %d%% · Volta rápida %d%%" % [roundi(setup.race_prep * 100), roundi(setup.quali_prep * 100)], 12, UiStyle.MUTED)
	v.add_child(prep)
	var quote := UiStyle.label("“%s”" % setup.feedback(), 13)
	quote.add_theme_font_override("font", _italic())
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(quote)
	if _practice_left():
		_program_editor(v, d["id"])
	return card


func _practice_left() -> bool:
	for i in range(weekend.current, weekend.sessions.size()):
		if weekend.is_practice(weekend.sessions[i]):
			return true
	return false


func _program_editor(parent: VBoxContainer, driver_id: String) -> void:
	var head := HBoxContainer.new()
	head.add_child(UiStyle.caption("Programa no próximo treino", UiStyle.MUTED))
	head.add_child(UiStyle.hspacer())
	var minutes := UiStyle.caption("")
	head.add_child(minutes)
	parent.add_child(head)
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 4)
	chips.add_theme_constant_override("v_separation", 4)
	parent.add_child(chips)
	var add := HBoxContainer.new()
	add.add_theme_constant_override("separation", 4)
	for id: String in ["aero", "mech", "race", "quali"]:
		var b := UiStyle.compact(UiStyle.button("+ " + PracticeSession.BLOCKS[id]["name"]), 11)
		b.custom_minimum_size = Vector2(0, 30)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_add_block.bind(driver_id, id))
		add.add_child(b)
	parent.add_child(add)
	_program_boxes[driver_id] = {"chips": chips, "minutes": minutes, "add": add}
	_refresh_program(driver_id)


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
	var chips: HFlowContainer = box["chips"]
	for c in chips.get_children():
		c.queue_free()
	var prog := weekend.program_of(driver_id)
	for i in prog.size():
		var b := UiStyle.compact(UiStyle.button("%d · %s ✕" % [i + 1, PracticeSession.BLOCKS[prog[i]]["name"]]), 11)
		b.custom_minimum_size = Vector2(0, 28)
		for state: String in ["normal", "hover"]:
			b.add_theme_stylebox_override(state, UiStyle.outline_box(UiStyle.INK, UiStyle.INK))
		b.add_theme_color_override("font_color", UiStyle.PAPER)
		b.add_theme_color_override("font_hover_color", UiStyle.PAPER)
		b.tooltip_text = "Tocar para tirar do programa"
		b.pressed.connect(_remove_block.bind(driver_id, i))
		chips.add_child(b)
	var used := PracticeSession.program_minutes(prog)
	(box["minutes"] as Label).text = "%d / 60 min" % used
	# só deixa acrescentar o que ainda cabe no treino
	for b: Button in (box["add"] as HBoxContainer).get_children():
		var id: String = ["aero", "mech", "race", "quali"][b.get_index()]
		b.disabled = used + int(PracticeSession.BLOCKS[id]["minutes"]) > 60


func _italic() -> FontVariation:
	var f := FontVariation.new()
	f.base_font = UiStyle.body_font()
	f.variation_transform = Transform2D(Vector2(1, 0), Vector2(0.2, 1), Vector2.ZERO)
	return f


func _on_simulate() -> void:
	weekend.simulate_current()
	Session.go_to_weekend()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.go_to_title()
