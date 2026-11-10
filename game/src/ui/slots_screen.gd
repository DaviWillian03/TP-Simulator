class_name SlotsScreen
extends Control
## Escolha de slot de save (mockup v32-4 aprovado): 3 cartões. Slot ocupado continua o que ele guarda (Campanha ou
## Mundial); slot vazio começa o modo que foi tocado no menu (Session.slots_mode); a lixeira apaga o slot.

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
	_build()
	layer.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(layer, "modulate:a", 1.0, 0.15)


func _build() -> void:
	for ch in _stage.get_children():
		ch.queue_free()
	var back := ScreenKit.round_button("back", 48, "Voltar")
	back.pressed.connect(Session.go_to_title)
	back.position = Vector2(18, 14)
	_stage.add_child(back)
	var t := UiStyle.g_label("Escolha um slot", 34, UiStyle.G_TEXT, "black")
	t.position = Vector2(80, 14)
	_stage.add_child(t)
	for s in range(1, SaveSlots.SLOTS + 1):
		_stage.add_child(_slot_card(s, Rect2(40 + (s - 1) * 400, 130, 360, 420)))


func _slot_card(slot: int, r: Rect2) -> Control:
	var sm := SaveSlots.summary(slot)
	var kind := String(sm.get("kind", ""))
	var p := Panel.new()
	p.position = r.position
	p.size = r.size
	if kind == "":
		var st := UiStyle.g_box(Color(1, 1, 1, 0.04), 22, 0, 0)
		st.set_border_width_all(2)
		st.border_color = Color(1, 1, 1, 0.18)
		p.add_theme_stylebox_override("panel", st)
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for stn: String in ["normal", "hover", "pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(stn, StyleBoxEmpty.new())
		var v := VBoxContainer.new()
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var plus := PanelContainer.new()
		plus.add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.1), 35, 18, 18))
		plus.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plus.add_child(ScreenKit.icon("plus", 34, UiStyle.G_TEXT))
		v.add_child(plus)
		var l1 := UiStyle.g_label("Slot %d vazio" % slot, 24, UiStyle.G_TEXT, "black")
		l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l1)
		var l2 := UiStyle.g_label("Começar %s" % ("o Mundial F1" if Session.slots_mode == "world" else "uma Campanha"), 14, UiStyle.G_TEXT_2, "bold")
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l2)
		b.add_child(v)
		b.pressed.connect(_start_new.bind(slot))
		ScreenKit.press_feedback(b)
		p.add_child(b)
		return p
	var team := String(sm["team"])
	var col := UiStyle.team_color(team)
	var st2 := UiStyle.g_box(Color("#1b1e26"), 22, 0, 0)
	st2.set_border_width_all(3)
	st2.border_color = col
	p.add_theme_stylebox_override("panel", st2)
	p.add_child(_caption_at("Slot %d" % slot, Vector2(18, 14)))
	var em := TeamEmblems.make_rect(team, 54)
	em.position = Vector2(18, 44)
	p.add_child(em)
	var tt := UiStyle.g_label(String(sm["title"]), 26, UiStyle.G_TEXT, "black")
	tt.position = Vector2(86, 40)
	p.add_child(tt)
	var ll := UiStyle.g_label(String(sm["line"]), 13, UiStyle.G_TEXT_2, "bold")
	ll.position = Vector2(86, 76)
	p.add_child(ll)
	var car := TextureRect.new()
	var cp := "res://assets/cars/%s.svg" % team
	if ResourceLoader.exists(cp):
		car.texture = load(cp)
	car.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	car.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	car.position = Vector2(20, 120)
	car.size = Vector2(320, 110)
	p.add_child(car)
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 8)
	for c: String in sm["chips"]:
		chips.add_child(_chip(c))
	chips.position = Vector2(18, 246)
	p.add_child(chips)
	p.add_child(_caption_at(String(sm["saved"]), Vector2(18, 296), false))
	var go := CutButton.new()
	go.text = "CONTINUAR"
	go.custom_minimum_size = Vector2(r.size.x - 18 - 98, 52)
	go.size = go.custom_minimum_size
	go.position = Vector2(18, r.size.y - 70)
	go.pressed.connect(_continue.bind(slot))
	p.add_child(go)
	var del := ScreenKit.round_button("trash", 52, "Apagar slot")
	del.position = Vector2(r.size.x - 18 - 64, r.size.y - 70)
	del.size = Vector2(64, 52)
	del.pressed.connect(_ask_delete.bind(slot))
	p.add_child(del)
	return p


func _caption_at(text: String, pos: Vector2, caps := true) -> Label:
	var l := UiStyle.g_caption(text) if caps else UiStyle.g_label(text, 12, UiStyle.G_TEXT_3, "bold")
	l.position = pos
	return l


func _chip(text: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.1), 15, 12, 4))
	p.add_child(UiStyle.g_label(text, 14, UiStyle.G_TEXT, "black"))
	return p


func _continue(slot: int) -> void:
	SaveSlots.current = slot
	var sm := SaveSlots.summary(slot)
	if String(sm.get("kind", "")) == "world":
		Session.open_world()
	else:
		var c := Campaign.load_saved()
		if c != null:
			Session.start_campaign(c)


func _start_new(slot: int) -> void:
	SaveSlots.current = slot
	if Session.slots_mode == "world":
		Session.open_team_select("world")
	else:
		Session.open_campaign()


func _ask_delete(slot: int) -> void:
	var sh := ScreenKit.sheet("Apagar o slot %d?" % slot, 560)
	var body: VBoxContainer = sh["body"]
	var l := UiStyle.g_label("O save deste slot será apagado e não dá para desfazer.", 16, UiStyle.G_TEXT_2, "bold")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(l)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var no := ScreenKit.light_button("Cancelar")
	no.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MAIN)
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.pressed.connect((sh["root"] as Control).queue_free)
	row.add_child(no)
	var yes := CutButton.new()
	yes.text = "APAGAR"
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yes.pressed.connect(func() -> void:
		SaveSlots.delete(slot)
		(sh["root"] as Control).queue_free()
		_build())
	row.add_child(yes)
	body.add_child(row)
	add_child(sh["root"])


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.go_to_title()
