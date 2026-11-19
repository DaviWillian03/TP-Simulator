extends Control
## Carro (mockup v42-1, 2026-11-19): notas do carro por área com o melhor rival, projetos em andamento, divisão do
## esforço entre o carro atual e o do ano seguinte, evolução na temporada (você × rivais) e as últimas entregas com o
## ganho esperado × real. "+ NOVO PROJETO" abre a escolha de área e tamanho (campaign_project_screen).

const AREA_ROWS := [["straight", "Reta"], ["slow", "Curvas lentas"], ["fast", "Curvas rápidas"], ["rel", "Confiabilidade"]]

var campaign: Campaign
var _layer: Control
var _accent: Color
var _effort_val: Label
var _effort_next: Label
var _effort_note: Label


func _ready() -> void:
	campaign = Session.campaign
	if campaign == null:
		Session.open_campaign.call_deferred()
		return
	var page := ScreenKit.garage_page(self, campaign.player_team)
	_layer = page["layer"]
	_accent = UiStyle.team_accent(campaign.team())
	var R := CampaignFrame.CONTENT
	var top_h := 300.0
	var gap := 16.0
	var w1 := 380.0
	var w2 := 420.0
	var w3 := R.size.x - w1 - w2 - gap * 2
	_panel(Rect2(R.position, Vector2(w1, top_h)), _ratings())
	_panel(Rect2(R.position + Vector2(w1 + gap, 0), Vector2(w2, top_h)), _projects())
	_panel(Rect2(R.position + Vector2(w1 + w2 + gap * 2, 0), Vector2(w3, top_h)), _effort())
	var y2 := R.position.y + top_h + gap
	var h2 := R.size.y - top_h - gap
	_panel(Rect2(Vector2(R.position.x, y2), Vector2(600, h2)), _graph())
	_panel(Rect2(Vector2(R.position.x + 600 + gap, y2), Vector2(R.size.x - 600 - gap, h2)), _deliveries(R.size.x - 600 - gap - 32))
	CampaignFrame.apply(_layer, "car", true)
	ProjectNotes.show_pending.call_deferred(self, campaign, func() -> void: Session.open_campaign_car.call_deferred())


func _panel(r: Rect2, content: Control) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", ScreenKit.glass_box(18, 16, 14))
	p.position = r.position
	p.size = r.size
	p.custom_minimum_size = r.size
	p.clip_contents = true
	p.add_child(content)
	_layer.add_child(p)


func _caption(text: String) -> Label:
	return UiStyle.g_caption(text)


# --- notas por área ------------------------------------------------------------------------------

func _ratings() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	var head := HBoxContainer.new()
	head.add_child(_caption("Notas do carro"))
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(fill)
	var tick := ColorRect.new()
	tick.color = Color.WHITE
	tick.custom_minimum_size = Vector2(3, 14)
	tick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(tick)
	head.add_child(UiStyle.g_label("  melhor rival", 12, UiStyle.G_TEXT_3, "bold"))
	v.add_child(head)
	var mine := campaign.area_ratings(campaign.player_team)
	var best := campaign.best_rival_areas()
	for row: Array in AREA_ROWS:
		var k: String = row[0]
		var val := float(mine.get(k, 0.0))
		var h := HBoxContainer.new()
		var name := UiStyle.g_label(String(row[1]), 15, UiStyle.G_TEXT, "black")
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(name)
		var up := val - float(campaign.area_last.get(k, val))
		if absf(up) >= 0.25:  # desgaste de uma corrida (~0,1) não conta como mudança
			h.add_child(UiStyle.g_label(("+" if up > 0 else "−") + ProjectNotes.num(absf(up), 1) + "  ", 13, UiStyle.G_UP if up > 0 else UiStyle.G_DOWN, "black"))
		h.add_child(UiStyle.g_label(str(roundi(val)), 17, UiStyle.G_TEXT, "black"))
		v.add_child(h)
		var bar := _RatingBar.new()
		bar.value = val
		bar.best = float(best.get(k, 0.0))
		bar.color = _accent
		v.add_child(bar)
	return v


