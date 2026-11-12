class_name TyreAllocation
extends RefCounted
## Jogos de pneus de cada piloto no fim de semana (decisão de 2026-11-08, regra real de 2026):
## 13 jogos secos — 8 macios, 3 médios, 2 duros (sprint: 12 = 6/4/2) — mais 5 intermediários e 2 de chuva.
## O treino gasta jogos sozinho (pelos blocos do programa) e devolve 2 depois de cada treino livre; 1 macio novo fica
## guardado para o Q3 (quem chega ao Q3 devolve esse jogo depois da classificação); depois da sprint, devolve o jogo com
## mais voltas. O que sobra vira o estoque da corrida (jogo com 0 volta = novo). Sem tela.

const NORMAL := {"soft": 8, "medium": 3, "hard": 2}
const SPRINT := {"soft": 6, "medium": 4, "hard": 2}
const WET := {"inter": 5, "wet": 2}
const RETURN_AFTER_PRACTICE := 2
const DRY := ["soft", "medium", "hard"]
## Bloco do treino -> compostos preferidos (o primeiro que houver). Aero e mecânico dividem o mesmo jogo.
const PRACTICE_COMPOUND := {"aero": ["hard", "medium"], "mech": ["hard", "medium"], "race": ["medium", "hard"], "quali": ["soft"]}
const SHARE_LAPS := 12  ## um jogo do treino serve a outro bloco enquanto tiver menos voltas que isso

var sets: Dictionary = {}  ## id do piloto -> Array[{id, compound, laps, returned, q3}]


var feeder := false  ## F2/F3: poucos jogos, sem devolução por treino e sem macio do Q3 (categories.json)
var return_after := RETURN_AFTER_PRACTICE


## dry_pair (2012): os dois compostos secos do GP [mais macio, mais duro] — 5 jogos do macio e 6 do duro.
static func make(driver_ids: Array, sprint: bool, cat: String = "F1", dry_pair: Array = []) -> TyreAllocation:
	var a := TyreAllocation.new()
	var r := CategoryRules.of(cat)
	var dry: Dictionary = r["dry_sprint"] if sprint and r.has("dry_sprint") else r["dry"]
	if dry_pair.size() == 2:
		dry = {String(dry_pair[0]): 5, String(dry_pair[1]): 6}
	var wet: Dictionary = r["wet"]
	a.feeder = CategoryRules.is_feeder(cat)
	a.return_after = int(r.get("return_after_practice", RETURN_AFTER_PRACTICE))
	for did: String in driver_ids:
		var list: Array = []
		for k: String in ["soft", "medium", "hard", "inter", "wet"]:
			for i in int(dry.get(k, wet.get(k, 0))):
				list.append({"id": list.size(), "compound": k, "laps": 0, "returned": false, "q3": false})
		if bool(r.get("q3_reserve", false)):
			_keep_one_q3(list)  # o último macio fica guardado para o Q3
		a.sets[did] = list
	return a


static func _keep_one_q3(list: Array) -> void:
	var first := true
	for i in range(list.size() - 1, -1, -1):
		var s: Dictionary = list[i]
		if s["compound"] == "soft":
			s["q3"] = first
			first = false


## Jogos ainda com a equipe (não devolvidos). q3_open: o macio do Q3 já pode ser usado.
func available(did: String, q3_open: bool = false) -> Array:
	return (sets.get(did, []) as Array).filter(func(s: Dictionary) -> bool:
		return not s["returned"] and (q3_open or not s["q3"]))


func get_set(did: String, set_id: int) -> Dictionary:
	for s: Dictionary in sets.get(did, []):
		if int(s["id"]) == set_id:
			return s
	return {}


## Contagem por composto: {composto: [disponíveis, entregues no fim de semana]}.
func summary(did: String) -> Dictionary:
	var out := {}
	for s: Dictionary in sets.get(did, []):
		var k: String = s["compound"]
		if not out.has(k):
			out[k] = [0, 0]
		out[k][1] += 1
		if not s["returned"]:
			out[k][0] += 1
	return out


func returned_count(did: String) -> int:
	return (sets.get(did, []) as Array).filter(func(s: Dictionary) -> bool: return s["returned"]).size()


# --- treino --------------------------------------------------------------------------------------

## Jogos que o treino não pode gastar: o macio do Q3 e o último jogo novo de médio e de duro (para a corrida).
func _reserved_for_race(did: String, s: Dictionary) -> bool:
	if s["q3"]:
		return true
	if int(s["laps"]) > 0 or not (s["compound"] in ["medium", "hard"]):
		return false
	var fresh := available(did).filter(func(x: Dictionary) -> bool: return x["compound"] == s["compound"] and int(x["laps"]) == 0)
	return fresh.size() <= 1


