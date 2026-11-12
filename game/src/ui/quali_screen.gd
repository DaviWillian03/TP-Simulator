extends Control
## Classificação ao vivo — a pista 3D em tela cheia (mockup v14), com os carros andando de verdade:
## volta de saída, volta lançada e volta de entrada. À esquerda, os cartões dos seus pilotos
## (escolha do pneu e botão de sair para a volta rápida); à direita, a tabela da parte atual com
## a linha vermelha da zona de eliminação. Q1/Q2/Q3 (ou SQ1/SQ2/SQ3 na sprint).
##
## O relógio roda pelo tempo real × velocidade; a simulação (QualiSim) é a mesma de sempre, a tela
## só desenha onde cada carro está na volta dele.

const UI_REFRESH_S := 0.2
const SPEEDS := [2.0, 4.0, 8.0, 16.0]
const LEFT_W := CarControlPanel.WIDTH + 24.0
const TOWER_W := 330.0
const SIDE_TOP := 78.0

var weekend: WeekendSim
var q: QualiSim
var time_scale := 4.0
var _view: TrackView3D
var _table: TimingTable
var _sub: Label
var _info_card: PanelContainer
var _clock: Label
var _clock_caption: Label
var _panels: Array[Dictionary] = []  # {car, pos, status, go: Button, bar, lap}
var _out_sheet: Control  # folha de saída para a pista aberta (v22-1): a sessão fica parada enquanto ela está aberta
var _out_choice := {}  # {car, set, mode, laps}
var _evolution: Label
var _cut_info: Label
var _end_card: PanelContainer
var _toasts: ToastFeed
var _refresh := 0.0
var _radio: RadioCard
var _speeds: PanelContainer


func _ready() -> void:
	Tips.show_once.call_deferred(self, "quali")
	weekend = Session.weekend
	if weekend == null or not weekend.is_quali(weekend.session_id()):
		Session.go_to_title.call_deferred()
		return
	q = weekend.make_quali()
	q.pause_between = true  # ao fim do Q1/Q2 a sessão para e mostra o resultado até você confirmar
	if Session.debug_advance_s > 0.0:  # (capturas de tela: a IA leva também os carros do jogador)
		q.auto_player = true
		if Session.debug_advance_s >= 99999.0:  # (captura) vai até o fim da classificação, sem parar nas partes
			q.run_to_end()
		else:
			q.advance(Session.debug_advance_s)
		q.auto_player = false
	var page := ScreenKit.garage_page(self, weekend.player_team)
	var layer: Control = page["layer"]

	# pista 3D em tela cheia, atrás de todo o resto
	var holder := Control.new()
	layer.add_child(holder)
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view = TrackView3D.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.add_child(_view)
	_view.setup(q)
	if Session.debug_camera.size() > 0:  # (capturas)
		_view.yaw = Session.debug_camera.get("yaw", _view.yaw)
		_view.pitch = Session.debug_camera.get("pitch", _view.pitch)
		_view.distance = Session.debug_camera.get("dist", _view.distance)
		_view.snap_camera = true
	ScreenKit.top_shade(layer)
	_build_top_bar(layer)

	# cartões dos seus pilotos: coluna vertical à esquerda
	var cards := VBoxContainer.new()
	cards.add_theme_constant_override("separation", 12)
	ScreenKit.place(cards, layer, Control.PRESET_TOP_LEFT, Vector2(12, SIDE_TOP))
	for car in q.cars:
		if car.is_player:
			cards.add_child(_player_panel(car))
	if Session.debug_ui == "out" and not _panels.is_empty():  # (captura) --ui=out abre a folha de saída
		_open_out_sheet.call_deferred(_panels[0])

	# tabela da parte atual, à direita
	var tower := PanelContainer.new()
	tower.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_GLASS, 20, 8, 6))
	ScreenKit.place(tower, layer, Control.PRESET_TOP_RIGHT, Vector2(-12, SIDE_TOP), Vector2(TOWER_W, 720.0 - SIDE_TOP - 8.0))
	var scroll := DragScroll.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tower.add_child(scroll)
	_table = TimingTable.new()
	_table.row_h = clampi(560 / q.cars.size(), 22, 26)  # 22 ou 24 carros cabem sem rolar
	_table.me_color = UiStyle.team_color(weekend.player_team)
	_table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_table.setup([
		{"title": "Pos", "width": 32, "kind": "pos"},
		{"title": "Piloto", "width": 0, "kind": "team"},
		{"title": "Melhor", "width": 76, "align": "right"},
		{"title": "Dif.", "width": 62, "align": "right"},
		{"title": "Pn", "width": 28, "kind": "tyre"},
	], q.cars.size(), "garage")
	scroll.add_child(_table)

	# faixa baixa no centro da área livre: pista evoluindo (ou o fim da classificação)
	var area := MarginContainer.new()
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_theme_constant_override("margin_left", int(LEFT_W))
	area.add_theme_constant_override("margin_right", int(TOWER_W + 24.0))
	area.add_theme_constant_override("margin_bottom", 12)
	layer.add_child(area)
	area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_END
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(col)
	_info_card = PanelContainer.new()
	_info_card.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_GLASS, 18, 18, 10))
	var iv := VBoxContainer.new()
	iv.add_theme_constant_override("separation", 2)
	_info_card.add_child(iv)
	_evolution = UiStyle.g_label("", 13, Color("#c3c9d3"))
	_evolution.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	iv.add_child(_evolution)
	_cut_info = UiStyle.g_label("", 13, Color("#ffb4a8"), "bold")
	_cut_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	iv.add_child(_cut_info)
	_radio = RadioCard.new()
	_radio.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(_radio)
	_radio.answered.connect(func(id: int, option: int) -> void:
		q.answer(id, option)
		_refresh_ui())
	col.add_child(_info_card)
	_end_card = _build_end_card()
	_end_card.visible = false
	col.add_child(_end_card)

	_toasts = ToastFeed.new()
	_toasts.position = Vector2(LEFT_W + 14.0, SIDE_TOP + 6.0)
	_toasts.custom_minimum_size = Vector2(440, 0)
	layer.add_child(_toasts)
	q.session_event.connect(func(t: String) -> void: _toasts.push(t))
	q.segment_finished.connect(_on_segment_finished)
	q.lap_completed.connect(_on_lap)
	q.decision_needed.connect(_on_decision)
	_refresh_ui()
	if q.waiting or q.is_over():  # (capturas com --advance chegam aqui já com a parte encerrada)
		_show_result.call_deferred(q.segment)


