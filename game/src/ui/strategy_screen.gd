extends Control
## Estratégia antes da largada (mockup design/mockups/v22-2-estrategia.html; decisões de 2026-11-08).
##
## Os engenheiros montam até 3 planos para cada piloto; o jogador escolhe um e pode mudar as voltas (− / +) e o pneu de
## cada stint (toque no pneu). O estoque de jogos vem do fim de semana. Na corrida o plano só avisa: a parada acontece
## quando o jogador confirma no box. Vale para Grande Prêmio, campanha e corrida rápida.

var weekend: WeekendSim
var ctx: Dictionary
var stocks: Dictionary
var options: Dictionary = {}  ## id do piloto -> planos dos engenheiros
var chosen: Dictionary = {}  ## id do piloto -> plano atual (cópia editável)
var picked: Dictionary = {}  ## id do piloto -> índice do plano dos engenheiros escolhido
var edited: Dictionary = {}  ## id do piloto -> true se o jogador mexeu
var _cols: Dictionary = {}  ## id do piloto -> VBoxContainer da coluna (refeita a cada mudança)


func _ready() -> void:
	weekend = Session.weekend
	if weekend == null:
		Session.go_to_title.call_deferred()
		return
	ctx = weekend.race_context()
	stocks = weekend.race_tyre_stock(weekend.session_id() != "sprint")
	options = weekend.engineer_strategy()
	for did: String in options:
		picked[did] = 0
		chosen[did] = (options[did][0] as Dictionary).duplicate(true)
	var page := ScreenKit.garage_page(self, weekend.player_team)
	var bd: GarageBackdrop = page["backdrop"]
	bd.floor_ratio = 1.0
	bd.show_lamps = false
	bd.cone_x = -1.0
	bd.set_glow(UiStyle.team_color(weekend.player_team), 0.2)
	var layer: Control = page["layer"]

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UiStyle.SP_L)
	var back := ScreenKit.round_button("back", 52, "Voltar")
	back.pressed.connect(_on_back)
	head.add_child(back)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -2)
	var rain := int(roundf(weekend.forecast[2] * 100)) if weekend.forecast.size() > 2 else 0
	titles.add_child(UiStyle.g_caption("Antes da largada · %d voltas · %d%% chuva" % [int(ctx["total_laps"]), rain]))
	titles.add_child(UiStyle.g_label("ESTRATÉGIA DA %s" % ("SPRINT" if bool(ctx["sprint"]) else "CORRIDA"), 30, UiStyle.G_TEXT, "black"))
	head.add_child(titles)
	ScreenKit.place(head, layer, Control.PRESET_TOP_LEFT, Vector2(44, 22))
	var hint := HBoxContainer.new()
	hint.add_theme_constant_override("separation", 6)
	hint.add_child(ScreenKit.icon("headset", 18, UiStyle.G_ENGINEER))
	hint.add_child(UiStyle.g_label("Os engenheiros montaram os planos; toque para mudar", UiStyle.FS_SMALL, UiStyle.G_TEXT, "bold"))
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_SURFACE_HOVER, 16, 12, 6))
	chip.add_child(hint)
	ScreenKit.place(chip, layer, Control.PRESET_TOP_RIGHT, Vector2(-44, 34))

	var x := 44.0
	for d: Dictionary in _my_drivers():
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", UiStyle.SP_S)
		var card := ScreenKit.g_card(UiStyle.G_SURFACE, 22, 16, 14)
		card.add_child(col)
		var holder := VBoxContainer.new()
		holder.add_child(card)
		ScreenKit.scroll_column(holder, layer, Vector2(x, 100), Vector2(586, 720 - 100 - 100))
		_cols[d["id"]] = col
		_build_col(d)
		x += 606.0

	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", UiStyle.SP_M)
	var reset := ScreenKit.light_button("VOLTAR AO PLANO DOS ENGENHEIROS")
	reset.pressed.connect(_reset)
	foot.add_child(reset)
	var note := UiStyle.g_label("Na corrida o plano só avisa: a parada acontece quando você confirma no box.", UiStyle.FS_SMALL, UiStyle.G_TEXT_2, "bold")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	foot.add_child(note)
	var go := CutButton.new()
	go.text = "IR PARA O GRID"
	go.custom_minimum_size = Vector2(240, UiStyle.TOUCH_MAIN)
	go.add_theme_font_size_override("font_size", UiStyle.fs(19))
	go.pressed.connect(_confirm)
	foot.add_child(go)
	layer.add_child(foot)
	foot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	foot.offset_left = 44
	foot.offset_right = -44
	foot.offset_top = -84
	foot.offset_bottom = -24


func _my_drivers() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for d: Dictionary in weekend.drivers:
		if d["team"] == weekend.player_team and options.has(d["id"]):
			out.append(d)
	return out


