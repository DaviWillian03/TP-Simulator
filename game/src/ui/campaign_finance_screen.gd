extends Control
## Finanças — resumo claro (mockup v11-1): receitas × despesas da temporada, caixa por rodada com projeção,
## saldo por corrida e histórico das temporadas. Os números vêm do livro-caixa da campanha (`Campaign.ledger`).

const INCOME_ROWS := [["sponsors", "Patrocínios"], ["bonus", "Bônus de resultado"], ["prize", "Prêmio do campeonato"]]
const EXPENSE_ROWS := [["ops", "Corridas e operação"], ["payroll", "Folha de pagamento"], ["upkeep", "Manutenção da fábrica"],
	["rd", "P&D (projetos)"], ["works", "Obras da fábrica"], ["contracts", "Contratos e multas"], ["debt", "Dívida"]]

var campaign: Campaign


func _ready() -> void:
	campaign = Session.campaign
	if campaign == null:
		Session.open_campaign.call_deferred()
		return
	var team := campaign.team()
	var page := ScreenKit.garage_page(self, campaign.player_team)
	(page["backdrop"] as GarageBackdrop).set_glow(Color(team["color"]), 0.16)
	var layer: Control = page["layer"]

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UiStyle.SP_L)
	var back := ScreenKit.round_button("back", 52, "Voltar à sede")
	back.pressed.connect(Session.open_campaign_hub)
	head.add_child(back)
	head.add_child(TeamEmblems.make_rect(campaign.player_team, 46))
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -2)
	titles.add_child(UiStyle.g_caption("%s · após %d de %d rodadas" % [team["name"], campaign.round, Campaign.calendar().size()]))
	titles.add_child(UiStyle.g_label("FINANÇAS", 26, UiStyle.G_TEXT, "black"))
	head.add_child(titles)
	ScreenKit.place(head, layer, Control.PRESET_TOP_LEFT, Vector2(44, 20))
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", UiStyle.SP_M)
	chips.add_child(_chip("Caixa", "US$ %d mi" % int(campaign.budget_musd)))
	chips.add_child(_chip("Projeção fim da temporada", "US$ %d mi" % int(campaign.projected_cash_end())))
	ScreenKit.place(chips, layer, Control.PRESET_TOP_RIGHT, Vector2(-44, 26))
	ScreenKit.campaign_nav(layer, "finance")

	_card(layer, Vector2(44, 150), Vector2(520, 190), "Receitas · temporada %d" % campaign.season, _income())
	_card(layer, Vector2(44, 352), Vector2(520, 348), "Despesas · temporada %d" % campaign.season, _expenses())
	var chart_card := _card(layer, Vector2(580, 150), Vector2(656, 296), "Caixa após cada rodada · projeção", _chart())
	_card(layer, Vector2(580, 458), Vector2(320, 242), "Por corrida", _per_race())
	_card(layer, Vector2(916, 458), Vector2(320, 242), "Temporadas anteriores", _history())
	chart_card.clip_contents = true


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


func _card(layer: Control, at: Vector2, size: Vector2, title: String, content: Control) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.06), 22, 20, 16))
	ScreenKit.place(card, layer, Control.PRESET_TOP_LEFT, at, size)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)
	v.add_child(UiStyle.g_caption(title))
	v.add_child(content)
	return card


func _money(v: float) -> String:
	return ("%.1f" % v).replace(".", ",")


func _row(name: String, value: float, max_value: float, color: Color) -> Control:
	var h := HBoxContainer.new()
	h.custom_minimum_size = Vector2(0, 30)
	h.add_theme_constant_override("separation", 10)
	var n := UiStyle.g_label(name, 15, Color("#e3e6eb"), "bold")
	n.custom_minimum_size = Vector2(190, 0)
	n.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(n)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = maxf(max_value, 0.01)
	bar.value = maxf(value, 0.0)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.custom_minimum_size = Vector2(0, 10)
	bar.add_theme_stylebox_override("background", UiStyle.g_box(Color(1, 1, 1, 0.08), 5, 0, 0))
	bar.add_theme_stylebox_override("fill", UiStyle.g_box(color, 5, 0, 0))
	h.add_child(bar)
	var v := UiStyle.g_label("US$ %s mi" % _money(value), 16, UiStyle.G_TEXT, "black")
	v.custom_minimum_size = Vector2(98, 0)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(v)
	return h