func _build_top_bar(layer: Control) -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE  # a barra não bloqueia o toque na pista
	ScreenKit.place(bar, layer, Control.PRESET_TOP_LEFT, Vector2(12, 6), Vector2(1256, 60))
	var back := ScreenKit.glass_round_button("back", 44, "Voltar ao fim de semana")
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(Session.go_to_weekend)
	bar.add_child(back)
	var head := ScreenKit.flag_title((("" if weekend.category == "F1" else weekend.category.replace("_", " ") + " · ") + weekend.session_name(weekend.session_id())).to_upper(), 20, String(weekend.circuit.get("country_code", "")))
	_sub = head["sub"]
	bar.add_child(head["box"])

	var speed_pill := PanelContainer.new()
	speed_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	speed_pill.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_GLASS, 24, 3, 3))
	var speed_opts: Array = []
	for s: float in SPEEDS:
		speed_opts.append([s, "%d×" % int(s)])
	var speeds := ScreenKit.segmented(speed_opts, time_scale, func(s: float) -> void: time_scale = s)
	_speeds = speeds
	speeds.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	for b: Control in (speeds.get_child(0) as Control).get_children():
		b.custom_minimum_size = Vector2(50, 40)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	speed_pill.add_child(speeds)
	bar.add_child(speed_pill)
	# desacelerar quando surge uma decisão (opção; vale para a classificação e a corrida)
	var slow := ScreenKit.glass_pill_button("")
	var paint := func() -> void: slow.text = "Pausa em decisões: %s" % ("SIM" if Session.slow_on_decisions else "NÃO")
	paint.call()
	slow.pressed.connect(func() -> void:
		Session.slow_on_decisions = not Session.slow_on_decisions
		paint.call())
	bar.add_child(slow)
	var rest := ScreenKit.glass_pill_button("SIMULAR RESTO")
	rest.pressed.connect(_simulate_rest)
	bar.add_child(rest)

	bar.add_child(UiStyle.hspacer())
	var clock := VBoxContainer.new()
	clock.add_theme_constant_override("separation", -6)
	clock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	clock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clock = UiStyle.g_label("", 30, UiStyle.G_TEXT, "black")
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_clock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clock.add_child(_clock)
	_clock_caption = UiStyle.g_caption("Tempo restante")
	_clock_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_clock_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clock.add_child(_clock_caption)
	bar.add_child(clock)


