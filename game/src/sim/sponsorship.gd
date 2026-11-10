class_name Sponsorship
extends RefCounted
## Patrocínios da campanha (mockup v11-2): 5 zonas do carro com valor, um patrocinador por zona, contrato de
## 1 a 3 anos com valor por corrida e bônus por pódio. As marcas fazem ofertas (que mudam todo mês) conforme a
## influência da equipe; o jogador aceita, recusa ou pede mais (uma vez por oferta, com risco de a marca desistir).
## Marcas reais só como TEXTO (sem logos). Valores PROVISÓRIOS (data/sponsors.json). Sem dependência de tela.

var contracts: Dictionary = {}  ## zona -> {brand, category, tier, per_race, bonus, until, goal_pos, goal_bonus} (goal_pos 0 = garantido)
var asked: Array = []  ## ofertas em que já pediu mais (neste mês)
var withdrawn: Array = []  ## ofertas retiradas pela marca (neste mês)
var boosted: Dictionary = {}  ## chave da oferta -> valor por corrida depois de pedir mais
var period := -1  ## mês (dias/30) a que o estado das ofertas se refere
var news: Array = []

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		_data = GameData.load_json(GameData.DATA_DIR + "sponsors.json")
	return _data


static func zones() -> Array:
	return data()["zones"]


static func zone(id: String) -> Dictionary:
	for z: Dictionary in zones():
		if z["id"] == id:
			return z
	return {}


# --- montagem inicial ----------------------------------------------------------------------------

## Contratos iniciais: nota do carro define quantas zonas e o nível das marcas; o total é escalado para o
## patrocínio base da campanha (mantém o equilíbrio financeiro já existente).
func setup(camp: Campaign, target_per_race: float) -> void:
	contracts.clear()
	asked.clear()
	withdrawn.clear()
	boosted.clear()
	news.clear()
	period = camp.day / 30
	var rating := camp.base_rating
	var count := 5 if rating >= 90.0 else (4 if rating >= 83.0 else 3)
	var tier := clampi(int((rating - 70.0) / 6.0) + 1, 1, 5)
	var raw := 0.0
	var picks: Array = []
	var used: Array = []
	for i in count:
		var z: Dictionary = zones()[i]
		var brand := _pick_brand(tier, "%s|%s|init" % [camp.player_team, z["id"]], used)
		used.append(brand["name"])
		var v := float(data()["tier_base"][tier - 1]) * float(z["mult"])
		raw += v
		picks.append({"zone": z["id"], "brand": brand, "v": v})
	var k := target_per_race / maxf(raw, 0.01)
	for p: Dictionary in picks:
		var brand: Dictionary = p["brand"]
		var per_race := snappedf(float(p["v"]) * k, 0.05)
		contracts[p["zone"]] = {"brand": brand["name"], "category": brand["category"], "tier": tier, "per_race": maxf(per_race, 0.05),
			"bonus": snappedf(per_race * 0.2, 0.05), "until": camp.season + (absi(hash(brand["name"])) % 3)}


func _pick_brand(tier: int, key: String, exclude: Array) -> Dictionary:
	var pool: Array = []
	for b: Dictionary in data()["brands"]:
		if int(b["tier"]) == tier and not exclude.has(b["name"]):
			pool.append(b)
	if pool.is_empty():
		for b: Dictionary in data()["brands"]:
			if not exclude.has(b["name"]):
				pool.append(b)
	return pool[absi(hash(key)) % pool.size()]


# --- consultas ---------------------------------------------------------------------------------------

func per_race_total() -> float:
	var total := 0.0
	for z: String in contracts:
		total += float(contracts[z]["per_race"])
	return total


## Bônus pago por piloto no pódio (soma dos contratos).
func bonus_per_podium() -> float:
	var total := 0.0
	for z: String in contracts:
		total += float(contracts[z]["bonus"])
	return total


func free_zones() -> Array[String]:
	var out: Array[String] = []
	for z: Dictionary in zones():
		if not contracts.has(z["id"]):
			out.append(z["id"])
	return out


func _sync(camp: Campaign) -> void:
	var p := camp.day / 30
	if p != period:
		period = p
		asked.clear()
		withdrawn.clear()
		boosted.clear()


