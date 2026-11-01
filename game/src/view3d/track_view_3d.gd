class_name TrackView3D
extends SubViewportContainer
## Vista 3D da corrida: pista com relevo, cenário, carros e clima, com câmera orbital.
##
## Controles: arrastar = girar · pinça/roda do mouse = zoom · botão de câmera = alterna entre
## visão geral, seguir seus pilotos e seguir o líder.

const CAR_SCALE := 4.0  ## ampliação máxima dos carros (câmera longe)


## De perto o carro fica quase no tamanho real (senão se sobrepõem no grid);
## de longe é ampliado para continuar visível.
func _car_scale() -> float:
	return clampf(distance / 70.0, 1.2, CAR_SCALE)
const PIT_OFFSET_M := 15.0

enum CamMode { OVERVIEW, FOLLOW_1, FOLLOW_2, LEADER }

var sim: RaceSim
var t3: Track3D
var cam_mode := CamMode.OVERVIEW
var yaw := 0.6
var snap_camera := false  ## câmera vai direto ao alvo (capturas de tela)
var pitch := 0.62  ## radianos acima do horizonte
var distance := 1400.0

var _vp: SubViewport
var _world_root: Node3D
var _cam: Camera3D
var _sun: DirectionalLight3D
var _env: Environment
var _sky_mat: ProceduralSkyMaterial
var _asphalt: StandardMaterial3D
var _rain: CPUParticles3D
var _cars: Dictionary = {}  # CarState -> MeshInstance3D
var _labels: Dictionary = {}
var _sc: MeshInstance3D
var _target := Vector3.ZERO
var _overview_target := Vector3.ZERO
var _night := false
var _last_wet := -1.0


func setup(p_sim: RaceSim) -> void:
	sim = p_sim
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_vp = SubViewport.new()
	_vp.msaa_3d = Viewport.MSAA_2X
	_vp.positional_shadow_atlas_size = 0
	add_child(_vp)
	_world_root = Node3D.new()
	_vp.add_child(_world_root)
	t3 = Track3D.new(sim.track)
	_night = sim.track.night
	_build_environment()
	_build_track()
	_world_root.add_child(Scenery3D.new().build(t3, _night))
	_build_cars()
	_overview_target = t3.bounds_3d().get_center()
	_target = _overview_target
	distance = _overview_distance()
	_update_camera(1.0)


# --- montagem ------------------------------------------------------------------------

func _build_environment() -> void:
	_sky_mat = ProceduralSkyMaterial.new()
	var sky := Sky.new()
	sky.sky_material = _sky_mat
	_env = Environment.new()
	_env.background_mode = Environment.BG_SKY
	_env.sky = sky
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.tonemap_exposure = 0.85
	_env.fog_enabled = true
	_env.fog_density = 0.00018
	var we := WorldEnvironment.new()
	we.environment = _env
	_world_root.add_child(we)
	_sun = DirectionalLight3D.new()
	_sun.shadow_enabled = true
	_sun.directional_shadow_max_distance = 2500.0
	_sun.rotation_degrees = Vector3(-48, 35, 0)
	_world_root.add_child(_sun)
	_cam = Camera3D.new()
	_cam.far = 9000.0
	_cam.fov = 50.0
	_world_root.add_child(_cam)
	_rain = CPUParticles3D.new()
	_rain.amount = 1400
	_rain.lifetime = 0.9
	_rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_rain.emission_box_extents = Vector3(60, 2, 60)
	_rain.direction = Vector3(0.15, -1, 0)
	_rain.spread = 4.0
	_rain.initial_velocity_min = 60.0
	_rain.initial_velocity_max = 75.0
	_rain.gravity = Vector3.ZERO
	var drop := BoxMesh.new()
	drop.size = Vector3(0.03, 0.9, 0.03)
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.75, 0.82, 0.95, 0.5)
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop.material = dm
	_rain.mesh = drop
	_rain.emitting = false
	_cam.add_child(_rain)
	_rain.position = Vector3(0, 25, -30)
	_apply_lighting(0.0, 0.0)