func _build_col(d: Dictionary) -> void:
	var did: String = d["id"]
	var col: VBoxContainer = _cols[did]
	for c in col.get_children():
		c.queue_free()
	var plan: Dictionary = chosen[did]
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	top.add_child(DriverPhotos.make_avatar(d, UiStyle.team_color(weekend.player_team), 46))
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", -4)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UiStyle.g_label(d["name"], 19, UiStyle.G_TEXT, "black"))
	tv.add_child(UiStyle.g_label(_sub_line(d), UiStyle.FS_CAPTION, UiStyle.G_TEXT_2, "bold"))
	top.add_child(tv)
	if edited.get(did, false):
		var chip := PanelContainer.new()
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		chip.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_SURFACE_HOVER, 14, 10, 4))
		chip.add_child(UiStyle.g_label("alterado por você", UiStyle.FS_CAPTION, UiStyle.G_TEXT, "bold"))
		top.add_child(chip)
	col.add_child(top)
	col.add_child(UiStyle.g_caption("Planos dos engenheiros"))
	var plans := HBoxContainer.new()
	plans.add_theme_constant_override("separation", 8)
	var list: Array = options[did]
	for i in list.size():
		plans.add_child(_plan_button(did, i, list[i]))
	col.add_child(plans)
	col.add_child(_timeline(plan))
	var stints: Array = plan["stints"]
	var lap := 1
	for i in stints.size():
		col.add_child(_stint_row(did, i, stints[i], lap))
		lap += int(stints[i]["laps"])
	col.add_child(UiStyle.g_caption("Estoque para a %s" % ("sprint" if bool(ctx["sprint"]) else "corrida")))
	col.add_child(_stock_row(did))
	var warn := RaceStrategy.warning(plan, weekend.tyres, ctx, stocks[did])
	var w := HBoxContainer.new()
	w.add_theme_constant_override("separation", 6)
	w.add_child(ScreenKit.icon("check" if warn == "" else "lock", 16, UiStyle.G_UP if warn == "" else UiStyle.G_DIRECTOR))
	var wl := UiStyle.g_label(warn if warn != "" else "Plano dentro da regra e do estoque", UiStyle.FS_SMALL, UiStyle.G_UP if warn == "" else UiStyle.G_DIRECTOR, "bold")
	wl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	w.add_child(wl)
	col.add_child(w)


func _sub_line(d: Dictionary) -> String:
	var parts: Array = []
	var grid: Array = weekend.grids.get(weekend.session_id(), [])
	if grid.has(d["id"]):
		parts.append("larga em P%d" % (grid.find(d["id"]) + 1))
	var team := GameData.team_by_id(weekend.teams, weekend.player_team)
	var eng := String((team.get("practice_skills", {}) as Dictionary).get(d["id"], {}).get("engineer_name", ""))
	if eng != "":
		parts.append(eng)
	return " · ".join(parts)


func _plan_button(did: String, i: int, p: Dictionary) -> Button:
	var on: bool = int(picked.get(did, -1)) == i and not edited.get(did, false)
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 54)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fill := UiStyle.G_LIGHT if on else UiStyle.G_SURFACE_HOVER
	for st: String in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, UiStyle.g_box(fill, 14, 0, 0))
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", -2)
	b.add_child(v)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 10
	v.add_child(UiStyle.g_label(p["name"], UiStyle.FS_SMALL, UiStyle.G_INK if on else UiStyle.G_TEXT, "black"))
	v.add_child(UiStyle.g_label(p["desc"], UiStyle.FS_CAPTION, UiStyle.G_INK_2 if on else UiStyle.G_TEXT_2, "bold"))
	b.pressed.connect(func() -> void:
		picked[did] = i
		edited[did] = false
		chosen[did] = (options[did][i] as Dictionary).duplicate(true)
		_build_col(_driver(did)))
	ScreenKit.press_feedback(b)
	return b


## Linha do tempo da corrida: um trecho por stint, na cor do pneu.
func _timeline(plan: Dictionary) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 2)
	bar.custom_minimum_size = Vector2(0, 30)
	for st: Dictionary in plan["stints"]:
		var c: Dictionary = weekend.tyres.compounds[st["compound"]]
		var seg := PanelContainer.new()
		seg.add_theme_stylebox_override("panel", UiStyle.g_box(Color(c["color"]), 8, 0, 0))
		seg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		seg.size_flags_stretch_ratio = maxf(float(st["laps"]), 1.0)
		var l := UiStyle.g_label("%s · %d" % [c["letter"], int(st["laps"])], UiStyle.FS_CAPTION, UiStyle.G_INK, "black")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		seg.add_child(l)
		bar.add_child(seg)
	v.add_child(bar)
	var ticks := HBoxContainer.new()
	var total := int(ctx["total_laps"])
	for t: int in [1, roundi(total * 0.25), roundi(total * 0.5), roundi(total * 0.75), total]:
		var l := UiStyle.g_label(str(t), UiStyle.FS_CAPTION, UiStyle.G_TEXT_3, "bold")
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ticks.add_child(l)
	v.add_child(ticks)
	return v