## Cartão compacto de um dos seus pilotos (mesma linguagem do cartão da corrida).
func _player_panel(car: CarState) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size.x = CarControlPanel.WIDTH
	card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var accent := UiStyle.team_accent(car.team)  # cores da equipe, como no cartão da corrida
	var hi := accent if accent.get_luminance() > 0.3 else accent.lightened(0.35)
	var cst := UiStyle.g_box(UiStyle.team_glass(accent), 20, 12, 10)
	cst.border_width_left = 5
	cst.border_color = accent
	cst.content_margin_left = 14
	card.add_theme_stylebox_override("panel", cst)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 7)
	card.add_child(v)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	var photo := Control.new()
	photo.custom_minimum_size = Vector2(CarControlPanel.PHOTO, CarControlPanel.PHOTO)
	photo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	photo.add_child(DriverPhotos.make_avatar(car.driver, car.team_color(), CarControlPanel.PHOTO))
	# tocar na foto segue esse carro na pista (de novo: volta à vista geral)
	var cam := Button.new()
	cam.flat = true
	cam.focus_mode = Control.FOCUS_NONE
	for st: String in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		cam.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	cam.tooltip_text = "Seguir na pista"
	photo.add_child(cam)
	cam.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cam.pressed.connect(func() -> void: _toasts.push("Câmera: " + _view.follow(car)))
	head.add_child(photo)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", -2)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var full := car.display_name()
	names.add_child(NameFlag.make(full.get_slice(" ", full.get_slice_count(" ") - 1), String(car.driver.get("nationality", "")), 18))
	var pos_row := HBoxContainer.new()
	pos_row.add_theme_constant_override("separation", 6)
	var logo := TeamEmblems.make_rect(String(car.team["id"]), 22)  # ao lado da foto, não por cima
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pos_row.add_child(logo)
	var pos := UiStyle.g_label("P–", 17, hi, "black")
	pos_row.add_child(pos)
	var num := UiStyle.g_label("#%d" % int(car.driver["number"]), 12, UiStyle.G_TEXT_3, "bold")
	num.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pos_row.add_child(num)
	names.add_child(pos_row)
	var status := UiStyle.g_label("", 12, UiStyle.G_TEXT_2, "bold")
	status.clip_text = true
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	names.add_child(status)
	head.add_child(names)
	v.add_child(head)

	var lap := UiStyle.g_label("", 12, Color("#c3c9d3"))
	lap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(lap)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 8)
	bar.add_theme_stylebox_override("background", UiStyle.g_box(Color(1, 1, 1, 0.12), 4, 0, 0))
	bar.add_theme_stylebox_override("fill", UiStyle.g_box(Color("#c77dff"), 4, 0, 0))
	v.add_child(bar)
	var sectors := SectorStrip.new()  # setores da volta: roxo / verde / amarelo
	v.add_child(sectors)
	var go := CutButton.new()
	go.fill_color = accent
	for k: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color"]:
		go.add_theme_color_override(k, UiStyle.ink_on(accent))
	go.custom_minimum_size = Vector2(0, 48)
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.clip_text = true
	for st: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var e := StyleBoxEmpty.new()
		e.content_margin_left = 12
		e.content_margin_right = 8
		go.add_theme_stylebox_override(st, e)
	go.add_theme_constant_override("icon_max_width", 18)
	go.add_theme_constant_override("h_separation", 6)
	go.add_theme_font_size_override("font_size", UiStyle.fs(13))
	v.add_child(go)
	var panel := {"car": car, "pos": pos, "status": status, "go": go, "bar": bar, "lap": lap, "sectors": sectors}
	go.pressed.connect(_open_out_sheet.bind(panel))
	_panels.append(panel)
	return card


# --- folha de saída para a pista (mockup v22-1) ----------------------------------------------

