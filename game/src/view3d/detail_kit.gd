class_name DetailKit
extends RefCounted
## Peças de detalhe da pista 3D (2026-11-14, pedido do usuário: pista mais detalhada, nível de jogo de gestão de
## automobilismo, sem copiar nenhum). Tudo é acumulado em poucas malhas (um SurfaceTool com cor por vértice, uma
## multimalha de público e uma de placas) para o celular aguentar.
##
## "Volume" barato: cada caixa sai com a base mais escura (sombra de canto, como oclusão de ambiente) e o topo um pouco
## mais claro; os lados viram para o sol com tons diferentes.

const AO := 0.38  ## quanto a base escurece
const CROWD := [Color("#e8392e"), Color("#f2f2f2"), Color("#2f6fd0"), Color("#f2b705"), Color("#1d1d1f"), Color("#ff7a00"),
	Color("#19a3a3"), Color("#7a4fd6"), Color("#e86a9a"), Color("#3a8f4f")]

var st := SurfaceTool.new()
var crowd_st := SurfaceTool.new()  ## público: uma faixa por fileira com a textura de torcedores (1 pixel = 1 pessoa)
var _crowd_empty := true
var boards: Array[Transform3D] = []
var board_colors: Array[Color] = []  ## r = desenho da placa (0..7), usado como coluna do atlas
var rng := RandomNumberGenerator.new()
var _empty := true


func _init(seed_value: int = 1) -> void:
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	crowd_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	rng.seed = seed_value


# --- geometria básica ----------------------------------------------------------------------------------

## Caixa centrada em xf.origin, eixos de xf.basis (x = largura, y = altura, z = comprimento).
func box(xf: Transform3D, size: Vector3, col: Color, ao: float = AO) -> void:
	var h := size / 2.0
	var faces := [
		[Vector3.UP, [Vector3(-1, 1, -1), Vector3(1, 1, -1), Vector3(1, 1, 1), Vector3(-1, 1, 1)]],
		[Vector3.RIGHT, [Vector3(1, -1, -1), Vector3(1, -1, 1), Vector3(1, 1, 1), Vector3(1, 1, -1)]],
		[Vector3.LEFT, [Vector3(-1, -1, 1), Vector3(-1, -1, -1), Vector3(-1, 1, -1), Vector3(-1, 1, 1)]],
		[Vector3.BACK, [Vector3(1, -1, 1), Vector3(-1, -1, 1), Vector3(-1, 1, 1), Vector3(1, 1, 1)]],
		[Vector3.FORWARD, [Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(1, 1, -1), Vector3(-1, 1, -1)]],
		[Vector3.DOWN, [Vector3(-1, -1, 1), Vector3(1, -1, 1), Vector3(1, -1, -1), Vector3(-1, -1, -1)]],
	]
	for f: Array in faces:
		var n: Vector3 = xf.basis * (f[0] as Vector3)
		n = n.normalized()
		var q: Array = f[1]
		var top := (f[0] as Vector3).y > 0.5
		for k in [0, 2, 1, 0, 3, 2]:
			var lp: Vector3 = q[k]
			var c := col.lightened(0.06) if top else col
			if lp.y < 0.0 and not top:
				c = c.darkened(ao)  # sombra de canto na base
			st.set_color(c)
			st.set_normal(n)
			st.add_vertex(xf * (lp * h))
	_empty = false


## Quadrilátero (dois lados) com cor única.
func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color) -> void:
	var n := (b - a).cross(d - a).normalized()
	for v: Vector3 in [a, b, c, a, c, d]:
		st.set_color(col)
		st.set_normal(n)
		st.add_vertex(v)
	_empty = false


## Faixa de público: frente (vertical, 0,8 m) e topo (0,4 m) de uma fileira; u = pessoas ao longo, v = linha do atlas.
func _crowd_strip(front: Vector3, out: Vector3, along: Vector3, length: float, row: float) -> void:
	var a := front - along * length / 2.0
	var b := front + along * length / 2.0
	var up := Vector3.UP * 0.8
	var back := out * 0.4
	var u1 := length / 0.62
	var v0 := row / 64.0
	var v1 := (row + 1.0) / 64.0
	for q: Array in [[a, b, b + up, a + up, -out], [a + up, b + up, b + up + back, a + up + back, Vector3.UP]]:
		var uv := [Vector2(0, v1), Vector2(u1, v1), Vector2(u1, v0), Vector2(0, v0)]
		for k in [0, 1, 2, 0, 2, 3]:
			crowd_st.set_normal(q[4])
			crowd_st.set_uv(uv[k])
			crowd_st.add_vertex(q[k])
	_crowd_empty = false


