extends Control
## Escolha de equipe dentro de cada modo (mockups v16-2/v16-3 aprovados, 2026-11-04). Padrão das telas de seleção de
## equipe: nome gigante em contorno atrás do carro, carro em destaque com reflexo, fileira de emblemas embaixo (todos
## com a cor de fundo da equipe). Acrescenta o carro (nota e 4 características), chefe/motor/títulos, os dois pilotos
## (foto, número, idade, nota, títulos) e, na campanha, o objetivo da diretoria.
## Modo vem de Session.team_select_mode: "campaign" (começa a campanha), "gp" (vai à configuração do GP) ou
## (o modo "corrida rápida" saiu em 2026-11-08).

const TRAITS := [["straight", "Reta", "#ffd24a"], ["slow", "Curvas lentas", "#ff6a5a"], ["fast", "Curvas rápidas", "#5c93ea"], ["rel", "Confiabilidade", "#3c9d5d"]]

var _mode := "gp"
var _cat := "F1"  ## categoria mostrada (F1/F2/F3; mockup v23-1)
var _team := ""
var _teams: Array = []
var _layer: Control
var _backdrop: GarageBackdrop
var _slab: Panel
var _giant: Label
var _name: Label
var _car: CarHero
var _info: VBoxContainer
var _drivers: VBoxContainer
var _goal: PanelContainer
var _strip: HBoxContainer
var _mode_label: Label


func _ready() -> void:
	_mode = Session.team_select_mode
	_cat = Session.category
	_teams = GameData.category_teams(_cat)
	_team = Session.player_team if not GameData.team_by_id(_teams, Session.player_team).is_empty() else String(_teams[0]["id"])
	var page := ScreenKit.garage_page(self, _team)
	_backdrop = page["backdrop"]
	_layer = page["layer"]

	_slab = Panel.new()
	ScreenKit.place(_slab, _layer, Control.PRESET_TOP_LEFT, Vector2(470, -26), Vector2(360, 90))
	_giant = Label.new()
	_giant.add_theme_font_override("font", UiStyle.G_BLACK)
	_giant.add_theme_color_override("font_color", Color(0, 0, 0, 0))
	_giant.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.55))
	_giant.add_theme_constant_override("outline_size", 3)
	_giant.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_giant.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_giant)
	_giant.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_giant.offset_top = 118
	_giant.offset_bottom = 320

	var head := VBoxContainer.new()
	head.add_theme_constant_override("separation", 2)
	var tag := PanelContainer.new()
	tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	tag.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.RED, 6, 10, 3))
	tag.add_child(UiStyle.g_label("ESCOLHA DE EQUIPE", 12, Color.WHITE, "black"))
	head.add_child(tag)
	_name = UiStyle.g_label("", 40, UiStyle.G_TEXT, "black")
	head.add_child(_name)
	_mode_label = UiStyle.g_label("", 13, Color("#c3c9d3"), "bold")
	head.add_child(_mode_label)
	ScreenKit.place(head, _layer, Control.PRESET_TOP_LEFT, Vector2(44, 26))
	# F1 / F2 / F3 nos dois modos (decisão de 2026-11-08)
	if _mode != "world":  # o Mundial é só F1
		var seg := ScreenKit.segmented([["F1", "F1"], ["F2", "F2"], ["F3", "F3"]], _cat, _set_category)
		seg.custom_minimum_size = Vector2(240, 0)
		ScreenKit.place(seg, _layer, Control.PRESET_TOP_RIGHT, Vector2(-44, 30))

	_car = CarHero.new()
	_layer.add_child(_car)
	_car.position = Vector2(300, 318)
	_car.custom_minimum_size = Vector2(680, 200)
	_car.size = Vector2(680, 200)

	_info = VBoxContainer.new()
	_info.add_theme_constant_override("separation", 4)
	ScreenKit.place(_glass(_info), _layer, Control.PRESET_TOP_LEFT, Vector2(44, 306), Vector2(256, 0))
	_drivers = VBoxContainer.new()
	_drivers.add_theme_constant_override("separation", 10)
	ScreenKit.place(_glass(_drivers), _layer, Control.PRESET_TOP_RIGHT, Vector2(-44, 306), Vector2(272, 0))
	if _mode == "campaign":
		_goal = _glass(VBoxContainer.new())
		ScreenKit.place(_goal, _layer, Control.PRESET_TOP_RIGHT, Vector2(-44, 90), Vector2(330, 0))

	_strip = HBoxContainer.new()
	_strip.add_theme_constant_override("separation", 6)
	ScreenKit.place(_strip, _layer, Control.PRESET_BOTTOM_LEFT, Vector2(44, -24))
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", 10)
	var back := ScreenKit.glass_pill_button("Voltar", 110)
	back.icon = load("res://assets/icons/back.svg")
	back.add_theme_constant_override("icon_max_width", 18)
	back.custom_minimum_size.y = UiStyle.TOUCH_MAIN
	back.pressed.connect(_back)
	acts.add_child(back)
	var go := CutButton.new()
	go.text = "CONFIRMAR"
	go.custom_minimum_size = Vector2(240, UiStyle.TOUCH_MAIN + 4)
	go.pressed.connect(_confirm)
	acts.add_child(go)
	ScreenKit.place(acts, _layer, Control.PRESET_BOTTOM_RIGHT, Vector2(-44, -24))
	_apply()


