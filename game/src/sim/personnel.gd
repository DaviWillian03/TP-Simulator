class_name Personnel
extends RefCounted
## Pessoal da campanha: contratos de pilotos, diretor técnico e engenheiros (mockups v10).
## Sem dependência de tela. Regras decididas pelo usuário (docs/DECISIONS.md): contrato simples
## (salário + duração → aceita / contraproposta / recusa); negocia a qualquer hora, mas a troca só vale
## na virada de temporada; quem tem contrato em outra equipe só vem depois que vence ou pagando multa;
## a IA também renova, dispensa e contrata na virada, e quem sobra vira agente livre.
## Valores PROVISÓRIOS. Técnicos e engenheiros são FICTÍCIOS (data/staff_pool.json).

const ROLES := ["director", "aero", "chassis", "durability", "engine"]
const ROLE_NAMES := {"director": "Diretor técnico", "aero": "Engenheiro de aerodinâmica", "chassis": "Engenheiro de chassi",
	"durability": "Engenheiro de durabilidade", "engine": "Engenheiro de motor"}
const ROLE_DEPT := {"aero": "aero", "chassis": "chassis", "durability": "durability", "engine": "engine"}
const BUYOUT_SHARE := 0.5  ## fração do salário restante paga para tirar alguém de outra equipe
const MAX_YEARS := 5
const AI_RENEW_BASE := 70  ## % de chance de a IA renovar um piloto que vence

## Estado (salvo na campanha)
var contracts: Dictionary = {}  ## id -> {team, salary, until}; team = id da equipe, "F2"/"F3"/"..." (outra categoria) ou "" (livre)
var pending: Dictionary = {}  ## id -> {salary, until, role} assinados para a próxima temporada (jogador)
var dismissed: Array = []  ## ids do jogador que saem na virada
var staff: Dictionary = {}  ## função -> id da pessoa na equipe do jogador ("" = vaga)
var news: Array = []
var _ex: Dictionary = {}  ## ex-pilotos do grid liberados: id -> dados (podem ser contratados de volta)

static var _staff_pool: Array = []
static var _free_agents: Array = []


# --- dados ---------------------------------------------------------------------------------

static func staff_pool() -> Array:
	if _staff_pool.is_empty():
		_staff_pool = GameData.load_json(GameData.DATA_DIR + "staff_pool.json")["people"]
	return _staff_pool


static func free_agent_drivers() -> Array:
	if _free_agents.is_empty():
		_free_agents = GameData.load_json(GameData.DATA_DIR + "free_agents.json")["drivers"]
	return _free_agents


## Salário pedido (US$ mi por ano) por nota do piloto.
static func driver_ask(rating: float) -> float:
	return snappedf(clampf(0.3 + pow(maxf(rating - 60.0, 0.0), 2.0) * 0.0083, 0.3, 14.0), 0.1)


## Salário pedido (US$ mi por ano) por habilidade do técnico.
static func staff_ask(skill: float) -> float:
	return snappedf(0.1 + pow(maxf(skill - 40.0, 0.0), 2.0) * 0.00025, 0.1)


static func _h(text: String) -> int:
	return absi(hash(text))


# --- montagem inicial ------------------------------------------------------------------------

func setup(camp: Campaign) -> void:
	contracts.clear()
	pending.clear()
	dismissed.clear()
	staff.clear()
	news.clear()
	for d: Dictionary in camp.drivers():
		contracts[d["id"]] = {"team": d["team"], "salary": driver_ask(float(d["rating"])),
			"until": camp.season + (_h(d["id"]) % 3) + (1 if d["team"] == camp.player_team else 0)}
	for f: Dictionary in Campaign.feeder_drivers():
		if not contracts.has(f["id"]):
			contracts[f["id"]] = {"team": f["category"], "salary": driver_ask(float(f["rating"])), "until": camp.season + (_h(f["id"]) % 2)}
	for f: Dictionary in free_agent_drivers():
		contracts[f["id"]] = {"team": "", "salary": driver_ask(float(f["rating"])), "until": camp.season}
	_assign_staff(camp)