const MODE_INFO := {
	"safe": ["shield", "Garantir tempo", "Volta limpa, com margem nas zebras. Menos chance de erro; cerca de 0,2 s mais lenta."],
	"limit": ["fire", "Buscar o limite", "Tudo na volta: mais rápida, mas com mais chance de erro e de volta apagada (limite de pista)."],
}
const LAPS_INFO := {
	1: ["clock", "1 volta rápida", "Sai, faz a volta e volta para o box. Gasta pouco o jogo."],
	2: ["clock", "2 voltas rápidas", "Volta de resfriamento entre as duas. Segunda chance, mas o pneu cai um pouco."],
}


## Jogos agrupados para a folha: iguais (mesmo composto, mesmas voltas, sem reserva) viram um bloco "×N".
func _set_groups(car: CarState) -> Array:
	var groups: Array = []
	var by_key := {}
	var order := {"soft": 0, "medium": 1, "hard": 2, "inter": 3, "wet": 4}
	var list: Array = q.alloc.available(car.driver["id"], true)
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["compound"] != b["compound"]:
			return int(order[a["compound"]]) < int(order[b["compound"]])
		return int(a["laps"]) < int(b["laps"]))
	var dry_track := q.weather.wetness < 0.05  # pista seca: os jogos de chuva ficam fora da folha
	for s: Dictionary in list:
		if dry_track and s["compound"] in ["inter", "wet"]:
			continue
		var locked: bool = s["q3"] and not q.q3_open
		var key := "%s|%d|%s" % [s["compound"], int(s["laps"]), str(locked)]
		if s["q3"] or not by_key.has(key):
			var g := {"set": s, "count": 1, "locked": locked}
			groups.append(g)
			if not s["q3"]:
				by_key[key] = g
		else:
			by_key[key]["count"] += 1
	return groups


func _open_out_sheet(panel: Dictionary) -> void:
	var car: CarState = panel["car"]
	if not q.can_go_out(car) or _out_sheet != null:
		return
	var def_set := q.best_set(car, q.ai_compound(car))
	_out_choice = {"car": car, "set": def_set, "mode": "safe", "laps": 1}
	var sh := ScreenKit.sheet(String(car.driver["name"]), 1160)
	_out_sheet = sh["root"]
	_out_sheet.tree_exited.connect(func() -> void: _out_sheet = null)
	var body: VBoxContainer = sh["body"]
	body.add_child(UiStyle.g_caption("%s · saída para a pista" % q.segment_name()))
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 18)
	body.add_child(cols)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", UiStyle.SP_S)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(left)
	left.add_child(UiStyle.g_caption("Pneus disponíveis"))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	left.add_child(grid)
	var set_group := ButtonGroup.new()
	for g: Dictionary in _set_groups(car):
		grid.add_child(_set_tile(car, g, set_group))
	left.add_child(UiStyle.g_caption("Atitude na volta"))
	var mrow := HBoxContainer.new()
	mrow.add_theme_constant_override("separation", 10)
	var mgroup := ButtonGroup.new()
	for m: String in ["safe", "limit"]:
		mrow.add_child(_option(MODE_INFO[m], mgroup, m == "safe", _pick_out.bind("mode", m)))
	left.add_child(mrow)
	left.add_child(UiStyle.g_caption("Voltas nesta saída"))
	var lrow := HBoxContainer.new()
	lrow.add_theme_constant_override("separation", 10)
	var lgroup := ButtonGroup.new()
	for n: int in [1, 2]:
		lrow.add_child(_option(LAPS_INFO[n], lgroup, n == 1, _pick_out.bind("laps", n)))
	left.add_child(lrow)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", UiStyle.SP_M)
	right.custom_minimum_size = Vector2(300, 0)
	cols.add_child(right)
	var sum := ScreenKit.g_card(UiStyle.G_SURFACE, 18, 16, 14)
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 6)
	sum.add_child(sv)
	sv.add_child(UiStyle.g_caption("Esta saída"))
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	var badge := TyreBadge.new()
	badge.custom_minimum_size = Vector2(40, 40)
	top.add_child(badge)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", -4)
	var tname := UiStyle.g_label("", 18, UiStyle.G_TEXT, "black")
	var tsub := UiStyle.g_label("", UiStyle.FS_CAPTION, UiStyle.G_TEXT_2, "bold")
	tv.add_child(tname)
	tv.add_child(tsub)
	top.add_child(tv)
	sv.add_child(top)
	var kv := {}
	for k: Array in [["pred", "Tempo previsto"], ["cut", "Corte (agora)"], ["left", "Tempo de sessão"]]:
		var r := HBoxContainer.new()
		var l := UiStyle.g_label(k[1], UiStyle.FS_SMALL, Color("#c3c9d3"), "bold")
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(l)
		var val := UiStyle.g_label("", UiStyle.FS_SMALL, UiStyle.G_TEXT, "black")
		r.add_child(val)
		sv.add_child(r)
		kv[k[0]] = val
	right.add_child(sum)
	var go := CutButton.new()
	go.text = "MANDAR PARA A PISTA"
	go.custom_minimum_size = Vector2(300, UiStyle.TOUCH_MAIN)
	go.add_theme_font_size_override("font_size", UiStyle.fs(17))
	go.pressed.connect(_confirm_out)
	right.add_child(go)
	_out_choice["ui"] = {"badge": badge, "name": tname, "sub": tsub, "kv": kv, "go": go}
	body.add_child(_alloc_row(car))
	add_child(_out_sheet)
	_update_out_summary()


