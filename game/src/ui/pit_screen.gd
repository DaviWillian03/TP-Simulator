class_name PitScreen
extends Control
## Tela do box (mockup v8-1) — abre por cima da corrida SEM pausar (1× ou 2×).
## Três colunas: pista em miniatura + parada dupla · jogos de pneus do estoque · ajustes do
## carro, tempo parado previsto e confirmação. Nada vale até "Confirmar box": só então o plano
## vai para a simulação (`RaceSim.set_pit_plan`). Custos e regras vêm de `PitStop`.

signal closed
signal speed_requested(scale: float)

const COMPOUNDS := ["soft", "medium", "hard", "inter", "wet"]
const COMPOUND_NOTE := {
	"soft": "mais rápido, dura menos", "medium": "equilíbrio", "hard": "dura mais, mais lento",
	"inter": "pista úmida", "wet": "pista encharcada",
}

var sim: RaceSim
var car: CarState
var mate: CarState = null

var _view: TrackView3D
var _home: Control
var _prev_followed: CarState = null
var _prev_cam_car := false

var _compound := "medium"
var _use_used := false
var _wing := 0
var _repair_wing := false
var _repair_floor := false
var _serve := true
var _double := 0  ## 0 só este carro · 1 companheiro na volta seguinte · 2 companheiro junto

var _mini: Panel
var _col_left: VBoxContainer
var _col_mid: VBoxContainer
var _col_right: VBoxContainer
var _countdown: Label
var _count_caption: Label
var _speed_seg: PanelContainer
var current_scale := 1.0  ## velocidade da corrida (a tela da corrida mantém este valor)


func setup(p_sim: RaceSim, p_car: CarState, view: TrackView3D, home: Control) -> void:
	sim = p_sim
	car = p_car
	_view = view
	_home = home
	for c in sim.cars:
		if c.is_player and c != car:
			mate = c
	_compound = _default_compound()
	_wing = car.wing_step
	_repair_wing = car.damage_wing > 0.0
	_serve = car.penalty_pending_s > 0.0
	if not car.plan.is_empty():  # já havia um plano confirmado: reabre com ele
		_compound = String(car.plan.get("compound", _compound))
		_use_used = bool(car.plan.get("use_used", false))
		_wing = int(car.plan.get("wing_step", _wing))
		_repair_wing = bool(car.plan.get("repair_wing", _repair_wing))
		_repair_floor = bool(car.plan.get("repair_floor", false))
		_serve = bool(car.plan.get("serve_penalty", _serve))
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	_attach_view()
	_refresh()


func _exit_tree() -> void:
	_detach_view()


## Composto sugerido: o primeiro seco diferente do atual com jogo no estoque (chuva: intermediário).
func _default_compound() -> String:
	var order := ["medium", "hard", "soft"]
	if sim.weather.wetness > 0.35:
		order = ["inter", "wet", "medium"]
	for k: String in order:
		if k != car.tyre and PitStop.sets_left(car, k) > 0:
			return k
	return car.tyre


# --- miniatura da pista -----------------------------------------------------------------

func _attach_view() -> void:
	_prev_cam_car = _view.cam_mode == TrackView3D.CamMode.CAR
	_prev_followed = _view.followed
	if not (_prev_cam_car and _view.followed == car):
		_view.follow(car)
	_view.reparent(_mini, false)
	_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _detach_view() -> void:
	if _view == null or not is_instance_valid(_view) or _home == null or not is_instance_valid(_home):
		return
	if _view.get_parent() != _home:
		_view.reparent(_home, false)
		_home.move_child(_view, 0)
		_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if _prev_cam_car and _prev_followed != null:
		if _view.followed != _prev_followed:
			_view.follow(_prev_followed)
	elif _view.cam_mode == TrackView3D.CamMode.CAR:
		_view.follow(null)
	_view = null


# --- construção -------------------------------------------------------------------------