func _assign_staff(camp: Campaign) -> void:
	var target := clampf(float(camp.base_rating) - 15.0, 45.0, 88.0)
	var taken: Dictionary = {}
	for role: String in ROLES:
		staff[role] = ""
		var best := ""
		var best_gap := 999.0
		for p: Dictionary in staff_pool():
			if p["role"] != role or taken.has(p["id"]):
				continue
			var gap := absf(float(p["skill"]) - target) + float(_h(p["id"]) % 5)
			if gap < best_gap:
				best_gap = gap
				best = p["id"]
		if role == "engine" and not camp.has_own_engine():
			continue
		staff[role] = best
		taken[best] = true
		contracts[best] = {"team": camp.player_team, "salary": staff_ask(float(person(best)["skill"])), "until": camp.season + 1 + (_h(best) % 3)}
	var ai_teams: Array = camp.teams().filter(func(t: Dictionary) -> bool: return t["id"] != camp.player_team)
	for p: Dictionary in staff_pool():
		if taken.has(p["id"]):
			continue
		var employed := _h(p["id"]) % 2 == 0
		contracts[p["id"]] = {"team": ai_teams[_h(p["id"] + "t") % ai_teams.size()]["id"] if employed else "",
			"salary": staff_ask(float(p["skill"])), "until": camp.season + (_h(p["id"]) % 3) if employed else camp.season}


# --- pessoas --------------------------------------------------------------------------------

## Dicionário unificado: {id, name, nationality, kind ("driver"/"staff"), role, rating, category, number}.
func person(id: String, camp: Campaign = null) -> Dictionary:
	if camp != null:
		for d: Dictionary in camp.drivers():
			if d["id"] == id:
				return {"id": id, "name": d["name"], "nationality": d["nationality"], "kind": "driver", "role": "driver", "rating": int(d["rating"]),
					"category": "F1", "number": int(d["number"]), "code": d["code"]}
	for p: Dictionary in staff_pool():
		if p["id"] == id:
			return {"id": id, "name": p["name"], "nationality": p["nationality"], "kind": "staff", "role": p["role"], "skill": int(p["skill"]), "rating": int(p["skill"]), "category": "Técnico"}
	for f: Dictionary in Campaign.feeder_drivers():
		if f["id"] == id:
			return {"id": id, "name": f["name"], "nationality": f["nationality"], "kind": "driver", "role": "driver", "rating": int(f["rating"]), "category": f["category"]}
	for f: Dictionary in free_agent_drivers():
		if f["id"] == id:
			return {"id": id, "name": f["name"], "nationality": f["nationality"], "kind": "driver", "role": "driver", "rating": int(f["rating"]), "category": f["category"]}
	if _ex.has(id):
		var e: Dictionary = _ex[id]
		return {"id": id, "name": e["name"], "nationality": e["nationality"], "kind": "driver", "role": "driver", "rating": int(e["rating"]),
			"category": "F1", "number": int(e["number"]), "code": e["code"]}
	return {}


func contract_of(id: String) -> Dictionary:
	return contracts.get(id, {})


func player_drivers(camp: Campaign) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for d: Dictionary in camp.drivers():
		if d["team"] == camp.player_team:
			out.append(d)
	return out


func is_mine(camp: Campaign, id: String) -> bool:
	if staff.values().has(id):
		return true
	for d in player_drivers(camp):
		if d["id"] == id:
			return true
	return false


