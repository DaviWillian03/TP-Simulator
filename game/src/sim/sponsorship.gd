class_name Sponsorship
extends RefCounted
## Patrocínios da campanha — v42, 2026-11-19 (docs/DECISIONS.md, mockup v42-4):
##  - 1 vaga de patrocinador PRINCIPAL e 3 SECUNDÁRIAS (bico, halo, asa dianteira);
##  - no início de cada ano, 3 ofertas por vaga: Garantido (só fixo), Equilibrado e Ousado (fixo menor + bônus por metas);
##  - o fixo é pago a cada corrida; cada meta paga o bônus quando é cumprida (posição no campeonato: no fim do ano).
##    Não cumprir a meta só perde o bônus;
##  - o Marketing da fábrica sobe o valor das ofertas e o número de metas por oferta;
##  - vaga livre na hora da corrida: o diretor comercial assina a oferta equilibrada.
## Contratos valem pela temporada. Marcas FICTÍCIAS (data/sponsors.json). Sem dependência de tela. Valores PROVISÓRIOS.

var base := 2.0  ## patrocínio base por corrida da equipe (US$ mi), a soma das vagas no valor "garantido"
var contracts: Dictionary = {}  ## vaga -> {brand, category, kind, per_race, goals: [{type, target, bonus, paid}], season}
var offers: Dictionary = {}  ## vaga -> [oferta] (geradas quando a vaga fica livre)
var gen: Dictionary = {}  ## vaga -> quantas vezes a vaga já recebeu ofertas (muda as marcas)
var news: Array = []

static var _data: Dictionary = {}

const GOAL_WEIGHT := {"pos": 1.4, "podiums": 1.0, "points": 0.8, "wins": 1.2, "best": 0.8}


static func data() -> Dictionary:
	if _data.is_empty():
		_data = GameData.load_json(GameData.DATA_DIR + "sponsors.json")
	return _data


static func slots() -> Array:
	return data()["slots"]


static func slot(id: String) -> Dictionary:
	for z: Dictionary in slots():
		if z["id"] == id:
			return z
	return {}


## As vagas também são as zonas do carro onde a marca aparece (tela do estúdio).
static func zones() -> Array:
	return slots()


static func zone(id: String) -> Dictionary:
	return slot(id)


static func kind(id: String) -> Dictionary:
	for k: Dictionary in data()["kinds"]:
		if k["id"] == id:
			return k
	return {}


static func calendar_size() -> int:
	return Campaign.calendar().size()


# --- montagem ------------------------------------------------------------------------------------

## Começo da campanha: guarda o patrocínio base da equipe; as vagas ficam livres com 3 ofertas cada.
func setup(camp: Campaign, target_per_race: float) -> void:
	base = maxf(target_per_race, 0.1)
	contracts.clear()
	offers.clear()
	gen.clear()
	news.clear()
	if camp.detail == "essential":
		fill_free(camp)


func free_slots() -> Array[String]:
	var out: Array[String] = []
	for z: Dictionary in slots():
		if not contracts.has(z["id"]):
			out.append(z["id"])
	return out


func free_zones() -> Array[String]:
	return free_slots()


# --- ofertas -------------------------------------------------------------------------------------

## As 3 ofertas da vaga livre (Garantido, Equilibrado, Ousado). Geradas uma vez por vez que a vaga fica livre.
func offers_for(camp: Campaign, slot_id: String) -> Array:
	if contracts.has(slot_id) or slot(slot_id).is_empty():
		return []
	if not offers.has(slot_id) or int((offers[slot_id] as Array)[0].get("season", -1)) != camp.season:
		offers[slot_id] = _make_offers(camp, slot_id)
	return offers[slot_id]


