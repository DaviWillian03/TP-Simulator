class_name RaceStrategy
extends RefCounted
## Estratégia montada antes da largada (decisão de 2026-11-08, mockup v22-2): os engenheiros sugerem planos prontos
## (pneu de largada + paradas) e o jogador pode alterar as voltas e os compostos. Na corrida o plano só AVISA — a parada
## acontece quando o jogador confirma no box. Sem tela.
##
## Um plano é {name, desc, stints: [{compound, laps, new}]}; a soma das voltas é o total da corrida.

const LIFE_USE := 0.95  ## os engenheiros planejam o stint até ~95% da vida do pneu antes do penhasco
const MAX_STOPS := 3
const MIN_STINT := 3


## Contexto da corrida para planejar: {total_laps, wear_mult, pit_loss, sprint, pace_k}.
## pace_k = RaceSim.tyre_pace_k_for(duração): a perda de ritmo do pneu cresce nas corridas curtas.
static func context(total_laps: int, wear_mult: float, pit_loss: float, sprint: bool, pace_k := 1.0) -> Dictionary:
	return {"total_laps": total_laps, "wear_mult": wear_mult, "pit_loss": pit_loss, "sprint": sprint, "pace_k": pace_k}


## Vida útil planejada de um composto (voltas), descontando o desgaste de jogo usado.
static func life(tyres: TyreModel, compound: String, ctx: Dictionary, used: bool = false) -> float:
	var l := tyres.expected_life_laps(compound, float(ctx["wear_mult"])) * LIFE_USE
	if used:
		l *= 1.0 - PitStop.USED_SET_WEAR
	return l


## Tempo estimado do plano (s acima do ideal): perda de ritmo de cada stint + o tempo das paradas.
static func cost(tyres: TyreModel, stints: Array, ctx: Dictionary) -> float:
	var total := 0.0
	for st: Dictionary in stints:
		var k: String = st["compound"]
		var w := 0.0 if bool(st.get("new", true)) else PitStop.USED_SET_WEAR
		var per := tyres.wear_per_lap(k) * float(ctx["wear_mult"])
		for i in int(st["laps"]):
			total += tyres.pace_penalty(k, w) * float(ctx.get("pace_k", 1.0))
			w += per
	return total + float(ctx["pit_loss"]) * maxi(stints.size() - 1, 0)


## Marca novo/usado em cada stint pela ordem do estoque ({composto: {new, used}}); devolve false se faltar jogo.
static func assign_sets(stints: Array, stock: Dictionary) -> bool:
	var left := {}
	for k: String in stock:
		left[k] = {"new": int(stock[k]["new"]), "used": int(stock[k]["used"])}
	var ok := true
	for st: Dictionary in stints:
		var s: Dictionary = left.get(st["compound"], {"new": 0, "used": 0})
		if int(s["new"]) > 0:
			s["new"] -= 1
			st["new"] = true
		elif int(s["used"]) > 0:
			s["used"] -= 1
			st["new"] = false
		else:
			st["new"] = true
			ok = false
	return ok


## Divide as voltas entre os stints na proporção da vida de cada pneu (pneu mais duro, stint mais longo).
static func _split(tyres: TyreModel, seq: Array, ctx: Dictionary) -> Array:
	var total := int(ctx["total_laps"])
	var lives: Array = []
	var sum := 0.0
	for k: String in seq:
		var l := life(tyres, k, ctx)
		lives.append(l)
		sum += l
	var stints: Array = []
	var used := 0
	for i in seq.size():
		var laps := total - used if i == seq.size() - 1 else maxi(MIN_STINT, roundi(total * lives[i] / sum))
		stints.append({"compound": seq[i], "laps": laps, "new": true})
		used += laps
	return stints


## O plano cabe na vida dos pneus e cumpre a regra dos compostos (na sprint não há regra)?
static func feasible(tyres: TyreModel, stints: Array, ctx: Dictionary) -> bool:
	var comps := {}
	for st: Dictionary in stints:
		if int(st["laps"]) < 1 or float(st["laps"]) > life(tyres, st["compound"], ctx, not bool(st.get("new", true))) + 1.0:
			return false
		comps[st["compound"]] = true
	return bool(ctx["sprint"]) or comps.size() >= 2


