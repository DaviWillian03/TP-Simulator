class_name TeamForecast
extends RefCounted
## Previsão do clima de UMA equipe (decisões de 2026-11-13): olha o clima real (WeatherModel) com distorções próprias —
## erra o momento da chuva, a intensidade e às vezes vê uma pancada que não vem. As distorções encolhem quando a chuva
## está perto, e a nota do pessoal (diretor de engenharia de pista + engenheiros de corrida) define o tamanho do erro.
## Nenhuma equipe acerta 100% (chance sempre entre 3% e 95%; confiança no máximo 92%). Erro "entre moderado e alto".
## A IA decide os pneus de chuva por esta previsão — o mesmo nível de informação que o jogador vê na folha de clima.

const NEAR_LAPS := 6.0  ## a partir de ~6 voltas de distância o erro começa a encolher
const MIN_SHRINK := 0.2  ## na volta atual ainda sobra 20% do erro (nunca é perfeita)
const CHANCE_MIN := 0.03
const CHANCE_MAX := 0.95
const CONF_MAX := 0.92
const SAMPLES := 7

var weather: WeatherModel
var skill := 65.0  ## 0..100 (pessoal)
var _s := 0.4  ## habilidade normalizada 0..1
var _bias_laps := 0.0  ## a equipe acha que a chuva vem antes (-) ou depois (+)
var _bias_int := 0.0  ## exagera (+) ou subestima (-) a intensidade
var _phantom_at := -1.0  ## instante (s) de uma pancada que só a equipe vê (-1 = nenhuma)
var _phantom_amp := 0.0
var _phase := 0.0


func _init(p_weather: WeatherModel, p_skill: float, seed_value: int, race_duration_s: float) -> void:
	weather = p_weather
	skill = p_skill
	_s = clampf((p_skill - 50.0) / 40.0, 0.0, 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_bias_laps = rng.randfn(0.0, 1.0) * sigma_laps()
	_bias_int = rng.randfn(0.0, 1.0) * lerpf(0.45, 0.2, _s)
	_phase = rng.randf() * TAU
	if rng.randf() < lerpf(0.55, 0.2, _s):  # alarme falso: equipe fraca vê chuva que não vem com mais frequência
		_phantom_at = rng.randf_range(0.15, 0.85) * race_duration_s
		_phantom_amp = rng.randf_range(0.2, lerpf(0.55, 0.25, _s))


## Desvio típico do erro de "quando chove", em voltas, quando a chuva ainda está longe.
func sigma_laps() -> float:
	return lerpf(9.5, 3.6, _s)


## Nota de previsão de uma equipe: pessoal de pista (diretor 60% + engenheiros 40%). Em temporada extra (2012), quem
## não tem engenheiro com fonte usa a força da equipe no lugar do diretor genérico.
static func skill_for(team: Dictionary, driver_ids: Array) -> float:
	var sk: Dictionary = team.get("practice_skills", {})
	if sk.is_empty():
		sk = Personnel.practice_skills_for(null, String(team.get("id", "")), driver_ids)
	var dir := 0.0
	var eng := 0.0
	var n := 0
	for did: String in sk:
		dir = maxf(dir, float(sk[did].get("director", 60)))
		eng += float(sk[did].get("engineer", 60))
		n += 1
	if n == 0:
		return 62.0
	if Season.active != Season.DEFAULT:  # 2012: diretor pela força do carro (78..90 → 55..85)
		dir = lerpf(55.0, 85.0, clampf((float(team.get("car_rating", 84)) - 78.0) / 12.0, 0.0, 1.0))
	return dir * 0.6 + (eng / n) * 0.4


## Intensidade de chuva que a equipe acha que vai haver no instante t (visto do instante now).
func perceived_at(t: float, now: float, lap_time: float) -> float:
	var dist_laps := maxf(0.0, (t - now) / maxf(lap_time, 1.0))
	var shrink := clampf(dist_laps / NEAR_LAPS, MIN_SHRINK, 1.0)
	var wobble := 0.75 + 0.25 * sin(now / 240.0 + _phase)  # a opinião muda um pouco ao longo da corrida
	var shift := _bias_laps * shrink * wobble * lap_time
	var v := weather.intensity_at(t - shift) * (1.0 + _bias_int * shrink)
	if _phantom_at >= 0.0:
		var d := absf(t - _phantom_at) / (lap_time * 2.5)
		if d < 1.0:
			v = maxf(v, _phantom_amp * (1.0 - d) * shrink)  # some quando chega perto: era alarme falso
	return clampf(v, 0.0, 1.5)


## Previsão volta a volta: [{lap, chance, intensity}] para as próximas `horizon` voltas (lap = deslocamento a partir
## da volta atual: 0 = agora). chance 0..1 (nunca 0 nem 1), intensity = média do que se espera se chover.
func by_lap(now: float, lap_time: float, horizon: int = 12) -> Array:
	var out: Array = []
	for k in horizon:
		var t := now + (k + 0.5) * lap_time
		var dist := k + 0.5
		var u := sigma_laps() * clampf(dist / NEAR_LAPS, MIN_SHRINK, 1.0) * 0.5 * lap_time  # incerteza da janela
		var wet := 0
		var sum := 0.0
		for i in SAMPLES:
			var v := perceived_at(t + u * (float(i) / (SAMPLES - 1) * 2.0 - 1.0), now, lap_time)
			if v > WeatherModel.RAIN_THRESHOLD:
				wet += 1
				sum += v
		var chance := clampf(float(wet) / SAMPLES, CHANCE_MIN, CHANCE_MAX)
		out.append({"lap": k, "chance": chance, "intensity": sum / wet if wet > 0 else 0.0})
	return out


## Janela de chuva prevista: {start, end, confidence, intensity} em voltas a partir de agora (start = -1: sem chuva
## prevista no horizonte). A confiança depende do pessoal e da distância, e nunca chega a 100%.
func window(now: float, lap_time: float, horizon: int = 12, threshold: float = 0.4) -> Dictionary:
	var laps := by_lap(now, lap_time, horizon)
	var start := -1
	var end := -1
	var peak := 0.0
	var inten := 0.0
	for e: Dictionary in laps:
		if float(e["chance"]) >= threshold:
			if start < 0:
				start = int(e["lap"])
			end = int(e["lap"])
			peak = maxf(peak, float(e["chance"]))
			inten = maxf(inten, float(e["intensity"]))
		elif start >= 0:
			break
	if start < 0:
		return {"start": -1, "end": -1, "confidence": confidence(horizon), "intensity": 0.0, "peak": 0.0}
	return {"start": start, "end": end, "confidence": confidence(start), "intensity": inten, "peak": peak}


## Confiança na previsão de algo a `dist_laps` voltas: cresce com o pessoal e quando o evento se aproxima.
func confidence(dist_laps: float) -> float:
	var base := lerpf(0.4, 0.82, _s)
	return clampf(base - dist_laps * lerpf(0.035, 0.02, _s), 0.2, CONF_MAX)


## O que a equipe espera da chuva nas próximas `laps` voltas (média da intensidade percebida) — usado pela IA.
func expected_rain(now: float, lap_time: float, laps: float = 1.5) -> float:
	var sum := 0.0
	for i in 4:
		sum += perceived_at(now + lap_time * laps * (i + 1) / 4.0, now, lap_time)
	return sum / 4.0
