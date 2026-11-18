extends Control
## Estratégia antes da largada — "Estratégias possíveis" (mockup design/mockups/v41-estrategias.html, aprovado em
## 2026-11-18), no estilo dos gráficos de estratégia da transmissão, em português e sem logos oficiais.
##
## Sempre três linhas por piloto: 1, 2 e 3 paradas (na sprint 0, 1 e 2), em qualquer pista (RaceStrategy.plans_by_stops).
## Cada linha tem a cor do pneu de cada stint, o pneu em cada parada com a janela ("VOLTA 18 A 24") e o rótulo à direita.
## A escolhida pode ser ajustada: tocar no pneu da parada muda a volta (− / +; no PC também arrastando ou com as setas)
## e tocar num trecho da linha troca o composto daquele stint. Na corrida o plano só avisa: a parada acontece quando o
## jogador confirma no box. Vale para Grande Prêmio, campanha e Mundial, no celular e no PC.

const ROW_Y := [150.0, 262.0, 374.0]
const ROW_SIZE := Vector2(1200, 100)
const LINE_Y := 70.0
const LINE_W := 1150.0  ## a linha vai do início até o pneu do fim
const TYRE := 46.0
const NAMES := {0: "SEM PARADA", 1: "UMA PARADA", 2: "DUAS PARADAS", 3: "TRÊS PARADAS"}

var weekend: WeekendSim
var ctx: Dictionary
var stocks: Dictionary
var options: Dictionary = {}  ## id do piloto -> as três estratégias dos engenheiros
var sel: Dictionary = {}  ## id do piloto -> índice da estratégia escolhida
var chosen: Dictionary = {}  ## id do piloto -> cópia editável da escolhida
var edited: Dictionary = {}  ## id do piloto -> o jogador mexeu na escolhida
var current := ""  ## piloto mostrado
var _stage: Control
var _rows: Control
var _legend: HBoxContainer
var _warn: Label
var _who: HBoxContainer
var _pop: Control = null  ## folhinha aberta (ajuste da parada ou troca de pneu)
var _pop_stop := -1  ## parada sendo ajustada (setas do teclado)


func _ready() -> void:
	weekend = Session.weekend
	if weekend == null:
		Session.go_to_title.call_deferred()
		return
	ctx = weekend.race_context()
	stocks = weekend.race_tyre_stock(weekend.session_id() != "sprint")
	options = weekend.engineer_strategy()
	for did: String in options:
		var list: Array = options[did]
		var di := 0
		for i in list.size():
			if bool((list[i] as Dictionary).get("default", false)):
				di = i
		sel[did] = di
		chosen[did] = (list[di] as Dictionary).duplicate(true)
	current = String(_my_drivers()[0]["id"]) if not _my_drivers().is_empty() else ""
	var bg := _Backdrop.new()
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage = Control.new()
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	_stage.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_stage.offset_left = -640
	_stage.offset_right = 640
	_stage.offset_top = -360
	_stage.offset_bottom = 360
	_header()
	_rows = Control.new()
	_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rows.size = Vector2(1280, 720)
	_stage.add_child(_rows)
	_legend = HBoxContainer.new()
	_legend.add_theme_constant_override("separation", 48)
	_legend.position = Vector2(40, 508)
	_legend.size = Vector2(1200, 84)
	_stage.add_child(_legend)
	for y: float in [500.0, 592.0]:
		_rule(y)
	_warn = UiStyle.g_label("", 13, UiStyle.G_DIRECTOR, "bold")
	_warn.position = Vector2(40, 600)
	_warn.size = Vector2(1200, 22)
	_stage.add_child(_warn)
	_footer()
	_refresh()
	if Session.debug_ui == "stratedit":  # (captura) --ui=stratedit abre o ajuste da 1ª parada
		_open_stop.call_deferred(0)


func _my_drivers() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for d: Dictionary in weekend.drivers:
		if d["team"] == weekend.player_team and options.has(d["id"]):
			out.append(d)
	return out


func _sprint() -> bool:
	return bool(ctx.get("is_sprint", ctx["sprint"]))


# --- cabeçalho, legenda e rodapé ------------------------------------------------------------------------

