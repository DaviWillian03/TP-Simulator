class_name CarControlPanel
extends PanelContainer
## Cartão de um carro do jogador — compacto e vertical, na coluna da esquerda (mockup v14):
## foto com o logo da equipe ao lado (não por cima), sobrenome, posição, pneu com a barra de vida,
## ritmo com um velocímetro (o ponteiro sobe ao atacar e desce ao poupar), energia com o ícone da
## bateria mostrando a carga (raio quando gasta, seta quando recarrega), ordens de equipe e box.
## Tocar no cartão (fora dos botões) leva a câmera da pista para esse piloto, como a linha da torre.

signal pit_pressed(car: CarState)
signal orders_pressed(car: CarState, anchor: Control)
signal focus_pressed(car: CarState)
signal mission_pressed(car: CarState)

const WIDTH := 236.0
const PHOTO := 62

var sim: RaceSim
var car: CarState

var _pos_label: Label
var _sub_label: Label
var _num_label: Label
var _tyre_badge: TyreBadge
var _tyre_label: Label
var _drs_box: PanelContainer
var _drs_icon: TextureRect
var _drs_title: Label
var _drs_sub: Label
var _life_bar: StandingsPanel.LifeBar
var _life_label: Label
var _battery: BatteryIcon
var _gauge: GaugeIcon
var _logo: TextureRect
var _style: StyleBoxFlat
var _last_pos := 0
var _hint_label: Label
var _box_btn: Button
var _orders_btn: Button
var _orders_value: Label
var _auto_label: Label
var _base_box: Dictionary
var _short_box: Dictionary
var _mission_btn: Button


func setup(p_sim: RaceSim, p_car: CarState) -> void:
	sim = p_sim
	car = p_car
	custom_minimum_size.x = WIDTH
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "Tocar para seguir este piloto na pista"
	_style = UiStyle.g_box(UiStyle.G_GLASS, 20, 12, 10)
	_style.border_width_left = 5  # faixa na cor da equipe
	_style.border_color = car.team_color()
	_style.content_margin_left = 14
	add_theme_stylebox_override("panel", _style)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)

	# cabeça: foto | sobrenome; logo + posição + número; diferenças
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var face := DriverPhotos.make_avatar(car.driver, car.team_color(), PHOTO)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(face)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", -2)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var full := car.display_name()
	var surname := UiStyle.g_label(full.get_slice(" ", full.get_slice_count(" ") - 1), 18, UiStyle.G_TEXT, "black")
	surname.clip_text = true
	surname.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	names.add_child(surname)
	var pos_row := HBoxContainer.new()  # logo da equipe ao lado da foto, depois a posição e o número
	pos_row.add_theme_constant_override("separation", 6)
	pos_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo = TeamEmblems.make_rect(String(car.team["id"]), 22)
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pos_row.add_child(_logo)
	_pos_label = UiStyle.g_label("P–", 17, UiStyle.RED, "black")
	_pos_label.pivot_offset = Vector2(10, 12)
	pos_row.add_child(_pos_label)
	_num_label = UiStyle.g_label("", 12, UiStyle.G_TEXT_3, "bold")
	_num_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pos_row.add_child(_num_label)
	names.add_child(pos_row)
	_sub_label = UiStyle.g_label("", 12, UiStyle.G_TEXT_2, "bold")
	_sub_label.clip_text = true
	_sub_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	names.add_child(_sub_label)
	head.add_child(names)
	v.add_child(head)

	# pneu: círculo, nome e voltas, barra de vida (esvazia) e %
	var tyre := HBoxContainer.new()
	tyre.add_theme_constant_override("separation", 6)
	tyre.mouse_filter = Control.MOUSE_FILTER_IGNORE
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

	# missões (2026-11-09, mockup v25): o piloto dosa ritmo e bateria; o cartão mostra os dois só como informação
	var auto_row := HBoxContainer.new()
	auto_row.add_theme_constant_override("separation", 6)
	auto_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gauge = GaugeIcon.new()
	_gauge.custom_minimum_size = Vector2(26, 26)
	_gauge.tooltip_text = "Ritmo (o piloto decide)"
	auto_row.add_child(_gauge)
	_battery = BatteryIcon.new()
	_battery.custom_minimum_size = Vector2(26, 26)
	_battery.tooltip_text = "Bateria (o piloto decide)"
	_battery.visible = sim.energy_k > 0.0
	auto_row.add_child(_battery)
	_auto_label = UiStyle.g_label("", 12, UiStyle.G_TEXT_3, "bold")
	_auto_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_auto_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_auto_label.clip_text = true
	auto_row.add_child(_auto_label)
	v.add_child(auto_row)
	_base_box = _mission_box(false)
	v.add_child(_base_box["root"])
	_short_box = _mission_box(true)
	v.add_child(_short_box["root"])

	# avisos (regra dos compostos, dano na asa) só ocupam espaço quando existem
	_hint_label = UiStyle.g_label("", 12, Color("#ffb4a8"), "bold")
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.visible = false
	v.add_child(_hint_label)

	var pit := HBoxContainer.new()
	pit.add_theme_constant_override("separation", 6)
	_orders_btn = Button.new()
	_orders_btn.focus_mode = Control.FOCUS_NONE
	_orders_btn.custom_minimum_size = Vector2(56, 44)
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
	_mission_btn = Button.new()
	_mission_btn.text = "MISSÃO"
	_mission_btn.focus_mode = Control.FOCUS_NONE
	_mission_btn.custom_minimum_size = Vector2(58, 44)
	for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
		_mission_btn.add_theme_stylebox_override(s, UiStyle.g_box(UiStyle.G_LIGHT if s in ["normal", "hover"] else UiStyle.G_LIGHT_PRESS, 12, 4, 0))
	for k: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		_mission_btn.add_theme_color_override(k, UiStyle.G_INK)
	_mission_btn.add_theme_font_size_override("font_size", UiStyle.fs(11))
	_mission_btn.pressed.connect(func() -> void: mission_pressed.emit(car))
	ScreenKit.press_feedback(_mission_btn)
	pit.add_child(_mission_btn)
	_box_btn = CutButton.new()
	_box_btn.text = "P/ BOX"
	_box_btn.custom_minimum_size = Vector2(0, 44)
	_box_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_box_btn.clip_text = true
	for st: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:  # margens menores: o botão é estreito
		var e := StyleBoxEmpty.new()
		e.content_margin_left = 8
		e.content_margin_right = 4
		_box_btn.add_theme_stylebox_override(st, e)
	_box_btn.add_theme_constant_override("icon_max_width", 18)
	_box_btn.add_theme_constant_override("h_separation", 6)
	_box_btn.add_theme_font_size_override("font_size", UiStyle.fs(11))
	_box_btn.pressed.connect(func() -> void: pit_pressed.emit(car))
	pit.add_child(_box_btn)
	v.add_child(pit)


