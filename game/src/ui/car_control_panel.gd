class_name CarControlPanel
extends PanelContainer
## Cartão de um carro do jogador — compacto e vertical, na coluna da esquerda (mockup v14):
## foto com o logo da equipe ao lado (não por cima), sobrenome, posição, pneu com a barra de vida,
## ritmo com um velocímetro (o ponteiro sobe ao atacar e desce ao poupar), energia com o ícone da
## bateria mostrando a carga (raio quando gasta, seta quando recarrega), ordens de equipe e box.
## Tocar no cartão (fora dos botões) leva a câmera da pista para esse piloto, como a linha da torre.

signal pit_pressed(car: CarState)
signal focus_pressed(car: CarState)
signal mission_pressed(car: CarState)
signal car_pressed(car: CarState)

const WIDTH := 236.0
const PHOTO := 46

var sim: RaceSim
var car: CarState

var _pos_label: Label
var _sub_label: Label
var _num_label: Label
var _tyre_badge: TyreBadge
var _diagram: CarDiagram
var _loss_label: Label
var _car_block: PanelContainer
var _drs_box: PanelContainer
var _drs_icon: TextureRect
var _drs_title: Label
var _drs_sub: Label
var _life_bar: StandingsPanel.LifeBar
var _life_label: Label
var _battery: BatteryIcon
var _kers: KersDrsBar  ## 2012: barra do KERS (esvazia a cada uso) + DRS (verde com a asa aberta), no lugar da bateria
var _gauge: GaugeIcon
var _logo: TextureRect
var _style: StyleBoxFlat
var _last_pos := 0
var _box_btn: Button
var _last_position := 0
var _auto_label: Label
var _base_box: Dictionary
var _short_box: Dictionary
var _mission_btn: Button
var _car_btn: Button
## Cores da equipe no cartão (pedido do usuário: nada de cinza com vermelho/branco em tudo).
var _accent: Color  ## botões cheios
var _hi: Color  ## textos e realces sobre o vidro escuro


