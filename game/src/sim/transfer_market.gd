class_name TransferMarket
extends RefCounted
## Mercado vivo durante a temporada (decisões do usuário, 2026-11-10). Sem tela.
## 1) Contratos futuros da IA: a partir de ~30% da temporada, cada equipe da IA decide renovar ou liberar quem vence e
##    fecha pilotos para o ano seguinte (anunciado nas notícias; a troca só vale na virada).
## 2) Rivais atrás dos seus: propostas pelos seus pilotos e técnicos. Você escolhe COBRIR (iguala o salário e estende),
##    ACEITAR A MULTA (recebe agora; ele sai na virada) ou DEIXAR IR quando o contrato acabar.
## 3) Pedidos de renovação perto do fim do contrato: ACEITAR, RECUSAR (piloto perde confiança por algumas corridas) ou
##    DEPOIS (pede de novo mais tarde; na segunda vez, não há "depois").
## Sem resposta no prazo, vale a opção mais conservadora (deixar ir no fim do contrato / pedir de novo depois).
## Valores PROVISÓRIOS.

const WINDOW_FROM := 0.3  ## fração da temporada em que o mercado abre
const RENEWAL_FROM := 0.45  ## a partir daqui as suas pessoas pedem renovação
const AI_DECIDE_CHANCE := 0.25  ## por rodada: a equipe da IA decide sobre quem vence
const AI_SIGN_CHANCE := 0.3  ## por rodada: a equipe com vaga no ano seguinte fecha alguém
const OFFER_CHANCE := 0.14  ## por rodada e pessoa (escala com a nota)
const RENEWAL_CHANCE := 0.4
const DECISION_DAYS := 21
const MAX_NEWS := 2  ## notícias de mercado por rodada
const REFUSE_MOOD := {"pace": -2, "consistency": -2}
const REFUSE_ROUNDS := 3

var future: Dictionary = {}  ## id -> {team, salary, until, start, from} contrato que começa na temporada `start`
var decided: Dictionary = {}  ## id -> "renewed" | "released" (pilotos da IA que vencem nesta temporada)
var leaving: Dictionary = {}  ## id (seu) -> equipe rival: sai na virada
var decisions: Array = []  ## decisões abertas: {uid, kind: "offer"|"renewal", id, team, salary, years, fee, ends_now, until_day, asks}
var asked: Dictionary = {}  ## id -> quantas vezes pediu renovação nesta temporada
var offered: Dictionary = {}  ## id -> true (no máximo uma proposta por pessoa por temporada)
var _uid := 1


# --- rodada ----------------------------------------------------------------------------------------------

## Chamado depois de cada corrida da campanha (F1).
func after_round(camp: Campaign) -> void:
	var cal := Campaign.calendar().size()
	var frac := float(camp.round) / float(maxi(cal, 1))
	_expire(camp)
	if frac < WINDOW_FROM or camp.round >= cal:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d|%d|market" % [camp.season, camp.round])
	var budget := [MAX_NEWS]
	_ai_decisions(camp, rng, budget)
	_ai_signings(camp, rng, budget)
	_rival_offers(camp, rng)
	if frac >= RENEWAL_FROM:
		_renewal_requests(camp, rng)


func _news(camp: Campaign, budget: Array, title: String, text: String, chips: Array, force := false, team := "") -> void:
	if not force and int(budget[0]) <= 0:
		return
	budget[0] = int(budget[0]) - 1
	camp.events._add(camp, {"day": camp.day, "cat": "market", "id": "market", "title": title, "text": text, "chips": chips, "team": team})


func _team_name(camp: Campaign, id: String) -> String:
	return String(GameData.team_by_id(camp.teams(), id).get("name", id))


## Vagas da equipe para a próxima temporada (quem tem contrato além desta + renovados + contratos futuros − quem sai).
func seats_next(camp: Campaign, team_id: String) -> int:
	var p: Personnel = camp.personnel
	var n := 0
	for d: Dictionary in camp.drivers():
		if d["team"] != team_id or leaving.has(d["id"]):
			continue
		if future.has(d["id"]) and String(future[d["id"]]["team"]) != team_id and int(future[d["id"]]["start"]) == camp.season + 1:
			continue
		var c: Dictionary = p.contract_of(d["id"])
		if int(c.get("until", 0)) > camp.season or String(decided.get(d["id"], "")) == "renewed" or p.pending.has(d["id"]):
			n += 1
	for id: String in future:
		if String(future[id]["team"]) == team_id and int(future[id]["start"]) == camp.season + 1:
			n += 1
	return n


