class_name NameFlag
extends Control
## Sobrenome do piloto com a bandeira do país "cortada" logo depois do nome (pedido do usuário:
## bandeira integrada ao nome sem atrapalhar a leitura). A bandeira é um paralelogramo inclinado
## no mesmo ângulo do recorte esportivo dos botões (CutButton), com fio claro e altura das
## maiúsculas: parece um adesivo da pintura do carro. O nome vem antes e nunca fica por cima;
## nome longo demais é cortado com "…" antes da bandeira.

const NATIONALITY_CODE := {
	"Alemanha": "de", "Argentina": "ar", "Austrália": "au", "Áustria": "at", "Bélgica": "be", "Brasil": "br",
	"Bulgária": "bg", "Canadá": "ca", "China": "cn", "Colômbia": "co", "Coreia do Sul": "kr", "Dinamarca": "dk",
	"Espanha": "es", "Estados Unidos": "us", "Finlândia": "fi", "França": "fr", "Holanda": "nl", "Países Baixos": "nl",
	"Hungria": "hu", "Índia": "in", "Irlanda": "ie", "Itália": "it", "Jamaica": "jm", "Japão": "jp", "México": "mx",
	"Mônaco": "mc", "Noruega": "no", "Nova Zelândia": "nz", "Paraguai": "py", "Polônia": "pl", "Reino Unido": "gb",
	"Singapura": "sg", "Sri Lanka": "lk", "Suécia": "se", "Tailândia": "th",
}

var text := ""
var font: Font = UiStyle.G_BLACK
var font_size := UiStyle.fs(18)
var color := UiStyle.G_TEXT
var flag: Texture2D


## Bandeira (textura) da nacionalidade escrita em português; null se não houver.
static func flag_for(nationality: String) -> Texture2D:
	var code: String = NATIONALITY_CODE.get(nationality, "")
	var path := "res://assets/flags/%s.svg" % code
	return load(path) if code != "" and ResourceLoader.exists(path) else null


static func make(name_text: String, nationality: String, size: int, col: Color = UiStyle.G_TEXT) -> NameFlag:
	var n := NameFlag.new()
	n.text = name_text.to_upper()
	n.font_size = UiStyle.fs(size)
	n.color = col
	n.flag = flag_for(nationality)
	n.tooltip_text = nationality
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.custom_minimum_size = Vector2(0, ceilf(n.font.get_height(n.font_size)))
	return n


func _flag_size() -> Vector2:
	var h := roundf(font_size * 0.62)  # altura das maiúsculas da Kanit
	return Vector2(roundf(h * 1.45), h)


func _draw() -> void:
	var fsz := _flag_size()
	var gap := roundf(font_size * 0.35)
	var room := size.x - (fsz.x + fsz.y * 0.35 + gap if flag else 0.0)
	# nome longo: primeiro diminui a letra (até 72%), só depois corta com "…"
	var fs := font_size
	var min_fs := roundi(font_size * 0.72)
	while fs > min_fs and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > room:
		fs -= 1
	var shown := text
	if font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > room:
		while shown.length() > 1 and font.get_string_size(shown + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > room:
			shown = shown.left(shown.length() - 1)
		shown += "…"
	var base := (size.y + font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0
	draw_string(font, Vector2(0, base), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)
	if flag == null:
		return
	var x := font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + gap
	var top := base - fsz.y - roundf(font_size * 0.02)
	var k := fsz.y * 0.35  # inclinação
	var pts := PackedVector2Array([Vector2(x + k, top), Vector2(x + k + fsz.x, top), Vector2(x + fsz.x, top + fsz.y), Vector2(x, top + fsz.y)])
	var w := fsz.x + k
	var uvs := PackedVector2Array()
	for p: Vector2 in pts:  # a textura cobre o paralelogramo inteiro (sem esticar a proporção 4:3)
		uvs.append(Vector2((p.x - x) / w, (p.y - top) / fsz.y))
	draw_colored_polygon(pts, Color.WHITE, uvs, flag)
	var edge := pts.duplicate()
	edge.append(pts[0])
	draw_polyline(edge, Color(1, 1, 1, 0.55), 1.0, true)
