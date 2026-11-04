class_name Livery
extends RefCounted
## Pintura do carro da equipe na campanha (estúdio de design, P9 aprovada; mockups v18 aprovados, 2026-11-04).
## Camadas (base, faixa, degradê, padrão, número) recortadas na carroceria, acabamento só visual (não muda o
## desempenho), até 3 pinturas especiais por temporada, capacete dos pilotos e o lançamento do carro com nota da crítica.
## O desenho sai como SVG em texto (mesma arte de CarArt / tools/make_car_art.py), carregado em tempo real.

const MAX_LAYERS := 12
const MAX_SPECIALS := 3
const KINDS := ["stripe", "gradient", "pattern", "number"]
const KIND_NAMES := {"base": "Base", "stripe": "Faixa", "gradient": "Degradê", "pattern": "Hexágonos", "number": "Número"}
const FINISHES := ["gloss", "matte", "metal", "pearl", "chrome", "neon", "carbon"]
const FINISH_NAMES := {"gloss": "Brilho", "matte": "Fosco", "metal": "Metálico", "pearl": "Perolado", "chrome": "Cromado", "neon": "Neon", "carbon": "Carbono"}
const PALETTE := ["#1347F5", "#00E1FF", "#FFFFFF", "#0B1E5C", "#11141A", "#E10600", "#FFD24A", "#3C9D5D", "#FF8000", "#C77DFF", "#8F98A7", "#D4A017"]
const LAUNCH_BONUS_MUSD := [0.0, 0.0, 0.2, 0.4, 0.6, 0.9]  ## por estrela da crítica
const LAUNCH_TRUST := [0, -2, 0, 1, 3, 5]

## pintura principal: {base, finish, accent, layers: [{kind, color, angle, offset, width, mirror, opacity}]}
var main: Dictionary = {}
var specials: Array = []  ## [{name, round (índice do calendário), paint: {...}}]
var helmet: Dictionary = {"base": "#FFFFFF", "stripe": "#1347F5", "visor": "#11141A", "pattern": "band"}
var launch: Dictionary = {}  ## lançamento pendente de ver: {season, stars, quotes, bonus, trust}
var launched_season := 0


static func default_paint(c1: String, c2: String) -> Dictionary:
	return {"base": c1, "finish": "gloss", "accent": c2, "layers": [
		{"kind": "stripe", "color": c2, "angle": 35.0, "offset": -0.15, "width": 0.8, "mirror": false, "opacity": 0.95},
		{"kind": "number", "color": "#FFFFFF", "angle": 0.0, "offset": 0.0, "width": 1.0, "mirror": false, "opacity": 1.0}]}


func setup(team: Dictionary) -> void:
	var c2 := String(team.get("color2", "#FFFFFF"))
	if Color(c2).get_luminance() < 0.15:
		c2 = "#F2F2F2"
	main = default_paint(String(team.get("color", "#888888")), c2)
	helmet = {"base": "#FFFFFF", "stripe": String(team.get("color", "#1347F5")), "visor": "#11141A", "pattern": "band"}


## Pintura usada numa rodada (especial, se marcada para ela).
func paint_for_round(round_index: int) -> Dictionary:
	for s: Dictionary in specials:
		if int(s.get("round", -1)) == round_index:
			return s["paint"]
	return main


# --- edição ---------------------------------------------------------------------------------------

func add_layer(paint: Dictionary, kind: String, color: String) -> bool:
	var layers: Array = paint["layers"]
	if layers.size() >= MAX_LAYERS or not KINDS.has(kind):
		return false
	var l := {"kind": kind, "color": color, "angle": 0.0, "offset": 0.0, "width": 1.0, "mirror": false, "opacity": 0.85 if kind != "pattern" else 0.14}
	if kind == "stripe":
		l["angle"] = 35.0
	layers.append(l)
	return true