func _ai_decisions(camp: Campaign, rng: RandomNumberGenerator, budget: Array) -> void:
	var p: Personnel = camp.personnel
	for d: Dictionary in camp.drivers():
		if d["team"] == camp.player_team or decided.has(d["id"]) or future.has(d["id"]):
			continue
		var c: Dictionary = p.contract_of(d["id"])
		if c.is_empty() or int(c["until"]) > camp.season:
			continue
		if rng.randf() >= AI_DECIDE_CHANCE:
			continue
		var chance := clampi(Personnel.AI_RENEW_BASE + int(d["rating"]) - 75, 20, 95)
		if seats_next(camp, d["team"]) >= 2:
			chance = 0  # a equipe já fechou os dois carros do ano que vem
		if rng.randi() % 100 < chance:
			c["until"] = camp.season + 1 + rng.randi() % 3
			c["salary"] = Personnel.driver_ask(float(d["rating"]))
			decided[d["id"]] = "renewed"
			if int(d["rating"]) >= 80:
				_news(camp, budget, "%s RENOVA COM A %s" % [String(d["name"]).to_upper(), _team_name(camp, d["team"]).to_upper()],
					"%s fica na %s até %d." % [d["name"], _team_name(camp, d["team"]), int(c["until"])],
					[{"kind": "good", "big": "até %d" % int(c["until"]), "small": "renovado"}], false, String(d["team"]))
		else:
			decided[d["id"]] = "released"


func _ai_signings(camp: Campaign, rng: RandomNumberGenerator, budget: Array) -> void:
	var p: Personnel = camp.personnel
	var order: Array = camp.teams().filter(func(t: Dictionary) -> bool: return t["id"] != camp.player_team)
	order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["car_rating"]) > float(b["car_rating"]))
	for t: Dictionary in order:
		if seats_next(camp, t["id"]) >= 2 or rng.randf() >= AI_SIGN_CHANCE:
			continue
		var pool := _candidates(camp)
		if pool.is_empty():
			return
		var pick: Dictionary = pool[rng.randi() % mini(3, pool.size())]
		var from := ""
		for d: Dictionary in camp.drivers():
			if d["id"] == pick["id"]:
				from = String(d["team"])
		var yrs := 1 + rng.randi() % 3
		future[pick["id"]] = {"team": t["id"], "salary": Personnel.driver_ask(float(pick["rating"])), "until": camp.season + yrs,
			"start": camp.season + 1, "from": from if from != "" else String(pick.get("category", ""))}
		_news(camp, budget, "%s ASSINA COM A %s PARA %d" % [String(pick["name"]).to_upper(), String(t["name"]).to_upper(), camp.season + 1],
			"%s%s correrá pela %s a partir da próxima temporada." % [pick["name"], (" (hoje na %s)" % _team_name(camp, from)) if from != "" else "", t["name"]],
			[{"kind": "", "big": str(camp.season + 1), "small": "contrato futuro"}, {"kind": "", "big": "nota %d" % int(pick["rating"]), "small": "piloto"}],
			int(pick["rating"]) >= 78, String(t["id"]))


## Quem pode ser contratado para o ano seguinte: liberados da IA, agentes livres e a base (melhor primeiro).
func _candidates(camp: Campaign) -> Array:
	var p: Personnel = camp.personnel
	var out: Array = []
	var seen := {}
	for d: Dictionary in camp.drivers():
		if d["team"] != camp.player_team and String(decided.get(d["id"], "")) == "released" and not future.has(d["id"]):
			out.append(p.person(d["id"], camp))
			seen[d["id"]] = true
	for x: Dictionary in p._available_drivers(camp):
		if not seen.has(x["id"]) and not future.has(x["id"]):
			out.append(x)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["rating"]) > int(b["rating"]))
	return out


# --- seus pilotos e técnicos -----------------------------------------------------------------------------------

func _my_people(camp: Campaign) -> Array:
	var p: Personnel = camp.personnel
	var out: Array = []
	for d in p.player_drivers(camp):
		out.append(d["id"])
	for role: String in p.staff:
		if String(p.staff[role]) != "":
			out.append(p.staff[role])
	return out


func open_for(id: String) -> Dictionary:
	for d: Dictionary in decisions:
		if d["id"] == id:
			return d
	return {}


