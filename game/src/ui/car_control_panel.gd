class_name CarControlPanel
extends VBoxContainer
## Painel de um carro do jogador: posição, pneu, bateria e as ordens (ritmo, energia, box).

var sim: RaceSim
var car: CarState

var _pos_label: Label
var _tyre_badge: TyreBadge
var _tyre_label: Label
var _wear_bar: ProgressBar
var _battery_bar: ProgressBar
var _status: Label
var _box_btn: Button
var _wing_btn: Button
var _damage_label: Label
var _order_group := ButtonGroup.new()
var _order_buttons := {}
var _compound_group := ButtonGroup.new()
var _compound_buttons := {}


func setup(p_sim: RaceSim, p_car: CarState) -> void:
	sim = p_sim
	car = p_car
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 6)

	var head := HBoxContainer.new()
	head.add_child(TeamEmblems.make_rect(car.team["id"], 22))
	head.add_child(UiStyle.label("#%d" % int(car.driver["number"]), 15))
	head.add_child(UiStyle.label(car.display_name(), 18, UiStyle.INK, true))
	head.add_child(UiStyle.hspacer())
	_pos_label = UiStyle.label("P–", 30, UiStyle.RED, true)
	head.add_child(_pos_label)
	add_child(head)

	var info := HBoxContainer.new()
	info.add_theme_constant_override("separation", 6)
	info.add_child(UiStyle.caption("Pneu"))
	_tyre_badge = TyreBadge.new()
	info.add_child(_tyre_badge)
	_tyre_label = UiStyle.label("", 13)
	_tyre_label.custom_minimum_size = Vector2(150, 0)
	info.add_child(_tyre_label)
	_wear_bar = _bar(UiStyle.INK)
	info.add_child(_wear_bar)
	info.add_child(UiStyle.caption("Bateria"))
	_battery_bar = _bar(UiStyle.RED)
	info.add_child(_battery_bar)
	_damage_label = UiStyle.label("", 11, UiStyle.RED, true)
	info.add_child(_damage_label)
	add_child(info)

	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 4)
	var pace_group := ButtonGroup.new()
	for entry: Array in [["Poupar", CarState.PaceMode.CONSERVE], ["Normal", CarState.PaceMode.NORMAL], ["Atacar", CarState.PaceMode.ATTACK]]:
		var b := _mode_button(entry[0], pace_group, car.pace_mode == entry[1])
		b.pressed.connect(sim.set_pace_mode.bind(car, entry[1]))
		modes.add_child(b)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(10, 0)
	modes.add_child(gap)
	var energy_group := ButtonGroup.new()
	for entry: Array in [["Carregar", CarState.EnergyMode.HARVEST], ["Equilíbrio", CarState.EnergyMode.BALANCED], ["Bateria", CarState.EnergyMode.DEPLOY]]:
		var b := _mode_button(entry[0], energy_group, car.energy_mode == entry[1])
		b.pressed.connect(sim.set_energy_mode.bind(car, entry[1]))
		modes.add_child(b)
	add_child(modes)

	var orders := HBoxContainer.new()
	orders.add_theme_constant_override("separation", 4)
	var cap := UiStyle.caption("Equipe")
	cap.custom_minimum_size = Vector2(46, 0)
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	orders.add_child(cap)
	for entry: Array in [["Deixar passar", CarState.TeamOrder.LET_BY], ["Não brigar", CarState.TeamOrder.HOLD], ["Liberado", CarState.TeamOrder.FREE]]:
		var b := _mode_button(entry[0], _order_group, car.team_order == entry[1])
		b.pressed.connect(sim.set_team_order.bind(car, entry[1]))
		_order_buttons[entry[1]] = b
		orders.add_child(b)
	add_child(orders)

	var pit := HBoxContainer.new()
	pit.add_theme_constant_override("separation", 4)
	for id: String in ["soft", "medium", "hard", "inter", "wet"]:
		var c: Dictionary = sim.tyres.compounds[id]
		var b := UiStyle.compact(UiStyle.button(c["letter"], true, _compound_group), 15)
		b.custom_minimum_size = Vector2(32, 34)
		b.add_theme_font_override("font", UiStyle.HEAVY_FONT)
		b.add_theme_color_override("font_color", Color(c["color"]))
		b.add_theme_color_override("font_hover_color", Color(c["color"]))
		b.add_theme_color_override("font_outline_color", UiStyle.INK)
		b.add_theme_constant_override("outline_size", 3)
		b.tooltip_text = c["name"]
		b.set_meta("compound", id)
		b.pressed.connect(_on_compound_changed)
		_compound_buttons[id] = b
		pit.add_child(b)
	_compound_buttons.get(car.pit_compound, _compound_buttons.values()[0]).button_pressed = true
	_wing_btn = UiStyle.compact(UiStyle.button("Trocar asa", true), 12)
	_wing_btn.custom_minimum_size = Vector2(84, 34)
	_wing_btn.toggled.connect(func(on: bool) -> void: car.repair_wing = on)
	_wing_btn.visible = false
	pit.add_child(_wing_btn)
	_box_btn = UiStyle.compact(UiStyle.accent(UiStyle.button("Chamar p/ box", true)), 13)
	_box_btn.custom_minimum_size = Vector2(122, 34)
	_box_btn.toggled.connect(_on_box_toggled)
	pit.add_child(_box_btn)
	_status = UiStyle.label("", 11, UiStyle.MUTED)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pit.add_child(_status)
	add_child(pit)