func _set_tile(car: CarState, g: Dictionary, group: ButtonGroup) -> Button:
	var s: Dictionary = g["set"]
	var c: Dictionary = q.tyres.compounds[s["compound"]]
	var b := Button.new()
	b.toggle_mode = true
	b.button_group = group
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(250, 66)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.disabled = g["locked"]
	for st: String in ["normal", "hover", "disabled"]:
		b.add_theme_stylebox_override(st, UiStyle.g_box(UiStyle.G_SURFACE if st != "disabled" else UiStyle.G_OFF, 16, 0, 0))
	for st: String in ["pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, UiStyle.g_box(UiStyle.G_LIGHT, 16, 0, 0))
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 10)
	b.add_child(h)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 12
	h.offset_right = -12
	var badge := TyreBadge.new()
	badge.custom_minimum_size = Vector2(34, 34)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.set_compound(c["letter"], Color(c["color"]))
	h.add_child(badge)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var laps := int(s["laps"])
	var title := "%s %s" % [c["name"], "novo" if laps == 0 else "usado"]
	if int(g["count"]) > 1:
		title += " ×%d" % int(g["count"])
	var name_l := UiStyle.g_label(title, UiStyle.FS_SMALL + 1, UiStyle.G_TEXT, "black")
	var sub_text := "guardado para o Q3" if g["locked"] else ("0 voltas" if laps == 0 else "%d voltas" % laps)
	if s["q3"] and not g["locked"]:
		sub_text = "jogo do Q3"
	var sub_l := UiStyle.g_label(sub_text, UiStyle.FS_CAPTION, UiStyle.G_TEXT_2, "bold")
	v.add_child(name_l)
	v.add_child(sub_l)
	var life := ProgressBar.new()
	life.show_percentage = false
	life.max_value = 1.0
	life.custom_minimum_size = Vector2(90, 6)
	life.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	life.mouse_filter = Control.MOUSE_FILTER_IGNORE
	life.value = clampf(1.0 - q.tyres.wear_per_lap(s["compound"]) * q.track.tyre_wear_factor * laps, 0.0, 1.0)
	life.add_theme_stylebox_override("background", UiStyle.g_box(Color(1, 1, 1, 0.12), 3, 0, 0))
	life.add_theme_stylebox_override("fill", UiStyle.g_box(UiStyle.G_UP, 3, 0, 0))
	v.add_child(life)
	h.add_child(v)
	if g["locked"]:
		h.add_child(ScreenKit.icon("lock", 18, UiStyle.G_TEXT_3))
	var paint := func() -> void:
		name_l.add_theme_color_override("font_color", UiStyle.G_INK if b.button_pressed else UiStyle.G_TEXT)
		sub_l.add_theme_color_override("font_color", UiStyle.G_INK_2 if b.button_pressed else UiStyle.G_TEXT_2)
	b.toggled.connect(func(_on: bool) -> void: paint.call())
	b.button_pressed = int(s["id"]) == int(_out_choice["set"])
	paint.call()
	var sid := int(s["id"])
	b.pressed.connect(func() -> void:
		_out_choice["set"] = sid
		_update_out_summary())
	ScreenKit.press_feedback(b)
	return b


