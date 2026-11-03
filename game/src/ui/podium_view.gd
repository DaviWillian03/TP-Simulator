class_name PodiumView
extends ColorRect
## Pódio animado no fim da corrida: os três primeiros sobem nos degraus (3º, depois 2º, depois o vencedor),
## com a foto de cada um, o logo da equipe e confete nas cores das equipes. Um botão leva ao resultado
## completo. Só apresentação: recebe os carros já na ordem final.

signal done

const STEP_H := [190.0, 140.0, 105.0]  ## altura dos degraus do 1º, 2º e 3º
const STEP_W := 220.0
const PHOTO := [132, 108, 108]
const ORDER := [1, 0, 2]  ## da esquerda para a direita: 2º, 1º, 3º

var _steps: Array[Control] = []
var _tops: Array[Control] = []


func setup(top3: Array[CarState], title: String) -> void:
	color = Color(0.02, 0.025, 0.035, 0.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var head := VBoxContainer.new()
	head.add_theme_constant_override("separation", -2)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cap := UiStyle.g_caption("Pódio")
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(cap)
	var t := UiStyle.g_label(title.to_upper(), 30, UiStyle.G_TEXT, "black")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(t)
	add_child(head)
	head.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	head.offset_top = 40
	head.offset_left = -400
	head.offset_right = 400

	var base_y := 720.0 - 120.0  # chão do pódio
	var x0 := 640.0 - STEP_W * 1.5
	for slot in 3:
		var place: int = ORDER[slot]  # 0 = vencedor
		if place >= top3.size():
			continue
		var car: CarState = top3[place]
		var x := x0 + slot * STEP_W
		# degrau
		var step := PanelContainer.new()
		var sb := UiStyle.g_box(car.team_color().darkened(0.25), 14, 0, 0)
		sb.corner_radius_bottom_left = 0
		sb.corner_radius_bottom_right = 0
		sb.border_width_top = 6
		sb.border_color = car.team_color()
		step.add_theme_stylebox_override("panel", sb)
		step.position = Vector2(x + 6, base_y)
		step.size = Vector2(STEP_W - 12, STEP_H[place])
		step.pivot_offset = Vector2((STEP_W - 12) / 2.0, STEP_H[place])
		step.scale = Vector2(1, 0)
		var num := UiStyle.g_label(str(place + 1), 64 if place == 0 else 52, Color(1, 1, 1, 0.9), "black")
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		step.add_child(num)
		add_child(step)
		step.position.y = base_y - STEP_H[place]
		_steps.append(step)
		# piloto em cima do degrau: foto, logo e nome
		var top := VBoxContainer.new()
		top.alignment = BoxContainer.ALIGNMENT_END
		top.add_theme_constant_override("separation", 6)
		top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var photo_row := CenterContainer.new()
		photo_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var photo := Control.new()
		var ps: int = PHOTO[place]
		photo.custom_minimum_size = Vector2(ps, ps)
		photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		photo.add_child(DriverPhotos.make_avatar(car.driver, car.team_color(), ps))
		var logo := TeamEmblems.make_rect(String(car.team["id"]), 34 if place == 0 else 30)
		photo.add_child(logo)
		logo.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		logo.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		logo.grow_vertical = Control.GROW_DIRECTION_BEGIN
		logo.offset_right = 4
		logo.offset_bottom = 2
		photo_row.add_child(photo)
		top.add_child(photo_row)
		var full := car.display_name()
		var nm := UiStyle.g_label(full.get_slice(" ", full.get_slice_count(" ") - 1).to_upper(), 22 if place == 0 else 19, UiStyle.G_TEXT, "black")
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		top.add_child(nm)
		var tm := UiStyle.g_label(String(car.team["name"]), 13, UiStyle.G_TEXT_2, "bold")
		tm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		top.add_child(tm)
		add_child(top)
		top.position = Vector2(x, 0)
		top.size = Vector2(STEP_W, base_y - STEP_H[place] - 8)
		top.modulate.a = 0.0
		top.pivot_offset = Vector2(STEP_W / 2.0, top.size.y)
		_tops.append(top)

	var go := CutButton.new()
	go.text = "RESULTADO COMPLETO"
	go.custom_minimum_size = Vector2(300, UiStyle.TOUCH_MAIN)
	add_child(go)
	go.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	go.offset_left = -150
	go.offset_right = 150
	go.offset_top = -UiStyle.TOUCH_MAIN - 28
	go.offset_bottom = -28
	go.modulate.a = 0.0
	go.pressed.connect(func() -> void:
		done.emit()
		queue_free())
	_animate(go, top3)


## 3º sobe, depois o 2º, depois o vencedor (degrau cresce, piloto aparece com um "salto"); confete no fim.
func _animate(go: Control, top3: Array[CarState]) -> void:
	var tw := create_tween()
	tw.tween_property(self, "color:a", 0.9, 0.35)
	var reveal := [2, 0, 1]  # índices em _steps/_tops (ordem esquerda→direita = 2º, 1º, 3º): 3º, 2º, 1º
	for i in reveal:
		if i >= _steps.size():
			continue
		var s: Control = _steps[i]
		var t: Control = _tops[i]
		tw.tween_property(s, "scale:y", 1.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func() -> void: t.scale = Vector2(0.6, 0.6))
		tw.parallel().tween_property(t, "modulate:a", 1.0, 0.25)
		tw.parallel().tween_property(t, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.25)
	tw.tween_callback(_confetti.bind(top3))
	tw.tween_property(go, "modulate:a", 1.0, 0.3)


func _confetti(top3: Array[CarState]) -> void:
	var colors: Array[Color] = [Color.WHITE, UiStyle.G_LIGHT]
	for car in top3:
		colors.append(car.team_color())
	for k in colors.size():
		var p := CPUParticles2D.new()
		p.position = Vector2(640, -10)
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = Vector2(640, 4)
		p.amount = 36
		p.lifetime = 3.2
		p.one_shot = true
		p.explosiveness = 0.15
		p.direction = Vector2(0, 1)
		p.spread = 25.0
		p.gravity = Vector2(0, 160)
		p.initial_velocity_min = 60.0
		p.initial_velocity_max = 170.0
		p.angular_velocity_min = -280.0
		p.angular_velocity_max = 280.0
		p.scale_amount_min = 4.0
		p.scale_amount_max = 7.0
		p.color = colors[k]
		add_child(p)
		p.emitting = true