func _stint_row(did: String, i: int, st: Dictionary, first_lap: int) -> Control:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiStyle.g_box(Color(0, 0, 0, 0.25), 14, 10, 6))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	box.add_child(h)
	var c: Dictionary = weekend.tyres.compounds[st["compound"]]
	var tyre_btn := Button.new()  # toque no pneu: troca o composto do stint
	tyre_btn.focus_mode = Control.FOCUS_NONE
	tyre_btn.custom_minimum_size = Vector2(UiStyle.TOUCH_MIN, UiStyle.TOUCH_MIN)
	tyre_btn.tooltip_text = "Trocar o pneu"
	for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
		tyre_btn.add_theme_stylebox_override(s, StyleBoxEmpty.new())
	var badge := TyreBadge.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.set_compound(c["letter"], Color(c["color"]))
	tyre_btn.add_child(badge)
	badge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tyre_btn.pressed.connect(func() -> void:
		RaceStrategy.cycle_compound(chosen[did], i, weekend.tyres, stocks[did])
		edited[did] = true
		_build_col(_driver(did)))
	ScreenKit.press_feedback(tyre_btn)
	h.add_child(tyre_btn)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", -4)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var last := first_lap + int(st["laps"]) - 1
	tv.add_child(UiStyle.g_label("Largada" if i == 0 else "Parada %d · volta %d" % [i, first_lap - 1], UiStyle.FS_BODY, UiStyle.G_TEXT, "black"))
	tv.add_child(UiStyle.g_label("%s %s · voltas %d–%d" % [c["name"], "novo" if bool(st.get("new", true)) else "usado", first_lap, last], UiStyle.FS_CAPTION, UiStyle.G_TEXT_2, "bold"))
	h.add_child(tv)
	var single := (chosen[did]["stints"] as Array).size() < 2
	for delta: int in [-1, 1]:
		var b := Button.new()
		b.text = "−" if delta < 0 else "+"
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(UiStyle.TOUCH_MIN, UiStyle.TOUCH_MIN)
		b.disabled = single
		b.add_theme_font_size_override("font_size", UiStyle.fs(20))
		b.pressed.connect(func() -> void:
			if RaceStrategy.adjust_laps(chosen[did], i, delta):
				edited[did] = true
				_build_col(_driver(did)))
		ScreenKit.press_feedback(b)
		if delta > 0:
			var lv := VBoxContainer.new()
			lv.add_theme_constant_override("separation", -6)
			lv.custom_minimum_size = Vector2(56, 0)
			var n := UiStyle.g_label(str(int(st["laps"])), 20, UiStyle.G_TEXT, "black")
			n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lv.add_child(n)
			var cap := UiStyle.g_caption("voltas")
			cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lv.add_child(cap)
			h.add_child(lv)
		h.add_child(b)
	return box


func _stock_row(did: String) -> Control:
	var h := HFlowContainer.new()
	h.add_theme_constant_override("h_separation", 6)
	h.add_theme_constant_override("v_separation", 6)
	var st: Dictionary = stocks[did]
	for k: String in weekend.tyres.dry_compounds():
		for kind: String in ["new", "used"]:
			var n := int(st.get(k, {}).get(kind, 0))
			if n <= 0:
				continue
			var c: Dictionary = weekend.tyres.compounds[k]
			var chip := PanelContainer.new()
			chip.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_SURFACE_HOVER, 14, 8, 3))
			var r := HBoxContainer.new()
			r.add_theme_constant_override("separation", 6)
			var bd := TyreBadge.new()
			bd.custom_minimum_size = Vector2(20, 20)
			bd.set_compound(c["letter"], Color(c["color"]))
			r.add_child(bd)
			r.add_child(UiStyle.g_label("%s %s ×%d" % [c["name"], "novo" if kind == "new" else "usado", n], UiStyle.FS_CAPTION, UiStyle.G_TEXT, "black"))
			chip.add_child(r)
			h.add_child(chip)
	return h


func _driver(did: String) -> Dictionary:
	for d: Dictionary in weekend.drivers:
		if d["id"] == did:
			return d
	return {}


func _reset() -> void:
	for did: String in options:
		picked[did] = 0
		edited[did] = false
		chosen[did] = (options[did][0] as Dictionary).duplicate(true)
		_build_col(_driver(did))


func _confirm() -> void:
	weekend.strategy = chosen.duplicate(true)
	Session.start_race_after_strategy()


func _on_back() -> void:
	if weekend.race_only:
		Session.go_to_title()
	else:
		get_tree().change_scene_to_file(Session.WEEKEND_SCENE)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back()