# --- projetos ----------------------------------------------------------------------------------------

func _projects() -> Control:
	var cp := campaign.my_parts()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.add_child(_caption("Projetos em andamento · %d de %d vagas" % [campaign.dev.busy(), campaign.dev.slots()]))
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	for r: Dictionary in cp.research:
		list.add_child(_project_row(r))
	if cp.research.is_empty():
		var none := UiStyle.g_label("Nenhum projeto. Escolha uma área e um tamanho: a peça nova entra nos dois carros quando ficar pronta.", 13, UiStyle.G_TEXT_2)
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(none)
	var scroll := DragScroll.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	v.add_child(scroll)
	var go := ScreenKit.glass_pill_button("+ Novo projeto")
	go.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MIN)
	go.disabled = campaign.dev.busy() >= campaign.dev.slots()
	if go.disabled:
		go.text = "Todas as vagas ocupadas"
	go.pressed.connect(Session.open_campaign_project)
	v.add_child(go)
	return v


func _project_row(r: Dictionary) -> Control:
	var area_id := String(r.get("area", CarParts.area_of_part(String(r["part"]))))
	var cp := campaign.my_parts()
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_GLASS_TILE, 14, 12, 8))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	box.add_child(v)
	var h := HBoxContainer.new()
	var t := UiStyle.g_label(ProjectNotes.project_name(r), 14, UiStyle.G_TEXT, "black")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	h.add_child(UiStyle.g_label("%d dia%s" % [int(r["days_left"]), "" if int(r["days_left"]) == 1 else "s"], 13, UiStyle.G_TEXT_2, "black"))
	v.add_child(h)
	var bar := _Bar.new()
	bar.value = 1.0 - float(r["days_left"]) / maxf(float(r["days_total"]), 1.0)
	bar.color = UiStyle.G_UP
	v.add_child(bar)
	var b := cp.band(campaign, area_id)
	var fx: Dictionary = r.get("fx", cp.project_fx(campaign, area_id, String(r.get("size", "M"))))
	var keep := 1.0 - cp.share_for(area_id)
	var d := UiStyle.g_label("Ganho esperado: %s · %s" % [ProjectNotes.band_text(area_id, fx, float(b[0]), float(b[1]), keep), String(CarParts.area(area_id).get("helps", ""))], 12, UiStyle.G_TEXT_3, "bold")
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(d)
	return box


# --- esforço: carro atual × ano seguinte -----------------------------------------------------------------

func _effort() -> Control:
	var cp := campaign.my_parts()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.add_child(_caption("Esforço da equipe"))
	var h := HBoxContainer.new()
	var a := UiStyle.g_label("Carro %d" % campaign.season, 15, UiStyle.G_TEXT, "black")
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(a)
	h.add_child(UiStyle.g_label("Carro %d" % (campaign.season + 1), 15, UiStyle.G_TEXT, "black"))
	v.add_child(h)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 10
	slider.value = roundf(cp.next_share * 100.0)
	slider.custom_minimum_size = Vector2(0, UiStyle.TOUCH_MIN)
	slider.tooltip_text = "Arraste (ou use as setas) para dividir o esforço"
	var grab := UiStyle.g_box(Color.WHITE, 14, 0, 0)
	grab.content_margin_left = 14
	grab.content_margin_right = 14
	slider.add_theme_stylebox_override("slider", UiStyle.g_box(Color(1, 1, 1, 0.12), 8, 0, 8))
	slider.add_theme_stylebox_override("grabber_area", UiStyle.g_box(_accent, 8, 0, 8))
	slider.add_theme_stylebox_override("grabber_area_highlight", UiStyle.g_box(_accent, 8, 0, 8))
	slider.value_changed.connect(_on_effort)
	v.add_child(slider)
	var h2 := HBoxContainer.new()
	_effort_val = UiStyle.g_label("", 15, UiStyle.G_TEXT, "black")
	_effort_val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h2.add_child(_effort_val)
	_effort_next = UiStyle.g_label("", 15, UiStyle.G_TEXT_2, "black")
	h2.add_child(_effort_next)
	v.add_child(h2)
	_effort_note = UiStyle.g_label("", 12, UiStyle.G_TEXT_2, "bold")
	_effort_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_effort_note)
	_refresh_effort()
	return v


