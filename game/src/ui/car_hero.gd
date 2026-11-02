class_name CarHero
extends Control
## O carro da equipe em destaque na garagem: ilustração lateral (assets/cars/<equipe>.svg,
## gerada por tools/make_car_art.py), sombra no chão, reflexo esmaecido e o número do piloto.

const ASPECT := 0.28  ## altura / largura da ilustração (1000×280)
const GROUND := 263.0 / 280.0  ## linha das rodas no chão, em fração da altura
const REFLECTION_SHADER := preload("res://src/ui/reflection.gdshader")

var _car := TextureRect.new()
var _refl := TextureRect.new()
var _shadow := TextureRect.new()
var _number: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shadow_g := Gradient.new()
	shadow_g.colors = PackedColorArray([Color(0, 0, 0, 0.75), Color(0, 0, 0, 0)])
	var st := GradientTexture2D.new()
	st.gradient = shadow_g
	st.fill = GradientTexture2D.FILL_RADIAL
	st.fill_from = Vector2(0.5, 0.5)
	st.fill_to = Vector2(1.0, 0.5)
	_shadow.texture = st
	_refl.flip_v = true
	var fade := ShaderMaterial.new()  # reflexo some aos poucos, a partir das rodas
	fade.shader = REFLECTION_SHADER
	_refl.material = fade
	for t: TextureRect in [_shadow, _refl, _car]:
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_SCALE
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shadow)
	add_child(_refl)
	add_child(_car)
	var italic := FontVariation.new()
	italic.base_font = UiStyle.G_BLACK
	italic.variation_transform = Transform2D(Vector2(1, 0), Vector2(-0.22, 1), Vector2.ZERO)
	_number = UiStyle.g_label("", 30, Color.WHITE, "black")
	_number.add_theme_font_override("font", italic)
	add_child(_number)
	resized.connect(_layout)
	_layout()


func set_team(team_id: String, number: int, number_color: Color = Color.WHITE, team: Dictionary = {}) -> void:
	var tex: Texture2D = CarArt.car_texture(team if not team.is_empty() else {"id": team_id})
	_car.texture = tex
	_refl.texture = tex
	_number.text = str(number)
	_number.add_theme_color_override("font_color", number_color)


func _layout() -> void:
	var w := size.x
	var h := w * ASPECT
	var g := h * GROUND
	_car.position = Vector2.ZERO
	_car.size = Vector2(w, h)
	_shadow.position = Vector2(w * 0.03, g - h * 0.07)
	_shadow.size = Vector2(w * 0.96, h * 0.14)
	_refl.position = Vector2(0, 2.0 * g - h)
	_refl.size = Vector2(w, h)
	_number.add_theme_font_size_override("font_size", UiStyle.fs(int(w * 0.036)))
	_number.position = Vector2(w * 0.632, h * 0.5)