func _set_category(cat: String) -> void:
	_cat = cat
	Session.category = cat
	_teams = GameData.category_teams(cat)
	if GameData.team_by_id(_teams, _team).is_empty():
		_team = String(_teams[0]["id"])
	_apply()


func _glass(content: Control) -> PanelContainer:
	var p := PanelContainer.new()
	var st := UiStyle.g_box(Color(0.03, 0.035, 0.047, 0.74), 20, 14, 12)
	st.set_border_width_all(1)
	st.border_color = Color(1, 1, 1, 0.08)
	p.add_theme_stylebox_override("panel", st)
	p.add_child(content)
	return p


func _team_rank(tid: String) -> int:
	var sorted := _teams.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["car_rating"]) > float(b["car_rating"]))
	for i in sorted.size():
		if sorted[i]["id"] == tid:
			return i + 1
	return sorted.size()


func _apply() -> void:
	var t := GameData.team_by_id(_teams, _team)
	var col := Color(t["color"])
	_backdrop.set_glow(col, 0.32)
	var sb := UiStyle.g_box(col, 26, 0, 0)
	sb.corner_radius_top_left = 0
	sb.corner_radius_top_right = 0
	_slab.add_theme_stylebox_override("panel", sb)
	var nm := String(t["name"]).to_upper()
	_name.text = nm
	var base_label: String = {"campaign": "CAMPANHA · EQUIPE REAL", "gp": "GRANDE PRÊMIO", "world": "CAMPEONATO MUNDIAL F1"}.get(_mode, "")
	_mode_label.text = base_label + ("" if _cat == "F1" else " · " + String(CategoryRules.of(_cat)["name"]).to_upper())
	_giant.text = nm
	var fs := 178
	while fs > 80 and UiStyle.G_BLACK.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > 1220:
		fs -= 6
	_giant.add_theme_font_size_override("font_size", fs)
	var drivers: Array = GameData.category_drivers(_cat).filter(func(d: Dictionary) -> bool: return d["team"] == _team)
	var c2 := Color(t.get("color2", "#ffffff"))
	_car.set_team(_team, int(drivers[0]["number"]) if not drivers.is_empty() else 0, c2 if c2.get_luminance() > 0.35 else Color.WHITE, t)
	_fill_info(t)
	_fill_drivers(drivers, col)
	if _goal != null:
		_goal.visible = not CategoryRules.is_feeder(_cat)
	if _goal != null and _goal.visible:
		var gv: VBoxContainer = _goal.get_child(0)
		for c in gv.get_children():
			c.queue_free()
		var rank := _team_rank(_team)
		var cap := UiStyle.g_caption("Objetivo da diretoria")
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		gv.add_child(cap)
		var g := UiStyle.g_label("Top %d dos construtores" % rank, 20, UiStyle.G_TEXT, "black")
		g.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		gv.add_child(g)
		var s := UiStyle.g_label(("Brigar pelo título" if rank <= 2 else ("Pódios regulares" if rank <= 4 else ("Pontos toda corrida" if rank <= 7 else "Sair do fundo do grid"))), 12, UiStyle.G_TEXT_2, "bold")
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		gv.add_child(s)
	_fill_strip()