func _build() -> void:
	# fundo opaco da Garagem na cor da equipe (cobre a corrida, que segue rodando por baixo)
	var bg := ColorRect.new()
	bg.color = UiStyle.G_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var backdrop := GarageBackdrop.new()
	backdrop.glow_color = car.team_color()
	add_child(backdrop)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 14)
	ScreenKit.place(bar, self, Control.PRESET_TOP_LEFT, Vector2(16, 8), Vector2(1248, 52))
	bar.add_child(DriverPhotos.make_avatar(car.driver, car.team_color(), 40))
	var ids := VBoxContainer.new()
	ids.add_theme_constant_override("separation", -2)
	ids.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ids.add_child(UiStyle.g_label("BOX · %s" % car.display_name().to_upper(), 24, UiStyle.G_TEXT, "black"))
	ids.add_child(UiStyle.g_caption("%s · volta %d de %d" % [sim.track.short_name.to_upper(), car.laps_done + 1, sim.total_laps]))
	bar.add_child(ids)
	_speed_seg = ScreenKit.segmented([[1.0, "1×"], [2.0, "2×"]], minf(2.0, current_scale), func(s: float) -> void: speed_requested.emit(s))
	_speed_seg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_child(_speed_seg)
	bar.add_child(UiStyle.hspacer())
	var count := PanelContainer.new()
	var cst := UiStyle.g_box(Color(UiStyle.RED, 0.18), 14, 14, 5)
	cst.border_width_left = 2
	cst.border_width_right = 2
	cst.border_width_top = 2
	cst.border_width_bottom = 2
	cst.border_color = UiStyle.RED
	count.add_theme_stylebox_override("panel", cst)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", -6)
	_count_caption = UiStyle.g_caption("Entrada do box em", Color("#ffb4a8"))
	_countdown = UiStyle.g_label("—", 22, UiStyle.G_TEXT, "black")
	cv.add_child(_count_caption)
	cv.add_child(_countdown)
	count.add_child(cv)
	count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_child(count)
	var back := ScreenKit.light_button("Voltar à corrida")
	back.custom_minimum_size = Vector2(0, 44)
	back.add_theme_font_size_override("font_size", 15)
	back.pressed.connect(_close)
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_child(back)

	# coluna esquerda: miniatura + parada dupla
	_col_left = VBoxContainer.new()
	_col_left.add_theme_constant_override("separation", 12)
	ScreenKit.place(_col_left, self, Control.PRESET_TOP_LEFT, Vector2(16, 70), Vector2(360, 636))
	_mini = Panel.new()
	_mini.add_theme_stylebox_override("panel", UiStyle.g_box(Color.BLACK, 16, 0, 0))
	_mini.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	_mini.custom_minimum_size = Vector2(360, 210)
	_col_left.add_child(_mini)
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", UiStyle.g_box(Color(0.05, 0.06, 0.08, 0.88), 12, 10, 5))
	chip.add_child(UiStyle.g_label("A corrida continua", 13, UiStyle.G_TEXT, "bold"))
	ScreenKit.place(chip, _mini, Control.PRESET_BOTTOM_LEFT, Vector2(10, -10))
	_col_left.add_child(Control.new())  # (a parada dupla entra no _refresh)

	_col_mid = VBoxContainer.new()
	_col_mid.add_theme_constant_override("separation", 8)
	var mid_panel := PanelContainer.new()
	mid_panel.add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.06), 20, 16, 14))
	mid_panel.add_child(_col_mid)
	ScreenKit.place(mid_panel, self, Control.PRESET_TOP_LEFT, Vector2(388, 70), Vector2(470, 636))

	_col_right = VBoxContainer.new()
	_col_right.add_theme_constant_override("separation", 8)
	ScreenKit.place(_col_right, self, Control.PRESET_TOP_LEFT, Vector2(870, 70), Vector2(394, 636))


func _clear(box: Control, keep := 0) -> void:
	var i := 0
	for c in box.get_children():
		if i >= keep:
			box.remove_child(c)
			c.queue_free()
		i += 1


# --- atualização ------------------------------------------------------------------------

func _refresh() -> void:
	_build_double()
	_build_sets()
	_build_right()


func _process(_delta: float) -> void:
	if car.in_pit or car.finished or car.retired:
		_close()
		return
	var eta := sim.pit_entry_eta_s(car)
	_count_caption.text = "Entrada do box em" if car.pit_requested else "Box não confirmado"
	_countdown.text = "%d:%02d" % [int(eta) / 60, int(eta) % 60] if car.pit_requested else "—"
	var scale := current_scale
	for b: Button in (_speed_seg.get_child(0) as Control).get_children():
		b.set_pressed_no_signal(is_equal_approx(float(b.get_meta("value")), scale))