func _bar(fill: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.min_value = 0.0
	b.max_value = 100.0
	b.show_percentage = false
	b.custom_minimum_size = Vector2(60, 7)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_theme_stylebox_override("fill", UiStyle.box(fill, 0, 0))
	return b


func _mode_button(text: String, group: ButtonGroup, pressed: bool) -> Button:
	var b := UiStyle.compact(UiStyle.button(text, true, group), 12)
	b.custom_minimum_size = Vector2(0, 32)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.button_pressed = pressed
	return b


func _selected_compound() -> String:
	var b := _compound_group.get_pressed_button()
	return b.get_meta("compound") if b else "hard"


func _on_compound_changed() -> void:
	if car.pit_requested and not car.in_pit:
		sim.request_pit(car, _selected_compound())


func _on_box_toggled(on: bool) -> void:
	if on:
		sim.request_pit(car, _selected_compound())
	else:
		sim.cancel_pit(car)


func refresh(race_position: int) -> void:
	_pos_label.text = "P%d" % race_position
	var c: Dictionary = sim.tyres.compounds[car.tyre]
	_tyre_badge.set_compound(c["letter"], Color(c["color"]))
	_tyre_label.text = "%s · %d volta%s · %d%%" % [c["name"], car.tyre_laps, "" if car.tyre_laps == 1 else "s", roundi(clampf(car.tyre_wear, 0.0, 1.0) * 100.0)]
	_wear_bar.value = clampf(car.tyre_wear, 0.0, 1.0) * 100.0
	_battery_bar.value = car.battery * 100.0
	# os botões acompanham o estado real (ex.: depois da parada o box volta a ficar solto;
	# se o piloto desobedecer, a ordem volta para "liberado")
	_box_btn.set_pressed_no_signal(car.pit_requested or car.in_pit)
	_box_btn.disabled = car.in_pit or car.finished or car.retired
	var order_btn: Button = _order_buttons[car.team_order]
	if not order_btn.button_pressed:
		order_btn.set_pressed_no_signal(true)
	_wing_btn.visible = car.damage_wing > 0.0 or car.repair_wing
	_wing_btn.set_pressed_no_signal(car.repair_wing)
	_damage_label.text = "ASA −%d%%" % roundi(car.damage_wing * 100.0) if car.damage_wing > 0.0 else ""
	var color := UiStyle.MUTED
	if car.retired:
		_status.text = "Abandonou: %s." % car.retire_reason
		color = UiStyle.RED
	elif car.finished:
		_status.text = "Corrida encerrada." + (" Desclassificado: não usou 2 compostos." if car.disqualified else "")
	elif car.in_pit:
		_status.text = "Drive-through…" if car.drive_through else "No pit lane…"
	elif car.drive_through:
		_status.text = "Punição: drive-through na próxima volta."
		color = UiStyle.RED
	elif car.pit_requested:
		if car.laps_done + 1 >= sim.total_laps:
			_status.text = "Última volta: não dá mais para parar."
		elif sim.frac_of(car) < sim.track.pit_entry_frac:
			_status.text = "Box confirmado: entra no fim desta volta."
		else:
			_status.text = "Box confirmado: entra na próxima volta."
	elif car.penalty_pending_s > 0.0:
		_status.text = "Punição de %d s: cumpre na próxima parada." % int(car.penalty_pending_s)
		color = UiStyle.RED
	elif not sim.compound_rule_ok(car):
		_status.text = "Falta usar outro composto seco."
		color = UiStyle.RED
	else:
		_status.text = "Vida estimada do pneu: ~%d voltas." % floori(sim.tyre_laps_left(car))
	_status.add_theme_color_override("font_color", color)