## Candidatos do mercado. kind: "driver" ou "staff"; filter: "all", "free", "feeder", "teams"; role para técnicos.
func market(camp: Campaign, kind: String, filter: String = "all", role: String = "") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var ids: Array[String] = []
	if kind == "driver":
		for d: Dictionary in camp.drivers():
			ids.append(d["id"])
		for f: Dictionary in Campaign.feeder_drivers():
			ids.append(f["id"])
		for f: Dictionary in free_agent_drivers():
			ids.append(f["id"])
		for id: String in _ex:
			ids.append(id)
	else:
		for p: Dictionary in staff_pool():
			ids.append(p["id"])
	for id in ids:
		var p := person(id, camp)
		if p.is_empty() or p["kind"] != kind:
			continue
		if kind == "staff" and role != "" and p["role"] != role:
			continue
		var c := contract_of(id)
		var team: String = c.get("team", "")
		var mine := is_mine(camp, id)
		match filter:
			"free":
				if team != "" or mine:
					continue
			"feeder":
				if team == "" or GameData.team_by_id(camp.teams(), team).size() > 0 or mine:
					continue
			"teams":
				if GameData.team_by_id(camp.teams(), team).is_empty() or mine:
					continue
		if mine and filter != "all":
			continue
		var entry := p.duplicate()
		entry["team"] = team
		entry["until"] = int(c.get("until", camp.season))
		entry["salary"] = float(c.get("salary", 0.0))
		entry["ask"] = ask_for(id, camp)
		entry["mine"] = mine
		entry["pending"] = pending.has(id)
		entry["buyout"] = buyout_cost(id, camp)
		out.append(entry)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["rating"]) > int(b["rating"]))
	return out


func ask_for(id: String, camp: Campaign) -> float:
	var p := person(id, camp)
	if p.is_empty():
		return 0.0
	return driver_ask(float(p["rating"])) if p["kind"] == "driver" else staff_ask(float(p["skill"]))


## Multa para tirar a pessoa da equipe atual (0 se está livre ou se o contrato vence esta temporada).
func buyout_cost(id: String, camp: Campaign) -> float:
	var c := contract_of(id)
	if c.is_empty() or c["team"] == "" or is_mine(camp, id):
		return 0.0
	var years := int(c["until"]) - camp.season
	return snappedf(float(c["salary"]) * maxi(years, 0) * BUYOUT_SHARE, 0.1)


# --- negociação -----------------------------------------------------------------------------

## Apelo da equipe do jogador (0,85 a 1,15): equipes com carro melhor atraem melhor.
func appeal(camp: Campaign) -> float:
	var rank := camp.rating_rank(camp.player_team)
	return 1.15 - 0.30 * float(rank - 1) / maxf(float(camp.teams().size() - 1), 1.0)


## Resposta a uma proposta: {result: "accept"|"counter"|"refuse", counter, interest (0..1), text}.
func evaluate(camp: Campaign, id: String, salary: float, years: int) -> Dictionary:
	var ask := ask_for(id, camp)
	var p := person(id, camp)
	var factor := appeal(camp) * (1.0 + 0.02 * float(clampi(years, 1, MAX_YEARS) - 2))
	var worth := salary * factor / maxf(ask, 0.05)
	var interest := clampf((worth - 0.5) / 0.6, 0.0, 1.0)  # 0,5 → 0 · 0,8 → 0,5 · 1,1 → 1
	var out := {"result": "refuse", "counter": 0.0, "interest": interest, "text": ""}
	var first := String(p.get("name", "")).get_slice(" ", 0)
	if worth >= 1.0:
		out["result"] = "accept"
		out["text"] = "%s aceita a proposta." % first
	elif worth >= 0.78:
		out["result"] = "counter"
		out["counter"] = ceilf(ask / factor * 10.0) / 10.0  # arredonda para cima: a contraproposta sempre é aceita
		out["text"] = "Por %d ano%s eu aceito US$ %s mi. Quero uma equipe competitiva." % [years, "" if years == 1 else "s", ("%.1f" % float(out["counter"])).replace(".", ",")]
	else:
		out["text"] = "%s recusa: a proposta está muito abaixo do que vale." % first
	return out


## Pode negociar? {ok, reason, buyout}. reason: "pending", "caixa", "".
func can_negotiate(camp: Campaign, id: String) -> Dictionary:
	var info := {"ok": true, "reason": "", "buyout": buyout_cost(id, camp)}
	if pending.has(id):
		info["ok"] = false
		info["reason"] = "pending"
	elif float(info["buyout"]) > 0.0 and camp.budget_musd - float(info["buyout"]) < CarDevelopment.RESERVE_MUSD:
		info["ok"] = false
		info["reason"] = "caixa"
	return info


