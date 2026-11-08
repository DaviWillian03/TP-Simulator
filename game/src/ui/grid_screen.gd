extends Control
## Grid de largada como na TV (mockup design/mockups/v22-4-grid-largada.html; decisões de 2026-11-08): uma fila por vez,
## da última até a primeira, com os dois pilotos — foto grande, posição, número, nome, equipe e a melhor volta da
## classificação (quando houve). ~1,5 s por fila; PULAR vai direto para a largada. Corrida e sprint.

const ROW_S := 1.5
const FRONT_HOLD_S := 2.2  ## a primeira fila fica um pouco mais na tela
const CARD := Vector2(500, 440)
const SLOTS := [Vector2(110, 150), Vector2(670, 210)]  ## carro da esquerda (posição ímpar) um pouco à frente

var weekend: WeekendSim
var sim: RaceSim
var order: Array[CarState] = []
var rows := 0
var row := -1  ## fila mostrada agora (0 = primeira fila)
var _timer := 0.0
var _title: Label
var _dots: HBoxContainer
var _cards: Array[Control] = []
var _layer: Control
var _done := false


func _ready() -> void:
	weekend = Session.weekend
	if weekend == null:
		Session.go_to_title.call_deferred()
		return
	sim = weekend.make_race()
	order.assign(sim.cars.duplicate())
	order.sort_custom(func(a: CarState, b: CarState) -> bool: return a.grid_position < b.grid_position)
	rows = ceili(order.size() / 2.0)
	var page := ScreenKit.garage_page(self, weekend.player_team)
	var bd: GarageBackdrop = page["backdrop"]
	bd.floor_ratio = 1.0
	bd.show_lamps = false
	bd.cone_x = -1.0
	bd.set_glow(Color("#24304a"), 0.3)
	_layer = page["layer"]
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 30)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -2)
	var kind := "Sprint" if sim.sprint else "Grid de largada"
	titles.add_child(UiStyle.g_caption("%s · %s" % [String(weekend.circuit["grand_prix"]), kind]))
	_title = UiStyle.g_label("", 30, UiStyle.G_TEXT, "black")
	titles.add_child(_title)
	head.add_child(titles)
	_dots = HBoxContainer.new()
	_dots.add_theme_constant_override("separation", 6)
	_dots.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for i in rows:
		var d := ColorRect.new()
		d.custom_minimum_size = Vector2(22, 8)
		d.color = Color(1, 1, 1, 0.12)
		_dots.add_child(d)
	head.add_child(_dots)
	ScreenKit.place(head, _layer, Control.PRESET_TOP_LEFT, Vector2(44, 22))
	var skip := ScreenKit.light_button("PULAR")
	skip.custom_minimum_size = Vector2(120, UiStyle.TOUCH_MIN + 4)
	skip.pressed.connect(_finish)
	ScreenKit.place(skip, _layer, Control.PRESET_TOP_RIGHT, Vector2(-44, 22))
	# (capturas) --advance=<s> pula as filas que já teriam passado
	_show_row(clampi(rows - 1 - int(Session.debug_advance_s / ROW_S), 0, rows - 1))


func _process(delta: float) -> void:
	if _done or row < 0:
		return
	_timer += delta
	var hold := FRONT_HOLD_S if row == 0 else ROW_S
	if _timer >= hold:
		if row == 0:
			_finish()
		else:
			_show_row(row - 1)


## Mostra a fila r (0 = primeira): os dois cartões entram deslizando.
func _show_row(r: int) -> void:
	row = r
	_timer = 0.0
	_title.text = "FILA %d" % (r + 1) if r > 0 else "PRIMEIRA FILA"
	for i in _dots.get_child_count():
		var fila := rows - 1 - i  # da esquerda para a direita: última fila → primeira
		(_dots.get_child(i) as ColorRect).color = UiStyle.RED if fila == r else (Color(1, 1, 1, 0.45) if fila > r else Color(1, 1, 1, 0.12))
	for c in _cards:
		c.queue_free()
	_cards.clear()
	for k in 2:
		var idx := r * 2 + k
		if idx >= order.size():
			continue
		var card := _card(order[idx], idx + 1)
		_layer.add_child(card)
		card.position = SLOTS[k] + Vector2(60, 0)
		card.modulate = Color(1, 1, 1, 0)
		var tw := card.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(card, "position", SLOTS[k], 0.35).set_delay(0.12 * k)
		tw.tween_property(card, "modulate:a", 1.0, 0.3).set_delay(0.12 * k)
		_cards.append(card)