## Pintura automática a partir das cores da equipe (botão "gerar pintura").
static func generate(c1: String, c2: String, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var accents := [c2, "#FFFFFF", "#00E1FF", "#FFD24A", "#E10600", "#11141A"]
	var base := c1 if rng.randf() < 0.75 else c2
	var p := {"base": base, "finish": FINISHES[rng.randi() % FINISHES.size()], "accent": c2, "layers": []}
	var a1: String = accents[rng.randi() % accents.size()]
	if a1 == base:
		a1 = "#FFFFFF"
	(p["layers"] as Array).append({"kind": "stripe", "color": a1, "angle": [0.0, 20.0, 35.0, -30.0][rng.randi() % 4], "offset": rng.randf_range(-0.2, 0.2),
		"width": rng.randf_range(0.7, 1.6), "mirror": false, "opacity": 0.95})
	if rng.randf() < 0.6:
		(p["layers"] as Array).append({"kind": "gradient", "color": "#0B1E5C" if Color(base).get_luminance() > 0.3 else "#000000", "angle": 0.0, "offset": 0.0,
			"width": 1.0, "mirror": rng.randf() < 0.5, "opacity": 0.8})
	if rng.randf() < 0.4:
		(p["layers"] as Array).append({"kind": "pattern", "color": "#FFFFFF", "angle": 0.0, "offset": 0.0, "width": 1.0, "mirror": false, "opacity": 0.14})
	(p["layers"] as Array).append({"kind": "number", "color": "#FFFFFF" if Color(base).get_luminance() < 0.6 else "#11141A", "angle": 0.0, "offset": 0.0,
		"width": 1.0, "mirror": false, "opacity": 1.0})
	return p


# --- crítica do lançamento -----------------------------------------------------------------------

## Nota da crítica (1–5): contraste entre base e destaques, número de camadas (nem vazia, nem poluída) e acabamento.
static func critic_stars(paint: Dictionary, seed_value: int) -> int:
	var base := Color(String(paint.get("base", "#888888")))
	var score := 2.0
	var layers: Array = paint.get("layers", [])
	var visible := layers.filter(func(l: Dictionary) -> bool: return l["kind"] != "number")
	if visible.size() >= 1 and visible.size() <= 4:
		score += 1.0
	elif visible.size() > 6:
		score -= 1.0
	var best_contrast := 0.0
	for l: Dictionary in visible:
		best_contrast = maxf(best_contrast, absf(Color(String(l["color"])).get_luminance() - base.get_luminance()))
	score += clampf(best_contrast * 2.5, 0.0, 1.5)
	if ["metal", "pearl", "chrome", "carbon"].has(String(paint.get("finish", ""))):
		score += 0.5
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	score += rng.randf_range(-0.6, 0.6)  # gosto é gosto
	return clampi(roundi(score), 1, 5)


## Gera o lançamento do carro da temporada (chamado na virada). Aplica os efeitos e guarda para a sede mostrar.
func make_launch(camp: Campaign) -> Dictionary:
	var stars := critic_stars(main, hash("launch|%d|%s" % [camp.season, camp.player_team]))
	var bonus: float = LAUNCH_BONUS_MUSD[stars]
	var trust: int = LAUNCH_TRUST[stars]
	camp.budget_musd += bonus  # bônus das marcas antes da 1ª rodada (entra no caixa inicial da temporada)
	if not camp.cash_log.is_empty():
		camp.cash_log[0]["cash"] = camp.budget_musd
	camp.trust = clampf(camp.trust + trust, 0.0, 100.0)
	var quotes := {
		1: ["“Parece um carro sem pintura. Faltou coragem.”", "“A gente queria mais cor.”"],
		2: ["“Correto, mas esquecível.”", "“Bonito de longe, sem graça de perto.”"],
		3: ["“Uma pintura limpa, que funciona.”", "“Gostei, mas não vou comprar a camiseta.”"],
		4: ["“Ousada na medida certa. Um dos mais bonitos do grid.”", "“Já quero a miniatura.”"],
		5: ["“Instantaneamente clássica. Vai ficar na história.”", "“Melhor pintura da década!”"]}
	launch = {"season": camp.season, "stars": stars, "quotes": quotes[stars], "bonus": bonus, "trust": trust}
	launched_season = camp.season
	return launch


# --- desenho --------------------------------------------------------------------------------------

## SVG do carro com a pintura (1000 × 280). c2: cor de detalhe (rodas, asas).
static func car_svg(paint: Dictionary) -> String:
	var base := String(paint.get("base", "#888888"))
	var c2 := String(paint.get("accent", "#FFFFFF"))
	var finish := String(paint.get("finish", "gloss"))
	var svg := CarArt.car_svg(base, c2)
	var clip := ""
	for d: String in CarArt.BODY:
		clip += '<path d="%s"/>' % d
	var defs := '<clipPath id="body">%s</clipPath>' % clip
	var g := ""
	var gid := 0
	if finish == "carbon":  # carbono exposto: trama escura sobre a base
		for i in range(-10, 60):
			g += '<path d="M%d 280L%d 0" stroke="#000000" stroke-opacity=".28" stroke-width="5"/>' % [i * 20, i * 20 + 120]
	for l: Dictionary in paint.get("layers", []):
		var col := String(l["color"])
		var op := float(l.get("opacity", 1.0))
		var ang := float(l.get("angle", 0.0))
		var off := float(l.get("offset", 0.0)) * 300.0
		var wd := float(l.get("width", 1.0))
		var mirror := bool(l.get("mirror", false))
		match String(l["kind"]):
			"stripe":
				var cx := 500.0 + off
				var w := 46.0 * wd
				var tilt := tan(deg_to_rad(clampf(ang, -70.0, 70.0))) * 280.0 * (-1.0 if mirror else 1.0)
				g += '<path d="M%.1f 280L%.1f 0L%.1f 0L%.1f 280Z" fill="%s" fill-opacity="%.2f"/>' % [cx - w - tilt * 0.5, cx - w + tilt * 0.5, cx + w + tilt * 0.5, cx + w - tilt * 0.5, col, op]
				g += '<path d="M%.1f 280L%.1f 0L%.1f 0L%.1f 280Z" fill="#FFFFFF" fill-opacity="%.2f"/>' % [cx + w + 8 - tilt * 0.5, cx + w + 8 + tilt * 0.5, cx + w + 20 + tilt * 0.5, cx + w + 20 - tilt * 0.5, op * 0.85]
			"gradient":
				gid += 1
				var x1 := "1" if mirror else "0"
				var x2 := "0" if mirror else "1"
				defs += '<linearGradient id="g%d" x1="%s" y1="0" x2="%s" y2="0"><stop offset="0" stop-color="%s" stop-opacity="0"/><stop offset=".55" stop-color="%s" stop-opacity="0"/><stop offset="1" stop-color="%s" stop-opacity="%.2f"/></linearGradient>' % [gid, x1, x2, col, col, col, op]
				g += '<rect x="0" y="0" width="1000" height="280" fill="url(#g%d)"/>' % gid
			"pattern":
				for row in range(4, 13):
					for colx in range(25, 46):
						var x := colx * 22.0 + (11.0 if row % 2 == 1 else 0.0)
						var y := row * 19.0
						g += '<path d="M%.1f %.1fh11l5.5 9.5-5.5 9.5h-11l-5.5-9.5z" fill="none" stroke="%s" stroke-opacity="%.2f" stroke-width="1.2"/>' % [x, y, col, op]
	# acabamento: brilho por cima
	var shine := ""
	match finish:
		"metal":
			shine = '<rect x="0" y="0" width="1000" height="280" fill="#FFFFFF" fill-opacity=".10"/>'
		"chrome":
			shine = '<path d="M0 150L1000 120L1000 150L0 182Z" fill="#FFFFFF" fill-opacity=".35"/>'
		"pearl":
			defs += '<linearGradient id="pearl" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E8FDFF" stop-opacity=".25"/><stop offset="1" stop-color="#F6D8FF" stop-opacity=".25"/></linearGradient>'
			shine = '<rect x="0" y="0" width="1000" height="280" fill="url(#pearl)"/>'
		"matte":
			shine = '<rect x="0" y="0" width="1000" height="280" fill="#000000" fill-opacity=".14"/>'
		"neon":
			shine = '<rect x="0" y="0" width="1000" height="280" fill="#FFFFFF" fill-opacity=".06"/>'
	var layer_svg := '<defs>%s</defs><g clip-path="url(#body)">%s%s</g>' % [defs, g, shine]
	# as camadas entram logo depois da carroceria (antes do cockpit, das asas e das rodas)
	var anchor := '<path d="M500 104L540 100 548 124 505 128Z"'
	return svg.replace(anchor, layer_svg + anchor) if svg.contains(anchor) else svg


static var _cache: Dictionary = {}


static func car_texture(paint: Dictionary) -> Texture2D:
	var key := JSON.stringify(paint)
	if not _cache.has(key):
		var img := Image.new()
		if img.load_svg_from_string(car_svg(paint), 1.0) != OK:
			return null
		_cache[key] = ImageTexture.create_from_image(img)
		if _cache.size() > 24:
			_cache.erase(_cache.keys()[0])
	return _cache[key]


## Capacete (perfil lateral simples) em SVG 200 × 160.
static func helmet_svg(h: Dictionary) -> String:
	var base := String(h.get("base", "#FFFFFF"))
	var stripe := String(h.get("stripe", "#1347F5"))
	var visor := String(h.get("visor", "#11141A"))
	var pat := ""
	match String(h.get("pattern", "band")):
		"band":
			pat = '<path d="M20 92C60 70 140 66 186 80L188 98C140 86 64 90 22 112Z" fill="%s"/>' % stripe
		"crown":
			pat = '<path d="M40 40C80 14 140 16 170 44L150 52C124 34 86 34 58 52Z" fill="%s"/>' % stripe
		"split":
			pat = '<path d="M100 10C150 12 190 50 190 100L190 140H100Z" fill="%s"/>' % stripe
		"stars":
			for p: Vector2 in [Vector2(60, 60), Vector2(100, 42), Vector2(140, 56), Vector2(80, 110)]:
				pat += '<circle cx="%d" cy="%d" r="9" fill="%s"/>' % [int(p.x), int(p.y), stripe]
	return ('<svg xmlns="http://www.w3.org/2000/svg" width="200" height="160" viewBox="0 0 200 160">'
		+ '<defs><clipPath id="hc"><path d="M14 112C10 50 54 10 108 10C160 10 196 50 192 104L190 140H40C24 140 16 128 14 112Z"/></clipPath></defs>'
		+ '<path d="M14 112C10 50 54 10 108 10C160 10 196 50 192 104L190 140H40C24 140 16 128 14 112Z" fill="%s"/>' % base
		+ '<g clip-path="url(#hc)">%s</g>' % pat
		+ '<path d="M110 62H188C192 74 192 90 190 100H118C108 100 102 92 102 82C102 70 104 62 110 62Z" fill="%s"/>' % visor
		+ '<path d="M118 70H180" stroke="#FFFFFF" stroke-opacity=".35" stroke-width="4" stroke-linecap="round"/>'
		+ '<path d="M40 140H190V150H40Z" fill="#11141A"/></svg>')


static func helmet_texture(h: Dictionary) -> Texture2D:
	var img := Image.new()
	if img.load_svg_from_string(helmet_svg(h), 1.0) != OK:
		return null
	return ImageTexture.create_from_image(img)


# --- salvar / carregar ------------------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"main": main, "specials": specials, "helmet": helmet, "launch": launch, "launched_season": launched_season}


static func from_dict(d: Dictionary) -> Livery:
	var l := Livery.new()
	l.main = d.get("main", {})
	l.specials = d.get("specials", [])
	for s: Dictionary in l.specials:
		s["round"] = int(s.get("round", -1))
	l.helmet = d.get("helmet", l.helmet)
	l.launch = d.get("launch", {})
	l.launched_season = int(d.get("launched_season", 0))
	return l
