class_name DriverSheet
extends Control
## Ficha do piloto (mockup v12): rosto, nota geral, os 6 atributos, nascimento/idade, títulos, contrato e multa.
## Dados que ainda não têm fonte confiável (altura, peso, vitórias, pódios, poles) aparecem como "—".
## "Negociar" fecha a ficha e pede a folha de contrato (sinal `negotiate`).

signal closed
signal negotiate(id: String)


func setup(camp: Campaign, id: String) -> void:
	var pe := camp.personnel
	var p := pe.person(id, camp)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.025, 0.03, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	var st := UiStyle.g_box(Color("#17191e"), 26, 30, 24)
	st.shadow_color = Color(0, 0, 0, 0.55)
	st.shadow_size = 24
	panel.add_theme_stylebox_override("panel", st)
	panel.custom_minimum_size = Vector2(860, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)

	var c := pe.contract_of(id)
	var team_id: String = c.get("team", "")
	var mine := pe.is_mine(camp, id)
	var team_name := "Agente livre"
	if mine:
		team_name = String(camp.team()["name"])
	elif team_id != "":
		team_name = String(GameData.team_by_id(camp.teams(), team_id).get("name", team_id))
	var color := UiStyle.team_color_from(camp.teams(), team_id) if GameData.team_by_id(camp.teams(), team_id).size() > 0 else Color("#6a7487")
	if mine:
		color = UiStyle.team_color(camp.player_team)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 20)
	top.add_child(DriverPhotos.make_avatar(p, color, 84))
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 2)
	var title := HBoxContainer.new()
	title.add_theme_constant_override("separation", 10)
	title.add_child(UiStyle.g_label(String(p["name"]).to_upper(), 34, UiStyle.G_TEXT, "black"))
	if p.has("number"):
		var num := UiStyle.g_label("#%d" % int(p["number"]), 20, UiStyle.G_TEXT_3, "black")
		num.size_flags_vertical = Control.SIZE_SHRINK_END
		title.add_child(num)
	names.add_child(title)
	var salary := float(c.get("salary", 0.0))
	names.add_child(UiStyle.g_label("%s · %s · contrato até %d · US$ %s mi/ano" % [team_name, p["nationality"], int(c.get("until", camp.season)), ("%.1f" % salary).replace(".", ",")], 14, UiStyle.G_TEXT_2, "bold"))
	var tags := HBoxContainer.new()
	tags.add_theme_constant_override("separation", 8)
	tags.add_child(_tag("no grid da F1" if p.get("category", "") == "F1" else "%s" % p.get("category", ""), "ok" if p.get("category", "") == "F1" else ""))
	var fee := pe.buyout_cost(id, camp)
	if fee > 0.0:
		tags.add_child(_tag("multa de rescisão US$ %s mi" % ("%.1f" % fee).replace(".", ","), "warn"))
	elif mine:
		tags.add_child(_tag("da sua equipe", "ok"))
	names.add_child(tags)
	top.add_child(names)
	top.add_child(UiStyle.hspacer())
	var big := VBoxContainer.new()
	big.add_theme_constant_override("separation", -8)
	var bn := UiStyle.g_label(str(int(p["rating"])), 64, UiStyle.G_TEXT, "black")
	bn.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	big.add_child(bn)
	var bc := UiStyle.g_caption("Nota geral")
	bc.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	big.add_child(bc)
	top.add_child(big)
	v.add_child(top)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 26)
	v.add_child(cols)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 0)
	left.add_child(UiStyle.g_caption("Atributos · nota geral = média ponderada"))
	if p.has("attrs"):
		for k: String in DriverStats.KEYS:
			left.add_child(_attr_row(String(DriverStats.NAMES[k]), int(p["attrs"][k])))
	else:
		var note := UiStyle.g_label("Sem atributos individuais: vale a nota geral.", 14, UiStyle.G_TEXT_3)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.custom_minimum_size = Vector2(380, 0)
		left.add_child(note)
	left.add_child(UiStyle.g_caption("Resumo"))
	var bio := UiStyle.g_label(Bio.driver(p, camp.season), 14, UiStyle.G_TEXT_2, "bold")
	bio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bio.custom_minimum_size = Vector2(380, 0)
	left.add_child(bio)
	cols.add_child(left)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 0)
	right.add_child(UiStyle.g_caption("Ficha"))
	var age := DriverStats.age(p, camp.season)
	var birth := String(p.get("birth", ""))
	var birth_txt := "—"
	if birth.length() == 10:
		birth_txt = "%s/%s/%s · %d anos" % [birth.substr(8, 2), birth.substr(5, 2), birth.substr(0, 4), age]
	for kv: Array in [["Nascimento", birth_txt], ["Nacionalidade", String(p["nationality"])],
			["Títulos mundiais", str(int(p["titles"])) if p.has("titles") else "—"], ["Altura · peso", _body(p)], ["Largadas · vitórias", _starts_wins(p)], ["Pódios · poles", _podiums_poles(p)],
			["Potencial", str(int(p["potential"])) if p.has("potential") else "—"]]:
		right.add_child(_kv(kv[0], kv[1]))
	cols.add_child(right)

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 12)
	var close := Button.new()
	close.text = "FECHAR"
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(150, UiStyle.TOUCH_MAIN)
	for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
		close.add_theme_stylebox_override(s, UiStyle.g_box(Color(1, 1, 1, 0.1), 14, 20, 0))
	close.add_theme_font_override("font", UiStyle.G_BLACK)
	close.add_theme_font_size_override("font_size", UiStyle.fs(16))
	close.pressed.connect(func() -> void:
		closed.emit()
		queue_free())
	ScreenKit.press_feedback(close)
	btns.add_child(close)
	btns.add_child(UiStyle.hspacer())
	var go := CutButton.new()
	go.text = "RENOVAR" if mine else "NEGOCIAR"
	go.custom_minimum_size = Vector2(220, UiStyle.TOUCH_MAIN)
	go.add_theme_font_size_override("font_size", UiStyle.fs(18))
	go.pressed.connect(func() -> void:
		negotiate.emit(id)
		queue_free())
	btns.add_child(go)
	v.add_child(btns)


