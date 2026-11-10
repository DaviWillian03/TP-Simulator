extends Control
## Abertura (mockup v32-5): logo no escuro com uma barra de carregamento curta e depois o menu. Pula sozinha nas capturas
## e opções de desenvolvimento (elas já escolhem a cena).

func _ready() -> void:
	if Session.dev_flags:  # capturas: se nenhuma opção trocou a cena, vai direto ao menu (sem abertura)
		var tree := get_tree()
		await tree.process_frame
		await tree.process_frame
		if is_instance_valid(self) and is_inside_tree() and tree.current_scene == self:
			Session.go_to_title()
		return
	var bg := ColorRect.new()
	bg.color = Color("#07090c")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var logo := TextureRect.new()
	logo.texture = load("res://assets/branding/logo.svg")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(620, 220)
	logo.size = Vector2(620, 220)
	add_child(logo)
	logo.set_anchors_preset(Control.PRESET_CENTER)
	logo.offset_left = -310
	logo.offset_right = 310
	logo.offset_top = -190
	logo.offset_bottom = 30
	var cap := UiStyle.g_caption("Temporada 2026")
	cap.set_anchors_preset(Control.PRESET_CENTER)
	cap.position = Vector2(0, 0)
	cap.offset_left = -70
	cap.offset_top = 60
	add_child(cap)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(260, 6)
	bar.add_theme_stylebox_override("background", UiStyle.g_box(Color(1, 1, 1, 0.12), 3, 0, 0))
	bar.add_theme_stylebox_override("fill", UiStyle.g_box(UiStyle.RED, 3, 0, 0))
	add_child(bar)
	bar.set_anchors_preset(Control.PRESET_CENTER)
	bar.offset_left = -130
	bar.offset_right = 130
	bar.offset_top = 110
	bar.offset_bottom = 116
	modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.35)
	tw.parallel().tween_property(bar, "value", 100.0, 1.3)
	tw.tween_interval(0.25)
	tw.tween_callback(Session.go_to_title)