## Opção grande (ícone + título + explicação) num grupo exclusivo.
func _option(info: Array, group: ButtonGroup, on: bool, pick: Callable) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.button_group = group
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 96)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for st: String in ["normal", "hover"]:
		b.add_theme_stylebox_override(st, UiStyle.g_box(UiStyle.G_SURFACE, 16, 0, 0))
	for st: String in ["pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, UiStyle.g_box(UiStyle.G_LIGHT, 16, 0, 0))
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 2)
	b.add_child(v)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 14
	v.offset_right = -14
	v.offset_top = 10
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 8)
	var ic := ScreenKit.icon(info[0], 20, UiStyle.G_TEXT)
	h.add_child(ic)
	var t := UiStyle.g_label(info[1], UiStyle.FS_BODY + 1, UiStyle.G_TEXT, "black")
	h.add_child(t)
	v.add_child(h)
	var d := UiStyle.g_label(info[2], UiStyle.FS_CAPTION, UiStyle.G_TEXT_2, "bold")
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(d)
	var paint := func() -> void:
		var ink := b.button_pressed
		t.add_theme_color_override("font_color", UiStyle.G_INK if ink else UiStyle.G_TEXT)
		d.add_theme_color_override("font_color", UiStyle.G_INK_2 if ink else UiStyle.G_TEXT_2)
		ic.modulate = UiStyle.G_INK if ink else UiStyle.G_TEXT
	b.toggled.connect(func(_on: bool) -> void: paint.call())
	b.button_pressed = on
	paint.call()
	b.pressed.connect(pick)
	ScreenKit.press_feedback(b)
	return b


## Jogos do fim de semana: disponíveis de cada composto seco e quantos já foram devolvidos.
func _alloc_row(car: CarState) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	h.add_child(UiStyle.g_caption("Fim de semana"))
	var sm := q.alloc.summary(car.driver["id"])
	for k: String in ["soft", "medium", "hard"]:
		if not sm.has(k):
			continue
		var c: Dictionary = q.tyres.compounds[k]
		var it := HBoxContainer.new()
		it.add_theme_constant_override("separation", 6)
		var bd := TyreBadge.new()
		bd.custom_minimum_size = Vector2(22, 22)
		bd.set_compound(c["letter"], Color(c["color"]))
		it.add_child(bd)
		it.add_child(UiStyle.g_label("%d de %d" % [sm[k][0], sm[k][1]], UiStyle.FS_SMALL, Color("#c3c9d3"), "black"))
		h.add_child(it)
	var ret := q.alloc.returned_count(car.driver["id"])
	if ret > 0:
		h.add_child(UiStyle.g_label("%d jogos devolvidos" % ret, UiStyle.FS_SMALL, UiStyle.G_TEXT_3, "bold"))
	return h


func _pick_out(key: String, value: Variant) -> void:
	_out_choice[key] = value
	_update_out_summary()


func _update_out_summary() -> void:
	if not _out_choice.has("ui"):
		return
	var ui: Dictionary = _out_choice["ui"]
	var car: CarState = _out_choice["car"]
	var s := q.alloc.get_set(car.driver["id"], int(_out_choice["set"]))
	var go: Button = ui["go"]
	go.disabled = s.is_empty()
	if s.is_empty():
		(ui["name"] as Label).text = "Escolha um jogo"
		return
	var c: Dictionary = q.tyres.compounds[s["compound"]]
	(ui["badge"] as TyreBadge).set_compound(c["letter"], Color(c["color"]))
	(ui["name"] as Label).text = "%s %s" % [c["name"], "novo" if int(s["laps"]) == 0 else "usado"]
	(ui["sub"] as Label).text = "%s · %d volta%s" % [String(MODE_INFO[_out_choice["mode"]][1]).to_lower(), int(_out_choice["laps"]), "" if int(_out_choice["laps"]) == 1 else "s"]
	var pred := q.expected_lap_time(car, s["compound"], int(s["laps"]) == 0)
	pred += -QualiSim.LIMIT_TIME_S if _out_choice["mode"] == "limit" else QualiSim.SAFE_TIME_S
	(ui["kv"]["pred"] as Label).text = UiStyle.format_time(pred)
	(ui["kv"]["cut"] as Label).text = _cut_time_text()
	var left := q.time_left_s()
	(ui["kv"]["left"] as Label).text = "%d:%02d" % [int(left) / 60, int(left) % 60]


## Tempo do último que passa de fase agora (ou "—" se ainda não há tempos suficientes / Q3).
func _cut_time_text() -> String:
	var adv: int = q.segments[q.segment]["advance"]
	if adv <= 0:
		return "—"
	var order := q.segment_order()
	if order.size() < adv:
		return "—"
	var t: float = q.best[order[adv - 1]][q.segment]
	return UiStyle.format_time(t) if t < INF else "—"