func _total(text: String, value: float, color: Color) -> Control:
	var h := HBoxContainer.new()
	var l := UiStyle.g_label(text, 15, Color("#c3c9d3"))
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	h.add_child(UiStyle.g_label("US$ %s mi" % _money(value), 22, color, "black"))
	return h


func _income() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	var top := 0.01
	for r: Array in INCOME_ROWS:
		top = maxf(top, float(campaign.ledger.get(r[0], 0.0)))
	for r: Array in INCOME_ROWS:
		var amount := float(campaign.ledger.get(r[0], 0.0))
		if amount > 0.0 or r[0] != "prize":
			v.add_child(_row(r[1], amount, top, Color("#3ec9a6")))
	v.add_child(_total("Receitas até agora", campaign.income_total(), Color("#7fe0b1")))
	return v


func _expenses() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	var top := 0.01
	for r: Array in EXPENSE_ROWS:
		top = maxf(top, float(campaign.ledger.get(r[0], 0.0)))
	for r: Array in EXPENSE_ROWS:
		var amount := float(campaign.ledger.get(r[0], 0.0))
		if amount <= 0.0 and r[0] == "debt":
			continue
		var color := Color("#ff6a5a") if r[0] in ["ops", "payroll", "upkeep"] else Color("#ffd24a")
		v.add_child(_row(r[1], amount, top, color))
	v.add_child(_total("Despesas até agora", campaign.expense_total(), Color("#ffb4a8")))
	return v


func _per_race() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	var f: Dictionary = Campaign.origins_data()["finance"]
	var sponsor := campaign.sponsor_per_race()
	var payroll := campaign.personnel.payroll_per_race(campaign)
	var ops := float(f["cost_base"]) + campaign.dev.upkeep_per_race()
	for r: Array in [["Patrocínios", "+ US$ %s mi" % _money(sponsor), Color("#7fe0b1")], ["Folha", "− US$ %s mi" % _money(payroll), Color("#ffb4a8")],
			["Fábrica e operação", "− US$ %s mi" % _money(ops), Color("#ffb4a8")]]:
		var h := HBoxContainer.new()
		h.custom_minimum_size = Vector2(0, 30)
		var l := UiStyle.g_label(r[0], 15, Color("#e3e6eb"), "bold")
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		h.add_child(UiStyle.g_label(r[1], 16, r[2], "black"))
		v.add_child(h)
	var net := sponsor - payroll - ops
	var tot := HBoxContainer.new()
	var tl := UiStyle.g_label("Saldo por corrida", 15, Color("#c3c9d3"))
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tot.add_child(tl)
	tot.add_child(UiStyle.g_label("%s US$ %s mi" % ["+" if net >= 0.0 else "−", _money(absf(net))], 20, Color("#7fe0b1") if net >= 0.0 else Color("#ffb4a8"), "black"))
	v.add_child(tot)
	return v


func _history() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	if campaign.seasons.is_empty():
		v.add_child(UiStyle.g_label("Aparece a cada temporada encerrada.", 13, UiStyle.G_TEXT_3))
		return v
	var head := HBoxContainer.new()
	for t: Array in [["Temp.", 56], ["Pos.", 46], ["Prêmio", 90], ["Saldo", 90]]:
		var l := UiStyle.g_caption(t[0])
		l.custom_minimum_size = Vector2(t[1], 0)
		head.add_child(l)
	v.add_child(head)
	for r: Dictionary in campaign.seasons.slice(-5):
		var row := HBoxContainer.new()
		for t: Array in [[str(int(r["season"])), 56], ["%dº" % int(r["position"]), 46], ["US$ %d mi" % int(r["prize"]), 90], ["US$ %d mi" % int(r["budget"]), 90]]:
			var l := UiStyle.g_label(t[0], 14, UiStyle.G_TEXT, "bold")
			l.custom_minimum_size = Vector2(t[1], 0)
			row.add_child(l)
		v.add_child(row)
	return v