func mesh() -> ArrayMesh:
	return null if _empty else st.commit()


# --- arquibancada ----------------------------------------------------------------------------------------

## Arquibancada: degraus de concreto com fileiras de cadeiras na cor dada, público, parede de fundo e cobertura em
## balanço com faixa colorida e pilares. b.z = ao longo da pista; out = para longe da pista; base = frente, no chão.
func grandstand(b: Basis, base: Vector3, out: Vector3, length: float, seat: Color, rows: int = 9) -> void:
	var conc := Color("#b9bcc1")
	var depth := 0.9
	var rise := 0.55
	var bb := Basis(out, Vector3.UP, b.z)  # x = para fora, z = ao longo
	for i in rows:
		var hgt := 1.0 + i * rise
		var c := base + out * (i * depth + depth / 2.0) + Vector3.UP * (hgt / 2.0)
		box(Transform3D(bb, c), Vector3(depth, hgt, length), conc, 0.25)
		# fileira de cadeiras na frente do degrau
		var sc := base + out * (i * depth + 0.3) + Vector3.UP * (hgt + 0.2)
		box(Transform3D(bb, sc), Vector3(0.45, 0.4, length - 0.4), seat.darkened(0.08 * (i % 2)), 0.1)
		# público: faixa inclinada sobre a fileira (topo e frente), textura com ~70% das cadeiras ocupadas
		var fa := base + out * (i * depth + 0.2) + Vector3.UP * (hgt + 0.25)
		_crowd_strip(fa, out, b.z, length - 0.6, float(rng.randi() % 64))
	var top := 1.0 + rows * rise
	var back := base + out * (rows * depth + 0.3)
	box(Transform3D(bb, back + Vector3.UP * (top + 1.6) / 2.0), Vector3(0.6, top + 1.6, length), conc.darkened(0.1), 0.3)
	# cobertura em balanço: laje inclinada do fundo para a frente, faixa colorida na borda e pilares atrás
	var roof_h := top + 4.2
	var span := rows * depth * 0.55 + 1.0  # cobre a metade de trás: de cima ainda se vê o público da frente
	var roof_c := base + out * (rows * depth - span / 2.0 + 0.6) + Vector3.UP * roof_h
	var tilt := Basis(b.z, deg_to_rad(-4.0)) * bb
	box(Transform3D(tilt, roof_c), Vector3(span, 0.35, length + 1.0), Color("#c3c8ce"), 0.0)
	var edge := base + out * (rows * depth - span + 0.6) + Vector3.UP * (roof_h - 0.15)
	box(Transform3D(bb, edge), Vector3(0.3, 1.1, length + 1.0), seat, 0.0)
	var cols := maxi(2, int(length / 12.0))
	for k in cols + 1:
		var along := -length / 2.0 + length * float(k) / cols
		var p := back + out * 0.5 + b.z * along
		box(Transform3D(bb, p + Vector3.UP * roof_h / 2.0), Vector3(0.5, roof_h, 0.5), Color("#6d737a"), 0.2)
		# viga da cobertura (do pilar até a frente)
		var beam := p + Vector3.UP * (roof_h + 0.45) - out * (span / 2.0 - 0.2)
		box(Transform3D(bb, beam), Vector3(span, 0.4, 0.3), Color("#5e646b"), 0.0)


# --- objetos de pista ------------------------------------------------------------------------------------

## Placa de publicidade sobre duas pernas (desenho sorteado entre os 8 do atlas). b.x aponta para a pista.
func billboard(b: Basis, base: Vector3, width: float = 12.0, height: float = 2.6, lift: float = 1.2) -> void:
	for s: float in [-0.42, 0.42]:
		box(Transform3D(b, base + b.z * (width * s) + Vector3.UP * lift / 2.0), Vector3(0.25, lift, 0.25), Color("#4a4f56"), 0.2)
	box(Transform3D(b, base + Vector3.UP * (lift + height / 2.0) - b.x * 0.18), Vector3(0.2, height + 0.2, width + 0.2), Color("#2d3136"), 0.1)
	boards.append(Transform3D(b.scaled(Vector3(1.0, height, width)), base + Vector3.UP * (lift + height / 2.0)))
	board_colors.append(Color(float(rng.randi() % 8) / 8.0, 0, 0))