func _rival_offers(camp: Campaign, rng: RandomNumberGenerator) -> void:
	var p: Personnel = camp.personnel
	var made := 0
	for id: String in _my_people(camp):
		if made >= 1 or offered.has(id) or leaving.has(id) or p.dismissed.has(id) or not open_for(id).is_empty():
			continue
		var who: Dictionary = p.person(id, camp)
		var rating := float(who.get("rating", 70))
		if rng.randf() >= OFFER_CHANCE * clampf((rating - 70.0) / 15.0, 0.25, 1.6):
			continue
		var team := _rival_team(camp, who, rng)
		if team.is_empty():
			continue
		var c: Dictionary = p.contract_of(id)
		var ends_now: bool = int(c.get("until", camp.season)) <= camp.season and not p.pending.has(id)
		var salary: float = snappedf(p.ask_for(id, camp) * rng.randf_range(1.15, 1.4), 0.1)
		var years_left := maxi(int(c.get("until", camp.season)) - camp.season, 0)
		var fee := snappedf(maxf(float(c.get("salary", 0.0)) * (years_left + 1) * 0.6, 1.0), 0.1)
		offered[id] = true
		_add_decision(camp, {"kind": "offer", "id": id, "team": team["id"], "salary": salary, "years": 2 + rng.randi() % 2,
			"fee": fee, "ends_now": ends_now})
		made += 1


## Equipe interessada: para pilotos, uma com vaga no ano seguinte (preferindo carro melhor); para técnicos, uma melhor.
func _rival_team(camp: Campaign, who: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var mine := float(GameData.team_by_id(camp.teams(), camp.player_team).get("car_rating", 80.0))
	var opts: Array = []
	for t: Dictionary in camp.teams():
		if t["id"] == camp.player_team:
			continue
		if who.get("kind", "") == "driver" and seats_next(camp, t["id"]) >= 2:
			continue
		if who.get("kind", "") != "driver" and float(t["car_rating"]) < mine - 1.0:
			continue
		opts.append(t)
	if opts.is_empty():
		return {}
	opts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["car_rating"]) > float(b["car_rating"]))
	return opts[rng.randi() % mini(3, opts.size())]


func _renewal_requests(camp: Campaign, rng: RandomNumberGenerator) -> void:
	var p: Personnel = camp.personnel
	for id: String in _my_people(camp):
		var c: Dictionary = p.contract_of(id)
		if int(c.get("until", 99999)) > camp.season or p.pending.has(id) or leaving.has(id) or p.dismissed.has(id):
			continue
		if int(asked.get(id, 0)) >= 2 or not open_for(id).is_empty() or rng.randf() >= RENEWAL_CHANCE:
			continue
		asked[id] = int(asked.get(id, 0)) + 1
		var salary: float = snappedf(p.ask_for(id, camp) * rng.randf_range(1.05, 1.2), 0.1)
		_add_decision(camp, {"kind": "renewal", "id": id, "team": camp.player_team, "salary": salary, "years": 2, "fee": 0.0,
			"ends_now": true, "asks": int(asked[id])})


func _add_decision(camp: Campaign, d: Dictionary) -> void:
	d["uid"] = _uid
	_uid += 1
	d["until_day"] = camp.day + DECISION_DAYS
	decisions.append(d)


func _expire(camp: Campaign) -> void:
	for d: Dictionary in decisions.duplicate():
		if camp.day > int(d["until_day"]):
			resolve(camp, int(d["uid"]), "let_go" if d["kind"] == "offer" else ("later" if int(d.get("asks", 1)) < 2 else "refuse"))


## Opções de cada decisão: [[código, rótulo curto]].
static func options_for(d: Dictionary) -> Array:
	if d["kind"] == "offer":
		var opts := [["cover", "Cobrir a proposta"], ["fee", "Aceitar a multa"]]
		opts.append(["let_go", "Deixar ir no fim do contrato" if not bool(d["ends_now"]) else "Deixar ir na virada"])
		return opts
	var out := [["accept", "Aceitar"], ["refuse", "Recusar"]]
	if int(d.get("asks", 1)) < 2:
		out.append(["later", "Depois"])
	return out