func _body(p: Dictionary) -> String:
	if p.get("height_cm", null) == null or p.get("weight_kg", null) == null:
		return "—" if p.get("height_cm", null) == null and p.get("weight_kg", null) == null else (("%.2f m" % (float(p["height_cm"]) / 100.0)).replace(".", ",") if p.get("height_cm", null) != null else "%d kg" % int(p["weight_kg"]))
	return "%s m · %d kg" % [("%.2f" % (float(p["height_cm"]) / 100.0)).replace(".", ","), int(p["weight_kg"])]


func _starts_wins(p: Dictionary) -> String:
	var c: Dictionary = p.get("career", {})
	return "%d · %d" % [int(c["starts"]), int(c["wins"])] if not c.is_empty() else "—"


func _podiums_poles(p: Dictionary) -> String:
	var c: Dictionary = p.get("career", {})
	return "%d · %d" % [int(c["podiums"]), int(c["poles"])] if not c.is_empty() else "—"


func _tag(text: String, kind: String) -> PanelContainer:
	var fill: Color = {"ok": Color(0.235, 0.616, 0.365, 0.25), "warn": Color(1, 0.82, 0.29, 0.22)}.get(kind, Color(1, 1, 1, 0.1))
	var fg: Color = {"ok": Color("#7fe0b1"), "warn": Color("#ffd24a")}.get(kind, Color("#c3c9d3"))
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(fill, 10, 10, 3))
	p.add_child(UiStyle.g_label(text, 12, fg, "bold"))
	return p


func _attr_row(name: String, value: int) -> Control:
	var h := HBoxContainer.new()
	h.custom_minimum_size = Vector2(0, 40)
	h.add_theme_constant_override("separation", 12)
	var n := UiStyle.g_label(name, 15, Color("#e3e6eb"), "bold")
	n.custom_minimum_size = Vector2(178, 0)
	n.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(n)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.value = value
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.custom_minimum_size = Vector2(0, 12)
	bar.add_theme_stylebox_override("background", UiStyle.g_box(Color(1, 1, 1, 0.1), 6, 0, 0))
	bar.add_theme_stylebox_override("fill", UiStyle.g_box(Color("#5c93ea"), 6, 0, 0))
	h.add_child(bar)
	var v := UiStyle.g_label(str(value), 18, UiStyle.G_TEXT, "black")
	v.custom_minimum_size = Vector2(34, 0)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(v)
	return h


func _kv(key: String, value: String) -> Control:
	var h := HBoxContainer.new()
	h.custom_minimum_size = Vector2(0, 36)
	var k := UiStyle.g_label(key, 15, UiStyle.G_TEXT_2, "bold")
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	k.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(k)
	var v := UiStyle.g_label(value, 15, UiStyle.G_TEXT_OFF if value == "—" else UiStyle.G_TEXT, "black")
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(v)
	return h