## Os planos prontos dos engenheiros (até 3): o mais rápido, uma alternativa com outro número de paradas e uma aposta
## de largada com macio (quando der).
static func engineer_plans(tyres: TyreModel, ctx: Dictionary, stock: Dictionary) -> Array:
	var cands: Array = []
	var dry := tyres.dry_compounds()
	for stops in range(0 if bool(ctx["sprint"]) else 1, MAX_STOPS + 1):
		for seq: Array in _sequences(dry, stops + 1):
			var stints := _split(tyres, seq, ctx)
			var have := assign_sets(stints, stock)
			if not have or not feasible(tyres, stints, ctx):
				continue
			cands.append({"stints": stints, "cost": cost(tyres, stints, ctx)})
	if cands.is_empty():  # nada cabe: duas paradas com os mais duros, mesmo além da vida (o jogador ajusta)
		var seq: Array = [dry[1], dry[2], dry[1]] if dry.size() >= 3 else [dry[0], dry[0], dry[0]]
		var stints := _split(tyres, seq, ctx)
		assign_sets(stints, stock)
		cands.append({"stints": stints, "cost": cost(tyres, stints, ctx)})
	cands.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["cost"]) < float(b["cost"]))
	var picks: Array = [cands[0]]
	for c: Dictionary in cands:  # outro número de paradas
		if (c["stints"] as Array).size() != (picks[0]["stints"] as Array).size():
			picks.append(c)
			break
	for c: Dictionary in cands:  # aposta: larga de macio
		if picks.size() >= 3:
			break
		if c["stints"][0]["compound"] == "soft" and not picks.has(c):
			picks.append(c)
			break
	for c: Dictionary in cands:
		if picks.size() >= 3:
			break
		if not picks.has(c):
			picks.append(c)
	var best := float(picks[0]["cost"])
	var out: Array = []
	for i in picks.size():
		var p: Dictionary = picks[i]
		var tag := "mais rápida" if i == 0 else "+%d s" % maxi(1, roundi(float(p["cost"]) - best))
		out.append(make(p["stints"], tyres, tag))
	return out


static func make(stints: Array, tyres: TyreModel, tag: String = "") -> Dictionary:
	var stops := stints.size() - 1
	var seq: Array = stints.map(func(st: Dictionary) -> String: return String(tyres.compounds[st["compound"]]["letter"]))
	var name := "Sem parada" if stops == 0 else ("1 parada" if stops == 1 else "%d paradas" % stops)
	return {"name": name, "desc": " → ".join(seq) + (" · " + tag if tag != "" else ""), "stints": stints.duplicate(true)}


static func _sequences(dry: Array, n: int) -> Array:
	var out: Array = [[]]
	for i in n:
		var next: Array = []
		for s: Array in out:
			for k: String in dry:
				var t := s.duplicate()
				t.append(k)
				next.append(t)
		out = next
	return out


# --- edição pelo jogador -------------------------------------------------------------------------

## Muda as voltas de um stint; o seguinte (ou o anterior, no último) compensa para a soma continuar igual ao total.
static func adjust_laps(plan: Dictionary, index: int, delta: int) -> bool:
	var stints: Array = plan["stints"]
	if stints.size() < 2:
		return false
	var other := index + 1 if index < stints.size() - 1 else index - 1
	var a := int(stints[index]["laps"]) + delta
	var b := int(stints[other]["laps"]) - delta
	if a < 1 or b < 1:
		return false
	stints[index]["laps"] = a
	stints[other]["laps"] = b
	return true


## Troca o composto de um stint pelo próximo da lista (toque no pneu).
static func cycle_compound(plan: Dictionary, index: int, tyres: TyreModel, stock: Dictionary) -> void:
	var dry := tyres.dry_compounds()
	var st: Dictionary = plan["stints"][index]
	st["compound"] = dry[(dry.find(st["compound"]) + 1) % dry.size()]
	assign_sets(plan["stints"], stock)


## Aviso do plano ("" = tudo certo).
static func warning(plan: Dictionary, tyres: TyreModel, ctx: Dictionary, stock: Dictionary) -> String:
	var stints: Array = (plan["stints"] as Array).duplicate(true)
	if not assign_sets(stints, stock):
		return "Falta jogo no estoque para este plano"
	var comps := {}
	for st: Dictionary in stints:
		comps[st["compound"]] = true
	if not bool(ctx["sprint"]) and comps.size() < 2:
		return "A regra pede dois compostos secos diferentes"
	for st: Dictionary in stints:
		if float(st["laps"]) > life(tyres, st["compound"], ctx, not bool(st["new"])) + 1.0:
			return "Um stint passa da vida do pneu (%s com %d voltas)" % [tyres.compounds[st["compound"]]["name"], int(st["laps"])]
	for st: Dictionary in stints:
		if not bool(st["new"]):
			return "Algum stint usa jogo usado (pouco jogo novo desse composto)"
	return ""


## Voltas em que o plano prevê as paradas (fim de cada stint, menos o último).
static func stop_laps(plan: Dictionary) -> Array:
	var out: Array = []
	var lap := 0
	var stints: Array = plan["stints"]
	for i in stints.size() - 1:
		lap += int(stints[i]["laps"])
		out.append(lap)
	return out
