class_name TrackView3D
extends SubViewportContainer
## Vista 3D da corrida: pista com relevo, cenário, carros e clima, com câmera orbital.
##
## Controles: arrastar = girar · pinça/roda do mouse = zoom · botão de câmera = alterna entre
## visão geral, seguir seus pilotos e seguir o líder.

const CAR_SCALE := 6.0  ## ampliação máxima do safety car (câmera longe)
const ZOOM_MIN := 40.0
const ZOOM_MAX := 4000.0


## De perto o carro fica quase no tamanho real (senão se sobrepõem no grid);
## de longe é ampliado para continuar visível.
func _car_scale() -> float:
	return clampf(distance / 80.0, 1.0, CAR_SCALE)
const PIT_OFFSET_M := 15.0
const GRID_BLEND_M := 160.0  ## depois da linha, em quantos metros o carro sai da fila do grid e vai para o eixo da pista

enum CamMode { OVERVIEW, FOLLOW_1, FOLLOW_2, LEADER, CAR }

var sim: TrackFeed  ## o que a pista mostra (corrida ou classificação)
var t3: Track3D
var cam_mode := CamMode.OVERVIEW
var followed: CarState = null  ## carro em foco (CamMode.CAR): escolhido tocando na torre
var yaw := 0.6
var snap_camera := false  ## câmera vai direto ao alvo (capturas de tela)
var pitch := 0.62  ## radianos acima do horizonte
var distance := 1400.0

var _vp: SubViewport


## Textura da vista 3D: a miniatura do box só espelha a pista (nada de tirar a pista do lugar).
func view_texture() -> Texture2D:
	return _vp.get_texture()

var _world_root: Node3D
var _cam: Camera3D
var _sun: DirectionalLight3D
var _env: Environment
var _sky_mat: ProceduralSkyMaterial
var _asphalt: StandardMaterial3D
var _rain: CPUParticles3D
var _rank_timer := 0.0
var _motion := MarkerMotion.new()
var _cars: Dictionary = {}  # CarState -> CarMarker3D
var _sc: MeshInstance3D
var _target := Vector3.ZERO
var _overview_target := Vector3.ZERO
var _night := false
var _last_wet := -1.0


## Aceita uma corrida (RaceSim), uma classificação (QualiSim) ou um TrackFeed pronto.
func setup(source: Variant) -> void:
	if source is RaceSim:
		sim = TrackFeed.of_race(source)
	elif source is QualiSim:
		sim = TrackFeed.of_quali(source)
	else:
		sim = source
	if source is RaceSim:  # animações de ultrapassagem, rodada e batida
		(source as RaceSim).overtake.connect(func(att: CarState, def: CarState, _z: String) -> void: _motion.on_overtake(att, def))
		(source as RaceSim).start_pass.connect(func(att: CarState, def: CarState) -> void: _motion.on_overtake(att, def))
		(source as RaceSim).incident.connect(func(car: CarState, kind: String, _t: String) -> void:
			_motion.on_incident(car, kind, Track3D.WIDTH, (source as RaceSim).render_distance(car)))
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
	_env.ambient_light_sky_contribution = 0.55  # menos azul do céu nas superfícies claras
	_env.ambient_light_color = Color("#d8d2c4")
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.tonemap_exposure = 0.72
	_env.adjustment_enabled = true  # cores mais vivas (gramado, zebras, placas)
	_env.adjustment_saturation = 1.0
	_env.adjustment_contrast = 1.05
	_env.fog_enabled = true
	_env.fog_density = 0.00004
	var we := WorldEnvironment.new()
	we.environment = _env
	_world_root.add_child(we)
	_sun = DirectionalLight3D.new()
	_sun.shadow_enabled = true
	_sun.directional_shadow_max_distance = 2500.0
	_sun.rotation_degrees = Vector3(-42, 35, 0)
	_sun.shadow_blur = 1.5
	_sun.shadow_bias = 0.08
	_sun.shadow_normal_bias = 2.5  # sem "listras" de sombra nos gramados grandes e planos
	_world_root.add_child(_sun)
	_cam = Camera3D.new()
	_cam.far = 9000.0
	_cam.near = 1.5  # mais precisão de profundidade: sem "briga" entre faixas sobrepostas (zebras, gramado, paddock)
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
	var verge := Materials3D.flat(Color("#4c6b33"), 1.0)
	verge.cull_mode = BaseMaterial3D.CULL_DISABLED
	_add_mesh(t3.skirt(-Track3D.WIDTH / 2.0 - Track3D.KERB_W, 3.0), verge)
	_add_mesh(t3.skirt(Track3D.WIDTH / 2.0 + Track3D.KERB_W, 3.0), verge)
	var teams: Array[Dictionary] = []
	for car in sim.cars:
		if not teams.has(car.team):
			teams.append(car.team)
	CircuitDressing.new().build(t3, _world_root, _asphalt, teams, _night)


