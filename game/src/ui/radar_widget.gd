class_name RadarWidget
extends PanelContainer
## Radar de chuva (proposta P3): chance de chuva nas próximas voltas, com incerteza
## que diminui conforme a nuvem se aproxima, e a umidade atual da pista.

const BUCKETS := 5

var sim: RaceSim
var _bars: Array[ColorRect] = []
var _pcts: Array[Label] = []
var _text: Label
var _wet_bar: ProgressBar
var _wet_label: Label
var _embedded := false  ## true = dentro da aba Clima do DADOS (maior, sem moldura própria)


func setup(p_sim: RaceSim, embedded: bool = false) -> void:
	sim = p_sim
	_embedded = embedded
	custom_minimum_size = Vector2(240, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", StyleBoxEmpty.new() if embedded else UiStyle.g_box(Color(0.05, 0.06, 0.08, 0.88), 16, 14, 10))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	add_child(v)
	var head := HBoxContainer.new()
	head.add_child(UiStyle.g_caption("Radar · próximas voltas"))
	v.add_child(head)

	var bars := HBoxContainer.new()
	bars.add_theme_constant_override("separation", 6)
	bars.custom_minimum_size = Vector2(0, 150 if embedded else 62)
	v.add_child(bars)
	for i in BUCKETS:
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 1)
		col.alignment = BoxContainer.ALIGNMENT_END
		var pct := UiStyle.g_label("", 11, UiStyle.G_TEXT_2)
		pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(pct)
		var bar := ColorRect.new()
		bar.color = Color("#5c93ea")
		bar.custom_minimum_size = Vector2(0, 4)
		col.add_child(bar)
		var lab := UiStyle.g_label("+%d" % ((i + 1) * 2), 11, UiStyle.G_TEXT_3)
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(lab)
		bars.add_child(col)
		_bars.append(bar)
		_pcts.append(pct)

	_text = UiStyle.g_label("", 16 if embedded else 13, Color("#c3c9d3"))
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(0 if embedded else 220, 0)
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(_text)
	var wet := HBoxContainer.new()
	wet.add_child(UiStyle.g_caption("Pista"))
	_wet_bar = ProgressBar.new()
	_wet_bar.show_percentage = false
	_wet_bar.custom_minimum_size = Vector2(70, 7)
	_wet_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wet_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_wet_bar.add_theme_stylebox_override("background", UiStyle.g_box(Color(1, 1, 1, 0.12), 4, 0, 0))
	_wet_bar.add_theme_stylebox_override("fill", UiStyle.g_box(Color("#5c93ea"), 4, 0, 0))
	wet.add_child(_wet_bar)
	_wet_label = UiStyle.g_label("", 12, UiStyle.G_TEXT, "black")
	wet.add_child(_wet_label)
	v.add_child(wet)


## Resumo de uma linha para o selo do clima na barra de topo ("Seca · chuva 68% em 8–10 v").
static func chip_text(p_sim: RaceSim) -> String:
	var f := p_sim.weather.forecast(p_sim.track.base_lap_time_s, BUCKETS * 2)
	var rain_now := p_sim.weather.rain_now() > WeatherModel.RAIN_THRESHOLD
	var base := p_sim.weather.rain_label().capitalize() if rain_now else p_sim.weather.surface_label().capitalize()
	if rain_now:
		return base
	for i in f.size():
		if f[i] >= 0.5:
			return "%s · chuva %d%% em %d–%d v" % [base, roundi(f[i] * 100.0), i * 2, i * 2 + 2]
	return "%s · sem chuva prevista" % base


func refresh() -> void:
	var lap := sim.track.base_lap_time_s
	var f := sim.weather.forecast(lap, BUCKETS * 2)
	for i in BUCKETS:
		_bars[i].custom_minimum_size = Vector2(0, maxf(3.0, f[i] * (110.0 if _embedded else 44.0)))
		_pcts[i].text = "%d%%" % roundi(f[i] * 100.0)
	var now := sim.weather.rain_label()
	var first := -1
	for i in f.size():
		if f[i] >= 0.5:
			first = i
			break
	if sim.weather.rain_now() > WeatherModel.RAIN_THRESHOLD:
		var stops := -1
		for i in f.size():
			if f[i] < 0.35:
				stops = i
				break
		_text.text = "%s agora. %s" % [now.capitalize(), "Deve parar em ~%d–%d voltas." % [stops * 2, stops * 2 + 2] if stops >= 0 else "Sem sinal de parar tão cedo."]
	elif first >= 0:
		_text.text = "Chuva provável em %d–%d voltas (%d%%)." % [first * 2, first * 2 + 2, roundi(f[first] * 100.0)]
	else:
		_text.text = "Sem chuva prevista nas próximas %d voltas." % (BUCKETS * 2)
	_wet_bar.value = sim.weather.wetness * 100.0
	_wet_label.text = "%s %d%%" % [sim.weather.surface_label().to_upper(), roundi(sim.weather.wetness * 100.0)]
