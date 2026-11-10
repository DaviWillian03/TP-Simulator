class_name Landmarks3D
extends RefCounted
## Marcos visuais que fazem reconhecer cada circuito de longe (lista do usuário de 2026-11-09). Todos são formas
## simples, originais e sem logotipos (o "touro" é uma escultura genérica de bronze, sem marca). A lista de cada pista
## fica em scenery.landmarks nos dados do circuito. Os lugares são reservados antes das árvores (clear_zones).

var sc: Scenery3D
var t3: Track3D
var root: Node3D
var night := false
var rng := RandomNumberGenerator.new()
var _spots: Dictionary = {}  ## chave do marco -> ponto no chão
## Ampliação estilizada: no celular, na vista geral (a 3–6 km), o marco precisa aparecer.
const SCALE := {"ferris_wheel": 2.3, "bull": 3.4, "sphere": 1.8, "cota_tower": 2.3, "flame_towers": 1.6, "mbs": 1.5,
	"biosphere": 2.2, "stadium": 1.5, "banking": 1.0, "w_hotel": 1.4, "wing_stand": 1.0}


func _init(p_sc: Scenery3D) -> void:
	sc = p_sc
	t3 = sc.t3
	root = sc.root
	night = sc.night
	rng.seed = hash(t3.track.id + "landmarks")


static func keys_of(track: TrackModel) -> Array:
	var list: Array = track.scenery.get("landmarks", [])
	if list.is_empty() and String(track.scenery.get("landmark", "")) != "":
		list = [track.scenery["landmark"]]
	return list


## Onde fica cada marco (perto da pista, do lado oposto aos boxes, sem cair em cima dela). Reserva o espaço.
func plan(keys: Array) -> void:
	var opp := -t3.track.pit_side
	var anchors := {"bull": [0.35, opp, 150.0, 70.0], "cota_tower": [0.03, opp, 170.0, 45.0], "ferris_wheel": [0.5, opp, 170.0, 60.0],
		"sphere": [0.08, opp, 190.0, 70.0], "flame_towers": [0.6, opp, 260.0, 80.0], "mbs": [0.15, opp, 230.0, 90.0],
		"biosphere": [0.45, opp, 170.0, 55.0], "stadium": [0.7, opp, 210.0, 120.0], "banking": [0.25, opp, 330.0, 260.0],
		"w_hotel": [0.9, opp, 120.0, 80.0], "wing_stand": [0.0, opp, 60.0, 50.0]}
	for k: String in keys:
		if not anchors.has(k):
			continue
		var a: Array = anchors[k]
		var sk: float = SCALE.get(k, 1.0)
		var p := _free_spot(float(a[0]), float(a[1]), float(a[2]) * (1.0 + (sk - 1.0) * 0.5), float(a[3]) * sk)
		_spots[k] = p
		sc.clear_zones.append(Vector4(p.x, 0, p.z, float(a[3]) * sk))


## Ponto no chão a ~dist metros da pista na fração dada; se cair perto de outro trecho, procura em volta.
func _free_spot(frac: float, side: float, dist: float, radius: float) -> Vector3:
	for k in 24:
		var f := fposmod(frac + k * 0.041, 1.0)
		var s := side if k % 2 == 0 else -side
		var b := t3.basis_at(f)
		var p := t3.point_at(f) + b.x * s * dist
		if t3.field_at(p, true).x > radius * 0.75 + 20.0:
			return Vector3(p.x, sc.ground_height(p), p.z)
	var tb := t3.bounds_3d()
	var q := Vector3(tb.position.x - dist, 0, tb.get_center().z)
	return Vector3(q.x, sc.ground_height(q), q.z)