func _fill_info(t: Dictionary) -> void:
	for c in _info.get_children():
		c.queue_free()
	if CategoryRules.is_feeder(_cat):
		_fill_feeder_info(t)
		return
	_info.add_child(UiStyle.g_caption("Carro %d" % 2026))
	var big := HBoxContainer.new()
	big.add_theme_constant_override("separation", 8)
	var base := float(t["car_rating"])
	big.add_child(UiStyle.g_label("%d" % roundi(base), 32, UiStyle.G_TEXT, "black"))
	var bl := UiStyle.g_label("nota geral · %dº carro do grid" % _team_rank(_team), 12, UiStyle.G_TEXT_2, "bold")
	bl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	big.add_child(bl)
	_info.add_child(big)
	var tr: Dictionary = t.get("car_traits", {})
	for row: Array in TRAITS:
		var v := float(tr.get("rel", 80)) if row[0] == "rel" else base + float(tr.get(row[0], 0.0))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		var l := UiStyle.g_label(row[1], 12, Color("#c3c9d3"), "bold")
		l.custom_minimum_size = Vector2(104, 0)
		h.add_child(l)
		var bar := _Bar.new()
		bar.value = clampf((v - 60.0) / 40.0, 0.0, 1.0)
		bar.color = Color(row[2])
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(bar)
		var n := UiStyle.g_label("%d" % roundi(v), 13, UiStyle.G_TEXT, "black")
		n.custom_minimum_size = Vector2(26, 0)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h.add_child(n)
		_info.add_child(h)
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 2)
	_info.add_child(sp)
	var titles: Variant = t.get("constructors_titles")
	for kv: Array in [["Chefe de equipe", t.get("principal") if t.get("principal") != null else "—"], ["Diretor técnico", t.get("technical_director") if t.get("technical_director") != null else "—"],
			["Motor", t.get("power_unit", "—")], ["Sede", t.get("hq", "—")], ["Equipe atual desde", str(int(t["founded"])) if t.has("founded") else "—"],
			["Títulos de construtores", str(int(titles)) if titles != null else "—"]]:
		var h2 := HBoxContainer.new()
		var k := UiStyle.g_label(kv[0], 12, UiStyle.G_TEXT_2, "bold")
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h2.add_child(k)
		h2.add_child(UiStyle.g_label(String(kv[1]), 12, UiStyle.G_TEXT, "black"))
		_info.add_child(h2)


## F2/F3: o chassi é igual para todos; a nota é a operação da equipe (mockup v23-1).
func _fill_feeder_info(t: Dictionary) -> void:
	_info.add_child(UiStyle.g_caption("Carro 2026 · %s" % _cat))
	var big := HBoxContainer.new()
	big.add_theme_constant_override("separation", 8)
	big.add_child(UiStyle.g_label("%d" % CategoryRules.operation_score(t, _teams), 32, UiStyle.G_TEXT, "black"))
	var bl := UiStyle.g_label("operação da equipe · %dº" % _team_rank(_team), 12, UiStyle.G_TEXT_2, "bold")
	bl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	big.add_child(bl)
	_info.add_child(big)
	var lv := CategoryRules.operation_levels(t, _teams)
	for kv: Array in [["Chassi", "Dallara %s (igual para todos)" % _cat], ["Motor", "Mecachrome V6"],
			["Engenharia", "nível %d" % int(lv["eng"])], ["Mecânicos", "nível %d" % int(lv["mech"])], ["Simulador", "nível %d" % int(lv["sim"])]]:
		var h2 := HBoxContainer.new()
		var k := UiStyle.g_label(kv[0], 12, UiStyle.G_TEXT_2, "bold")
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h2.add_child(k)
		h2.add_child(UiStyle.g_label(String(kv[1]), 12, UiStyle.G_TEXT, "black"))
		_info.add_child(h2)