func _build_double() -> void:
	_clear(_col_left, 1)
	var pn := ScreenKit.g_card(Color(1, 1, 1, 0.06), 20, 16, 14)
	pn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_col_left.add_child(pn)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pn.add_child(v)
	v.add_child(UiStyle.g_caption("Parada dupla"))
	if mate == null or mate.retired or mate.finished or mate.in_pit:
		v.add_child(_note("Sem companheiro disponível para a parada dupla."))
		return
	var wait := sim.box_queue_wait_s(mate)
	var both := HBoxContainer.new()
	both.add_theme_constant_override("separation", 8)
	both.add_child(_double_cell(car, "Entra primeiro", "pit em %s" % _mmss(sim.pit_entry_eta_s(car)), true))
	both.add_child(_double_cell(mate, "Espera ~%.1f s" % (_estimate_total() + PitStop.QUEUE_GAP_S) if _double == 2 else "Segue na pista", "entra na volta %d" % (car.laps_done + 2) if _double == 1 else ("junto, na fila" if _double == 2 else "sem box agora"), false))
	v.add_child(both)
	var opts := [[0, "Só %s" % car.code()], [1, "%s na volta seguinte" % mate.code()], [2, "%s junto (fila)" % mate.code()]]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for o: Array in opts:
		var b := Button.new()
		b.text = o[1]
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MIN)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ScreenKit._selectable_styles(b, 12)
		b.add_theme_stylebox_override("normal", UiStyle.g_box(Color(1, 1, 1, 0.08), 12, 6, 0))
		b.add_theme_font_size_override("font_size", 12)
		b.set_pressed_no_signal(_double == int(o[0]))
		var val: int = o[0]
		b.pressed.connect(func() -> void:
			_double = val
			_refresh())
		row.add_child(b)
	v.add_child(row)
	var info := "Se os dois entram na mesma volta, o segundo espera o primeiro sair do box (agora ~%.1f s de fila). Segurar um carro por uma volta evita a fila, mas ele roda mais com o pneu velho." % wait
	v.add_child(_note(info))


func _double_cell(c: CarState, line1: String, line2: String, me: bool) -> PanelContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", UiStyle.g_box(Color(c.team_color(), 0.28) if me else Color(1, 1, 1, 0.07), 14, 12, 9))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -1)
	v.add_child(UiStyle.g_caption(StandingsPanel.surname(c.display_name()).to_upper()))
	v.add_child(UiStyle.g_label(line1, 15, UiStyle.G_TEXT, "black"))
	v.add_child(UiStyle.g_label(line2, 12, UiStyle.G_TEXT_2))
	p.add_child(v)
	return p


func _note(text: String) -> Label:
	var l := UiStyle.g_label(text, 12, UiStyle.G_TEXT_3)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(300, 0)
	return l


func _mmss(s: float) -> String:
	return "%d:%02d" % [int(s) / 60, int(s) % 60]


# --- pneus ------------------------------------------------------------------------------

func _build_sets() -> void:
	_clear(_col_mid)
	_col_mid.add_child(UiStyle.g_caption("Pneus para a parada"))
	var wet_now: bool = sim.weather.wetness > 0.35
	for k: String in COMPOUNDS:
		_col_mid.add_child(_set_row(k, wet_now))
	var which := HBoxContainer.new()
	which.add_theme_constant_override("separation", 6)
	for o: Array in [[false, "Jogo novo"], [true, "Jogo usado"]]:
		var b := Button.new()
		b.text = o[1]
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 40)
		var used: bool = o[0]
		ScreenKit._selectable_styles(b, 12)
		b.add_theme_stylebox_override("normal", UiStyle.g_box(Color(1, 1, 1, 0.08), 12, 6, 0))
		b.add_theme_font_size_override("font_size", 13)
		b.set_pressed_no_signal(_use_used == used)
		b.disabled = not PitStop.has_set(car, _compound, used)
		b.pressed.connect(func() -> void:
			_use_used = used
			_refresh())
		which.add_child(b)
	_col_mid.add_child(which)
	_col_mid.add_child(_note("O jogo usado já rodou na classificação e começa com ~15% de desgaste. O estoque acaba: pense na corrida inteira."))
	var rule := sim.compound_rule_ok(car)
	if not rule:
		var warn := UiStyle.g_label("● Ainda falta usar outro composto seco (regra da prova)", 12, Color("#ffd24a"), "bold")
		warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_col_mid.add_child(warn)


