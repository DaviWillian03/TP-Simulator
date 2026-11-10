class_name SettingsScreen
extends Control
## Configurações (mockup v32-1 aprovado): som, tamanho da letra, jogo e ajuda/dados. Salvam na hora (Settings).

const W := 1280.0
const H := 720.0

var _stage: Control


func _ready() -> void:
	var page := ScreenKit.garage_page(self, Session.player_team)
	(page["backdrop"] as GarageBackdrop).set_glow(Color("#2a3346"), 0.35)
	var layer: Control = page["layer"]
	_stage = Control.new()
	_stage.set_anchors_preset(Control.PRESET_CENTER)
	_stage.offset_left = -W / 2.0
	_stage.offset_right = W / 2.0
	_stage.offset_top = -H / 2.0
	_stage.offset_bottom = H / 2.0
	layer.add_child(_stage)
	var back := ScreenKit.round_button("back", 48, "Voltar")
	back.pressed.connect(Session.go_to_title)
	back.position = Vector2(18, 14)
	_stage.add_child(back)
	var title := VBoxContainer.new()
	title.add_theme_constant_override("separation", -2)
	title.add_child(UiStyle.g_caption("Opções"))
	title.add_child(UiStyle.g_label("Configurações", 28, UiStyle.G_TEXT, "black"))
	title.position = Vector2(78, 8)
	_stage.add_child(title)
	_left_card()
	_right_card()
	layer.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(layer, "modulate:a", 1.0, 0.15)


func _card(r: Rect2) -> VBoxContainer:
	var p := Panel.new()
	p.position = r.position
	p.size = r.size
	p.add_theme_stylebox_override("panel", UiStyle.g_box(Color("#171a21"), 22, 0, 0))
	_stage.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.position = Vector2(20, 16)
	v.size = Vector2(r.size.x - 40, r.size.y - 32)
	p.add_child(v)
	return v


func _row(parent: Control, title: String, sub: String, ctl: Control, tall := 62) -> HBoxContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.05), 16, 16, 0))
	p.custom_minimum_size = Vector2(0, tall)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", -2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tv.add_child(UiStyle.g_label(title, 16, UiStyle.G_TEXT, "black"))
	if sub != "":
		tv.add_child(UiStyle.g_label(sub, 12, UiStyle.G_TEXT_2, "bold"))
	h.add_child(tv)
	if ctl != null:
		ctl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(ctl)
	p.add_child(h)
	parent.add_child(p)
	return h


func _slider(value: float, on_change: Callable) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 100.0
	s.step = 5.0
	s.value = roundf(value * 100.0)
	s.custom_minimum_size = Vector2(240, 36)
	s.focus_mode = Control.FOCUS_NONE
	s.add_theme_stylebox_override("slider", UiStyle.g_box(Color(1, 1, 1, 0.14), 5, 0, 0))
	s.add_theme_stylebox_override("grabber_area", UiStyle.g_box(Color("#F5C542"), 5, 0, 0))
	s.add_theme_stylebox_override("grabber_area_highlight", UiStyle.g_box(Color("#F5C542"), 5, 0, 0))
	var knob := _circle(24)
	s.add_theme_icon_override("grabber", knob)
	s.add_theme_icon_override("grabber_highlight", knob)
	s.add_theme_constant_override("center_grabber", 1)
	h.add_child(s)
	var pct := UiStyle.g_label("%d%%" % int(s.value), 15, UiStyle.G_TEXT, "black")
	pct.custom_minimum_size = Vector2(46, 0)
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(pct)
	s.value_changed.connect(func(v: float) -> void:
		pct.text = "%d%%" % int(v)
		on_change.call(v / 100.0))
	return h


