extends Control
## Sede 3D (mockup v26-5): o campus em isometria com um prédio por instalação e o nível em cima. Tocar num prédio abre o
## painel à direita: nível atual em anel, o que muda no próximo nível, os 5 níveis e a obra (custo, dias, CONSTRUIR).
## As instalações são as estruturas da fábrica (data/factory.json): túnel de vento, simulador, fábrica de peças e
## marketing. O centro técnico leva à árvore de P&D e o centro de pilotos ao Pessoal.

const STRUCT := {"wind": "wind", "sim": "sim", "factory": "parts", "hosp": "media"}  ## prédio -> estrutura
const SHORTCUT := {"design": ["Centro técnico", "Projetos de P&D do carro", "pen", "ÁRVORE DE P&D"],
	"drivers": ["Centro de pilotos", "Pilotos e corpo técnico", "users", "PESSOAL"]}
const ICONS := {"wind": "wind", "sim": "sim", "factory": "factory", "hosp": "hand", "design": "pen", "drivers": "users"}

var campaign: Campaign
var dev: CarDevelopment
var _campus: HqCampus
var _panel: VBoxContainer
var _sel := "wind"


func _ready() -> void:
	campaign = Session.campaign
	if campaign == null:
		Session.open_campaign.call_deferred()
		return
	dev = campaign.dev
	for a: String in OS.get_cmdline_user_args():  # (capturas) --hq=<prédio>
		if a.begins_with("--hq="):
			_sel = a.trim_prefix("--hq=")
	var page := ScreenKit.garage_page(self, campaign.player_team)
	(page["backdrop"] as GarageBackdrop).set_glow(UiStyle.SECTION["hq"])
	var layer: Control = page["layer"]
	var R := CampaignFrame.CONTENT
	_campus = HqCampus.new()
	_campus.colors = HqCampus.default_colors()
	_campus.icons = ICONS
	_campus.position = Vector2(R.position.x, R.position.y)
	_campus.clip_contents = true
	_campus.size = Vector2(R.size.x - 416, R.size.y - 44)
	_campus.picked.connect(_on_pick)
	layer.add_child(_campus)
	_campus.mouse_filter = Control.MOUSE_FILTER_STOP
	_campus.fit(_campus.size)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiStyle.g_box(Color(0.07, 0.08, 0.105, 0.94), 22, 20, 18))
	card.position = Vector2(R.end.x - 400, R.position.y)
	card.size = Vector2(400, R.size.y)
	layer.add_child(card)
	_panel = VBoxContainer.new()
	_panel.add_theme_constant_override("separation", 14)
	card.add_child(_panel)
	var total := 0
	for b: String in STRUCT:
		total += dev.level_of(STRUCT[b])
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 8)
	foot.add_child(_chip("%d / %d níveis" % [total, STRUCT.size() * _max()], "hq", UiStyle.SECTION["hq"]))
	foot.add_child(_chip("%d obra%s" % [_works(), "" if _works() == 1 else "s"], "timer", UiStyle.G_TEXT))
	ScreenKit.place(foot, layer, Control.PRESET_BOTTOM_LEFT, Vector2(R.position.x + 10, -18))
	_refresh()
	CampaignFrame.apply(layer, "hq", true)


func _max() -> int:
	return int(CarDevelopment.factory_data()["max_level"])


func _works() -> int:
	var n := 0
	for b: String in STRUCT:
		if not dev.work_of(STRUCT[b]).is_empty():
			n += 1
	return n


func _on_pick(id: String) -> void:
	_sel = id
	_refresh()


