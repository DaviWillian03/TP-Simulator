class_name CircuitDressing
extends RefCounted
## Acabamento do circuito em 3D (2026-11-09, pedido do usuário: pistas mais bonitas, detalhadas, coloridas e legíveis
## de longe; referência de nível de detalhe: jogos de gestão de automobilismo, sem copiar nenhum).
## Gramado aparado em listras, áreas de escape (asfalto + brita), barreiras de pneus, muros com placas, pit lane com
## diagonais de entrada/saída pintadas, prédio dos boxes e torre de controle, paddock com motorhomes, arquibancadas
## cobertas, passarelas sobre a pista e marcações do grid. Tudo gerado em código (sem arquivos de terceiros).

const VERGE_W := 30.0  ## gramado aparado de cada lado
const VERGE_DROP := 1.2  ## o gramado desce até o terreno (que fica 1,2 m abaixo da pista)
const PADDOCK_DEPTH := 70.0
const AD_COLORS := [Color("#1f4fa0"), Color("#f2f2f2"), Color("#e10600"), Color("#f5c400"), Color("#16a085"), Color("#1d1d1f"), Color("#ff7a00")]
const STAND_COLORS := [Color("#2f6fd0"), Color("#e8392e"), Color("#f2b705"), Color("#19a3a3"), Color("#7a4fd6")]

var t3: Track3D
var root: Node3D
var night := false
var teams: Array[Dictionary] = []
var asphalt: StandardMaterial3D
var w := Track3D.WIDTH / 2.0
var side := -1.0  ## lado do pit lane
var street := false  ## circuito de rua: calçada e muros colados na pista, sem brita
var real_map := false  ## pista com o mapa real (OSM): grama natural estreita, escapes no estilo do circuito (2026-11-13)
var vw := VERGE_W  ## largura do gramado de cada lado
var runoff: Dictionary = {}  ## estilo dos escapes (data/runoff.json)
var _vc: StandardMaterial3D
var _cache: Dictionary = {}


func build(p_t3: Track3D, p_root: Node3D, p_asphalt: StandardMaterial3D, p_teams: Array[Dictionary], p_night: bool) -> void:
	t3 = p_t3
	root = p_root
	asphalt = p_asphalt
	teams = p_teams
	night = p_night
	side = t3.track.pit_side
	street = bool(t3.track.scenery.get("street", false))
	real_map = FileAccess.file_exists("res://data/scenery/%s.json" % String(t3.track.id))
	var all_runoff: Dictionary = GameData.load_json(GameData.DATA_DIR + "runoff.json") if FileAccess.file_exists(GameData.DATA_DIR + "runoff.json") else {}
	runoff = all_runoff.get(String(t3.track.id), {})
	if real_map:
		vw = 12.0
	_vc = Materials3D.vertex_color(0.7)
	_vc.cull_mode = BaseMaterial3D.CULL_DISABLED
	_verges()
	_runoff()
	_barriers()
	_pit_lane()
	_pit_building()
	_paddock()
	_grandstands()
	_bridges()
	_grid_marks()


