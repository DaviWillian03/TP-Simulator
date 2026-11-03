class_name RadioCard
extends PanelContainer
## Cartão do rádio: mostra a pergunta pendente de um piloto do jogador com as opções.
## Não pausa a corrida; sem resposta no prazo, o piloto decide sozinho.

signal answered(message_id: int, option: int)

const WIDTH := 600.0  ## faixa baixa no centro da pista

var _message_id := -1
var _who: Label
var _avatar_holder: HBoxContainer
var _text: Label
var _answers: HBoxContainer
var _deadline: Label


func _ready() -> void:
	var style := UiStyle.g_box(UiStyle.G_LIGHT, 16, 16, 12)
	style.border_width_left = 7
	style.border_color = UiStyle.RED
	add_theme_stylebox_override("panel", style)
	custom_minimum_size = Vector2(WIDTH, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	_avatar_holder = HBoxContainer.new()
	head.add_child(_avatar_holder)
	head.add_child(UiStyle.g_caption("Rádio ·", UiStyle.G_INK_2))
	_who = UiStyle.g_label("", 13, UiStyle.G_INK, "black")
	_who.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_who)
	v.add_child(head)
	_text = UiStyle.g_label("", 16, UiStyle.G_INK, "black")
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(WIDTH - 24.0, 0)
	v.add_child(_text)
	_answers = HBoxContainer.new()
	_answers.add_theme_constant_override("separation", 6)
	v.add_child(_answers)
	_deadline = UiStyle.g_label("", 12, UiStyle.G_INK_2)
	v.add_child(_deadline)
	visible = false


func show_message(m: Dictionary) -> void:
	if m.is_empty():
		visible = false
		_message_id = -1
		return
	if int(m["id"]) == _message_id:
		return
	_message_id = m["id"]
	var car: CarState = m["car"]
	for c in _avatar_holder.get_children():
		c.queue_free()
	_avatar_holder.add_child(DriverPhotos.make_avatar(car.driver, car.team_color(), 34))
	_who.text = StandingsPanel.surname(car.display_name())
	_text.text = "“%s”" % m["text"]
	for c in _answers.get_children():
		c.queue_free()
	for i in m["options"].size():
		var b := Button.new()
		b.text = String(m["options"][i]["label"])
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MIN)
		var first: bool = i == 0
		for state: String in ["normal", "hover", "pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(state, UiStyle.g_box(UiStyle.G_INK if first else Color("#e3e6eb"), 12, 8, 0))
		for k: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(k, Color.WHITE if first else UiStyle.G_INK)
		b.add_theme_font_size_override("font_size", UiStyle.fs(14))
		ScreenKit.press_feedback(b)
		b.pressed.connect(func() -> void: answered.emit(_message_id, i))
		_answers.add_child(b)
	if m.has("deadline_text"):  # classificação: prazo em segundos de sessão, não em voltas
		_deadline.text = String(m["deadline_text"])
	else:
		var left := int(m["expires_lap"]) - car.laps_done
		_deadline.text = "Sem resposta em %d volta%s, o piloto decide sozinho" % [left, "" if left == 1 else "s"]
	visible = true
