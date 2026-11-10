extends Control
## Fábrica — investimento em estrutura da campanha (mockup v9-3). Quatro estruturas com níveis 1 a 5
## (túnel de vento e CFD · simulador e centro de dados · fábrica de peças e qualidade · marketing e
## patrocínios). Cada melhoria custa dinheiro e dias de obra; uma obra por vez em cada estrutura.
## Estruturas melhores aceleram a árvore de P&D e aumentam a chance de cada upgrade dar certo.

var _grid: GridContainer
var campaign: Campaign
var dev: CarDevelopment
var _layer: Control
var _toasts: ToastFeed


func _ready() -> void:
	campaign = Session.campaign
	if campaign == null:
		Session.open_campaign.call_deferred()
		return
	dev = campaign.dev
	var team := campaign.team()
	var page := ScreenKit.garage_page(self, campaign.player_team)
	(page["backdrop"] as GarageBackdrop).set_glow(Color(team["color"]), 0.16)
	_layer = page["layer"]

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UiStyle.SP_L)
	var back := ScreenKit.round_button("back", 52, "Voltar à sede")
	back.pressed.connect(Session.open_campaign_hub)
	head.add_child(back)
	head.add_child(TeamEmblems.make_rect(campaign.player_team, 46))
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -2)
	titles.add_child(UiStyle.g_caption("%s · nível geral %s" % [team["name"], ("%.1f" % dev.overall_level_exact()).replace(".", ",")]))
	titles.add_child(UiStyle.g_label("FÁBRICA · ESTRUTURA", 26, UiStyle.G_TEXT, "black"))
	head.add_child(titles)
	ScreenKit.place(head, _layer, Control.PRESET_TOP_LEFT, Vector2(44, 20))

	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", UiStyle.SP_M)
	chips.add_child(_chip("Caixa", "US$ %d mi" % int(campaign.budget_musd)))
	chips.add_child(_chip("Custo por corrida", "US$ %.1f mi" % campaign.cost_per_race()))
	ScreenKit.place(chips, _layer, Control.PRESET_TOP_RIGHT, Vector2(-44, 26))
	ScreenKit.campaign_nav(_layer, "factory")
	# grade 2×2 numa coluna que rola (com a letra maior, não cabe tudo na tela)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UiStyle.SP_M)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 20)
	_grid.add_theme_constant_override("v_separation", 14)
	col.add_child(_grid)
	ScreenKit.scroll_column(col, _layer, Vector2(44, 150), Vector2(1280 - 88, 720 - 150 - 8))
	for id: String in CarDevelopment.STRUCT_ORDER:
		_build_card(id)
	_toasts = ToastFeed.new()
	_toasts.custom_minimum_size = Vector2(400, 0)
	ScreenKit.place(_toasts, _layer, Control.PRESET_TOP_LEFT, Vector2(680, 100), Vector2(400, 0))


func _chip(caption: String, value: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_SURFACE_HOVER, 26, 18, 7))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var cap := UiStyle.g_caption(caption)
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(cap)
	h.add_child(UiStyle.g_label(value, 17, UiStyle.G_TEXT, "black"))
	p.add_child(h)
	return p


func _rich(bbcode: String, size: int) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_theme_font_override("normal_font", UiStyle.G_SEMI)
	r.add_theme_font_override("bold_font", UiStyle.G_BLACK)
	r.add_theme_font_size_override("normal_font_size", UiStyle.fs(size))
	r.add_theme_font_size_override("bold_font_size", UiStyle.fs(size))
	r.add_theme_color_override("default_color", UiStyle.G_TEXT)
	r.text = bbcode
	return r


