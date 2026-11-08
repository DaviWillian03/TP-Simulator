class_name Personnel
extends RefCounted
## Pessoal da campanha: contratos de pilotos, diretor técnico e engenheiros (mockups v10).
## Sem dependência de tela. Regras decididas pelo usuário (docs/DECISIONS.md): contrato simples
## (salário + duração → aceita / contraproposta / recusa); negocia a qualquer hora, mas a troca só vale
## na virada de temporada; quem tem contrato em outra equipe só vem depois que vence ou pagando multa;
## a IA também renova, dispensa e contrata na virada, e quem sobra vira agente livre.
## Valores PROVISÓRIOS. Técnicos e engenheiros são FICTÍCIOS (data/staff_pool.json).

## Os 4 cargos técnicos de cada equipe (decisão do usuário, 2026-11-04; nomes reais em data/staff_2026.json).
const ROLES := ["director", "aero", "designer", "trackside", "race1", "race2"]
const ROLE_NAMES := {"director": "Diretor técnico", "aero": "Chefe de aerodinâmica", "designer": "Projetista-chefe",
	"race1": "Engenheiro de corrida · carro 1", "race2": "Engenheiro de corrida · carro 2",
	"trackside": "Diretor de engenharia de pista"}
## Efeitos (PROVISÓRIO): diretor = todos os departamentos de P&D; aerodinâmica = depto. aero; projetista = chassi,
## durabilidade e motor; engenharia de pista = ganho dos treinos livres (acerto).
const DESIGNER_DEPTS := ["chassis", "durability", "engine"]
const PRACTICE_PER_POINT := 0.012  ## ganho dos treinos por ponto de nota da engenharia de pista acima de 75
const AI_STAFF_DEV_K := 0.015  ## equipes da IA: desenvolvimento por ponto de nota média do corpo técnico acima de 82
const AI_STAFF_RENEW := 85  ## % de chance de a IA renovar um técnico com contrato vencendo
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
var prospects: Array = []  ## base da campanha (F2/F3 e pilotos novos fictícios): evolui, sobe de categoria e se aposenta
var agents: Array = []  ## pilotos de outras categorias (IndyCar, WEC, FE...) e quem ficou sem vaga
var retired: Array = []  ## [{name, age, season, f1}] aposentadorias (notícias e histórico)
var _lists_ready := false

static var _staff_pool: Array = []
static var _team_staff_data: Array = []
static var _free_agents: Array = []


# --- dados ---------------------------------------------------------------------------------

## Todos os técnicos: os 44 das equipes de 2026 (reais ou genéricos) + os do mercado (fictícios).
static func staff_pool() -> Array:
	if _staff_pool.is_empty():
		_staff_pool = team_staff_data() + GameData.load_json(GameData.DATA_DIR + "staff_pool.json")["people"] + _race_engineers(false)
	return _staff_pool


static func team_staff_data() -> Array:
	if _team_staff_data.is_empty():
		_team_staff_data = GameData.load_json(GameData.DATA_DIR + "staff_2026.json")["people"] + _race_engineers(true)
	return _team_staff_data


## Engenheiros de corrida (decisão de 2026-11-08): os de 2026 viram os cargos race1/race2 da equipe (pela ordem dos pilotos
## nos dados); os genéricos ficam no mercado (sem "team"), alternando carro 1 / carro 2.
static func _race_engineers(with_team: bool) -> Array:
	var out: Array = []
	var order := {}
	for d: Dictionary in GameData.drivers():
		var t: String = d["team"]
		order[d["id"]] = int(order.get("_n_" + t, 0))
		order["_n_" + t] = int(order.get("_n_" + t, 0)) + 1
	var i := 0
	for p: Dictionary in GameData.load_json(GameData.DATA_DIR + "race_engineers_2026.json")["people"]:
		var e := {"id": p["id"], "name": p["name"], "nationality": String(p.get("nationality", "—")), "skill": int(p["skill"]), "real": bool(p.get("real", false))}
		if e["real"]:
			e["real_title"] = "Engenheiro de corrida"
		if String(p.get("team", "")) != "":
			if not with_team:
				continue
			e["team"] = p["team"]
			e["role"] = "race1" if int(order.get(p.get("driver", ""), 0)) == 0 else "race2"
		else:
			if with_team:
				continue
			e["role"] = "race1" if i % 2 == 0 else "race2"
			i += 1
		out.append(e)
	return out


