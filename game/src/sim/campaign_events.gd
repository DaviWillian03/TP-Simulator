class_name CampaignEvents
extends RefCounted
## Eventos inesperados da campanha (mockup v13-1). Sorteados por dia conforme a frequência escolhida; a CONSEQUÊNCIA É
## AUTOMÁTICA (decisão do usuário) e vira uma notícia. Tipos: pilotos (lesão com reserva, crise de confiança, sondagem),
## calendário (corrida cancelada), equipe/fábrica (incêndio, peças com defeito, patrocinador sai, avanço) e mercado/
## finanças (crise econômica, apoio do país-sede). Tom sóbrio. Valores PROVISÓRIOS (data/events.json). Sem tela.

const CAT_NAMES := {"driver": "PILOTO", "calendar": "CALENDÁRIO", "team": "EQUIPE", "market": "MERCADO"}
const CAT_COLORS := {"driver": Color("#ff6a5a"), "calendar": Color("#ffd24a"), "team": Color("#5c93ea"), "market": Color("#3c9d5d")}
const FREQUENCIES := {"off": "Desligados", "rare": "Raros", "normal": "Normais", "frequent": "Frequentes"}
const MAX_NEWS := 30

var freq := "normal"
var news: Array = []  ## [{day, cat, id, title, text, chips: [{kind, big, small}]}] (mais nova primeiro)
var unseen: Array = []  ## notícias ainda não mostradas no cartão
var injuries: Dictionary = {}  ## id do piloto lesionado -> {rounds_left, sub_id, original, sub_contract_prev}
var moods: Dictionary = {}  ## id do piloto -> {rounds_left, delta: {atributo: valor}}
var principals: Dictionary = {}  ## id da equipe -> chefe novo (troca de dirigentes)
var postponed: Dictionary = {}  ## índice da rodada -> dias de adiamento
var cancelled: Array = []  ## índices do calendário cancelados nesta temporada
var ask_mult: Dictionary = {}  ## id do piloto -> multiplicador do salário pedido até a virada
var market_until := -1
var market_mult := 1.0

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		_data = GameData.load_json(GameData.DATA_DIR + "events.json")
	return _data


static func event_def(id: String) -> Dictionary:
	for e: Dictionary in data()["events"]:
		if e["id"] == id:
			return e
	return {}


func market_multiplier(day: int) -> float:
	return market_mult if day <= market_until else 1.0


# --- sorteio diário --------------------------------------------------------------------------------

func tick_day(camp: Campaign, day: int) -> void:
	var p := float(data()["daily_probability"].get(freq, 0.0))
	if p <= 0.0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d|%d|ev" % [camp.season, day])
	if rng.randf() >= p:
		return
	var pool: Array = []
	var total := 0.0
	for e: Dictionary in data()["events"]:
		if _eligible(camp, e):
			pool.append(e)
			total += float(e["weight"])
	if pool.is_empty():
		return
	var roll := rng.randf() * total
	for e: Dictionary in pool:
		roll -= float(e["weight"])
		if roll <= 0.0:
			_add(camp, _apply(camp, e, rng, day))
			return


## Piloto do jogador sem lesão nem crise em andamento (reservas que estão no carro ficam de fora).
func _free_player_driver(camp: Campaign, need_attrs: bool = false) -> Dictionary:
	var subs: Array = injuries.values().map(func(i: Dictionary) -> String: return i["sub_id"])
	for d: Dictionary in camp.personnel.player_drivers(camp):
		if injuries.has(d["id"]) or moods.has(d["id"]) or subs.has(d["id"]):
			continue
		if need_attrs and not DriverStats.has_attrs(d):
			continue
		return d
	return {}


func _eligible(camp: Campaign, e: Dictionary) -> bool:
	match e["id"]:
		"driver_injury":
			return not _free_player_driver(camp).is_empty() and not _stand_in(camp).is_empty()
		"driver_crisis":
			return not _free_player_driver(camp, true).is_empty()
		"driver_offer":
			for d: Dictionary in camp.personnel.player_drivers(camp):
				if not ask_mult.has(d["id"]):
					return true
			return false
		"race_cancelled":
			return cancelled.size() < 2 and not _cancel_candidates(camp).is_empty()
		"factory_fire", "parts_defect", "breakthrough":
			return not camp.dev.projects.is_empty()
		"sponsor_leaves":
			return camp.sponsors.contracts.size() >= 2
		"economic_crisis":
			return market_until < camp.day
		"race_postponed":
			return not _postpone_candidates(camp).is_empty()
	return true


