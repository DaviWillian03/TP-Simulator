extends Control
## Fábrica (mockup v42-3, 2026-11-19): as quatro estruturas em cartões 2×2, cada uma com o nível, o efeito de AGORA e o
## do PRÓXIMO nível escritos em números (antes/depois), o custo e os dias da obra e o botão AMPLIAR. Uma obra por vez
## em cada estrutura. Efeitos: data/factory.json via CarDevelopment.effect_lines.

var campaign: Campaign
var dev: CarDevelopment
var _layer: Control
var _box_w := 250.0


func _ready() -> void:
	campaign = Session.campaign
	if campaign == null:
		Session.open_campaign.call_deferred()
		return
	dev = campaign.dev
	var page := ScreenKit.garage_page(self, campaign.player_team)
	(page["backdrop"] as GarageBackdrop).set_glow(UiStyle.SECTION["hq"], 0.16)
	_layer = page["layer"]
	var R := CampaignFrame.CONTENT
	var gap := 16.0
	var w := (R.size.x - gap) / 2.0
	var h := (R.size.y - gap) / 2.0
	_box_w = (w - 36.0 - 12.0) / 2.0
	var cards: Array[Control] = []
	for i in CarDevelopment.STRUCT_ORDER.size():
		var c := _card(CarDevelopment.STRUCT_ORDER[i])
		c.position = R.position + Vector2((i % 2) * (w + gap), (i / 2) * (h + gap))
		c.size = Vector2(w, h)
		c.custom_minimum_size = c.size
		_layer.add_child(c)
		cards.append(c)
	CampaignFrame.apply(_layer, "hq", true, "SEDE · FÁBRICA")
	ScreenKit.stagger_in(cards)


func _card(id: String) -> Control:
	var st := CarDevelopment.structure(id)
	var lv := dev.level_of(id)
	var max_lv := int(CarDevelopment.factory_data()["max_level"])
	var work := dev.work_of(id)
	var info := dev.upgrade_info(id, campaign.budget_musd)
	var color := Color(st["color"])
	var card := PanelContainer.new()
	card.clip_contents = true
	card.add_theme_stylebox_override("panel", ScreenKit.glass_box(18, 18, 14))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var ic := PanelContainer.new()
	ic.custom_minimum_size = Vector2(44, 44)
	ic.add_theme_stylebox_override("panel", UiStyle.g_box(Color(color, 0.2), 22, 10, 10))
	ic.add_child(ScreenKit.icon(String(st["icon"]), 24, color))
	head.add_child(ic)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", -3)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_child(UiStyle.g_caption(String(st["sub"])))
	names.add_child(UiStyle.g_label(String(st["name"]), 20, UiStyle.G_TEXT, "black"))
	head.add_child(names)
	var lvl := VBoxContainer.new()
	lvl.add_theme_constant_override("separation", 4)
	lvl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var lt := UiStyle.g_label("Nível %d/%d" % [lv, max_lv], 13, UiStyle.G_TEXT_2, "black")
	lt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lvl.add_child(lt)
	var pips := Pips.new()
	pips.level = lv
	pips.building = not work.is_empty()
	lvl.add_child(pips)
	head.add_child(lvl)
	v.add_child(head)
	var cmp := HBoxContainer.new()
	cmp.add_theme_constant_override("separation", 12)
	cmp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cmp.add_child(_effects_box("Agora · nível %d" % lv, CarDevelopment.effect_lines(id, lv), CarDevelopment.effect_lines(id, lv), false, _box_w))
	if lv < max_lv:
		cmp.add_child(_effects_box("Nível %d" % (lv + 1), CarDevelopment.effect_lines(id, lv + 1), CarDevelopment.effect_lines(id, lv), true, _box_w))
	v.add_child(cmp)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	if not work.is_empty():
		var wb := VBoxContainer.new()
		wb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wb.add_child(UiStyle.g_label("Em obras · nível %d · faltam %d dias" % [int(work["to"]), int(work["days_left"])], 14, UiStyle.G_DIRECTOR, "black"))
		var bar := _Bar.new()
		bar.value = 1.0 - float(work["days_left"]) / maxf(float(work["days_total"]), 1.0)
		bar.color = UiStyle.G_DIRECTOR
		wb.add_child(bar)
		foot.add_child(wb)
	else:
		var cost := VBoxContainer.new()
		cost.add_theme_constant_override("separation", -2)
		cost.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cost.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if info["reason"] == "max":
			cost.add_child(UiStyle.g_label("Estrutura no nível máximo", 14, UiStyle.G_TEXT_2, "bold"))
		else:
			cost.add_child(UiStyle.g_label("US$ %d mi · %d dias" % [int(info["cost"]), int(info["days"])], 16, UiStyle.G_TEXT, "black"))
			cost.add_child(UiStyle.g_label("manutenção +US$ %s mi por corrida" % ProjectNotes.num(float(st["upkeep_per_level"])), 12, UiStyle.G_TEXT_3, "bold"))
		foot.add_child(cost)
		var go := CutButton.new()
		go.custom_minimum_size = Vector2(170, 48)
		go.add_theme_font_size_override("font_size", UiStyle.fs(16))
		go.text = "AMPLIAR"
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
	return card


## Caixa de efeitos; na do próximo nível, a linha que muda fica verde.
func _effects_box(caption: String, lines: Array[String], before: Array[String], is_next: bool, width: float) -> Control:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st := UiStyle.g_box(UiStyle.G_GLASS_TILE, 14, 14, 10)
	if is_next:
		st.set_border_width_all(1)
		st.border_color = Color(UiStyle.G_UP, 0.5)
	p.add_theme_stylebox_override("panel", st)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	v.add_child(UiStyle.g_caption(caption, UiStyle.G_UP if is_next else UiStyle.G_TEXT_3))
	for i in lines.size():
		var changed := is_next and (i >= before.size() or before[i] != lines[i])
		var l := UiStyle.g_label(lines[i], 13, UiStyle.G_UP if changed else UiStyle.G_TEXT, "black" if changed else "bold")
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(width - 28, 0)  # largura fixa: sem ela o rótulo mede a altura com largura zero
		v.add_child(l)
	return p


func _on_upgrade(id: String) -> void:
	if dev.start_upgrade(campaign, id):
		campaign.save()
		Session.open_campaign_factory()  # recarrega a tela com o caixa e as obras novos


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.open_campaign_hq()


## Cinco marcas de nível (cheias até o nível atual; a próxima amarela se está em obras).
class Pips:
	extends Control

	var level := 1
	var building := false

	func _init() -> void:
		custom_minimum_size = Vector2(5 * 22 + 4 * 5, 10)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		for i in 5:
			var r := Rect2(i * 27.0, 0.0, 22.0, 10.0)
			var col := Color(1, 1, 1, 0.14)
			if i < level:
				col = UiStyle.G_UP
			elif i == level and building:
				col = UiStyle.G_DIRECTOR
			draw_style_box(UiStyle.g_box(col, 4, 0, 0), r)


class _Bar:
	extends Control
	var value := 0.5
	var color := Color.WHITE

	func _init() -> void:
		custom_minimum_size = Vector2(0, 10)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_style_box(UiStyle.g_box(Color(1, 1, 1, 0.1), 5, 0, 0), Rect2(Vector2.ZERO, size))
		draw_style_box(UiStyle.g_box(color, 5, 0, 0), Rect2(Vector2.ZERO, Vector2(size.x * clampf(value, 0.03, 1.0), size.y)))
