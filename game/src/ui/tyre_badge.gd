class_name TyreBadge
extends Control
## Pneu como nas transmissões: círculo escuro com aro na cor do composto e a letra no meio.

var letter := ""
var ring := Color.WHITE


func _init() -> void:
	custom_minimum_size = Vector2(19, 19)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_compound(p_letter: String, p_color: Color) -> void:
	if p_letter == letter and p_color == ring:
		return
	letter = p_letter
	ring = p_color
	queue_redraw()


func _draw() -> void:
	if letter == "":
		return
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 0.5
	draw_circle(c, r, ring, true, -1.0, true)
	draw_circle(c, r - 3.0, UiStyle.INK, true, -1.0, true)
	var font := UiStyle.HEAVY_FONT
	var fs := 9
	var w := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, c + Vector2(-w / 2.0, 3.5), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