func _rule(y: float) -> void:
	var r := ColorRect.new()
	r.color = UiStyle.G_STRAT_RULE
	r.position = Vector2(40, y)
	r.size = Vector2(1200, 1)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(r)


func _header() -> void:
	var c := weekend.circuit
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	top.add_child(CampaignHub.flag_rect(String(c.get("country_code", "")), 18))
	var cn := UiStyle.g_label(String(c.get("country", "")), 15, UiStyle.G_TEXT, "black")
	top.add_child(cn)
	var year := Season.year(Season.active) if Season.active != "" else 2026
	top.add_child(UiStyle.g_label("|  %s %d" % [String(c.get("grand_prix", "")), year], 15, UiStyle.G_TEXT_2, "bold"))
	top.position = Vector2(40, 18)
	_stage.add_child(top)
	_rule(50)
	var title := UiStyle.g_label("%s  /  %s" % [String(c.get("short_name", c.get("name", ""))), "ESTRATÉGIAS DA SPRINT" if _sprint() else "ESTRATÉGIAS POSSÍVEIS"], 40, UiStyle.G_TEXT, "black")
	title.add_theme_font_override("font", UiStyle.italic_black())
	title.position = Vector2(40, 62)
	_stage.add_child(title)
	_who = HBoxContainer.new()
	_who.add_theme_constant_override("separation", 8)
	_who.position = Vector2(860, 66)
	_who.size = Vector2(380, 48)
	_who.alignment = BoxContainer.ALIGNMENT_END
	_stage.add_child(_who)
	_rule(128)


func _fill_who() -> void:
	for ch in _who.get_children():
		ch.queue_free()
	var grid: Array = weekend.grids.get(weekend.session_id(), [])
	for d: Dictionary in _my_drivers():
		var did := String(d["id"])
		var on := did == current
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 48)
		var full := String(d["name"])
		b.text = "%s%s" % [full.get_slice(" ", full.get_slice_count(" ") - 1).to_upper(), (" · P%d" % (grid.find(did) + 1)) if grid.has(did) else ""]
		b.add_theme_font_override("font", UiStyle.G_BLACK)
		b.add_theme_font_size_override("font_size", UiStyle.fs(15))
		for st: String in ["normal", "hover", "pressed", "hover_pressed"]:
			var box := UiStyle.g_box(UiStyle.G_LIGHT if on else UiStyle.G_SURFACE_HOVER, 12, 16, 0)
			box.border_width_left = 6
			box.border_color = UiStyle.team_color(weekend.player_team)
			b.add_theme_stylebox_override(st, box)
		for k: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(k, UiStyle.G_INK if on else UiStyle.G_TEXT)
		b.pressed.connect(func() -> void:
			current = did
			_close_pop()
			_refresh())
		ScreenKit.press_feedback(b)
		_who.add_child(b)


func _footer() -> void:
	var back := _ghost("‹ VOLTAR")
	back.position = Vector2(40, 642)
	back.pressed.connect(_on_back)
	_stage.add_child(back)
	var reset := _ghost("REFAZER PLANOS")
	reset.position = Vector2(190, 642)
	reset.pressed.connect(_reset)
	_stage.add_child(reset)
	var go := CutButton.new()
	go.text = "CONFIRMAR ESTRATÉGIA"
	go.custom_minimum_size = Vector2(320, 58)
	go.add_theme_font_size_override("font_size", UiStyle.fs(18))
	_stage.add_child(go)
	go.position = Vector2(1240.0 - go.get_combined_minimum_size().x, 638)
	go.resized.connect(func() -> void: go.position.x = 1240.0 - go.size.x)
	go.pressed.connect(_confirm)


func _ghost(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 50)
	b.add_theme_font_override("font", UiStyle.G_BLACK)
	b.add_theme_font_size_override("font_size", UiStyle.fs(16))
	for st: String in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, UiStyle.g_box(UiStyle.G_SURFACE_HOVER if st == "normal" else UiStyle.G_SURFACE_PRESS, 12, 20, 0))
	ScreenKit.press_feedback(b)
	return b


