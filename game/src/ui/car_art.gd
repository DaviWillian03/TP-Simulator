class_name CarArt
extends RefCounted
## Arte gerada em tempo real para qualquer equipe (inclusive a criada na campanha): a ilustração
## lateral do carro (mesmo desenho de tools/make_car_art.py) e o emblema (forma + sigla + cores).
## SVG montado em texto e carregado com Image.load_svg_from_string (funciona no Android).

const BODY := ["M40 214C120 206 230 190 330 176L330 214 60 222Z", "M300 178L430 160 520 150 560 156 560 236 300 236Z",
	"M470 168C560 158 650 160 720 178L760 214C700 236 560 238 470 236Z", "M505 120C560 112 620 118 700 150 780 176 850 192 902 200L902 214 720 214 520 162Z",
	"M600 121L882 102 882 170 720 150Z", "M886 96L976 96 986 232 900 232Z"]
const SHAPES := {
	"square": '<rect x="2" y="2" width="20" height="20" rx="3" fill="%s" stroke="%s" stroke-width="1.4"/>',
	"hex": '<path d="M7 2h10l5 10-5 10H7L2 12z" fill="%s" stroke="%s" stroke-width="1.4"/>',
	"circle": '<circle cx="12" cy="12" r="10.2" fill="%s" stroke="%s" stroke-width="1.4"/>',
	"shield": '<path d="M3 2h18v9c0 6-4 9-9 11C7 20 3 17 3 11z" fill="%s" stroke="%s" stroke-width="1.4"/>',
	"diamond": '<path d="M12 1l11 11-11 11L1 12z" fill="%s" stroke="%s" stroke-width="1.4"/>',
}

static var _cache: Dictionary = {}


## Textura do carro da equipe: arquivo pronto para as equipes reais; gerada para a criada.
static func car_texture(team: Dictionary) -> Texture2D:
	if team.has("livery_paint") and not (team["livery_paint"] as Dictionary).is_empty():  # campanha: pintura do estúdio
		var t := Livery.car_texture(team["livery_paint"])
		if t != null:
			return t
	var id: String = team.get("id", "")
	if not team.get("custom", false) and ResourceLoader.exists("res://assets/cars/%s.svg" % id):
		return load("res://assets/cars/%s.svg" % id)
	var key := "car:%s:%s:%s" % [id, team.get("color", ""), team.get("color2", "")]
	if not _cache.has(key):
		_cache[key] = _from_svg(car_svg(team.get("color", "#888888"), team.get("color2", "#ffffff")), 1.0)
	return _cache[key]


static func emblem_texture(shape: String, color: String, color2: String, short: String) -> Texture2D:
	var key := "emb:%s:%s:%s:%s" % [shape, color, color2, short]
	if not _cache.has(key):
		_cache[key] = _from_svg(emblem_svg(shape, color, color2, short), 10.0)
	return _cache[key]


static func _from_svg(svg: String, scale: float) -> Texture2D:
	var img := Image.new()
	if img.load_svg_from_string(svg, scale) != OK:
		return null
	return ImageTexture.create_from_image(img)


static func emblem_svg(shape: String, color: String, color2: String, short: String) -> String:
	var body: String = SHAPES.get(shape, SHAPES["hex"]) % [color, color2]
	# a sigla vai como letras desenhadas pelo jogo por cima (o importador de SVG não garante texto)
	return '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">%s</svg>' % body


static func car_svg(c1: String, c2: String) -> String:
	var body := ""
	var shine := ""
	for d: String in BODY:
		body += '<path d="%s" fill="%s"/>' % [d, c1]
		shine += '<path d="%s" fill="url(#hl)"/>' % d
	var wheels := ""
	for cx: int in [215, 802]:
		wheels += '<circle cx="%d" cy="200" r="63" fill="#121316"/><circle cx="%d" cy="200" r="52" fill="none" stroke="#F5C400" stroke-width="4"/>' % [cx, cx]
		wheels += '<circle cx="%d" cy="200" r="36" fill="#262a31"/>' % cx
		for a in 5:
			wheels += '<line x1="%d" y1="200" x2="%.1f" y2="%.1f" stroke="#3b4049" stroke-width="5"/>' % [cx, cx + 34.0 * cos(a * 1.2566), 200.0 + 34.0 * sin(a * 1.2566)]
		wheels += '<circle cx="%d" cy="200" r="9" fill="%s"/>' % [cx, c2]
	return ('<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="280" viewBox="0 0 1000 280">'
		+ '<defs><linearGradient id="hl" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffffff" stop-opacity=".34"/>'
		+ '<stop offset=".55" stop-color="#ffffff" stop-opacity="0"/><stop offset="1" stop-color="#000000" stop-opacity=".25"/></linearGradient></defs>'
		+ '<path d="M150 236H906V246H150Z M860 236L918 220 918 236Z" fill="#15171b"/>'
		+ '<path d="M18 236H150V244L18 246Z" fill="#1d2026"/><path d="M30 226L142 221 142 229 30 234Z" fill="%s"/>' % c2
		+ '<path d="M18 204H46L52 246H18Z" fill="#1d2026"/>' + body
		+ '<path d="M60 216C200 200 330 186 470 186 600 186 720 196 902 204L902 210C720 203 600 195 470 195 330 195 200 208 60 222Z" fill="%s" fill-opacity=".95"/>' % c2
		+ '<path d="M480 236C560 222 680 222 760 214L760 236Z" fill="#0f1013" fill-opacity=".85"/>' + shine
		+ '<path d="M500 104L540 100 548 124 505 128Z" fill="#0d0e11"/>'
		+ '<rect x="874" y="94" width="112" height="15" rx="2" fill="%s"/><rect x="880" y="113" width="104" height="10" rx="2" fill="#16181d"/>' % c2
		+ '<rect x="900" y="214" width="82" height="8" fill="#16181d"/>'
		+ '<circle cx="468" cy="140" r="21" fill="%s"/><path d="M452 136h30v9h-30z" fill="#101215"/>' % c2
		+ '<path d="M392 158C420 128 480 120 530 128" stroke="#15171b" stroke-width="9" fill="none" stroke-linecap="round"/>'
		+ '<path d="M530 128V154" stroke="#15171b" stroke-width="8"/><rect x="418" y="146" width="24" height="8" rx="2" fill="#15171b"/>'
		+ wheels + '</svg>')
