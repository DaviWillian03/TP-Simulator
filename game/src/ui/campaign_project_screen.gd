extends Control
## Novo projeto (mockup v42-2, 2026-11-19): escolhe a ÁREA (asa dianteira, asa traseira, assoalho, suspensão, motor) e o
## TAMANHO (pequeno, médio, grande). Mostra custo, prazo, ganho esperado em s/volta no tipo de pista em que a área
## ajuda, a faixa do resultado (60–120%, o piso sobe com a equipe técnica e a fábrica) e quem aperta essa faixa.
## Teclado/mouse: clique nos blocos; Esc volta para a tela Carro.

var campaign: Campaign
var _layer: Control
var _area := ""
var _size := "M"
var _area_row: HBoxContainer
var _left: VBoxContainer
var _right: VBoxContainer
var _go: CutButton
var _why: Label


func _ready() -> void:
	campaign = Session.campaign
	if campaign == null:
		Session.open_campaign.call_deferred()
		return
	var page := ScreenKit.garage_page(self, campaign.player_team)
	_layer = page["layer"]
	var R := CampaignFrame.CONTENT
	var cp := campaign.my_parts()
	for a: Dictionary in CarParts.areas():  # primeira área livre como escolha inicial
		if cp.project_info(campaign, a["id"], "M")["reason"] not in ["engine", "now"]:
			_area = a["id"]
			break
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	var back := ScreenKit.round_button("back", 48, "Voltar ao carro")
	back.pressed.connect(Session.open_campaign_car)
	head.add_child(back)
	head.add_child(UiStyle.g_label("Novo projeto", 28, UiStyle.G_TEXT, "black"))
	ScreenKit.place(head, _layer, Control.PRESET_TOP_LEFT, R.position)
	_area_row = HBoxContainer.new()
	_area_row.add_theme_constant_override("separation", 12)
	ScreenKit.place(_area_row, _layer, Control.PRESET_TOP_LEFT, R.position + Vector2(0, 62), Vector2(R.size.x, 118))
	var lp := PanelContainer.new()
	lp.add_theme_stylebox_override("panel", ScreenKit.glass_box(18, 18, 14))
	_left = VBoxContainer.new()
	_left.add_theme_constant_override("separation", 8)
	lp.add_child(_left)
	ScreenKit.place(lp, _layer, Control.PRESET_TOP_LEFT, R.position + Vector2(0, 196), Vector2(620, 330))
	var rp := PanelContainer.new()
	rp.add_theme_stylebox_override("panel", ScreenKit.glass_box(18, 18, 14))
	_right = VBoxContainer.new()
	_right.add_theme_constant_override("separation", 10)
	rp.add_child(_right)
	ScreenKit.place(rp, _layer, Control.PRESET_TOP_LEFT, R.position + Vector2(636, 196), Vector2(R.size.x - 636, 330))
	_go = CutButton.new()
	_go.custom_minimum_size = Vector2(380, 56)
	_go.add_theme_font_size_override("font_size", UiStyle.fs(18))
	_go.pressed.connect(_on_start)
	ScreenKit.place(_go, _layer, Control.PRESET_TOP_LEFT, Vector2(R.end.x - 380, R.end.y - 60))
	_why = UiStyle.g_label("", 13, UiStyle.G_DOWN, "bold")
	ScreenKit.place(_why, _layer, Control.PRESET_TOP_LEFT, Vector2(R.position.x, R.end.y - 44), Vector2(R.size.x - 400, 0))
	CampaignFrame.apply(_layer, "car", true, "CARRO · NOVO PROJETO")
	_refresh()


func _refresh() -> void:
	for c in _area_row.get_children():
		c.queue_free()
	for c in _left.get_children():
		c.queue_free()
	for c in _right.get_children():
		c.queue_free()
	var cp := campaign.my_parts()
	for a: Dictionary in CarParts.areas():
		_area_row.add_child(_area_tile(a, cp.project_info(campaign, a["id"], _size)))
	if _area == "":
		_left.add_child(UiStyle.g_label("Todas as áreas já têm projeto em andamento.", 15, UiStyle.G_TEXT_2, "bold"))
		_go.disabled = true
		_go.text = "SEM ÁREA LIVRE"
		return
	var info := cp.project_info(campaign, _area, _size)
	_build_left(info)
	_build_right(info)
	_go.disabled = not bool(info["ok"])
	_go.text = "INICIAR PROJETO · US$ %s MI" % ProjectNotes.num(float(info["cost"]), 1) if info["ok"] else "INDISPONÍVEL"
	_why.text = {"slots": "Todas as vagas da fábrica estão ocupadas.", "cash": "Caixa insuficiente (a reserva mínima é de US$ %d mi)." % int(CarDevelopment.RESERVE_MUSD),
		"cap": "O teto de gastos do ano não comporta este projeto.", "now": "Esta área já tem um projeto em andamento.",
		"engine": "Equipe cliente: o motor é do fornecedor."}.get(info["reason"], "")