func _mesh(mesh: Mesh, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


func _box(size: Vector3, xf: Transform3D, mat: Material) -> MeshInstance3D:
	var key := "%s" % size
	if not _cache.has(key):
		var bm := BoxMesh.new()
		bm.size = size
		_cache[key] = bm
	var mi := MeshInstance3D.new()
	mi.mesh = _cache[key]
	mi.material_override = mat
	mi.transform = xf
	root.add_child(mi)
	return mi


## Altura do gramado aparado a x metros do eixo (desce linearmente até o terreno).
func _verge_lift(x: float) -> float:
	return -VERGE_DROP * clampf((absf(x) - w) / vw, 0.0, 1.0)


func _pit_side_zone(i: int) -> bool:
	return t3.in_pit_zone(i)


## Trecho do prédio dos boxes e do paddock (em volta da linha de chegada), em metros para cada lado.
func _paddock_half() -> float:
	return maxf(teams.size(), 1) * 12.0 + 40.0


func _in_paddock(i: int) -> bool:
	var d := fposmod(float(i) / t3.n + 0.5, 1.0) * t3.track.length_m - t3.track.length_m * 0.5
	return absf(d) <= _paddock_half() and t3.in_pit_zone(i)


# --- gramado, escapes e barreiras -----------------------------------------------------------------

func _verges() -> void:
	if street:
		_sidewalks()
		return
	var stripes := Materials3D.mowed_grass() if not real_map else Materials3D.ground(Color("#6f8f4a"))  # mapa real: grama natural
	stripes.cull_mode = BaseMaterial3D.CULL_DISABLED
	if night:
		stripes.albedo_color = Color(0.5, 0.55, 0.68)
	for s: float in [-1.0, 1.0]:
		# trecho sobre ponte (scenery.spans.bridge): sem gramado ao lado, para não cobrir a pista que passa por baixo
		var normal := func(i: int) -> bool: return not (s == side and _pit_side_zone(i)) and not _on_bridge(i)
		if s > 0:
			_mesh(t3.band(w, w + vw, 0.0, -VERGE_DROP, 12.0, normal), stripes)
		else:
			_mesh(t3.band(-w - vw, -w, -VERGE_DROP, 0.0, 12.0, normal), stripes)
	# lado do pit lane: plano até a borda de fora do pit lane; no trecho do paddock, plano até o fim dele; depois desce
	var lane_out := w + Track3D.PIT_GAP + Track3D.PIT_LANE_W + 3.0
	var pad_out := lane_out + PADDOCK_DEPTH
	var lane_only := func(i: int) -> bool: return _pit_side_zone(i) and not _in_paddock(i)
	var pad := func(i: int) -> bool: return _in_paddock(i)
	for spec: Array in [[lane_only, lane_out], [pad, pad_out]]:
		var far: float = spec[1]
		if side < 0:
			_mesh(t3.band(-far, -w, 0.0, 0.0, 12.0, spec[0]), stripes)
			_mesh(t3.band(-far - 24.0, -far, -VERGE_DROP, 0.0, 12.0, spec[0]), stripes)
		else:
			_mesh(t3.band(w, far, 0.0, 0.0, 12.0, spec[0]), stripes)
			_mesh(t3.band(far, far + 24.0, 0.0, -VERGE_DROP, 12.0, spec[0]), stripes)


func _on_bridge(i: int) -> bool:
	var sp: Array = (t3.track.scenery.get("spans", {}) as Dictionary).get("bridge", [])
	if sp.size() < 2:
		return false
	var f := float(i) / t3.n
	return f >= float(sp[0]) and f <= float(sp[1])


## Rua: calçada clara dos dois lados (o resto é a cidade).
func _sidewalks() -> void:
	var walk := Materials3D.ground(Color("#bdb8ad"))
	walk.cull_mode = BaseMaterial3D.CULL_DISABLED
	var not_pit := func(i: int) -> bool: return true
	_mesh(t3.band(w, w + 9.0, 0.0, -0.1, 8.0, not_pit), walk)
	_mesh(t3.band(-w - 9.0, -w, -0.1, 0.0, 8.0, not_pit), walk)
	var lane_out := w + Track3D.PIT_GAP + Track3D.PIT_LANE_W + 3.0
	var pad := func(i: int) -> bool: return _in_paddock(i)
	var conc := Materials3D.flat(Color("#8a8e93"), 0.95)
	conc.cull_mode = BaseMaterial3D.CULL_DISABLED
	conc.metallic_specular = 0.1
	var far := lane_out + PADDOCK_DEPTH * 0.5
	if side < 0:
		_mesh(t3.band(-far, -w, -0.02, -0.02, 10.0, pad), conc)
	else:
		_mesh(t3.band(w, far, -0.02, -0.02, 10.0, pad), conc)


## Escape nas curvas: faixa de asfalto azulado logo após a zebra e brita clara depois, do lado de fora.
func _runoff() -> void:
	if street:
		return
	if not runoff.is_empty():
		_styled_runoff()
		return
	var tarmac := Materials3D.ground(Color("#56606e"))
	tarmac.cull_mode = BaseMaterial3D.CULL_DISABLED
	var gravel := Materials3D.ground(Color("#c2a46a"))
	gravel.cull_mode = BaseMaterial3D.CULL_DISABLED
	var k := Track3D.KERB_W
	for s: float in [-1.0, 1.0]:
		var mask := func(i: int) -> bool: return t3.outside_side(i) == s and not (s == side and _pit_side_zone(i))
		var a0 := w + k
		var a1 := w + k + 5.0
		var a2 := w + k + 22.0
		if s > 0:
			_mesh(t3.band(a0, a1, _verge_lift(a0) + 0.05, _verge_lift(a1) + 0.05, 8.0, mask), tarmac)
			_mesh(t3.band(a1, a2, _verge_lift(a1) + 0.05, _verge_lift(a2) + 0.05, 8.0, mask), gravel)
		else:
			_mesh(t3.band(-a1, -a0, _verge_lift(a1) + 0.05, _verge_lift(a0) + 0.05, 8.0, mask), tarmac)
			_mesh(t3.band(-a2, -a1, _verge_lift(a2) + 0.05, _verge_lift(a1) + 0.05, 8.0, mask), gravel)


## Largura do escape (a partir da zebra): mais largo nas curvas fechadas (freada forte).
func _runoff_w(sharp: bool) -> float:
	return 38.0 if sharp else 24.0


func _sharp(i: int) -> bool:
	for k in range(-5, 6):
		if t3.curvature[(i + k + t3.n) % t3.n] > 0.22:
			return true
	return false


## Escapes no estilo real do circuito (data/runoff.json): brita, asfalto com faixa pintada ou asfalto todo pintado.
func _styled_runoff() -> void:
	var style := String(runoff.get("style", "gravel"))
	var cols: Array = runoff.get("colors", [])
	var tarmac := Materials3D.ground(Color("#5a6270"))
	var gravel := Materials3D.ground(Color("#cdb27a"))
	var fill: StandardMaterial3D = gravel if style == "gravel" else (tarmac if style == "asphalt" else Materials3D.ground(Color(String(cols[0]))))
	var strip: StandardMaterial3D = tarmac
	if style == "asphalt" and cols.size() > 0:
		strip = Materials3D.ground(Color(String(cols[0])))
	elif style == "painted" and cols.size() > 1:
		strip = Materials3D.ground(Color(String(cols[1])))
	for m: StandardMaterial3D in [fill, strip]:
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		if night:
			m.albedo_color = Color(0.5, 0.55, 0.68)
	var k := Track3D.KERB_W
	var strip_w := 3.0
	for s: float in [-1.0, 1.0]:
		for sharp: bool in [false, true]:
			var mask := func(i: int) -> bool: return t3.outside_side(i) == s and not (s == side and _pit_side_zone(i)) and _sharp(i) == sharp
			var a0 := w + k
			var a1 := a0 + strip_w
			var a2 := a0 + _runoff_w(sharp)
			if s > 0:
				_mesh(t3.band(a0, a1, _verge_lift(a0) + 0.06, _verge_lift(a1) + 0.06, 8.0, mask), strip)
				_mesh(t3.band(a1, a2, _verge_lift(a1) + 0.05, _verge_lift(a2) + 0.05, 8.0, mask), fill)
			else:
				_mesh(t3.band(-a1, -a0, _verge_lift(a1) + 0.06, _verge_lift(a0) + 0.06, 8.0, mask), strip)
				_mesh(t3.band(-a2, -a1, _verge_lift(a2) + 0.05, _verge_lift(a1) + 0.05, 8.0, mask), fill)


## Barreira de pneus (vermelho/branco) atrás da brita; no resto da volta, muro baixo com placas coloridas.
func _barriers() -> void:
	if street:  # muros com placas colados na pista, pneus no lado de fora das curvas e tela alta
		var fence := Materials3D.flat(Color(0.8, 0.84, 0.88, 0.3), 0.4)
		fence.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fence.cull_mode = BaseMaterial3D.CULL_DISABLED
		for s2: float in [-1.0, 1.0]:
			var off := s2 * (w + Track3D.KERB_W + 1.2)
			var plain := func(i: int) -> bool: return t3.outside_side(i) != s2 and not (s2 == side and _pit_side_zone(i))
			var tyre := func(i: int) -> bool: return t3.outside_side(i) == s2 and not (s2 == side and _pit_side_zone(i))
			var any := func(i: int) -> bool: return not (s2 == side and _pit_side_zone(i))
			_mesh(t3.wall_palette(off, 1.2, plain, AD_COLORS, 4), _vc)
			_mesh(t3.wall(off, 1.2, tyre, Color("#d42020"), Color("#f2f2f2")), _vc)
			var fm := _mesh(t3.wall(off, 3.2, any, Color.WHITE, Color.WHITE), fence)
			fm.position.y = 1.2
		return
	var k := Track3D.KERB_W
	for s: float in [-1.0, 1.0]:
		var tyres := func(i: int) -> bool: return t3.outside_side(i) == s and not (s == side and _pit_side_zone(i))
		var boards := func(i: int) -> bool: return t3.outside_side(i) != s and not (s == side and _pit_side_zone(i))
		var off := s * (w + k + (_runoff_w(false) + 1.0 if not runoff.is_empty() else 23.0))
		var mi := _mesh(t3.wall(off, 1.3, tyres, Color("#d42020"), Color("#f2f2f2")), _vc)
		mi.position.y = _verge_lift(off)
		var off2 := s * (w + (vw if real_map else 14.0))
		var mb := _mesh(t3.wall_palette(off2, 1.25, boards, AD_COLORS, 5), _vc)
		mb.position.y = _verge_lift(off2)


# --- pit lane --------------------------------------------------------------------------------------

func _pit_lane() -> void:
	var lane := t3.pit_strip(-Track3D.PIT_LANE_W / 2.0, Track3D.PIT_LANE_W / 2.0, 0.035)
	_mesh(lane, asphalt)
	var white := Materials3D.vertex_color(0.6)
	white.cull_mode = BaseMaterial3D.CULL_DISABLED
	var hw := Track3D.PIT_LANE_W / 2.0
	_mesh(t3.pit_strip(-hw, -hw + 0.35, 0.07), white)  # linha branca do lado da pista (contínua: não cruzar)
	_mesh(t3.pit_strip(hw - 0.35, hw, 0.07), white)
	# faixa de trabalho em frente às garagens (mais clara) e a faixa rápida
	var work := Materials3D.flat(Color("#5b5f66"), 0.9)
	work.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh(t3.pit_strip(0.5, hw - 0.4, 0.05, 0.99), work)
	_mesh(t3.pit_gore(0.06), _vc)  # diagonais zebradas de entrada e saída
	# muro do pit (branco com tela) só onde o pit lane já está separado
	var wall_at := side * (w + Track3D.PIT_GAP * 0.5)
	var sep := func(i: int) -> bool: return t3.pit_ramp(float(i) / t3.n) > 0.97
	_mesh(t3.wall(wall_at, 1.2, sep, Color("#eef0f2"), Color("#eef0f2")), _vc)
	var fence := Materials3D.flat(Color(0.85, 0.88, 0.9, 0.35), 0.4)
	fence.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fence.cull_mode = BaseMaterial3D.CULL_DISABLED
	var fm := _mesh(t3.wall(wall_at, 2.6, sep, Color.WHITE, Color.WHITE), fence)
	fm.position.y = 1.2
	# linhas de limite de velocidade (transversais) na entrada e na saída
	var line_mat := Materials3D.flat(Color("#f4f4f4"), 0.5)
	for f: float in [t3.track.pit_entry_frac + Track3D.PIT_RAMP_M / t3.track.length_m, t3.track.pit_exit_frac - Track3D.PIT_RAMP_M / t3.track.length_m]:
		var b := t3.basis_at(f)
		var c := t3.point_at(f) + b.x * t3.pit_offset(f)
		_box(Vector3(Track3D.PIT_LANE_W, 0.06, 0.6), Transform3D(b, c + Vector3.UP * 0.08), line_mat)


## Prédio dos boxes contínuo: base branca, portões escuros com a cor da equipe, andar de vidro e laje com beiral.
## Na linha de chegada, a torre de controle.
func _pit_building() -> void:
	var body := Materials3D.flat(Color("#eceef0"), 0.7)
	var door := Materials3D.flat(Color("#23262b"), 0.6)
	var glass := Materials3D.flat(Color("#3d5a73"), 0.15)
	glass.metallic = 0.5
	var roof := Materials3D.flat(Color("#b9bec4"), 0.9)
	if night:
		glass.emission_enabled = true
		glass.emission = Color("#ffd58a")
		glass.emission_energy_multiplier = 0.8
	var front := w + Track3D.PIT_GAP + Track3D.PIT_LANE_W + 2.0
	var depth := 18.0
	var bays := maxi(teams.size(), 1) * 2
	var bay_len := 12.0
	var start := -float(bays) * bay_len / 2.0
	for k in bays:
		var f := fposmod((start + (k + 0.5) * bay_len) / t3.track.length_m, 1.0)
		var b := t3.basis_at(f)
		var c := t3.point_at(f)
		var base := c + b.x * side * (front + depth / 2.0)
		var out := b.x * side  # do pit lane para fora
		var team: Dictionary = teams[(k >> 1) % teams.size()] if not teams.is_empty() else {"color": "#888888"}
		var stripe := Materials3D.flat(Color(team["color"]), 0.5)
		for part: Array in [
			[0.0, 4.5, Vector3(depth, 9.0, bay_len + 0.05), body],
			[-depth / 2.0 - 0.05, 2.5, Vector3(0.2, 5.0, bay_len - 2.0), door],
			[-depth / 2.0 - 0.1, 5.5, Vector3(0.2, 0.8, bay_len - 0.6), stripe],
			[-depth / 2.0 - 0.05, 7.7, Vector3(0.2, 2.0, bay_len - 0.4), glass],
			[-0.8, 9.2, Vector3(depth + 1.6, 0.35, bay_len + 0.05), roof],
		]:
			_box(part[2], Transform3D(b, base + out * float(part[0]) + Vector3.UP * float(part[1])), part[3])
	# torre de controle na linha de chegada
	var b0 := t3.basis_at(0.0)
	var tower := t3.point_at(0.0) + b0.x * side * (front + depth + 10.0)
	_box(Vector3(14.0, 22.0, 14.0), Transform3D(b0, tower + Vector3.UP * 11.0), body)
	_box(Vector3(15.0, 5.0, 15.0), Transform3D(b0, tower + Vector3.UP * 24.0), glass)
	_box(Vector3(17.0, 0.6, 17.0), Transform3D(b0, tower + Vector3.UP * 26.8), roof)
	# pórtico de largada sobre a pista (luzes)
	var gantry := Materials3D.flat(Color("#2b2e33"), 0.6)
	var g0 := t3.point_at(0.0)
	_box(Vector3(Track3D.WIDTH + 6.0, 1.2, 1.2), Transform3D(b0, g0 + Vector3.UP * 8.0), gantry)
	for s: float in [-1.0, 1.0]:
		_box(Vector3(0.8, 8.0, 0.8), Transform3D(b0, g0 + b0.x * s * (w + 2.5) + Vector3.UP * 4.0), gantry)


## Paddock atrás dos boxes: piso de concreto, fileiras de motorhomes (brancos com a cor da equipe) e caminhões.
func _paddock() -> void:
	var concrete := Materials3D.flat(Color("#73787e"), 0.95)
	concrete.metallic_specular = 0.1
	concrete.cull_mode = BaseMaterial3D.CULL_DISABLED
	var a := w + Track3D.PIT_GAP + Track3D.PIT_LANE_W + 1.0
	var b := a + PADDOCK_DEPTH
	var mask := func(i: int) -> bool: return _in_paddock(i)
	if side < 0:
		_mesh(t3.band(-b, -a, 0.03, 0.03, 10.0, mask), concrete)
	else:
		_mesh(t3.band(a, b, 0.03, 0.03, 10.0, mask), concrete)
	var white := Materials3D.flat(Color("#f4f5f6"), 0.5)
	var dark := Materials3D.flat(Color("#2c3036"), 0.4)
	var n_teams := teams.size()
	for k in n_teams:
		var team: Dictionary = teams[k]
		var col := Materials3D.flat(Color(team["color"]), 0.5)
		var along := (float(k) - n_teams / 2.0) * 26.0
		var f := fposmod(along / t3.track.length_m, 1.0)
		var bs := t3.basis_at(f)
		var c := t3.point_at(f)
		for row in 2:
			var off := a + 26.0 + row * 20.0
			var p := c + bs.x * side * off
			_box(Vector3(10.0, 4.2, 18.0), Transform3D(bs, p + Vector3.UP * 2.1), white)
			_box(Vector3(10.2, 0.9, 18.2), Transform3D(bs, p + Vector3.UP * 4.4), col)
			_box(Vector3(10.4, 0.15, 6.0), Transform3D(bs, p + Vector3.UP * 3.0 - bs.z * 11.0), dark)
		# caminhão da equipe no fundo
		var pt := c + bs.x * side * (a + 62.0)
		_box(Vector3(3.2, 4.0, 16.0), Transform3D(bs, pt + Vector3.UP * 2.0), col)


# --- arquibancadas, passarelas e grid ---------------------------------------------------------------

## Arquibancada coberta (três degraus de assentos coloridos, cobertura branca em pilares).
func _stand(b: Basis, base: Vector3, out: Vector3, length: float, col: Color) -> void:
	var seat := Materials3D.flat(col, 0.6)
	var conc := Materials3D.flat(Color("#c9cbcf"), 0.85)
	var roof := Materials3D.flat(Color("#f2f3f5"), 0.5)
	for tier in 4:
		var h := 1.4 + tier * 2.0
		_box(Vector3(3.2, h, length), Transform3D(b, base + out * (tier * 3.2) + Vector3.UP * h / 2.0), seat if tier > 0 else conc)
	_box(Vector3(15.0, 0.4, length + 2.0), Transform3D(b, base + out * 5.0 + Vector3.UP * 11.5), roof)
	for s: float in [-0.45, 0.0, 0.45]:
		_box(Vector3(0.5, 11.5, 0.5), Transform3D(b, base + out * 11.5 + b.z * (length * s) + Vector3.UP * 5.75), conc)


func _grandstands() -> void:
	var opp := -side
	var b0 := t3.basis_at(0.0)
	for k in 3:  # reta principal, do lado oposto aos boxes
		var f := fposmod((k - 1) * 70.0 / t3.track.length_m, 1.0)
		var b := t3.basis_at(f)
		var base := t3.point_at(f) + b.x * opp * (w + 18.0)
		_stand(b, base, b.x * opp, 62.0, STAND_COLORS[k % STAND_COLORS.size()])
	var _u := b0
	# nas curvas mais fechadas, do lado de fora, atrás da barreira de pneus
	var picks: Array = []
	var cand: Array = []
	for i in t3.n:
		if t3.curvature[i] > Track3D.SHARP_CORNER * 1.6 and not t3.in_pit_zone(i):
			cand.append([t3.curvature[i], i])
	cand.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	for c: Array in cand:
		var i: int = c[1]
		var far := true
		for p: int in picks:
			if absi(p - i) < t3.n / 8:
				far = false
		if far:
			picks.append(i)
		if picks.size() >= 4:
			break
	for idx in picks.size():
		var i: int = picks[idx]
		var f := float(i) / t3.n
		var s := t3.outside_side(i)
		if s == 0.0:
			continue
		var b := t3.basis_at(f)
		var base := t3.point_at(f) + b.x * s * (w + Track3D.KERB_W + 30.0) + Vector3.UP * _verge_lift(w + 30.0)
		_stand(b, base, b.x * s, 48.0, STAND_COLORS[(idx + 3) % STAND_COLORS.size()])


## Passarelas brancas sobre as maiores retas, com faixa de publicidade.
func _bridges() -> void:
	var best: Array = []
	var run := 0
	for i in t3.n * 2:
		var m := i % t3.n
		if t3.curvature[m] < 0.02 and not t3.in_pit_zone(m):
			run += 1
		else:
			if run > 30:
				best.append([run, (m - run / 2 + t3.n) % t3.n])
			run = 0
		if i >= t3.n and run == 0:
			break
	best.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var deck := Materials3D.flat(Color("#f2f3f5"), 0.5)
	for k in mini(best.size(), 2):
		var f := float(best[k][1]) / t3.n
		var b := t3.basis_at(f)
		var c := t3.point_at(f)
		var span := Track3D.WIDTH + 24.0
		_box(Vector3(span, 1.2, 4.0), Transform3D(b, c + Vector3.UP * 7.5), deck)
		_box(Vector3(span - 6.0, 1.6, 0.3), Transform3D(b, c + Vector3.UP * 7.4 + b.z * 2.1), Materials3D.flat(AD_COLORS[(k * 3) % AD_COLORS.size()], 0.5))
		for s: float in [-1.0, 1.0]:
			_box(Vector3(1.2, 7.0, 3.0), Transform3D(b, c + b.x * s * (span / 2.0 - 2.0) + Vector3.UP * 3.5), deck)


func _grid_marks() -> void:
	var grid_mat := Materials3D.flat(Color("#f2f2f2"), 0.6)
	for slot in 22:
		var d := -RaceSim.GRID_SPACING_M * slot - 5.0 - 2.0
		var f := fposmod(d, t3.track.length_m) / t3.track.length_m
		var b := t3.basis_at(f)
		var p := t3.point_at(f) + b.x * (RaceSim.GRID_LATERAL_M if slot % 2 == 0 else -RaceSim.GRID_LATERAL_M) + Vector3.UP * 0.09
		_box(Vector3(2.6, 0.05, 0.35), Transform3D(b, p), grid_mat)
		_box(Vector3(0.3, 0.05, 2.0), Transform3D(b, p + b.x * 1.15 + b.z * 1.0), grid_mat)
		_box(Vector3(0.3, 0.05, 2.0), Transform3D(b, p - b.x * 1.15 + b.z * 1.0), grid_mat)
	# linha de chegada quadriculada
	var chk_a := Materials3D.flat(Color("#f4f4f4"), 0.5)
	var chk_b := Materials3D.flat(Color("#1b1b1b"), 0.5)
	var b0 := t3.basis_at(0.0)
	var p0 := t3.point_at(0.0) + Vector3.UP * 0.1
	var cells := 14
	for r in 2:
		for c in cells:
			var x := -w + (c + 0.5) * Track3D.WIDTH / cells
			_box(Vector3(Track3D.WIDTH / cells, 0.05, 1.0), Transform3D(b0, p0 + b0.x * x + b0.z * (r - 0.5)), chk_a if (r + c) % 2 == 0 else chk_b)
