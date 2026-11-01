class_name Scenery3D
extends RefCounted
## Monta o cenário 3D de um circuito a partir do tema (dados do circuito): terreno que acompanha
## o relevo, água, árvores e prédios (instanciados com MultiMesh para rodar no celular),
## arquibancadas na reta principal e o marco visual do lugar. Determinístico por circuito.

const MARGIN := 700.0
const GRID := 72
const TRACK_CLEAR_M := 32.0

const TREE_THEMES := {"park": 0.55, "forest": 0.7, "lake": 0.4, "hills": 0.35, "mountains": 0.3, "river": 0.4, "airfield": 0.12, "prairie": 0.1}
const CITY_THEMES := {"city": 0.5, "oldcity": 0.45, "harbor": 0.55, "bay": 0.5, "strip": 0.55, "marina": 0.35, "coast": 0.35, "lake": 0.12}
const WATER_THEMES := ["lake", "harbor", "marina", "bay", "coast", "river", "dunes"]
const GROUND := {"desert": Color("#c9a970"), "dunes": Color("#d9c08a"), "city": Color("#6e6a60"), "oldcity": Color("#857a5e"),
	"strip": Color("#8a7a5c"), "harbor": Color("#706b62"), "bay": Color("#6a675f"), "marina": Color("#8c7e64")}

var t3: Track3D
var root := Node3D.new()
var night := false
var theme := "park"
var landmark := ""
var rng := RandomNumberGenerator.new()
var water_center := Vector3.INF
var water_radius := 0.0
var water_side := ""
var _box: AABB


func build(p_t3: Track3D, p_night: bool) -> Node3D:
	t3 = p_t3
	night = p_night
	theme = t3.track.scenery.get("theme", "park")
	landmark = t3.track.scenery.get("landmark", "")
	rng.seed = hash(t3.track.id)
	_box = t3.bounds_3d().grow(MARGIN)
	t3.build_field(_box, 48.0)
	_terrain()
	_water()
	_trees_and_buildings()
	_grandstands()
	_landmark()
	if night:
		_track_lights()
	return root


# --- terreno -------------------------------------------------------------------------

func _terrain() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var avg := 0.0
	for p in t3.center:
		avg += p.y
	avg /= t3.n
	var heights := PackedFloat32Array()
	var verts := PackedVector3Array()
	for gz in GRID + 1:
		for gx in GRID + 1:
			var p := Vector3(lerpf(_box.position.x, _box.end.x, float(gx) / GRID), 0.0, lerpf(_box.position.z, _box.end.z, float(gz) / GRID))
			var near := t3.field_at(p)
			# perto da pista o chão fica logo abaixo dela; longe, tende à altura média com leve ondulação
			var far_t := clampf((near.x - 30.0) / 450.0, 0.0, 1.0)
			var h := lerpf(near.y - 1.2, avg + sin(p.x / 230.0) * cos(p.z / 190.0) * 6.0, far_t)
			verts.append(Vector3(p.x, h, p.z))
	for gz in GRID:
		for gx in GRID:
			var i := gz * (GRID + 1) + gx
			var quad := [verts[i], verts[i + 1], verts[i + GRID + 2], verts[i + GRID + 1]]
			var nrm: Vector3 = (quad[1] - quad[0]).cross(quad[3] - quad[0]).normalized()
			if nrm.y < 0.0:
				nrm = -nrm
			for k in [0, 1, 2, 0, 2, 3]:
				st.set_normal(nrm)
				st.add_vertex(quad[k])
	var mesh := MeshInstance3D.new()
	mesh.mesh = st.commit()
	var mat := Materials3D.grass() if not GROUND.has(theme) else Materials3D.ground(GROUND[theme])
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if night:
		mat.albedo_color = Color(0.45, 0.48, 0.6)
	mesh.material_override = mat
	root.add_child(mesh)


