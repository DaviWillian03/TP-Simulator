class_name SafeArea
extends RefCounted
## Área segura da tela (câmera frontal "furo", recortes e cantos). No Galaxy S23 em paisagem o furo da câmera fica
## numa das laterais e tampava botões e cartões. Aqui pegamos os recortes do sistema, convertemos para as unidades
## da interface (1280×720 com "expand") e encolhemos a tela de cada cena por esse tanto. Sem recorte, nada muda.
## Teste no PC: `--cutout=44` (lateral esquerda), `--cutout=0,0,44,0` (esq,topo,dir,base em unidades de UI).

const MARGIN := 10.0  ## folga extra em volta do recorte (unidades de UI)
const MAX_INSET := 90.0  ## nenhum recorte de verdade passa disso; protege contra valores estranhos

static var debug := Vector4.ZERO  ## (esq, topo, dir, base) simulados pelo --cutout


static func install(tree: SceneTree) -> void:
	tree.node_added.connect(func(n: Node) -> void:
		if n is Control and n.get_parent() == tree.root and n.get_script() != null:
			_apply.call_deferred(n))


## Folgas (esq, topo, dir, base) em unidades de UI.
static func insets() -> Vector4:
	if debug != Vector4.ZERO:
		return debug
	var win := DisplayServer.window_get_size()
	if win.x <= 0 or win.y <= 0:
		return Vector4.ZERO
	var scr := DisplayServer.screen_get_size()
	if scr.x <= 0 or scr.y <= 0:
		return Vector4.ZERO
	var px := Vector4.ZERO  # em pixels da tela física
	var safe := DisplayServer.get_display_safe_area()
	if safe.size.x > 0 and safe.size != scr:
		px = Vector4(safe.position.x, safe.position.y, scr.x - safe.end.x, scr.y - safe.end.y)
	for c: Rect2 in DisplayServer.get_display_cutouts():  # cada recorte empurra a borda mais próxima
		if c.size.x <= 0 or c.size.y <= 0:
			continue
		var cx := c.get_center().x / scr.x
		var cy := c.get_center().y / scr.y
		if cx < 0.2:
			px.x = maxf(px.x, c.end.x)
		elif cx > 0.8:
			px.z = maxf(px.z, scr.x - c.position.x)
		elif cy < 0.3:
			px.y = maxf(px.y, c.end.y)
		elif cy > 0.7:
			px.w = maxf(px.w, scr.y - c.position.y)
	# pixels da tela -> unidades de UI (a janela é escalada para caber em 1280×720 com "expand")
	var k := minf(win.x / 1280.0, win.y / 720.0) * (win.x / float(scr.x) if win.x < scr.x else 1.0)
	k = maxf(k, 0.0001)
	var out := Vector4.ZERO
	for i in 4:
		var v := px[i]
		out[i] = minf(v / k + MARGIN, MAX_INSET) if v > 0.5 else 0.0
	return out


## Soma das folgas por eixo (esq+dir, topo+base).
static func size() -> Vector2:
	var i := insets()
	return Vector2(i.x + i.z, i.y + i.w)


static func _apply(n: Node) -> void:
	if not is_instance_valid(n) or not n is Control:
		return
	var c := n as Control
	var i := insets()
	if i == Vector4.ZERO or c.get_meta("safe_applied", false):
		return
	if not (c.anchor_left == 0.0 and c.anchor_top == 0.0 and c.anchor_right == 1.0 and c.anchor_bottom == 1.0):
		return  # só telas que ocupam a janela inteira
	c.set_meta("safe_applied", true)
	c.offset_left += i.x
	c.offset_top += i.y
	c.offset_right -= i.z
	c.offset_bottom -= i.w
