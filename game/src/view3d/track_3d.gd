class_name Track3D
extends RefCounted
## Geometria 3D da pista a partir do traçado (TrackModel) e do perfil de relevo:
## amostras ao longo da volta, faixa de asfalto, linhas brancas, zebras nas curvas e pit lane.
## Coordenadas em metros: x = leste, z = sul (como o traçado), y = altura.

const WIDTH := 14.0
const STEP_M := 4.0
const KERB_W := 1.6
const LINE_W := 0.35

var track: TrackModel
var n := 0
var center := PackedVector3Array()
var right := PackedVector3Array()  ## vetor para a direita do sentido de corrida
var curvature := PackedFloat32Array()


func _init(p_track: TrackModel) -> void:
	track = p_track
	n = maxi(64, int(track.length_m / STEP_M))
	for i in n:
		var f := float(i) / n
		center.append(point_at(f))
	for i in n:
		var fwd := (center[(i + 1) % n] - center[(i - 1 + n) % n]).normalized()
		right.append(fwd.cross(Vector3.UP).normalized())
	for i in n:
		var a := (center[i] - center[(i - 3 + n) % n]).normalized()
		var b := (center[(i + 3) % n] - center[i]).normalized()
		curvature.append(a.angle_to(b))


## Ponto do eixo da pista (com altura) na fração da volta.
func point_at(frac: float) -> Vector3:
	var p := track.position_at(frac)
	return Vector3(p.x, track.height_at(frac), p.y)


## Orientação de um carro na fração: -Z do Basis aponta para a frente.
func basis_at(frac: float) -> Basis:
	var a := point_at(frac - 0.0015)
	var b := point_at(frac + 0.0015)
	var fwd := (b - a).normalized()
	return Basis.looking_at(fwd, Vector3.UP)


func right_at(frac: float) -> Vector3:
	var b := basis_at(frac)
	return b.x


## Faixa ao longo da pista entre os deslocamentos laterais a e b (metros; + = direita).
func strip(a: float, b: float, lift: float, uv_scale: float = 8.0, mask: Callable = Callable()) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dist := 0.0
	for i in n:
		var j := (i + 1) % n
		if mask.is_valid() and not mask.call(i):
			dist += center[i].distance_to(center[j])
			continue
		var p0a := center[i] + right[i] * a + Vector3.UP * lift
		var p0b := center[i] + right[i] * b + Vector3.UP * lift
		var p1a := center[j] + right[j] * a + Vector3.UP * lift
		var p1b := center[j] + right[j] * b + Vector3.UP * lift
		var seg := center[i].distance_to(center[j])
		var v0 := dist / uv_scale
		var v1 := (dist + seg) / uv_scale
		for v: Array in [[p0a, Vector2(0, v0)], [p1a, Vector2(0, v1)], [p1b, Vector2(1, v1)],
				[p0a, Vector2(0, v0)], [p1b, Vector2(1, v1)], [p0b, Vector2(1, v0)]]:
			st.set_normal(Vector3.UP)
			st.set_uv(v[1])
			st.add_vertex(v[0])
		dist += seg
	st.generate_tangents()
	return st.commit()


