extends Control
## Finanças (mockups v11-1 e v19 aprovados): receitas × despesas da temporada, teto de gastos (trava rígida), crédito
## (banco com juros e adiantamento de patrocínio) e a restrição de túnel de vento pela posição do ano anterior.
## Os números vêm do livro-caixa da campanha (`Campaign.ledger`).

const INCOME_ROWS := [["sponsors", "Patrocínios"], ["bonus", "Bônus de resultado"], ["prize", "Prêmio do campeonato"], ["events_in", "Apoio e eventos"],
	["loan", "Empréstimo e adiantamento"]]
const EXPENSE_ROWS := [["ops", "Corridas e operação"], ["upkeep", "Manutenção da fábrica"], ["rd", "P&D e peças"], ["payroll", "Folha de pagamento"],
	["works", "Obras da fábrica"], ["contracts", "Contratos e multas"], ["events", "Eventos inesperados"], ["debt", "Juros e parcelas"]]

var campaign: Campaign
var _layer: Control


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
	chips.add_child(_chip("Dívida", "US$ %s mi" % _money(campaign.debt_total())))
	ScreenKit.place(chips, layer, Control.PRESET_TOP_RIGHT, Vector2(-44, 26))
	ScreenKit.campaign_nav(layer, "finance")

	_layer = layer
	_card(layer, Vector2(44, 150), Vector2(520, 250), "Receitas · temporada %d" % campaign.season, _income())
	_card(layer, Vector2(44, 412), Vector2(520, 288), "Despesas · temporada %d" % campaign.season, _expenses())
	_card(layer, Vector2(580, 150), Vector2(656, 250), "Teto de gastos %d · igual para todas as equipes" % campaign.season, _cap())
	_card(layer, Vector2(580, 412), Vector2(320, 288), "Crédito", _credit())
	_card(layer, Vector2(916, 412), Vector2(320, 288), "Túnel de vento %d" % campaign.season, _atr())


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


func _row(name: String, value: float, max_value: float, color: Color, capped: bool = false) -> Control:
	var h := HBoxContainer.new()
	h.custom_minimum_size = Vector2(0, 28)
	h.add_theme_constant_override("separation", 8)
	var n := UiStyle.g_label(name, 15, Color("#e3e6eb"), "bold")
	n.custom_minimum_size = Vector2(0 if capped else 190, 0)
	n.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(n)
	if capped:  # conta no teto de gastos
		var tag := UiStyle.g_label("TETO", 10, Color("#ffd24a"), "black")
		tag.custom_minimum_size = Vector2(190 - UiStyle.G_BOLD.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, UiStyle.fs(15)).x - 8, 0)
		tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(tag)
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
		if amount > 0.0 or r[0] in ["sponsors", "bonus"]:
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
		if amount <= 0.0 and r[0] in ["debt", "events"]:
			continue
		var capped: bool = Campaign.CAP_CATEGORIES.has(r[0])
		v.add_child(_row(r[1], amount, top, Color("#ff6a5a") if capped else Color("#8f98a7"), capped))
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


# --- teto, crédito e túnel (item 5) -------------------------------------------------------------------