## Destaque do cartão quando a câmera da pista está seguindo este piloto.
func set_followed(on: bool) -> void:
	_style.border_width_top = 2 if on else 0
	_style.border_width_right = 2 if on else 0
	_style.border_width_bottom = 2 if on else 0
	_style.bg_color = Color(UiStyle.G_GLASS, 0.95) if on else UiStyle.G_GLASS


## Toque no cartão (fora dos botões): segue esse piloto na pista.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		focus_pressed.emit(car)
		accept_event()


## Caixa de missão (base ou curta): título, situação e barra de andamento.
func _mission_box(short: bool) -> Dictionary:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := UiStyle.g_box(Color(UiStyle.RED, 0.18) if short else UiStyle.G_SURFACE, 12, 8, 6)
	if short:
		st.set_border_width_all(1)
		st.border_color = Color(UiStyle.RED, 0.5)
	p.add_theme_stylebox_override("panel", st)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	var cap := UiStyle.g_caption("Missão curta" if short else "Missão de base")
	v.add_child(cap)
	var title := UiStyle.g_label("", 13, UiStyle.G_TEXT, "black")
	title.custom_minimum_size = Vector2(150, 0)
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(title)
	var sub := UiStyle.g_label("", 12, UiStyle.G_TEXT_2, "bold")
	sub.custom_minimum_size = Vector2(150, 0)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(sub)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = 1.0
	bar.custom_minimum_size = Vector2(0, 5)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", UiStyle.g_box(Color(1, 1, 1, 0.12), 3, 0, 0))
	v.add_child(bar)
	return {"root": p, "title": title, "sub": sub, "bar": bar, "short": short}