## Aplica a escolha. Devolve o texto do resultado (para o aviso).
func resolve(camp: Campaign, uid: int, choice: String) -> String:
	var d: Dictionary = {}
	for x: Dictionary in decisions:
		if int(x["uid"]) == uid:
			d = x
	if d.is_empty():
		return ""
	decisions.erase(d)
	var p: Personnel = camp.personnel
	var id: String = d["id"]
	var who: Dictionary = p.person(id, camp)
	var name := String(who.get("name", id))
	var c: Dictionary = p.contract_of(id)
	var until := int(c.get("until", camp.season))
	var salary := float(d["salary"])
	if d["kind"] == "offer":
		var rival := _team_name(camp, d["team"])
		match choice:
			"cover":
				if until <= camp.season:
					p.pending[id] = {"salary": salary, "until": camp.season + int(d["years"]), "role": who.get("role", "driver")}
				else:
					c["salary"] = salary
					c["until"] = until + 1
				return "%s fica: salário igualado (US$ %s mi/ano)." % [name, _m(salary)]
			"fee":
				var fee := float(d["fee"])
				camp.budget_musd += fee
				camp.record("events_in", fee)
				leaving[id] = d["team"]
				future[id] = {"team": d["team"], "salary": salary, "until": camp.season + int(d["years"]), "start": camp.season + 1, "from": camp.player_team}
				return "%s vai para a %s na virada. Multa recebida: US$ %s mi." % [name, rival, _m(fee)]
			_:
				var start := maxi(until, camp.season) + 1
				future[id] = {"team": d["team"], "salary": salary, "until": start + int(d["years"]) - 1, "start": start, "from": camp.player_team}
				if start == camp.season + 1:
					leaving[id] = d["team"]
					return "%s vai para a %s quando o contrato acabar, na virada." % [name, rival]
				return "%s cumpre o contrato até %d e depois vai para a %s." % [name, until, rival]
	match choice:
		"accept":
			p.pending[id] = {"salary": salary, "until": camp.season + int(d["years"]), "role": who.get("role", "driver")}
			return "%s renovado até %d (US$ %s mi/ano)." % [name, camp.season + int(d["years"]), _m(salary)]
		"later":
			return "%s vai perguntar de novo mais tarde." % name
	# recusou: piloto perde confiança por algumas corridas
	if who.get("kind", "") == "driver":
		for x: Dictionary in camp._drivers:
			if x["id"] == id and not camp.events.moods.has(id):
				camp.events._apply_mood(x, REFUSE_ROUNDS, REFUSE_MOOD)
	return "%s ficou chateado com a recusa e sai quando o contrato acabar." % name


static func _m(v: float) -> String:
	return ("%.1f" % v).replace(".", ",")


# --- virada -----------------------------------------------------------------------------------------------------

## Antes do mercado da virada: aplica os contratos futuros que começam na próxima temporada (o resto do mercado da
## virada — renovações que faltaram, vagas — continua em Personnel.rollover).
func apply_at_rollover(camp: Campaign) -> void:
	var p: Personnel = camp.personnel
	var next := camp.season + 1
	for id: String in future.keys():
		var f: Dictionary = future[id]
		if int(f["start"]) != next:
			continue
		var who: Dictionary = p.person(id, camp)
		if who.is_empty():  # aposentou-se na virada: o contrato futuro cai
			future.erase(id)
			continue
		if who.get("kind", "") == "driver":
			p._seat_driver(camp, id, String(f["team"]))
			p.pending.erase(id)
			p.dismissed.erase(id)
		else:
			for role: String in p.staff:
				if String(p.staff[role]) == id:
					p.staff[role] = ""
		p.contracts[id] = {"team": String(f["team"]), "salary": float(f["salary"]), "until": int(f["until"])}
		future.erase(id)
	leaving.clear()
	decided.clear()
	asked.clear()
	offered.clear()
	decisions.clear()


func to_dict() -> Dictionary:
	return {"future": future, "decided": decided, "leaving": leaving, "decisions": decisions, "asked": asked, "offered": offered, "uid": _uid}


static func from_dict(d: Dictionary) -> TransferMarket:
	var m := TransferMarket.new()
	m.future = d.get("future", {})
	for id: String in m.future:
		for k: String in ["until", "start"]:
			m.future[id][k] = int(m.future[id][k])
		m.future[id]["salary"] = float(m.future[id]["salary"])
	m.decided = d.get("decided", {})
	m.leaving = d.get("leaving", {})
	m.decisions = d.get("decisions", [])
	for x: Dictionary in m.decisions:
		for k: String in ["uid", "years", "until_day", "asks"]:
			if x.has(k):
				x[k] = int(x[k])
	m.asked = d.get("asked", {})
	m.offered = d.get("offered", {})
	m._uid = int(d.get("uid", 1))
	return m
