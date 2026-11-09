class_name SectorStrip
extends Control
## Setores da volta na classificação (pedido de 2026-11-09): três faixas S1 · S2 · S3 que acendem quando o carro
## fecha cada setor — roxo = melhor da sessão, verde = melhor do piloto, amarelo = mais lento que o melhor dele.
## Faixas finas e sem texto, como na transmissão; o setor em andamento pisca de leve em branco.

const COLORS := {"purple": Color("#b14dff"), "green": Color("#2fd38a"), "yellow": Color("#ffd24a")}

var marks: Array = []  ## [{time, color}] dos setores fechados
var running := false  ## volta lançada em andamento (contorno no próximo setor)


func _init() -> void:
	custom_minimum_size = Vector2(0, 8)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_state(p_marks: Array, p_running: bool) -> void:
	if p_marks == marks and p_running == running:
		return
	marks = p_marks.duplicate()
	running = p_running
	queue_redraw()


func _draw() -> void:
	var n := QualiSim.SECTORS
	var gap := 4.0
	var w := (size.x - gap * (n - 1)) / n
	var h := minf(size.y, 6.0)
	var y := (size.y - h) / 2.0
	for i in n:
		var r := Rect2(i * (w + gap), y, w, h)
		var col := Color(1, 1, 1, 0.12)
		if i < marks.size():
			col = COLORS.get(String((marks[i] as Dictionary)["color"]), Color.GRAY)
		elif running and i == marks.size():
			col = Color(1, 1, 1, 0.45)
		draw_rect(r, col)
