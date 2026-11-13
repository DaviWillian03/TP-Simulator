class_name WeatherSheet
extends RefCounted
## Folha de clima da corrida (mockup design/mockups/v38-clima.html, aprovado em 2026-11-13). Abre pelo selo do clima na
## barra do topo; a corrida continua atrás e a folha se atualiza sozinha. Tudo é a PREVISÃO DA SUA EQUIPE
## (TeamForecast: erra conforme o pessoal, nunca é 100%): recado do engenheiro com faixa de voltas e confiança, pista e
## pneu agora, linha do tempo das próximas voltas e a volta em que outro tipo de pneu deve passar a valer.

const HORIZON := 12
const BAR_MAX := 64.0
const RAIN_BLUE := UiStyle.G_RAIN
const RAIN_LIGHT := UiStyle.G_RAIN_LIGHT

var sim: RaceSim
var team_id := ""
var car: CarState  ## primeiro carro do jogador (o pneu "agora" e a troca prevista são dele)
var root: Control
var _body: VBoxContainer
var _content: VBoxContainer
var _timer: Timer


static func open(p_sim: RaceSim, p_team: String, parent: Control) -> WeatherSheet:
	var ws := WeatherSheet.new()
	ws.sim = p_sim
	ws.team_id = p_team
	for c in p_sim.cars:
		if c.is_player and not c.retired and not c.finished:
			ws.car = c
			break
	if ws.car == null and not p_sim.cars.is_empty():
		ws.car = p_sim.cars[0]
	var team: Dictionary = ws.car.team if ws.car != null else {}
	var sh := ScreenKit.sheet("Clima", 1000, UiStyle.team_accent(team) if not team.is_empty() else Color(0, 0, 0, 0))
	ws.root = sh["root"]
	ws._body = sh["body"]
	ws._body.add_child(UiStyle.g_caption("Previsão da sua equipe"))
	ws._content = VBoxContainer.new()
	ws._content.add_theme_constant_override("separation", UiStyle.SP_M)
	ws._body.add_child(ws._content)
	ws._timer = Timer.new()
	ws._timer.wait_time = 1.0
	ws._timer.autostart = true
	ws._timer.timeout.connect(ws.refresh)
	ws.root.add_child(ws._timer)
	ws.root.set_meta("weather_sheet", ws)  # mantém o objeto vivo enquanto a folha existe
	parent.add_child(ws.root)
	ws.refresh()
	return ws


func refresh() -> void:
	if not is_instance_valid(root) or sim == null:
		return
	var fc := sim.forecast_of(team_id)
	for c in _content.get_children():
		c.queue_free()
	var lap_t := sim.track.base_lap_time_s
	var now := sim.time_s
	var lap_now := _current_lap()
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", UiStyle.SP_M)
	top.add_child(_engineer_box(fc, now, lap_t, lap_now))
	top.add_child(_now_box())
	_content.add_child(top)
	if fc != null:
		_content.add_child(_timeline(fc, now, lap_t, lap_now))
		_content.add_child(_switch_box(fc, now, lap_t, lap_now))


func _current_lap() -> int:
	return (car.laps_done + 1) if car != null else 1


# --- recado do engenheiro -----------------------------------------------------------------------

func _engineer_box(fc: TeamForecast, now: float, lap_t: float, lap_now: int) -> Control:
	var card := ScreenKit.g_card(Color(1, 1, 1, 0.05), 18, 16, 14)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_stretch_ratio = 1.35
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UiStyle.SP_M)
	card.add_child(h)
	var accent := UiStyle.team_accent(car.team) if car != null else UiStyle.RED
	var av := PanelContainer.new()
	av.add_theme_stylebox_override("panel", UiStyle.g_box(accent, 28, 0, 0))
	av.custom_minimum_size = Vector2(56, 56)
	av.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var ic := ScreenKit.icon("headset", 28, UiStyle.ink_on(accent))
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	av.add_child(ic)
	h.add_child(av)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var eng := _engineer_name()
	v.add_child(UiStyle.g_caption(eng + " · engenheiro de corrida" if eng != "" else "Engenharia de pista"))
	var msg := "Sem previsão da equipe."
	var conf := 0.5
	if fc != null:
		var win := fc.window(now, lap_t, HORIZON)
		conf = float(win["confidence"])
		msg = _message(win, lap_now)
	var q := UiStyle.g_label(msg, 20, UiStyle.G_TEXT, "black")
	q.set_meta("keep_case", true)
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	q.custom_minimum_size = Vector2(420, 0)
	v.add_child(q)
	v.add_child(_confidence_row(conf))
	return card