## Rodadas futuras que podem ser adiadas uma semana sem encostar na seguinte (pelo menos 14 dias de folga).
func _postpone_candidates(camp: Campaign) -> Array[int]:
	var out: Array[int] = []
	var n := Campaign.calendar().size()
	for i in range(camp.round + 2, n - 1):
		if cancelled.has(i) or postponed.has(i):
			continue
		if camp.round_day(i + 1) - camp.round_day(i) >= 14:
			out.append(i)
	return out


## Equipe da IA sorteada.
func _rival(camp: Campaign, rng: RandomNumberGenerator) -> Dictionary:
	var pool := camp.teams().filter(func(t: Dictionary) -> bool: return t["id"] != camp.player_team)
	return pool[rng.randi() % pool.size()]


func _cancel_candidates(camp: Campaign) -> Array[int]:
	var out: Array[int] = []
	var n := Campaign.calendar().size()
	for i in range(camp.round + 1, n):
		if not cancelled.has(i):
			out.append(i)
	return out if out.size() >= 3 else ([] as Array[int])


## Melhor piloto da F2/F3 livre para entrar no lugar de um lesionado (nota mais alta que não esteja em outra equipe).
func _stand_in(camp: Campaign) -> Dictionary:
	var best: Dictionary = {}
	for e in camp.personnel.market(camp, "driver", "feeder"):
		if camp.personnel.pending.has(e["id"]) or camp.personnel.is_mine(camp, e["id"]):
			continue
		if not Personnel.old_enough(e, camp.season):  # reserva também precisa ter 18 anos
			continue
		best = e
		break
	return best


# --- efeitos -----------------------------------------------------------------------------------------

func _chip(kind: String, big: String, small: String) -> Dictionary:
	return {"kind": kind, "big": big, "small": small}


func _money(v: float) -> String:
	return ("%.1f" % v).replace(".", ",")