func _cap() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	var h := HBoxContainer.new()
	var spent := campaign.cap_spent()
	var a := UiStyle.g_label("US$ %s mi" % _money(spent), 30, UiStyle.G_TEXT, "black")
	h.add_child(a)
	var b := UiStyle.g_label("  gastos de US$ %d mi" % int(Campaign.COST_CAP_MUSD), 14, UiStyle.G_TEXT_2, "bold")
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_SHRINK_END
	h.add_child(b)
	h.add_child(UiStyle.g_label("US$ %s mi livres" % _money(campaign.cap_left()), 20, Color("#7fe0b1") if campaign.cap_left() > 10.0 else Color("#ffb4a8"), "black"))
	v.add_child(h)
	var meter := CapMeter.new()
	meter.parts = [[float(campaign.ledger.get("ops", 0.0)), Color("#ff6a5a")], [float(campaign.ledger.get("upkeep", 0.0)), Color("#ffb4a8")],
		[maxf(float(campaign.ledger.get("rd", 0.0)), 0.0), Color("#c77dff")]]
	meter.limit = Campaign.COST_CAP_MUSD
	v.add_child(meter)
	var leg := HBoxContainer.new()
	leg.add_theme_constant_override("separation", 14)
	for e: Array in [["operação", "#ff6a5a"], ["manutenção", "#ffb4a8"], ["P&D e peças", "#c77dff"]]:
		var d := HBoxContainer.new()
		d.add_theme_constant_override("separation", 6)
		var sq := ColorRect.new()
		sq.color = Color(e[1])
		sq.custom_minimum_size = Vector2(10, 10)
		sq.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		d.add_child(sq)
		d.add_child(UiStyle.g_label(e[0], 12, Color("#c3c9d3"), "bold"))
		leg.add_child(d)
	var outl := UiStyle.g_label("fora do teto: salários, obras e juros", 12, UiStyle.G_TEXT_3, "bold")
	outl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	leg.add_child(outl)
	v.add_child(leg)
	var lock := PanelContainer.new()
	lock.add_theme_stylebox_override("panel", UiStyle.g_box(Color(0.88, 0.02, 0.0, 0.14), 12, 12, 8))
	var lh := HBoxContainer.new()
	lh.add_theme_constant_override("separation", 8)
	lh.add_child(ScreenKit.icon("lock", 18, Color("#ffb4a8")))
	var lt := UiStyle.g_label("Trava rígida: quando o teto acaba, projetos, pesquisas e peças novas ficam bloqueados até a próxima temporada.", 13, Color("#ffb4a8"), "bold")
	lt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lh.add_child(lt)
	lock.add_child(lh)
	v.add_child(lock)
	return v


func _credit() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	var bank_total := 0.0
	var bank_per := 0.0
	var bank_races := 0
	for l: Dictionary in campaign.loans:
		bank_total += float(l["per_race"]) * int(l["races_left"])
		bank_per += float(l["per_race"])
		bank_races = maxi(bank_races, int(l["races_left"]))
	v.add_child(_loan_row("bank", "Banco", ("%d parcelas restantes" % bank_races) if bank_races > 0 else "sem empréstimo",
		"US$ %s mi" % _money(bank_total) if bank_total > 0.0 else "—", ("− %s por corrida" % _money(bank_per)) if bank_per > 0.0 else "nenhum"))
	var adv := campaign.advance
	v.add_child(_loan_row("hand", "Adiantamento", "patrocínio antecipado",
		"US$ %s mi" % _money(float(adv["amount"])) if not adv.is_empty() else "—", ("− %s por corrida" % _money(float(adv["cut"]))) if not adv.is_empty() else "nenhum"))
	var b := ScreenKit.light_button("Pedir dinheiro")
	b.pressed.connect(_open_loan_sheet)
	b.disabled = campaign.bank_room() <= 0.0 and campaign.advance_room() <= 0.0
	v.add_child(b)
	return v


func _loan_row(icon_name: String, title: String, sub: String, value: String, per: String) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(Color(0, 0, 0, 0.25), 16, 10, 8))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var ic := PanelContainer.new()
	ic.custom_minimum_size = Vector2(44, 44)
	var col := Color("#5c93ea") if icon_name == "bank" else Color("#ffd24a")
	ic.add_theme_stylebox_override("panel", UiStyle.g_box(Color(col, 0.2), 14, 10, 10))
	ic.add_child(ScreenKit.icon("money" if icon_name == "bank" else "arrow", 22, col))
	h.add_child(ic)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", -3)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UiStyle.g_label(title, 16, UiStyle.G_TEXT, "black"))
	tv.add_child(UiStyle.g_label(sub, 12, UiStyle.G_TEXT_2, "bold"))
	h.add_child(tv)
	var vv := VBoxContainer.new()
	vv.add_theme_constant_override("separation", -3)
	var a := UiStyle.g_label(value, 17, UiStyle.G_TEXT, "black")
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vv.add_child(a)
	var b := UiStyle.g_label(per, 12, Color("#ffb4a8") if per != "nenhum" else UiStyle.G_TEXT_2, "bold")
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vv.add_child(b)
	h.add_child(vv)
	p.add_child(h)
	return p