## Vagas de piloto na próxima temporada (2 − quem fica − novos contratados).
func open_driver_seats(camp: Campaign) -> int:
	var keep := 0
	for d in player_drivers(camp):
		if dismissed.has(d["id"]):
			continue
		if int(contracts[d["id"]]["until"]) > camp.season or pending.has(d["id"]):
			keep += 1
	for id: String in pending:
		if person(id, camp).get("kind", "") == "driver" and not is_mine(camp, id):
			keep += 1
	return 2 - keep


## Assina (ou renova). replace_id: piloto atual que sai para dar a vaga (quando não há vaga).
func sign(camp: Campaign, id: String, salary: float, years: int, replace_id: String = "") -> Dictionary:
	var ok := can_negotiate(camp, id)
	if not ok["ok"]:
		return {"ok": false, "text": "Não é possível negociar agora (%s)." % ok["reason"]}
	var ev := evaluate(camp, id, salary, years)
	if ev["result"] != "accept":
		return {"ok": false, "text": ev["text"], "result": ev["result"]}
	var p := person(id, camp)
	if p["kind"] == "driver" and not is_mine(camp, id) and open_driver_seats(camp) <= 0:
		if replace_id == "" or not is_mine(camp, replace_id):
			return {"ok": false, "text": "Sem vaga: escolha qual piloto sai."}
		dismiss(camp, replace_id)
	var fee := float(ok["buyout"])
	if fee > 0.0:
		camp.budget_musd -= fee
	pending[id] = {"salary": salary, "until": camp.season + years, "role": p["role"]}
	dismissed.erase(id)
	var msg := "%s contratado para %d (US$ %s mi/ano)." % [p["name"], camp.season + 1, ("%.1f" % salary).replace(".", ",")]
	_log(msg)
	return {"ok": true, "text": msg, "fee": fee}


## Dispensa um piloto ou técnico do jogador (sai na virada); paga metade do salário restante.
func dismiss(camp: Campaign, id: String) -> float:
	if not is_mine(camp, id) or dismissed.has(id):
		return 0.0
	var c := contract_of(id)
	var years := maxi(int(c.get("until", camp.season)) - camp.season, 0)
	var fee := snappedf(float(c.get("salary", 0.0)) * years * BUYOUT_SHARE, 0.1)
	camp.budget_musd -= fee
	dismissed.append(id)
	pending.erase(id)
	_log("%s será dispensado na virada (multa US$ %s mi)." % [person(id, camp)["name"], ("%.1f" % fee).replace(".", ",")])
	return fee


func cancel_dismiss(id: String) -> void:
	dismissed.erase(id)


# --- folha e efeitos ------------------------------------------------------------------------------

## Salários da equipe por temporada (pilotos atuais + técnicos atuais).
func payroll_per_season(camp: Campaign) -> float:
	var total := 0.0
	for d in player_drivers(camp):
		total += float(contracts.get(d["id"], {}).get("salary", 0.0))
	for role: String in staff:
		if staff[role] != "":
			total += float(contracts.get(staff[role], {}).get("salary", 0.0))
	return total


func payroll_per_race(camp: Campaign) -> float:
	return payroll_per_season(camp) / float(maxi(Campaign.calendar().size(), 1))


## Efeitos dos técnicos nos projetos: {"aero.days": 0.06, "aero.success": 3.9, ...} (dias em fração; acerto em pontos).
func staff_effects(_camp: Campaign) -> Dictionary:
	var out := {}
	var director := 0.0
	if staff.get("director", "") != "":
		director = float(person(staff["director"])["skill"])
	for dept: String in ["engine", "aero", "chassis", "durability"]:
		var days := maxf(director - 50.0, 0.0) / 600.0
		var success := maxf(director - 50.0, 0.0) * 0.05
		var role := String(dept)
		if staff.get(role, "") != "":
			var s := float(person(staff[role])["skill"])
			days += maxf(s - 50.0, 0.0) / 500.0
			success += maxf(s - 50.0, 0.0) * 0.13
		out[dept + ".days"] = days
		out[dept + ".success"] = success
	return out


# --- virada de temporada ---------------------------------------------------------------------------

