class_name RaceMeta
extends RefCounted
## Sorteio interno de cada etapa da F1 (pedido do usuário, 2026-11-14). Nada disso aparece na tela, e nem o jogador nem a
## IA sabem o resultado: descobrem na pista.
##
## PNEUS: o "meta" de paradas da corrida principal. Na temporada (campanha e Mundial) as etapas são repartidas
## exatamente: 20% três paradas, 35% duas e 45% uma, embaralhadas entre as pistas (Silverstone pode ser 1 parada num
## ano e 3 no outro). No Grande Prêmio avulso cada corrida sorteia com essas chances. O desgaste da corrida é calibrado
## para que a estratégia mais rápida tenha esse número de paradas em qualquer duração (25/50/100%). Os engenheiros
## planejam às cegas, com o desgaste "médio" (de 2 paradas), e todos reagem ao desgaste real durante a corrida.
##
## CARROS: a forma de cada equipe em cada etapa é só sorte em volta da nota do carro (sem resultado real nem afinidade):
## 45% das etapas variação baixa, 35% média, 20% grande (para cima ou para baixo). Na temporada cada equipe tem
## exatamente essa proporção; no GP avulso, as chances.
## Só F1: F2/F3 seguem com CarForm e as regras de pneu da categoria.

const STOP_SHARE := [[3, 0.20], [2, 0.35], [1, 0.45]]
const TIER_SHARE := [["low", 0.45], ["mid", 0.35], ["high", 0.20]]
const NOMINAL_STOPS := 2  ## o plano "padrão às cegas" dos engenheiros
## pontos de nota do carro por faixa (PROVISÓRIO): baixa ~N(0; 0,7); média 1,5–3; grande 3,5–6
const LOW_SIGMA := 0.7
const MID_RANGE := Vector2(1.5, 3.0)
const HIGH_RANGE := Vector2(3.5, 6.0)

static var _wear_cache := {}


# --- sorteio ----------------------------------------------------------------------------------------------