func _chart() -> Control:
	var c := CashChart.new()
	c.custom_minimum_size = Vector2(610, 214)
	c.log = campaign.cash_log
	c.rounds = Campaign.calendar().size()
	c.per_race = campaign.sponsor_per_race() - campaign.cost_per_race()
	c.prize = float(Campaign.origins_data()["finance"]["prize_pool"][mini(campaign.team_position(campaign.player_team), 12) - 1])
	return c


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.open_campaign_hub()


## Caixa depois de cada rodada (linha cheia) e projeção até a última rodada (tracejada), com a reserva mínima.
class CashChart:
	extends Control

	var log: Array = []
	var rounds := 22
	var per_race := 0.0
	var prize := 0.0

	func _draw() -> void:
		if log.is_empty():
			return
		var lo := INF
		var hi := -INF
		var last_r := int(log[log.size() - 1]["r"])
		var last_cash := float(log[log.size() - 1]["cash"])
		var proj: Array = []
		for r in range(last_r, rounds + 1):
			var cash := last_cash + per_race * (r - last_r) + (prize if r == rounds else 0.0)
			proj.append([r, cash])
		for p: Dictionary in log:
			lo = minf(lo, float(p["cash"]))
			hi = maxf(hi, float(p["cash"]))
		for p: Array in proj:
			lo = minf(lo, float(p[1]))
			hi = maxf(hi, float(p[1]))
		lo = minf(lo, CarDevelopment.RESERVE_MUSD)
		var pad := maxf((hi - lo) * 0.12, 4.0)
		lo -= pad
		hi += pad
		var x0 := 16.0
		var w := size.x - 32.0
		var h := size.y - 30.0
		var pt := func(r: float, cash: float) -> Vector2:
			return Vector2(x0 + w * r / float(maxi(rounds, 1)), 8.0 + (1.0 - (cash - lo) / maxf(hi - lo, 0.01)) * (h - 16.0))
		var ry: float = (pt.call(0.0, CarDevelopment.RESERVE_MUSD) as Vector2).y
		draw_dashed_line(Vector2(x0, ry), Vector2(x0 + w, ry), Color(1, 0.42, 0.35, 0.5), 1.5, 6.0)
		draw_string(UiStyle.G_BOLD, Vector2(x0 + 4, ry - 5), "RESERVA MÍNIMA", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#ff6a5a"))
		var pp := PackedVector2Array()
		for p: Array in proj:
			pp.append(pt.call(float(p[0]), float(p[1])))
		if pp.size() > 1:
			draw_dashed_line(pp[0], pp[pp.size() - 1], Color("#8f98a7"), 3.0, 8.0)
			for i in range(1, pp.size() - 1):
				pass
		var lp := PackedVector2Array()
		for p: Dictionary in log:
			lp.append(pt.call(float(p["r"]), float(p["cash"])))
		if lp.size() > 1:
			draw_polyline(lp, Color("#3ec9a6"), 4.0, true)
		var end: Vector2 = lp[lp.size() - 1]
		draw_circle(end, 7.0, Color.WHITE, true, -1.0, true)
		draw_arc(end, 7.0, 0.0, TAU, 20, Color("#3ec9a6"), 3.0, true)
		draw_string(UiStyle.G_BOLD, Vector2(x0, size.y - 6), "RD 1", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UiStyle.G_TEXT_3)
		draw_string(UiStyle.G_BOLD, Vector2(x0 + w - 40, size.y - 6), "RD %d" % rounds, HORIZONTAL_ALIGNMENT_RIGHT, 40, 11, UiStyle.G_TEXT_3)