func _make_offers(camp: Campaign, slot_id: String) -> Array:
	var g := int(gen.get(slot_id, 0))
	gen[slot_id] = g + 1
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("spons|%s|%d|%s|%d" % [camp.player_team, camp.season, slot_id, g])
	var used: Array = []
	for c: Dictionary in contracts.values():
		used.append(c["brand"])
	var pool: Array = (data()["brands"] as Array).filter(func(b: Dictionary) -> bool: return not used.has(b["name"]))
	var luck: Array = data()["luck"]
	var market := camp.events.market_multiplier(camp.day) if camp.events != null else 1.0
	var safe := base * float(slot(slot_id)["share"]) * camp.dev.sponsor_mult() * market
	var out: Array = []
	for k: Dictionary in data()["kinds"]:
		var brand: Dictionary = pool.pop_at(rng.randi() % pool.size()) if not pool.is_empty() else {"name": "Marca %d" % out.size(), "category": ""}
		var per_race := snappedf(safe * float(k["fixed_k"]) * rng.randf_range(float(luck[0]), float(luck[1])), 0.05)
		var bonus_pool := safe * calendar_size() * float(k["pool_k"])
		var goals := _goals_for(camp, String(k["id"]), bonus_pool)
		out.append({"key": "%d|%s|%d|%s" % [camp.season, slot_id, g, k["id"]], "season": camp.season, "brand": brand["name"],
			"category": brand.get("category", ""), "kind": k["id"], "kind_name": k["name"], "per_race": maxf(per_race, 0.05),
			"goals": goals, "bonus_total": _sum_bonus(goals)})
	return out


static func _sum_bonus(goals: Array) -> float:
	var t := 0.0
	for g: Dictionary in goals:
		t += float(g["bonus"])
	return t


## Metas da oferta: mais ousadas pagam mais. O alvo vem da força da equipe (posição pela nota do carro).
func _goals_for(camp: Campaign, kind_id: String, pool: float) -> Array:
	if kind_id == "safe" or pool <= 0.0:
		return []
	var r := camp.rating_rank(camp.player_team)
	var bold := kind_id == "bold"
	var pod_exp := float([26, 18, 12, 7, 4, 2, 1, 1, 0, 0, 0, 0][clampi(r, 1, 12) - 1])
	var pts_exp := clampf(46.0 - 4.0 * r, 3.0, 44.0)
	var list: Array = []
	var goal_pos := camp.season_goal()
	list.append({"type": "pos", "target": maxi(1, goal_pos - 2) if bold else goal_pos})
	if bold and r <= 4:
		list.append({"type": "wins", "target": maxi(1, int([12, 5, 2, 1][r - 1]))})
	elif pod_exp >= (1.0 if bold else 2.0):
		list.append({"type": "podiums", "target": maxi(1, roundi(pod_exp * 1.1) + 1) if bold else maxi(1, roundi(pod_exp * 0.7))})
	else:
		list.append({"type": "points", "target": roundi(pts_exp) + 2 if bold else maxi(1, roundi(pts_exp * 0.75))})
	list.append({"type": "best", "target": maxi(1, 2 * r - (6 if bold else 3))})
	list = list.slice(0, camp.dev.goals_per_offer())
	var wsum := 0.0
	for g: Dictionary in list:
		wsum += float(GOAL_WEIGHT[g["type"]])
	for g: Dictionary in list:
		g["bonus"] = maxf(snappedf(pool * float(GOAL_WEIGHT[g["type"]]) / wsum, 0.1), 0.1)
		g["paid"] = false
	return list


static func goal_text(g: Dictionary) -> String:
	var n := int(g["target"])
	match String(g["type"]):
		"pos":
			return "Top %d no campeonato" % n if n > 1 else "Título de construtores"
		"podiums":
			return "%d pódio%s" % [n, "s" if n > 1 else ""]
		"points":
			return "%d chegadas nos pontos" % n
		"wins":
			return "%d vitória%s" % [n, "s" if n > 1 else ""]
		_:
			return "Um resultado no top %d" % n if n > 1 else "Uma vitória"


# --- progresso das metas -----------------------------------------------------------------------------

## Números da temporada da equipe: {podiums, points, wins, best}.
static func season_stats(camp: Campaign) -> Dictionary:
	var out := {"podiums": 0, "points": 0, "wins": 0, "best": 99}
	for h: Dictionary in camp.history:
		var res: Array = h.get("results", [])
		for i in res.size():
			if camp.team_of(String(res[i])) != camp.player_team:
				continue
			if i < 3:
				out["podiums"] = int(out["podiums"]) + 1
			if i < 10:
				out["points"] = int(out["points"]) + 1
			if i == 0:
				out["wins"] = int(out["wins"]) + 1
			out["best"] = mini(int(out["best"]), i + 1)
	return out