func _add_mesh(mesh: Mesh, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	_world_root.add_child(mi)


## Cada carro é um marcador plano na cor da equipe com o número do piloto (ver CarMarker3D).
func _build_cars() -> void:
	for car in sim.cars:
		var m := CarMarker3D.new()
		m.setup(car)
		_world_root.add_child(m)
		_cars[car] = m
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
	_rank_timer -= delta
	if _rank_timer <= 0.0:  # quem está à frente desenha por cima; os seus carros sempre na frente
		_rank_timer = 0.3
		var order := sim.standings()
		for i in order.size():
			(_cars[order[i]] as CarMarker3D).set_rank(i if not order[i].is_player else -1)
	_motion.step(delta)
	for car: CarState in _cars:
		var mi: CarMarker3D = _cars[car]
		var wreck := not sim.marker_visible(car) and _motion.is_wreck_visible(car)
		mi.visible = sim.marker_visible(car) or wreck
		if not mi.visible:
			continue
		var d := _motion.wreck_distance(car) if wreck else sim.render_distance(car) + _motion.distance_offset(car)
		var frac := fposmod(d, sim.track.length_m) / sim.track.length_m
		var pos := t3.point_at(frac)
		var basis := t3.basis_at(frac)
		if wreck:  # batido/quebrado: parado fora da pista, apagando
			pos += basis.x * _motion.wreck_lateral(car)
			mi.set_fade(_motion.wreck_alpha(car))
		else:
			mi.set_fade(1.0)
			if car.in_pit:  # segue o pit lane, inclusive as diagonais de entrada e saída
				pos += basis.x * t3.pit_offset(frac)
			elif car.laps_done == 0 and d < GRID_BLEND_M:
				# grid em duas filas; depois das luzes, abre para o eixo da pista aos poucos (e as trocas da largada
				# balançam para o lado). `d` negativo = ainda atrás da linha.
				var side := RaceSim.GRID_LATERAL_M * (1.0 if car.grid_position % 2 == 0 else -1.0)
				var k := clampf(1.0 - maxf(d, 0.0) / GRID_BLEND_M, 0.0, 1.0)
				var lat := side * k + (_motion.lateral(car) if d >= 0.0 else 0.0)
				pos += basis.x * clampf(lat, -Track3D.WIDTH * 0.46, Track3D.WIDTH * 0.46)
			else:
				pos += basis.x * _motion.lateral(car)
		mi.set_alert(not wreck and _motion.is_off_track(car))
		mi.position = pos + Vector3.UP * 3.0
	_sc.visible = sim.safety_car_out()
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
		_sky_mat.sky_top_color = Color("#2f7fd8").lerp(Color("#5d6670"), overcast)
		_sky_mat.sky_horizon_color = Color("#cfe3f5").lerp(Color("#8d949b"), overcast)
		_sky_mat.ground_horizon_color = Color("#a8b3a0").lerp(Color("#7c8279"), overcast)
		_sky_mat.ground_bottom_color = Color("#4a5240")
		_sun.light_energy = lerpf(1.05, 0.35, overcast)
		_sun.light_color = Color("#fff1d6")
		_env.ambient_light_energy = lerpf(0.24, 0.5, overcast)
	_env.fog_light_color = _sky_mat.sky_horizon_color
	_env.fog_density = lerpf(0.00004, 0.0006, overcast)
	_rain.emitting = rain > WeatherModel.RAIN_THRESHOLD
	_rain.amount = int(lerpf(600, 2000, clampf(rain, 0.0, 1.0)))
	if _asphalt != null:
		Materials3D.set_wet(_asphalt, wetness)
		if _night:  # holofotes iluminam a pista nas corridas noturnas
			_asphalt.emission_enabled = true
			_asphalt.emission = Color("#5a5e6a")
			_asphalt.emission_energy_multiplier = 0.6


# --- câmera ----------------------------------------------------------------------------

## Segue o carro escolhido na torre; tocar no mesmo carro de novo volta à vista geral.
## Devolve o rótulo da câmera (para o aviso).
func follow(car: CarState) -> String:
	_saved_cam = {}
	if car == null or (cam_mode == CamMode.CAR and followed == car):
		cam_mode = CamMode.OVERVIEW
		followed = null
		distance = _overview_distance()
		pitch = 0.62
		return "Visão geral"
	cam_mode = CamMode.CAR
	followed = car
	distance = 140.0
	return "Seguindo %s" % car.code()


func cycle_camera() -> String:
	_saved_cam = {}  # o jogador escolheu a câmera: vale a escolha dele, mesmo acelerado
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


## Tempo acelerado (4×/8×): a câmera se afasta para a vista geral, mais fácil de acompanhar;
## ao voltar para 1×/2× retorna à câmera que o jogador usava. Devolve o rótulo quando muda.
var _saved_cam: Dictionary = {}


func set_fast_time(on: bool) -> String:
	if on and _saved_cam.is_empty() and cam_mode != CamMode.OVERVIEW:
		_saved_cam = {"mode": cam_mode, "distance": distance, "pitch": pitch, "followed": followed}
		cam_mode = CamMode.OVERVIEW
		distance = _overview_distance()
		pitch = 0.62
		return "Visão geral (tempo acelerado)"
	if not on and not _saved_cam.is_empty():
		cam_mode = _saved_cam["mode"]
		followed = _saved_cam.get("followed")
		distance = _saved_cam["distance"]
		pitch = _saved_cam["pitch"]
		_saved_cam = {}
		return _cam_label()
	return ""


func _cam_label() -> String:
	match cam_mode:
		CamMode.OVERVIEW:
			return "Visão geral"
		CamMode.FOLLOW_1, CamMode.FOLLOW_2, CamMode.CAR:
			var car := _follow_car()
			return "Seguindo %s" % (car.code() if car != null else "—")
	return "Seguindo o líder"


## Centra a visão geral num ponto da pista (fração da volta) — capturas e atalhos de câmera.
func look_at_frac(frac: float) -> void:
	_overview_target = t3.point_at(frac)
	_target = _overview_target


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
		CamMode.CAR:
			return followed
	return null


func _update_camera(delta: float) -> void:
	var car := _follow_car()
	var goal := _overview_target
	if car != null and _cars.has(car):
		goal = (_cars[car] as CarMarker3D).position
	_target = goal if snap_camera else _target.lerp(goal, clampf(delta * 4.0, 0.0, 1.0))
	var dir := Vector3(cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw))
	_cam.position = _target + dir * distance
	_cam.look_at(_target, Vector3.UP)


