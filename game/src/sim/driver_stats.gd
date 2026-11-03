class_name DriverStats
extends RefCounted
## Atributos dos pilotos (0-100): ritmo, classificação, regularidade, ultrapassagem/defesa, chuva e gestão de
## pneus, mais o potencial. Pilotos sem atributos (F2/F3 e agentes livres) usam a nota geral em todos.
## A nota geral (`rating`) é a média ponderada dos atributos (tools/enrich_drivers.py). PROVISÓRIO.

const KEYS := ["pace", "quali", "consistency", "racecraft", "wet", "tyres"]
const NAMES := {"pace": "Ritmo de corrida", "quali": "Classificação", "consistency": "Regularidade", "racecraft": "Ultrapassagem e defesa",
	"wet": "Chuva", "tyres": "Gestão de pneus"}
const WEIGHTS := {"pace": 0.30, "quali": 0.15, "consistency": 0.15, "racecraft": 0.20, "wet": 0.10, "tyres": 0.10}
## Quanto cada ponto de atributo pesa na simulação
const RACECRAFT_K := 0.009  ## s por volta de vantagem por ponto de diferença entre atacante e defensor
const QUALI_K := 0.010  ## s na volta lançada por ponto de (classificação − ritmo)
const WET_K := 0.012  ## fração do tempo perdido na chuva por ponto abaixo de 80
const TYRE_K := 0.004  ## fração do desgaste por ponto abaixo/acima de 75
const AGE_PEAK := 29
const AGE_DECLINE_FROM := 34


static func attr(driver: Dictionary, key: String) -> float:
	var a: Dictionary = driver.get("attrs", {})
	return float(a.get(key, driver.get("rating", 75)))


static func overall(driver: Dictionary) -> float:
	var total := 0.0
	for k: String in KEYS:
		total += attr(driver, k) * float(WEIGHTS[k])
	return total


static func has_attrs(driver: Dictionary) -> bool:
	return driver.has("attrs")


## Idade em anos completos no ano dado (0 se não há data de nascimento).
static func age(driver: Dictionary, year: int) -> int:
	var b: String = driver.get("birth", "")
	return year - int(b.left(4)) if b.length() >= 4 else 0


## Evolução na virada: jovens sobem em direção ao potencial; veteranos acima dos 33 perdem ritmo e reflexo.
## Devolve a variação aplicada à nota geral (para mensagens).
static func evolve(driver: Dictionary, next_year: int, seed_value: int) -> int:
	if not has_attrs(driver):
		return 0
	var years := age(driver, next_year)
	if years <= 0:
		return 0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|%d|%d" % [driver["id"], next_year, seed_value])
	var before := overall(driver)
	var delta := 0
	if years < AGE_PEAK:
		var room := float(driver.get("potential", before)) - before
		delta = clampi(roundi(room * 0.25 + rng.randf_range(-0.5, 1.0)), 0, 4)
	elif years >= AGE_DECLINE_FROM:
		delta = -clampi(roundi((years - AGE_DECLINE_FROM + 1) * 0.5 + rng.randf_range(0.0, 1.0)), 0, 3)
	if delta != 0:
		var a: Dictionary = driver["attrs"]
		for k: String in KEYS:
			var shift := delta
			if delta < 0 and k in ["pace", "quali"]:
				shift = delta - 1 if rng.randf() < 0.5 else delta  # velocidade cai primeiro
			elif delta < 0 and k in ["racecraft", "tyres", "wet"]:
				shift = 0 if rng.randf() < 0.5 else delta  # experiência segura mais
			a[k] = clampi(int(a[k]) + shift, 30, 99)
		driver["rating"] = roundi(overall(driver))
	return delta
