class_name ChampionCelebration
extends Control
## Animação de campeão (mockups design/mockups/v24-4 e v24-5; decisões de 2026-11-08), na bandeirada da corrida que
## decide o título de pilotos ou de construtores, de qualquer equipe (mais festa quando é a sua):
## 1) pista: luz na cor da equipe, confete caindo e a faixa "X É CAMPEÃO!" (a tela da corrida segue o carro);
## 2) pôster: foto grande (construtores: o carro), "CAMPEÃO MUNDIAL <ano>", coroas dos títulos e os números da temporada.
## Toque pula a fase da pista; CONTINUAR fecha. Emite `done`.

signal done

const TRACK_S := 3.6
const CONFETTI := 110

## data: {kind ("drivers"/"teams"), name, color, season, titles, place, mine, stats: [[rótulo, valor]], driver (dict) ou team (dict),
##        note (texto do pôster)}
var data: Dictionary = {}
var _phase := 0
var _t := 0.0
var _confetti: Array[Dictionary] = []
var _track_layer: Control
var _rng := RandomNumberGenerator.new()


func setup(p_data: Dictionary) -> void:
	data = p_data
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rng.seed = hash(String(data.get("name", "")))
	_build_track()


func _color() -> Color:
	return Color(data.get("color", Color("#ff8000")))


# --- fase 1: pista ------------------------------------------------------------------------------------

func _build_track() -> void:
	_phase = 1
	_track_layer = Control.new()
	_track_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_track_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_track_layer)
	var tint := ColorRect.new()  # a luz da pista ganha a cor da equipe
	tint.color = Color(_color(), 0.0)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_track_layer.add_child(tint)
	create_tween().tween_property(tint, "color:a", 0.28 if data.get("mine", false) else 0.2, 0.6)
	var band := PanelContainer.new()
	var st := UiStyle.g_box(Color(_color(), 0.92), 0, 0, 18)
	band.add_theme_stylebox_override("panel", st)
	band.set_anchors_and_offsets_preset(Control.PRESET_HCENTER_WIDE)
	band.offset_top = -100
	band.offset_bottom = 100
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ink := UiStyle.contrast_text(_color())
	var place := UiStyle.g_label(String(data.get("place", "")).to_upper(), 20, ink, "black")
	place.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(place)
	var big := UiStyle.g_label(headline(), 64, ink, "black")
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(big)
	var sub := UiStyle.g_label(("Campeão mundial de pilotos %d" if data.get("kind", "drivers") == "drivers" else "Campeã mundial de construtores %d") % int(data.get("season", 2026)), 20, ink, "black")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	band.add_child(v)
	_track_layer.add_child(band)
	band.scale = Vector2(1, 0)
	band.pivot_offset = Vector2(640, 100)
	create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(band, "scale", Vector2.ONE, 0.5).set_delay(0.3)
	for i in CONFETTI:
		var c := ColorRect.new()
		c.size = Vector2(_rng.randf_range(7, 12), _rng.randf_range(12, 18))
		c.color = [_color(), Color.WHITE, UiStyle.G_DIRECTOR, _color().darkened(0.4)][i % 4]
		c.position = Vector2(_rng.randf_range(0, 1280), _rng.randf_range(-720, -10))
		c.rotation = _rng.randf_range(0, TAU)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_track_layer.add_child(c)
		_confetti.append({"n": c, "v": _rng.randf_range(140, 300), "w": _rng.randf_range(-3, 3), "x": _rng.randf_range(-40, 40)})


## "NORRIS É CAMPEÃO!" (bicampeão, tricampeão...) ou "MCLAREN É CAMPEÃ!".
func headline() -> String:
	var name := String(data.get("name", ""))
	if data.get("kind", "drivers") == "teams":
		return "%s É CAMPEÃ!" % name.to_upper()
	var last := name.get_slice(" ", name.get_slice_count(" ") - 1).to_upper()
	var n := int(data.get("titles", 1))
	var word: String = {2: "BICAMPEÃO", 3: "TRICAMPEÃO", 4: "TETRACAMPEÃO", 5: "PENTACAMPEÃO", 6: "HEXACAMPEÃO", 7: "HEPTACAMPEÃO", 8: "OCTACAMPEÃO"}.get(n, "CAMPEÃO")
	return "%s É %s!" % [last, word]


func _process(delta: float) -> void:
	_t += minf(delta, 0.1)  # um travamento de quadro não pula a fase da pista
	for c: Dictionary in _confetti:
		var n: ColorRect = c["n"]
		if not is_instance_valid(n):
			continue
		n.position += Vector2(float(c["x"]) * delta, float(c["v"]) * delta)
		n.rotation += float(c["w"]) * delta
		if n.position.y > 740:
			n.position.y = -20
	if _phase == 1 and _t >= TRACK_S:
		_show_poster()