func _set_row(k: String, wet_now: bool) -> Control:
	var c: Dictionary = sim.tyres.compounds[k]
	var st: Dictionary = car.tyre_stock.get(k, {"new": 0, "used": 0}) if not car.tyre_stock.is_empty() else {"new": 9, "used": 0}
	var total := int(st["new"]) + int(st["used"])
	var on := k == _compound
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 62)
	b.disabled = total <= 0
	var fill := UiStyle.G_LIGHT if on else Color(1, 1, 1, 0.07)
	for s: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		b.add_theme_stylebox_override(s, UiStyle.g_box(fill, 16, 14, 0))
	ScreenKit.press_feedback(b)
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 12)
	b.add_child(h)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 14
	h.offset_right = -14
	var badge := TyreBadge.new()
	badge.custom_minimum_size = Vector2(40, 40)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.set_compound(c["letter"], Color(c["color"]))
	h.add_child(badge)
	var names := VBoxContainer.new()
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	names.add_theme_constant_override("separation", -2)
	var fg := UiStyle.G_INK if on else UiStyle.G_TEXT
	var nm := UiStyle.g_label(String(c["name"]), 17, fg, "black")
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sub := UiStyle.g_label(COMPOUND_NOTE[k], 12, UiStyle.G_INK_2 if on else UiStyle.G_TEXT_2)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	names.add_child(nm)
	names.add_child(sub)
	h.add_child(names)
	h.add_child(UiStyle.hspacer())
	var grp := VBoxContainer.new()
	grp.alignment = BoxContainer.ALIGNMENT_CENTER
	grp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grp.add_theme_constant_override("separation", 2)
	var cap := UiStyle.g_caption("Novos %d · usados %d" % [int(st["new"]), int(st["used"])], UiStyle.G_INK_2 if on else UiStyle.G_TEXT_3)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grp.add_child(cap)
	var dots := SetDots.new()
	dots.setup(int(st["new"]), int(st["used"]), on)
	dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dots.size_flags_horizontal = Control.SIZE_SHRINK_END
	grp.add_child(dots)
	h.add_child(grp)
	# compostos de chuva ficam apagados com a pista seca (e vice-versa), mas continuam escolhíveis
	var odd := (k in ["inter", "wet"]) != wet_now
	b.modulate = Color(1, 1, 1, 0.55 if odd and not on else 1.0)
	b.pressed.connect(func() -> void:
		_compound = k
		if not PitStop.has_set(car, k, _use_used):
			_use_used = not _use_used
		_refresh())
	return b


# --- ajustes, tempo e confirmação ---------------------------------------------------------

func _plan() -> Dictionary:
	return PitStop.make_plan(_compound, _use_used, _wing, _repair_wing, _repair_floor, _serve)


func _estimate_total() -> float:
	return float(PitStop.estimate(car, _plan())["total"])


