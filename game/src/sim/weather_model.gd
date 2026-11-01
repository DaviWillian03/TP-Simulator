class_name WeatherModel
extends RefCounted
## Clima da corrida: chuva ao longo do tempo, umidade da pista, borracha acumulada e a
## previsão do radar (com incerteza que diminui conforme a chuva se aproxima).
##
## A linha do tempo da chuva é sorteada no início (com a semente da corrida), então a mesma
## semente sempre produz o mesmo clima.

const WET_RATE := 1.0 / 300.0  ## chuva forte (1.0) leva ~5 min para encharcar a pista
const DRY_RATE := 1.0 / 600.0  ## sem chuva, uma pista encharcada seca em ~12 min (mais rápido com borracha)
const RUBBER_RATE := 1.0 / 2400.0  ## ~40 min de pista seca para "emborrachar" totalmente
const RUBBER_WASH := 1.0 / 240.0  ## chuva lava a borracha
const RAMP_S := 90.0  ## a chuva aumenta e diminui aos poucos
const RAIN_THRESHOLD := 0.08  ## abaixo disso não conta como chuva

var segments: Array = []  ## [{start_s, end_s, intensity}]
var wetness := 0.0  ## 0 seco · ~0.3 úmido · ~0.6 molhado · 1 encharcado
var rubber := 0.0  ## 0 pista "verde" · 1 pista emborrachada
var time_s := 0.0
var _noise_seed := 0


## options["weather"]: "dry" (sem chuva), "rain" (chuva garantida), um Array de segmentos
## [{start_s, end_s, intensity}] (testes), ou ausente (sorteio pela probabilidade do circuito).
func _init(rain_probability: float, race_duration_s: float, rng: RandomNumberGenerator, options: Dictionary = {}) -> void:
	_noise_seed = rng.randi()
	var w: Variant = options.get("weather", "random")
	if w is Array:
		segments = w
	elif w == "dry":
		segments = []
	else:
		var rains: bool = w == "rain" or rng.randf() < rain_probability
		if rains:
			var events := 1 if rng.randf() < 0.7 else 2
			for i in events:
				var start := rng.randf_range(0.1, 0.75) * race_duration_s
				var length := rng.randf_range(0.12, 0.35) * race_duration_s
				segments.append({"start_s": start, "end_s": start + length, "intensity": rng.randf_range(0.3, 1.0)})
	wetness = clampf(float(options.get("start_wetness", 0.0)), 0.0, 1.0)


func intensity_at(t: float) -> float:
	var best := 0.0
	for s: Dictionary in segments:
		var a := float(s["start_s"])
		var b := float(s["end_s"])
		if t < a - RAMP_S or t > b + RAMP_S:
			continue
		var k := 1.0
		if t < a:
			k = 1.0 - (a - t) / RAMP_S
		elif t > b:
			k = 1.0 - (t - b) / RAMP_S
		best = maxf(best, float(s["intensity"]) * clampf(k, 0.0, 1.0))
	return best


func rain_now() -> float:
	return intensity_at(time_s)


## Avança o clima. green = pista em bandeira verde (carros andando forte emborracham e secam).
func step(dt: float, green: bool = true) -> void:
	time_s += dt
	var r := rain_now()
	if r > RAIN_THRESHOLD:
		wetness += dt * r * WET_RATE
		rubber -= dt * r * RUBBER_WASH
	else:
		wetness -= dt * DRY_RATE * (0.8 + 0.4 * rubber) * (1.0 if green else 0.5)
		if green and wetness < 0.1:
			rubber += dt * RUBBER_RATE
	wetness = clampf(wetness, 0.0, 1.0)
	rubber = clampf(rubber, 0.0, 1.0)


## Radar: probabilidade de chuva em janelas de 2 voltas até `horizon` voltas à frente.
## Quanto mais longe a janela, maior o erro (ruído estável por janela, não "pisca").
func forecast(lap_time_s: float, horizon_laps: int = 10) -> Array[float]:
	var out: Array[float] = []
	var h := 2
	while h <= horizon_laps:
		var a := time_s + (h - 2) * lap_time_s
		var b := time_s + h * lap_time_s
		var truth := 0.0
		var t := a
		while t <= b:
			truth = maxf(truth, intensity_at(t))
			t += lap_time_s / 4.0
		var p := 0.08 + 0.84 * clampf(truth / 0.5, 0.0, 1.0)
		var slot := floori(a / lap_time_s / 2.0)
		var noise := _stable_noise(slot) * (0.06 + 0.045 * h)
		out.append(clampf(p + noise, 0.02, 0.98))
		h += 2
	return out


## Primeira janela (em voltas) com chance de chuva >= limite, ou -1.
func laps_until_rain(lap_time_s: float, threshold: float = 0.5) -> int:
	var f := forecast(lap_time_s)
	for i in f.size():
		if f[i] >= threshold:
			return (i + 1) * 2
	return -1


func _stable_noise(slot: int) -> float:
	var x := sin(float(slot) * 12.9898 + float(_noise_seed % 1000) * 78.233) * 43758.5453
	return (x - floorf(x)) * 2.0 - 1.0


func surface_label() -> String:
	if wetness < 0.08:
		return "seco"
	if wetness < 0.35:
		return "úmido"
	if wetness < 0.7:
		return "molhado"
	return "encharcado"


func rain_label() -> String:
	var r := rain_now()
	if r <= RAIN_THRESHOLD:
		return "sem chuva"
	if r < 0.4:
		return "garoa"
	if r < 0.75:
		return "chuva"
	return "chuva forte"
