class_name CarShowcase3D
extends Node3D
## Carro de F1 simples em 3D, montado em código e ORIGINAL (2026-11-13): bico, chassi, laterais, assoalho, asas, halo,
## capacete e rodas, com a pintura da equipe (cor principal + secundária). Usado no pedestal da tela inicial. Unidades em
## metros (~5,6 m de comprimento), frente para -Z.

var c1 := Color("#1868DB")
var c2 := Color.WHITE


static func make(team: Dictionary) -> CarShowcase3D:
	var car := CarShowcase3D.new()
	car.c1 = Color(String(team.get("color", "#1868DB")))
	car.c2 = Color(String(team.get("color2", "#ffffff")))
	if car.c2.get_luminance() < 0.12 and car.c1.get_luminance() < 0.12:
		car.c2 = Color("#d0d4da")
	car._build()
	return car


func _mat(col: Color, metal := 0.35, rough := 0.35) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = metal
	m.roughness = rough
	return m


func _box(size: Vector3, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	add_child(mi)
	return mi


## Peça afunilada (prisma de 8 vértices): largura/altura na traseira (z1) e na frente (z0).
func _taper(w1: float, h1: float, z1: float, w0: float, h0: float, z0: float, y: float, mat: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var b := [Vector3(-w1, y, z1), Vector3(w1, y, z1), Vector3(w1, y + h1, z1), Vector3(-w1, y + h1, z1),
		Vector3(-w0, y, z0), Vector3(w0, y, z0), Vector3(w0, y + h0, z0), Vector3(-w0, y + h0, z0)]
	for f: Array in [[0, 1, 2, 3], [5, 4, 7, 6], [4, 0, 3, 7], [1, 5, 6, 2], [3, 2, 6, 7], [4, 5, 1, 0]]:
		for k: int in [0, 1, 2, 0, 2, 3]:
			st.add_vertex(b[f[k]])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	add_child(mi)


func _build() -> void:
	var body := _mat(c1)
	var accent := _mat(c2)
	var carbon := _mat(Color("#15171b"), 0.2, 0.6)
	var tyre := _mat(Color("#121314"), 0.0, 0.85)
	var rim := _mat(Color("#2a2d33"), 0.7, 0.3)
	# assoalho (carbono) e chassi
	_box(Vector3(1.6, 0.06, 3.4), Vector3(0, 0.08, 0.3), carbon)
	_taper(0.42, 0.55, 1.4, 0.16, 0.22, -1.9, 0.12, body)  # chassi + bico
	_taper(0.16, 0.22, -1.9, 0.07, 0.12, -2.55, 0.12, accent)  # ponta do bico
	# laterais (sidepods) afunilando para trás
	for s: float in [-1.0, 1.0]:
		var sp := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.42, 0.42, 1.7)
		sp.mesh = bm
		sp.material_override = body
		sp.position = Vector3(s * 0.55, 0.32, 0.45)
		add_child(sp)
		_box(Vector3(0.44, 0.06, 1.72), Vector3(s * 0.55, 0.54, 0.45), accent)  # faixa da cor secundária
	# tampa do motor e barbatana
	_taper(0.3, 0.55, 2.2, 0.36, 0.7, 0.3, 0.3, body)
	_box(Vector3(0.04, 0.42, 1.1), Vector3(0, 0.95, 1.4), accent)
	# asa dianteira e traseira
	_box(Vector3(1.9, 0.05, 0.42), Vector3(0, 0.1, -2.35), accent)
	_box(Vector3(1.9, 0.04, 0.2), Vector3(0, 0.18, -2.2), body)
	for s: float in [-1.0, 1.0]:
		_box(Vector3(0.04, 0.22, 0.5), Vector3(s * 0.95, 0.18, -2.35), carbon)
		_box(Vector3(0.04, 0.6, 0.62), Vector3(s * 0.66, 0.85, 2.45), carbon)
	_box(Vector3(1.32, 0.06, 0.48), Vector3(0, 1.1, 2.45), body)
	_box(Vector3(1.32, 0.05, 0.28), Vector3(0, 0.98, 2.38), accent)
	# cockpit: halo, capacete
	_box(Vector3(0.5, 0.05, 0.5), Vector3(0, 0.82, -0.2), carbon)
	var halo := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.28
	tm.outer_radius = 0.33
	halo.mesh = tm
	halo.material_override = carbon
	halo.position = Vector3(0, 0.86, -0.15)
	halo.scale = Vector3(1.0, 1.0, 1.25)
	add_child(halo)
	var helmet := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.17
	sm.height = 0.32
	helmet.mesh = sm
	helmet.material_override = _mat(Color("#f2c200"), 0.3, 0.25)
	helmet.position = Vector3(0, 0.8, 0.05)
	add_child(helmet)
	# rodas
	for p: Vector3 in [Vector3(-0.92, 0.36, -1.45), Vector3(0.92, 0.36, -1.45), Vector3(-0.94, 0.38, 1.75), Vector3(0.94, 0.38, 1.75)]:
		var wheel := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.36 if p.z < 0 else 0.38
		cm.bottom_radius = cm.top_radius
		cm.height = 0.36 if p.z < 0 else 0.44
		wheel.mesh = cm
		wheel.material_override = tyre
		wheel.rotation = Vector3(0, 0, PI / 2)
		wheel.position = p
		add_child(wheel)
		var hub := MeshInstance3D.new()
		var hm := CylinderMesh.new()
		hm.top_radius = 0.2
		hm.bottom_radius = 0.2
		hm.height = cm.height + 0.02
		hub.mesh = hm
		hub.material_override = rim
		hub.rotation = wheel.rotation
		hub.position = p
		add_child(hub)


## Pedestal giratório numa janela 3D própria (SubViewport transparente) para pôr em telas 2D.
static func turntable(team: Dictionary, px: Vector2i) -> SubViewportContainer:
	var box := SubViewportContainer.new()
	box.stretch = true
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp := SubViewport.new()
	vp.size = px
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_2X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	box.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.6, 0.7)
	e.ambient_light_energy = 0.9
	env.environment = e
	world.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-50, -35, 0)
	key.light_energy = 1.4
	world.add_child(key)
	var rim_l := DirectionalLight3D.new()
	rim_l.rotation_degrees = Vector3(-20, 150, 0)
	rim_l.light_energy = 0.7
	rim_l.light_color = Color(0.75, 0.85, 1.0)
	world.add_child(rim_l)
	var pivot := Node3D.new()
	world.add_child(pivot)
	var car := CarShowcase3D.make(team)
	pivot.add_child(car)
	var disc := MeshInstance3D.new()  # pedestal
	var cm := CylinderMesh.new()
	cm.top_radius = 3.4
	cm.bottom_radius = 3.5
	cm.height = 0.12
	disc.mesh = cm
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color("#1a1e26")
	dm.metallic = 0.6
	dm.roughness = 0.35
	disc.material_override = dm
	disc.position.y = -0.06
	world.add_child(disc)
	var cam := Camera3D.new()
	var eye := Vector3(0, 2.7, 8.8)
	cam.fov = 30
	# orientação calculada à mão: look_at() não funciona antes de a câmera entrar na árvore
	cam.transform = Transform3D(Basis.looking_at(Vector3(0, 0.3, 0) - eye, Vector3.UP), eye)
	world.add_child(cam)
	pivot.rotation.y = 0.6
	var tw := pivot.create_tween().set_loops()
	tw.tween_property(pivot, "rotation:y", 0.6 + TAU, 16.0).from(0.6)
	return box