func _fill_legend() -> void:
	for ch in _legend.get_children():
		ch.queue_free()
	var st: Dictionary = stocks.get(current, {})
	for k: String in _dry_hard_first():
		var c: Dictionary = weekend.tyres.compounds[k]
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 14)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", -2)
		v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		v.add_child(UiStyle.g_label(String(c["name"]).to_upper(), 22, Color(c["color"]), "bold"))
		var n := int(st.get(k, {}).get("new", 0))
		var u := int(st.get(k, {}).get("used", 0))
		v.add_child(UiStyle.g_caption("%d novo%s%s" % [n, "" if n == 1 else "s", (" · %d usado%s" % [u, "" if u == 1 else "s"]) if u > 0 else ""]))
		item.add_child(v)
		var tb := TyreBadge.new()
		tb.custom_minimum_size = Vector2(TYRE, TYRE)
		tb.set_compound(String(c["letter"]), Color(c["color"]))
		item.add_child(tb)
		_legend.add_child(item)
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_legend.add_child(fill)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", -2)
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var laps := UiStyle.g_label("%d VOLTAS" % int(ctx["total_laps"]), 22, UiStyle.G_TEXT_2, "bold")
	laps.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	info.add_child(laps)
	var rain := int(roundf(float(weekend.team_forecast(weekend.player_team)[2]["chance"]) * 100)) if weekend.forecast.size() > 2 else 0
	var cap := UiStyle.g_caption("chuva na corrida: %d%% (previsão da equipe)" % rain)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	info.add_child(cap)
	_legend.add_child(info)


## Compostos secos do duro para o macio (como a legenda do gráfico de referência).
func _dry_hard_first() -> Array:
	var dry: Array = weekend.tyres.dry_compounds().duplicate()
	dry.reverse()
	return dry


# --- linhas das estratégias ----------------------------------------------------------------------------

func _refresh() -> void:
	_fill_who()
	for ch in _rows.get_children():
		ch.queue_free()
	var list: Array = options.get(current, [])
	for i in mini(list.size(), ROW_Y.size()):
		var plan: Dictionary = chosen[current] if i == int(sel[current]) else list[i]
		var row := _StratRow.new()
		row.screen = self
		row.index = i
		row.plan = plan
		row.selected = i == int(sel[current])
		row.adjusted = row.selected and bool(edited.get(current, false))
		row.position = Vector2(40, ROW_Y[i])
		row.size = ROW_SIZE
		_rows.add_child(row)
		row.build()
	_fill_legend()
	var warn := RaceStrategy.warning(chosen[current], weekend.tyres, ctx, stocks[current]) if chosen.has(current) else ""
	if _locked_start(current):
		var rest_new := true
		for k in range(1, (chosen[current]["stints"] as Array).size()):
			rest_new = rest_new and bool(chosen[current]["stints"][k].get("new", true))
		if warn.begins_with("Algum stint usa jogo usado") and rest_new:
			warn = ""
		if warn == "":
			warn = "Largada com o pneu do Q2 (regra de 2012): o primeiro trecho não muda."
	_warn.text = warn


func _locked_start(did: String) -> bool:
	return weekend.session_id() == "race" and weekend.start_rule.has(did)


## Tocar numa linha: ela vira a escolhida (cópia nova dos engenheiros).
func pick(i: int) -> void:
	if i == int(sel[current]):
		return
	_close_pop()
	sel[current] = i
	edited[current] = false
	chosen[current] = (options[current][i] as Dictionary).duplicate(true)
	_refresh()


func compound_color(k: String) -> Color:
	return Color(weekend.tyres.compounds[k]["color"])


func compound_letter(k: String) -> String:
	return String(weekend.tyres.compounds[k]["letter"])


func total_laps() -> int:
	return int(ctx["total_laps"])


# --- ajustes da escolhida ------------------------------------------------------------------------------