func _paint_mission(box: Dictionary, m: Dictionary) -> void:
	var root: Control = box["root"]
	root.visible = not m.is_empty()
	if m.is_empty():
		return
	var stt := Missions.status(sim, car, m)
	(box["title"] as Label).text = Missions.title(m)
	(box["sub"] as Label).text = String(stt["text"])
	var bar: ProgressBar = box["bar"]
	bar.value = float(stt["progress"])
	var col: Color = UiStyle.RED if box["short"] else (UiStyle.G_UP if bool(stt["ok"]) else UiStyle.G_DOWN)
	bar.add_theme_stylebox_override("fill", UiStyle.g_box(col, 3, 0, 0))


func refresh(race_position: int) -> void:
	_pos_label.text = "P%d" % race_position
	_num_label.text = "#%d" % int(car.driver["number"])
	_sub_label.text = _gaps_text(race_position)
	var c: Dictionary = sim.tyres.compounds[car.tyre]
	_tyre_badge.set_compound(c["letter"], Color(c["color"]))
	_tyre_label.text = "%s · %dv" % [c["name"], car.tyre_laps]
	if _drs_box != null:
		var open := sim.drs_open(car)
		_drs_box.add_theme_stylebox_override("panel", UiStyle.g_box(Color(UiStyle.G_UP, 0.15) if open else Color(1, 1, 1, 0.05), 12, 10, 6))
		_drs_icon.modulate = UiStyle.G_UP if open else UiStyle.G_TEXT_3
		_drs_title.text = "DRS ABERTO" if open else "DRS"
		_drs_title.add_theme_color_override("font_color", UiStyle.G_UP if open else UiStyle.G_TEXT_2)
		if open:
			_drs_sub.text = "a %s s do P%d" % [String.num(car.gap_ahead_s, 1).replace(".", ","), maxi(race_position - 1, 1)]
		elif car.laps_done < RaceSim.DRS_FROM_LAP:
			_drs_sub.text = "liberado a partir da volta %d" % (RaceSim.DRS_FROM_LAP + 1)
		else:
			_drs_sub.text = "abre a menos de 1 s do carro da frente"
	var life := 1.0 - clampf(car.tyre_wear, 0.0, 1.0)
	_life_bar.set_life(life)
	_life_label.text = "%d%%" % roundi(life * 100.0)
	_battery.level = car.battery
	_battery.mode = car.energy_mode
	_gauge.mode = car.pace_mode
	if _last_pos != 0 and race_position != _last_pos:  # mudou de posição: o número pulsa (verde ganhou, vermelho perdeu)
		var gained := race_position < _last_pos
		_pos_label.add_theme_color_override("font_color", Color("#39d36b") if gained else Color("#ff4d3d"))
		var tw := _pos_label.create_tween()
		tw.tween_property(_pos_label, "scale", Vector2(1.35, 1.35), 0.12)
		tw.tween_property(_pos_label, "scale", Vector2.ONE, 0.25)
		tw.tween_interval(1.2)
		tw.tween_callback(func() -> void: _pos_label.add_theme_color_override("font_color", UiStyle.RED))
	_last_pos = race_position
	_auto_label.text = "piloto: %s" % ["poupando", "normal", "atacando"][int(car.pace_mode)]
	_paint_mission(_base_box, car.mission_base if not car.mission_base.is_empty() else Missions.base_mission("normal"))
	var short: Dictionary = car.mission_short if not car.mission_short.is_empty() and car.laps_done >= int(car.mission_short.get("start", 0)) else {}
	if not car.mission_short.is_empty() and short.is_empty():  # agendada (o piloto pediu para esperar)
		short = car.mission_short
	_paint_mission(_short_box, short)
	_orders_value.text = {CarState.TeamOrder.FREE: "Liberado", CarState.TeamOrder.HOLD: "Não brigar", CarState.TeamOrder.LET_BY: "Deixar"}[car.team_order]
	var hints: Array[String] = []
	if car.damage_wing > 0.0:
		hints.append("Asa −%d%%" % roundi(car.damage_wing * 100.0))
	if car.damage_floor > 0.0:
		hints.append("Assoalho −%d%%" % roundi(car.damage_floor * 100.0))
	if car.power_loss_s > 0.0:
		hints.append("Problema mecânico: −%s s/volta" % String.num(car.power_loss_s, 1).replace(".", ","))
	if not (car.finished or car.retired or sim.compound_rule_ok(car)):
		hints.append("Falta usar outro composto seco.")
	_hint_label.text = " · ".join(hints)
	_hint_label.visible = not hints.is_empty()
	var active := not (car.retired or car.finished)
	_mission_btn.disabled = not active
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