func _build_track() -> void:
	_asphalt = Materials3D.asphalt()
	_asphalt.cull_mode = BaseMaterial3D.CULL_DISABLED
	_add_mesh(t3.strip(-Track3D.WIDTH / 2.0, Track3D.WIDTH / 2.0, 0.05), _asphalt)
	var white := Materials3D.flat(Color("#ececec"), 0.6)
	white.cull_mode = BaseMaterial3D.CULL_DISABLED
	_add_mesh(t3.strip(-Track3D.WIDTH / 2.0, -Track3D.WIDTH / 2.0 + Track3D.LINE_W, 0.08), white)
	_add_mesh(t3.strip(Track3D.WIDTH / 2.0 - Track3D.LINE_W, Track3D.WIDTH / 2.0, 0.08), white)
	var kerb := Materials3D.vertex_color(0.7)
	kerb.cull_mode = BaseMaterial3D.CULL_DISABLED
	_add_mesh(t3.kerbs(), kerb)
	var verge := Materials3D.flat(Color("#5a5a52"), 1.0)
	verge.cull_mode = BaseMaterial3D.CULL_DISABLED
	_add_mesh(t3.skirt(-Track3D.WIDTH / 2.0 - Track3D.KERB_W, 3.0), verge)
	_add_mesh(t3.skirt(Track3D.WIDTH / 2.0 + Track3D.KERB_W, 3.0), verge)
	_build_track_details()
	# linha de chegada (quadriculada simplificada: faixa branca larga)
	var line := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(Track3D.WIDTH, 0.12, 2.0)
	line.mesh = bm
	line.transform = Transform3D(t3.basis_at(0.0), t3.point_at(0.0) + Vector3.UP * 0.1)
	line.material_override = Materials3D.flat(Color.WHITE, 0.5)
	_world_root.add_child(line)


## Detalhes que todo circuito real tem: pit lane, prédio dos boxes, brita nas curvas,
## guard-rails, barreiras de pneus e marcações do grid de largada.
func _build_track_details() -> void:
	var w := Track3D.WIDTH / 2.0
	var k := Track3D.KERB_W
	# pit lane (lado esquerdo da reta principal)
	_add_mesh(t3.strip(-w - 22.0, -w - 8.0, 0.04, 8.0, t3.in_pit_zone), _asphalt)
	var wall_mat := Materials3D.vertex_color(0.5)
	wall_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_add_mesh(t3.wall(-w - 6.0, 1.1, t3.in_pit_zone, Color("#d9d9d9"), Color("#d9d9d9")), wall_mat)
	# brita só do lado de fora das curvas, depois das zebras, com barreira de pneus atrás
	var gravel := Materials3D.ground(Color("#7a6a4e"))
	gravel.cull_mode = BaseMaterial3D.CULL_DISABLED
	var out_r := func(i: int) -> bool: return t3.outside_side(i) > 0.0  # pit lane só à esquerda
	var out_l := func(i: int) -> bool: return t3.outside_side(i) < 0.0 and not t3.in_pit_zone(i)
	_add_mesh(t3.strip(w + k, w + k + 16.0, 0.03, 8.0, out_r), gravel)
	_add_mesh(t3.strip(-w - k - 16.0, -w - k, 0.03, 8.0, out_l), gravel)
	_add_mesh(t3.wall(w + k + 17.0, 1.2, out_r, Color("#1d1d1f"), Color("#c8102e")), wall_mat)
	_add_mesh(t3.wall(-w - k - 17.0, 1.2, out_l, Color("#1d1d1f"), Color("#1f4fa0")), wall_mat)
	# guard-rail (cinza) no resto da volta, mais perto da pista
	var rail_r := func(i: int) -> bool: return t3.outside_side(i) <= 0.0
	var rail_l := func(i: int) -> bool: return t3.outside_side(i) >= 0.0 and not t3.in_pit_zone(i)
	_add_mesh(t3.wall(w + 9.0, 0.9, rail_r, Color("#bfc4c9"), Color("#aab0b6")), wall_mat)
	_add_mesh(t3.wall(-w - 9.0, 0.9, rail_l, Color("#bfc4c9"), Color("#aab0b6")), wall_mat)
	_build_pit_building(w)
	# marcações do grid (duas filas, atrás da linha de chegada)
	var grid_mat := Materials3D.flat(Color("#f2f2f2"), 0.6)
	for slot in sim.cars.size():
		var d := -RaceSim.GRID_SPACING_M * slot - 5.0 - 2.0
		var f := fposmod(d, sim.track.length_m) / sim.track.length_m
		var b := t3.basis_at(f)
		var mark := MeshInstance3D.new()
		var bm2 := BoxMesh.new()
		bm2.size = Vector3(2.4, 0.05, 0.35)
		mark.mesh = bm2
		mark.material_override = grid_mat
		mark.transform = Transform3D(b, t3.point_at(f) + b.x * (3.0 if slot % 2 == 0 else -3.0) + Vector3.UP * 0.09)
		_world_root.add_child(mark)