func _build_right() -> void:
	_clear(_col_right)
	var adj := ScreenKit.g_card(Color(1, 1, 1, 0.06), 20, 16, 10)
	var av := VBoxContainer.new()
	av.add_theme_constant_override("separation", 0)
	adj.add_child(av)
	av.add_child(UiStyle.g_caption("Ajustes do carro"))
	# asa dianteira: passos −1…+2
	var wing_row := _adj_row("Asa dianteira", "mais asa: mais rápido, gasta mais pneu", 60)
	var steps := HBoxContainer.new()
	steps.add_theme_constant_override("separation", 4)
	for s in range(PitStop.WING_MIN, PitStop.WING_MAX + 1):
		var b := Button.new()
		b.text = ("+%d" % s) if s > 0 else ("−%d" % -s if s < 0 else "0")
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(UiStyle.TOUCH_MIN - 4, UiStyle.TOUCH_MIN - 4)
		ScreenKit._selectable_styles(b, 10)
		b.add_theme_stylebox_override("normal", UiStyle.g_box(Color(1, 1, 1, 0.08), 10, 4, 0))
		b.add_theme_font_size_override("font_size", 14)
		b.set_pressed_no_signal(_wing == s)
		var val := s
		b.pressed.connect(func() -> void:
			_wing = val
			_refresh())
		steps.add_child(b)
	wing_row.add_child(steps)
	av.add_child(wing_row)
	# asa danificada
	var dmg := car.damage_wing > 0.0
	av.add_child(_toggle_row("Trocar a asa danificada",
		("asa com −%d%% de eficiência" % roundi(car.damage_wing * 100.0)) if dmg else "asa sem dano", _repair_wing and dmg, dmg,
		func(on: bool) -> void:
			_repair_wing = on
			_refresh()))
	# assoalho
	var fl := car.damage_floor > 0.0
	av.add_child(_toggle_row("Reparo parcial do assoalho",
		("recupera metade do dano (−%d%%)" % roundi(car.damage_floor * 100.0)) if fl else "assoalho sem dano", _repair_floor and fl, fl,
		func(on: bool) -> void:
			_repair_floor = on
			_refresh()))
	# punição de tempo
	var pen := car.penalty_pending_s > 0.0
	av.add_child(_toggle_row("Cumprir a punição de %d s agora" % int(car.penalty_pending_s) if pen else "Cumprir punição de tempo",
		"se não cumprir, soma %d s ao tempo final" % int(car.penalty_pending_s) if pen else "nenhuma punição pendente", _serve and pen, pen,
		func(on: bool) -> void:
			_serve = on
			_refresh()))
	_col_right.add_child(adj)

	var est := PitStop.estimate(car, _plan())
	var tm := ScreenKit.g_card(Color(1, 1, 1, 0.06), 20, 16, 10)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 2)
	tm.add_child(tv)
	tv.add_child(UiStyle.g_caption("Tempo parado previsto"))
	var big := HBoxContainer.new()
	big.add_theme_constant_override("separation", 4)
	var secs := UiStyle.g_label(("%.1f" % float(est["total"])).replace(".", ","), 50, UiStyle.G_TEXT, "black")
	big.add_child(secs)
	var unit := UiStyle.g_label("s", 22, UiStyle.G_TEXT_2)
	unit.size_flags_vertical = Control.SIZE_SHRINK_END
	big.add_child(unit)
	tv.add_child(big)
	tv.add_child(_cost_row("Troca de pneus", float(est["base"]), false))
	if _wing != car.wing_step:
		tv.add_child(_cost_row("Asa dianteira %+d" % _wing, float(est["wing_adjust"]), true))
	if float(est["wing_change"]) > 0.0:
		tv.add_child(_cost_row("Troca da asa danificada", float(est["wing_change"]), true))
	if float(est["floor"]) > 0.0:
		tv.add_child(_cost_row("Reparo do assoalho", float(est["floor"]), true))
	if float(est["penalty"]) > 0.0:
		tv.add_child(_cost_row("Punição de %d s cumprida" % int(car.penalty_pending_s), float(est["penalty"]), true))
	_col_right.add_child(tm)
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_col_right.add_child(fill)

	var cancel := Button.new()
	cancel.text = "CANCELAR PARADA" if (car.pit_requested or car.pit_defer_laps >= 0) else "NÃO PARAR"
	cancel.focus_mode = Control.FOCUS_NONE
	cancel.custom_minimum_size = Vector2(0, 44)
	for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
		cancel.add_theme_stylebox_override(s, UiStyle.g_box(Color(1, 1, 1, 0.1) if s != "pressed" else Color(1, 1, 1, 0.2), 14, 10, 0))
	cancel.add_theme_font_size_override("font_size", 14)
	cancel.pressed.connect(_cancel)
	ScreenKit.press_feedback(cancel)
	_col_right.add_child(cancel)
	var ok := CutButton.new()
	ok.text = "CONFIRMAR BOX"
	ok.custom_minimum_size = Vector2(0, 54)
	ok.add_theme_font_size_override("font_size", 18)
	ok.disabled = not PitStop.has_set(car, _compound, _use_used)
	ok.pressed.connect(_confirm)
	_col_right.add_child(ok)


func _adj_row(title: String, sub: String, height: int) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.custom_minimum_size = Vector2(0, height)
	r.add_theme_constant_override("separation", 10)
	var t := VBoxContainer.new()
	t.alignment = BoxContainer.ALIGNMENT_CENTER
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_constant_override("separation", -1)
	t.add_child(UiStyle.g_label(title, 15, UiStyle.G_TEXT, "black"))
	var s := UiStyle.g_label(sub, 11, UiStyle.G_TEXT_2)
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	s.custom_minimum_size = Vector2(150, 0)
	t.add_child(s)
	r.add_child(t)
	return r