## Técnicos de uma equipe no início de 2026: cargo -> pessoa.
static func team_staff(team_id: String) -> Dictionary:
	var out := {}
	for p: Dictionary in team_staff_data():
		if p["team"] == team_id:
			out[p["role"]] = p
	return out


## Quem acerta o carro no treino (decisão de 2026-11-08): {id do piloto: {director, engineer, engineer_name}} — o diretor de
## engenharia de pista da equipe e o engenheiro de corrida do carro (1º piloto = carro 1). camp = null: dados de 2026.
static func practice_skills_for(camp: Campaign, team_id: String, driver_ids: Array) -> Dictionary:
	if (camp == null or camp.personnel == null) and GameData.category_of(team_id) != "F1":
		return feeder_skills(team_id, driver_ids)
	var out := {}
	var st := {}
	if camp == null or camp.personnel == null:
		st = team_staff(team_id)
	for i in driver_ids.size():
		var role := "race1" if i == 0 else "race2"
		var dir_p: Dictionary = st.get("trackside", {}) if camp == null or camp.personnel == null else camp.personnel.staff_of(camp, team_id, "trackside")
		var eng_p: Dictionary = st.get(role, {}) if camp == null or camp.personnel == null else camp.personnel.staff_of(camp, team_id, role)
		out[driver_ids[i]] = {"director": float(dir_p.get("skill", 55)), "engineer": float(eng_p.get("skill", 55)),
			"engineer_name": String(eng_p.get("name", "")), "director_name": String(dir_p.get("name", ""))}
	return out


## F2/F3 fora da campanha: chefe de engenharia e engenheiros genéricos (nomes do name_pool), fixos por equipe.
static func feeder_skills(team_id: String, driver_ids: Array) -> Dictionary:
	var out := {}
	var chief := generic_person("chief|" + team_id)
	for i in driver_ids.size():
		var eng := generic_person("eng%d|%s" % [i, team_id])
		out[driver_ids[i]] = {"director": float(chief["skill"]), "engineer": float(eng["skill"]),
			"engineer_name": eng["name"], "director_name": chief["name"]}
	return out


## Pessoa genérica determinística (nome do name_pool e nota 58-74) a partir de uma chave.
static func generic_person(key: String) -> Dictionary:
	var pool: Dictionary = GameData.load_json(GameData.DATA_DIR + "name_pool.json")["nationalities"]
	var nats: Array = pool.keys()
	nats.sort()
	var h := absi(hash(key))
	var nat: String = nats[h % nats.size()]
	var firsts: Array = pool[nat]["first"]
	var lasts: Array = pool[nat]["last"]
	return {"name": "%s %s" % [firsts[(h / 7) % firsts.size()], lasts[(h / 131) % lasts.size()]], "nationality": nat, "skill": 58 + (h / 17) % 17}


## Multiplicador do ganho dos treinos pela nota da engenharia de pista (0 = vaga: um pouco pior).
static func practice_mult(trackside_skill: float) -> float:
	if trackside_skill <= 0.0:
		return 0.9
	return clampf(1.0 + (trackside_skill - 75.0) * PRACTICE_PER_POINT, 0.85, 1.25)


static func free_agent_drivers() -> Array:
	if _free_agents.is_empty():
		_free_agents = GameData.load_json(GameData.DATA_DIR + "free_agents.json")["drivers"]
	return _free_agents


## Base da campanha (cópia própria: muda ao longo dos anos). Feita na primeira vez a partir dos dados de 2026.
func feeder() -> Array:
	_ensure_lists()
	return prospects


func outside() -> Array:
	_ensure_lists()
	return agents


func _ensure_lists() -> void:
	if _lists_ready:
		return
	_lists_ready = true
	if prospects.is_empty():
		for f: Dictionary in Campaign.feeder_drivers():
			prospects.append(f.duplicate(true))
	if agents.is_empty():
		for f: Dictionary in free_agent_drivers():
			agents.append(f.duplicate(true))


