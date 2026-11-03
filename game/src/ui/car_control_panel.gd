class_name CarControlPanel
extends PanelContainer
## Cartão de um carro do jogador — compacto e vertical, para ficar na coluna da esquerda sem
## tampar a pista (mockup v14): foto grande, sobrenome, posição, pneu com a barra de vida,
## diferença para o carro da frente e o de trás, ritmo, energia (com a bateria embaixo), ordens de
## equipe (popover) e o botão de box, que abre a tela do box (a corrida não pausa).

signal pit_pressed(car: CarState)
signal orders_pressed(car: CarState, anchor: Control)

const WIDTH := 236.0
const PHOTO := 62

var sim: RaceSim
var car: CarState

var _pos_label: Label
var _sub_label: Label
var _tyre_badge: TyreBadge
var _tyre_label: Label
var _life_bar: StandingsPanel.LifeBar
var _life_label: Label
var _battery_bar: ProgressBar
var _hint_label: Label
var _box_btn: Button
var _orders_btn: Button
var _orders_value: Label
var _pace_buttons := {}
var _energy_buttons := {}


func setup(p_sim: RaceSim, p_car: CarState) -> void:
	sim = p_sim
	car = p_car
	custom_minimum_size.x = WIDTH
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_GLASS, 20, 12, 10))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)

	# cabeça: foto, sobrenome, #número · diferenças, posição
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	# foto com a posição num selo no canto (assim o sobrenome ganha a largura toda)
	var photo := Control.new()
	photo.custom_minimum_size = Vector2(PHOTO, PHOTO)
	photo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var face := DriverPhotos.make_avatar(car.driver, car.team_color(), PHOTO)
	photo.add_child(face)
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.RED, 9, 6, 0))
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pos_label = UiStyle.g_label("P–", 14, Color.WHITE, "black")
	_pos_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(_pos_label)
	photo.add_child(chip)
	chip.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	chip.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	chip.grow_vertical = Control.GROW_DIRECTION_BEGIN
	chip.offset_right = 6
	chip.offset_bottom = 3
	head.add_child(photo)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", -2)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var full := car.display_name()
	var surname := UiStyle.g_label(full.get_slice(" ", full.get_slice_count(" ") - 1), 18, UiStyle.G_TEXT, "black")
	surname.clip_text = true
	surname.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	names.add_child(surname)
	_sub_label = UiStyle.g_label("", 12, UiStyle.G_TEXT_2, "bold")
	_sub_label.clip_text = true
	_sub_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	names.add_child(_sub_label)
	head.add_child(names)
	v.add_child(head)

	# pneu: círculo, nome e voltas, barra de vida (esvazia) e %
	var tyre := HBoxContainer.new()
	tyre.add_theme_constant_override("separation", 6)
	_tyre_badge = TyreBadge.new()
	_tyre_badge.custom_minimum_size = Vector2(22, 22)
	_tyre_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tyre.add_child(_tyre_badge)
	_tyre_label = UiStyle.g_label("", 12, Color("#c3c9d3"))
	tyre.add_child(_tyre_label)
	_life_bar = StandingsPanel.LifeBar.new()
	_life_bar.custom_minimum_size = Vector2(0, 16)
	_life_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_life_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tyre.add_child(_life_bar)
	_life_label = UiStyle.g_label("", 12, UiStyle.G_TEXT, "black")
	_life_label.custom_minimum_size = Vector2(36, 0)
	_life_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tyre.add_child(_life_label)
	v.add_child(tyre)

	# ritmo e energia (um embaixo do outro: cabem na largura estreita sem apertar os dedos)
	v.add_child(_segment([["Poupar", CarState.PaceMode.CONSERVE], ["Normal", CarState.PaceMode.NORMAL], ["Atacar", CarState.PaceMode.ATTACK]],
		car.pace_mode, _pace_buttons, func(m: int) -> void: sim.set_pace_mode(car, m)))
	v.add_child(_segment([["Carregar", CarState.EnergyMode.HARVEST], ["Equil.", CarState.EnergyMode.BALANCED], ["Bateria", CarState.EnergyMode.DEPLOY]],
		car.energy_mode, _energy_buttons, func(m: int) -> void: sim.set_energy_mode(car, m)))
	_battery_bar = ProgressBar.new()
	_battery_bar.show_percentage = false
	_battery_bar.custom_minimum_size = Vector2(0, 5)
	_battery_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_battery_bar.tooltip_text = "Bateria"
	_battery_bar.add_theme_stylebox_override("background", UiStyle.g_box(Color(1, 1, 1, 0.12), 3, 0, 0))
	_battery_bar.add_theme_stylebox_override("fill", UiStyle.g_box(Color("#5c93ea"), 3, 0, 0))
	v.add_child(_battery_bar)

	# avisos (regra dos compostos, dano na asa) só ocupam espaço quando existem
	_hint_label = UiStyle.g_label("", 12, Color("#ffb4a8"), "bold")
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.visible = false
	v.add_child(_hint_label)

	var pit := HBoxContainer.new()
	pit.add_theme_constant_override("separation", 6)
	_orders_btn = Button.new()
	_orders_btn.focus_mode = Control.FOCUS_NONE
	_orders_btn.custom_minimum_size = Vector2(72, 44)
	for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
		_orders_btn.add_theme_stylebox_override(s, UiStyle.g_box(UiStyle.G_SURFACE_HOVER if s != "pressed" else UiStyle.G_SURFACE_PRESS, 12, 4, 0))
	var ob := VBoxContainer.new()
	ob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ob.alignment = BoxContainer.ALIGNMENT_CENTER
	ob.add_theme_constant_override("separation", -3)
	var oc := UiStyle.g_label("EQUIPE", 11, UiStyle.G_TEXT_3, "bold")
	oc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	oc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_orders_value = UiStyle.g_label("Liberado", 12, UiStyle.G_TEXT, "black")
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
	_box_btn.text = "P/ BOX"
	_box_btn.custom_minimum_size = Vector2(0, 44)
	_box_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_box_btn.clip_text = true
	for st: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:  # margens menores: o botão é estreito
		var e := StyleBoxEmpty.new()
		e.content_margin_left = 12
		e.content_margin_right = 8
		_box_btn.add_theme_stylebox_override(st, e)
	_box_btn.add_theme_constant_override("icon_max_width", 18)
	_box_btn.add_theme_constant_override("h_separation", 6)
	_box_btn.add_theme_font_size_override("font_size", UiStyle.fs(13))
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
		b.custom_minimum_size = Vector2(0, 38)
		b.clip_text = true  # os três dividem a largura; o texto não alarga o cartão
		ScreenKit._selectable_styles(b, 17)
		for st: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			var sb: StyleBoxFlat = b.get_theme_stylebox(st)
			sb.content_margin_left = 2
			sb.content_margin_right = 2
		b.add_theme_font_size_override("font_size", UiStyle.fs(11))
		b.button_pressed = o[1] == selected
		b.pressed.connect(on_pick.bind(o[1]))
		store[o[1]] = b
		h.add_child(b)
	return p