## Temporada inteira: {"stops": {circuito: n}, "car": {circuito: {equipe: pontos}}}, com as proporções exatas.
static func season_draw(circuit_ids: Array, team_ids: Array, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("meta|season|%d" % seed_value)
	var n := circuit_ids.size()
	var stops := _shuffled(_bag(STOP_SHARE, n), rng)
	var out := {"stops": {}, "car": {}}
	for i in n:
		out["stops"][String(circuit_ids[i])] = int(stops[i])
		out["car"][String(circuit_ids[i])] = {}
	for tid: Variant in team_ids:
		var tiers := _shuffled(_bag(TIER_SHARE, n), rng)
		for i in n:
			out["car"][String(circuit_ids[i])][String(tid)] = car_offset(String(tiers[i]), rng)
	return out


## Uma etapa só (Grande Prêmio avulso): {"stops": n, "car": {equipe: pontos}} pelas chances.
static func single_draw(team_ids: Array, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("meta|single|%d" % seed_value)
	var car := {}
	for tid: Variant in team_ids:
		car[String(tid)] = car_offset(String(_pick(TIER_SHARE, rng.randf())), rng)
	return {"stops": int(_pick(STOP_SHARE, rng.randf())), "car": car}


## A etapa de uma temporada sorteada, no formato do GP avulso ({} se a pista não está no sorteio).
static func round_of(draw: Dictionary, circuit_id: String) -> Dictionary:
	if not (draw.get("stops", {}) as Dictionary).has(circuit_id):
		return {}
	return {"stops": int(draw["stops"][circuit_id]), "car": (draw["car"] as Dictionary).get(circuit_id, {})}


static func car_offset(tier: String, rng: RandomNumberGenerator) -> float:
	var sign := 1.0 if rng.randf() < 0.5 else -1.0
	match tier:
		"low":
			return clampf(rng.randfn(0.0, LOW_SIGMA), -1.5, 1.5)
		"mid":
			return sign * rng.randf_range(MID_RANGE.x, MID_RANGE.y)
		_:
			return sign * rng.randf_range(HIGH_RANGE.x, HIGH_RANGE.y)


## Quantidades exatas de cada valor para n etapas (arredonda e o último completa).
static func _bag(share: Array, n: int) -> Array:
	var out: Array = []
	for i in share.size():
		var k := n - out.size() if i == share.size() - 1 else roundi(n * float(share[i][1]))
		for j in maxi(k, 0):
			out.append(share[i][0])
	return out


static func _shuffled(a: Array, rng: RandomNumberGenerator) -> Array:
	var b := a.duplicate()
	for i in range(b.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: Variant = b[i]
		b[i] = b[j]
		b[j] = t
	return b


static func _pick(share: Array, roll: float) -> Variant:
	var acc := 0.0
	for s: Array in share:
		acc += float(s[1])
		if roll < acc:
			return s[0]
	return share[share.size() - 1][0]


# --- pneus: desgaste que faz do meta a estratégia mais rápida ---------------------------------------------

## Fator de desgaste da pista (no lugar de tyre_wear_factor) para que a corrida tenha `stops` paradas como estratégia
## mais rápida nesta duração. Sem efeitos do regulamento (wear_k entra por cima, na corrida).
## 1 parada fica perto da fronteira com 2 (o pneu ainda gasta de verdade); 2 e 3, no meio da faixa.
static func wear_factor(stops: int, track: TrackModel, tyres: TyreModel, duration_pct: float) -> float:
	var key := "f|%s|%.2f|%s|%.1f|%d" % [track.id, duration_pct, ",".join(PackedStringArray(tyres.dry_compounds())), track.pit_lane_loss_s, stops]
	if _wear_cache.has(key):
		return float(_wear_cache[key])
	var b := boundaries(track, tyres, duration_pct)
	var lo: float = b[0] * 0.5 if stops <= 1 else b[mini(stops, 3) - 2]
	var hi: float = b[mini(stops, 3) - 1]
	# dentro da faixa em que o plano mais rápido tem `stops` paradas, prefere onde a IA (que decide pela vida do pneu)
	# também chega a `stops`: assim o meta é o que a pista mostra de verdade
	var total := maxi(3, roundi(track.laps * duration_pct))
	var div := pow(duration_pct, RaceSim.WEAR_SHORT_RACE_EXP)
	var ok: Array = []
	for i in 17:
		var f := lo * pow(hi / lo, (i + 0.5) / 17.0)
		if ai_stops(tyres, total, f / div) == stops:
			ok.append(f)
	var out: float
	if ok.is_empty():
		out = hi * 0.8 if stops <= 1 else sqrt(lo * hi)
	elif stops <= 1:
		out = float(ok[roundi((ok.size() - 1) * 0.8)])  # 1 parada: perto do limite (o pneu ainda gasta de verdade)
	else:
		out = float(ok[ok.size() / 2])
	_wear_cache[key] = out
	return out


## Paradas que a IA planeja pela vida do pneu (StrategyAI._plan_from, sem a aposta): largada de médio, depois o duro.
static func ai_stops(tyres: TyreModel, total: int, mult: float) -> int:
	var dry := tyres.dry_compounds()
	var start: String = "medium" if dry.has("medium") else String(dry[0])
	var life_now := tyres.expected_life_laps(start, mult) * 0.9
	var life_hard := tyres.expected_life_laps(String(dry[dry.size() - 1]), mult)
	var n := 1
	while life_now + life_hard * n < total and n < 6:
		n += 1
	return n


## Fatores em que o plano mais rápido passa de 1→2, 2→3 e 3→4 paradas (cache por pista, duração e compostos).
static func boundaries(track: TrackModel, tyres: TyreModel, duration_pct: float) -> Array:
	var key := "%s|%.2f|%s|%.1f" % [track.id, duration_pct, ",".join(PackedStringArray(tyres.dry_compounds())), track.pit_lane_loss_s]
	if _wear_cache.has(key):
		return _wear_cache[key]
	var total := maxi(3, roundi(track.laps * duration_pct))
	var div := pow(duration_pct, RaceSim.WEAR_SHORT_RACE_EXP)
	var pace_k := RaceSim.tyre_pace_k_for(duration_pct)
	var at := func(f: float) -> int:
		return best_stops(tyres, RaceStrategy.context(total, f / div, track.pit_lane_loss_s, false, pace_k))
	var out: Array = []
	for n in [1, 2, 3]:  # menor fator em que o melhor plano já tem mais que n paradas
		var lo := 0.05 if out.is_empty() else float(out[out.size() - 1])
		var hi := lo * 2.0
		while at.call(hi) <= n and hi < 40.0:
			lo = hi
			hi *= 2.0
		for i in 14:
			var mid := sqrt(lo * hi)
			if at.call(mid) <= n:
				lo = mid
			else:
				hi = mid
		out.append(hi)
	_wear_cache[key] = out
	return out


## Número de paradas do plano mais rápido (estoque à vontade). A ordem dos pneus não muda o custo nem a vida: basta
## testar as combinações de compostos (sem repetir permutações).
static func best_stops(tyres: TyreModel, ctx: Dictionary) -> int:
	var dry := tyres.dry_compounds()
	var best := INF
	var best_n := 99
	for stops in range(1, 5):
		for seq: Array in _combos(dry, stops + 1):
			var stints := RaceStrategy._split(tyres, seq, ctx)
			if not RaceStrategy.feasible(tyres, stints, ctx):
				continue
			var c := RaceStrategy.cost(tyres, stints, ctx)
			if c < best:
				best = c
				best_n = stops
	return best_n


static func _combos(items: Array, n: int, start := 0) -> Array:
	if n == 0:
		return [[]]
	var out: Array = []
	for i in range(start, items.size()):
		for rest: Array in _combos(items, n - 1, i):
			out.append([items[i]] + rest)
	return out


# --- carros ------------------------------------------------------------------------------------------------

## Cópia das equipes com a forma sorteada da etapa na `car_rating` (campo `form` guarda a variação). Na campanha,
## soma também as características do carro × perfil da pista (desenvolvimento do jogador) e a confiabilidade.
## scale = 0 desliga a sorte (testes de regra).
static func apply_car(teams: Array, car: Dictionary, scale: float = 1.0, profile: Dictionary = {}) -> Array:
	var out: Array = []
	for t: Dictionary in teams:
		var c := t.duplicate()
		var f := float(car.get(String(t["id"]), 0.0)) * maxf(scale, 0.0)
		if scale > 0.0 and not profile.is_empty():
			f += CarParts.traits_effect(t, profile)
			var rel := float((t.get("car_traits", {}) as Dictionary).get("rel", CarParts.REL_NEUTRAL))
			c["failure_mult"] = float(t.get("failure_mult", 1.0)) * CarParts.rel_mult(rel)
		c["form"] = f
		c["car_rating"] = float(t["car_rating"]) + f
		out.append(c)
	return out