func _toggle_row(title: String, sub: String, on: bool, enabled: bool, on_change: Callable) -> Control:
	var r := _adj_row(title, sub, 56)
	var sw := PitSwitch.new()
	sw.on = on
	sw.enabled = enabled
	sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sw.changed.connect(on_change)
	r.add_child(sw)
	var line := VBoxContainer.new()
	line.add_child(r)
	var sep := ColorRect.new()
	sep.color = Color(1, 1, 1, 0.07)
	sep.custom_minimum_size = Vector2(0, 1)
	line.add_child(sep)
	return line


func _cost_row(text: String, secs: float, extra: bool) -> Control:
	var h := HBoxContainer.new()
	h.add_child(UiStyle.g_label(text, 14, UiStyle.G_TEXT_2))
	h.add_child(UiStyle.hspacer())
	h.add_child(UiStyle.g_label(("+%.1f s" if extra else "%.1f s") % secs, 14, Color("#ffd24a") if extra else UiStyle.G_TEXT, "black"))
	return h


# --- decisões ---------------------------------------------------------------------------

func _confirm() -> void:
	var plan := _plan()
	if not sim.set_pit_plan(car, plan):
		return
	if mate != null and not (mate.retired or mate.finished or mate.in_pit):
		var mplan := PitStop.make_plan(_compound, false, mate.wing_step, mate.damage_wing > 0.0, false, mate.penalty_pending_s > 0.0)
		if not PitStop.has_set(mate, _compound, false):
			mplan["use_used"] = true
		match _double:
			1:
				if sim.set_pit_plan(mate, mplan):
					sim.defer_pit(mate, 1)
			2:
				sim.set_pit_plan(mate, mplan)
	_close()


func _cancel() -> void:
	sim.cancel_pit(car)
	car.plan = {}
	car.pit_defer_laps = -1
	_close()


func _close() -> void:
	if not is_inside_tree():
		return
	_detach_view()
	closed.emit()
	queue_free()


# --- peças gráficas ---------------------------------------------------------------------

## Pontinhos do estoque: cheio = jogo novo, vazado = usado, apagado = já gasto (até 3).
class SetDots:
	extends Control

	var fresh := 0
	var used := 0
	var light := false

	func setup(p_new: int, p_used: int, p_light: bool) -> void:
		fresh = p_new
		used = p_used
		light = p_light
		custom_minimum_size = Vector2(3 * 19, 14)

	func _draw() -> void:
		var ink := UiStyle.G_INK if light else Color("#f3f4f6")
		var dim := Color(0.45, 0.5, 0.58, 0.9) if light else Color(1, 1, 1, 0.28)
		for i in 3:
			var c := Vector2(7 + i * 19, 7)
			if i < fresh:
				draw_circle(c, 6.0, ink)
			elif i < fresh + used:
				draw_arc(c, 5.0, 0.0, TAU, 20, ink, 2.0, true)
			else:
				draw_arc(c, 5.0, 0.0, TAU, 20, dim, 2.0, true)


## Chave liga/desliga (alvo de toque 44 px; o desenho tem 52×30).
class PitSwitch:
	extends Control

	signal changed(on: bool)
	var on := false
	var enabled := true

	func _init() -> void:
		custom_minimum_size = Vector2(60, UiStyle.TOUCH_MIN)

	func _gui_input(e: InputEvent) -> void:
		if enabled and e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			on = not on
			queue_redraw()
			changed.emit(on)

	func _draw() -> void:
		var r := Rect2((size.x - 52) / 2.0, (size.y - 30) / 2.0, 52, 30)
		var bg := Color("#3c9d5d") if on else Color(1, 1, 1, 0.14)
		if not enabled:
			bg = Color(1, 1, 1, 0.06)
		var st := StyleBoxFlat.new()
		st.bg_color = bg
		st.set_corner_radius_all(15)
		draw_style_box(st, r)
		var cx := r.position.x + (39.0 if on else 15.0)
		draw_circle(Vector2(cx, r.position.y + 15.0), 12.0, Color.WHITE if on else (Color("#c3c9d3") if enabled else Color(1, 1, 1, 0.2)))
