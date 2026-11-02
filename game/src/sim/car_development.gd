class_name CarDevelopment
extends RefCounted
## Desenvolvimento do carro (árvore de P&D, estilo F1 2017) e estrutura da fábrica — modo campanha.
## Sem dependência de tela. Decisões do usuário (docs/DECISIONS.md): paga com dinheiro do orçamento,
## leva dias de calendário, projetos simultâneos limitados pela fábrica, carro atual × carro do ano
## seguinte com a mesma reserva de dinheiro e de projetos. Valores PROVISÓRIOS (data/rd_tree.json,
## data/factory.json).
##
## Nó = "departamento.braço.índice" (ex.: "aero.0.3"). Carro: "cur" (atual) ou "next" (ano seguinte).

const RESERVE_MUSD := 5.0  ## o caixa nunca fica abaixo disto por causa de um projeto
const PARTIAL_SHARE := 0.5  ## resultado parcial rende metade do efeito
const CARRY_SHARE := 0.5  ## na virada, o carro novo herda esta fração do bônus do carro velho
const AUTO_CAP_MUSD := 40.0  ## modo Essencial: teto de gasto por mês (30 dias)
const AUTO_NEXT_SHARE := 0.3  ## modo Essencial: fatia do gasto para o carro do ano seguinte
const DEPT_ORDER := ["engine", "aero", "chassis", "durability"]
const STRUCT_ORDER := ["wind", "sim", "parts", "media"]

## Estado (salvo na campanha)
var levels: Dictionary = {"wind": 1, "sim": 1, "parts": 1, "media": 1}
var media_start := 1  ## nível de marketing em que o patrocínio base foi definido
var done: Dictionary = {"cur": {}, "next": {}}  ## id do nó -> "full" | "partial"
var projects: Array = []  ## [{car, id, days_left, days_total, cost}]
var works: Array = []  ## [{struct, to, days_left, days_total}] (uma obra por estrutura)
var carry := 0.0  ## bônus herdado do carro anterior
var focus := "balanced"  ## modo Essencial: "balanced", "aero", "chassis", "durability", "engine"
var staff_mod: Dictionary = {}  ## efeitos dos técnicos (Personnel.staff_effects), publicados pela campanha
var auto_spent := 0.0  ## gasto automático no mês atual
var auto_spent_next := 0.0
var auto_month := -1
var news: Array = []  ## mensagens recentes (mais nova primeiro)
var seed_base := 1

static var _tree: Dictionary = {}
static var _factory: Dictionary = {}


# --- dados -------------------------------------------------------------------------------

static func tree() -> Dictionary:
	if _tree.is_empty():
		_tree = GameData.load_json(GameData.DATA_DIR + "rd_tree.json")
	return _tree


static func factory_data() -> Dictionary:
	if _factory.is_empty():
		_factory = GameData.load_json(GameData.DATA_DIR + "factory.json")
	return _factory


static func department(dept_id: String) -> Dictionary:
	for d: Dictionary in tree()["departments"]:
		if d["id"] == dept_id:
			return d
	return {}


static func node_id(dept: String, arm: int, index: int) -> String:
	return "%s.%d.%d" % [dept, arm, index]


## {dept, arm, index, node (dados do JSON), kind (dados do tipo), cost, days} ou {} se inválido.
static func node_info(id: String) -> Dictionary:
	var p := id.split(".")
	if p.size() != 3:
		return {}
	var dep := department(p[0])
	if dep.is_empty() or int(p[1]) >= dep["arms"].size():
		return {}
	var arm: Dictionary = dep["arms"][int(p[1])]
	if int(p[2]) >= arm["nodes"].size():
		return {}
	var node: Dictionary = arm["nodes"][int(p[2])]
	var kind: Dictionary = tree()["kinds"][node["k"]]
	var cost: float = float(kind["cost_musd"]) * (1.0 + float(tree()["cost_step"]) * int(p[2]))
	return {"dept": p[0], "arm": int(p[1]), "index": int(p[2]), "node": node, "kind": kind, "effect": arm["effect"],
		"arm_name": arm["name"], "cost": snappedf(cost, 0.1), "days": int(kind["days"])}