func _find(list: Array, id: String) -> Dictionary:
	for x: Dictionary in list:
		if x["id"] == id:
			return x
	return {}


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
	prospects.clear()
	agents.clear()
	retired.clear()
	_lists_ready = false
	_ensure_lists()
	var on_grid := {}
	for d: Dictionary in camp.drivers():
		on_grid[d["id"]] = true
	prospects = prospects.filter(func(x: Dictionary) -> bool: return not on_grid.has(x["id"]))  # escolhidos pela equipe criada
	for d: Dictionary in camp.drivers():
		contracts[d["id"]] = {"team": d["team"], "salary": driver_ask(float(d["rating"])),
			"until": camp.season + (_h(d["id"]) % 3) + (1 if d["team"] == camp.player_team else 0)}
	for f: Dictionary in feeder():
		if not contracts.has(f["id"]):
			contracts[f["id"]] = {"team": f["category"], "salary": driver_ask(float(f["rating"])), "until": camp.season + (_h(f["id"]) % 2)}
	for f: Dictionary in outside():
		contracts[f["id"]] = {"team": "", "salary": driver_ask(float(f["rating"])), "until": camp.season}
	_assign_staff(camp)


func _assign_staff(camp: Campaign) -> void:
	var taken: Dictionary = {}
	# equipes do grid: os técnicos de 2026 (inclusive os da sua equipe, se for uma equipe real)
	for p: Dictionary in team_staff_data():
		if GameData.team_by_id(camp.teams(), p["team"]).is_empty():
			continue
		contracts[p["id"]] = {"team": p["team"], "salary": staff_ask(float(p["skill"])), "until": camp.season + 1 + (_h(p["id"]) % 3)}
		taken[p["id"]] = true
	for role: String in ROLES:
		staff[role] = ""
	var own := team_staff(camp.player_team)
	if not own.is_empty():
		for role: String in ROLES:
			if own.has(role):
				staff[role] = own[role]["id"]
	else:  # equipe criada: técnicos do mercado no nível da estrutura
		for role: String in ROLES:
			_hire_market_for(camp, role, taken)
	# mercado: os fictícios sem equipe são agentes livres
	for p: Dictionary in staff_pool():
		if not taken.has(p["id"]):
			contracts[p["id"]] = {"team": "", "salary": staff_ask(float(p["skill"])), "until": camp.season}


## Equipe criada (ou cargo novo num save antigo): contrata do mercado alguém no nível da estrutura.
func _hire_market_for(camp: Campaign, role: String, taken: Dictionary) -> void:
	var target := clampf(float(camp.base_rating) - 5.0, 55.0, 88.0)
	var best := ""
	var best_gap := 999.0
	for p: Dictionary in staff_pool():
		if p["role"] != role or taken.has(p["id"]) or p.has("team"):
			continue
		if String(contracts.get(p["id"], {}).get("team", "")) != "":
			continue
		var gap := absf(float(p["skill"]) - target) + float(_h(p["id"]) % 5)
		if gap < best_gap:
			best_gap = gap
			best = p["id"]
	if best != "":
		staff[role] = best
		taken[best] = true
		contracts[best] = {"team": camp.player_team, "salary": staff_ask(float(person(best)["skill"])), "until": camp.season + 1 + (_h(best) % 3)}


## Técnico de uma equipe num cargo (quem tem contrato com ela), ou {}.
func staff_of(camp: Campaign, team_id: String, role: String) -> Dictionary:
	if team_id == camp.player_team:
		var id: String = staff.get(role, "")
		return person(id) if id != "" else {}
	for p: Dictionary in staff_pool():
		if p["role"] == role and String(contracts.get(p["id"], {}).get("team", "")) == team_id:
			return person(p["id"])
	return {}


## Nota média de diretor, aerodinâmica e projetista (vaga conta 60).
func tech_staff_avg(camp: Campaign, team_id: String) -> float:
	var total := 0.0
	for role: String in ["director", "aero", "designer"]:
		total += float(staff_of(camp, team_id, role).get("skill", 60))
	return total / 3.0


## Equipes da IA: fator de desenvolvimento pela nota média de diretor, aerodinâmica e projetista.
func ai_dev_factor(camp: Campaign, team_id: String) -> float:
	return clampf(1.0 + (tech_staff_avg(camp, team_id) - 82.0) * AI_STAFF_DEV_K, 0.7, 1.25)