## Chamado ao encerrar a temporada (antes de season += 1): a IA renova/dispensa/contrata e o jogador
## recebe os contratos assinados. Muda a lista de pilotos do grid.
func rollover(camp: Campaign) -> void:
	var season := camp.season
	# 1) IA: renovações e dispensas
	for t: Dictionary in camp.teams():
		if t["id"] == camp.player_team:
			continue
		for d: Dictionary in camp.drivers().filter(func(x: Dictionary) -> bool: return x["team"] == t["id"]):
			var c: Dictionary = contracts[d["id"]]
			if int(c["until"]) > season:
				continue
			var chance := clampi(AI_RENEW_BASE + int(d["rating"]) - 75, 20, 95)
			if _h("%s|%d|renew" % [d["id"], season]) % 100 < chance:
				c["until"] = season + 1 + (_h("%s|%d|yrs" % [d["id"], season]) % 3)
				c["salary"] = driver_ask(float(d["rating"]))
			else:
				_release_to_pool(camp, d)
	# 2) jogador: dispensados e vencidos sem renovação saem
	for d in player_drivers(camp):
		if dismissed.has(d["id"]) or (int(contracts[d["id"]]["until"]) <= season and not pending.has(d["id"])):
			_release_to_pool(camp, d)
	# 3) jogador: contratos assinados entram (pilotos e técnicos)
	for id: String in pending:
		var p := person(id, camp)
		var pend: Dictionary = pending[id]
		if p["kind"] == "driver":
			if not is_mine(camp, id):
				_seat_driver(camp, id, camp.player_team)
			contracts[id] = {"team": camp.player_team, "salary": float(pend["salary"]), "until": int(pend["until"])}
		else:
			var role: String = p["role"]
			var old: String = staff.get(role, "")
			if old != "" and old != id:
				contracts[old] = {"team": "", "salary": float(contracts[old]["salary"]), "until": season}
			staff[role] = id
			contracts[id] = {"team": camp.player_team, "salary": float(pend["salary"]), "until": int(pend["until"])}
	pending.clear()
	dismissed.clear()
	# 4) técnicos do jogador com contrato vencido saem (vaga)
	for role: String in ROLES:
		var id2: String = staff.get(role, "")
		if id2 != "" and int(contracts[id2]["until"]) <= season:
			contracts[id2] = {"team": "", "salary": float(contracts[id2]["salary"]), "until": season}
			staff[role] = ""
			_log("%s deixou a equipe (contrato vencido)." % person(id2)["name"])
	# 5) a IA completa os assentos; o jogador também precisa de 2 pilotos
	_fill_ai(camp)
	_fill_player(camp)
	camp.driver_ids.assign(player_drivers(camp).map(func(d: Dictionary) -> String: return d["id"]))
	# contratos das pessoas do jogador valem a partir da próxima temporada
	for d in player_drivers(camp):
		if not contracts.has(d["id"]) or contracts[d["id"]]["team"] != camp.player_team:
			contracts[d["id"]] = {"team": camp.player_team, "salary": driver_ask(float(d["rating"])), "until": season + 2}


func _release_to_pool(camp: Campaign, d: Dictionary) -> void:
	camp._drivers.erase(d)
	var is_feeder := false
	for f: Dictionary in Campaign.feeder_drivers():
		if f["id"] == d["id"]:
			is_feeder = true
	if not is_feeder and not _free_agent_ids().has(d["id"]):
		_ex[d["id"]] = {"name": d["name"], "nationality": d["nationality"], "rating": int(d["rating"]), "number": int(d["number"]), "code": d["code"]}
	contracts[d["id"]] = {"team": "", "salary": float(contracts[d["id"]]["salary"]), "until": camp.season}
	if d["team"] != camp.player_team:
		_log("%s não foi renovado e é agente livre." % d["name"])


func _free_agent_ids() -> Array[String]:
	var out: Array[String] = []
	for f: Dictionary in free_agent_drivers():
		out.append(f["id"])
	return out