func _apply(camp: Campaign, e: Dictionary, rng: RandomNumberGenerator, day: int) -> Dictionary:
	var n := {"day": day, "cat": e["cat"], "id": e["id"], "title": "", "text": "", "chips": []}
	match e["id"]:
		"driver_injury":
			var d := _free_player_driver(camp)
			var rounds := rng.randi_range(int(e["rounds"][0]), int(e["rounds"][1]))
			var sub := _stand_in(camp)
			_swap_in(camp, d, sub, rounds)
			n["title"] = "%s SOFRE LESÃO" % String(d["name"]).to_upper()
			n["text"] = "%s se machucou e ficará fora de %d corrida%s. A equipe aciona o reserva %s no carro #%d." % [d["name"], rounds, "" if rounds == 1 else "s", sub["name"], int(d["number"])]
			n["chips"] = [_chip("bad", "%d corrida%s" % [rounds, "" if rounds == 1 else "s"], "fora da pista"), _chip("", String(sub["name"]).get_slice(" ", 1), "reserva no carro (nota %d)" % int(sub["rating"])),
				_chip("good", "sem custo", "o seguro cobre a substituição")]
		"driver_crisis":
			var d2 := _free_player_driver(camp, true)
			var rounds2 := rng.randi_range(int(e["rounds"][0]), int(e["rounds"][1]))
			_apply_mood(d2, rounds2, {"pace": int(e["pace"]), "consistency": int(e["consistency"])})
			n["title"] = "%s ATRAVESSA CRISE DE CONFIANÇA" % String(d2["name"]).to_upper()
			n["text"] = "Após uma sequência de resultados ruins e muita cobrança, %s perde ritmo e regularidade por %d corridas." % [d2["name"], rounds2]
			n["chips"] = [_chip("bad", "%d corridas" % rounds2, "em baixa de confiança"), _chip("bad", "−%d / −%d" % [-int(e["pace"]), -int(e["consistency"])], "ritmo / regularidade")]
		"driver_offer":
			var d3: Dictionary = {}
			for x: Dictionary in camp.personnel.player_drivers(camp):
				if not ask_mult.has(x["id"]):
					d3 = x
					break
			ask_mult[d3["id"]] = float(e["ask_mult"])
			n["title"] = "SONDAGEM DA CONCORRÊNCIA POR %s" % String(d3["name"]).to_upper()
			n["text"] = "%s recebeu uma sondagem de outra equipe. A renovação do contrato ficará 15%% mais cara até o fim da temporada." % d3["name"]
			n["chips"] = [_chip("bad", "+15%", "na renovação")]
		"race_cancelled":
			var cands := _cancel_candidates(camp)
			var idx: int = cands[rng.randi() % cands.size()]
			cancelled.append(idx)
			var gp: String = Campaign.calendar()[idx]["grand_prix"]
			n["title"] = "%s CANCELADO" % gp.to_upper()
			n["text"] = "Por uma crise na região, o %s sai do calendário. A rodada não rende pontos nem patrocínio." % gp
			n["chips"] = [_chip("bad", "−1 rodada", "no calendário"), _chip("", "%d" % (Campaign.calendar().size() - cancelled.size()), "corridas restantes na temporada")]
		"factory_fire":
			for p: Dictionary in camp.dev.projects:
				p["days_left"] = int(p["days_left"]) + int(e["delay_days"])
				p["days_total"] = int(p["days_total"]) + int(e["delay_days"])
			var cost := float(e["cost_musd"])
			camp.budget_musd -= cost
			camp.record("events", cost)
			n["title"] = "INCÊNDIO NA FÁBRICA"
			n["text"] = "Um incêndio num depósito atrasa os projetos em andamento em %d dias e custa US$ %s mi em reparos." % [int(e["delay_days"]), _money(cost)]
			n["chips"] = [_chip("bad", "+%d dias" % int(e["delay_days"]), "nos projetos"), _chip("bad", "US$ %s mi" % _money(cost), "em reparos")]
		"parts_defect":
			var p2: Dictionary = camp.dev.projects[rng.randi() % camp.dev.projects.size()]
			var info := CarDevelopment.node_info(p2["id"])
			camp.dev.projects.erase(p2)
			camp.budget_musd += float(p2["cost"]) * 0.5
			camp.record("rd", -float(p2["cost"]) * 0.5)
			n["title"] = "LOTE DE PEÇAS COM DEFEITO"
			n["text"] = "O projeto “%s” perdeu a produção. Metade do dinheiro volta ao caixa." % info["node"]["n"]
			n["chips"] = [_chip("bad", "projeto perdido", String(info["node"]["n"])), _chip("good", "US$ %s mi" % _money(float(p2["cost"]) * 0.5), "devolvidos")]
		"sponsor_leaves":
			var zones: Array = camp.sponsors.contracts.keys()
			var z: String = zones[rng.randi() % zones.size()]
			var c: Dictionary = camp.sponsors.contracts[z]
			camp.sponsors.contracts.erase(z)
			n["title"] = "%s ENCERRA O PATROCÍNIO" % String(c["brand"]).to_upper()
			n["text"] = "A marca rompe o contrato da zona %s sem multa. A zona fica livre para novas ofertas." % String(Sponsorship.zone(z)["name"]).to_lower()
			n["chips"] = [_chip("bad", "−US$ %s mi" % _money(float(c["per_race"])), "por corrida"), _chip("", "zona livre", String(Sponsorship.zone(z)["name"]))]
		"breakthrough":
			var p3: Dictionary = camp.dev.projects[rng.randi() % camp.dev.projects.size()]
			var info3 := CarDevelopment.node_info(p3["id"])
			p3["days_left"] = mini(int(p3["days_left"]), 1)
			n["title"] = "AVANÇO NO DESENVOLVIMENTO"
			n["text"] = "A equipe técnica encontra uma solução: o projeto “%s” termina na próxima semana." % info3["node"]["n"]
			n["chips"] = [_chip("good", "1 dia", "para concluir"), _chip("", String(info3["node"]["n"]), "projeto adiantado")]
		"economic_crisis":
			market_until = day + int(e["days"])
			market_mult = float(e["mult"])
			n["title"] = "CRISE ECONÔMICA"
			n["text"] = "A economia desacelera: as ofertas de patrocínio valem 15%% menos pelos próximos %d dias." % int(e["days"])
			n["chips"] = [_chip("bad", "−15%", "nas ofertas"), _chip("", "%d dias" % int(e["days"]), "de duração")]
		"rival_factory_fire":
			var t := _rival(camp, rng)
			var cp: CarParts = camp.parts.get(t["id"])
			if cp != null:
				for r: Dictionary in cp.research:
					r["days_left"] = int(r["days_left"]) + int(e["delay_days"])
				for q: Dictionary in cp.queue:
					q["days_left"] = int(q["days_left"]) + int(e["delay_days"])
			n["title"] = "INCÊNDIO NA FÁBRICA DA %s" % String(t["name"]).to_upper()
			n["text"] = "Um incêndio atrasa em %d dias as pesquisas e a produção de peças da %s." % [int(e["delay_days"]), t["name"]]
			n["chips"] = [_chip("good", "+%d dias" % int(e["delay_days"]), "para a rival")]
		"rival_staff_leaves", "rival_sponsor":
			var t2 := _rival(camp, rng)
			var cp2: CarParts = camp.parts.get(t2["id"])
			if cp2 != null:
				cp2.gain_k *= float(e["gain_mult"])
			var bad: bool = e["id"] == "rival_staff_leaves"
			n["title"] = ("%s PERDE UM TÉCNICO-CHAVE" if bad else "%s FECHA PATROCÍNIO GRANDE") % String(t2["name"]).to_upper()
			n["text"] = ("Um engenheiro importante deixa a %s: as peças novas dela devem render menos neste ano." if bad
				else "A %s anuncia um patrocinador novo e acelera o desenvolvimento do carro.") % t2["name"]
			n["chips"] = [_chip("good" if bad else "bad", "%+d%%" % roundi((float(e["gain_mult"]) - 1.0) * 100.0), "no desenvolvimento da rival")]
		"principal_change":
			var t3 := _rival(camp, rng)
			var names: Dictionary = GameData.load_json(GameData.DATA_DIR + "name_pool.json")["nationalities"]
			var nats: Array = names.keys()
			var pool: Dictionary = names[nats[rng.randi() % nats.size()]]
			var new_name := "%s %s" % [pool["first"][rng.randi() % pool["first"].size()], pool["last"][rng.randi() % pool["last"].size()]]
			var old := String(t3.get("principal", "")) if t3.get("principal") != null else ""
			t3["principal"] = new_name
			principals[t3["id"]] = new_name
			n["title"] = "NOVO CHEFE NA %s" % String(t3["name"]).to_upper()
			n["text"] = ("%s deixa o comando da %s; %s assume o cargo." % [old, t3["name"], new_name]) if old != "" else ("%s assume o comando da %s." % [new_name, t3["name"]])
			n["chips"] = [_chip("", new_name, "novo chefe de equipe")]
		"race_postponed":
			var cands := _postpone_candidates(camp)
			var idx: int = cands[rng.randi() % cands.size()]
			postponed[idx] = int(e["days"])
			var gp: String = Campaign.calendar()[idx]["grand_prix"]
			n["title"] = "%s ADIADO" % gp.to_upper()
			n["text"] = "Por problemas de logística, o %s passa para uma semana depois. A data nova já está no calendário." % gp
			n["chips"] = [_chip("", "+%d dias" % int(e["days"]), "na data")]
		"host_support":
			var amount := snappedf(rng.randf_range(float(e["amount"][0]), float(e["amount"][1])), 0.5)
			camp.budget_musd += amount
			camp.record("events_in", amount)
			n["title"] = "APOIO DO PAÍS-SEDE"
			n["text"] = "O governo local reforça o caixa com US$ %s mi em troca de eventos promocionais." % _money(amount)
			n["chips"] = [_chip("good", "+US$ %s mi" % _money(amount), "no caixa")]
	return n