## Folhinha da parada: volta da parada com − / + (no PC: setas do teclado ou arrastar o pneu na linha).
func _open_stop(stop: int) -> void:
	_close_pop()
	var plan: Dictionary = chosen[current]
	if stop >= (plan["stints"] as Array).size() - 1:
		return
	_pop_stop = stop
	var lap := int(RaceStrategy.stop_laps(plan)[stop])
	var x := 40.0 + LINE_W * float(lap) / total_laps()
	var box := _pop_box("PARADA %d · VOLTA DA PARADA" % (stop + 1), Vector2(clampf(x - 150.0, 40.0, 940.0), ROW_Y[int(sel[current])] + 92.0), 300.0)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var minus := _step_btn("−", func() -> void: adjust_stop(stop, -1))
	h.add_child(minus)
	var lbl := UiStyle.g_label("VOLTA %d" % lap, 22, UiStyle.G_TEXT, "black")
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(lbl)
	h.add_child(_step_btn("+", func() -> void: adjust_stop(stop, 1)))
	box["body"].add_child(h)
	var hint := UiStyle.g_caption("no PC: ← → ou arraste o pneu")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box["body"].add_child(hint)


## Folhinha do pneu de um trecho: os compostos secos com o estoque de cada um.
func _open_compound(stint: int) -> void:
	_close_pop()
	if stint == 0 and _locked_start(current):
		_warn.text = "Largada com o pneu do Q2 (regra de 2012): o primeiro trecho não muda."
		return
	var plan: Dictionary = chosen[current]
	var lap0 := 0
	for k in stint:
		lap0 += int(plan["stints"][k]["laps"])
	var mid := float(lap0) + float(plan["stints"][stint]["laps"]) / 2.0
	var x := 40.0 + LINE_W * mid / total_laps()
	var box := _pop_box("PNEU DO %dº TRECHO" % (stint + 1), Vector2(clampf(x - 150.0, 40.0, 940.0), ROW_Y[int(sel[current])] + 92.0), 300.0)
	var st: Dictionary = stocks.get(current, {})
	for k: String in weekend.tyres.dry_compounds():
		var c: Dictionary = weekend.tyres.compounds[k]
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 52)
		var on := String(plan["stints"][stint]["compound"]) == k
		for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(s, UiStyle.g_box(UiStyle.G_SURFACE_HOVER if on or s != "normal" else Color(0, 0, 0, 0), 12, 0, 0))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tb := TyreBadge.new()
		tb.custom_minimum_size = Vector2(38, 38)
		tb.set_compound(String(c["letter"]), Color(c["color"]))
		row.add_child(tb)
		var nl := UiStyle.g_label(String(c["name"]).to_upper(), 16, UiStyle.G_TEXT, "black")
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(nl)
		var n := int(st.get(k, {}).get("new", 0))
		row.add_child(UiStyle.g_caption("%d novo%s" % [n, "" if n == 1 else "s"]))
		b.add_child(row)
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 10
		row.offset_right = -10
		b.pressed.connect(func() -> void:
			plan["stints"][stint]["compound"] = k
			RaceStrategy.assign_sets(plan["stints"], stocks[current])
			edited[current] = true
			_close_pop()
			_refresh())
		ScreenKit.press_feedback(b)
		box["body"].add_child(b)