static func all_node_ids(dept: String) -> Array[String]:
	var out: Array[String] = []
	var dep := department(dept)
	for a in dep["arms"].size():
		for i in dep["arms"][a]["nodes"].size():
			out.append(node_id(dept, a, i))
	return out


# --- fábrica -----------------------------------------------------------------------------

static func structure(id: String) -> Dictionary:
	for s: Dictionary in factory_data()["structures"]:
		if s["id"] == id:
			return s
	return {}


func level_of(struct_id: String) -> int:
	return int(levels.get(struct_id, 1))


## Nível geral (média arredondada), para as telas e o custo por corrida.
func overall_level() -> int:
	var sum := 0
	for s: String in STRUCT_ORDER:
		sum += level_of(s)
	return roundi(float(sum) / STRUCT_ORDER.size())


func overall_level_exact() -> float:
	var sum := 0
	for s: String in STRUCT_ORDER:
		sum += level_of(s)
	return float(sum) / STRUCT_ORDER.size()


func set_all_levels(level: int) -> void:
	for s: String in STRUCT_ORDER:
		levels[s] = clampi(level, 1, int(factory_data()["max_level"]))
	media_start = level_of("media")


func slots() -> int:
	return int(factory_data()["slots"][level_of("parts") - 1])


func defect_chance() -> float:
	return float(structure("parts")["defect_pct"][level_of("parts") - 1]) / 100.0


func practice_gain_mult() -> float:
	return 1.0 + float(structure("sim")["practice_gain_pct"][level_of("sim") - 1]) / 100.0


func sponsor_mult() -> float:
	var m: Array = structure("media")["sponsor_mult"]
	return float(m[level_of("media") - 1]) / float(m[media_start - 1])


func influence() -> int:
	return int(structure("media")["influence"][level_of("media") - 1])


## Manutenção da fábrica por corrida (US$ mi), somada à base do campanha.
func upkeep_per_race() -> float:
	var total := 0.0
	for s: String in STRUCT_ORDER:
		total += float(structure(s)["upkeep_per_level"]) * level_of(s)
	return total


## Efeito da estrutura num nível (BBCode: [b] para os números), para os cartões da fábrica.
static func effect_text(struct_id: String, level: int) -> String:
	var st := structure(struct_id)
	var i := clampi(level, 1, 5) - 1
	match struct_id:
		"wind":
			return "[b]−%d%%[/b] nos dias dos nós de aero\n[b]+%d[/b] pontos de chance de acerto" % [int(st["days_pct"][i]), int(st["success_pct"][i])]
		"sim":
			return "[b]+%d%%[/b] no acerto dos treinos" % int(st["practice_gain_pct"][i])
		"parts":
			return "[b]%d[/b] projetos ao mesmo tempo\npeças com defeito: [b]%d%%[/b]" % [int(st["slots"][i]), int(st["defect_pct"][i])]
		_:
			var m: Array = st["sponsor_mult"]
			return "marcas até o nível [b]%d[/b] (influência)\nofertas com [b]×%s[/b] de valor" % [int(st["influence"][i]), ("%.1f" % (float(m[i]) / float(m[0]))).replace(".", ",")]


## Texto curto do efeito de um nó.
static func node_effect_text(info: Dictionary) -> String:
	var v: float = float(info["kind"][info["effect"]])
	match info["effect"]:
		"perf":
			return "+%s na nota do carro" % ("%.2f" % v).replace(".", ",")
		"rel":
			return "−%d%% de quebras" % roundi(v * 100.0)
		"eff":
			return "−%d%% nos dias dos projetos do departamento" % roundi(v * 100.0)
		_:
			return "+%s pontos de chance de acerto" % ("%.1f" % v).replace(".", ",")


func work_of(struct_id: String) -> Dictionary:
	for w: Dictionary in works:
		if w["struct"] == struct_id:
			return w
	return {}