func build(keys: Array) -> void:
	var main_root := root
	for k: String in keys:
		var holder := Node3D.new()  # cada marco num nó próprio, ampliado em volta do seu ponto
		main_root.add_child(holder)
		root = holder
		if _spots.has(k):
			var sk: float = SCALE.get(k, 1.0)
			var p: Vector3 = _spots[k]
			holder.transform = Transform3D(Basis.from_scale(Vector3.ONE * sk), p * (1.0 - sk))
		match k:
			"ferris_wheel":
				_ferris_wheel(_spots[k])
			"bull":
				_bull(_spots[k])
			"sphere":
				_sphere(_spots[k])
			"cota_tower":
				_cota_tower(_spots[k])
			"flame_towers":
				_flame_towers(_spots[k])
			"mbs":
				_mbs(_spots[k])
			"biosphere":
				_biosphere(_spots[k])
			"stadium":
				_stadium(_spots[k])
			"banking":
				_banking(_spots[k])
			"w_hotel":
				_w_hotel(_spots[k])
			"wing_stand":
				_wing_stand(_spots[k])
			"palms":
				_palms()
			"dunes":
				_dunes()
			"strip_hotels":
				_strip_hotels()
			"floodlights":
				_floodlights()
	root = main_root


# --- peças ---------------------------------------------------------------------------------------------------

func _mat(c: Color, rough := 0.6, emit := 0.0) -> StandardMaterial3D:
	var m := Materials3D.flat(c, rough)
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	return m