## Prédio dos boxes atrás do pit lane: um vão de 12 m por garagem, com portão escuro
## virado para o pit lane e uma faixa na cor da equipe (duas garagens por equipe).
func _build_pit_building(w: float) -> void:
	var teams: Array[Dictionary] = []
	for car in sim.cars:
		if not teams.has(car.team):
			teams.append(car.team)
	var body := Materials3D.flat(Color("#6f7276"), 0.85)
	var door := Materials3D.flat(Color("#1c1e22"), 0.6)
	var glass := Materials3D.flat(Color("#33414d"), 0.15)
	glass.metallic = 0.4
	var roof := Materials3D.flat(Color("#3f4247"), 0.95)
	var bays := teams.size() * 2
	for k in bays:
		var f := float((k - bays / 2) * 3) / t3.n  # 3 amostras = 12 m por vão
		var b := t3.basis_at(f)
		var base := t3.point_at(f) - b.x * (w + 31.0)
		var team: Dictionary = teams[k / 2]
		var stripe := Materials3D.flat(Color(team["color"]), 0.5)
		# (deslocamento lateral a partir do centro do prédio, altura, tamanho, material)
		for part: Array in [
			[0.0, 4.5, Vector3(16.0, 9.0, 12.05), body],
			[8.05, 2.4, Vector3(0.2, 4.8, 9.6), door],  # portão (face do pit lane)
			[8.1, 5.6, Vector3(0.2, 0.7, 11.0), stripe],  # faixa da equipe
			[8.05, 7.6, Vector3(0.2, 1.8, 11.4), glass],  # vidro do andar de cima
			[2.0, 9.15, Vector3(20.0, 0.3, 12.05), roof],  # laje com beiral sobre o pit lane
		]:
			var mi := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = part[2]
			mi.mesh = bm
			mi.material_override = part[3]
			mi.transform = Transform3D(b, base + b.x * float(part[0]) + Vector3.UP * float(part[1]))
			_world_root.add_child(mi)