## Informações do próximo nível da estrutura: {ok, reason, to, cost, days}.
func upgrade_info(struct_id: String, budget: float) -> Dictionary:
	var lv := level_of(struct_id)
	var max_lv := int(factory_data()["max_level"])
	var info := {"ok": false, "reason": "", "to": lv + 1, "cost": 0.0, "days": 0}
	if lv >= max_lv:
		info["reason"] = "max"
		return info
	if not work_of(struct_id).is_empty():
		info["reason"] = "works"
		return info
	info["cost"] = float(structure(struct_id)["cost_musd"][lv - 1])
	info["days"] = int(factory_data()["days_to_level"][lv - 1])
	if budget - float(info["cost"]) < RESERVE_MUSD:
		info["reason"] = "cash"
		return info
	info["ok"] = true
	return info


func start_upgrade(camp: Campaign, struct_id: String) -> bool:
	var info := upgrade_info(struct_id, camp.budget_musd)
	if not info["ok"]:
		return false
	camp.budget_musd -= float(info["cost"])
	camp.record("works", float(info["cost"]))
	works.append({"struct": struct_id, "to": int(info["to"]), "days_left": int(info["days"]), "days_total": int(info["days"])})
	_log("Obra iniciada: %s (nível %d)." % [structure(struct_id)["name"], int(info["to"])])
	return true


# --- efeitos da árvore --------------------------------------------------------------------

func is_done(car: String, id: String) -> bool:
	return (done[car] as Dictionary).has(id)


func _share(car: String, id: String) -> float:
	var r: String = (done[car] as Dictionary).get(id, "")
	return 1.0 if r == "full" else (PARTIAL_SHARE if r == "partial" else 0.0)


## Soma dos efeitos de um tipo ("perf", "rel", "eff", "qual") dos nós prontos; opcionalmente de um departamento.
func effect_sum(car: String, effect: String, dept: String = "") -> float:
	var total := 0.0
	for id: String in (done[car] as Dictionary):
		var info := node_info(id)
		if info.is_empty() or info["effect"] != effect or (dept != "" and info["dept"] != dept):
			continue
		total += float(info["kind"][effect]) * _share(car, id)
	return total


## Bônus na nota do carro atual (somado ao car_rating da equipe).
func rating_bonus() -> float:
	return carry + effect_sum("cur", "perf")


## Multiplicador de quebras (menor = mais confiável).
func failure_mult() -> float:
	return clampf(1.0 - effect_sum("cur", "rel"), 0.35, 1.0)


func days_mult(dept: String) -> float:
	var m := 1.0 - effect_sum_both("eff", dept) - float(staff_mod.get(dept + ".days", 0.0))
	if dept == "aero":
		m -= float(structure("wind")["days_pct"][level_of("wind") - 1]) / 100.0
	return clampf(m, 0.4, 1.0)


## Eficiência e qualidade valem para o departamento nos dois carros (o time é o mesmo).
func effect_sum_both(effect: String, dept: String) -> float:
	return effect_sum("cur", effect, dept) + effect_sum("next", effect, dept)


## Chance de acerto (0..1) de um projeto do departamento.
func success_chance(dept: String) -> float:
	var base := float(factory_data()["base_success_pct"])
	# aerodinâmica: túnel de vento; os demais departamentos: fábrica de peças e qualidade
	var fac: float = float(structure("wind" if dept == "aero" else "parts")["success_pct"][level_of("wind" if dept == "aero" else "parts") - 1])
	return clampf((base + fac + effect_sum_both("qual", dept) + float(staff_mod.get(dept + ".success", 0.0))) / 100.0, 0.05, 0.98)


func dept_available(dept: String, camp: Campaign) -> bool:
	var dep := department(dept)
	return not bool(dep.get("needs_own_engine", false)) or camp.has_own_engine()


# --- estado dos nós -----------------------------------------------------------------------

func project_of(car: String, id: String) -> Dictionary:
	for p: Dictionary in projects:
		if p["car"] == car and p["id"] == id:
			return p
	return {}


## "done" | "now" | "open" | "lock" (bloqueado: pai pendente ou departamento indisponível)
func node_state(car: String, id: String, camp: Campaign) -> String:
	if is_done(car, id):
		return "done"
	if not project_of(car, id).is_empty():
		return "now"
	var info := node_info(id)
	if info.is_empty() or not dept_available(info["dept"], camp):
		return "lock"
	var parent: int = int(info["node"]["p"])
	if parent < 0:
		return "open"
	return "open" if is_done(car, node_id(info["dept"], info["arm"], parent)) else "lock"