func _on_effort(value: float) -> void:
	campaign.my_parts().next_share = clampf(value / 100.0, 0.0, 1.0)
	_refresh_effort()
	campaign.save()


func _refresh_effort() -> void:
	var cp := campaign.my_parts()
	var share := roundi(cp.next_share * 100.0)
	_effort_val.text = "%d%%" % (100 - share)
	_effort_next.text = "%d%%" % share
	_effort_note.text = "%d%% do ganho das entregas vai para o carro %d e rende ×%s na virada. Hoje ele já tem %s na nota inicial." % [share, campaign.season + 1,
		ProjectNotes.num(float(CarParts.projects_cfg()["next_k"]), 1), ("+" if campaign.next_car_estimate() >= 0.0 else "−") + ProjectNotes.num(absf(campaign.next_car_estimate()), 1)]


# --- evolução na temporada -----------------------------------------------------------------------------

func _graph() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.add_child(_caption("Evolução na temporada · você × rivais"))
	var g := _Graph.new()
	g.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var lines: Array = []
	var mine: Array = campaign.rating_log.get(campaign.player_team, [])
	# rivais: os 3 de nota mais próxima acima de você (ou os melhores, se você é o mais rápido)
	var others: Array = campaign.teams().filter(func(t: Dictionary) -> bool: return t["id"] != campaign.player_team)
	others.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["car_rating"]) > float(b["car_rating"]))
	var my_r := float(campaign.team()["car_rating"])
	var above := others.filter(func(t: Dictionary) -> bool: return float(t["car_rating"]) >= my_r)
	var pick: Array = above.slice(maxi(0, above.size() - 3)) if above.size() >= 3 else others.slice(0, 3)
	var legend := HBoxContainer.new()
	legend.add_theme_constant_override("separation", 14)
	for t: Dictionary in pick:
		var col := UiStyle.team_accent(t)
		lines.append({"pts": campaign.rating_log.get(t["id"], []), "color": col, "w": 2.5})
		legend.add_child(_legend_item(String(t.get("short", t["name"])), col))
	lines.append({"pts": mine, "color": _accent, "w": 5.0})
	legend.add_child(_legend_item("Você", _accent))
	g.lines = lines
	g.rounds = Campaign.calendar().size()
	v.add_child(g)
	v.add_child(legend)
	if mine.size() < 2:
		var hint := UiStyle.g_label("O gráfico começa depois da primeira corrida.", 12, UiStyle.G_TEXT_3, "bold")
		v.add_child(hint)
	return v


func _legend_item(text: String, col: Color) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	var dot := ColorRect.new()
	dot.color = col
	dot.custom_minimum_size = Vector2(14, 4)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(dot)
	h.add_child(UiStyle.g_label(text, 12, UiStyle.G_TEXT_2, "bold"))
	return h


# --- últimas entregas -------------------------------------------------------------------------------------

func _deliveries(width: float) -> Control:
	var cp := campaign.my_parts()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.add_child(_caption("Últimas entregas"))
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for e: Dictionary in cp.deliveries.slice(0, 8):
		var box := PanelContainer.new()
		box.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_GLASS_TILE, 14, 12, 8))
		var bv := VBoxContainer.new()
		bv.add_theme_constant_override("separation", 2)
		box.add_child(bv)
		var lines := ProjectNotes.delivery_lines(e)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		h.add_child(ScreenKit.icon("check", 16, UiStyle.G_UP))
		h.add_child(UiStyle.g_label(lines[0], 14, UiStyle.G_TEXT, "black"))
		bv.add_child(h)
		var d := UiStyle.g_label(lines[1], 12, UiStyle.G_UP if float(e.get("ratio", 1.0)) >= 1.0 else UiStyle.G_DOWN, "bold")
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(width - 28, 0)
		bv.add_child(d)
		list.add_child(box)
	if cp.deliveries.is_empty():
		var none := UiStyle.g_label("Nada entregue ainda. O ganho real aparece aqui: sempre positivo, entre 60% e 120% do esperado.", 13, UiStyle.G_TEXT_2)
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(none)
	var scroll := DragScroll.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	v.add_child(scroll)
	return v


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.open_campaign_hub()