func _add_mesh(mesh: Mesh, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	_world_root.add_child(mi)


func _build_cars() -> void:
	var mat := Materials3D.vertex_color(0.35)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for car in sim.cars:
		var mi := MeshInstance3D.new()
		mi.mesh = CarModel3D.mesh_for(car.team)
		mi.material_override = mat
		mi.scale = Vector3.ONE * CAR_SCALE
		_world_root.add_child(mi)
		_cars[car] = mi
		if car.is_player:
			var l := Label3D.new()
			l.text = car.code()
			l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			l.no_depth_test = true
			l.fixed_size = true
			l.pixel_size = 0.0004
			l.font = UiStyle.HEAVY_FONT
			l.font_size = 26
			l.outline_size = 9
			l.modulate = Color.WHITE
			l.outline_modulate = UiStyle.INK
			l.position = Vector3(0, 4.0, 0)
			mi.add_child(l)
			_labels[car] = l
	_sc = MeshInstance3D.new()
	var sc_mesh := BoxMesh.new()
	sc_mesh.size = Vector3(2.0, 1.4, 4.6)
	_sc.mesh = sc_mesh
	var scm := Materials3D.flat(Color("#F5C400"), 0.4)
	scm.emission_enabled = true
	scm.emission = Color("#F5C400")
	scm.emission_energy_multiplier = 0.6
	_sc.material_override = scm
	_sc.scale = Vector3.ONE * CAR_SCALE
	_sc.visible = false
	_world_root.add_child(_sc)


# --- atualização por quadro ------------------------------------------------------------

func _process(delta: float) -> void:
	if sim == null:
		return
	for car: CarState in _cars:
		var mi: MeshInstance3D = _cars[car]
		mi.visible = not car.retired
		if car.retired:
			continue
		var d := sim.render_distance(car)
		var frac := fposmod(d, sim.track.length_m) / sim.track.length_m
		var pos := t3.point_at(frac)
		var basis := t3.basis_at(frac)
		if car.in_pit:
			pos -= basis.x * PIT_OFFSET_M
		elif car.stall_s > 0.0:
			pos += basis.x * (Track3D.WIDTH * 0.9)
			basis = basis.rotated(Vector3.UP, 1.2)
		elif d < 0.0:
			pos += basis.x * (3.0 if car.grid_position % 2 == 0 else -3.0)
		mi.transform = Transform3D(basis.scaled(Vector3.ONE * _car_scale()), pos + Vector3.UP * 0.1)
	_sc.visible = sim.control.flag == RaceControl.Flag.SC
	if _sc.visible:
		var lead := sim.standings()[0]
		var f := fposmod(sim.render_distance(lead) + 80.0, sim.track.length_m) / sim.track.length_m
		_sc.transform = Transform3D(t3.basis_at(f).scaled(Vector3.ONE * _car_scale()), t3.point_at(f) + Vector3.UP * 0.1)
	var w := sim.weather.wetness
	var r := sim.weather.rain_now()
	if absf(w - _last_wet) > 0.01 or (r > WeatherModel.RAIN_THRESHOLD) != _rain.emitting:
		_last_wet = w
		_apply_lighting(w, r)
	_update_camera(delta)


## Céu, sol e pista conforme chuva, umidade e noite.
func _apply_lighting(wetness: float, rain: float) -> void:
	var overcast := clampf(maxf(rain * 1.3, wetness * 0.6), 0.0, 1.0)
	if _night:
		_sky_mat.sky_top_color = Color("#0b1022")
		_sky_mat.sky_horizon_color = Color("#2a2f4a")
		_sky_mat.ground_horizon_color = Color("#1a1d2b")
		_sky_mat.ground_bottom_color = Color("#0b0d14")
		_sun.light_energy = 0.35
		_sun.light_color = Color("#9fb4ff")
		_env.ambient_light_energy = 0.9
	else:
		_sky_mat.sky_top_color = Color("#3b78c2").lerp(Color("#5d6670"), overcast)
		_sky_mat.sky_horizon_color = Color("#bcd2e8").lerp(Color("#8d949b"), overcast)
		_sky_mat.ground_horizon_color = Color("#a8b3a0").lerp(Color("#7c8279"), overcast)
		_sky_mat.ground_bottom_color = Color("#4a5240")
		_sun.light_energy = lerpf(0.95, 0.3, overcast)
		_sun.light_color = Color("#fff4e0")
		_env.ambient_light_energy = lerpf(0.22, 0.45, overcast)
	_env.fog_light_color = _sky_mat.sky_horizon_color
	_env.fog_density = lerpf(0.00008, 0.0007, overcast)
	_rain.emitting = rain > WeatherModel.RAIN_THRESHOLD
	_rain.amount = int(lerpf(600, 2000, clampf(rain, 0.0, 1.0)))
	if _asphalt != null:
		Materials3D.set_wet(_asphalt, wetness)
		if _night:  # holofotes iluminam a pista nas corridas noturnas
			_asphalt.emission_enabled = true
			_asphalt.emission = Color("#5a5e6a")
			_asphalt.emission_energy_multiplier = 0.6


# --- câmera ----------------------------------------------------------------------------

func cycle_camera() -> String:
	cam_mode = (cam_mode + 1) % 4 as CamMode
	var players: Array[CarState] = []
	for car in sim.cars:
		if car.is_player:
			players.append(car)
	match cam_mode:
		CamMode.OVERVIEW:
			distance = _overview_distance()
			return "Visão geral"
		CamMode.FOLLOW_1, CamMode.FOLLOW_2:
			distance = 140.0
			var idx := 0 if cam_mode == CamMode.FOLLOW_1 else 1
			return "Seguindo %s" % (players[idx].code() if idx < players.size() else "—")
		_:
			distance = 140.0
			return "Seguindo o líder"


func _overview_distance() -> float:
	return maxf(t3.bounds_3d().size.x, t3.bounds_3d().size.z) * 0.78


func _follow_car() -> CarState:
	var players: Array[CarState] = []
	for car in sim.cars:
		if car.is_player:
			players.append(car)
	match cam_mode:
		CamMode.FOLLOW_1:
			return players[0] if players.size() > 0 else null
		CamMode.FOLLOW_2:
			return players[1] if players.size() > 1 else null
		CamMode.LEADER:
			return sim.standings()[0]
	return null


func _update_camera(delta: float) -> void:
	var car := _follow_car()
	var goal := _overview_target
	if car != null and _cars.has(car):
		goal = (_cars[car] as MeshInstance3D).position
	_target = goal if snap_camera else _target.lerp(goal, clampf(delta * 4.0, 0.0, 1.0))
	var dir := Vector3(cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw))
	_cam.position = _target + dir * distance
	_cam.look_at(_target, Vector3.UP)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag or (event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT)):
		var rel: Vector2 = event.relative
		yaw -= rel.x * 0.006
		pitch = clampf(pitch + rel.y * 0.004, 0.12, 1.45)
		accept_event()
	elif event is InputEventMagnifyGesture:
		distance = clampf(distance / event.factor, 60.0, 4000.0)
		accept_event()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clampf(distance * 0.88, 60.0, 4000.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clampf(distance * 1.12, 60.0, 4000.0)