func ground_height(p: Vector3) -> float:
	var near := t3.field_at(p)
	var avg := t3.bounds_3d().get_center().y
	var far_t := clampf((near.x - 30.0) / 450.0, 0.0, 1.0)
	return lerpf(near.y - 1.2, avg + sin(p.x / 230.0) * cos(p.z / 190.0) * 6.0, far_t)


# --- água ----------------------------------------------------------------------------

func _water() -> void:
	if not WATER_THEMES.has(theme):
		return
	var tb := t3.bounds_3d()
	if theme == "lake":
		# maior espaço livre dentro do contorno da pista (ex.: o lago de Interlagos)
		var best := -1.0
		for k in 400:
			var p := Vector3(rng.randf_range(tb.position.x, tb.end.x), 0, rng.randf_range(tb.position.z, tb.end.z))
			if not t3.inside(p):
				continue
			var d := t3.nearest(p, 4).x
			if d > best:
				best = d
				water_center = p
		water_radius = clampf(best - 18.0, 40.0, 220.0)
		var disc := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = water_radius
		cyl.bottom_radius = water_radius
		cyl.height = 0.4
		cyl.radial_segments = 40
		disc.mesh = cyl
		disc.scale = Vector3(1.35, 1.0, 0.8)
		water_center.y = ground_height(water_center) + 0.2
		disc.position = water_center
		disc.material_override = Materials3D.water()
		root.add_child(disc)
		return
	# mar/rio/porto: faixa de água no lado mais livre do mapa
	var sides := {"south": tb.end.z, "north": tb.position.z, "east": tb.end.x, "west": tb.position.x}
	water_side = ["south", "north", "east", "west"][rng.randi() % 4] if theme != "harbor" else "south"
	var plane := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	var size := Vector2(_box.size.x, _box.size.z)
	var pos := _box.get_center()
	match water_side:
		"south":
			size.y = _box.end.z - (tb.end.z + 60.0)
			pos.z = tb.end.z + 60.0 + size.y / 2.0
		"north":
			size.y = (tb.position.z - 60.0) - _box.position.z
			pos.z = _box.position.z + size.y / 2.0
		"east":
			size.x = _box.end.x - (tb.end.x + 60.0)
			pos.x = tb.end.x + 60.0 + size.x / 2.0
		"west":
			size.x = (tb.position.x - 60.0) - _box.position.x
			pos.x = _box.position.x + size.x / 2.0
	pm.size = size
	plane.mesh = pm
	pos.y = tb.position.y - 0.5
	plane.position = pos
	plane.material_override = Materials3D.water()
	root.add_child(plane)
	var _unused := sides


func _in_water(p: Vector3) -> bool:
	if water_center != Vector3.INF:
		var d := Vector2((p.x - water_center.x) / 1.35, (p.z - water_center.z) / 0.8)
		return d.length() < water_radius + 8.0
	var tb := t3.bounds_3d()
	match water_side:
		"south":
			return p.z > tb.end.z + 50.0
		"north":
			return p.z < tb.position.z - 50.0
		"east":
			return p.x > tb.end.x + 50.0
		"west":
			return p.x < tb.position.x - 50.0
	return false


# --- árvores e prédios ----------------------------------------------------------------