## Ganho dos treinos de uma equipe pela engenharia de pista.
func team_practice_mult(camp: Campaign, team_id: String) -> float:
	return practice_mult(float(staff_of(camp, team_id, "trackside").get("skill", 0)))


## Engenheiro de corrida de um carro (slot 0 = carro 1).
func race_engineer_of(camp: Campaign, team_id: String, slot: int) -> Dictionary:
	return staff_of(camp, team_id, "race1" if slot == 0 else "race2")


## Saves antigos (cargos de antes de 2026-11-04 ou técnicos que não existem mais): refaz o corpo técnico.
func repair_staff(camp: Campaign) -> void:
	var ok := not staff.is_empty()
	for role: String in staff:
		var id: String = staff[role]
		if not ROLES.has(role) or (id != "" and person(id).is_empty()):
			ok = false
	if not ok:
		staff.clear()
		_assign_staff(camp)
		return
	# saves de antes dos engenheiros de corrida (2026-11-08): só completa o que falta, sem mexer no resto
	for p: Dictionary in team_staff_data():
		if not contracts.has(p["id"]) and not GameData.team_by_id(camp.teams(), p["team"]).is_empty():
			contracts[p["id"]] = {"team": p["team"], "salary": staff_ask(float(p["skill"])), "until": camp.season + 1 + (_h(p["id"]) % 3)}
	for p: Dictionary in staff_pool():
		if not contracts.has(p["id"]):
			contracts[p["id"]] = {"team": "", "salary": staff_ask(float(p["skill"])), "until": camp.season}
	var own := team_staff(camp.player_team)
	for role: String in ROLES:
		if staff.has(role):
			continue
		staff[role] = ""
		if own.has(role) and String(contracts.get(own[role]["id"], {}).get("team", "")) == camp.player_team:
			staff[role] = own[role]["id"]
		else:
			_hire_market_for(camp, role, {})


# --- pessoas --------------------------------------------------------------------------------

## Dicionário unificado: {id, name, nationality, kind ("driver"/"staff"), role, rating, category, number}.
func person(id: String, camp: Campaign = null) -> Dictionary:
	if camp != null:
		for d: Dictionary in camp.drivers():
			if d["id"] == id:
				var out := {"id": id, "name": d["name"], "nationality": d["nationality"], "kind": "driver", "role": "driver", "rating": int(d["rating"]),
					"category": "F1", "number": int(d["number"]), "code": d["code"]}
				for k: String in ["attrs", "birth", "titles", "potential", "height_cm", "weight_kg", "career"]:
					if d.has(k):
						out[k] = d[k]
				return out
	for p: Dictionary in staff_pool():
		if p["id"] == id:
			var o2 := {"id": id, "name": p["name"], "nationality": p["nationality"], "kind": "staff", "role": p["role"], "skill": int(p["skill"]), "rating": int(p["skill"]), "category": "Técnico"}
			if p.has("real_title"):
				o2["real_title"] = p["real_title"]
			return o2
	for list: Array in [feeder(), outside()]:
		var f := _find(list, id)
		if not f.is_empty():
			var o := {"id": id, "name": f["name"], "nationality": f["nationality"], "kind": "driver", "role": "driver", "rating": int(f["rating"]), "category": f["category"]}
			for k: String in ["birth", "potential", "regen", "birth_estimated"]:
				if f.has(k):
					o[k] = f[k]
			return o
	if _ex.has(id):
		var e: Dictionary = _ex[id]
		var out2 := {"id": id, "name": e["name"], "nationality": e["nationality"], "kind": "driver", "role": "driver", "rating": int(e["rating"]),
			"category": "F1", "number": int(e["number"]), "code": e["code"]}
		for k: String in ["attrs", "birth", "titles", "potential", "height_cm", "weight_kg", "career"]:
			if e.has(k):
				out2[k] = e[k]
		return out2
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
		for f: Dictionary in feeder():
			ids.append(f["id"])
		for f: Dictionary in outside():
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
		if kind == "staff" and role != "" and not String(p["role"]).begins_with(role):  # "race" = engenheiros dos dois carros
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
	if p["kind"] != "driver":
		return staff_ask(float(p["skill"]))
	return snappedf(driver_ask(float(p["rating"])) * float(camp.events.ask_mult.get(id, 1.0)), 0.1)


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
## Menores de 18 anos não podem ser contratados para a F1 (decisão do usuário, 2026-11-04): vale a idade na temporada
## em que o contrato começa (a seguinte).
const F1_MIN_AGE := 18