func _fill_drivers(drivers: Array, col: Color) -> void:
	for c in _drivers.get_children():
		c.queue_free()
	_drivers.add_child(UiStyle.g_caption("Pilotos"))
	for d: Dictionary in drivers:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.05), 14, 10, 10))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		var num := UiStyle.g_label(str(int(d["number"])), 30, Color(0, 0, 0, 0), "black")
		num.add_theme_color_override("font_outline_color", Color.WHITE)
		num.add_theme_constant_override("outline_size", 3)
		num.custom_minimum_size = Vector2(42, 0)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(num)
		var face := DriverPhotos.make_avatar(d, col, 56)
		face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(face)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", -2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nm := UiStyle.g_label(String(d["name"]), 16, UiStyle.G_TEXT, "black")
		nm.clip_text = true
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		v.add_child(nm)
		var age := DriverCareer.age_in(d, 2026)
		v.add_child(UiStyle.g_label("%s · %d anos" % [d.get("nationality", ""), age], 12, UiStyle.G_TEXT_2, "bold"))
		var chips := HBoxContainer.new()
		chips.add_theme_constant_override("separation", 6)
		var nt := int(d.get("titles", 0))
		var chip_texts: Array = ["Nota %d" % int(d.get("rating", 0)), "%d título%s" % [nt, "" if nt == 1 else "s"]]
		if CategoryRules.is_feeder(_cat):  # piloto pagante: quanto traz por ano
			chip_texts[1] = "traz US$ %s mi" % String.num(CategoryRules.pay_musd(_cat, float(d.get("rating", 60))), 1).replace(".", ",")
		for i in chip_texts.size():
			var p := PanelContainer.new()
			p.add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.1), 6, 6, 1))
			p.add_child(UiStyle.g_label(chip_texts[i], 12, UiStyle.G_UP if (i == 1 and CategoryRules.is_feeder(_cat)) else UiStyle.G_TEXT, "black"))
			chips.add_child(p)
		v.add_child(chips)
		h.add_child(v)
		card.add_child(h)
		_drivers.add_child(card)


func _fill_strip() -> void:
	for c in _strip.get_children():
		c.queue_free()
	for t: Dictionary in _teams:
		var tid := String(t["id"])
		var on := tid == _team
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(64, 64)
		b.tooltip_text = String(t["name"])
		var st := UiStyle.g_box(TeamEmblems._frame_color(t), 14, 0, 0)  # todos com a cor de fundo da equipe (pedido do usuário)
		st.set_border_width_all(3 if on else 0)
		st.border_color = Color.WHITE
		if on:
			st.shadow_color = Color(0, 0, 0, 0.55)
			st.shadow_size = 12
		for s: String in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
			b.add_theme_stylebox_override(s, st)
		var cc := CenterContainer.new()
		cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var em := TeamEmblems.make_rect(tid, 44)
		em.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cc.add_child(em)
		b.add_child(cc)
		b.pressed.connect(func() -> void:
			_team = tid
			_apply())
		ScreenKit.press_feedback(b)
		var wrap := Control.new()  # o escolhido sobe um pouco, sem empurrar os outros
		wrap.custom_minimum_size = Vector2(64, 64)
		wrap.add_child(b)
		b.position = Vector2(0, -8 if on else 0)
		b.size = Vector2(64, 64)
		_strip.add_child(wrap)


func _confirm() -> void:
	Session.player_team = _team
	Session.category = _cat
	match _mode:
		"campaign":  # F2/F3: campanha na categoria de base (a F1 corre simulada)
			Session.start_campaign(Campaign.new_feeder(_team) if CategoryRules.is_feeder(_cat) else Campaign.new_real(_team))
		"world":
			Session.start_world(_team)
		_:
			Session.open_gp_setup()


func _back() -> void:
	if _mode == "campaign":
		Session.open_campaign()
	else:
		Session.go_to_title()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_back()


## Barra horizontal simples (0..1).
class _Bar:
	extends Control
	var value := 0.5
	var color := Color.WHITE

	func _init() -> void:
		custom_minimum_size = Vector2(0, 7)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_style_box(UiStyle.g_box(Color(1, 1, 1, 0.12), 4, 0, 0), Rect2(Vector2.ZERO, size))
		draw_style_box(UiStyle.g_box(color, 4, 0, 0), Rect2(Vector2.ZERO, Vector2(size.x * clampf(value, 0.03, 1.0), size.y)))