func _add(mesh: Mesh, xf: Transform3D, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = xf
	root.add_child(mi)
	return mi


func _box(size: Vector3, xf: Transform3D, mat: Material) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	return _add(bm, xf, mat)


func _cyl(r_top: float, r_bot: float, h: float, xf: Transform3D, mat: Material, seg := 16) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bot
	cm.height = h
	cm.radial_segments = seg
	return _add(cm, xf, mat)


## Base virada para a pista (o marco "olha" para quem está na pista).
func _facing(p: Vector3) -> Basis:
	var near := t3.bounds_3d().get_center()
	var d := Vector3(near.x - p.x, 0, near.z - p.z)
	if d.length() < 1.0:
		return Basis()
	return Basis.looking_at(d.normalized(), Vector3.UP)


# --- marcos --------------------------------------------------------------------------------------------------

## Roda-gigante (Suzuka, Singapura): aro, raios, gôndolas coloridas e cavaletes em A.
func _ferris_wheel(p: Vector3) -> void:
	var b := _facing(p)  # a roda fica de frente para a pista
	var white := _mat(Color("#eef0f3"), 0.45, 0.6 if night else 0.0)
	var c := p + Vector3.UP * 48.0
	var torus := TorusMesh.new()
	torus.inner_radius = 39.0
	torus.outer_radius = 41.5
	torus.rings = 48
	_add(torus, Transform3D(b * Basis(Vector3.RIGHT, PI / 2.0), c), white)
	for k in 12:
		var a := TAU * k / 12.0
		var spoke := Basis(b.z, a) * b
		_box(Vector3(0.8, 40.0, 0.8), Transform3D(spoke, c + spoke.y * 20.0), white)
	var cols := [Color("#e8392e"), Color("#2f6fd0"), Color("#f2b705"), Color("#19a3a3"), Color("#7a4fd6"), Color("#ff7a00")]
	for k in 24:
		var a := TAU * k / 24.0
		var pos := c + (b.x * cos(a) + Vector3.UP * sin(a)) * 40.5 + Vector3.DOWN * 3.0
		_box(Vector3(3.2, 3.6, 3.2), Transform3D(b, pos), _mat(cols[k % cols.size()], 0.5, 0.8 if night else 0.0))
	for s: float in [-1.0, 1.0]:
		for t: float in [-1.0, 1.0]:
			var leg := Basis(b.x, t * 0.22) * b
			_box(Vector3(1.6, 52.0, 1.6), Transform3D(leg, p + b.z * s * 5.0 + b.x * t * 8.0 + Vector3.UP * 24.0), white)
	_box(Vector3(30.0, 4.0, 14.0), Transform3D(b, p + Vector3.UP * 2.0), _mat(Color("#c9cbcf")))


## Escultura de touro (genérica, bronze): corpo, cabeça baixa de investida, chifres, pernas e pedestal de pedra.
func _bull(p: Vector3) -> void:
	var b := _facing(p)
	var bronze := _mat(Color("#8c5a2b"), 0.35)
	bronze.metallic = 0.7
	var horn := _mat(Color("#e9e1cf"), 0.4)
	var rock := _mat(Color("#7d7a73"), 0.95)
	_box(Vector3(26.0, 8.0, 34.0), Transform3D(b, p + Vector3.UP * 4.0), rock)
	var base := p + Vector3.UP * 8.0
	_box(Vector3(13.0, 13.0, 30.0), Transform3D(b * Basis(Vector3.RIGHT, 0.08), base + Vector3.UP * 17.0), bronze)  # corpo
	_box(Vector3(14.5, 11.0, 12.0), Transform3D(b, base + Vector3.UP * 20.0 + b.z * 9.0), bronze)  # cernelha/ombros
	_box(Vector3(8.5, 8.0, 10.0), Transform3D(b * Basis(Vector3.RIGHT, 0.55), base + Vector3.UP * 12.5 - b.z * 19.0), bronze)  # cabeça baixa
	for s: float in [-1.0, 1.0]:
		var hb := b * Basis(Vector3.FORWARD, s * 1.0) * Basis(Vector3.RIGHT, -0.5)
		_cyl(0.2, 1.4, 9.0, Transform3D(hb, base + Vector3.UP * 17.0 - b.z * 20.0 + b.x * s * 7.0), horn, 8)
		for f: float in [-1.0, 1.0]:
			_box(Vector3(3.2, 12.0, 3.2), Transform3D(b * Basis(Vector3.RIGHT, f * 0.25), base + Vector3.UP * 6.0 + b.x * s * 4.5 + b.z * f * 10.0), bronze)
	_box(Vector3(1.2, 1.2, 12.0), Transform3D(b * Basis(Vector3.RIGHT, -0.6), base + Vector3.UP * 20.0 + b.z * 19.0), bronze)  # rabo


## Esfera gigante de telão (Las Vegas): acesa, com faixas de cor.
func _sphere(p: Vector3) -> void:
	var sm := SphereMesh.new()
	sm.radius = 58.0
	sm.height = 116.0
	sm.radial_segments = 32
	sm.rings = 16
	var img := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 64:
			var hue := fposmod(float(x) / 64.0 + float(y) / 90.0, 1.0)
			img.set_pixel(x, y, Color.from_hsv(hue, 0.75, 1.0))
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.emission_enabled = true
	m.emission_texture = m.albedo_texture
	m.emission_energy_multiplier = 1.6 if night else 0.7
	_add(sm, Transform3D(Basis(), p + Vector3.UP * 60.0), m)


## Torre de observação branca com cabos vermelhos em leque (Austin).
func _cota_tower(p: Vector3) -> void:
	var white := _mat(Color("#f2f3f5"), 0.4)
	var red := _mat(Color("#d42020"), 0.5, 0.6 if night else 0.0)
	_cyl(2.5, 4.0, 76.0, Transform3D(Basis(), p + Vector3.UP * 38.0), white)
	_cyl(9.0, 7.0, 6.0, Transform3D(Basis(), p + Vector3.UP * 70.0), _mat(Color("#33414d"), 0.15))
	_cyl(10.0, 10.0, 1.0, Transform3D(Basis(), p + Vector3.UP * 73.5), white)
	for k in 14:
		var a := TAU * k / 14.0
		var out := Vector3(cos(a), 0, sin(a))
		var top := p + Vector3.UP * 66.0
		var bot := p + out * 22.0
		var mid := (top + bot) / 2.0
		var dir := (top - bot).normalized()
		var bb := Basis.looking_at(dir, out.cross(dir) if absf(dir.y) < 0.99 else Vector3.FORWARD)
		_box(Vector3(0.6, 0.6, top.distance_to(bot)), Transform3D(bb, mid), red)


## Três torres em forma de chama, de vidro (Baku); à noite acendem em laranja.
func _flame_towers(p: Vector3) -> void:
	var glass := _mat(Color("#3d6a8f"), 0.12, 0.0)
	glass.metallic = 0.6
	if night:
		glass = _mat(Color("#ff7a1a"), 0.3, 2.2)
	var b := _facing(p)
	for k in 3:
		var off := b.x * (k - 1) * 48.0 + b.z * (absf(k - 1) * 22.0)
		var h := 150.0 if k == 1 else 130.0
		var t := _cyl(4.0, 22.0, h, Transform3D(Basis(), p + off + Vector3.UP * h / 2.0), glass, 12)
		t.scale = Vector3(1.0, 1.0, 0.75)


## Três torres com a "prancha de barco" em cima (Singapura).
func _mbs(p: Vector3) -> void:
	var b := _facing(p).rotated(Vector3.UP, PI / 2.0)
	var facade := Materials3D.facade(Color("#c9d4dc"), night)
	for k in 3:
		_box(Vector3(26.0, 180.0, 14.0), Transform3D(b * Basis(Vector3.FORWARD, 0.05), p + b.x * (k - 1) * 36.0 + Vector3.UP * 90.0), facade)
	_box(Vector3(130.0, 8.0, 32.0), Transform3D(b, p + b.x * 8.0 + Vector3.UP * 186.0), _mat(Color("#e9eef2"), 0.4))
	_box(Vector3(118.0, 3.0, 24.0), Transform3D(b, p + b.x * 8.0 + Vector3.UP * 191.0), _mat(Color("#3f8f5a"), 0.8))


## Domo geodésico translúcido (Montreal).
func _biosphere(p: Vector3) -> void:
	var sm := SphereMesh.new()
	sm.radius = 38.0
	sm.height = 76.0
	sm.radial_segments = 14
	sm.rings = 8
	var m := _mat(Color(0.88, 0.92, 0.95, 0.55), 0.2)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_add(sm, Transform3D(Basis(), p + Vector3.UP * 28.0), m)
	var frame := _mat(Color("#dfe4e8"), 0.4)
	var wire := SphereMesh.new()
	wire.radius = 38.4
	wire.height = 76.8
	wire.radial_segments = 14
	wire.rings = 8
	var mi := _add(wire, Transform3D(Basis(), p + Vector3.UP * 28.0), frame)
	frame.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = frame
	frame.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	frame.albedo_color.a = 0.25


## Estádio oval (Miami, Cidade do México): arquibancada em anel, gramado no meio e cobertura.
func _stadium(p: Vector3) -> void:
	var outer := CylinderMesh.new()
	outer.top_radius = 95.0
	outer.bottom_radius = 80.0
	outer.height = 26.0
	outer.radial_segments = 32
	var mi := _add(outer, Transform3D(Basis(), p + Vector3.UP * 13.0), _mat(Color("#cfd3d8"), 0.7))
	mi.scale = Vector3(1.0, 1.0, 0.72)
	var seats := CylinderMesh.new()
	seats.top_radius = 88.0
	seats.bottom_radius = 58.0
	seats.height = 0.6
	seats.radial_segments = 32
	var ms := _add(seats, Transform3D(Basis(), p + Vector3.UP * 26.2), _mat(Color("#e05a2b"), 0.6))
	ms.scale = Vector3(1.0, 1.0, 0.72)
	var field := CylinderMesh.new()
	field.top_radius = 56.0
	field.bottom_radius = 56.0
	field.height = 0.5
	field.radial_segments = 32
	var mf := _add(field, Transform3D(Basis(), p + Vector3.UP * 26.4), _mat(Color("#3f8a2e"), 1.0))
	mf.scale = Vector3(1.0, 1.0, 0.72)


## Antigo oval de concreto com as curvas inclinadas (Monza).
func _banking(p: Vector3) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 64
	var ax := 210.0
	var az := 120.0
	for k in seg:
		var a0 := TAU * k / seg
		var a1 := TAU * (k + 1) / seg
		var bank := func(a: float) -> float: return 6.0 + 7.0 * absf(cos(a))  # mais inclinado nas cabeceiras
		var q := [Vector3(cos(a0) * ax, 0.6, sin(a0) * az), Vector3(cos(a1) * ax, 0.6, sin(a1) * az),
			Vector3(cos(a1) * (ax + 16.0), bank.call(a1), sin(a1) * (az + 16.0)), Vector3(cos(a0) * (ax + 16.0), bank.call(a0), sin(a0) * (az + 16.0))]
		for i in [0, 1, 2, 0, 2, 3]:
			st.set_normal(Vector3.UP)
			st.add_vertex(q[i])
	st.generate_normals()
	var m := _mat(Color("#b9b5ab"), 0.9)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_add(st.commit(), Transform3D(_facing(p), p), m)


## Hotel com casca de vidro e treliça sobre a pista (Abu Dhabi).
func _w_hotel(p: Vector3) -> void:
	var b := _facing(p)
	var facade := Materials3D.facade(Color("#d9e2ea"), night)
	for s: float in [-1.0, 1.0]:
		var bm := _cyl(26.0, 26.0, 46.0, Transform3D(b, p + b.x * s * 46.0 + Vector3.UP * 23.0), facade, 20)
		bm.scale = Vector3(1.0, 1.0, 0.6)
	var shell := _mat(Color(0.75, 0.85, 1.0, 0.45) if not night else Color(0.6, 0.4, 1.0, 0.7), 0.2, 1.5 if night else 0.0)
	shell.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_box(Vector3(170.0, 4.0, 70.0), Transform3D(b * Basis(Vector3.FORWARD, 0.04), p + Vector3.UP * 54.0), shell)


## Arquibancada com duas grandes "asas" de cobertura (Xangai), atrás da reta principal.
func _wing_stand(p: Vector3) -> void:
	var b := t3.basis_at(0.0)
	var conc := _mat(Color("#d7d9dc"), 0.7)
	var seats := _mat(Color("#2f6fd0"), 0.6)
	var wing := _mat(Color("#f4f5f7"), 0.4)
	for s: float in [-1.0, 1.0]:
		var c := p + b.z * s * 70.0
		_box(Vector3(30.0, 22.0, 90.0), Transform3D(b, c + Vector3.UP * 11.0), conc)
		_box(Vector3(26.0, 1.0, 86.0), Transform3D(b * Basis(Vector3.FORWARD, 0.35 * -t3.track.pit_side), c + Vector3.UP * 16.0), seats)
		_box(Vector3(70.0, 2.0, 95.0), Transform3D(b * Basis(Vector3.FORWARD, 0.18 * t3.track.pit_side), c + Vector3.UP * 34.0), wing)


## Palmeiras na avenida em volta (Albert Park, Miami, Abu Dhabi).
func _palms() -> void:
	var trunk := BoxMesh.new()
	trunk.size = Vector3(0.9, 14.0, 0.9)
	var leaf := BoxMesh.new()
	leaf.size = Vector3(1.6, 0.4, 9.0)
	var tx: Array[Transform3D] = []
	var lx: Array[Transform3D] = []
	var tc: Array[Color] = []
	var lc: Array[Color] = []
	var i := 0
	while i < t3.n:
		for s: float in [-1.0, 1.0]:
			if s == t3.track.pit_side and t3.in_pit_zone(i):
				continue
			var p := t3.center[i] + t3.right[i] * s * (Track3D.WIDTH / 2.0 + 44.0)
			if t3.field_at(p, true).x < 36.0:
				continue
			p.y = sc.ground_height(p)
			var tilt := Basis(Vector3.FORWARD, rng.randf_range(-0.12, 0.12))
			tx.append(Transform3D(tilt, p + Vector3.UP * 7.0))
			tc.append(Color("#8a6a45"))
			for k in 6:
				var a := TAU * k / 6.0 + rng.randf() * 0.4
				var lb := Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, 0.35)
				lx.append(Transform3D(lb, p + tilt.y * 14.0 + Basis(Vector3.UP, a).z * -3.5))
				lc.append(Color("#3d8a2a").lerp(Color("#6aa83f"), rng.randf()))
		i += 9
	if not tx.is_empty():
		root.add_child(sc.make_multimesh(trunk, tx, tc, Materials3D.vertex_color(0.9)))
		root.add_child(sc.make_multimesh(leaf, lx, lc, Materials3D.vertex_color(0.9)))


