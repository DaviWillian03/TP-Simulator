class_name ChampionshipCard
extends PanelContainer
## Pop-up do campeonato ao vivo na corrida (mockups v17 aprovados, 2026-11-04): "se terminar assim" para pilotos ou
## construtores, e o cartão dourado "título em jogo". Aparece no alto da tela, some sozinho e não bloqueia toques.

const LIFETIME_S := 6.0
const GOLD := Color("#c9971a")

var _body: VBoxContainer
var _head: PanelContainer
var _head_label: Label
var _head_sub: Label
var _icon: TextureRect
var _tween: Tween


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(500, 0)
	var st := UiStyle.g_box(Color(0.03, 0.035, 0.047, 0.92), 18, 0, 0)
	st.set_border_width_all(1)
	st.border_color = Color(1, 1, 1, 0.1)
	st.shadow_color = Color(0, 0, 0, 0.5)
	st.shadow_size = 16
	add_theme_stylebox_override("panel", st)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)
	_head = PanelContainer.new()
	_head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hh := HBoxContainer.new()
	hh.add_theme_constant_override("separation", 10)
	_icon = ScreenKit.icon("flag", 18, Color.WHITE)
	hh.add_child(_icon)
	_head_label = UiStyle.g_label("", 13, Color.WHITE, "black")
	_head_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hh.add_child(_head_label)
	_head_sub = UiStyle.g_label("", 12, Color(1, 1, 1, 0.9), "bold")
	hh.add_child(_head_sub)
	_head.add_child(hh)
	v.add_child(_head)
	var m := MarginContainer.new()
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for k: String in ["left", "right"]:
		m.add_theme_constant_override("margin_" + k, 14)
	m.add_theme_constant_override("margin_top", 8)
	m.add_theme_constant_override("margin_bottom", 10)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 4)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(_body)
	v.add_child(m)
	modulate = Color(1, 1, 1, 0)
	visible = false


func _set_head(text: String, sub: String, gold: bool) -> void:
	var hs := UiStyle.g_box(GOLD if gold else UiStyle.RED, 0, 14, 9)
	hs.corner_radius_top_left = 18
	hs.corner_radius_top_right = 18
	_head.add_theme_stylebox_override("panel", hs)
	_head_label.text = text
	_head_sub.text = sub
	_icon.texture = load("res://assets/icons/%s.svg" % ("check" if gold else "flag"))


func _clear() -> void:
	for c in _body.get_children():
		c.queue_free()


## rows: [[id, antes, depois]] (já na ordem projetada); before: ordem de antes (ids) para as setas de posição.
## kind: "drivers" | "teams". names: id -> nome; mine: ids do jogador (destaque); msg: linha final.
func show_standings(kind: String, rows: Array, before: Array, drivers: Dictionary, team_colors: Dictionary, mine: Array, msg: String) -> void:
	_clear()
	_set_head("CAMPEONATO AO VIVO" if kind == "drivers" else "CONSTRUTORES AO VIVO", "se terminar assim", false)
	for i in mini(4, rows.size()):
		var r: Array = rows[i]
		var id: String = r[0]
		var row := PanelContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.08) if mine.has(id) else Color(0, 0, 0, 0), 10, 6, 3))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		var p := UiStyle.g_label(str(i + 1), 16, UiStyle.G_TEXT, "black")
		p.custom_minimum_size = Vector2(22, 0)
		p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h.add_child(p)
		var name := ""
		var sub := ""
		if kind == "drivers":
			var d: Dictionary = drivers.get(id, {})
			h.add_child(DriverPhotos.make_avatar(d, Color(team_colors.get(d.get("team", ""), Color.GRAY)), 32))
			name = String(d.get("name", id))
			sub = String(GameData.team_by_id(_teams(), String(d.get("team", ""))).get("name", ""))
		else:
			h.add_child(TeamEmblems.make_rect(id, 30))
			name = String(GameData.team_by_id(_teams(), id).get("name", id))
		var nv := VBoxContainer.new()
		nv.add_theme_constant_override("separation", -3)
		nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nv.add_child(UiStyle.g_label(name, 15, UiStyle.G_TEXT, "black"))
		if sub != "":
			nv.add_child(UiStyle.g_label(sub, 11, UiStyle.G_TEXT_2, "bold"))
		h.add_child(nv)
		var pts := HBoxContainer.new()
		pts.add_theme_constant_override("separation", 6)
		var before_l := UiStyle.g_label("%d →" % int(r[1]), 13, UiStyle.G_TEXT_2, "bold")
		before_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pts.add_child(before_l)
		pts.add_child(UiStyle.g_label(str(int(r[2])), 17, UiStyle.G_TEXT, "black"))
		h.add_child(pts)
		var bi := before.find(id)
		var mv := UiStyle.g_label("", 13, UiStyle.G_TEXT, "black")
		mv.custom_minimum_size = Vector2(32, 0)
		mv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if bi < 0 or bi > i:
			mv.text = "▲%d" % ((bi - i) if bi >= 0 else 1)
			mv.add_theme_color_override("font_color", Color("#7fe0b1"))
		elif bi < i:
			mv.text = "▼%d" % (i - bi)
			mv.add_theme_color_override("font_color", Color("#ff8a80"))
		h.add_child(mv)
		row.add_child(h)
		_body.add_child(row)
	_add_msg("flag", msg, Color("#ffd24a"))
	_pop()


## Cartão dourado: o título fica decidido se a corrida terminar assim.
func show_title(name: String, driver: Dictionary, team_color: Color, lap_text: String, sub: String, msg: String, is_team: bool, team_id: String = "") -> void:
	_clear()
	_set_head("TÍTULO EM JOGO", lap_text, true)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	h.add_child(TeamEmblems.make_rect(team_id, 60) if is_team else DriverPhotos.make_avatar(driver, team_color, 64))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := UiStyle.g_label("SE TERMINAR ASSIM, %s É CAMPEÃ" % name.to_upper(), 20, UiStyle.G_TEXT, "black")
	if not is_team:
		t.text = "SE TERMINAR ASSIM, %s É CAMPEÃO" % name.to_upper()
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var s := UiStyle.g_label(sub, 13, Color("#c3c9d3"), "bold")
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(s)
	h.add_child(v)
	_body.add_child(h)
	_add_msg("check", msg, Color("#ffd24a"))
	_pop(LIFETIME_S + 2.0)


func _add_msg(icon_name: String, text: String, col: Color) -> void:
	if text == "":
		return
	var sep := ColorRect.new()
	sep.color = Color(1, 1, 1, 0.08)
	sep.custom_minimum_size = Vector2(0, 1)
	_body.add_child(sep)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.add_child(ScreenKit.icon(icon_name, 16, col))
	var l := UiStyle.g_label(text, 13, Color("#c3c9d3"), "bold")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	_body.add_child(h)


func _pop(life: float = LIFETIME_S) -> void:
	visible = true
	move_to_front()  # por cima da pista e dos painéis criados depois
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.2)
	_tween.tween_interval(life)
	_tween.tween_property(self, "modulate:a", 0.0, 0.4)
	_tween.tween_callback(func() -> void: visible = false)


## Equipes da temporada em jogo (2012 tem outro grid); fora de um fim de semana, as de 2026.
func _teams() -> Array:
	return Session.weekend.teams if Session.weekend != null and not Session.weekend.teams.is_empty() else GameData.teams()