## Projeto de nó: {ok, reason, cost, days, success}
func project_info(car: String, id: String, camp: Campaign) -> Dictionary:
	var info := node_info(id)
	var out := {"ok": false, "reason": "", "cost": 0.0, "days": 0, "success": 0.0}
	if info.is_empty():
		out["reason"] = "invalid"
		return out
	out["cost"] = float(info["cost"])
	out["days"] = maxi(1, ceili(float(info["days"]) * days_mult(info["dept"])))
	out["success"] = success_chance(info["dept"])
	var st := node_state(car, id, camp)
	if st == "done":
		out["reason"] = "done"
	elif st == "now":
		out["reason"] = "now"
	elif st == "lock":
		out["reason"] = "engine" if not dept_available(info["dept"], camp) else "locked"
	elif projects.size() >= slots():
		out["reason"] = "slots"
	elif camp.budget_musd - float(out["cost"]) < RESERVE_MUSD:
		out["reason"] = "cash"
	else:
		out["ok"] = true
	return out


func start_project(camp: Campaign, car: String, id: String) -> bool:
	var pi := project_info(car, id, camp)
	if not pi["ok"]:
		return false
	camp.budget_musd -= float(pi["cost"])
	camp.record("rd", float(pi["cost"]))
	projects.append({"car": car, "id": id, "days_left": int(pi["days"]), "days_total": int(pi["days"]), "cost": float(pi["cost"])})
	return true


func cancel_project(camp: Campaign, car: String, id: String) -> bool:
	var p := project_of(car, id)
	if p.is_empty():
		return false
	camp.budget_musd += float(p["cost"]) * 0.5  # cancelar devolve metade do dinheiro
	camp.record("rd", -float(p["cost"]) * 0.5)
	projects.erase(p)
	return true


# --- passagem do tempo --------------------------------------------------------------------

## Avança n dias: projetos e obras andam; resultados são resolvidos. Devolve as mensagens novas.
func tick(camp: Campaign, n: int) -> Array[String]:
	var msgs: Array[String] = []
	for _d in n:
		camp_day_step(camp, msgs)
	if camp.detail == "essential":
		_auto_plan(camp)
	return msgs


func camp_day_step(camp: Campaign, msgs: Array[String]) -> void:
	for p: Dictionary in projects.duplicate():
		p["days_left"] = int(p["days_left"]) - 1
		if int(p["days_left"]) <= 0:
			projects.erase(p)
			var text := _resolve(camp, p)
			msgs.append(text)
			_log(text)
	for w: Dictionary in works.duplicate():
		w["days_left"] = int(w["days_left"]) - 1
		if int(w["days_left"]) <= 0:
			works.erase(w)
			levels[w["struct"]] = int(w["to"])
			camp.sync_factory_level()
			var text := "Obra concluída: %s agora é nível %d." % [structure(w["struct"])["name"], int(w["to"])]
			msgs.append(text)
			_log(text)


func _resolve(camp: Campaign, p: Dictionary) -> String:
	var info := node_info(p["id"])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|%s|%d|%d" % [p["car"], p["id"], camp.season, camp.day + seed_base])
	var name: String = info["node"]["n"]
	var tag := "(2027) " if p["car"] == "next" else ""
	if rng.randf() < defect_chance():
		camp.budget_musd += float(p["cost"]) * 0.5
		camp.record("rd", -float(p["cost"]) * 0.5)
		return "%sFalha na produção: %s. A peça saiu com defeito (metade do dinheiro devolvida)." % [tag, name]
	if rng.randf() < success_chance(info["dept"]):
		(done[p["car"]] as Dictionary)[p["id"]] = "full"
		camp.refresh_rating()
		return "%sProjeto concluído: %s." % [tag, name]
	(done[p["car"]] as Dictionary)[p["id"]] = "partial"
	camp.refresh_rating()
	return "%sResultado parcial: %s rendeu só metade do esperado." % [tag, name]