func _pop_box(title: String, pos: Vector2, w: float) -> Dictionary:
	var catcher := Button.new()  # toque fora fecha
	catcher.flat = true
	catcher.focus_mode = Control.FOCUS_NONE
	for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
		catcher.add_theme_stylebox_override(s, StyleBoxEmpty.new())
	catcher.position = Vector2.ZERO
	catcher.size = Vector2(1280, 720)
	catcher.pressed.connect(_close_pop)
	_stage.add_child(catcher)
	var p := PanelContainer.new()
	var st := UiStyle.g_box(UiStyle.G_GLASS, 18, 14, 14)
	st.set_border_width_all(1)
	st.border_color = UiStyle.G_STRAT_RULE
	st.shadow_color = Color(0, 0, 0, 0.55)
	st.shadow_size = 18
	p.add_theme_stylebox_override("panel", st)
	p.position = pos
	p.custom_minimum_size = Vector2(w, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.add_child(UiStyle.g_caption(title))
	p.add_child(v)
	catcher.add_child(p)
	p.position = pos
	_pop = catcher
	return {"root": catcher, "body": v}


func _step_btn(text: String, on: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(48, 48)
	b.add_theme_font_override("font", UiStyle.G_BLACK)
	b.add_theme_font_size_override("font_size", UiStyle.fs(24))
	for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(s, UiStyle.g_box(UiStyle.G_SURFACE_HOVER if s == "normal" else UiStyle.G_SURFACE_PRESS, 12, 0, 0))
	b.pressed.connect(on)
	ScreenKit.press_feedback(b)
	return b


## Move a parada `stop` uma volta (o trecho seguinte compensa). Reabre a folhinha com a volta nova.
func adjust_stop(stop: int, delta: int) -> void:
	if RaceStrategy.adjust_laps(chosen[current], stop, delta):
		edited[current] = true
		var reopen := _pop != null and _pop_stop == stop
		_refresh()
		if reopen:
			_open_stop(stop)


func _close_pop() -> void:
	if _pop != null and is_instance_valid(_pop):
		_pop.queue_free()
	_pop = null
	_pop_stop = -1


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or _pop_stop < 0:
		return
	if k.keycode == KEY_LEFT or k.keycode == KEY_RIGHT:
		adjust_stop(_pop_stop, -1 if k.keycode == KEY_LEFT else 1)
		get_viewport().set_input_as_handled()


# --- confirmação ---------------------------------------------------------------------------------------

func _reset() -> void:
	_close_pop()
	for did: String in options:
		var list: Array = options[did]
		var di := 0
		for i in list.size():
			if bool((list[i] as Dictionary).get("default", false)):
				di = i
		sel[did] = di
		edited[did] = false
		chosen[did] = (list[di] as Dictionary).duplicate(true)
	_refresh()


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
		if _pop != null:  # Esc / voltar fecha a folhinha antes de sair da tela
			_close_pop()
		else:
			_on_back()


# --- peças ---------------------------------------------------------------------------------------------

## Fundo escuro com listras diagonais finas e pontos (linguagem dos gráficos de transmissão, desenho próprio).
class _Backdrop:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), UiStyle.G_STRAT_BG)
		var step := 22.0
		var x := -size.y
		while x < size.x:
			draw_line(Vector2(x, size.y), Vector2(x + size.y * 0.47, 0), UiStyle.G_STRAT_STRIPE, 2.0)
			x += step
		var y := 13.0
		while y < size.y:
			var xx := 13.0
			while xx < size.x:
				draw_rect(Rect2(xx, y, 1.5, 1.5), UiStyle.G_STRAT_DOT)
				xx += 26.0
			y += 26.0


