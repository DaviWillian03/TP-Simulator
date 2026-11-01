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


func setup(p_sim: RaceSim) -> void:
	sim = p_sim
	custom_minimum_size = Vector2(240, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := UiStyle.outline_box(UiStyle.PAPER, UiStyle.INK)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", style)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	add_child(v)
	var head := HBoxContainer.new()
	head.add_child(UiStyle.label("RADAR", 13, UiStyle.INK, true))
	head.add_child(UiStyle.hspacer())
	head.add_child(UiStyle.caption("Próximas voltas"))
	v.add_child(head)

	var bars := HBoxContainer.new()
	bars.add_theme_constant_override("separation", 6)
	bars.custom_minimum_size = Vector2(0, 62)
	v.add_child(bars)
	for i in BUCKETS:
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 1)
		col.alignment = BoxContainer.ALIGNMENT_END
		var pct := UiStyle.label("", 9, UiStyle.MUTED)
		pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(pct)
		var bar := ColorRect.new()
		bar.color = Color("#1F6FE5")
		bar.custom_minimum_size = Vector2(0, 4)
		col.add_child(bar)
		var lab := UiStyle.label("+%d" % ((i + 1) * 2), 10)
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(lab)
		bars.add_child(col)
		_bars.append(bar)
		_pcts.append(pct)

	_text = UiStyle.label("", 12)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(220, 0)
	v.add_child(_text)
	var wet := HBoxContainer.new()
	wet.add_child(UiStyle.caption("Pista"))
	_wet_bar = ProgressBar.new()
	_wet_bar.show_percentage = false
	_wet_bar.custom_minimum_size = Vector2(70, 7)
	_wet_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wet_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_wet_bar.add_theme_stylebox_override("fill", UiStyle.box(Color("#1F6FE5"), 0, 0))
	wet.add_child(_wet_bar)
	_wet_label = UiStyle.label("", 12, UiStyle.INK, true)
	wet.add_child(_wet_label)
	v.add_child(wet)


func refresh() -> void:
	var lap := sim.track.base_lap_time_s
	var f := sim.weather.forecast(lap, BUCKETS * 2)
	for i in BUCKETS:
		_bars[i].custom_minimum_size = Vector2(0, maxf(3.0, f[i] * 44.0))
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
		_text.text = "Chuva provável em %d–%d voltas (%d%%). A previsão melhora conforme a nuvem chega." % [first * 2, first * 2 + 2, roundi(f[first] * 100.0)]
	else:
		_text.text = "Sem chuva prevista nas próximas %d voltas." % (BUCKETS * 2)
	_wet_bar.value = sim.weather.wetness * 100.0
	_wet_label.text = "%s %d%%" % [sim.weather.surface_label().to_upper(), roundi(sim.weather.wetness * 100.0)]
