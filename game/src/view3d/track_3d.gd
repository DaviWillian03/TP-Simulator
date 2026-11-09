class_name Track3D
extends RefCounted
## Geometria 3D da pista a partir do traçado (TrackModel) e do perfil de relevo:
## amostras ao longo da volta, faixa de asfalto, linhas brancas, zebras nas curvas e pit lane.
## Coordenadas em metros: x = leste, z = sul (como o traçado), y = altura.

const WIDTH := 14.0
const STEP_M := 4.0
const KERB_W := 1.6
const LINE_W := 0.35
## Curvatura (rad em ~24 m) a partir da qual há área de escape com brita: raio < ~200 m.
const SHARP_CORNER := 0.12

var track: TrackModel
var n := 0
var center := PackedVector3Array()
var right := PackedVector3Array()  ## vetor para a direita do sentido de corrida
var curvature := PackedFloat32Array()
var inside_limit := PackedFloat32Array()  ## por amostra: distância máxima do eixo do lado de DENTRO da curva (evita dobras)
var turn := PackedFloat32Array()  ## +1 = virando à esquerda (dentro = esquerda), −1 = direita, 0 = reta


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
	# raio local (pelas 6 amostras em volta) e o lado de dentro: faixas largas não podem passar do centro da curva
	var raw := PackedFloat32Array()
	for i in n:
		var a := center[i] - center[(i - 3 + n) % n]
		var b := center[(i + 3) % n] - center[i]
		turn.append(signf(a.cross(b).y) if curvature[i] > 0.01 else 0.0)
		var r := (STEP_M * 6.0) / maxf(curvature[i], 0.0001)
		raw.append(clampf(r * 0.8, WIDTH / 2.0 + 2.0, 400.0))
	for i in n:  # o menor raio por perto (a faixa vizinha também dobraria)
		var m := 400.0
		for k in range(-8, 9):
			m = minf(m, raw[(i + k + n) % n])
		inside_limit.append(m)


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


## Zebras nas curvas com as cores reais do circuito (scenery.kerbs; padrão vermelho/branco), alternando a cada ~4 m.
func kerbs() -> ArrayMesh:
	var palette: Array[Color] = []
	for h: String in track.scenery.get("kerbs", ["#d42020", "#f2f2f2"]):  # cores reais das zebras de cada circuito
		palette.append(Color(h))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side: float in [-1.0, 1.0]:
		var a := side * WIDTH / 2.0
		var b := side * (WIDTH / 2.0 + KERB_W)
		for i in n:
			if not (is_corner(i) or is_corner((i + 2) % n) or is_corner((i - 2 + n) % n)):
				continue
			var j := (i + 1) % n
			var col := palette[i % palette.size()]
			var lift := 0.06
			var quad := [center[i] + right[i] * a, center[j] + right[j] * a, center[j] + right[j] * b, center[i] + right[i] * b]
			for k in [0, 1, 2, 0, 2, 3]:
				st.set_color(col)
				st.set_normal(Vector3.UP)
				st.add_vertex(quad[k] + Vector3.UP * lift)
	return st.commit()


# --- pit lane (2026-11-09): sai da pista em diagonal, corre separado por um muro e volta em diagonal ----

const PIT_LANE_W := 11.0
const PIT_GAP := 6.0  ## grama/muro entre a borda da pista e o pit lane
const PIT_RAMP_M := 110.0  ## comprimento da diagonal de entrada e de saída


## Metros percorridos dentro do pit lane na fração (−1 fora dele) e o comprimento total do pit lane.
func pit_progress(frac: float) -> Vector2:
	var total := fposmod(track.pit_exit_frac - track.pit_entry_frac, 1.0) * track.length_m
	var s := fposmod(frac - track.pit_entry_frac, 1.0) * track.length_m
	return Vector2(s if s <= total else -1.0, total)