## Barra da nota (escala 50..100) com o risco branco do melhor rival.
class _RatingBar:
	extends Control
	var value := 70.0
	var best := 0.0
	var color := Color.WHITE
	const LO := 50.0
	const HI := 100.0

	func _init() -> void:
		custom_minimum_size = Vector2(0, 22)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _x(v: float) -> float:
		return size.x * clampf((v - LO) / (HI - LO), 0.0, 1.0)

	func _draw() -> void:
		var r := Rect2(0, 4, size.x, 12)
		draw_style_box(UiStyle.g_box(Color(1, 1, 1, 0.1), 6, 0, 0), r)
		draw_style_box(UiStyle.g_box(color, 6, 0, 0), Rect2(0, 4, maxf(_x(value), 12.0), 12))
		if best > 0.0:
			draw_rect(Rect2(_x(best) - 1.5, 0, 3, 20), Color.WHITE)


## Barra simples (0..1).
class _Bar:
	extends Control
	var value := 0.5
	var color := Color.WHITE

	func _init() -> void:
		custom_minimum_size = Vector2(0, 10)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_style_box(UiStyle.g_box(Color(1, 1, 1, 0.1), 5, 0, 0), Rect2(Vector2.ZERO, size))
		if value > 0.0:
			draw_style_box(UiStyle.g_box(color, 5, 0, 0), Rect2(Vector2.ZERO, Vector2(size.x * clampf(value, 0.03, 1.0), size.y)))


## Linhas da nota do carro por rodada (você grossa; rivais finas).
class _Graph:
	extends Control
	var lines: Array = []  ## [{pts: [nota...], color, w}]
	var rounds := 23

	func _init() -> void:
		custom_minimum_size = Vector2(0, 150)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var lo := INF
		var hi := -INF
		for l: Dictionary in lines:
			for p: Variant in l["pts"]:
				lo = minf(lo, float(p))
				hi = maxf(hi, float(p))
		var area := Rect2(36, 6, size.x - 44, size.y - 30)
		var font := UiStyle.G_BOLD
		var fsz := UiStyle.fs(12)
		for i in 3:  # linhas de grade
			var y := area.position.y + area.size.y * i / 2.0
			draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), Color(1, 1, 1, 0.08), 1.0)
		draw_string(font, Vector2(area.position.x, size.y - 6), "RD 1", HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, UiStyle.G_TEXT_3)
		draw_string(font, Vector2(area.end.x - 48, size.y - 6), "RD %d" % rounds, HORIZONTAL_ALIGNMENT_RIGHT, 48, fsz, UiStyle.G_TEXT_3)
		if lo == INF:
			return
		if hi - lo < 4.0:
			var mid := (hi + lo) * 0.5
			lo = mid - 2.0
			hi = mid + 2.0
		draw_string(font, Vector2(0, area.position.y + 10), str(roundi(hi)), HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, UiStyle.G_TEXT_3)
		draw_string(font, Vector2(0, area.end.y), str(roundi(lo)), HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, UiStyle.G_TEXT_3)
		for l: Dictionary in lines:
			var pts: Array = l["pts"]
			if pts.is_empty():
				continue
			var poly := PackedVector2Array()
			for i in pts.size():
				var x := area.position.x + area.size.x * float(i) / maxf(float(rounds), 1.0)
				var y := area.end.y - area.size.y * (float(pts[i]) - lo) / (hi - lo)
				poly.append(Vector2(x, y))
			if poly.size() >= 2:
				draw_polyline(poly, l["color"], float(l["w"]), true)
			draw_circle(poly[poly.size() - 1], float(l["w"]) + 1.5, l["color"])
