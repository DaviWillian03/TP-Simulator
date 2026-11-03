class_name CarForm
extends RefCounted
## "Forma do fim de semana": a nota do carro (car_rating) é a força média da equipe, mas em cada GP ela chega um
## pouco melhor ou pior. Três ingredientes, todos determinísticos pela semente do fim de semana:
##  1. variação normal de GP para GP (sigma ~2 pontos);
##  2. afinidade do carro com a pista (fixa para equipe + circuito: algumas pistas "servem" a certos carros);
##  3. de vez em quando (20%) um fim de semana muito bom ou muito ruim (+-2,5 a 5 pontos).
## Resultado típico: o carro do meio do pelotão às vezes briga com os de frente e o de frente às vezes sofre,
## como na temporada de 2012. Os pontos entram na `car_rating` de uma cópia da equipe (a original não muda).
## Valores PROVISÓRIOS (calibrados com tools/balance_report.gd).

const WEEKEND_SIGMA := 2.0
const AFFINITY_SIGMA := 1.4
const SPIKE_CHANCE := 0.2
const SPIKE_RANGE := Vector2(2.5, 5.0)
const MAX_ABS := 7.0


## Pontos de nota que a equipe ganha (ou perde) neste GP. scale = 0 desliga (testes de regra).
static func offset(team_id: String, circuit_id: String, seed_value: int, scale: float = 1.0) -> float:
	if scale <= 0.0:
		return 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("form|%d|%s|%s" % [seed_value, circuit_id, team_id])
	var v := rng.randfn(0.0, WEEKEND_SIGMA)
	if rng.randf() < SPIKE_CHANCE:
		v += (1.0 if rng.randf() < 0.5 else -1.0) * rng.randf_range(SPIKE_RANGE.x, SPIKE_RANGE.y)
	var fit := RandomNumberGenerator.new()
	fit.seed = hash("fit|%s|%s" % [circuit_id, team_id])  # não depende da semente: a pista favorece sempre o mesmo carro
	v += fit.randfn(0.0, AFFINITY_SIGMA)
	return clampf(v * scale, -MAX_ABS, MAX_ABS)


## Cópia das equipes com a forma aplicada em `car_rating` (campo `form` guarda a variação).
static func apply(teams: Array, circuit_id: String, seed_value: int, scale: float = 1.0) -> Array:
	var out: Array = []
	for t: Dictionary in teams:
		var c := t.duplicate()
		var f := offset(String(t["id"]), circuit_id, seed_value, scale)
		c["form"] = f
		c["car_rating"] = float(t["car_rating"]) + f
		out.append(c)
	return out