func _area_tile(a: Dictionary, info: Dictionary) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_ALL
	b.custom_minimum_size = Vector2(0, 118)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var on: bool = a["id"] == _area
	var off: bool = info["reason"] in ["engine", "now"]
	for s: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var fill := UiStyle.G_LIGHT if on else (UiStyle.G_SURFACE_HOVER if s.begins_with("hover") else UiStyle.G_SURFACE)
		var st := UiStyle.g_box(fill, 16, 12, 10)
		if s == "focus":
			st = UiStyle.g_box(Color(0, 0, 0, 0), 16, 12, 10)
			st.set_border_width_all(2)
			st.border_color = Color(1, 1, 1, 0.5)
		b.add_theme_stylebox_override(s, st)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 12
	v.offset_top = 10
	v.offset_right = -10
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ink := UiStyle.G_INK if on else (UiStyle.G_TEXT_OFF if off else UiStyle.G_TEXT)
	var n := UiStyle.g_label(String(a["name"]), 15, ink, "black")
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(n)
	v.add_child(UiStyle.g_label(String(a["helps"]), 12, UiStyle.G_INK_2 if on else UiStyle.G_TEXT_3, "bold"))
	if off:
		v.add_child(UiStyle.g_label("em andamento" if info["reason"] == "now" else "motor do fornecedor", 11, UiStyle.G_WARN, "bold"))
	b.add_child(v)
	b.disabled = off
	b.pressed.connect(func() -> void:
		_area = String(a["id"])
		_refresh())
	ScreenKit.press_feedback(b)
	return b


func _build_left(info: Dictionary) -> void:
	var cp := campaign.my_parts()
	_left.add_child(UiStyle.g_caption("Tamanho do projeto"))
	var seg := HBoxContainer.new()
	seg.add_theme_constant_override("separation", 6)
	for s: Dictionary in CarParts.sizes():
		var si := cp.project_info(campaign, _area, String(s["id"]))
		var b := Button.new()
		b.focus_mode = Control.FOCUS_ALL
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 62)
		var on: bool = s["id"] == _size
		for st_name: String in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
			var st := UiStyle.g_box(UiStyle.G_LIGHT if on else (UiStyle.G_SURFACE_HOVER if st_name.begins_with("hover") else UiStyle.G_SURFACE), 12, 8, 6)
			if st_name == "focus":
				st = UiStyle.g_box(Color(0, 0, 0, 0), 12, 8, 6)
				st.set_border_width_all(2)
				st.border_color = Color(1, 1, 1, 0.5)
			b.add_theme_stylebox_override(st_name, st)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", -2)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var t := UiStyle.g_label(String(s["name"]), 15, UiStyle.G_INK if on else UiStyle.G_TEXT, "black")
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(t)
		var c := UiStyle.g_label("US$ %s mi · %d dias" % [ProjectNotes.num(float(si["cost"]), 1), int(si["days"])], 12, UiStyle.G_INK_2 if on else UiStyle.G_TEXT_3, "bold")
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(c)
		b.add_child(v)
		b.pressed.connect(func() -> void:
			_size = String(s["id"])
			_refresh())
		ScreenKit.press_feedback(b)
		seg.add_child(b)
	_left.add_child(seg)
	var a := CarParts.area(_area)
	_left.add_child(UiStyle.g_caption("Ganho esperado (%s %s)" % [String(a["name"]), String(CarParts.size_of(_size)["name"])]))
	var keep := 1.0 - float(info["share"])
	_left.add_child(UiStyle.g_label(ProjectNotes.band_text(_area, info["fx"], float(info["lo"]), float(info["hi"]), keep), 24, UiStyle.G_TEXT, "black"))
	var where := ""
	if _area == "rel":
		where = "Menos quebras de motor e câmbio nos dois carros, em todas as pistas."
	else:
		var avg := CarParts.fx_seconds(info["fx"]) * keep
		where = "Em pistas de %s (%s…) · média do calendário %s" % [String(a["helps"]), ", ".join(ProjectNotes.best_tracks(_area)), ProjectNotes.sec(avg)]
	var wl := UiStyle.g_label(where, 13, UiStyle.G_TEXT_2, "bold")
	wl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_left.add_child(wl)
	_left.add_child(UiStyle.g_caption("Faixa do resultado"))
	var band := _Band.new()
	band.lo = float(info["lo"])
	band.hi = float(info["hi"])
	_left.add_child(band)
	if float(info["share"]) > 0.0:
		var nl := UiStyle.g_label("%d%% do ganho vai para o carro %d (esforço da equipe, tela Carro)." % [roundi(float(info["share"]) * 100.0), campaign.season + 1], 12, UiStyle.G_TEXT_3, "bold")
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_left.add_child(nl)