## Velocímetro do ritmo: o ponteiro vai para a esquerda (poupar), meio (normal) ou direita (atacar), com
## a cor do arco acompanhando (verde, amarelo, vermelho). Anima ao trocar.
class GaugeIcon:
	extends Control
	var mode := CarState.PaceMode.NORMAL:
		set(v):
			mode = v
			var target := {CarState.PaceMode.CONSERVE: -0.8, CarState.PaceMode.NORMAL: 0.0, CarState.PaceMode.ATTACK: 0.8}[v] as float
			if not is_equal_approx(target, _target):
				_target = target
				set_process(true)
	var _angle := 0.0
	var _target := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS

	func _process(delta: float) -> void:
		_angle = move_toward(_angle, _target, delta * 4.0)
		queue_redraw()
		if is_equal_approx(_angle, _target):
			set_process(false)

	func _draw() -> void:
		var c := Vector2(size.x / 2.0, size.y * 0.62)
		var r := minf(size.x, size.y) * 0.44
		draw_circle(size / 2.0, minf(size.x, size.y) / 2.0, Color(1, 1, 1, 0.07), true, -1.0, true)
		var col := Color("#39d36b") if _angle < -0.3 else (Color("#ff4d3d") if _angle > 0.3 else Color("#ffd24a"))
		draw_arc(c, r, PI * 1.15, PI * 1.85, 24, Color(1, 1, 1, 0.18), 3.0, true)
		var a := PI * 1.5 + _angle * PI * 0.4
		draw_arc(c, r, PI * 1.15, a, 24, col, 3.0, true)
		draw_line(c, c + Vector2(cos(a), sin(a)) * (r - 2.0), Color.WHITE, 2.2, true)
		draw_circle(c, 2.6, Color.WHITE, true, -1.0, true)


## Bateria com a carga desenhada dentro (verde → amarelo → vermelho), raio quando está gastando e seta
## para cima quando está recarregando. O nível anima suavemente.
class BatteryIcon:
	extends Control
	var level := 0.8:
		set(v):
			level = clampf(v, 0.0, 1.0)
			set_process(true)
	var mode := CarState.EnergyMode.BALANCED:
		set(v):
			mode = v
			queue_redraw()
	var _shown := 0.8
	var _t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS

	func _process(delta: float) -> void:
		_shown = move_toward(_shown, level, delta * 0.8)
		_t += delta
		queue_redraw()

	func _draw() -> void:
		draw_circle(size / 2.0, minf(size.x, size.y) / 2.0, Color(1, 1, 1, 0.07), true, -1.0, true)
		var body := Rect2(Vector2(size.x * 0.3, size.y * 0.2), Vector2(size.x * 0.4, size.y * 0.64))
		var cap := Rect2(Vector2(size.x * 0.42, size.y * 0.13), Vector2(size.x * 0.16, size.y * 0.08))
		draw_rect(cap, Color.WHITE)
		draw_rect(body, Color.WHITE, false, 1.8)
		var inner := body.grow(-2.6)
		var h := inner.size.y * _shown
		var fill := Color("#39d36b") if _shown > 0.5 else (Color("#ffd24a") if _shown > 0.2 else Color("#ff4d3d"))
		draw_rect(Rect2(Vector2(inner.position.x, inner.end.y - h), Vector2(inner.size.x, h)), fill)
		var mid := body.get_center()
		var ink := Color(0.05, 0.06, 0.08)
		if mode == CarState.EnergyMode.DEPLOY:  # raio piscando: gastando energia
			var k := 0.6 + 0.4 * sin(_t * 8.0)
			var bolt := PackedVector2Array([mid + Vector2(1.5, -8), mid + Vector2(-4, 1), mid + Vector2(-0.5, 1), mid + Vector2(-1.5, 8), mid + Vector2(4, -1), mid + Vector2(0.5, -1)])
			draw_colored_polygon(bolt, Color(1, 1, 1, k) if _shown < 0.35 else Color(ink, k))
		elif mode == CarState.EnergyMode.HARVEST:  # seta subindo: recarregando
			var off := fmod(_t * 10.0, 6.0) - 3.0
			var arrow := PackedVector2Array([mid + Vector2(0, -6 + off), mid + Vector2(4.5, -1 + off), mid + Vector2(-4.5, -1 + off)])
			draw_colored_polygon(arrow, ink)
			draw_line(mid + Vector2(0, -2 + off), mid + Vector2(0, 5 + off), ink, 2.4)