func _circle(d: int) -> ImageTexture:
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	var c := (d - 1) / 2.0
	for y in d:
		for x in d:
			var dist := Vector2(x - c, y - c).length()
			img.set_pixel(x, y, Color(1, 1, 1, clampf(c + 0.5 - dist, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


func _toggle(on: bool, on_change: Callable) -> Control:
	var t := _Toggle.new()
	t.value = on
	t.changed.connect(on_change)
	return t


func _left_card() -> void:
	var v := _card(Rect2(60, 92, 560, 590))
	v.add_child(UiStyle.g_caption("Som"))
	_row(v, "Volume geral", "", _slider(Settings.master, func(x: float) -> void:
		Settings.master = x
		Settings.apply_audio()
		Settings.save_all()))
	_row(v, "Efeitos", "motores, rádio, pit stop", _slider(Settings.sfx, func(x: float) -> void:
		Settings.sfx = x
		Settings.apply_audio()
		Settings.save_all()))
	_row(v, "Música dos menus", "", _slider(Settings.music, func(x: float) -> void:
		Settings.music = x
		Settings.apply_audio()
		Settings.save_all()))
	_row(v, "Sons de toque", "", _toggle(Settings.touch_sounds, func(x: bool) -> void:
		Settings.touch_sounds = x
		Settings.save_all()))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	v.add_child(gap)
	v.add_child(UiStyle.g_caption("Texto"))
	var seg := ScreenKit.segmented([["small", "Pequena"], ["normal", "Normal"], ["large", "Grande"]], Settings.text_size, func(x: String) -> void:
		Settings.text_size = x
		Settings.save_all()
		get_tree().reload_current_scene.call_deferred())  # recria a tela já com a letra nova
	_row(v, "Tamanho da letra", "", seg)


func _right_card() -> void:
	var v := _card(Rect2(640, 92, 580, 590))
	v.add_child(UiStyle.g_caption("Jogo"))
	var seg := ScreenKit.segmented([[1, "1×"], [2, "2×"], [4, "4×"]], Settings.start_speed, func(x: int) -> void:
		Settings.start_speed = x
		Settings.save_all())
	_row(v, "Velocidade inicial da corrida", "", seg)
	_row(v, "Reduzir a velocidade em decisões", "", _toggle(Settings.slow_on_decisions, func(x: bool) -> void:
		Settings.slow_on_decisions = x
		Session.slow_on_decisions = x
		Settings.save_all()))
	_row(v, "Dicas na primeira vez", "", _toggle(Settings.tips_on, func(x: bool) -> void:
		Settings.tips_on = x
		Settings.save_all()))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	v.add_child(gap)
	v.add_child(UiStyle.g_caption("Ajuda e dados"))
	_link(v, "Ajuda", "", func() -> void: HelpSheet.open(self))
	_link(v, "Ver as dicas de novo", "", func() -> void:
		Settings.reset_tips()
		_toast_done("Dicas reativadas."))
	_link(v, "Saves e slots", "", func() -> void: Session.open_slots(""))
	var ver := UiStyle.g_label("F1 Guidelines · versão %s" % String(ProjectSettings.get_setting("application/config/version", "0.1")), 12, UiStyle.G_TEXT_3, "bold")
	v.add_child(ver)


func _link(parent: Control, title: String, sub: String, on: Callable) -> void:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 54)
	for st: String in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, UiStyle.g_box(Color(1, 1, 1, 0.05 if st == "normal" else 0.1), 16, 16, 0))
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 16
	h.offset_right = -16
	var l := UiStyle.g_label(title, 16, UiStyle.G_TEXT, "black")
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(l)
	h.add_child(UiStyle.hspacer())
	var ic := ScreenKit.icon("chevron", 22, UiStyle.G_TEXT_2)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	b.add_child(h)
	b.pressed.connect(on)
	ScreenKit.press_feedback(b)
	parent.add_child(b)


func _toast_done(text: String) -> void:
	var l := UiStyle.g_label(text, 14, UiStyle.G_UP, "black")
	l.position = Vector2(660, 690)
	_stage.add_child(l)
	create_tween().tween_property(l, "modulate:a", 0.0, 1.6).set_delay(0.8)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.go_to_title()


## Interruptor liga/desliga.
class _Toggle:
	extends Control
	signal changed(on: bool)
	var value := false

	func _init() -> void:
		custom_minimum_size = Vector2(56, 32)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			value = not value
			queue_redraw()
			changed.emit(value)
			accept_event()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, Vector2(56, 32))
		draw_rect(r, Color.TRANSPARENT)
		var st := StyleBoxFlat.new()
		st.bg_color = Color("#2FD38A") if value else Color(1, 1, 1, 0.16)
		st.set_corner_radius_all(16)
		st.anti_aliasing = true
		draw_style_box(st, r)
		draw_circle(Vector2(40 if value else 16, 16), 12, Color.WHITE, true, -1.0, true)