func _add(camp: Campaign, item: Dictionary) -> void:
	news.push_front(item)
	unseen.push_front(item)
	while news.size() > MAX_NEWS:
		news.pop_back()
	camp.refresh_rating()


# --- lesão e crise ---------------------------------------------------------------------------------------

## Troca o piloto lesionado pelo reserva no grid (o original volta quando acabam as corridas de afastamento).
func _swap_in(camp: Campaign, injured: Dictionary, sub_person: Dictionary, rounds: int) -> void:
	var idx := camp._drivers.find(injured)
	var sub := {"id": sub_person["id"], "name": sub_person["name"], "code": Campaign.driver_code(sub_person["name"]), "number": int(injured["number"]),
		"nationality": sub_person["nationality"], "team": camp.player_team, "rating": int(sub_person["rating"]), "from": sub_person.get("category", "F2")}
	camp._drivers[idx] = sub
	var prev: Dictionary = camp.personnel.contracts.get(sub["id"], {}).duplicate()
	camp.personnel.contracts[sub["id"]] = {"team": camp.player_team, "salary": Personnel.driver_ask(float(sub["rating"])), "until": camp.season}
	injuries[injured["id"]] = {"rounds_left": rounds, "sub_id": sub["id"], "original": injured, "prev_contract": prev}