## Ofertas do mês para uma zona livre: {key, brand, category, tier, per_race, bonus, years, asked}.
func offers_for(camp: Campaign, zone_id: String) -> Array[Dictionary]:
	_sync(camp)
	var out: Array[Dictionary] = []
	if contracts.has(zone_id):
		return out
	var z := zone(zone_id)
	var influence := camp.dev.influence()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d|%s|%d" % [camp.season, zone_id, period])
	var tiers := [influence, maxi(1, influence - 1), maxi(1, influence - 2)]
	var used: Array = []
	for c: Dictionary in contracts.values():
		used.append(c["brand"])
	for t in tiers:
		var brand := _pick_brand(t, "%d|%s|%d|%d" % [camp.season, zone_id, period, out.size()], used)
		used.append(brand["name"])
		var key := "%d|%s|%s" % [period, zone_id, brand["name"]]
		if withdrawn.has(key):
			continue
		var luck := rng.randf_range(0.9, 1.15)
		var per_race := snappedf(float(data()["tier_base"][int(brand["tier"]) - 1]) * float(z["mult"]) * luck * camp.dev.sponsor_mult() * camp.events.market_multiplier(camp.day), 0.05)
		if boosted.has(key):
			per_race = float(boosted[key])
		var frac: float = data()["podium_bonus_options"][rng.randi() % data()["podium_bonus_options"].size()]
		var season_total := per_race * calendar_size()
		out.append({"key": key, "goal_per_race": maxf(snappedf(per_race * GOAL_SHARE, 0.05), 0.05), "goal_bonus": snappedf(season_total * GOAL_BONUS_K, 0.5),
			"goal_pos": maxi(1, camp.season_goal()), "brand": brand["name"], "category": brand["category"], "tier": int(brand["tier"]),
			"per_race": maxf(per_race, 0.05), "bonus": snappedf(per_race * frac, 0.05), "years": 1 + rng.randi() % 3, "asked": asked.has(key)})
	return out


## Contratos por meta: o valor por corrida é menor, mas ao fim do ano paga um bônus se a equipe terminar entre os N primeiros.
const GOAL_SHARE := 0.6  ## valor por corrida do contrato por meta = 60% do garantido
const GOAL_BONUS_K := 1.0  ## bônus da meta = o total anual do garantido (cumprida a meta: 160% do garantido)


static func calendar_size() -> int:
	return Campaign.calendar().size()


## Fim da temporada: paga o bônus dos contratos por meta cumpridos (posição final nos construtores). Devolve o total pago.
func settle_goals(camp: Campaign, position: int) -> float:
	var total := 0.0
	for z: String in contracts:
		var c: Dictionary = contracts[z]
		var pos := int(c.get("goal_pos", 0))
		if pos <= 0:
			continue
		if position <= pos:
			total += float(c.get("goal_bonus", 0.0))
			news.push_front("%s paga o bônus da meta (top %d): US$ %s mi." % [c["brand"], pos, ("%.1f" % float(c["goal_bonus"])).replace(".", ",")])
		else:
			news.push_front("%s: meta de top %d não cumprida, sem bônus." % [c["brand"], pos])
	return total


## Resumo para a tela de Receitas: garantido x meta (no ano), e quantos contratos dependem do campeonato.
func year_summary(camp: Campaign) -> Dictionary:
	var left := camp.races_left_in_season()
	var guaranteed := 0.0
	var goal_total := 0.0
	var goals := 0
	for z: String in contracts:
		var c: Dictionary = contracts[z]
		guaranteed += float(c["per_race"]) * left
		if int(c.get("goal_pos", 0)) > 0:
			goal_total += float(c.get("goal_bonus", 0.0))
			goals += 1
	return {"guaranteed": guaranteed, "goal": goal_total, "goal_count": goals, "count": contracts.size()}


# --- ações ------------------------------------------------------------------------------------------

func accept(camp: Campaign, zone_id: String, key: String, mode: String = "safe") -> Dictionary:
	if contracts.has(zone_id):
		return {"ok": false, "text": "A zona já tem patrocinador."}
	for o: Dictionary in offers_for(camp, zone_id):
		if o["key"] == key:
			var goal := mode == "goal"
			contracts[zone_id] = {"brand": o["brand"], "category": o["category"], "tier": o["tier"], "per_race": o["goal_per_race"] if goal else o["per_race"],
				"bonus": o["bonus"], "until": camp.season + int(o["years"]) - 1, "goal_pos": int(o["goal_pos"]) if goal else 0, "goal_bonus": float(o["goal_bonus"]) if goal else 0.0}
			var msg := "%s fecha com a %s: US$ %s mi por corrida até %d%s." % [o["brand"], String(zone(zone_id)["name"]).to_lower(), ("%.2f" % float(contracts[zone_id]["per_race"])).replace(".", ","), camp.season + int(o["years"]) - 1,
				(" (meta: top %d)" % int(o["goal_pos"])) if goal else ""]
			news.push_front(msg)
			return {"ok": true, "text": msg}
	return {"ok": false, "text": "Oferta indisponível."}