func _log(text: String) -> void:
	news.push_front(text)
	while news.size() > 8:
		news.pop_back()


# --- modo Essencial: o diretor técnico escolhe os projetos ----------------------------------

## Nós abertos de um carro, ordenados do mais vantajoso (efeito por dinheiro) ao menos.
func recommended(car: String, camp: Campaign, dept_filter: String = "") -> Array[String]:
	var scored: Array = []
	for dept: String in DEPT_ORDER:
		if (dept_filter != "" and dept != dept_filter) or not dept_available(dept, camp):
			continue
		var w := 1.0
		if focus != "balanced":
			w = 2.0 if focus == dept else 0.7
		for id: String in all_node_ids(dept):
			if node_state(car, id, camp) != "open":
				continue
			var info := node_info(id)
			var kind: Dictionary = info["kind"]
			var value: float = float(kind[info["effect"]])
			if info["effect"] == "perf":
				value *= 1.0
			elif info["effect"] == "rel":
				value *= 1.2
			elif info["effect"] == "eff":
				value *= 4.0
			else:
				value *= 0.06
			scored.append([value * w / maxf(float(info["cost"]), 0.1), id])
	scored.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var out: Array[String] = []
	for s: Array in scored:
		out.append(s[1])
	return out


func _auto_plan(camp: Campaign) -> void:
	var month := camp.day / 30
	if month != auto_month:
		auto_month = month
		auto_spent = 0.0
		auto_spent_next = 0.0
	var guard := 0
	while projects.size() < slots() and guard < 8:
		guard += 1
		var car := "cur"
		if auto_spent > 0.0 and auto_spent_next < AUTO_NEXT_SHARE * auto_spent:
			car = "next"
		var picked := ""
		for id: String in recommended(car, camp):
			var pi := project_info(car, id, camp)
			if pi["ok"] and auto_spent + float(pi["cost"]) <= AUTO_CAP_MUSD:
				picked = id
				break
		if picked == "":
			break
		var cost := float(node_info(picked)["cost"])
		if start_project(camp, car, picked):
			auto_spent += cost
			if car == "next":
				auto_spent_next += cost
		else:
			break


# --- virada de temporada --------------------------------------------------------------------

## O carro do ano seguinte vira o carro atual; o antigo deixa só uma fração do bônus.
func rollover() -> void:
	carry = (carry + effect_sum("cur", "perf")) * CARRY_SHARE
	done["cur"] = (done["next"] as Dictionary).duplicate()
	done["next"] = {}
	var keep: Array = []
	for p: Dictionary in projects:
		if p["car"] == "next":
			p["car"] = "cur"
		else:
			continue  # projeto do carro velho que não terminou é perdido
		keep.append(p)
	projects = keep


# --- salvar / carregar -------------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"levels": levels, "media_start": media_start, "done": done, "projects": projects, "works": works, "carry": carry,
		"focus": focus, "auto_spent": auto_spent, "auto_spent_next": auto_spent_next, "auto_month": auto_month, "news": news}


static func from_dict(d: Dictionary) -> CarDevelopment:
	var c := CarDevelopment.new()
	for k: String in d.get("levels", {}):
		c.levels[k] = int(d["levels"][k])
	c.media_start = int(d.get("media_start", 1))
	c.done = {"cur": (d.get("done", {}).get("cur", {}) as Dictionary).duplicate(), "next": (d.get("done", {}).get("next", {}) as Dictionary).duplicate()}
	c.projects = d.get("projects", [])
	for p: Dictionary in c.projects:
		p["days_left"] = int(p["days_left"])
		p["days_total"] = int(p["days_total"])
	c.works = d.get("works", [])
	for w: Dictionary in c.works:
		w["days_left"] = int(w["days_left"])
		w["days_total"] = int(w["days_total"])
		w["to"] = int(w["to"])
	c.carry = float(d.get("carry", 0.0))
	c.focus = d.get("focus", "balanced")
	c.auto_spent = float(d.get("auto_spent", 0.0))
	c.auto_spent_next = float(d.get("auto_spent_next", 0.0))
	c.auto_month = int(d.get("auto_month", -1))
	c.news = d.get("news", [])
	return c