func _card(car: CarState, pos: int) -> Control:
	var d: Dictionary = car.driver
	var tc := UiStyle.team_color(String(car.team["id"]))
	var card := Panel.new()
	card.size = CARD
	card.clip_contents = true
	var st := UiStyle.g_box(UiStyle.G_GLASS, 26, 0, 0)
	st.border_width_bottom = 8
	st.border_color = tc
	card.add_theme_stylebox_override("panel", st)
	var face := Panel.new()  # retrato grande sobre a cor da equipe
	face.position = Vector2.ZERO
	face.size = Vector2(250, CARD.y - 8)
	face.clip_contents = true
	var fst := UiStyle.g_box(tc, 26, 0, 0)
	fst.corner_radius_top_right = 0
	fst.corner_radius_bottom_right = 0
	face.add_theme_stylebox_override("panel", fst)
	card.add_child(face)
	var tex := DriverPhotos.portrait_texture(String(d["id"]))
	if tex != null:
		var img := TextureRect.new()
		img.texture = tex
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		face.add_child(img)
	else:
		var ini := UiStyle.g_label(DriverPhotos.initials(String(d["name"])), 80, UiStyle.contrast_text(tc), "black")
		ini.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		face.add_child(ini)
	var p := UiStyle.g_label("P%d" % pos, 44, UiStyle.G_TEXT, "black")
	p.position = Vector2(18, 10)
	p.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	p.add_theme_constant_override("shadow_offset_y", 2)
	card.add_child(p)
	var v := VBoxContainer.new()
	v.position = Vector2(270, 26)
	v.size = Vector2(CARD.x - 290, CARD.y - 40)
	v.add_theme_constant_override("separation", 4)
	card.add_child(v)
	v.add_child(UiStyle.g_label(str(int(d["number"])), 64, tc.lightened(0.15), "black"))
	var parts := String(d["name"]).split(" ", false)
	var first := " ".join(parts.slice(0, parts.size() - 1)) if parts.size() > 1 else ""
	if first != "":
		v.add_child(UiStyle.g_label(first, 24, UiStyle.G_TEXT, "bold"))
	var last := UiStyle.g_label(String(parts[parts.size() - 1]).to_upper(), 34, UiStyle.G_TEXT, "black")
	last.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(last)
	var team := HBoxContainer.new()
	team.add_theme_constant_override("separation", 8)
	var stripe := ColorRect.new()
	stripe.color = tc
	stripe.custom_minimum_size = Vector2(6, 22)
	team.add_child(stripe)
	team.add_child(UiStyle.g_label(String(car.team.get("name", "")), UiStyle.FS_BODY, Color("#c3c9d3"), "black"))
	v.add_child(team)
	var qt: Dictionary = weekend.quali_times.get("sprint" if sim.sprint else "race", {}).get(d["id"], {})
	if not qt.is_empty():  # sem classificação (só a corrida): não mostra nada no lugar (decisão do usuário)
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 24)
		v.add_child(gap)
		var tr := HBoxContainer.new()
		tr.add_theme_constant_override("separation", 6)
		tr.add_child(ScreenKit.icon("clock", 20, Color("#c3c9d3")))
		tr.add_child(UiStyle.g_label(UiStyle.format_time(float(qt["time"])), 22, UiStyle.G_TEXT, "black"))
		v.add_child(tr)
		v.add_child(UiStyle.g_label("melhor volta · %s" % String(qt["part"]), UiStyle.FS_CAPTION, UiStyle.G_TEXT_3, "bold"))
	return card


func _finish() -> void:
	if _done:
		return
	_done = true
	Session.start_race_from_grid(sim)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_finish()
