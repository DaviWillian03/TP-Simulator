class_name ProjectNotes
extends RefCounted
## Textos dos projetos de peça (v42) e o aviso de entrega que aparece na sede e na tela Carro:
## "Assoalho C entregue · esperado −0,10 · real −0,12 s/volta (curvas rápidas)".


## "Assoalho · grande".
static func project_name(r: Dictionary) -> String:
	var a := CarParts.area(String(r.get("area", CarParts.area_of_part(String(r.get("part", ""))))))
	var sz := CarParts.size_of(String(r.get("size", "M")))
	return "%s · %s" % [String(a.get("name", r.get("part", ""))), String(sz["name"])]


static func num(v: float, digits := 2) -> String:
	return (("%." + str(digits) + "f") % v).replace(".", ",")


## Segundos por volta ganhos (positivo) → "−0,08 s/volta".
static func sec(v: float) -> String:
	return "−%s s/volta" % num(absf(v))


## Ganho de um conjunto de características numa área: "−0,08 s/volta" ou, na confiabilidade, "−6% de quebras".
static func gain_text(area_id: String, fx: Dictionary) -> String:
	if area_id == "rel":
		return "−%d%% de quebras" % roundi(CarParts.rel_fail_cut(float(fx.get("rel", 0.0))) * 100.0)
	return sec(CarParts.fx_seconds(fx, CarParts.area_profile(area_id)))


## Faixa esperada: "−0,06 A −0,11 s/volta" (no tipo de pista da área).
static func band_text(area_id: String, fx: Dictionary, lo: float, hi: float, keep := 1.0) -> String:
	if area_id == "rel":
		var c := CarParts.rel_fail_cut(float(fx.get("rel", 0.0))) * 100.0
		return "−%d%% a −%d%% de quebras" % [roundi(c * lo), roundi(c * hi)]
	var s := CarParts.fx_seconds(fx, CarParts.area_profile(area_id)) * keep
	return "−%s a −%s s/volta" % [num(s * lo), num(s * hi)]


## Pistas do calendário onde a área mais conta (as 3 de perfil mais parecido).
static func best_tracks(area_id: String, n := 3) -> Array[String]:
	var prof := CarParts.area_profile(area_id)
	var scored: Array = []
	for rd: Dictionary in Campaign.calendar():
		var p := Campaign.track_profile(String(rd["id"]))
		var v := 0.0
		for k: String in CarParts.PERF:
			v += float(prof.get(k, 0.0)) * float(p.get(k, 0.0))
		scored.append([v, String(GameData.circuit(rd["id"]).get("short_name", rd["id"]))])
	scored.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var out: Array[String] = []
	for s: Array in scored.slice(0, n):
		out.append(String(s[1]))
	return out


## Linha de uma entrega: título e detalhe.
static func delivery_lines(e: Dictionary) -> Array[String]:
	var area_id := String(e.get("area", ""))
	var a := CarParts.area(area_id)
	var title := "%s · versão %s · antes da RD %d" % [String(a.get("name", e.get("part", ""))), String(e.get("v", "")), int(e.get("round", 0)) + 1]
	var detail := "Esperado %s · real %s" % [gain_text(area_id, e.get("expected", {})), gain_text(area_id, e.get("real", {}))]
	detail += " (%d%%)" % roundi(float(e.get("ratio", 1.0)) * 100.0)
	if float(e.get("share", 0.0)) > 0.0:
		detail += " · %d%% vai para o carro do ano que vem" % roundi(float(e["share"]) * 100.0)
	return [title, detail]


## Avisos de projetos entregues ainda não vistos (um de cada vez). on_done é chamado depois do último.
static func show_pending(host: Control, camp: Campaign, on_done: Callable) -> void:
	if camp == null or camp.my_parts() == null or not is_instance_valid(host):
		return
	var cp := camp.my_parts()
	if cp.done_research.is_empty():
		return
	cp.done_research.clear()
	var fresh: Array = cp.deliveries.filter(func(e: Dictionary) -> bool: return int(e.get("season", 0)) == camp.season).slice(0, 4)
	if fresh.is_empty():
		return
	var sh := ScreenKit.sheet("Projeto entregue" if fresh.size() == 1 else "%d projetos entregues" % fresh.size(), 760)
	var body: VBoxContainer = sh["body"]
	for e: Dictionary in fresh:
		var card := ScreenKit.g_card(Color(1, 1, 1, 0.06), 16, 16, 12)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		card.add_child(v)
		var lines := delivery_lines(e)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		h.add_child(ScreenKit.icon("check", 18, UiStyle.G_UP))
		h.add_child(UiStyle.g_label(lines[0], 16, UiStyle.G_TEXT, "black"))
		v.add_child(h)
		var d := UiStyle.g_label(lines[1], 13, UiStyle.G_UP if float(e.get("ratio", 1.0)) >= 1.0 else UiStyle.G_TEXT_2, "bold")
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(d)
		body.add_child(card)
	var note := UiStyle.g_label("A peça nova já está nos dois carros. O ganho real fica sempre entre 60% e 120% do esperado.", 13, UiStyle.G_TEXT_2)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(note)
	var ok := CutButton.new()
	ok.text = "OK"
	ok.custom_minimum_size = Vector2(180, 52)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_END
	body.add_child(ok)
	var root: Control = sh["root"]
	ok.pressed.connect(func() -> void:
		root.queue_free()
		camp.save()
		if on_done.is_valid():
			on_done.call())
	host.add_child(root)