func _trees_and_buildings() -> void:
	var tree_density: float = TREE_THEMES.get(theme, 0.08)
	var city_density: float = CITY_THEMES.get(theme, 0.0)
	var trees: Array[Transform3D] = []
	var tree_cols: Array[Color] = []
	var builds: Array[Transform3D] = []
	var step := 26.0
	var z := _box.position.z
	while z < _box.end.z:
		var x := _box.position.x
		while x < _box.end.x:
			var p := Vector3(x + rng.randf_range(-9, 9), 0, z + rng.randf_range(-9, 9))
			x += step
			var near := t3.field_at(p, true)
			if near.x < TRACK_CLEAR_M or _in_water(p):
				continue
			var cluster := sin(p.x / 140.0 + 1.3) * cos(p.z / 110.0) + rng.randf_range(-0.35, 0.35)
			var y := ground_height(p)
			if city_density > 0.0 and near.x > 60.0 and cluster < -0.1 and rng.randf() < city_density:
				var hgt := rng.randf_range(12.0, 38.0) * (1.6 if theme in ["strip", "bay", "city"] else 1.0)
				var w := rng.randf_range(14.0, 26.0)
				var b := Basis().scaled(Vector3(w, hgt, rng.randf_range(14.0, 26.0))).rotated(Vector3.UP, rng.randf() * 0.4)
				builds.append(Transform3D(b, Vector3(p.x, y + hgt / 2.0, p.z)))
			elif tree_density > 0.0 and cluster > 0.6 - tree_density * 1.6:
				for k in 3:
					var q := p + Vector3(rng.randf_range(-10, 10), 0, rng.randf_range(-10, 10))
					var s := rng.randf_range(0.8, 1.5)
					trees.append(Transform3D(Basis().scaled(Vector3(s, s * rng.randf_range(0.9, 1.3), s)), Vector3(q.x, ground_height(q), q.z)))
					var g := Color("#2c4a22").lerp(Color("#4d6a30"), rng.randf())
					tree_cols.append(g.darkened(0.5) if night else g)
		z += step
	if not trees.is_empty():
		root.add_child(_multimesh(_tree_mesh(), trees, tree_cols, Materials3D.vertex_color(0.9)))
	if not builds.is_empty():
		var box := BoxMesh.new()
		box.size = Vector3.ONE
		var cols: Array[Color] = []
		var palette := [Color("#c9b99a"), Color("#a9a39a"), Color("#b3826a"), Color("#d8d2c4"), Color("#8f939a"), Color("#c4a882")]
		for i in builds.size():
			cols.append(palette[rng.randi() % palette.size()])
		var mat := Materials3D.facade(Color("#ffffff") if theme != "strip" else Color("#9fb0d0"), night)
		mat.vertex_color_use_as_albedo = true  # cor por prédio (MultiMesh) multiplica a fachada
		root.add_child(_multimesh(box, builds, cols, mat))


func _tree_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 7
	for i in seg:  # copa (cone baixo + topo)
		var a0 := TAU * i / seg
		var a1 := TAU * (i + 1) / seg
		var p0 := Vector3(cos(a0) * 4.5, 3.0, sin(a0) * 4.5)
		var p1 := Vector3(cos(a1) * 4.5, 3.0, sin(a1) * 4.5)
		var top := Vector3(0, 12.0, 0)
		var nrm := (p1 - p0).cross(top - p0).normalized()
		for v in [p0, top, p1]:
			st.set_color(Color.WHITE)
			st.set_normal(-nrm if nrm.y < 0 else nrm)
			st.add_vertex(v)
		for v in [p0, p1, Vector3(0, 3.0, 0)]:
			st.set_color(Color.WHITE)
			st.set_normal(Vector3.DOWN)
			st.add_vertex(v)
	for i in 4:  # tronco
		var a0 := TAU * i / 4
		var a1 := TAU * (i + 1) / 4
		var q := [Vector3(cos(a0) * 0.5, 0, sin(a0) * 0.5), Vector3(cos(a1) * 0.5, 0, sin(a1) * 0.5),
			Vector3(cos(a1) * 0.5, 3.2, sin(a1) * 0.5), Vector3(cos(a0) * 0.5, 3.2, sin(a0) * 0.5)]
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_color(Color("#5a4630"))
			st.set_normal(Vector3(cos(a0), 0, sin(a0)))
			st.add_vertex(q[k])
	return st.commit()


func _multimesh(mesh: Mesh, xforms: Array[Transform3D], colors: Array[Color], mat: Material) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		mm.set_instance_color(i, colors[i])
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	inst.material_override = mat
	return inst


# --- arquibancadas, marco e iluminação -----------------------------------------------