## Posto de comissário: casinha laranja com teto branco.
func marshal_post(b: Basis, base: Vector3) -> void:
	box(Transform3D(b, base + Vector3.UP * 1.2), Vector3(2.2, 2.4, 2.2), Color("#f07d1a"), 0.3)
	box(Transform3D(b, base + Vector3.UP * 2.55), Vector3(2.8, 0.3, 2.8), Color("#f4f4f4"), 0.0)


## Tenda de hospitalidade: base branca e telhado em pirâmide.
func tent(b: Basis, base: Vector3, size: float, col: Color) -> void:
	box(Transform3D(b, base + Vector3.UP * 1.5), Vector3(size, 3.0, size), Color("#f2f3f5"), 0.3)
	box(Transform3D(b, base + Vector3.UP * 0.4), Vector3(size + 0.05, 0.8, size + 0.05), col, 0.2)
	var top := base + Vector3.UP * 5.0
	var c := [base + Vector3.UP * 3.0 + b.x * size / 2.0 + b.z * size / 2.0, base + Vector3.UP * 3.0 - b.x * size / 2.0 + b.z * size / 2.0,
		base + Vector3.UP * 3.0 - b.x * size / 2.0 - b.z * size / 2.0, base + Vector3.UP * 3.0 + b.x * size / 2.0 - b.z * size / 2.0]
	for i in 4:
		var a: Vector3 = c[i]
		var d: Vector3 = c[(i + 1) % 4]
		quad(a, d, top, top, Color("#f7f7f7") if i % 2 == 0 else Color("#e4e6e9"))


## Placas de distância antes da freada (300/200/100 m): postes com painel branco e faixas pretas.
func distance_board(b: Basis, base: Vector3, stripes: int) -> void:
	box(Transform3D(b, base + Vector3.UP * 1.0), Vector3(0.15, 2.0, 0.15), Color("#5a5f66"), 0.2)
	box(Transform3D(b, base + Vector3.UP * 2.5), Vector3(0.15, 1.2, 1.4), Color("#f4f4f4"), 0.0)
	for k in stripes:
		box(Transform3D(b, base + Vector3.UP * (2.15 + k * 0.32) - b.x * 0.02), Vector3(0.16, 0.14, 1.3), Color("#1d1d1f"), 0.0)


## Poste da tela de proteção.
func fence_post(b: Basis, base: Vector3, height: float) -> void:
	box(Transform3D(b, base + Vector3.UP * height / 2.0), Vector3(0.18, height, 0.18), Color("#7c838b"), 0.15)


# --- montagem dos nós -------------------------------------------------------------------------------------

## Nós prontos: malha principal (cor por vértice), público e placas. Adiciona em `parent`.
func build_into(parent: Node3D, night: bool) -> void:
	var m := mesh()
	if m != null:
		var mi := MeshInstance3D.new()
		mi.mesh = m
		var mat := Materials3D.vertex_color(0.75)
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		if night:
			mat.albedo_color = Color(0.62, 0.66, 0.78)
		mi.material_override = mat
		parent.add_child(mi)
	if not _crowd_empty:
		var cm := MeshInstance3D.new()
		cm.mesh = crowd_st.commit()
		cm.material_override = Materials3D.crowd(night)
		parent.add_child(cm)
	if not boards.is_empty():
		var qm := QuadMesh.new()  # face na direção +x (para a pista): gira o quad padrão (que olha para +z)
		qm.size = Vector2(1.0, 1.0)
		qm.orientation = PlaneMesh.FACE_X
		parent.add_child(_multi(qm, boards, board_colors, Materials3D.ad_boards(night)))


func _multi(mesh_res: Mesh, xforms: Array[Transform3D], colors: Array[Color], mat: Material) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh_res
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		mm.set_instance_color(i, colors[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	return mmi