static func old_enough(p: Dictionary, season: int) -> bool:
	var a := DriverCareer.age_in(p, season)
	return a == 0 or a >= F1_MIN_AGE  # sem data de nascimento: não bloqueia


func can_negotiate(camp: Campaign, id: String) -> Dictionary:
	var info := {"ok": true, "reason": "", "buyout": buyout_cost(id, camp)}
	var who := person(id, camp)
	if who.get("kind", "") == "driver" and not is_mine(camp, id) and not old_enough(who, camp.season + 1):
		info["ok"] = false
		info["reason"] = "menor de 18 anos"
		return info
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
		camp.record("contracts", fee)
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
	camp.record("contracts", fee)
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
	var director := _skill_of("director")
	var aero := _skill_of("aero")
	var designer := _skill_of("designer")
	for dept: String in ["engine", "aero", "chassis", "durability"]:
		var days := maxf(director - 50.0, 0.0) / 600.0
		var success := maxf(director - 50.0, 0.0) * 0.05
		var s2 := aero if dept == "aero" else designer
		days += maxf(s2 - 50.0, 0.0) / 500.0
		success += maxf(s2 - 50.0, 0.0) * 0.13
		out[dept + ".days"] = days
		out[dept + ".success"] = success
	out["practice"] = practice_mult(_skill_of("trackside"))
	return out


func _skill_of(role: String) -> float:
	var id: String = staff.get(role, "")
	return float(person(id).get("skill", 0)) if id != "" else 0.0


# --- virada de temporada ---------------------------------------------------------------------------

## Chamado ao encerrar a temporada (antes de season += 1): a IA renova/dispensa/contrata e o jogador
## recebe os contratos assinados. Muda a lista de pilotos do grid.
func rollover(camp: Campaign) -> void:
	var season := camp.season
	_careers(camp)
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
	# 4b) técnicos da IA: renovam (quase sempre) e preenchem vagas com o melhor livre do cargo
	_ai_staff(camp)
	# 5) a IA completa os assentos; o jogador também precisa de 2 pilotos
	_fill_ai(camp)
	_fill_player(camp)
	_top_up_f3(camp)
	camp.driver_ids.assign(player_drivers(camp).map(func(d: Dictionary) -> String: return d["id"]))
	# contratos das pessoas do jogador valem a partir da próxima temporada
	for d in player_drivers(camp):
		if not contracts.has(d["id"]) or contracts[d["id"]]["team"] != camp.player_team:
			contracts[d["id"]] = {"team": camp.player_team, "salary": driver_ask(float(d["rating"])), "until": season + 2}


func _ai_staff(camp: Campaign) -> void:
	var season := camp.season
	var order: Array = camp.teams().filter(func(t: Dictionary) -> bool: return t["id"] != camp.player_team)
	order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["car_rating"]) > float(b["car_rating"]))
	for t: Dictionary in order:
		for role: String in ROLES:
			var cur := staff_of(camp, t["id"], role)
			if not cur.is_empty():
				var c: Dictionary = contracts[cur["id"]]
				if int(c["until"]) > season or pending.has(cur["id"]):
					continue
				if _h("%s|%d|staff" % [cur["id"], season]) % 100 < AI_STAFF_RENEW:
					c["until"] = season + 1 + (_h(cur["id"] + str(season)) % 3)
					continue
				contracts[cur["id"]] = {"team": "", "salary": float(c["salary"]), "until": season}
				_log("%s deixa a %s." % [cur["name"], t["name"]])
			var best := ""
			var best_skill := -1.0
			for p: Dictionary in staff_pool():
				var cc: Dictionary = contracts.get(p["id"], {})
				if p["role"] != role or String(cc.get("team", "")) != "" or pending.has(p["id"]):
					continue
				if float(p["skill"]) > best_skill:
					best_skill = float(p["skill"])
					best = p["id"]
			if best != "":
				contracts[best] = {"team": t["id"], "salary": staff_ask(best_skill), "until": season + 1 + (_h(best) % 3)}
				_log("%s contrata %s (%s)." % [t["name"], person(best)["name"], String(ROLE_NAMES[role]).to_lower()])