## Escolhe o jogo de um bloco do treino: reaproveita um jogo do mesmo composto com poucas voltas (aero e mecânico
## dividem o jogo), senão abre um novo. -1 = nenhum jogo livre (o bloco roda com o que já está no carro).
func pick_for_practice(did: String, block: String, wet: bool = false) -> int:
	var prefs: Array = ["inter", "wet"] if wet else PRACTICE_COMPOUND.get(block, ["medium"])
	var share := block in ["aero", "mech"] or wet
	if feeder:  # F2/F3: o treino inteiro roda num jogo só, do composto mais duro (sobram os outros para a corrida)
		prefs = ["wet"] if wet else ["hard", "medium", "soft"]
		share = true
	for k: String in prefs:
		if share:
			for s: Dictionary in available(did):
				if s["compound"] == k and int(s["laps"]) > 0 and (feeder or int(s["laps"]) < SHARE_LAPS):
					return int(s["id"])
		for s: Dictionary in available(did):
			if s["compound"] == k and int(s["laps"]) == 0 and not _reserved_for_race(did, s):
				return int(s["id"])
	for s: Dictionary in available(did):  # sem jogo novo livre: o usado com menos voltas
		if int(s["laps"]) > 0 and s["compound"] in (["inter", "wet"] if wet else DRY):
			return int(s["id"])
	return -1


func add_laps(did: String, set_id: int, laps: int) -> void:
	var s := get_set(did, set_id)
	if not s.is_empty():
		s["laps"] = int(s["laps"]) + maxi(laps, 0)


## Gasta os jogos de um treino: blocks = [{block, laps, wet}] na ordem em que o piloto rodou.
func consume_practice(did: String, blocks: Array) -> void:
	for b: Dictionary in blocks:
		if int(b.get("laps", 0)) <= 0:
			continue
		var id := pick_for_practice(did, String(b["block"]), bool(b.get("wet", false)))
		add_laps(did, id, int(b["laps"]))


## Fim de cada treino livre: devolve 2 jogos — os mais usados primeiro (nunca o macio do Q3 nem a reserva da corrida).
func return_after_practice(did: String) -> void:
	var cands: Array = available(did).filter(func(s: Dictionary) -> bool:
		return s["compound"] in DRY and not _reserved_for_race(did, s))
	cands.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["laps"]) != int(b["laps"]):
			return int(a["laps"]) > int(b["laps"])
		return a["compound"] == "soft" and b["compound"] != "soft")  # entre novos, devolve macio (há mais)
	for i in mini(return_after, cands.size()):
		cands[i]["returned"] = true


# --- classificação e sprint ---------------------------------------------------------------------

## Quem disputou o Q3 devolve o macio guardado; quem caiu antes fica com ele (novo) para a corrida.
func after_quali(did: String, reached_q3: bool) -> void:
	for s: Dictionary in sets.get(did, []):
		if s["q3"]:
			if reached_q3:
				s["returned"] = true
			s["q3"] = false


## Depois da sprint: os jogos novos gastos viram usados e o jogo com mais voltas na sprint é devolvido.
## stints: [{compound, laps}] na ordem.
func after_sprint(did: String, stints: Array) -> void:
	var best := {}
	for st: Dictionary in stints:
		var k: String = st["compound"]
		var pick := {}
		for s: Dictionary in available(did, true):
			if s["compound"] == k and int(s["laps"]) == 0 and not s["q3"]:
				pick = s
				break
		if pick.is_empty():
			for s: Dictionary in available(did, true):
				if s["compound"] == k:
					pick = s
					break
		if pick.is_empty():
			continue
		pick["laps"] = int(pick["laps"]) + int(st["laps"])
		if best.is_empty() or int(st["laps"]) > int(best["n"]):
			best = {"set": pick, "n": int(st["laps"])}
	if not best.is_empty():
		best["set"]["returned"] = true


## Estoque da corrida no formato do PitStop: {composto: {new, used}}.
func race_stock(did: String, include_q3: bool = true) -> Dictionary:
	var out := {}
	for k: String in ["soft", "medium", "hard", "inter", "wet"]:
		out[k] = {"new": 0, "used": 0}
	for s: Dictionary in available(did, include_q3):
		out[s["compound"]]["new" if int(s["laps"]) == 0 else "used"] += 1
	return out
