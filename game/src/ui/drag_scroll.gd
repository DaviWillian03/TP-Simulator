class_name DragScroll
extends ScrollContainer
## Lista que rola arrastando o dedo (ou o mouse), para cima/baixo ou para os lados.
##
## Por que não basta o ScrollContainer do Godot: ele só recebe o arrasto se o toque chegar até
## ele, mas os botões e linhas das nossas listas "seguram" o toque antes (mouse_filter STOP).
## Aqui o arrasto é lido em `_input`, que roda ANTES da interface: passou da zona morta, a lista
## rola, os botões ficam desligados até soltar o dedo (para o arrasto não virar um toque) e,
## ao soltar, a lista continua deslizando um pouco e para devagar (inércia), como no celular.

const DEADZONE := 14.0  ## px que o dedo anda antes de virar arrasto (abaixo disso é toque)
const FRICTION := 5.0   ## quanto a inércia freia por segundo

var _pressing := false
var _dragging := false
var _press_pos := Vector2.ZERO
var _start_scroll := Vector2.ZERO
var _velocity := Vector2.ZERO
var _last_pos := Vector2.ZERO
var _last_time := 0.0
var _disabled: Array[BaseButton] = []
var _saved: Array[Dictionary] = []  # visual "desligado" original de cada botão


func _ready() -> void:
	set_process(false)


func is_dragging() -> bool:
	return _dragging


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	# Só eventos de mouse: no celular o toque também gera mouse (emulação), e no PC o mouse
	# gera toque — tratar os dois rolaria a lista em dobro.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if get_global_rect().has_point(event.position):
				_pressing = true
				_dragging = false
				_press_pos = event.position
				_last_pos = event.position
				_last_time = Time.get_ticks_msec() / 1000.0
				_start_scroll = Vector2(scroll_horizontal, scroll_vertical)
				_velocity = Vector2.ZERO
				set_process(false)
		elif _pressing:
			_pressing = false
			if _dragging:
				_dragging = false
				set_process(_velocity.length() > 60.0)
				_enable_buttons.call_deferred()  # depois que a interface tratar o soltar
	elif event is InputEventMouseMotion and _pressing:
		var delta: Vector2 = event.position - _press_pos
		if not _dragging:
			if not _can_scroll(delta) or not _pointer_inside():
				return
			_dragging = true
			_disable_buttons()
		var now := Time.get_ticks_msec() / 1000.0
		var dt := maxf(now - _last_time, 0.001)
		var step: Vector2 = (_last_pos - event.position) / dt
		_velocity = _velocity.lerp(step, 0.5)
		_last_pos = event.position
		_last_time = now
		_apply(_start_scroll - delta)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	# inércia depois de soltar o dedo
	_velocity *= maxf(0.0, 1.0 - FRICTION * delta)
	_apply(Vector2(scroll_horizontal, scroll_vertical) + _velocity * delta)
	if _velocity.length() < 30.0:
		set_process(false)


func _apply(target: Vector2) -> void:
	if horizontal_scroll_mode != SCROLL_MODE_DISABLED:
		scroll_horizontal = int(target.x)
	if vertical_scroll_mode != SCROLL_MODE_DISABLED:
		scroll_vertical = int(target.y)


## Só vira arrasto se andou além da zona morta numa direção em que a lista rola.
func _can_scroll(delta: Vector2) -> bool:
	var h := horizontal_scroll_mode != SCROLL_MODE_DISABLED and absf(delta.x) > DEADZONE
	var v := vertical_scroll_mode != SCROLL_MODE_DISABLED and absf(delta.y) > DEADZONE
	return h or v


## O dedo está sobre esta lista (e não sobre uma janela por cima dela)?
func _pointer_inside() -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	return hovered == null or hovered == self or is_ancestor_of(hovered)


func _disable_buttons() -> void:
	_disabled.clear()
	_collect(self)
	_saved.clear()
	for b in _disabled:
		# desligado com a mesma cara de ligado (a lista só está rolando, nada mudou)
		var keep := {}
		keep["sb"] = b.get_theme_stylebox("disabled") if b.has_theme_stylebox_override("disabled") else null
		keep["fc"] = b.get_theme_color("font_disabled_color") if b.has_theme_color_override("font_disabled_color") else null
		keep["ic"] = b.get_theme_color("icon_disabled_color") if b.has_theme_color_override("icon_disabled_color") else null
		_saved.append(keep)
		b.add_theme_stylebox_override("disabled", b.get_theme_stylebox("pressed" if b.button_pressed else "normal"))
		b.add_theme_color_override("font_disabled_color", b.get_theme_color("font_pressed_color" if b.button_pressed else "font_color"))
		b.add_theme_color_override("icon_disabled_color", b.get_theme_color("icon_normal_color"))
		b.disabled = true  # desligar cancela o toque que começou no botão


func _collect(n: Node) -> void:
	for c in n.get_children():
		if c is BaseButton and not (c as BaseButton).disabled:
			_disabled.append(c)
		_collect(c)


func _enable_buttons() -> void:
	for i in _disabled.size():
		var b := _disabled[i]
		if not is_instance_valid(b):
			continue
		b.disabled = false
		var keep: Dictionary = _saved[i]
		if keep["sb"] == null:
			b.remove_theme_stylebox_override("disabled")
		else:
			b.add_theme_stylebox_override("disabled", keep["sb"])
		for k: Array in [["fc", "font_disabled_color"], ["ic", "icon_disabled_color"]]:
			if keep[k[0]] == null:
				b.remove_theme_color_override(k[1])
			else:
				b.add_theme_color_override(k[1], keep[k[0]])
	_disabled.clear()
	_saved.clear()
