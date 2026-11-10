class_name PartsDialogs
extends RefCounted
## Avisos das peças (mockups v15-3 e v15-4 aprovados): "pesquisa concluída" (quantas unidades fabricar) e o resultado
## real de um upgrade depois da primeira corrida com ele (funcionou / rendeu menos / não funcionou: voltar, corrigir ou
## manter). Usados pela sede e pela tela de peças; mostram um aviso por vez, na ordem.

const GOOD := Color("#3c9d5d")
const MID := Color("#ffd24a")


## Mostra o próximo aviso pendente (se houver); ao fechar, mostra o seguinte e chama on_done.
static func show_pending(screen: Control, camp: Campaign, on_done: Callable) -> bool:
	var cp := camp.my_parts()
	if cp == null:
		return false
	if not cp.done_research.is_empty():
		var e: Dictionary = cp.done_research.pop_front()
		_research_done(screen, camp, e, on_done)
		return true
	if not cp.reveals.is_empty():
		var r: Dictionary = cp.reveals.pop_front()
		_reveal(screen, camp, r, on_done)
		return true
	return false


static func _next(screen: Control, camp: Campaign, on_done: Callable) -> void:
	camp.refresh_rating()
	camp.save()
	if on_done.is_valid():
		on_done.call()
	if screen.is_inside_tree():
		show_pending(screen, camp, on_done)


static func _fx_chips(fx: Dictionary) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	for k: String in fx:
		var v := float(fx[k])
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UiStyle.g_box(Color(GOOD, 0.2) if v > 0 else Color(UiStyle.RED, 0.18), 10, 10, 4))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var icon_name: String = {"straight": "t_straight", "slow": "t_slow", "fast": "t_fast", "rel": "t_rel"}[k]
		row.add_child(ScreenKit.icon(icon_name, 18, UiStyle.G_TEXT))
		row.add_child(UiStyle.g_label("%s %s" % ["▲" if v > 0 else "▼", ("%.1f" % absf(v)).replace(".", ",").trim_suffix(",0")], 16,
			Color("#7fe0b1") if v > 0 else Color("#ff8a80"), "black"))
		p.add_child(row)
		h.add_child(p)
	return h


static func _fact(icon_name: String, value: String, caption: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", UiStyle.g_box(Color(1, 1, 1, 0.06), 14, 12, 8))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.add_child(ScreenKit.icon(icon_name, 22, UiStyle.G_TEXT_2))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -3)
	v.add_child(UiStyle.g_label(value, 18, UiStyle.G_TEXT, "black"))
	v.add_child(UiStyle.g_label(caption, 11, UiStyle.G_TEXT_2, "bold"))
	h.add_child(v)
	p.add_child(h)
	return p


## Blocos de escolha: [[id, título, sub, preço]]; devolve {row, get: Callable}
static func _choices(items: Array) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var state := {"sel": items[0][0]}
	var buttons: Array[Button] = []
	var paint := func() -> void:
		for b: Button in buttons:
			var on: bool = b.get_meta("id") == state["sel"]
			var st := UiStyle.g_box(UiStyle.G_LIGHT if on else Color(1, 1, 1, 0.06), 16, 14, 10)
			for s: String in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
				b.add_theme_stylebox_override(s, st)
			for l: Label in b.find_children("*", "Label", true, false):
				l.add_theme_color_override("font_color", UiStyle.G_INK if on else (UiStyle.G_TEXT_2 if l.has_meta("sub") else UiStyle.G_TEXT))
	for it: Array in items:
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 112)
		b.set_meta("id", it[0])
		var v := VBoxContainer.new()
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 14
		v.offset_right = -14
		v.offset_top = 10
		v.offset_bottom = -10
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_theme_constant_override("separation", 2)
		v.add_child(UiStyle.g_label(it[1], 16, UiStyle.G_TEXT, "black"))
		var s := UiStyle.g_label(it[2], 12, UiStyle.G_TEXT_2, "bold")
		s.set_meta("sub", true)
		s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(s)
		var sp := Control.new()
		sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(sp)
		v.add_child(UiStyle.g_label(it[3], 18, UiStyle.G_TEXT, "black"))
		b.add_child(v)
		b.pressed.connect(func() -> void: state["sel"] = it[0]; paint.call())
		ScreenKit.press_feedback(b)
		buttons.append(b)
		row.add_child(b)
	paint.call()
	return {"row": row, "get": func() -> String: return state["sel"]}


static func _money(v: float) -> String:
	return ("%.1f" % v).replace(".", ",") if absf(v) < 10.0 else "%d" % roundi(v)