func setup(p_sim: RaceSim, p_car: CarState) -> void:
	sim = p_sim
	car = p_car
	custom_minimum_size.x = WIDTH
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "Tocar para seguir este piloto na pista"
	_accent = UiStyle.team_accent(car.team)
	_hi = _accent if _accent.get_luminance() > 0.3 else _accent.lightened(0.35)
	_style = UiStyle.g_box(UiStyle.team_glass(_accent), 20, 12, 10)
	_style.border_width_left = 5  # faixa na cor da equipe
	_style.border_color = _accent
	_style.content_margin_left = 14
	add_theme_stylebox_override("panel", _style)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
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
	names.add_child(NameFlag.make(full.get_slice(" ", full.get_slice_count(" ") - 1), String(car.driver.get("nationality", "")), 18))
	var pos_row := HBoxContainer.new()  # logo da equipe ao lado da foto, depois a posição e o número
	pos_row.add_theme_constant_override("separation", 6)
	pos_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo = TeamEmblems.make_rect(String(car.team["id"]), 22)
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pos_row.add_child(_logo)
	_pos_label = UiStyle.g_label("P–", 17, _hi, "black")
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

	# missões (2026-11-09, mockup v25): o piloto dosa ritmo e bateria; o cartão mostra os dois só como informação
	var auto_row := HBoxContainer.new()
	auto_row.add_theme_constant_override("separation", 6)
	auto_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gauge = GaugeIcon.new()
	_gauge.custom_minimum_size = Vector2(22, 22)
	_gauge.tooltip_text = "Ritmo (o piloto decide)"
	auto_row.add_child(_gauge)
	_battery = BatteryIcon.new()
	_battery.custom_minimum_size = Vector2(22, 22)
	_battery.tooltip_text = "Bateria (o piloto decide)"
	_battery.visible = sim.energy_k > 0.0
	auto_row.add_child(_battery)
	_auto_label = UiStyle.g_label("", 12, UiStyle.G_TEXT_3, "bold")
	_auto_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_auto_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_auto_label.clip_text = true
	auto_row.add_child(_auto_label)
	_base_box = _mission_box(false)
	v.add_child(_base_box["root"])
	# ritmo e bateria (o piloto decide) viram ícones na linha da missão de base: uma linha a menos no cartão
	if sim.kers:
		_kers = KersDrsBar.new()
		_kers.custom_minimum_size = Vector2(80, 22)
		_kers.tooltip_text = "KERS da volta (o piloto decide) · DRS"
		auto_row.add_child(_kers)
	for ic: Control in [_gauge, _battery] + ([_kers] if _kers != null else []):
		auto_row.remove_child(ic)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		(_base_box["head"] as HBoxContainer).add_child(ic)
	_auto_label.visible = false
	_short_box = _mission_box(true)
	v.add_child(_short_box["root"])

	# carro (mockup v33): mini-carro com ! nas peças com problema, pneu (barra e %) e o que o dano custa por volta
	_car_block = PanelContainer.new()
	_car_block.mouse_filter = Control.MOUSE_FILTER_STOP
	_car_block.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_car_block.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_SURFACE, 14, 8, 6))
	_car_block.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			car_pressed.emit(car)
			accept_event())
	var cb := HBoxContainer.new()
	cb.add_theme_constant_override("separation", 10)
	cb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_diagram = CarDiagram.new()
	_diagram.custom_minimum_size = Vector2(62, 88)
	_diagram.setup(car, 27.0)
	cb.add_child(_diagram)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 6)
	cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tyre := HBoxContainer.new()
	tyre.add_theme_constant_override("separation", 6)
	tyre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tyre_badge = TyreBadge.new()
	_tyre_badge.custom_minimum_size = Vector2(24, 24)
	_tyre_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tyre.add_child(_tyre_badge)
	_life_bar = StandingsPanel.LifeBar.new()
	_life_bar.custom_minimum_size = Vector2(0, 16)
	_life_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_life_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tyre.add_child(_life_bar)
	_life_label = UiStyle.g_label("", 13, UiStyle.G_TEXT, "black")
	_life_label.custom_minimum_size = Vector2(38, 0)
	_life_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tyre.add_child(_life_label)
	cv.add_child(tyre)
	_loss_label = UiStyle.g_label("", 13, UiStyle.G_BAD, "black")
	_loss_label.visible = false
	cv.add_child(_loss_label)
	cb.add_child(cv)
	_car_block.add_child(cb)
	v.add_child(_car_block)

	# ações (2026-11-10): símbolos no lugar de "MISSÃO" e "P/ BOX"; embaixo, as ordens de equipe sempre à mostra
	var pit := HBoxContainer.new()
	pit.add_theme_constant_override("separation", 6)
	_mission_btn = Button.new()
	_mission_btn.focus_mode = Control.FOCUS_NONE
	_mission_btn.tooltip_text = "Missões do piloto"
	_mission_btn.custom_minimum_size = Vector2(0, 44)
	_mission_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mission_btn.icon = load("res://assets/icons/target.svg")
	_mission_btn.expand_icon = false
	_mission_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mission_btn.add_theme_constant_override("icon_max_width", 26)
	for k: String in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color", "icon_focus_color"]:
		_mission_btn.add_theme_color_override(k, Color.WHITE)
	_mission_btn.add_theme_color_override("icon_disabled_color", UiStyle.G_TEXT_OFF)
	for st: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		_mission_btn.add_theme_stylebox_override(st, UiStyle.g_box(UiStyle.G_OFF if st == "disabled" else Color(_accent, 0.30 if st in ["normal", "hover"] else 0.45), 12, 4, 0))
	_mission_btn.pressed.connect(func() -> void: mission_pressed.emit(car))
	ScreenKit.press_feedback(_mission_btn)
	pit.add_child(_mission_btn)
	_car_btn = Button.new()
	_car_btn.focus_mode = Control.FOCUS_NONE
	_car_btn.custom_minimum_size = Vector2(0, 44)
	_car_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_car_btn.icon = load("res://assets/icons/car.svg")
	_car_btn.expand_icon = false
	_car_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_car_btn.add_theme_constant_override("icon_max_width", 26)
	for k: String in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color", "icon_focus_color"]:
		_car_btn.add_theme_color_override(k, Color.WHITE)
	for st: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		_car_btn.add_theme_stylebox_override(st, UiStyle.g_box(UiStyle.G_OFF if st == "disabled" else Color(1, 1, 1, 0.10 if st in ["normal", "hover"] else 0.18), 12, 4, 0))
	_car_btn.pressed.connect(func() -> void: car_pressed.emit(car))
	ScreenKit.press_feedback(_car_btn)
	pit.add_child(_car_btn)
	_box_btn = CutButton.new()
	_box_btn.tooltip_text = "Chamar para o box"
	_box_btn.fill_color = _accent
	for k: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color"]:
		_box_btn.add_theme_color_override(k, UiStyle.ink_on(_accent))
	_box_btn.icon = load("res://assets/icons/wrench.svg")  # box = mecânicos
	_box_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box_btn.custom_minimum_size = Vector2(0, 44)
	_box_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_box_btn.clip_text = true
	for st: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:  # margens menores: o botão é estreito
		var e := StyleBoxEmpty.new()
		e.content_margin_left = 8
		e.content_margin_right = 4
		_box_btn.add_theme_stylebox_override(st, e)
	_box_btn.add_theme_constant_override("icon_max_width", 24)
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
	_style.bg_color = UiStyle.team_glass(_accent, 0.9 if on else 0.78)


