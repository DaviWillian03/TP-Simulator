extends GutTest
## Letra maior, lista que rola arrastando e zoom da pista (pedidos de jogabilidade no celular).


func test_font_scale_grows_small_text_more_than_titles() -> void:
	assert_eq(UiStyle.fs(12), 14, "texto pequeno cresce 20%")
	assert_eq(UiStyle.fs(16), 19)
	assert_eq(UiStyle.fs(40), 44, "título ganha só o acréscimo fixo")
	assert_true(UiStyle.fs(UiStyle.FS_CAPTION) >= 14, "menor texto passa a 14 px")


func _press(at: Vector2, pressed: bool) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = at
	e.global_position = at
	return e


func _move(at: Vector2) -> InputEventMouseMotion:
	var e := InputEventMouseMotion.new()
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	e.position = at
	e.global_position = at
	return e


func _list() -> Array:
	var sc := DragScroll.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.position = Vector2.ZERO
	sc.size = Vector2(300, 200)
	var v := VBoxContainer.new()
	sc.add_child(v)
	var buttons: Array[Button] = []
	for i in 20:
		var b := Button.new()
		b.text = "linha %d" % i
		b.custom_minimum_size = Vector2(280, 50)
		v.add_child(b)
		buttons.append(b)
	add_child_autofree(sc)
	return [sc, buttons]


func test_drag_scrolls_list_and_blocks_button_press() -> void:
	var made := _list()
	var sc: DragScroll = made[0]
	var buttons: Array[Button] = made[1]
	await wait_process_frames(2)
	var pressed := [false]
	buttons[1].pressed.connect(func() -> void: pressed[0] = true)
	sc._input(_press(Vector2(100, 150), true))
	sc._input(_move(Vector2(100, 120)))
	sc._input(_move(Vector2(100, 40)))
	assert_true(sc.is_dragging(), "passou da zona morta: virou arrasto")
	assert_eq(sc.scroll_vertical, 110, "a lista acompanha o dedo")
	assert_true(buttons[1].disabled, "botões desligados durante o arrasto")
	sc._input(_press(Vector2(100, 40), false))
	await wait_process_frames(2)
	assert_false(buttons[1].disabled, "voltam ao soltar")
	assert_false(pressed[0], "arrastar não aperta o botão")


func test_small_move_is_still_a_tap() -> void:
	var made := _list()
	var sc: DragScroll = made[0]
	await wait_process_frames(2)
	sc._input(_press(Vector2(100, 150), true))
	sc._input(_move(Vector2(104, 146)))
	assert_false(sc.is_dragging(), "movimento pequeno continua sendo toque")
	assert_eq(sc.scroll_vertical, 0)
	sc._input(_press(Vector2(104, 146), false))


func test_drag_outside_list_is_ignored() -> void:
	var made := _list()
	var sc: DragScroll = made[0]
	await wait_process_frames(2)
	sc._input(_press(Vector2(600, 150), true))
	sc._input(_move(Vector2(600, 20)))
	assert_false(sc.is_dragging())
	assert_eq(sc.scroll_vertical, 0)


func test_track_zoom_is_clamped() -> void:
	var tv := TrackView3D.new()
	tv.distance = 1000.0
	tv.zoom_by(0.5)
	assert_almost_eq(tv.distance, 500.0, 0.01)
	for i in 30:
		tv.zoom_by(0.5)
	assert_eq(tv.distance, TrackView3D.ZOOM_MIN, "não atravessa o chão")
	for i in 30:
		tv.zoom_by(2.0)
	assert_eq(tv.distance, TrackView3D.ZOOM_MAX)
	tv.free()