func _swap_out(camp: Campaign, injured_id: String) -> void:
	var inj: Dictionary = injuries[injured_id]
	for i in camp._drivers.size():
		if camp._drivers[i]["id"] == inj["sub_id"]:
			camp._drivers[i] = inj["original"]
			break
	if (inj["prev_contract"] as Dictionary).is_empty():
		camp.personnel.contracts.erase(inj["sub_id"])
	else:
		camp.personnel.contracts[inj["sub_id"]] = inj["prev_contract"]
	injuries.erase(injured_id)


func _apply_mood(driver: Dictionary, rounds: int, delta: Dictionary) -> void:
	for k: String in delta:
		driver["attrs"][k] = clampi(int(driver["attrs"][k]) + int(delta[k]), 30, 99)
	driver["rating"] = roundi(DriverStats.overall(driver))
	moods[driver["id"]] = {"rounds_left": rounds, "delta": delta}


func _end_mood(camp: Campaign, id: String) -> void:
	var m: Dictionary = moods[id]
	for d: Dictionary in camp._drivers:
		if d["id"] == id:
			for k: String in m["delta"]:
				d["attrs"][k] = clampi(int(d["attrs"][k]) - int(m["delta"][k]), 30, 99)
			d["rating"] = roundi(DriverStats.overall(d))
	moods.erase(id)


## Depois de cada corrida disputada: lesões e crises andam uma rodada.
func on_race_recorded(camp: Campaign) -> void:
	for id: String in injuries.keys():
		injuries[id]["rounds_left"] = int(injuries[id]["rounds_left"]) - 1
		if int(injuries[id]["rounds_left"]) <= 0:
			var name: String = injuries[id]["original"]["name"]
			_swap_out(camp, id)
			_add(camp, {"day": camp.day, "cat": "driver", "id": "driver_back", "title": "%s VOLTA AO CARRO" % name.to_upper(),
				"text": "%s está recuperado e volta a correr no próximo fim de semana." % name, "chips": [{"kind": "good", "big": "recuperado", "small": "de volta ao grid"}]})
	for id: String in moods.keys():
		moods[id]["rounds_left"] = int(moods[id]["rounds_left"]) - 1
		if int(moods[id]["rounds_left"]) <= 0:
			_end_mood(camp, id)


## Na virada de temporada: todos voltam ao normal e o calendário cancelado zera.
func reset_for_new_season(camp: Campaign) -> void:
	for id: String in injuries.keys():
		_swap_out(camp, id)
	for id: String in moods.keys():
		_end_mood(camp, id)
	cancelled.clear()
	postponed.clear()
	ask_mult.clear()
	market_until = -1
	market_mult = 1.0


# --- salvar / carregar --------------------------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"freq": freq, "news": news, "unseen": unseen.size(), "injuries": injuries, "moods": moods, "cancelled": cancelled, "postponed": postponed, "principals": principals, "ask_mult": ask_mult,
		"market_until": market_until, "market_mult": market_mult}


static func from_dict(d: Dictionary) -> CampaignEvents:
	var e := CampaignEvents.new()
	e.freq = d.get("freq", "normal")
	e.news = d.get("news", [])
	for n: Dictionary in e.news:
		n["day"] = int(n["day"])
	e.unseen = e.news.slice(0, int(d.get("unseen", 0)))
	e.injuries = d.get("injuries", {})
	for id: String in e.injuries:
		e.injuries[id]["rounds_left"] = int(e.injuries[id]["rounds_left"])
		var o: Dictionary = e.injuries[id]["original"]
		o["number"] = int(o["number"])
		o["rating"] = int(o["rating"])
	e.moods = d.get("moods", {})
	for id: String in e.moods:
		e.moods[id]["rounds_left"] = int(e.moods[id]["rounds_left"])
	e.cancelled = (d.get("cancelled", []) as Array).map(func(x: Variant) -> int: return int(x))
	e.ask_mult = d.get("ask_mult", {})
	e.principals = d.get("principals", {})
	for k: Variant in (d.get("postponed", {}) as Dictionary):
		e.postponed[int(k)] = int(d["postponed"][k])
	e.market_until = int(d.get("market_until", -1))
	e.market_mult = float(d.get("market_mult", 1.0))
	return e