func _engineer_name() -> String:
	if car == null:
		return ""
	var sk: Dictionary = (car.team.get("practice_skills", {}) as Dictionary).get(car.driver["id"], {})
	if sk.is_empty():
		var ids: Array = [String(car.driver["id"])]
		sk = Personnel.practice_skills_for(null, String(car.team["id"]), ids).get(car.driver["id"], {})
	return String(sk.get("engineer_name", ""))


func _message(win: Dictionary, lap_now: int) -> String:
	var raining := sim.weather.rain_now() > WeatherModel.RAIN_THRESHOLD
	var start := int(win["start"])
	if start < 0:
		if raining:
			return "\"Está chovendo, mas achamos que para logo. Nada forte nas próximas %d voltas.\"" % HORIZON
		return "\"Não esperamos chuva nas próximas %d voltas.\"" % HORIZON
	var a := lap_now + start
	var b := lap_now + int(win["end"])
	var kind := _intensity_word(float(win["intensity"]))
	if start == 0:
		return "\"%s agora. Deve continuar até a volta %d, mais ou menos.\"" % [_cap(kind), b]
	if a == b:
		return "\"%s deve chegar por volta da volta %d.\"" % [_cap(kind), a]
	return "\"%s deve chegar entre as voltas %d e %d.\"" % [_cap(kind), a, b]


static func _cap(t: String) -> String:
	return t.left(1).to_upper() + t.substr(1)


static func _intensity_word(i: float) -> String:
	if i < 0.3:
		return "garoa"
	if i < 0.65:
		return "chuva"
	return "chuva forte"


func _confidence_row(conf: float) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	var filled := clampi(roundi(conf * 5.0), 1, 5)
	for k in 5:
		var seg := ColorRect.new()
		seg.custom_minimum_size = Vector2(22, 8)
		seg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		seg.color = UiStyle.G_DIRECTOR if k < filled else Color(1, 1, 1, 0.14)
		h.add_child(seg)
	var l := UiStyle.g_label("  confiança %d%%" % roundi(conf * 100.0), 13, UiStyle.G_DIRECTOR, "black")
	h.add_child(l)
	return h


# --- pista e pneu agora --------------------------------------------------------------------------

func _now_box() -> Control:
	var card := ScreenKit.g_card(Color(1, 1, 1, 0.05), 18, 16, 14)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	v.add_child(UiStyle.g_caption("Pista e pneu agora"))
	var w := sim.weather.wetness
	var best := sim.tyres.best_for_wetness(w)
	if sim.tyres.is_dry(best) and car != null:
		best = car.tyre if sim.tyres.is_dry(car.tyre) else sim.tyres.dry_compounds()[0]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(_badge(best, 46))
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", -4)
	tv.add_child(UiStyle.g_label(sim.weather.surface_label().to_upper(), 30, UiStyle.G_TEXT, "black"))
	var kind := "slick" if sim.tyres.is_dry(best) else String(sim.tyres.compounds[best]["name"]).to_lower()
	tv.add_child(UiStyle.g_label("%s é o mais rápido" % kind, 13, UiStyle.G_TEXT_2, "bold"))
	row.add_child(tv)
	v.add_child(row)
	v.add_child(_WetMeter.new(w))
	var lbl := HBoxContainer.new()
	for t: String in ["seca", "úmida", "molhada", "encharcada"]:
		var l := UiStyle.g_label(t, 12, UiStyle.G_TEXT_3, "bold")
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_child(l)
	v.add_child(lbl)
	return card


func _badge(compound: String, px: int) -> Control:
	var c: Dictionary = sim.tyres.compounds[compound]
	var tb := TyreBadge.new()
	tb.custom_minimum_size = Vector2(px, px)
	tb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tb.set_compound(String(c["letter"]), Color(c["color"]))
	return tb


# --- linha do tempo -------------------------------------------------------------------------------

func _timeline(fc: TeamForecast, now: float, lap_t: float, lap_now: int) -> Control:
	var card := ScreenKit.g_card(Color(1, 1, 1, 0.05), 18, 16, 12)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)
	var head := HBoxContainer.new()
	var cap := UiStyle.g_caption("Próximas voltas · chance de chuva")
	cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(cap)
	head.add_child(UiStyle.g_label("▭ janela prevista", 13, RAIN_LIGHT, "black"))
	v.add_child(head)
	var laps := fc.by_lap(now, lap_t, HORIZON)
	var win := fc.window(now, lap_t, HORIZON)
	var total := sim.total_laps
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for e: Dictionary in laps:
		var lap := lap_now + int(e["lap"])
		if lap > total:
			break
		var inside := int(win["start"]) >= 0 and int(e["lap"]) >= int(win["start"]) and int(e["lap"]) <= int(win["end"])
		row.add_child(_lap_column(lap, float(e["chance"]), float(e["intensity"]), inside))
	v.add_child(row)
	return card


