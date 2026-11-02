class_name PitTapOverlay
extends Control
## Mini-jogo do box (mockup v8-2): com o carro parado, um marcador vai e volta numa barra; tocar
## com o marcador no verde solta o carro mais cedo (perfeito −0,3 s), tocar longe custa +0,6 s.
## Vale uma vez por parada. Sem toque (ou se o jogador não olhar), a parada segue neutra.
## Só aparece para carros do jogador; a IA e as simulações em lote não passam por aqui.

signal finished

const SWEEP_S := 1.15  ## uma ida do marcador (0→1) em tempo real
const PERFECT_ZONE := 0.08  ## meia-largura do verde forte (fração da barra)
const GOOD_ZONE := 0.16  ## meia-largura do verde claro

var sim: RaceSim
var car: CarState

var _gauge: Control
var _marker: ColorRect
var _title: Label
var _hint: Label
var _btn: CutButton
var _result: Label
var _t := 0.0
var _tapped := false
var _end_in := -1.0


func setup(p_sim: RaceSim, p_car: CarState) -> void:
	sim = p_sim
	car = p_car
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.025, 0.03, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var box := PanelContainer.new()
	var st := UiStyle.g_box(UiStyle.G_LIGHT, 24, 32, 24)
	st.border_width_left = 9
	st.border_color = UiStyle.RED
	box.add_theme_stylebox_override("panel", st)
	box.custom_minimum_size = Vector2(640, 0)
	center.add_child(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	box.add_child(v)

	var who := HBoxContainer.new()
	who.alignment = BoxContainer.ALIGNMENT_CENTER
	who.add_theme_constant_override("separation", 10)
	who.add_child(DriverPhotos.make_avatar(car.driver, car.team_color(), 34))
	who.add_child(UiStyle.g_caption("Carro parado no box · %s" % car.display_name(), UiStyle.G_INK_2))
	v.add_child(who)
	_title = UiStyle.g_label("TOQUE QUANDO O MARCADOR ESTIVER NO VERDE", 28, UiStyle.G_INK, "black")
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_title)
	_hint = UiStyle.g_label("", 15, UiStyle.G_INK_2)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_hint)

	_gauge = Gauge.new()
	_gauge.custom_minimum_size = Vector2(0, 46)
	v.add_child(_gauge)
	_marker = ColorRect.new()
	_marker.color = UiStyle.G_INK
	_marker.size = Vector2(6, 54)
	_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gauge.add_child(_marker)
	var legend := HBoxContainer.new()
	var l1 := UiStyle.g_label("+0,6 s", 12, UiStyle.G_INK_2)
	var l2 := UiStyle.g_label("−0,3 s (perfeito)", 12, Color("#2a6b3f"), "black")
	var l3 := UiStyle.g_label("+0,6 s", 12, UiStyle.G_INK_2)
	l1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l3.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	legend.add_child(l1)
	legend.add_child(l2)
	legend.add_child(l3)
	v.add_child(legend)

	_result = UiStyle.g_label("", 20, UiStyle.G_INK, "black")
	_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_result)
	_btn = CutButton.new()
	_btn.text = "SOLTAR O CARRO"
	_btn.custom_minimum_size = Vector2(320, 68)
	_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_btn.pressed.connect(_tap)
	v.add_child(_btn)
	_update_hint()


func _update_hint() -> void:
	var c: Dictionary = sim.tyres.compounds.get(car.pit_compound, {})
	_hint.text = "Pneus %s · parada prevista %.1f s" % [String(c.get("name", "novos")), car.box_hold_s]


## Posição do marcador 0..1 (vai e volta).
func marker_pos() -> float:
	return 1.0 - absf(fposmod(_t / SWEEP_S, 2.0) - 1.0)


## Precisão do toque: 1 no centro do verde forte, 0 fora do verde claro.
static func accuracy_at(pos: float) -> float:
	var d := absf(pos - 0.5)
	if d <= PERFECT_ZONE:
		return 1.0
	if d >= GOOD_ZONE * 2.0:
		return 0.0
	return 1.0 - (d - PERFECT_ZONE) / (GOOD_ZONE * 2.0 - PERFECT_ZONE)


func _tap() -> void:
	if _tapped:
		return
	_tapped = true
	var acc := accuracy_at(marker_pos())
	var delta := sim.pit_tap(car, acc)
	_btn.disabled = true
	if delta < -0.05:
		_result.text = "PERFEITO · %s s" % ("%.1f" % delta).replace(".", ",")
		_result.add_theme_color_override("font_color", Color("#2a6b3f"))
	elif delta > 0.05:
		_result.text = "FORA DO VERDE · +%s s" % ("%.1f" % delta).replace(".", ",")
		_result.add_theme_color_override("font_color", UiStyle.RED)
	else:
		_result.text = "BOM · %s s" % ("%.1f" % delta).replace(".", ",")


func _process(delta: float) -> void:
	_t += delta
	var w := _gauge.size.x
	_marker.position = Vector2(w * _tapped_pos() - 3.0, -4.0)
	# o carro saiu do box (ou a parada acabou): fecha logo depois de mostrar o resultado
	if not car.in_pit or car.box_hold_s <= 0.0:
		if _end_in < 0.0:
			_end_in = 0.5 if _tapped else 0.0
		_end_in -= delta
		if _end_in <= 0.0:
			finished.emit()
			queue_free()


var _frozen_pos := -1.0


func _tapped_pos() -> float:
	if _tapped:
		if _frozen_pos < 0.0:
			_frozen_pos = marker_pos()
		return _frozen_pos
	return marker_pos()


## Barra com a faixa verde (clara larga, forte no centro).
class Gauge:
	extends Control

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color("#d6d9df")
		bg.set_corner_radius_all(int(size.y / 2.0))
		draw_style_box(bg, r)
		var g2 := Rect2(size.x * (0.5 - PitTapOverlay.GOOD_ZONE * 2.0), 0, size.x * PitTapOverlay.GOOD_ZONE * 4.0, size.y)
		draw_rect(g2, Color(0.235, 0.616, 0.365, 0.35))
		var g1 := Rect2(size.x * (0.5 - PitTapOverlay.PERFECT_ZONE), 0, size.x * PitTapOverlay.PERFECT_ZONE * 2.0, size.y)
		draw_rect(g1, Color("#3c9d5d"))