func _row(text: String, value: String, color := UiStyle.G_TEXT) -> HBoxContainer:
	var h := HBoxContainer.new()
	var l := UiStyle.g_label(text, 14, UiStyle.G_TEXT, "black")
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.add_child(l)
	h.add_child(UiStyle.g_label(value, 14, color, "black"))
	return h


func _build_right(info: Dictionary) -> void:
	var dept := String(CarParts.part(String(CarParts.area(_area)["part"]))["dept"])
	var dev := campaign.dev
	var sid := CarDevelopment.struct_for(dept)
	_right.add_child(UiStyle.g_caption("Quem aperta a faixa"))
	_right.add_child(_row("Equipe técnica (%s)" % {"aero": "aerodinâmica", "chassis": "chassi", "engine": "motor", "durability": "confiabilidade"}.get(dept, dept),
		"+%d%%" % roundi(dev.staff_narrow(dept) * 100.0), UiStyle.G_UP))
	_right.add_child(_row("%s · nível %d" % [String(CarDevelopment.structure(sid)["name"]), dev.level_of(sid)],
		"+%d%%" % roundi(CarDevelopment.narrow_at(dept, dev.level_of(sid)) * 100.0), UiStyle.G_UP))
	if dept == "aero" and absf(dev.atr - 1.0) > 0.001:
		var atr := roundi((dev.atr - 1.0) * 20.0)
		_right.add_child(_row("Restrição de túnel (posição do ano passado)", ("+%d%%" if atr >= 0 else "−%d%%") % absi(atr), UiStyle.G_UP if atr >= 0 else UiStyle.G_DOWN))
	_right.add_child(_row("Vagas livres", "%d de %d" % [maxi(0, dev.slots() - dev.busy()), dev.slots()]))
	_right.add_child(_row("Teto de gastos restante", "US$ %d mi" % int(campaign.cap_left_rd())))
	_right.add_child(_row("Caixa", "US$ %d mi" % int(campaign.budget_musd)))
	_right.add_child(_row("Vai para", "Carro %d" % campaign.season if float(info["share"]) <= 0.0 else "%d%% %d · %d%% %d" % [100 - roundi(float(info["share"]) * 100.0), campaign.season, roundi(float(info["share"]) * 100.0), campaign.season + 1]))


func _on_start() -> void:
	if campaign.my_parts().start_project(campaign, _area, _size):
		campaign.save()
		Session.open_campaign_car()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.open_campaign_car()


## Faixa do resultado: escala de 50% a 130%, faixa piso..teto e o risco do esperado (100%).
class _Band:
	extends Control
	var lo := 0.6
	var hi := 1.2
	const A := 0.5
	const B := 1.3

	func _init() -> void:
		custom_minimum_size = Vector2(0, 42)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _x(v: float) -> float:
		return size.x * clampf((v - A) / (B - A), 0.0, 1.0)

	func _draw() -> void:
		draw_style_box(UiStyle.g_box(Color(1, 1, 1, 0.1), 8, 0, 0), Rect2(0, 2, size.x, 16))
		var grad := Gradient.new()
		grad.colors = PackedColorArray([UiStyle.G_WARN, UiStyle.G_UP])
		var r := Rect2(_x(lo), 2, _x(hi) - _x(lo), 16)
		var steps := 24
		for i in steps:
			var c := grad.sample(float(i) / (steps - 1))
			draw_rect(Rect2(r.position.x + r.size.x * i / steps, r.position.y, r.size.x / steps + 1, r.size.y), c)
		draw_rect(Rect2(_x(1.0) - 1.5, 0, 3, 20), Color.WHITE)
		var font := UiStyle.G_BOLD
		var fs := UiStyle.fs(12)
		draw_string(font, Vector2(_x(lo) - 20, 38), "%d%%" % roundi(lo * 100.0), HORIZONTAL_ALIGNMENT_CENTER, 40, fs, UiStyle.G_TEXT_2)
		draw_string(font, Vector2(_x(1.0) - 40, 38), "ESPERADO", HORIZONTAL_ALIGNMENT_CENTER, 80, fs, UiStyle.G_TEXT)
		draw_string(font, Vector2(_x(hi) - 20, 38), "%d%%" % roundi(hi * 100.0), HORIZONTAL_ALIGNMENT_CENTER, 40, fs, UiStyle.G_TEXT_2)