## {value, target, frac (0..1), done, text} de uma meta.
static func progress(camp: Campaign, g: Dictionary, stats: Dictionary = {}) -> Dictionary:
	if stats.is_empty():
		stats = season_stats(camp)
	var t := int(g["target"])
	var out := {"target": t, "done": bool(g.get("paid", false))}
	match String(g["type"]):
		"pos":
			var pos := camp.team_position(camp.player_team)
			out["value"] = pos
			if camp.history.is_empty():  # antes da primeira corrida a tabela ainda não diz nada
				out["frac"] = 0.0
				out["text"] = "—"
				out["ahead"] = false
				return out
			out["frac"] = clampf(1.0 - float(pos - t) / 6.0, 0.0, 1.0) if pos > t else 1.0
			out["text"] = "você: %dº" % pos
			out["ahead"] = pos <= t
		"best":
			var b := int(stats["best"])
			out["value"] = b
			out["frac"] = 1.0 if b <= t else clampf(1.0 - float(b - t) / 10.0, 0.0, 0.95)
			out["text"] = "melhor: %dº" % b if b < 99 else "—"
		_:
			var v := int(stats[g["type"]])
			out["value"] = v
			out["frac"] = clampf(float(v) / maxf(t, 1), 0.0, 1.0)
			out["text"] = "%d/%d" % [mini(v, t), t]
	return out


# --- ações ------------------------------------------------------------------------------------------

func accept(camp: Campaign, slot_id: String, key: String) -> Dictionary:
	if contracts.has(slot_id):
		return {"ok": false, "text": "A vaga já tem patrocinador."}
	for o: Dictionary in offers_for(camp, slot_id):
		if o["key"] != key:
			continue
		var goals: Array = (o["goals"] as Array).duplicate(true)
		contracts[slot_id] = {"brand": o["brand"], "category": o["category"], "kind": o["kind"], "per_race": float(o["per_race"]),
			"goals": goals, "season": camp.season}
		offers.erase(slot_id)
		var msg := "%s fecha como patrocinador %s: US$ %s mi por corrida%s." % [o["brand"],
			"principal" if slot_id == "main" else "secundário (%s)" % String(slot(slot_id)["name"]).to_lower(), _money(float(o["per_race"])),
			(" + até US$ %s mi em metas" % _money(float(o["bonus_total"]))) if not goals.is_empty() else ""]
		news.push_front(msg)
		return {"ok": true, "text": msg}
	return {"ok": false, "text": "Oferta indisponível."}


## Diretor comercial: assina a oferta equilibrada de cada vaga livre. Devolve quantas fechou.
func fill_free(camp: Campaign) -> int:
	var n := 0
	for z: String in free_slots():
		var list := offers_for(camp, z)
		var pick := {}
		for o: Dictionary in list:
			if o["kind"] == "balanced":
				pick = o
		if pick.is_empty() and not list.is_empty():
			pick = list[0]
		if not pick.is_empty() and accept(camp, z, String(pick["key"]))["ok"]:
			n += 1
	return n


func auto_fill(camp: Campaign) -> int:
	return fill_free(camp)


## Depois de cada corrida: metas de contagem (pódios, pontos, vitórias, melhor resultado) cumpridas pagam o bônus na hora.
## Devolve o total pago.
func after_race(camp: Campaign) -> float:
	var stats := season_stats(camp)
	var total := 0.0
	for z: String in contracts:
		var c: Dictionary = contracts[z]
		for g: Dictionary in c.get("goals", []):
			if bool(g["paid"]) or g["type"] == "pos":
				continue
			var p := progress(camp, g, stats)
			var met: bool = int(p["value"]) <= int(g["target"]) if g["type"] == "best" else int(p["value"]) >= int(g["target"])
			if met:
				g["paid"] = true
				total += float(g["bonus"])
				news.push_front("%s: meta cumprida (%s) — bônus de US$ %s mi." % [c["brand"], goal_text(g).to_lower(), _money(float(g["bonus"]))])
	return total


## Fim da temporada: paga as metas de posição no campeonato cumpridas. Devolve o total pago.
func settle_goals(camp: Campaign, position: int) -> float:
	var total := 0.0
	for z: String in contracts:
		var c: Dictionary = contracts[z]
		for g: Dictionary in c.get("goals", []):
			if g["type"] != "pos" or bool(g["paid"]):
				continue
			if position <= int(g["target"]):
				g["paid"] = true
				total += float(g["bonus"])
				news.push_front("%s paga o bônus da meta (%s): US$ %s mi." % [c["brand"], goal_text(g).to_lower(), _money(float(g["bonus"]))])
			else:
				news.push_front("%s: meta de %s não cumprida, sem bônus." % [c["brand"], goal_text(g).to_lower()])
	return total