static func _research_done(screen: Control, camp: Campaign, e: Dictionary, on_done: Callable) -> void:
	var cp := camp.my_parts()
	var pid: String = e["part"]
	var p := CarParts.part(pid)
	var s := cp.spec(pid, int(e["spec"]))
	var title := "%s %s %s" % [String(p["name"]).to_upper(), s["v"], "CORRIGIDA" if bool(e.get("fix", false)) else "LIBERADA"]
	var sh := ScreenKit.sheet("Pesquisa concluída · " + String(p["area"]).to_lower(), 860)
	var body: VBoxContainer = sh["body"]
	body.add_child(UiStyle.g_label(title, 30, UiStyle.G_TEXT, "black"))
	body.add_child(_fx_chips(s["fx"]))
	if bool(e.get("fix", false)):
		var ok := CutButton.new()
		ok.text = "ENTENDI"
		ok.pressed.connect(func() -> void: sh["root"].queue_free(); _next(screen, camp, on_done))
		body.add_child(ok)
		screen.add_child(sh["root"])
		return
	var d1 := cp.ready_in(camp, pid, 1)
	var d2 := cp.ready_in(camp, pid, 2)
	var gp1 := camp.race_after(d1)
	var gp2 := camp.race_after(d2)
	var facts := HBoxContainer.new()
	facts.add_theme_constant_override("separation", 10)
	facts.add_child(_fact("money", "US$ %s mi" % _money(cp.unit_cost(pid)), "por unidade"))
	facts.add_child(_fact("clock", "%d dias" % cp.unit_days(camp, pid), "por unidade"))
	facts.add_child(_fact("flag", _short(gp1), "1ª unidade a tempo"))
	facts.add_child(_fact("flag", _short(gp2), "2ª unidade"))
	body.add_child(facts)
	var ch := _choices([["2", "Fabricar 2", "Uma para cada carro.", "US$ %s mi" % _money(cp.unit_cost(pid) * 2)],
		["1", "Fabricar 1", "Estreia num carro; a 2ª pode vir depois.", "US$ %s mi" % _money(cp.unit_cost(pid))],
		["0", "Depois", "A especificação fica liberada para quando quiser.", "—"]])
	body.add_child(ch["row"])
	var go := CutButton.new()
	go.text = "CONFIRMAR"
	go.pressed.connect(func() -> void:
		var n := int(ch["get"].call())
		if n > 0:
			cp.order_units(camp, pid, int(e["spec"]), n)
		sh["root"].queue_free()
		_next(screen, camp, on_done))
	body.add_child(go)
	screen.add_child(sh["root"])


static func _short(r: Dictionary) -> String:
	if r.is_empty():
		return "2027"
	var g := String(r.get("grand_prix", ""))
	for pre: String in ["GP da ", "GP do ", "GP de ", "GP dos ", "GP das ", "GP "]:
		if g.begins_with(pre):
			return g.trim_prefix(pre)
	return g


static func _reveal(screen: Control, camp: Campaign, r: Dictionary, on_done: Callable) -> void:
	var cp := camp.my_parts()
	var pid: String = r["part"]
	var p := CarParts.part(pid)
	var s := cp.spec(pid, int(r["spec"]))
	var outcome := String(s["outcome"])
	var name := "%s %s" % [String(p["name"]).to_upper(), s["v"]]
	var head: String = {"good": "%s FUNCIONOU" % name, "small": "%s RENDEU MENOS" % name, "bad": "%s NÃO FUNCIONOU" % name}.get(outcome, name)
	var sh := ScreenKit.sheet("Primeira corrida com a peça", 860)
	var body: VBoxContainer = sh["body"]
	var band := ColorRect.new()
	band.color = {"good": GOOD, "small": MID}.get(outcome, UiStyle.RED)
	band.custom_minimum_size = Vector2(0, 6)
	body.add_child(band)
	body.add_child(UiStyle.g_label(head, 30, UiStyle.G_TEXT, "black"))
	var cmp := HBoxContainer.new()
	cmp.add_theme_constant_override("separation", 16)
	var a := VBoxContainer.new()
	a.add_child(UiStyle.g_caption("Prometido"))
	a.add_child(_fx_chips(s["fx"]))
	cmp.add_child(a)
	cmp.add_child(ScreenKit.icon("arrow", 28, UiStyle.G_TEXT_2))
	var b := VBoxContainer.new()
	b.add_child(UiStyle.g_caption("Na pista"))
	b.add_child(_fx_chips(s["real"]))
	cmp.add_child(b)
	body.add_child(cmp)
	var msg: String = {"good": "A correlação entre túnel e pista bateu. A peça entrega o que prometeu.",
		"small": "A peça funciona, mas rende menos do que o túnel de vento mostrou.",
		"bad": "A correlação entre túnel e pista falhou: a peça deixou o carro pior."}.get(outcome, "")
	var ml := UiStyle.g_label(msg + " Isso também acontece com as rivais.", 14, UiStyle.G_TEXT_2)
	ml.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(ml)
	if outcome == "good":
		var ok := CutButton.new()
		ok.text = "ÓTIMO"
		ok.pressed.connect(func() -> void: sh["root"].queue_free(); _next(screen, camp, on_done))
		body.add_child(ok)
		screen.add_child(sh["root"])
		return
	var fix := cp.fix_info(camp, pid, int(r["spec"]))
	var items: Array = []
	if outcome == "bad":
		items.append(["revert", "Voltar à anterior", "As unidades antigas voltam para os carros. A %s fica guardada." % s["v"], "grátis"])
	if fix["ok"]:
		items.append(["fix", "Corrigir a %s" % s["v"], "Pesquisa curta (%d dias). Pode dar certo ou não." % int(fix["days"]), "US$ %s mi" % _money(float(fix["cost"]))])
	items.append(["keep", "Manter", "Segue com a peça como está.", "—"])
	var ch := _choices(items)
	body.add_child(ch["row"])
	var go := CutButton.new()
	go.text = "CONFIRMAR"
	go.pressed.connect(func() -> void:
		match String(ch["get"].call()):
			"revert":
				for car in 2:
					var u := cp.unit_on(pid, car)
					if int(u.get("spec", -1)) == int(r["spec"]):
						var alt := cp.best_stock_unit(pid)
						if not alt.is_empty() and int(alt["spec"]) != int(r["spec"]):
							cp.install(int(alt["uid"]), car)
			"fix":
				cp.start_fix(camp, pid, int(r["spec"]))
		sh["root"].queue_free()
		_next(screen, camp, on_done))
	body.add_child(go)
	screen.add_child(sh["root"])