func _refresh() -> void:
	var lv := {}
	for b: String in STRUCT:
		lv[b] = [dev.level_of(STRUCT[b]), _max()]
	_campus.levels = lv
	_campus.selected = _sel
	_campus.refresh()
	for c in _panel.get_children():
		c.queue_free()
	var col: Color = HqCampus.default_colors()[_sel]
	if SHORTCUT.has(_sel):
		var s: Array = SHORTCUT[_sel]
		_panel.add_child(_head(s[2], col, "INSTALAÇÃO", s[0]))
		var d := UiStyle.g_label(s[1], 16, UiStyle.G_TEXT_2, "bold")
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_panel.add_child(d)
		_panel.add_child(_spacer())
		var go := CutButton.new()
		go.text = s[3]
		go.custom_minimum_size = Vector2(0, 60)
		go.add_theme_font_size_override("font_size", UiStyle.fs(19))
		go.pressed.connect(Session.open_campaign_rd if _sel == "design" else Session.open_campaign_staff)
		_panel.add_child(go)
		return
	var sid: String = STRUCT[_sel]
	var st := CarDevelopment.structure(sid)
	var level := dev.level_of(sid)
	var work := dev.work_of(sid)
	var info := dev.upgrade_info(sid, campaign.budget_musd)
	_panel.add_child(_head(ICONS[_sel], col, String(st["sub"]).to_upper(), String(st["name"])))
	var mid := HBoxContainer.new()
	mid.add_theme_constant_override("separation", 16)
	mid.add_child(RingGauge.make(float(level) / _max(), 96, col, str(level), "de %d" % _max(), "", 9.0))
	var eff := VBoxContainer.new()
	eff.add_theme_constant_override("separation", 6)
	eff.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eff.add_child(_rich(CarDevelopment.effect_text(sid, level), 14))
	mid.add_child(eff)
	_panel.add_child(mid)
	_panel.add_child(UiStyle.g_caption("Níveis"))
	var nodes := HBoxContainer.new()
	nodes.add_theme_constant_override("separation", 10)
	for i in _max():
		var done := i < level
		var next := i == level
		var building := next and not work.is_empty()
		var sq := PanelContainer.new()
		sq.custom_minimum_size = Vector2(48, 48)
		var fill := col if done else (Color("#ffd24a") if building else (UiStyle.G_LIGHT if next else Color(1, 1, 1, 0.06)))
		var box := UiStyle.g_box(fill, 12, 0, 0)
		if next and not building:
			box.border_color = col
			box.set_border_width_all(3)
		sq.add_theme_stylebox_override("panel", box)
		var ic := ScreenKit.icon("check" if done else ("timer" if building else ("up" if next else "lock")), 22, UiStyle.G_INK if (done or next) else UiStyle.G_TEXT_OFF)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sq.add_child(ic)
		nodes.add_child(sq)
	_panel.add_child(nodes)
	if level < _max():
		var nx := PanelContainer.new()
		nx.add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.06), 16, 14, 12))
		var nv := VBoxContainer.new()
		nv.add_theme_constant_override("separation", 8)
		var nh := HBoxContainer.new()
		nh.add_theme_constant_override("separation", 8)
		nh.add_child(ScreenKit.icon("up", 20, col))
		nh.add_child(UiStyle.g_label("NÍVEL %d" % (level + 1), 17, UiStyle.G_TEXT, "black"))
		nv.add_child(nh)
		nv.add_child(_rich(CarDevelopment.effect_text(sid, level + 1), 14))
		if work.is_empty() and info["reason"] != "max":
			var ch := HBoxContainer.new()
			ch.add_theme_constant_override("separation", 8)
			ch.add_child(_chip("%d mi" % int(info["cost"]), "money", UiStyle.SECTION["money"]))
			ch.add_child(_chip("%d dias" % int(info["days"]), "cal", UiStyle.G_TEXT))
			nv.add_child(ch)
		nx.add_child(nv)
		_panel.add_child(nx)
	_panel.add_child(_spacer())
	if not work.is_empty():
		var wl := UiStyle.g_label("EM OBRAS · %d DIAS" % int(work["days_left"]), 15, Color("#ffd24a"), "black")
		_panel.add_child(wl)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.value = 100.0 * (1.0 - float(work["days_left"]) / maxf(float(work["days_total"]), 1.0))
		bar.custom_minimum_size = Vector2(0, 12)
		bar.add_theme_stylebox_override("background", UiStyle.g_box(Color(1, 1, 1, 0.1), 6, 0, 0))
		bar.add_theme_stylebox_override("fill", UiStyle.g_box(Color("#ffd24a"), 6, 0, 0))
		_panel.add_child(bar)
		return
	var go := CutButton.new()
	go.custom_minimum_size = Vector2(0, 60)
	go.add_theme_font_size_override("font_size", UiStyle.fs(19))
	go.text = "CONSTRUIR"
	if info["reason"] == "max":
		go.text = "NÍVEL MÁXIMO"
		go.disabled = true
	elif info["reason"] == "cash":
		go.text = "SEM CAIXA"
		go.disabled = true
	else:
		go.pressed.connect(_on_build.bind(sid))
	_panel.add_child(go)


func _on_build(sid: String) -> void:
	if dev.start_upgrade(campaign, sid):
		campaign.save()
		Session.open_campaign_hq()


func _head(icon_name: String, col: Color, cap: String, title: String) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var sq := PanelContainer.new()
	sq.add_theme_stylebox_override("panel", UiStyle.g_box(col, 16, 12, 12))
	sq.add_child(ScreenKit.icon(icon_name, 30, UiStyle.G_INK))
	h.add_child(sq)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UiStyle.g_caption(cap))
	var t := UiStyle.g_label(title.to_upper(), 22, UiStyle.G_TEXT, "black")
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	h.add_child(v)
	return h


func _chip(text: String, icon_name: String, col: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(Color(0.06, 0.07, 0.09, 0.85), 15, 12, 5))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.add_child(ScreenKit.icon(icon_name, 16, col))
	h.add_child(UiStyle.g_label(text, 14, UiStyle.G_TEXT, "black"))
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
	r.add_theme_color_override("default_color", UiStyle.G_TEXT_2)
	r.text = bbcode
	return r


func _spacer() -> Control:
	var c := Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.open_campaign_hub()
