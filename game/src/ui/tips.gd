class_name Tips
extends RefCounted
## Dica de primeira vez (mockup v32-3): um aviso curto na primeira vez que a tela abre; "ENTENDI" fecha e
## "NÃO MOSTRAR MAIS" desliga todas as dicas (Configurações). Textos em data/help.json.


static func text_for(key: String) -> String:
	var d: Dictionary = GameData.load_json(GameData.DATA_DIR + "help.json").get("tips", {})
	return String(d.get(key, ""))


## Mostra a dica `key` sobre `screen`, uma única vez. Não faz nada com as dicas desligadas.
static func show_once(screen: Control, key: String) -> void:
	if not Settings.tips_on or Settings.tip_seen(key) or not is_instance_valid(screen):
		return
	var text := text_for(key)
	if text == "":
		return
	Settings.mark_tip(key)
	var panel := PanelContainer.new()
	var st := UiStyle.g_box(Color(0.043, 0.051, 0.071, 0.94), 20, 18, 14)
	st.set_border_width_all(2)
	st.border_color = Color("#F5C542")
	st.shadow_color = Color(0, 0, 0, 0.5)
	st.shadow_size = 16
	panel.add_theme_stylebox_override("panel", st)
	panel.custom_minimum_size = Vector2(460, 0)
	panel.z_index = 80
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", UiStyle.g_box(Color("#F5C542"), 14, 10, 3))
	var ch := HBoxContainer.new()
	ch.add_theme_constant_override("separation", 6)
	ch.add_child(ScreenKit.icon("bell", 14, UiStyle.G_INK))
	ch.add_child(UiStyle.g_label("Dica", 12, UiStyle.G_INK, "black"))
	chip.add_child(ch)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(chip)
	var l := UiStyle.g_label(text, 16, UiStyle.G_TEXT, "black")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var off := Button.new()
	off.text = "Não mostrar mais"
	off.flat = true
	off.focus_mode = Control.FOCUS_NONE
	off.add_theme_font_size_override("font_size", UiStyle.fs(12))
	off.add_theme_color_override("font_color", UiStyle.G_TEXT_3)
	off.pressed.connect(func() -> void:
		Settings.tips_on = false
		Settings.save_all()
		panel.queue_free())
	row.add_child(off)
	row.add_child(UiStyle.hspacer())
	var ok := ScreenKit.light_button("Entendi")
	ok.custom_minimum_size = Vector2(130, UiStyle.TOUCH_MIN)
	ok.pressed.connect(panel.queue_free)
	row.add_child(ok)
	v.add_child(row)
	screen.add_child(panel)
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.position = Vector2(0, 0)
	panel.offset_left = -230
	panel.offset_right = 230
	panel.offset_top = 96
	panel.offset_bottom = 96