func _release_to_pool(camp: Campaign, d: Dictionary) -> void:
	camp._drivers.erase(d)
	camp.free_number(int(d.get("number", 0)))
	if _find(feeder(), d["id"]).is_empty() and _find(outside(), d["id"]).is_empty():
		var e := {"name": d["name"], "nationality": d["nationality"], "rating": int(d["rating"]), "number": int(d["number"]), "code": d["code"]}
		for k: String in ["attrs", "birth", "titles", "potential", "height_cm", "weight_kg", "career"]:
			if d.has(k):
				e[k] = d[k]
		_ex[d["id"]] = e
	contracts[d["id"]] = {"team": "", "salary": float(contracts[d["id"]]["salary"]), "until": camp.season}
	if d["team"] != camp.player_team:
		_log("%s não foi renovado e é agente livre." % d["name"])


func _free_agent_ids() -> Array[String]:
	var out: Array[String] = []
	for f: Dictionary in outside():
		out.append(f["id"])
	return out


## Pilotos disponíveis para contratar (livres ou com contrato que vence nesta temporada), melhor primeiro.
func _available_drivers(camp: Campaign) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var seated: Dictionary = {}
	for d: Dictionary in camp.drivers():
		seated[d["id"]] = true
	var ids: Array[String] = []
	for f: Dictionary in feeder():
		ids.append(f["id"])
	for f: Dictionary in outside():
		ids.append(f["id"])
	for id: String in _ex:
		ids.append(id)
	for id in ids:
		if seated.has(id) or pending.has(id):
			continue
		if not old_enough(person(id, camp), camp.season + 1):  # menor de 18: não pode ir para a F1
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
	var number := camp.rookie_number(p)
	var nd := {"id": id, "name": p["name"], "code": Campaign.driver_code(p["name"]), "number": number,
		"nationality": p["nationality"], "team": team_id, "rating": int(p["rating"]), "from": p.get("category", "F2")}
	for k: String in ["attrs", "birth", "titles", "potential", "height_cm", "weight_kg", "career"]:
		if p.has(k):
			nd[k] = p[k]
	camp._drivers.append(nd)
	_ex.erase(id)
	prospects.erase(_find(feeder(), id))  # subiu para a F1: sai da base
	agents.erase(_find(outside(), id))


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


# --- carreiras: aposentadoria, evolução da base, promoção e pilotos novos -------------------

func _careers(camp: Campaign) -> void:
	var season := camp.season
	var seed_value := int(camp.dev.seed_base) if camp.dev != null else 0
	# 1) aposentadorias (grid, ex-pilotos, base e outras categorias)
	for d: Dictionary in camp.drivers().duplicate():
		var c: Dictionary = contracts.get(d["id"], {})
		var under := int(c.get("until", season)) > season
		var mine: bool = d["team"] == camp.player_team
		if mine and under:
			continue  # o seu piloto cumpre o contrato até o fim
		if DriverCareer.roll("retire|%s|%d|%d" % [d["id"], season, seed_value]) < DriverCareer.retire_chance(d, season, true, under):
			_retire(camp, d, true)
	for id: String in _ex.keys():
		var e: Dictionary = _ex[id].duplicate()
		e["id"] = id
		if DriverCareer.roll("retire|%s|%d|%d" % [id, season, seed_value]) < DriverCareer.retire_chance(e, season, false, false):
			_ex.erase(id)
			_retire_record(e, season, false)
	for list: Array in [feeder(), outside()]:
		for d: Dictionary in list.duplicate():
			if DriverCareer.roll("retire|%s|%d|%d" % [d["id"], season, seed_value]) < DriverCareer.retire_chance(d, season, d.get("category", "") != "Sem vaga", false):
				list.erase(d)
				contracts.erase(d["id"])
				_retire_record(d, season, false)
	# 2) evolução de quem só tem nota geral
	for list: Array in [feeder(), outside()]:
		for d: Dictionary in list:
			DriverCareer.evolve_prospect(d, season + 1, seed_value)
	for id: String in _ex:
		if not _ex[id].has("attrs"):
			var e2: Dictionary = _ex[id]
			e2["id"] = id
			DriverCareer.evolve_prospect(e2, season + 1, seed_value)
			e2.erase("id")
	# 3) promoções: os melhores da F3 sobem; F2 velhos demais ou excedentes ficam sem vaga
	var f3: Array = feeder().filter(func(x: Dictionary) -> bool: return x["category"] == "F3")
	f3.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["rating"]) > int(b["rating"]))
	for i in mini(DriverCareer.PROMOTE_F3, f3.size()):
		f3[i]["category"] = "F2"
		_set_series(f3[i], "F2", season)
	var f2: Array = feeder().filter(func(x: Dictionary) -> bool: return x["category"] == "F2")
	f2.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["rating"]) > int(b["rating"]))
	for i in f2.size():
		var x: Dictionary = f2[i]
		if i >= DriverCareer.F2_SIZE or DriverCareer.age_in(x, season + 1) > DriverCareer.F2_MAX_YEARS_AGE:
			prospects.erase(x)
			x["category"] = "Sem vaga"
			agents.append(x)
			_set_series(x, "", season)