func _build_card(id: String) -> void:
	var st := CarDevelopment.structure(id)
	var lv := dev.level_of(id)
	var work := dev.work_of(id)
	var info := dev.upgrade_info(id, campaign.budget_musd)
	var color := Color(st["color"])
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.06), 22, 22, 16))
	card.custom_minimum_size = Vector2(586, 252)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	card.add_child(v)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	var ic := PanelContainer.new()
	ic.custom_minimum_size = Vector2(52, 52)
	ic.add_theme_stylebox_override("panel", UiStyle.g_box(Color(color, 0.2), 26, 12, 12))
	ic.add_child(ScreenKit.icon(String(st["icon"]), 28, color))
	head.add_child(ic)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", -2)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_child(UiStyle.g_caption(String(st["sub"])))
	names.add_child(UiStyle.g_label(String(st["name"]), 21, UiStyle.G_TEXT, "black"))
	head.add_child(names)
	var pips := Pips.new()
	pips.level = lv
	pips.building = not work.is_empty()
	pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(pips)
	v.add_child(head)

	var cmp := HBoxContainer.new()
	cmp.add_theme_constant_override("separation", 12)
	cmp.add_child(_compare_box("Agora · nível %d" % lv, CarDevelopment.effect_text(id, lv), Color(1, 1, 1, 0.07)))
	if lv < int(CarDevelopment.factory_data()["max_level"]):
		cmp.add_child(_compare_box("Nível %d" % (lv + 1), CarDevelopment.effect_text(id, lv + 1), Color(0.235, 0.616, 0.365, 0.18)))
	v.add_child(cmp)
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(fill)

	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 14)
	if not work.is_empty():
		var wb := VBoxContainer.new()
		wb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wb.add_child(UiStyle.g_label("EM OBRAS · NÍVEL %d · %d DIAS" % [int(work["to"]), int(work["days_left"])], 14, Color("#ffd24a"), "black"))
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.value = 100.0 * (1.0 - float(work["days_left"]) / maxf(float(work["days_total"]), 1.0))
		bar.custom_minimum_size = Vector2(0, 12)
		bar.add_theme_stylebox_override("background", UiStyle.g_box(Color(1, 1, 1, 0.1), 6, 0, 0))
		bar.add_theme_stylebox_override("fill", UiStyle.g_box(Color("#ffd24a"), 6, 0, 0))
		wb.add_child(bar)
		foot.add_child(wb)
	else:
		var cost := VBoxContainer.new()
		cost.add_theme_constant_override("separation", -2)
		cost.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if info["reason"] == "max":
			cost.add_child(UiStyle.g_label("Estrutura no nível máximo", 15, UiStyle.G_TEXT_2, "bold"))
		else:
			cost.add_child(_rich("[b]US$ %d mi[/b] · %d dias" % [int(info["cost"]), int(info["days"])], 16))
			cost.add_child(UiStyle.g_label("manutenção +US$ %s mi por corrida" % ("%.2f" % float(st["upkeep_per_level"])).replace(".", ","), 12, UiStyle.G_TEXT_2))
		foot.add_child(cost)
		var go := CutButton.new()
		go.custom_minimum_size = Vector2(190, 48)
		go.add_theme_font_size_override("font_size", UiStyle.fs(16))
		go.text = "MELHORAR"
		if info["reason"] == "max":
			go.text = "NÍVEL MÁXIMO"
			go.disabled = true
		elif info["reason"] == "cash":
			go.text = "SEM CAIXA"
			go.disabled = true
		else:
			go.pressed.connect(_on_upgrade.bind(id))
		foot.add_child(go)
	v.add_child(foot)


func _compare_box(caption: String, bbcode: String, fill: Color) -> Control:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", UiStyle.g_box(fill, 14, 14, 10))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	p.add_child(v)
	v.add_child(UiStyle.g_caption(caption))
	v.add_child(_rich(bbcode, 14))
	return p


func _on_upgrade(id: String) -> void:
	if dev.start_upgrade(campaign, id):
		campaign.save()
		Session.open_campaign_factory()  # recarrega a tela com o caixa e as obras novos


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.open_campaign_hub()


## Cinco marcas de nível (cheias até o nível atual; a próxima listrada se está em obras).
class Pips:
	extends Control

	var level := 1
	var building := false

	func _init() -> void:
		custom_minimum_size = Vector2(5 * 26 + 4 * 5, 10)

	func _draw() -> void:
		for i in 5:
			var r := Rect2(i * 31.0, 0.0, 26.0, 10.0)
			var col := Color(1, 1, 1, 0.14)
			if i < level:
				col = Color("#f3f4f6")
			elif i == level and building:
				col = Color("#ffd24a")
			var st := StyleBoxFlat.new()
			st.bg_color = col
			st.set_corner_radius_all(5)
			draw_style_box(st, r)