## Toque no cartão (fora dos botões): segue esse piloto na pista.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		focus_pressed.emit(car)
		accept_event()


## Caixa de missão (base ou curta): título, situação e barra de andamento.
func _mission_box(short: bool) -> Dictionary:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := UiStyle.g_box(Color(_hi, 0.16) if short else Color(_hi, 0.08), 12, 8, 4)
	if short:
		st.set_border_width_all(1)
		st.border_color = Color(_hi, 0.5)
	p.add_theme_stylebox_override("panel", st)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	# compacto (2026-11-10): rótulo curto ao lado do título e situação em uma linha, para os dois cartões caberem na tela
	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", 6)
	th.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cap := UiStyle.g_label("Curta" if short else "Base", 10, _hi if short else UiStyle.G_TEXT_3, "bold")  # sem espaçamento largo: sobra lugar para o título
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cap.visible = false  # só o nome da missão (pedido de 2026-11-10: sem "base"/"curta")
	th.add_child(cap)
	var title := UiStyle.g_label("", 12, UiStyle.G_TEXT, "black")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	th.add_child(title)
	v.add_child(th)
	var sub := UiStyle.g_label("", 12, UiStyle.G_TEXT_2, "bold")
	sub.custom_minimum_size = Vector2(150, 0)
	sub.clip_text = true
	sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	sub.visible = false  # a situação ("o piloto decide o ritmo"…) fica só na dica do cartão
	v.add_child(sub)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = 1.0
	bar.custom_minimum_size = Vector2(0, 5)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", UiStyle.g_box(Color(1, 1, 1, 0.12), 3, 0, 0))
	v.add_child(bar)
	return {"root": p, "title": title, "sub": sub, "bar": bar, "short": short, "head": th}


func _paint_mission(box: Dictionary, m: Dictionary) -> void:
	var root: Control = box["root"]
	root.visible = not m.is_empty()
	if m.is_empty():
		return
	var stt := Missions.status(sim, car, m)
	(box["title"] as Label).text = Missions.title(m)
	(box["sub"] as Label).text = String(stt["text"])
	root.tooltip_text = String(stt["text"])
	var bar: ProgressBar = box["bar"]
	bar.value = float(stt["progress"])
	var col: Color = _hi if box["short"] else (UiStyle.G_UP if bool(stt["ok"]) else UiStyle.G_DOWN)
	bar.add_theme_stylebox_override("fill", UiStyle.g_box(col, 3, 0, 0))


