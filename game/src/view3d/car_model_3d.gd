class_name CarModel3D
extends RefCounted
## Malha simples de um carro de F1 (caixas com cor por vértice) nas cores da equipe.
## Escala real (~5,6 m); a visualização amplia os carros para ficarem visíveis de longe.

static var _cache: Dictionary = {}


static func mesh_for(team: Dictionary) -> ArrayMesh:
	var key: String = team["id"]
	if _cache.has(key):
		return _cache[key]
	var c1 := Color(team["color"])
	var c2 := Color(team["color2"])
	var dark := Color("#18191c")
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# (centro, tamanho, cor) — frente do carro aponta para -Z
	var parts := [
		[Vector3(0, 0.38, 0.2), Vector3(0.9, 0.42, 3.4), c1],  # monocoque
		[Vector3(0, 0.33, -2.1), Vector3(0.36, 0.26, 1.6), c1],  # bico
		[Vector3(0, 0.12, -2.75), Vector3(1.95, 0.06, 0.45), c2],  # asa dianteira
		[Vector3(0.62, 0.32, 0.6), Vector3(0.42, 0.34, 1.7), c2],  # laterais
		[Vector3(-0.62, 0.32, 0.6), Vector3(0.42, 0.34, 1.7), c2],
		[Vector3(0, 0.72, 0.45), Vector3(0.42, 0.34, 1.3), c1],  # tampa do motor
		[Vector3(0, 0.95, 2.45), Vector3(1.05, 0.28, 0.32), c2],  # asa traseira
		[Vector3(0, 0.62, 2.45), Vector3(0.08, 0.5, 0.12), dark],  # suporte da asa
		[Vector3(0, 0.66, -0.35), Vector3(0.5, 0.06, 0.5), dark],  # halo
		[Vector3(0.85, 0.33, -1.45), Vector3(0.32, 0.66, 0.66), dark],  # rodas
		[Vector3(-0.85, 0.33, -1.45), Vector3(0.32, 0.66, 0.66), dark],
		[Vector3(0.85, 0.36, 1.75), Vector3(0.4, 0.72, 0.72), dark],
		[Vector3(-0.85, 0.36, 1.75), Vector3(0.4, 0.72, 0.72), dark],
	]
	for part: Array in parts:
		_box(st, part[0], part[1], part[2])
	var mesh := st.commit()
	_cache[key] = mesh
	return mesh


static func _box(st: SurfaceTool, c: Vector3, s: Vector3, col: Color) -> void:
	var h := s / 2.0
	var faces := [
		[Vector3.UP, [Vector3(-1, 1, -1), Vector3(1, 1, -1), Vector3(1, 1, 1), Vector3(-1, 1, 1)]],
		[Vector3.DOWN, [Vector3(-1, -1, 1), Vector3(1, -1, 1), Vector3(1, -1, -1), Vector3(-1, -1, -1)]],
		[Vector3.RIGHT, [Vector3(1, -1, -1), Vector3(1, -1, 1), Vector3(1, 1, 1), Vector3(1, 1, -1)]],
		[Vector3.LEFT, [Vector3(-1, -1, 1), Vector3(-1, -1, -1), Vector3(-1, 1, -1), Vector3(-1, 1, 1)]],
		[Vector3.BACK, [Vector3(1, -1, 1), Vector3(-1, -1, 1), Vector3(-1, 1, 1), Vector3(1, 1, 1)]],
		[Vector3.FORWARD, [Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(1, 1, -1), Vector3(-1, 1, -1)]],
	]
	for f: Array in faces:
		var q: Array = f[1]
		for k in [0, 2, 1, 0, 3, 2]:
			st.set_color(col)
			st.set_normal(f[0])
			st.add_vertex(c + q[k] * h)