## Pilotos novos (fictícios) completam a F3 — no fim da virada, depois que as equipes contrataram da base.
func _top_up_f3(camp: Campaign) -> void:
	var season := camp.season
	var seed_value := int(camp.dev.seed_base) if camp.dev != null else 0
	var used := {}
	for list: Array in [feeder(), outside()]:
		for x: Dictionary in list:
			used[x["name"]] = true
	for d: Dictionary in camp.drivers():
		used[d["name"]] = true
	var n_f3 := feeder().filter(func(x: Dictionary) -> bool: return x["category"] == "F3").size()
	var k := 0
	while n_f3 < DriverCareer.F3_SIZE:
		var r := DriverCareer.make_regen(season + 1, k, seed_value, used)
		prospects.append(r)
		contracts[r["id"]] = {"team": "F3", "salary": driver_ask(float(r["rating"])), "until": season + 1 + (k % 2)}
		n_f3 += 1
		k += 1
	if k > 0:
		_log("%d pilotos novos estreiam na F3 em %d." % [k, season + 1])




func _set_series(x: Dictionary, team: String, season: int) -> void:
	var c: Dictionary = contracts.get(x["id"], {"salary": driver_ask(float(x["rating"]))})
	c["team"] = team
	c["until"] = season + 1 if team != "" else season
	contracts[x["id"]] = c


func _retire(camp: Campaign, d: Dictionary, f1: bool) -> void:
	camp._drivers.erase(d)
	camp.free_number(int(d.get("number", 0)))
	contracts.erase(d["id"])
	_retire_record(d, camp.season, f1)


func _retire_record(d: Dictionary, season: int, f1: bool) -> void:
	var a := DriverCareer.age_in(d, season)
	retired.append({"name": d["name"], "age": a, "season": season, "f1": f1})
	if f1:
		_log("%s anuncia a aposentadoria aos %d anos." % [d["name"], a])


func _log(text: String) -> void:
	news.push_front(text)
	while news.size() > 12:
		news.pop_back()


# --- salvar / carregar ---------------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"contracts": contracts, "pending": pending, "dismissed": dismissed, "staff": staff, "news": news, "ex": _ex,
		"prospects": feeder(), "agents": outside(), "retired": retired}


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
	p.prospects = d.get("prospects", [])
	p.agents = d.get("agents", [])
	p.retired = d.get("retired", [])
	return p


## Saves antigos (sem a base própria): monta a base e tira quem já está no grid.
func sync_with_grid(camp: Campaign) -> void:
	var on_grid := {}
	for d: Dictionary in camp.drivers():
		on_grid[d["id"]] = true
	feeder()
	prospects = prospects.filter(func(x: Dictionary) -> bool: return not on_grid.has(x["id"]))
	agents = agents.filter(func(x: Dictionary) -> bool: return not on_grid.has(x["id"]))
