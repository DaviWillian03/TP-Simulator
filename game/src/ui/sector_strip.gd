class_name SectorStrip
extends Control
## Setores da volta na classificação (pedido de 2026-11-09): três faixas S1 · S2 · S3 que acendem quando o carro
## fecha cada setor — roxo = melhor da sessão, verde = melhor do piloto, amarelo = mais lento que o melhor dele.
## O setor em andamento fica com contorno; os que faltam ficam apagados.

const COLORS := {"purple": Color("#b14dff"), "green": Color("#2fd38a"), "yellow": Color("#ffd24a")}

var marks: Array = []  ## [{time, color}] dos setores fechados
var running := false  ## volta lançada em andamento (contorno no próximo setor)


func _init() -> void:
	custom_minimum_size = Vector2(0, 30)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_state(p_marks: Array, p_running: bool) -> void:
	if p_marks == marks and p_running == running:
		return
	marks = p_marks.duplicate()
	running = p_running
	queue_redraw()


func _draw() -> void:
	var n := QualiSim.SECTORS
	var gap := 6.0
	var w := (size.x - gap * (n - 1)) / n
	var font := UiStyle.G_BLACK
	var fs := UiStyle.fs(12)
	for i in n:
		var r := Rect2(i * (w + gap), 0, w, size.y)
		var st := StyleBoxFlat.new()
		st.set_corner_radius_all(8)
		var done := i < marks.size()
		var text_col := Color("#8f98a7")
		var label := "S%d" % (i + 1)
		if done:
			var m: Dictionary = marks[i]
			st.bg_color = COLORS.get(String(m["color"]), Color.GRAY)
			text_col = Color("#11141a") if String(m["color"]) != "purple" else Color.WHITE
			label = "S%d  %s" % [i + 1, String.num(float(m["time"]), 3).replace(".", ",")]
		else:
			st.bg_color = Color(1, 1, 1, 0.08)
			if running and i == marks.size():
				st.border_color = Color(1, 1, 1, 0.7)
				st.set_border_width_all(2)
		draw_style_box(st, r)
		var ts := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		draw_string(font, Vector2(r.position.x + (w - ts.x) / 2.0, r.position.y + (size.y + fs * 0.72) / 2.0), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, text_col)