func _gui_input(event: InputEvent) -> void:
	if _phase == 1 and event is InputEventMouseButton and event.pressed:
		_show_poster()
		accept_event()


# --- fase 2: pôster ----------------------------------------------------------------------------------

func _show_poster() -> void:
	if _phase == 2:
		return
	_phase = 2
	var col := _color()
	var poster := Control.new()
	poster.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	poster.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(poster)
	var bg := _Diagonal.new()
	bg.color = col
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	poster.add_child(bg)
	var big1 := UiStyle.g_label("1", 600, Color(1, 1, 1, 0.05), "black")
	big1.position = Vector2(620, -150)
	poster.add_child(big1)
	var pic := Panel.new()  # foto grande (construtores: o carro)
	pic.position = Vector2(40, 40)
	pic.size = Vector2(520, 640)
	pic.clip_contents = true
	pic.add_theme_stylebox_override("panel", UiStyle.g_box(col.lightened(0.15), 30, 0, 0))
	poster.add_child(pic)
	var tex: Texture2D = null
	if data.get("kind", "drivers") == "drivers":
		tex = DriverPhotos.portrait_texture(String((data.get("driver", {}) as Dictionary).get("id", "")))
	else:
		tex = CarArt.car_texture(data.get("team", {}))
	if tex != null:
		var img := TextureRect.new()
		img.texture = tex
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if data.get("kind", "drivers") == "drivers" else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pic.add_child(img)
	else:
		var ini := UiStyle.g_label(DriverPhotos.initials(String(data.get("name", ""))), 160, UiStyle.contrast_text(col), "black")
		ini.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pic.add_child(ini)
	var v := VBoxContainer.new()
	v.position = Vector2(640, 70)
	v.size = Vector2(600, 600)
	v.add_theme_constant_override("separation", 10)
	poster.add_child(v)
	var cap := UiStyle.g_label(("CAMPEÃO MUNDIAL %d" if data.get("kind", "drivers") == "drivers" else "CAMPEÃ DE CONSTRUTORES %d") % int(data.get("season", 2026)), 22, UiStyle.G_TEXT, "black")
	cap.add_theme_color_override("font_shadow_color", col)
	cap.add_theme_constant_override("shadow_offset_y", 2)
	v.add_child(cap)
	var parts := String(data.get("name", "")).split(" ", false)
	var title := "\n".join(parts).to_upper() if data.get("kind", "drivers") == "drivers" and parts.size() <= 3 else String(data.get("name", "")).to_upper()
	var nm := UiStyle.g_label(title, 56, UiStyle.G_TEXT, "black")
	nm.add_theme_constant_override("line_spacing", -14)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(nm)
	var crowns := HBoxContainer.new()
	crowns.add_theme_constant_override("separation", 8)
	for i in clampi(int(data.get("titles", 1)), 1, 10):
		crowns.add_child(ScreenKit.icon("crown", 30, UiStyle.G_DIRECTOR))
	var team_txt := String(data.get("team_name", "")) if data.get("kind", "drivers") == "drivers" else ""
	var tl := UiStyle.g_label("%dº título%s" % [int(data.get("titles", 1)), " · " + team_txt if team_txt != "" else ""], 18, Color("#c3c9d3"), "black")
	tl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	crowns.add_child(tl)
	v.add_child(crowns)
	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 10)
	for s: Array in data.get("stats", []):
		var b := PanelContainer.new()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.07), 16, 12, 10))
		var bv := VBoxContainer.new()
		bv.add_theme_constant_override("separation", -2)
		bv.add_child(UiStyle.g_label(str(s[1]), 32, UiStyle.G_TEXT, "black"))
		bv.add_child(UiStyle.g_caption(String(s[0])))
		b.add_child(bv)
		grid.add_child(b)
	v.add_child(grid)
	var note := UiStyle.g_label(String(data.get("note", "")), UiStyle.FS_BODY, Color("#c3c9d3"), "bold")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(580, 0)
	v.add_child(note)
	var go := CutButton.new()
	go.text = "CONTINUAR"
	go.custom_minimum_size = Vector2(260, UiStyle.TOUCH_MAIN)
	go.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	go.pressed.connect(_finish)
	v.add_child(go)
	poster.modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(poster, "modulate:a", 1.0, 0.35)
	if _track_layer != null:
		tw.parallel().tween_property(_track_layer, "modulate:a", 0.0, 0.35)
	pic.position.x = -560
	create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).tween_property(pic, "position:x", 40.0, 0.5)


func _finish() -> void:
	done.emit()
	queue_free()


## Fundo do pôster: faixa diagonal na cor da equipe à esquerda, escuro à direita.
class _Diagonal:
	extends Control
	var color := Color("#ff8000")

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), UiStyle.G_BG)
		draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(size.x * 0.58, 0), Vector2(size.x * 0.32, size.y), Vector2(0, size.y)]), color)
