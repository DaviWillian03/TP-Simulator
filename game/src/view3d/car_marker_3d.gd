class_name CarMarker3D
extends Node3D
## Marcador de carro na pista 3D, no estilo do Motorsport Manager: disco plano na cor da equipe
## com o número do piloto por cima. Sempre encara a câmera e tem tamanho constante na tela
## (não encolhe quando a câmera se afasta), então dá para achar o carro de qualquer distância.
## Os carros do jogador são maiores e ganham um anel branco.
##
## Por que sprites e não malha 3D: o disco é só um círculo; `fixed_size` + `billboard` do Godot
## resolvem o tamanho constante e a orientação sem shader, e o `Label3D` cuida do texto.

const DISC_PX := 128  ## textura do círculo (branca; a cor vem do `modulate`)
const PIXEL_SIZE := 0.0026  ## com fixed_size: tamanho na tela por pixel de textura
const NORMAL_SCALE := 0.17
const PLAYER_SCALE := 0.2

static var _disc: ImageTexture

var _layers: Array[GeometryInstance3D] = []
var _base_alpha: Array[float] = []
var _alert: Sprite3D
var _fade := 1.0  # de trás para a frente: anel, contorno, disco, número


func setup(car: CarState) -> void:
	var color := car.team_color()
	var k := PLAYER_SCALE if car.is_player else NORMAL_SCALE
	if car.is_player:
		_sprite(Color.WHITE, 1.0 * k)
	_sprite(Color(0.04, 0.05, 0.07, 0.95), 0.86 * k)
	_sprite(color, 0.74 * k)
	# número do piloto (o logo da equipe foi testado e perdeu: repete nos dois carros e some pequeno)
	var label := Label3D.new()
	label.text = str(int(car.driver["number"]))
	label.font = UiStyle.G_BLACK
	label.font_size = 64
	label.pixel_size = PIXEL_SIZE * k * 0.95
	label.modulate = _ink_for(color)
	label.outline_size = 0
	_flag(label)
	add_child(label)
	_layers.append(label)
	for l in _layers:
		_base_alpha.append((l as Variant).modulate.a)
	# anel amarelo de alerta (rodou / saiu da pista), atrás do disco
	_alert = Sprite3D.new()
	_alert.texture = _disc_texture()
	_alert.modulate = Color("#ffd24a")
	_flag(_alert)
	_alert.pixel_size = PIXEL_SIZE * k * 1.15
	_alert.visible = false
	add_child(_alert)
	_alert.render_priority = -1


## Transparência do marcador inteiro (carro batido apagando).
func set_fade(a: float) -> void:
	if is_equal_approx(a, _fade):
		return
	_fade = a
	for i in _layers.size():
		var m: Color = (_layers[i] as Variant).modulate
		m.a = _base_alpha[i] * a
		(_layers[i] as Variant).modulate = m


## Anel amarelo piscando enquanto o carro está fora da pista.
func set_alert(on: bool) -> void:
	_alert.visible = on and int(Time.get_ticks_msec() / 180) % 2 == 0


## Ordem de desenho: cada carro desenha as suas 3-4 camadas juntas (senão os números de carros
## sobrepostos se misturam). `rank` 0 = fica por cima de todos.
func set_rank(rank: int) -> void:
	var base := clampi(105 - rank * 4, -100, 109)
	for i in _layers.size():
		_layers[i].render_priority = base + i
	_alert.render_priority = base - 1


## Preto ou branco, o que contrastar mais com a cor da equipe.
static func _ink_for(c: Color) -> Color:
	return Color("#0b0c0f") if c.get_luminance() > 0.42 else Color.WHITE


func _sprite(color: Color, scale_k: float) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = _disc_texture()
	s.modulate = color
	_flag(s)
	s.pixel_size = PIXEL_SIZE * scale_k
	add_child(s)
	_layers.append(s)
	return s


func _flag(s: GeometryInstance3D) -> void:
	s.set("billboard", BaseMaterial3D.BILLBOARD_ENABLED)
	s.set("fixed_size", true)
	s.set("no_depth_test", true)
	if s is Sprite3D:
		(s as Sprite3D).shaded = false
		(s as Sprite3D).double_sided = true
		(s as Sprite3D).texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


## Círculo branco com borda suave (uma textura para todos os carros).
static func _disc_texture() -> ImageTexture:
	if _disc != null:
		return _disc
	var img := Image.create(DISC_PX, DISC_PX, true, Image.FORMAT_RGBA8)
	var c := (DISC_PX - 1) / 2.0
	var r := DISC_PX / 2.0 - 1.5
	for y in DISC_PX:
		for x in DISC_PX:
			var d := Vector2(x - c, y - c).length()
			img.set_pixel(x, y, Color(1, 1, 1, clampf(r - d + 0.5, 0.0, 1.0)))
	img.generate_mipmaps()
	_disc = ImageTexture.create_from_image(img)
	return _disc
