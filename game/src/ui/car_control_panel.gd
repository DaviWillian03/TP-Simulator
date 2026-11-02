class_name CarControlPanel
extends PanelContainer
## Cartão de um carro do jogador — direção Garagem (mockup v7): rosto, nome, posição, pneu com a
## barra de vida (esvazia), diferença para o carro da frente e o de trás, ritmo e energia, ordens
## de equipe (popover) e o botão de box, que abre a tela do box (a corrida não pausa).

signal pit_pressed(car: CarState)
signal orders_pressed(car: CarState, anchor: Control)

var sim: RaceSim
var car: CarState

var _pos_label: Label
var _tyre_badge: TyreBadge
var _tyre_label: Label
var _life_bar: StandingsPanel.LifeBar
var _life_label: Label
var _gap_label: Label
var _battery_bar: ProgressBar
var _damage_label: Label
var _rule_label: Label
var _box_btn: Button
var _orders_btn: Button
var _orders_value: Label
var _pace_buttons := {}
var _energy_buttons := {}
var _box_status := ""


func setup(p_sim: RaceSim, p_car: CarState) -> void:
	sim = p_sim
	car = p_car
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var team_color := car.team_color()
	add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.06), 18, 12, 7))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	add_child(v)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 9)
	head.add_child(DriverPhotos.make_avatar(car.driver, team_color, 40))
	head.add_child(UiStyle.g_label(car.display_name(), 17, UiStyle.G_TEXT, "black"))
	head.add_child(TeamEmblems.make_rect(car.team["id"], 22))
	var num := UiStyle.g_label("#%d" % int(car.driver["number"]), 13, UiStyle.G_TEXT_3)
	num.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(num)
	_rule_label = UiStyle.g_label("", 12, Color("#ffb4a8"), "bold")
	_rule_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_rule_label)
	_damage_label = UiStyle.g_label("", 12, Color("#ffd24a"), "black")
	_damage_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_damage_label)
	head.add_child(UiStyle.hspacer())
	_pos_label = UiStyle.g_label("P–", 27, UiStyle.RED, "black")
	head.add_child(_pos_label)
	v.add_child(head)

	var tyre := HBoxContainer.new()
	tyre.add_theme_constant_override("separation", 7)
	_tyre_badge = TyreBadge.new()
	_tyre_badge.custom_minimum_size = Vector2(20, 20)
	tyre.add_child(_tyre_badge)
	_tyre_label = UiStyle.g_label("", 12, Color("#c3c9d3"))
	_tyre_label.custom_minimum_size = Vector2(84, 0)
	tyre.add_child(_tyre_label)
	_life_bar = StandingsPanel.LifeBar.new()
	_life_bar.custom_minimum_size = Vector2(0, 18)
	_life_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tyre.add_child(_life_bar)
	_life_label = UiStyle.g_label("", 12, UiStyle.G_TEXT, "black")
	_life_label.custom_minimum_size = Vector2(32, 0)
	_life_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tyre.add_child(_life_label)
	_gap_label = UiStyle.g_label("", 12, Color("#a8b0bd"), "bold")
	_gap_label.custom_minimum_size = Vector2(112, 0)
	_gap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tyre.add_child(_gap_label)
	_battery_bar = ProgressBar.new()
	_battery_bar.show_percentage = false
	_battery_bar.custom_minimum_size = Vector2(34, 8)
	_battery_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_battery_bar.tooltip_text = "Bateria"
	_battery_bar.add_theme_stylebox_override("background", UiStyle.g_box(Color(1, 1, 1, 0.12), 4, 0, 0))
	_battery_bar.add_theme_stylebox_override("fill", UiStyle.g_box(Color("#5c93ea"), 4, 0, 0))
	tyre.add_child(_battery_bar)
	v.add_child(tyre)

	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 8)
	modes.add_child(_segment([["Poupar", CarState.PaceMode.CONSERVE], ["Normal", CarState.PaceMode.NORMAL], ["Atacar", CarState.PaceMode.ATTACK]],
		car.pace_mode, _pace_buttons, func(m: int) -> void: sim.set_pace_mode(car, m)))
	modes.add_child(_segment([["Carregar", CarState.EnergyMode.HARVEST], ["Equilíbrio", CarState.EnergyMode.BALANCED], ["Bateria", CarState.EnergyMode.DEPLOY]],
		car.energy_mode, _energy_buttons, func(m: int) -> void: sim.set_energy_mode(car, m)))
	v.add_child(modes)

	var pit := HBoxContainer.new()
	pit.add_theme_constant_override("separation", 8)
	_orders_btn = Button.new()
	_orders_btn.focus_mode = Control.FOCUS_NONE
	_orders_btn.custom_minimum_size = Vector2(96, 44)
	for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
		_orders_btn.add_theme_stylebox_override(s, UiStyle.g_box(UiStyle.G_SURFACE_HOVER if s != "pressed" else UiStyle.G_SURFACE_PRESS, 12, 6, 0))
	var ob := VBoxContainer.new()
	ob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ob.alignment = BoxContainer.ALIGNMENT_CENTER
	ob.add_theme_constant_override("separation", -2)
	var oc := UiStyle.g_caption("Equipe")
	oc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	oc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_orders_value = UiStyle.g_label("Liberado", 13, UiStyle.G_TEXT, "black")
	_orders_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_orders_value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ob.add_child(oc)
	ob.add_child(_orders_value)
	_orders_btn.add_child(ob)
	ob.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_orders_btn.pressed.connect(func() -> void: orders_pressed.emit(car, _orders_btn))
	ScreenKit.press_feedback(_orders_btn)
	pit.add_child(_orders_btn)
	_box_btn = CutButton.new()
	_box_btn.text = "CHAMAR P/ BOX"
	_box_btn.custom_minimum_size = Vector2(0, 44)
	_box_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_box_btn.add_theme_font_size_override("font_size", 15)
	_box_btn.pressed.connect(func() -> void: pit_pressed.emit(car))
	pit.add_child(_box_btn)
	v.add_child(pit)