## Dunas de areia em volta (Zandvoort).
func _dunes() -> void:
	var sand := _mat(Color("#dcc58e"), 1.0)
	var grass := _mat(Color("#8a9a5a"), 1.0)
	var tb := t3.bounds_3d()
	for k in 26:
		var p := Vector3(rng.randf_range(tb.position.x - 300, tb.end.x + 300), 0, rng.randf_range(tb.position.z - 300, tb.end.z + 300))
		if t3.field_at(p, true).x < 90.0 or sc.in_water(p):
			continue
		var sm := SphereMesh.new()
		sm.radius = rng.randf_range(40.0, 90.0)
		sm.height = sm.radius * 0.5
		sm.radial_segments = 12
		sm.rings = 6
		var mi := _add(sm, Transform3D(Basis(Vector3.UP, rng.randf() * TAU), Vector3(p.x, sc.ground_height(p) - 2.0, p.z)), sand if rng.randf() < 0.6 else grass)
		mi.scale = Vector3(1.6, 1.0, 1.0)


## Hotéis altos com faixas de néon ao longo de um lado (Las Vegas).
func _strip_hotels() -> void:
	var tb := t3.bounds_3d()
	var neon := [Color("#ff2fa8"), Color("#2fe0ff"), Color("#ffd02f"), Color("#7a4fff"), Color("#2fff8a")]
	for k in 12:
		var x := tb.position.x - 120.0 - (k % 2) * 90.0
		var z := tb.position.z + k * tb.size.z / 11.0
		var p := Vector3(x, 0, z)
		var y := sc.ground_height(p)
		var h := rng.randf_range(90.0, 190.0)
		_box(Vector3(46.0, h, 34.0), Transform3D(Basis(), Vector3(x, y + h / 2.0, z)), Materials3D.facade(Color("#d9d2c4"), night))
		_box(Vector3(47.0, 4.0, 35.0), Transform3D(Basis(), Vector3(x, y + h - 6.0, z)), _mat(neon[k % neon.size()], 0.4, 2.0 if night else 0.8))


## Torres de iluminação altas em volta da pista (Lusail, corridas noturnas).
func _floodlights() -> void:
	var pole := _mat(Color("#9aa0a6"), 0.5)
	var lamp := _mat(Color("#fff6d8"), 0.3, 4.0 if night else 0.5)
	var i := 0
	while i < t3.n:
		var s := 1.0 if (i / 40) % 2 == 0 else -1.0
		if not (s == t3.track.pit_side and t3.in_pit_zone(i)):
			var p := t3.center[i] + t3.right[i] * s * (Track3D.WIDTH / 2.0 + 30.0)
			p.y = sc.ground_height(p)
			_box(Vector3(1.4, 40.0, 1.4), Transform3D(Basis(), p + Vector3.UP * 20.0), pole)
			_box(Vector3(8.0, 4.0, 1.6), Transform3D(t3.basis_at(float(i) / t3.n), p + Vector3.UP * 41.0), lamp)
		i += 20