func _lap_column(lap: int, chance: float, inten: float, inside: bool) -> Control:
	var col := PanelContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st := UiStyle.g_box(Color(RAIN_BLUE, 0.12) if inside else Color(0, 0, 0, 0), 10, 2, 4)
	if inside:
		st.set_border_width_all(2)
		st.border_color = Color(RAIN_LIGHT, 0.5)
	col.add_theme_stylebox_override("panel", st)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(v)
	var icon := "sun"
	if chance >= 0.2:
		icon = "cloud"
	if chance >= 0.4:
		icon = "drizzle" if inten < 0.3 else ("rain" if inten < 0.65 else "storm")
	var ic := ScreenKit.icon(icon, 22, RAIN_LIGHT if chance >= 0.2 else UiStyle.G_SUN)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ic)
	var bar_box := Control.new()
	bar_box.custom_minimum_size = Vector2(0, BAR_MAX)
	var bar := Panel.new()
	bar.add_theme_stylebox_override("panel", UiStyle.g_box(Color(RAIN_BLUE, 0.35 + chance * 0.65), 6, 0, 0))
	bar_box.add_child(bar)
	bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	bar.offset_left = -11
	bar.offset_right = 11
	bar.offset_top = -maxf(4.0, chance * BAR_MAX)
	v.add_child(bar_box)
	var p := UiStyle.g_label("%d%%" % roundi(chance * 100.0), 12, RAIN_LIGHT, "black")
	p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(p)
	var n := UiStyle.g_label(str(lap), 12, UiStyle.G_TEXT_3, "bold")
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(n)
	return col


# --- troca prevista -------------------------------------------------------------------------------

func _switch_box(fc: TeamForecast, now: float, lap_t: float, lap_now: int) -> Control:
	var card := ScreenKit.g_card(Color(1, 1, 1, 0.05), 18, 16, 12)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	card.add_child(h)
	var tyre := car.tyre if car != null else "medium"
	var sw := fc.tyre_switch(now, lap_t, sim.tyres, tyre, HORIZON)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if sw.is_empty():
		h.add_child(_badge(tyre, 46))
		v.add_child(UiStyle.g_label("Sem troca de tipo de pneu prevista", 19, UiStyle.G_TEXT, "black"))
		v.add_child(UiStyle.g_label("nas próximas %d voltas, pela previsão da equipe" % HORIZON, 13, UiStyle.G_TEXT_2, "bold"))
	else:
		var comp := String(sw["compound"])
		var lap := lap_now + int(sw["lap"])
		h.add_child(_badge(comp, 46))
		var name := "slick" if sim.tyres.is_dry(comp) else String(sim.tyres.compounds[comp]["name"]).to_lower()
		v.add_child(UiStyle.g_label("%s passa a valer a partir da volta ~%d" % [name, lap], 19, UiStyle.G_TEXT, "black"))
		v.add_child(UiStyle.g_label("se o clima vier como previsto · a equipe avisa pelo rádio", 13, UiStyle.G_TEXT_2, "bold"))
	h.add_child(v)
	return card


## Régua da umidade da pista: degradê de seca a encharcada com o marcador no estado atual.
class _WetMeter:
	extends Control

	var value := 0.0

	func _init(v: float) -> void:
		value = v
		custom_minimum_size = Vector2(0, 26)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var y := 6.0
		var hh := 14.0
		var cols: Array = UiStyle.G_WET_SCALE
		var n := cols.size() - 1
		for i in n:
			var x0 := size.x * i / n
			var x1 := size.x * (i + 1) / n
			draw_polygon(PackedVector2Array([Vector2(x0, y), Vector2(x1, y), Vector2(x1, y + hh), Vector2(x0, y + hh)]),
				PackedColorArray([cols[i], cols[i + 1], cols[i + 1], cols[i]]))
		var kx := clampf(value, 0.0, 1.0) * size.x
		draw_rect(Rect2(kx - 3, 0, 6, 26), Color.WHITE)


## Texto curto do selo do clima na barra do topo: o estado da pista e a opinião da SUA equipe.
static func chip_text(p_sim: RaceSim, p_team: String) -> String:
	var raining := p_sim.weather.rain_now() > WeatherModel.RAIN_THRESHOLD
	var base := p_sim.weather.rain_label().capitalize() if raining else "Pista " + p_sim.weather.surface_label()
	var fc := p_sim.forecast_of(p_team)
	if fc == null:
		return base
	var win := fc.window(p_sim.time_s, p_sim.track.base_lap_time_s, HORIZON)
	if int(win["start"]) < 0:
		return "%s · sem chuva prevista" % base
	if int(win["start"]) == 0:
		return base
	var lap := 1
	for c in p_sim.cars:
		if c.is_player:
			lap = c.laps_done + 1
			break
	return "%s · chuva na v%d" % [base, lap + int(win["start"])]