## Zoom: pinça com dois dedos (calculada aqui, porque no celular o gesto chega como dois toques),
## roda do mouse, gesto de lupa e os botões + / − da tela de corrida. Um dedo gira a câmera.
var _touches: Dictionary = {}  # índice do dedo -> posição
var _pinch_start := 0.0
var _pinch_distance := 0.0


func zoom_by(factor: float) -> void:
	distance = clampf(distance * factor, ZOOM_MIN, ZOOM_MAX)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
		if _touches.size() == 2:
			var p: Array = _touches.values()
			_pinch_start = (p[0] as Vector2).distance_to(p[1])
			_pinch_distance = distance
		accept_event()
	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if _touches.size() >= 2:
			var p2: Array = _touches.values()
			var now := (p2[0] as Vector2).distance_to(p2[1])
			if _pinch_start > 10.0 and now > 10.0:
				distance = clampf(_pinch_distance * _pinch_start / now, ZOOM_MIN, ZOOM_MAX)
		else:
			_rotate(event.relative)
		accept_event()
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) and event.device != InputEvent.DEVICE_ID_EMULATION:
		_rotate(event.relative)
		accept_event()
	elif event is InputEventMagnifyGesture:
		distance = clampf(distance / event.factor, ZOOM_MIN, ZOOM_MAX)
		accept_event()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_by(0.88)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_by(1.12)


func _rotate(rel: Vector2) -> void:
	yaw -= rel.x * 0.006
	pitch = clampf(pitch + rel.y * 0.004, 0.12, 1.45)