func _confirm_out() -> void:
	var car: CarState = _out_choice["car"]
	var laps := int(_out_choice["laps"])
	if q.send_out_set(car, int(_out_choice["set"]), laps, String(_out_choice["mode"])):
		_toasts.push("%s saiu para %s." % [car.code(), "a volta rápida" if laps == 1 else "duas voltas rápidas"], "hot")
	if _out_sheet != null:
		_out_sheet.queue_free()
	_refresh_ui()


func _process(delta: float) -> void:
	if q == null:
		return
	if not q.is_over() and not q.waiting and _out_sheet == null:  # folha de saída aberta: a sessão espera a decisão
		q.advance(delta * time_scale)
	_refresh -= delta
	if _refresh <= 0.0:
		_refresh = UI_REFRESH_S
		_refresh_ui()


func _refresh_ui() -> void:
	var seg: Dictionary = q.segments[q.segment]
	var adv: int = seg["advance"]
	_sub.text = "%s · %s" % [weekend.circuit["grand_prix"], ("%d avançam" % adv) if adv > 0 else "disputa da pole"]
	if q.is_over():
		_clock.text = "FIM"
		_clock_caption.text = "CLASSIFICAÇÃO ENCERRADA"
	elif q.is_red_flag():
		_clock.text = "BANDEIRA VERMELHA"
		_clock_caption.text = "RELÓGIO PARADO"
	else:
		_clock.text = "%s %s" % [seg["name"], ScreenKit.clock(q.time_left_s())]
		_clock_caption.text = "TEMPO RESTANTE"
	var order := q.standings()
	var active := q.active_cars().size()
	var lead_best := q.best_in_segment(order[0])
	for i in order.size():
		var car := order[i]
		var out: bool = q.eliminated_in[car] >= 0
		var b := q.best_in_segment(car)
		_table.set_row_style(i, "me" if car.is_player else ("out" if out else "normal"))
		_table.set_pos(i, 0, str(i + 1), Color(1, 1, 1, 0.18) if out else car.team_color())
		_table.set_team(i, 1, car.team["id"], car.code())  # sigla de 3 letras, como na transmissão
		_table.set_text(i, 2, UiStyle.format_time(b))
		_table.set_text(i, 3, "—" if i == 0 or b == INF or out else "+%.3f" % (b - lead_best))
		var c: Dictionary = q.tyres.compounds[car.tyre] if q.run_tyre.has(car) else {}
		_table.set_tyre(i, 4, c.get("letter", ""), Color(c.get("color", "#00000000")), "")
	_table.set_cut_line(adv - 1 if adv > 0 and adv < active and not q.is_over() else -1)
	_cut_info.text = "" if adv <= 0 or q.is_over() else "Linha vermelha: zona de eliminação (%dº–%dº)" % [adv + 1, active]
	# a evolução da pista é implícita (pedido de 2026-11-10): sem aviso; só diz a condição quando a pista está molhada
	_evolution.text = "Pista %s." % q.weather.surface_label().to_lower() if q.weather.wetness > 0.1 else ""
	_evolution.visible = _evolution.text != ""
	for p: Dictionary in _panels:
		_refresh_panel(p, order)
	var ask := {}
	for p: Dictionary in _panels:
		var d := q.pending_for(p["car"])
		if not d.is_empty():
			ask = d
	_radio.show_message(ask)
	_end_card.visible = q.is_over()
	_info_card.visible = not q.is_over()


