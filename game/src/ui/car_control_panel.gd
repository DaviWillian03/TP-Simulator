class_name CarControlPanel
extends PanelContainer
## Painel de um carro do jogador: posição, pneu, bateria e as ordens (ritmo, energia, box).

var sim: RaceSim
var car: CarState

var _pos_label: Label
var _tyre_label: Label
var _wear_bar: ProgressBar
var _battery_bar: ProgressBar
var _status: Label
var _box_btn: Button
var _compound_group := ButtonGroup.new()
var _compound_buttons := {}


func setup(p_sim: RaceSim, p_car: CarState) -> void:
	sim = p_sim
	car = p_car
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)

	var head := HBoxContainer.new()
	var stripe := ColorRect.new()
	stripe.color = car.team_color()
	stripe.custom_minimum_size = Vector2(5, 22)
	head.add_child(stripe)
	head.add_child(UiStyle.label("#%d %s" % [int(car.driver["number"]), car.display_name()], 16, UiStyle.TEXT, true))
	head.add_child(UiStyle.hspacer())
	_pos_label = UiStyle.label("P–", 20, UiStyle.ACCENT_2, true)
	head.add_child(_pos_label)
	v.add_child(head)

	var info := HBoxContainer.new()
	_tyre_label = UiStyle.label("", 13, UiStyle.TEXT)
	_tyre_label.custom_minimum_size = Vector2(175, 0)
	info.add_child(_tyre_label)
	_wear_bar = _bar()
	info.add_child(_wear_bar)
	info.add_child(UiStyle.label("Bateria", 13, UiStyle.MUTED))
	_battery_bar = _bar()
	_battery_bar.add_theme_stylebox_override("fill", UiStyle.box(UiStyle.GOOD, 4, UiStyle.GOOD, 0))
	info.add_child(_battery_bar)
	v.add_child(info)

	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 4)
	var pace_group := ButtonGroup.new()
	for entry: Array in [["Poupar", CarState.PaceMode.CONSERVE], ["Normal", CarState.PaceMode.NORMAL], ["Atacar", CarState.PaceMode.ATTACK]]:
		var b := _mode_button(entry[0], pace_group, car.pace_mode == entry[1])
		b.pressed.connect(sim.set_pace_mode.bind(car, entry[1]))
		modes.add_child(b)
	var sep := VSeparator.new()
	modes.add_child(sep)
	var energy_group := ButtonGroup.new()
	for entry: Array in [["Carregar", CarState.EnergyMode.HARVEST], ["Equilíbrio", CarState.EnergyMode.BALANCED], ["Bateria", CarState.EnergyMode.DEPLOY]]:
		var b := _mode_button(entry[0], energy_group, car.energy_mode == entry[1])
		b.pressed.connect(sim.set_energy_mode.bind(car, entry[1]))
		modes.add_child(b)
	v.add_child(modes)

	var pit := HBoxContainer.new()
	pit.add_theme_constant_override("separation", 4)
	for id: String in sim.tyres.dry_compounds():
		var c: Dictionary = sim.tyres.compounds[id]
		var b := UiStyle.button(c["letter"], true, _compound_group)
		b.custom_minimum_size = Vector2(44, 40)
		b.add_theme_color_override("font_color", Color(c["color"]))
		b.add_theme_color_override("font_pressed_color", Color(c["color"]))
		b.add_theme_font_override("font", UiStyle.BOLD_FONT)
		b.tooltip_text = c["name"]
		b.set_meta("compound", id)
		b.pressed.connect(_on_compound_changed)
		_compound_buttons[id] = b
		pit.add_child(b)
	_compound_buttons.get(car.pit_compound, _compound_buttons.values()[0]).button_pressed = true
	_box_btn = UiStyle.compact(UiStyle.button("CHAMAR P/ BOX", true), 14)
	_box_btn.custom_minimum_size = Vector2(130, 40)
	_box_btn.add_theme_font_override("font", UiStyle.BOLD_FONT)
	_box_btn.toggled.connect(_on_box_toggled)
	pit.add_child(_box_btn)
	_status = UiStyle.label("", 12, UiStyle.MUTED)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pit.add_child(_status)
	v.add_child(pit)


func _bar() -> ProgressBar:
	var b := ProgressBar.new()
	b.min_value = 0.0
	b.max_value = 100.0
	b.show_percentage = false
	b.custom_minimum_size = Vector2(70, 12)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return b


func _mode_button(text: String, group: ButtonGroup, pressed: bool) -> Button:
	var b := UiStyle.compact(UiStyle.button(text, true, group))
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
	_tyre_label.text = "%s · %d volta%s · %d%% gasto" % [c["name"], car.tyre_laps, "" if car.tyre_laps == 1 else "s", roundi(clampf(car.tyre_wear, 0.0, 1.0) * 100.0)]
	_wear_bar.value = clampf(car.tyre_wear, 0.0, 1.0) * 100.0
	_wear_bar.add_theme_stylebox_override("fill", UiStyle.box(Color(c["color"]), 4, Color(c["color"]), 0))
	_battery_bar.value = car.battery * 100.0
	# o botão acompanha o estado real (ex.: depois da parada ele volta a ficar solto)
	_box_btn.set_pressed_no_signal(car.pit_requested or car.in_pit)
	_box_btn.disabled = car.in_pit or car.finished
	if car.finished:
		_status.text = "Corrida encerrada." + (" Desclassificado: não usou 2 compostos." if car.disqualified else "")
	elif car.in_pit:
		_status.text = "No pit lane…"
	elif car.pit_requested:
		if car.laps_done + 1 >= sim.total_laps:
			_status.text = "Última volta: não dá mais para parar."
		elif sim.frac_of(car) < sim.track.pit_entry_frac:
			_status.text = "Box confirmado: entra no fim desta volta."
		else:
			_status.text = "Box confirmado: entra na próxima volta."
	elif not sim.tyres.rule_satisfied(car.compounds_used):
		_status.text = "Regra: falta usar outro composto seco."
		_status.add_theme_color_override("font_color", UiStyle.WARN)
		return
	else:
		_status.text = "Vida estimada do pneu: ~%d voltas." % floori(sim.tyre_laps_left(car))
	_status.add_theme_color_override("font_color", UiStyle.MUTED)