## Controle segmentado (ritmo ou energia). options: [[texto, valor], ...].
func _segment(options: Array, selected: int, store: Dictionary, on_pick: Callable) -> PanelContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_SURFACE, 22, 3, 3))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 2)
	p.add_child(h)
	var group := ButtonGroup.new()
	for o: Array in options:
		var b := Button.new()
		b.text = o[0]
		b.toggle_mode = true
		b.button_group = group
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 34)
		ScreenKit._selectable_styles(b, 17)
		b.add_theme_font_size_override("font_size", 12)
		b.button_pressed = o[1] == selected
		b.pressed.connect(on_pick.bind(o[1]))
		store[o[1]] = b
		h.add_child(b)
	return p


func refresh(race_position: int) -> void:
	_pos_label.text = "P%d" % race_position
	var c: Dictionary = sim.tyres.compounds[car.tyre]
	_tyre_badge.set_compound(c["letter"], Color(c["color"]))
	_tyre_label.text = "%s · %d volta%s" % [c["name"], car.tyre_laps, "" if car.tyre_laps == 1 else "s"]
	var life := 1.0 - clampf(car.tyre_wear, 0.0, 1.0)
	_life_bar.set_life(life)
	_life_label.text = "%d%%" % roundi(life * 100.0)
	_battery_bar.value = car.battery * 100.0
	# os botões acompanham o estado real (se o piloto desobedecer a ordem, volta para "liberado")
	for k: int in _pace_buttons:
		(_pace_buttons[k] as Button).set_pressed_no_signal(car.pace_mode == k)
	for k: int in _energy_buttons:
		(_energy_buttons[k] as Button).set_pressed_no_signal(car.energy_mode == k)
	_orders_value.text = {CarState.TeamOrder.FREE: "Liberado", CarState.TeamOrder.HOLD: "Não brigar", CarState.TeamOrder.LET_BY: "Deixar passar"}[car.team_order]
	_damage_label.text = "ASA −%d%%" % roundi(car.damage_wing * 100.0) if car.damage_wing > 0.0 else ""
	_rule_label.text = "" if car.finished or car.retired or sim.compound_rule_ok(car) else "● Falta outro composto"
	_gap_label.text = _gaps_text(race_position)
	var active := not (car.retired or car.finished)
	for b: Dictionary in [_pace_buttons, _energy_buttons]:
		for k: int in b:
			(b[k] as Button).disabled = not active
	_orders_btn.disabled = not active
	_box_btn.disabled = car.in_pit or car.finished or car.retired
	_box_btn.text = _box_text()


## Texto do botão de box, que também conta o estado da parada.
func _box_text() -> String:
	if car.retired:
		return "ABANDONOU: %s" % car.retire_reason.to_upper()
	if car.finished:
		return "DESCLASSIFICADO" if car.disqualified else "CORRIDA ENCERRADA"
	if car.in_pit:
		if car.box_hold_s > 0.0:
			return "PARADO NO BOX…"
		return "DRIVE-THROUGH…" if car.drive_through else "NO PIT LANE…"
	if car.drive_through:
		return "DRIVE-THROUGH NA PRÓXIMA"
	if car.pit_requested:
		if car.laps_done + 1 >= sim.total_laps:
			return "ÚLTIMA VOLTA: SEM BOX"
		return "BOX CONFIRMADO · AJUSTAR"
	if car.pit_defer_laps >= 0:
		return "BOX NA VOLTA %d · AJUSTAR" % (car.pit_defer_laps + 1)
	return "CHAMAR P/ BOX"


func _gaps_text(race_position: int) -> String:
	var order := sim.standings()
	var i := race_position - 1
	var ahead := "—"
	var behind := "—"
	if i > 0 and sim.laps_behind_leader(car) == sim.laps_behind_leader(order[i - 1]):
		ahead = "+%.1f s" % maxf(0.0, sim.gap_to_leader_s(car) - sim.gap_to_leader_s(order[i - 1]))
	if i + 1 < order.size() and not order[i + 1].retired and sim.laps_behind_leader(order[i + 1]) == sim.laps_behind_leader(car):
		behind = "%.1f s" % maxf(0.0, sim.gap_to_leader_s(order[i + 1]) - sim.gap_to_leader_s(car))
	return "▲ %s   ▼ %s" % [ahead, behind]