func _refresh_panel(p: Dictionary, order: Array[CarState]) -> void:
	var car: CarState = p["car"]
	(p["pos"] as Label).text = "P%d" % (order.find(car) + 1)
	var state := q.status_of(car)
	var garage := state == "Garagem"
	var running := state in ["Volta de saída", "Volta lançada", "Volta de entrada"]
	(p["status"] as Label).text = state
	var lap: Label = p["lap"]
	var bar: ProgressBar = p["bar"]
	bar.visible = running
	if garage:
		lap.text = "%d jogo(s) de macios novos" % q.new_softs_left(car)
		if car.last_lap_time > 0.0:
			lap.text += " · última: %s" % UiStyle.format_time(car.last_lap_time)
	elif running:
		bar.value = q.render_distance(car) / q.track.length_m * 100.0
		var c: Dictionary = q.tyres.compounds[car.tyre]
		var flying := state == "Volta lançada"
		lap.text = "%s · %d%% da volta" % [c["name"], roundi(bar.value)]
		if flying:  # o objetivo da volta é escolha do piloto: a tela só informa
			lap.text = "%s · %s · %d%%" % [c["name"], q.lap_mode_label(car), roundi(bar.value)]
		bar.add_theme_stylebox_override("fill", UiStyle.g_box(Color("#c77dff") if flying else Color("#8f98a7"), 4, 0, 0))
	else:
		lap.text = state
	(p["sectors"] as SectorStrip).set_state(q.sectors_of(car), state == "Volta lançada")
	var go: Button = p["go"]
	go.disabled = not q.can_go_out(car)
	if garage:
		go.text = "SAIR PARA A PISTA" if q.time_left_s() > 0.0 else "TEMPO ESGOTADO"
	elif running:
		go.text = "EM ANDAMENTO"
	else:
		go.text = state.to_upper()


## Volta comprometida de um dos seus pilotos: o rádio pergunta; com a opção ligada, a sessão desacelera.
func _on_decision(_d: Dictionary) -> void:
	if Session.slow_on_decisions and time_scale > SPEEDS[0]:
		time_scale = SPEEDS[0]
		for b: Button in (_speeds.get_child(0) as Control).get_children():
			b.set_pressed_no_signal(is_equal_approx(float(b.get_meta("value")), time_scale))
		_toasts.push("Rádio: decisão pendente — velocidade reduzida.")
	_refresh_ui()


func _on_lap(car: CarState, lap_time: float, valid: bool) -> void:
	if car.is_player and valid:
		_toasts.push("%s: %s (%s)" % [car.code(), UiStyle.format_time(lap_time), q.segment_name()], "hot")


func _on_segment_finished(index: int, eliminated: Array) -> void:
	var last := index >= q.segments.size() - 1
	if _skipping and not last:
		return  # "simular o resto" não para nas partes do meio
	if not last and eliminated.is_empty():
		return
	_show_result.call_deferred(index)


var _result: QualiResultSheet
var _skipping := false


## Resultado da parte que acabou (mockups v28): eliminados em destaque; no fim do Q3, a pole.
func _show_result(index: int) -> void:
	if _result != null and is_instance_valid(_result):
		return
	var last := index >= q.segments.size() - 1
	var order := q.segment_order()
	var out: Array[CarState] = []
	for car in q.cars:
		if q.eliminated_in[car] == index:
			out.append(car)
	out.sort_custom(func(a: CarState, b: CarState) -> bool:
		if q.best[a][index] != q.best[b][index]:
			return q.best[a][index] < q.best[b][index]
		return a.index < b.index)
	if not last and out.is_empty() and not q.waiting:
		return
	_result = QualiResultSheet.make(q, index, order, out, String(weekend.circuit["grand_prix"]), last)
	_result.confirmed.connect(func() -> void:
		if last:
			weekend.finish_quali(q)
			Session.go_to_weekend()
		else:
			q.resume()
			_refresh_ui())
	add_child(_result)


func _simulate_rest() -> void:
	q.auto_player = true  # a IA da equipe decide as saídas dos seus carros até o fim
	_skipping = true
	q.run_to_end()
	_refresh_ui()


func _build_end_card() -> PanelContainer:
	var card := PanelContainer.new()
	var st := UiStyle.g_box(UiStyle.G_LIGHT, 20, 24, 14)
	st.border_width_left = 7
	st.border_color = UiStyle.RED
	card.add_theme_stylebox_override("panel", st)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	card.add_child(h)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UiStyle.g_label("CLASSIFICAÇÃO ENCERRADA", 20, UiStyle.G_INK, "black"))
	v.add_child(UiStyle.g_label("A tabela mostra o grid de largada.", 14, UiStyle.G_INK_2))
	h.add_child(v)
	var go := CutButton.new()
	go.text = "CONTINUAR"
	go.custom_minimum_size = Vector2(190, UiStyle.TOUCH_MAIN)
	go.pressed.connect(func() -> void:
		weekend.finish_quali(q)
		Session.go_to_weekend())
	h.add_child(go)
	return card


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.go_to_weekend()