## Modo Essencial: o diretor comercial fecha a melhor oferta (valor por corrida) de cada zona livre. Devolve quantas fechou.
func auto_fill(camp: Campaign) -> int:
	var n := 0
	for z: String in free_zones():
		var best := {}
		for o: Dictionary in offers_for(camp, z):
			if best.is_empty() or float(o["per_race"]) > float(best["per_race"]):
				best = o
		if not best.is_empty() and accept(camp, z, String(best["key"]))["ok"]:
			n += 1
	return n


## Pede mais: com chance (cresce com a influência) a marca sobe o valor; senão retira a oferta.
func ask_more(camp: Campaign, zone_id: String, key: String) -> Dictionary:
	_sync(camp)
	if asked.has(key):
		return {"ok": false, "text": "Você já pediu mais nesta oferta."}
	for o: Dictionary in offers_for(camp, zone_id):
		if o["key"] != key:
			continue
		asked.append(key)
		var chance := float(data()["ask_more_base_chance"]) + float(data()["ask_more_per_influence"]) * camp.dev.influence()
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("%s|%d" % [key, camp.day])
		if rng.randf() < chance:
			boosted[key] = snappedf(float(o["per_race"]) * (1.0 + float(data()["ask_more_gain"])), 0.05)
			return {"ok": true, "text": "%s topou: US$ %s mi por corrida." % [o["brand"], ("%.2f" % float(boosted[key])).replace(".", ",")]}
		withdrawn.append(key)
		return {"ok": false, "text": "%s desistiu da oferta." % o["brand"], "withdrawn": true}
	return {"ok": false, "text": "Oferta indisponível."}


## Rescinde o contrato da zona: paga meia temporada por ano restante. Devolve a multa.
func terminate(camp: Campaign, zone_id: String) -> float:
	if not contracts.has(zone_id):
		return 0.0
	var c: Dictionary = contracts[zone_id]
	var years := maxi(int(c["until"]) - camp.season + 1, 1)
	var fee := snappedf(float(c["per_race"]) * float(data()["terminate_races_per_year"]) * years, 0.1)
	camp.budget_musd -= fee
	camp.record("contracts", fee)
	contracts.erase(zone_id)
	news.push_front("Contrato com %s rescindido (multa US$ %s mi)." % [c["brand"], ("%.1f" % fee).replace(".", ",")])
	return fee


## Fim da temporada: contratos vencidos saem e as zonas ficam livres.
func expire(camp: Campaign) -> Array[String]:
	var out: Array[String] = []
	for z in contracts.keys():
		if int(contracts[z]["until"]) <= camp.season:
			out.append(String(contracts[z]["brand"]))
			news.push_front("Contrato com %s terminou." % contracts[z]["brand"])
			contracts.erase(z)
	return out


# --- salvar / carregar -------------------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"contracts": contracts, "asked": asked, "withdrawn": withdrawn, "boosted": boosted, "period": period, "news": news}


static func from_dict(d: Dictionary) -> Sponsorship:
	var s := Sponsorship.new()
	s.contracts = d.get("contracts", {})
	for z: String in s.contracts:
		s.contracts[z]["per_race"] = float(s.contracts[z]["per_race"])
		s.contracts[z]["bonus"] = float(s.contracts[z]["bonus"])
		s.contracts[z]["until"] = int(s.contracts[z]["until"])
		s.contracts[z]["tier"] = int(s.contracts[z]["tier"])
		s.contracts[z]["goal_pos"] = int(s.contracts[z].get("goal_pos", 0))
		s.contracts[z]["goal_bonus"] = float(s.contracts[z].get("goal_bonus", 0.0))
	s.asked = d.get("asked", [])
	s.withdrawn = d.get("withdrawn", [])
	s.boosted = d.get("boosted", {})
	s.period = int(d.get("period", -1))
	s.news = d.get("news", [])
	return s