func _grandstands() -> void:
	var mat := Materials3D.flat(Color("#c9c3b5"), 0.8)
	var seats := Materials3D.flat(Color("#2f5d9b"), 0.6)
	for k in range(-6, 7, 3):
		var f := float(k) / t3.n * 2.0
		var c := t3.point_at(f)
		var b := t3.basis_at(f)
		var side := b.x * -1.0  # lado esquerdo da reta principal
		var pos := c + side * (Track3D.WIDTH / 2.0 + 14.0)
		for tier in 3:
			var stand := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(10.0 - tier * 3.0, 3.0 + tier * 3.0, 30.0)
			stand.mesh = bm
			stand.material_override = seats if tier > 0 else mat
			stand.transform = Transform3D(b, pos + side * (tier * 3.0) + Vector3.UP * (1.5 + tier * 1.5))
			root.add_child(stand)


func _landmark() -> void:
	var tb := t3.bounds_3d()
	var spot := Vector3(tb.position.x - 160.0, 0, tb.get_center().z)
	match landmark:
		"skyline", "towers":
			var facade := Materials3D.facade(Color("#a8a49a"), night)
			for i in 14:
				var tower := MeshInstance3D.new()
				var bm := BoxMesh.new()
				var h := rng.randf_range(70.0, 170.0)
				bm.size = Vector3(rng.randf_range(22, 34), h, rng.randf_range(22, 34))
				tower.mesh = bm
				var p := Vector3(tb.position.x - 260.0 + rng.randf_range(-120, 120), 0, tb.position.z + rng.randf_range(0, tb.size.z))
				tower.position = Vector3(p.x, ground_height(p) + h / 2.0, p.z)
				tower.material_override = facade
				root.add_child(tower)
		"ferris_wheel":
			var wheel := MeshInstance3D.new()
			var torus := TorusMesh.new()
			torus.inner_radius = 38.0
			torus.outer_radius = 41.0
			wheel.mesh = torus
			wheel.rotation_degrees = Vector3(90, 0, 0)
			wheel.position = Vector3(spot.x, ground_height(spot) + 44.0, spot.z)
			wheel.material_override = Materials3D.flat(Color("#e9e3d6"), 0.5)
			root.add_child(wheel)
		"sphere":
			var ball := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 55.0
			sm.height = 110.0
			ball.mesh = sm
			ball.position = Vector3(spot.x, ground_height(spot) + 55.0, spot.z)
			var m := Materials3D.flat(Color("#f5a623"), 0.4)
			m.emission_enabled = night
			m.emission = Color("#f5a623")
			m.emission_energy_multiplier = 1.5
			ball.material_override = m
			root.add_child(ball)
		"mountains", "hills":
			for i in 5:
				var mtn := MeshInstance3D.new()
				var cm := CylinderMesh.new()
				cm.top_radius = 0.0
				cm.bottom_radius = rng.randf_range(220, 380)
				cm.height = rng.randf_range(140, 260)
				cm.radial_segments = 7
				mtn.mesh = cm
				var p := Vector3(_box.position.x + rng.randf() * _box.size.x, 0, _box.position.z - 200.0)
				mtn.position = p + Vector3.UP * cm.height / 2.0
				mtn.material_override = Materials3D.flat(Color("#6e7a5a"), 1.0)
				root.add_child(mtn)


## Corridas noturnas: postes de luz (emissivos) ao longo da pista.
func _track_lights() -> void:
	var xforms: Array[Transform3D] = []
	var cols: Array[Color] = []
	var i := 0
	while i < t3.n:
		var side := 1.0 if (i / 12) % 2 == 0 else -1.0
		var p := t3.center[i] + t3.right[i] * side * (Track3D.WIDTH / 2.0 + 6.0)
		xforms.append(Transform3D(Basis(), p + Vector3.UP * 6.0))
		cols.append(Color.WHITE)
		i += 12
	var pole := BoxMesh.new()
	pole.size = Vector3(0.6, 12.0, 0.6)
	var m := Materials3D.flat(Color("#fff2c4"), 0.5)
	m.emission_enabled = true
	m.emission = Color("#ffe3a0")
	m.emission_energy_multiplier = 3.0
	root.add_child(_multimesh(pole, xforms, cols, m))