## Uma estratégia: linha na cor do pneu de cada trecho, pneu em cada parada com a janela e o rótulo à direita.
class _StratRow:
	extends Control

	var screen: Node
	var index := 0
	var plan: Dictionary = {}
	var selected := false
	var adjusted := false
	var _drag_stop := -1
	var _drag_x := 0.0

	func build() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		var stints: Array = plan["stints"]
		var total: int = screen.total_laps()
		var stops := RaceStrategy.stop_laps(plan)
		if selected:
			var tag := PanelContainer.new()
			tag.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_LIGHT, 6, 8, 1))
			var tl := UiStyle.g_label("ESCOLHIDA · AJUSTADA" if adjusted else "ESCOLHIDA", 11, UiStyle.G_INK, "black")
			tag.add_child(tl)
			tag.position = Vector2(14, 8)
			tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(tag)
		for s in stops.size():
			var lap := int(stops[s])
			var x := LINE_W * float(lap) / total
			var a := maxi(1, lap - 3)
			var b := mini(total - 1, lap + 3)
			var lab := RichTextLabel.new()
			lab.bbcode_enabled = true
			lab.fit_content = true
			lab.scroll_active = false
			lab.autowrap_mode = TextServer.AUTOWRAP_OFF
			lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
			lab.add_theme_font_override("normal_font", UiStyle.G_SEMI)
			lab.add_theme_font_override("bold_font", UiStyle.G_BLACK)
			lab.add_theme_font_size_override("normal_font_size", UiStyle.fs(19))
			lab.add_theme_font_size_override("bold_font_size", UiStyle.fs(19))
			lab.text = "[right]VOLTA [b]%d[/b] A [b]%d[/b][/right]" % [a, b]
			lab.size = Vector2(240, 30)
			lab.position = Vector2(x - 30.0 - 240.0, 26)
			add_child(lab)
			var t := _tyre_button(String(stints[s]["compound"]), x)
			var stop := s
			t.pressed.connect(func() -> void:
				if not selected:
					screen.pick(index)
				else:
					screen._open_stop(stop))
			t.gui_input.connect(_drag.bind(stop))
			add_child(t)
		var name := UiStyle.g_label(NAMES.get(stops.size(), "%d PARADAS" % stops.size()), 25, UiStyle.G_TEXT, "black")
		name.add_theme_font_override("font", UiStyle.italic_black())
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		name.size = Vector2(360, 34)
		name.position = Vector2(ROW_SIZE.x - 62.0 - 360.0, 20)
		name.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(name)
		var last := _tyre_button(String(stints[stints.size() - 1]["compound"]), LINE_W + TYRE / 2.0 - 2.0)
		last.disabled = true
		last.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(last)
		queue_redraw()

	func _tyre_button(k: String, x: float) -> Button:
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		for s: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			b.add_theme_stylebox_override(s, StyleBoxEmpty.new())
		b.size = Vector2(TYRE, TYRE)
		b.position = Vector2(x - TYRE / 2.0, LINE_Y - TYRE / 2.0)
		b.tooltip_text = "Mudar a volta da parada"
		var tb := TyreBadge.new()
		tb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tb.set_compound(screen.compound_letter(k), screen.compound_color(k))
		b.add_child(tb)
		tb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ScreenKit.press_feedback(b)
		return b

	## PC: arrastar o pneu da parada pela linha muda a volta (uma volta a cada ~LINE_W/total px).
	func _drag(event: InputEvent, stop: int) -> void:
		if not selected:
			return
		var mb := event as InputEventMouseButton
		if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
			_drag_stop = stop if mb.pressed else -1
			_drag_x = mb.position.x
			return
		var mm := event as InputEventMouseMotion
		if mm != null and _drag_stop == stop and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			var px := LINE_W / float(screen.total_laps())
			while mm.position.x - _drag_x >= px:
				_drag_x += px
				screen.adjust_stop(stop, 1)
			while _drag_x - mm.position.x >= px:
				_drag_x -= px
				screen.adjust_stop(stop, -1)

	## Toque na linha: escolhe a estratégia; na escolhida, abre a troca de pneu do trecho tocado.
	func _gui_input(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if not selected:
			screen.pick(index)
			return
		var total: int = screen.total_laps()
		var lap := mb.position.x / LINE_W * total
		var acc := 0.0
		var stints: Array = plan["stints"]
		for i in stints.size():
			acc += float(stints[i]["laps"])
			if lap <= acc or i == stints.size() - 1:
				screen._open_compound(i)
				return

	func _draw() -> void:
		if selected:
			var st := UiStyle.g_box(UiStyle.G_STRAT_SEL, 16, 0, 0)
			st.set_border_width_all(2)
			st.border_color = Color(UiStyle.G_LIGHT, 0.85)
			draw_style_box(st, Rect2(Vector2(0, 0), size))
		var stints: Array = plan["stints"]
		var total: int = screen.total_laps()
		var x0 := 0.0
		for i in stints.size():
			var col: Color = screen.compound_color(String(stints[i]["compound"]))
			var nxt: Color = screen.compound_color(String(stints[i + 1]["compound"])) if i + 1 < stints.size() else col
			var x1 := x0 + LINE_W * float(stints[i]["laps"]) / total
			var mid := x0 + (x1 - x0) * 0.7
			var h := 2.5
			draw_rect(Rect2(x0, LINE_Y - h, mid - x0, h * 2.0), col)
			draw_polygon(PackedVector2Array([Vector2(mid, LINE_Y - h), Vector2(x1, LINE_Y - h), Vector2(x1, LINE_Y + h), Vector2(mid, LINE_Y + h)]),
				PackedColorArray([col, nxt, nxt, col]))
			x0 = x1