## 0 na pista, 1 no pit lane já separado; sobe na diagonal de entrada e desce na de saída.
func pit_ramp(frac: float) -> float:
	var pp := pit_progress(frac)
	if pp.x < 0.0:
		return 0.0
	var a := smoothstep(0.0, PIT_RAMP_M, pp.x)
	var b := smoothstep(0.0, PIT_RAMP_M, pp.y - pp.x)
	return minf(a, b)


## Deslocamento lateral do centro do pit lane (m, + = direita) na fração.
func pit_offset(frac: float) -> float:
	var r := pit_ramp(frac)
	var near := WIDTH / 2.0 - PIT_LANE_W / 2.0 + 1.0
	var far := WIDTH / 2.0 + PIT_GAP + PIT_LANE_W / 2.0
	return track.pit_side * lerpf(near, far, r)


## Faixa ao longo do pit lane: do deslocamento a ao b medidos a partir do centro do pit lane (para fora = +).
func pit_strip(a: float, b: float, lift: float, min_ramp: float = 0.0, colors: Array = []) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dist := 0.0
	for i in n:
		var j := (i + 1) % n
		var fi := float(i) / n
		var fj := float(j) / n
		if pit_progress(fi).x < 0.0 or pit_progress(fj).x < 0.0 or minf(pit_ramp(fi), pit_ramp(fj)) < min_ramp:
			continue
		var side := track.pit_side
		var oi := pit_offset(fi)
		var oj := pit_offset(fj)
		var p0a := center[i] + right[i] * (oi + side * a) + Vector3.UP * lift
		var p0b := center[i] + right[i] * (oi + side * b) + Vector3.UP * lift
		var p1a := center[j] + right[j] * (oj + side * a) + Vector3.UP * lift
		var p1b := center[j] + right[j] * (oj + side * b) + Vector3.UP * lift
		var col: Color = colors[i % colors.size()] if not colors.is_empty() else Color.WHITE
		var seg := center[i].distance_to(center[j])
		for v: Array in [[p0a, Vector2(0, dist / 8.0)], [p1a, Vector2(0, (dist + seg) / 8.0)], [p1b, Vector2(1, (dist + seg) / 8.0)],
				[p0a, Vector2(0, dist / 8.0)], [p1b, Vector2(1, (dist + seg) / 8.0)], [p0b, Vector2(1, dist / 8.0)]]:
			st.set_color(col)
			st.set_normal(Vector3.UP)
			st.set_uv(v[1])
			st.add_vertex(v[0])
		dist += seg
	return st.commit()