## Pilotos disponíveis para contratar (livres ou com contrato que vence nesta temporada), melhor primeiro.
func _available_drivers(camp: Campaign) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var seated: Dictionary = {}
	for d: Dictionary in camp.drivers():
		seated[d["id"]] = true
	var ids: Array[String] = []
	for f: Dictionary in Campaign.feeder_drivers():
		ids.append(f["id"])
	for f: Dictionary in free_agent_drivers():
		ids.append(f["id"])
	for id: String in _ex:
		ids.append(id)
	for id in ids:
		if seated.has(id) or pending.has(id):
			continue
		var c: Dictionary = contracts.get(id, {})
		if c.is_empty() or (c["team"] != "" and int(c["until"]) > camp.season):
			continue
		var p := person(id, camp)
		if not p.is_empty():
			out.append(p)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["rating"]) > int(b["rating"]))
	return out


func _seat_driver(camp: Campaign, id: String, team_id: String) -> void:
	for d: Dictionary in camp._drivers:  # já está no grid (veio de outra equipe): só troca de time
		if d["id"] == id:
			d["team"] = team_id
			return
	var p := person(id, camp)
	var used: Array = []
	for d: Dictionary in camp.drivers():
		used.append(int(d["number"]))
	var number := int(p.get("number", 0))
	if number <= 0 or used.has(number):
		number = 2
		while used.has(number):
			number += 1
	camp._drivers.append({"id": id, "name": p["name"], "code": Campaign.driver_code(p["name"]), "number": number,
		"nationality": p["nationality"], "team": team_id, "rating": int(p["rating"]), "from": p.get("category", "F2")})
	_ex.erase(id)


func _fill_ai(camp: Campaign) -> void:
	var order: Array = camp.teams().filter(func(t: Dictionary) -> bool: return t["id"] != camp.player_team)
	order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["car_rating"]) > float(b["car_rating"]))
	for t: Dictionary in order:  # equipes melhores escolhem primeiro
		while player_or_team_seats(camp, t["id"]) < 2:
			var pool := _available_drivers(camp)
			if pool.is_empty():
				break
			var pick: Dictionary = pool[_h("%s|%d|%d" % [t["id"], camp.season, player_or_team_seats(camp, t["id"])]) % mini(3, pool.size())]
			_seat_driver(camp, pick["id"], t["id"])
			contracts[pick["id"]] = {"team": t["id"], "salary": driver_ask(float(pick["rating"])), "until": camp.season + 1 + (_h(pick["id"]) % 3)}
			_log("%s assina com %s." % [pick["name"], t["name"]])


func player_or_team_seats(camp: Campaign, team_id: String) -> int:
	var n := 0
	for d: Dictionary in camp.drivers():
		if d["team"] == team_id:
			n += 1
	return n


func _fill_player(camp: Campaign) -> void:
	while player_or_team_seats(camp, camp.player_team) < 2:
		var pool := _available_drivers(camp)
		if pool.is_empty():
			break
		# sem vaga preenchida pelo jogador: contratação automática pelo melhor custo-benefício
		var best: Dictionary = pool[0]
		var best_value := -1.0
		for p: Dictionary in pool:
			var v := float(p["rating"]) / (1.0 + driver_ask(float(p["rating"])) * 0.6)
			if v > best_value:
				best_value = v
				best = p
		_seat_driver(camp, best["id"], camp.player_team)
		contracts[best["id"]] = {"team": camp.player_team, "salary": driver_ask(float(best["rating"])), "until": camp.season + 2}
		_log("Vaga de piloto vazia: %s foi contratado automaticamente." % best["name"])


func _log(text: String) -> void:
	news.push_front(text)
	while news.size() > 12:
		news.pop_back()


# --- salvar / carregar ---------------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"contracts": contracts, "pending": pending, "dismissed": dismissed, "staff": staff, "news": news, "ex": _ex}


static func from_dict(d: Dictionary) -> Personnel:
	var p := Personnel.new()
	p.contracts = d.get("contracts", {})
	for id: String in p.contracts:
		p.contracts[id]["salary"] = float(p.contracts[id]["salary"])
		p.contracts[id]["until"] = int(p.contracts[id]["until"])
	p.pending = d.get("pending", {})
	for id: String in p.pending:
		p.pending[id]["salary"] = float(p.pending[id]["salary"])
		p.pending[id]["until"] = int(p.pending[id]["until"])
	p.dismissed = d.get("dismissed", [])
	p.staff = d.get("staff", {})
	p.news = d.get("news", [])
	p._ex = d.get("ex", {})
	return p