## Resumo do ano: fixo que ainda entra, bônus já ganho e bônus em jogo.
func year_summary(camp: Campaign) -> Dictionary:
	var left := camp.races_left_in_season()
	var fixed := 0.0
	var secured := 0.0
	var stake := 0.0
	var goals := 0
	for c: Dictionary in contracts.values():
		fixed += float(c["per_race"]) * left
		for g: Dictionary in c.get("goals", []):
			goals += 1
			if bool(g["paid"]):
				secured += float(g["bonus"])
			else:
				stake += float(g["bonus"])
	return {"guaranteed": fixed, "secured": secured, "goal": stake, "goal_count": goals, "count": contracts.size()}


func per_race_total() -> float:
	var total := 0.0
	for c: Dictionary in contracts.values():
		total += float(c["per_race"])
	return total


## Para previsões (verba do mês, finanças): vaga livre conta como o valor garantido dela.
func expected_per_race(camp: Campaign) -> float:
	var total := per_race_total()
	for z: String in free_slots():
		total += base * float(slot(z)["share"]) * camp.dev.sponsor_mult()
	return total


## Desde a v42 não há bônus por pódio solto: pódios entram como meta dos contratos.
func bonus_per_podium() -> float:
	return 0.0


## Fim da temporada: todos os contratos terminam; no ano novo cada vaga recebe 3 ofertas.
func expire(_camp: Campaign) -> Array[String]:
	var out: Array[String] = []
	for c: Dictionary in contracts.values():
		out.append(String(c["brand"]))
	if not out.is_empty():
		news.push_front("Contratos de patrocínio encerrados: %s. Novas ofertas para o ano que vem." % ", ".join(out))
	contracts.clear()
	offers.clear()
	return out


static func _money(v: float) -> String:
	return ("%.1f" % v).replace(".", ",")


# --- salvar / carregar -------------------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"v": 42, "base": base, "contracts": contracts, "offers": offers, "gen": gen, "news": news}


static func from_dict(d: Dictionary) -> Sponsorship:
	var s := Sponsorship.new()
	s.news = d.get("news", [])
	if int(d.get("v", 0)) < 42:
		return _migrate(s, d)
	s.base = float(d.get("base", 2.0))
	s.contracts = d.get("contracts", {})
	for z: String in s.contracts:
		var c: Dictionary = s.contracts[z]
		c["per_race"] = float(c["per_race"])
		c["season"] = int(c.get("season", 0))
		for g: Dictionary in c.get("goals", []):
			g["target"] = int(g["target"])
			g["bonus"] = float(g["bonus"])
			g["paid"] = bool(g.get("paid", false))
	s.offers = d.get("offers", {})
	for z: String in s.offers:
		for o: Dictionary in s.offers[z]:
			o["season"] = int(o.get("season", 0))
			o["per_race"] = float(o["per_race"])
			for g: Dictionary in o.get("goals", []):
				g["target"] = int(g["target"])
				g["bonus"] = float(g["bonus"])
	for z: String in d.get("gen", {}):
		s.gen[z] = int(d["gen"][z])
	return s


## Save de antes da v42 (5 zonas): o total por corrida vira o patrocínio base; as marcas antigas viram contratos
## "garantidos" nas vagas novas (o principal fica com a maior), valendo até o fim do ano.
static func _migrate(s: Sponsorship, d: Dictionary) -> Sponsorship:
	var old: Array = (d.get("contracts", {}) as Dictionary).values()
	old.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["per_race"]) > float(b["per_race"]))
	var total := 0.0
	for c: Dictionary in old:
		total += float(c["per_race"])
	s.base = maxf(total, 0.5)
	var i := 0
	var brands: Array = data()["brands"]
	for z: Dictionary in slots():
		if i >= old.size():
			break
		var b: Dictionary = brands[(absi(hash(String(old[i]["brand"]))) + i) % brands.size()]  # marcas fictícias desde a v42
		s.contracts[z["id"]] = {"brand": b["name"], "category": b.get("category", ""), "kind": "safe",
			"per_race": snappedf(total * float(z["share"]), 0.05), "goals": [], "season": 0}
		i += 1
	return s