## Barranco lateral do asfalto até o chão (esconde a borda flutuante quando o terreno é mais baixo).
func skirt(offset: float, depth: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n:
		var j := (i + 1) % n
		var a := center[i] + right[i] * offset
		var b := center[j] + right[j] * offset
		var a2 := a + Vector3.DOWN * depth
		var b2 := b + Vector3.DOWN * depth
		var nrm := right[i] * signf(offset)
		for v in [a, b, b2, a, b2, a2]:
			st.set_normal(nrm)
			st.add_vertex(v)
	return st.commit()


func is_corner(i: int) -> bool:
	return curvature[i] > 0.035


## Zebras: faixas vermelho/branco nas curvas (cor por vértice, alternando a cada ~3 m).
func kerbs() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side: float in [-1.0, 1.0]:
		var a := side * WIDTH / 2.0
		var b := side * (WIDTH / 2.0 + KERB_W)
		for i in n:
			if not (is_corner(i) or is_corner((i + 2) % n) or is_corner((i - 2 + n) % n)):
				continue
			var j := (i + 1) % n
			var col := Color("#d42020") if i % 2 == 0 else Color("#f2f2f2")
			var lift := 0.06
			var quad := [center[i] + right[i] * a, center[j] + right[j] * a, center[j] + right[j] * b, center[i] + right[i] * b]
			for k in [0, 1, 2, 0, 2, 3]:
				st.set_color(col)
				st.set_normal(Vector3.UP)
				st.add_vertex(quad[k] + Vector3.UP * lift)
	return st.commit()


func bounds_3d() -> AABB:
	var box := AABB(center[0], Vector3.ZERO)
	for p in center:
		box = box.expand(p)
	return box


# --- campo de distância/altura pré-calculado (consulta rápida para o cenário) ----------
var _field_box := Rect2()
var _field_cell := 20.0
var _field_w := 0
var _field_h := 0
var _field := PackedVector2Array()  # (distância, altura) por célula


## Pré-calcula, numa grade, a distância até a pista e a altura do trecho mais próximo.
## Montar o cenário consulta milhares de pontos; sem a grade, cada consulta percorreria a pista.
func build_field(box: AABB, cell: float = 20.0) -> void:
	_field_cell = cell
	_field_box = Rect2(box.position.x, box.position.z, box.size.x, box.size.z)
	_field_w = int(ceil(box.size.x / cell)) + 1
	_field_h = int(ceil(box.size.z / cell)) + 1
	_field.resize(_field_w * _field_h)
	for gz in _field_h:
		for gx in _field_w:
			var p := Vector3(_field_box.position.x + gx * cell, 0, _field_box.position.y + gz * cell)
			_field[gz * _field_w + gx] = nearest(p, 4)


## Distância e altura aproximadas (interpolação bilinear da grade).
func field_at(p: Vector3, exact_near: bool = false) -> Vector2:
	if _field.is_empty():
		return nearest(p, 6)
	var fx := clampf((p.x - _field_box.position.x) / _field_cell, 0.0, _field_w - 1.001)
	var fz := clampf((p.z - _field_box.position.y) / _field_cell, 0.0, _field_h - 1.001)
	var ix := int(fx)
	var iz := int(fz)
	var tx := fx - ix
	var tz := fz - iz
	var a := _field[iz * _field_w + ix].lerp(_field[iz * _field_w + ix + 1], tx)
	var b := _field[(iz + 1) * _field_w + ix].lerp(_field[(iz + 1) * _field_w + ix + 1], tx)
	var v := a.lerp(b, tz)
	if exact_near and v.x < 90.0:
		return nearest(p, 2)  # perto da pista a interpolação erra; refina com a conta exata
	return v


## Distância horizontal (aproximada) de um ponto ao eixo da pista e a altura do trecho mais próximo.
## Usa amostragem reduzida para ser rápido o bastante na montagem do cenário.
func nearest(p: Vector3, stride: int = 6) -> Vector2:
	var best := INF
	var h := 0.0
	var i := 0
	while i < n:
		var c := center[i]
		var d := Vector2(p.x - c.x, p.z - c.z).length()
		if d < best:
			best = d
			h = c.y
		i += stride
	return Vector2(best, h)


## O ponto (x, z) está dentro do contorno da pista?
func inside(p: Vector3) -> bool:
	var c := false
	var j := n - 1
	for i in n:
		var a := center[i]
		var b := center[j]
		if (a.z > p.z) != (b.z > p.z) and p.x < (b.x - a.x) * (p.z - a.z) / (b.z - a.z + 0.0001) + a.x:
			c = not c
		j = i
	return c