func refresh(race_position: int) -> void:
	_last_position = race_position
	_pos_label.text = "P%d" % race_position
	_num_label.text = "#%d" % int(car.driver["number"])
	_sub_label.text = _gaps_text(race_position)
	var c: Dictionary = sim.tyres.compounds[car.tyre]
	_tyre_badge.set_compound(c["letter"], Color(c["color"]))
	_tyre_badge.tooltip_text = "%s · %dv" % [c["name"], car.tyre_laps]
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
	if _kers != null:
		_kers.set_state(car.kers, car.kers_on, sim.drs_open(car))
	_gauge.mode = car.pace_mode
	if _last_pos != 0 and race_position != _last_pos:  # mudou de posição: o número pulsa (verde ganhou, vermelho perdeu)
		var gained := race_position < _last_pos
		_pos_label.add_theme_color_override("font_color", Color("#39d36b") if gained else Color("#ff4d3d"))
		var tw := _pos_label.create_tween()
		tw.tween_property(_pos_label, "scale", Vector2(1.35, 1.35), 0.12)
		tw.tween_property(_pos_label, "scale", Vector2.ONE, 0.25)
		tw.tween_interval(1.2)
		tw.tween_callback(func() -> void: _pos_label.add_theme_color_override("font_color", _hi))
	_last_pos = race_position
	_auto_label.text = "piloto: %s" % ["poupando", "normal", "atacando"][int(car.pace_mode)]
	_gauge.tooltip_text = "Ritmo (o piloto decide): " + ["poupando", "normal", "atacando"][int(car.pace_mode)]
	_paint_mission(_base_box, car.mission_base if not car.mission_base.is_empty() else Missions.base_mission("normal"))
	var short: Dictionary = car.mission_short if not car.mission_short.is_empty() and car.laps_done >= int(car.mission_short.get("start", 0)) else {}
	if not car.mission_short.is_empty() and short.is_empty():  # agendada (o piloto pediu para esperar)
		short = car.mission_short
	_paint_mission(_short_box, short)
	_diagram.refresh()
	var loss := car.damage_loss_s()
	_loss_label.visible = loss > 0.0
	if loss > 0.0:
		_loss_label.text = "−%s s" % String.num(loss, 1).replace(".", ",")
		_loss_label.add_theme_color_override("font_color", UiStyle.G_BAD if loss >= 0.6 else UiStyle.G_WARN)
	var active := not (car.retired or car.finished)
	_mission_btn.disabled = not active
	_car_btn.disabled = not active
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
		return "CONFIRMADO"
	if car.pit_defer_laps >= 0:
		return "BOX VOLTA %d" % (car.pit_defer_laps + 1)
	return ""  # só o símbolo do box


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
## 2012: barra do KERS que esvazia a cada uso (acende enquanto o piloto usa) e o bloco DRS, verde com a asa aberta.
class KersDrsBar:
	extends Control
	var _level := 1.0
	var _on := false
	var _drs := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS

	func set_state(level: float, on: bool, drs: bool) -> void:
		if is_equal_approx(level, _level) and on == _on and drs == _drs:
			return
		_level = clampf(level, 0.0, 1.0)
		_on = on
		_drs = drs
		queue_redraw()

	func _draw() -> void:
		var h := size.y
		var bar := Rect2(0, h * 0.3, size.x - 40.0, h * 0.4)
		draw_rect(bar, Color(1, 1, 1, 0.12))
		var fill := Rect2(bar.position, Vector2(bar.size.x * _level, bar.size.y))
		draw_rect(fill, UiStyle.G_DIRECTOR.lightened(0.25) if _on else UiStyle.G_DIRECTOR)
		var chip := Rect2(size.x - 36.0, 0, 36.0, h)
		var sb := StyleBoxFlat.new()
		sb.bg_color = UiStyle.G_UP if _drs else Color(1, 1, 1, 0.10)
		sb.set_corner_radius_all(6)
		draw_style_box(sb, chip)
		var font := UiStyle.G_BLACK
		var fs := UiStyle.fs(11)
		var tw := font.get_string_size("DRS", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, Vector2(chip.position.x + (chip.size.x - tw) / 2.0, h * 0.5 + fs * 0.36), "DRS", HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
			UiStyle.G_INK if _drs else UiStyle.G_TEXT_2)


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