func _atr() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(Color(0.36, 0.58, 0.92, 0.14), 14, 12, 10))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.add_child(ScreenKit.icon("t_fast", 30, Color("#5c93ea")))
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", -2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UiStyle.g_label("%d%%" % roundi(campaign.atr_mult(campaign.player_team) * 100.0), 22, Color("#5c93ea"), "black"))
	var pos := int(campaign.last_positions.get(campaign.player_team, 0))
	var sub := UiStyle.g_label("do tempo de pesquisa de aerodinâmica · %s" % ("%dº no ano passado" % pos if pos > 0 else "%dº carro do grid" % campaign.rating_rank(campaign.player_team)), 12, Color("#c3c9d3"), "bold")
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(sub)
	h.add_child(tv)
	p.add_child(h)
	v.add_child(p)
	var note := UiStyle.g_label("Regra da F1: quem termina mais à frente pesquisa menos aerodinâmica no ano seguinte (campeão 70%, último 115%). Vale para todas as equipes, inclusive a IA: muda os dias e a chance das pesquisas de aero.", 12, UiStyle.G_TEXT_3, "bold")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(note)
	return v


## Folha "Pedir dinheiro" (mockup v19-2): banco (valor + prazo) ou adiantamento de patrocínio.
func _open_loan_sheet() -> void:
	var sh := ScreenKit.sheet("Pedir dinheiro", 780)
	var body: VBoxContainer = sh["body"]
	var state := {"kind": "bank" if campaign.bank_room() > 0.0 else "advance", "amount": 0.0, "term": 1}
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	var draw: Callable
	draw = func() -> void:
		for c in content.get_children():
			c.queue_free()
		var room: float = campaign.bank_room() if state["kind"] == "bank" else campaign.advance_room()
		if float(state["amount"]) <= 0.0 or float(state["amount"]) > room:
			state["amount"] = snappedf(room * 0.5, 1.0) if room >= 2.0 else room
		var tabs := ScreenKit.segmented([["bank", "Banco · com juros"], ["advance", "Adiantamento de patrocínio"]], state["kind"], func(k: Variant) -> void:
			state["kind"] = String(k)
			state["amount"] = 0.0
			draw.call())
		content.add_child(tabs)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		var val := UiStyle.g_label("US$ %s mi" % _money(float(state["amount"])), 40, UiStyle.G_TEXT, "black")
		val.custom_minimum_size = Vector2(250, 0)
		row.add_child(val)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = maxf(room, 0.1)
		slider.step = 0.5
		slider.value = float(state["amount"])
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slider.custom_minimum_size = Vector2(0, 44)
		slider.value_changed.connect(func(x: float) -> void:
			state["amount"] = x
			val.text = "US$ %s mi" % _money(x))
		slider.drag_ended.connect(func(_c: bool) -> void: draw.call())
		row.add_child(slider)
		row.add_child(UiStyle.g_label("limite US$ %s mi" % _money(room), 13, UiStyle.G_TEXT_2, "bold"))
		content.add_child(row)
		if state["kind"] == "bank":
			var terms := HBoxContainer.new()
			terms.add_theme_constant_override("separation", 10)
			for i in Campaign.BANK_TERMS.size():
				var info := campaign.loan_info(float(state["amount"]), i)
				var t: Array = Campaign.BANK_TERMS[i]
				var b := Button.new()
				b.focus_mode = Control.FOCUS_NONE
				b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				b.custom_minimum_size = Vector2(0, 70)
				var on: bool = int(state["term"]) == i
				for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
					b.add_theme_stylebox_override(s, UiStyle.g_box(UiStyle.G_LIGHT if on else Color(1, 1, 1, 0.06), 16, 14, 8))
				b.text = "%s\njuros %d%% · US$ %s mi por corrida" % [("%d corridas" % int(t[0])) if int(t[0]) > 0 else "Até o fim de %d" % (campaign.season + 1), roundi(float(t[1]) * 100.0), _money(float(info["per_race"]))]
				b.add_theme_color_override("font_color", UiStyle.G_INK if on else UiStyle.G_TEXT)
				b.add_theme_font_size_override("font_size", UiStyle.fs(13))
				b.pressed.connect(func() -> void: state["term"] = i; draw.call())
				terms.add_child(b)
			content.add_child(terms)
		var facts := HBoxContainer.new()
		facts.add_theme_constant_override("separation", 10)
		var amount := float(state["amount"])
		var to_pay := float(campaign.loan_info(amount, int(state["term"]))["total"]) if state["kind"] == "bank" else amount
		var penalty: bool = state["kind"] == "bank" and campaign.debt_total() + to_pay > Campaign.DEBT_TRUST_LIMIT
		for f: Array in [["US$ %d mi" % int(campaign.budget_musd + amount), "caixa depois"],
				["US$ %s mi" % _money(to_pay), "total a pagar" if state["kind"] == "bank" else "a menos no patrocínio até o fim do ano"],
				["−3" if penalty else "0", "confiança da diretoria (dívida alta)"]]:
			var p := PanelContainer.new()
			p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			p.add_theme_stylebox_override("panel", UiStyle.g_box(Color(0, 0, 0, 0.3), 14, 14, 8))
			var fv := VBoxContainer.new()
			fv.add_theme_constant_override("separation", -3)
			fv.add_child(UiStyle.g_label(f[0], 20, UiStyle.G_TEXT, "black"))
			var cap_l := UiStyle.g_label(f[1], 12, UiStyle.G_TEXT_2, "bold")
			cap_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			fv.add_child(cap_l)
			p.add_child(fv)
			facts.add_child(p)
		content.add_child(facts)
		var warn := UiStyle.g_label("O dinheiro emprestado entra no caixa, mas os gastos continuam limitados pelo teto.", 13, Color("#ffd24a"), "bold")
		content.add_child(warn)
		var go := CutButton.new()
		go.text = "CONFIRMAR"
		go.custom_minimum_size = Vector2(300, 56)
		go.size_flags_horizontal = Control.SIZE_SHRINK_END
		go.disabled = amount <= 0.0
		go.pressed.connect(func() -> void:
			var ok: bool = campaign.take_loan(amount, int(state["term"])) if state["kind"] == "bank" else campaign.take_advance(amount)
			if ok:
				campaign.save()
				Session.open_campaign_finance())
		content.add_child(go)
	body.add_child(content)
	draw.call()
	add_child(sh["root"])


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
		draw_string(UiStyle.G_BOLD, Vector2(x0 + 4, ry - 5), "RESERVA MÍNIMA", HORIZONTAL_ALIGNMENT_LEFT, -1, UiStyle.fs(11), Color("#ff6a5a"))
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
		draw_string(UiStyle.G_BOLD, Vector2(x0, size.y - 6), "RD 1", HORIZONTAL_ALIGNMENT_LEFT, -1, UiStyle.fs(11), UiStyle.G_TEXT_3)
		draw_string(UiStyle.G_BOLD, Vector2(x0 + w - 40, size.y - 6), "RD %d" % rounds, HORIZONTAL_ALIGNMENT_RIGHT, 40, UiStyle.fs(11), UiStyle.G_TEXT_3)


## Barra do teto de gastos: segmentos gastos por categoria e a marca do limite.
class CapMeter:
	extends Control
	var parts: Array = []  ## [[valor, cor]]
	var limit := 150.0

	func _init() -> void:
		custom_minimum_size = Vector2(0, 26)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_style_box(UiStyle.g_box(Color(1, 1, 1, 0.08), 13, 0, 0), Rect2(Vector2.ZERO, size))
		var x := 0.0
		for p: Array in parts:
			var w := size.x * clampf(float(p[0]) / limit, 0.0, 1.0)
			w = minf(w, size.x - x)
			if w > 0.0:
				draw_rect(Rect2(x, 0, w, size.y), p[1])
			x += w
		draw_rect(Rect2(size.x - 3, -4, 3, size.y + 8), UiStyle.RED)