func refresh(race_position: int) -> void:
	_pos_label.text = "P%d" % race_position
	_sub_label.text = "#%d · %s" % [int(car.driver["number"]), _gaps_text(race_position)]
	var c: Dictionary = sim.tyres.compounds[car.tyre]
	_tyre_badge.set_compound(c["letter"], Color(c["color"]))
	_tyre_label.text = "%s · %dv" % [c["name"], car.tyre_laps]
	var life := 1.0 - clampf(car.tyre_wear, 0.0, 1.0)
	_life_bar.set_life(life)
	_life_label.text = "%d%%" % roundi(life * 100.0)
	_battery_bar.value = car.battery * 100.0
	# os botões acompanham o estado real (se o piloto desobedecer a ordem, volta para "liberado")
	for k: int in _pace_buttons:
		(_pace_buttons[k] as Button).set_pressed_no_signal(car.pace_mode == k)
	for k: int in _energy_buttons:
		(_energy_buttons[k] as Button).set_pressed_no_signal(car.energy_mode == k)
	_orders_value.text = {CarState.TeamOrder.FREE: "Liberado", CarState.TeamOrder.HOLD: "Não brigar", CarState.TeamOrder.LET_BY: "Deixar"}[car.team_order]
	var hints: Array[String] = []
	if car.damage_wing > 0.0:
		hints.append("Asa −%d%%" % roundi(car.damage_wing * 100.0))
	if not (car.finished or car.retired or sim.compound_rule_ok(car)):
		hints.append("Falta usar outro composto seco.")
	_hint_label.text = " · ".join(hints)
	_hint_label.visible = not hints.is_empty()
	var active := not (car.retired or car.finished)
	for b: Dictionary in [_pace_buttons, _energy_buttons]:
		for k: int in b:
			(b[k] as Button).disabled = not active
	_orders_btn.disabled = not active
	_box_btn.disabled = car.in_pit or car.finished or car.retired
	_box_btn.text = _box_text()


## Texto do botão de box, que também conta o estado da parada (curto: o botão é estreito).
func _box_text() -> String:
	if car.retired:
		return "ABANDONOU"
	if car.finished:
		return "DESCLASSIFICADO" if car.disqualified else "ENCERRADA"
	if car.in_pit:
		if car.box_hold_s > 0.0:
			return "PARADO NO BOX"
		return "DRIVE-THROUGH" if car.drive_through else "NO PIT LANE"
	if car.drive_through:
		return "DRIVE-THROUGH"
	if car.pit_requested:
		if car.laps_done + 1 >= sim.total_laps:
			return "SEM BOX (ÚLT.)"
		return "BOX CONFIRMADO"
	if car.pit_defer_laps >= 0:
		return "BOX VOLTA %d" % (car.pit_defer_laps + 1)
	return "P/ BOX"


func _gaps_text(race_position: int) -> String:
	var order := sim.standings()
	var i := race_position - 1
	var ahead := "—"
	var behind := "—"
	if i > 0 and sim.laps_behind_leader(car) == sim.laps_behind_leader(order[i - 1]):
		ahead = "+%.1f" % maxf(0.0, sim.gap_to_leader_s(car) - sim.gap_to_leader_s(order[i - 1]))
	if i + 1 < order.size() and not order[i + 1].retired and sim.laps_behind_leader(order[i + 1]) == sim.laps_behind_leader(car):
		behind = "%.1f" % maxf(0.0, sim.gap_to_leader_s(order[i + 1]) - sim.gap_to_leader_s(car))
	return "▲%s ▼%s" % [ahead, behind]