## Área pintada (zebrada) entre a borda da pista e o pit lane nas diagonais de entrada e saída.
func pit_gore(lift: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var side := track.pit_side
	for i in n:
		var j := (i + 1) % n
		var fi := float(i) / n
		var fj := float(j) / n
		var ri := pit_ramp(fi)
		var rj := pit_ramp(fj)
		if pit_progress(fi).x < 0.0 or pit_progress(fj).x < 0.0 or (ri > 0.98 and rj > 0.98):
			continue
		var edge := WIDTH / 2.0 + KERB_W * 0.0
		var inner_i := absf(pit_offset(fi)) - PIT_LANE_W / 2.0
		var inner_j := absf(pit_offset(fj)) - PIT_LANE_W / 2.0
		if inner_i <= edge and inner_j <= edge:
			continue
		var col := Color("#f2f2f2") if (i / 2) % 2 == 0 else Color("#3b3e44")
		var q := [center[i] + right[i] * side * edge, center[j] + right[j] * side * edge,
			center[j] + right[j] * side * maxf(inner_j, edge), center[i] + right[i] * side * maxf(inner_i, edge)]
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_color(col)
			st.set_normal(Vector3.UP)
			st.add_vertex(q[k] + Vector3.UP * lift)
	return st.commit()


## Deslocamento lateral limitado do lado de dentro da curva (direita = +; virando à esquerda o lado de dentro é −).
func _clamp_off(i: int, off: float) -> float:
	var inside := (turn[i] > 0.0 and off < 0.0) or (turn[i] < 0.0 and off > 0.0)
	if not inside:
		return off
	return signf(off) * minf(absf(off), inside_limit[i])


## Faixa com altura variável entre as bordas (gramado aparado que desce até o terreno).
func band(a: float, b: float, lift_a: float, lift_b: float, uv_scale: float, mask: Callable = Callable()) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dist := 0.0
	for i in n:
		var j := (i + 1) % n
		var seg := center[i].distance_to(center[j])
		if mask.is_valid() and not mask.call(i):
			dist += seg
			continue
		var p0a := center[i] + right[i] * _clamp_off(i, a) + Vector3.UP * lift_a
		var p0b := center[i] + right[i] * _clamp_off(i, b) + Vector3.UP * lift_b
		var p1a := center[j] + right[j] * _clamp_off(j, a) + Vector3.UP * lift_a
		var p1b := center[j] + right[j] * _clamp_off(j, b) + Vector3.UP * lift_b
		var nrm := Vector3.UP
		for v: Array in [[p0a, Vector2(0, dist / uv_scale)], [p1a, Vector2(0, (dist + seg) / uv_scale)], [p1b, Vector2(1, (dist + seg) / uv_scale)],
				[p0a, Vector2(0, dist / uv_scale)], [p1b, Vector2(1, (dist + seg) / uv_scale)], [p0b, Vector2(1, dist / uv_scale)]]:
			st.set_normal(nrm)
			st.set_uv(v[1])
			st.add_vertex(v[0])
		dist += seg
	return st.commit()


## Parede com várias cores em sequência (placas de publicidade).
func wall_palette(offset: float, height: float, mask: Callable, palette: Array, run: int = 6) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n:
		if not mask.call(i):
			continue
		var j := (i + 1) % n
		var a := center[i] + right[i] * _clamp_off(i, offset)
		var b := center[j] + right[j] * _clamp_off(j, offset)
		var col: Color = palette[(i / run) % palette.size()]
		var nrm := -right[i] * signf(offset)
		for v in [a, b, b + Vector3.UP * height, a, b + Vector3.UP * height, a + Vector3.UP * height]:
			st.set_color(col)
			st.set_normal(nrm)
			st.add_vertex(v)
	return st.commit()


## A amostra i está no trecho do pit lane (da entrada à saída, passando pela linha)?
func in_pit_zone(i: int) -> bool:
	return pit_progress(float(i) / n).x >= 0.0


## Curva ou perto de uma (para brita e barreiras de pneus).
func near_corner(i: int, span: int = 4) -> bool:
	for k in range(-span, span + 1):
		if is_corner((i + k + n) % n):
			return true
	return false


## Lado de fora da curva perto da amostra i: +1 = direita, -1 = esquerda, 0 = reta.
## (O carro que perde a curva escapa para fora, por isso a brita fica desse lado.)
func outside_side(i: int, span: int = 4) -> float:
	var best := SHARP_CORNER
	var side := 0.0
	for k in range(-span, span + 1):
		var m := (i + k + n) % n
		if curvature[m] > best:
			best = curvature[m]
			var a := center[m] - center[(m - 3 + n) % n]
			var b := center[(m + 3) % n] - center[m]
			# y do produto vetorial > 0 = virando à esquerda (x leste, z sul) -> fora = direita
			side = 1.0 if a.cross(b).y > 0.0 else -1.0
	return side


## Parede vertical ao longo da pista no deslocamento lateral dado (guard-rail / barreira).
func wall(offset: float, height: float, mask: Callable, col_a: Color, col_b: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n:
		if not mask.call(i):
			continue
		var j := (i + 1) % n
		var a := center[i] + right[i] * _clamp_off(i, offset)
		var b := center[j] + right[j] * _clamp_off(j, offset)
		var col := col_a if (i % 4) < 2 else col_b
		var nrm := -right[i] * signf(offset)
		for v in [a, b, b + Vector3.UP * height, a, b + Vector3.UP * height, a + Vector3.UP * height]:
			st.set_color(col)
			st.set_normal(nrm)
			st.add_vertex(v)
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
