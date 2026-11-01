class_name RadioCard
extends PanelContainer
## Cartão do rádio: mostra a pergunta pendente de um piloto do jogador com as opções.
## Não pausa a corrida; sem resposta no prazo, o piloto decide sozinho.

signal answered(message_id: int, option: int)

var _message_id := -1
var _who: Label
var _emblem: TextureRect
var _text: Label
var _answers: HBoxContainer
var _deadline: Label


func _ready() -> void:
	var style := UiStyle.box(UiStyle.INK, 12, 10)
	add_theme_stylebox_override("panel", style)
	custom_minimum_size = Vector2(440, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	head.add_child(UiStyle.caption("Rádio ·", UiStyle.PAPER))
	_emblem = TeamEmblems.make_rect("", 18)
	head.add_child(_emblem)
	_who = UiStyle.label("", 14, UiStyle.PAPER, true)
	head.add_child(_who)
	head.add_child(UiStyle.caption("· pergunta", UiStyle.PAPER))
	v.add_child(head)
	_text = UiStyle.label("", 16, UiStyle.PAPER, true)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(416, 0)
	v.add_child(_text)
	_answers = HBoxContainer.new()
	_answers.add_theme_constant_override("separation", 6)
	v.add_child(_answers)
	_deadline = UiStyle.caption("", Color("#b9b0a0"))
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
	_emblem.texture = TeamEmblems.get_texture(car.team["id"])
	_who.text = StandingsPanel.surname(car.display_name())
	_text.text = "“%s”" % m["text"]
	for c in _answers.get_children():
		c.queue_free()
	for i in m["options"].size():
		var b := UiStyle.button(m["options"][i]["label"])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 36)
		UiStyle.compact(b, 13)
		if i == 0:
			UiStyle.accent(b)
		else:
			for state: String in ["normal", "hover"]:
				b.add_theme_stylebox_override(state, UiStyle.outline_box(Color(0, 0, 0, 0), UiStyle.PAPER))
			b.add_theme_color_override("font_color", UiStyle.PAPER)
			b.add_theme_color_override("font_hover_color", UiStyle.PAPER)
		b.pressed.connect(func() -> void: answered.emit(_message_id, i))
		_answers.add_child(b)
	var left := int(m["expires_lap"]) - car.laps_done
	_deadline.text = "Sem resposta em %d volta%s, o piloto decide sozinho" % [left, "" if left == 1 else "s"]
	visible = true
