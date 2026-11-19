class_name CarDevelopment
extends RefCounted
## Fábrica da equipe do jogador (modo campanha) — v42, 2026-11-19 (docs/DECISIONS.md).
## Quatro estruturas com efeito escrito em números em cada nível (data/factory.json):
##  - Túnel de vento / CFD: projetos de aero mais rápidos e faixa de ganho aero mais apertada;
##  - Fábrica de peças: vagas de projeto, peças mecânicas mais rápidas e faixa mecânica mais apertada;
##  - Simulador: acerto dos treinos;
##  - Marketing: valor das ofertas de patrocínio e metas por oferta.
## Ampliar custa dinheiro e leva dias (uma obra por estrutura). Os projetos de peça em si ficam em CarParts (a mesma
## regra da IA); aqui ficam as vagas, a velocidade e o aperto da faixa que a fábrica dá. A árvore de P&D antiga saiu na
## v42: o que já tinha sido desenvolvido virou nota do carro (migrate_tree). Sem dependência de tela.

const RESERVE_MUSD := 5.0  ## o caixa nunca fica abaixo disto por causa de um projeto
const CARRY_SHARE := 0.5  ## na virada, o carro novo herda esta fração do que o carro velho ganhou no ano
const AUTO_CAP_MUSD := 40.0  ## modo Essencial: teto de gasto por mês (30 dias)
const DEPT_ORDER := ["engine", "aero", "chassis", "durability"]
const STRUCT_ORDER := ["wind", "parts", "sim", "media"]
const TREE_PERF_TO_RATING := 0.5  ## migração da árvore antiga: cada ponto de "perf" pronto vira meio ponto de nota

## Estado (salvo na campanha)
var levels: Dictionary = {"wind": 1, "sim": 1, "parts": 1, "media": 1}
var media_start := 1  ## nível de marketing em que o patrocínio base foi definido
var works: Array = []  ## [{struct, to, days_left, days_total}] (uma obra por estrutura)
var carry := 0.0  ## bônus herdado dos carros anteriores (nota)
var atr := 1.0  ## restrição de túnel de vento (tempo de pesquisa aero; publicada pela campanha)
var parts_busy := 0  ## projetos de peça em andamento (CarParts): ocupam as vagas da fábrica
var staff_mod: Dictionary = {}  ## efeitos dos técnicos (Personnel.staff_effects), publicados pela campanha
var auto_spent := 0.0  ## gasto automático no mês atual
var auto_month := -1
var news: Array = []  ## mensagens recentes (mais nova primeiro)
var seed_base := 1

static var _factory: Dictionary = {}


# --- dados -------------------------------------------------------------------------------

static func factory_data() -> Dictionary:
	if _factory.is_empty():
		_factory = GameData.load_json(GameData.DATA_DIR + "factory.json")
	return _factory


static func structure(id: String) -> Dictionary:
	for s: Dictionary in factory_data()["structures"]:
		if s["id"] == id:
			return s
	return {}


static func _at(list: Array, level: int) -> float:
	return float(list[clampi(level, 1, list.size()) - 1])


func level_of(struct_id: String) -> int:
	return int(levels.get(struct_id, 1))


## Nível geral (média arredondada), para as telas e o custo por corrida.
func overall_level() -> int:
	return roundi(overall_level_exact())


func overall_level_exact() -> float:
	var sum := 0
	for s: String in STRUCT_ORDER:
		sum += level_of(s)
	return float(sum) / STRUCT_ORDER.size()


func set_all_levels(level: int) -> void:
	for s: String in STRUCT_ORDER:
		levels[s] = clampi(level, 1, int(factory_data()["max_level"]))
	media_start = level_of("media")


# --- efeitos -------------------------------------------------------------------------------

static func slots_at(level: int) -> int:
	return int(_at(structure("parts")["slots"], level))


func slots() -> int:
	return slots_at(level_of("parts"))


## Estrutura que cuida dos projetos do departamento: aero = túnel de vento; o resto = fábrica de peças.
static func struct_for(dept: String) -> String:
	return "wind" if dept == "aero" else "parts"


## Projetos do departamento mais rápidos (fração) pela estrutura no nível.
static func days_cut_at(dept: String, level: int) -> float:
	return _at(structure(struct_for(dept))["days_pct"], level) / 100.0


## Quanto a estrutura sobe o piso da faixa de ganho (fração).
static func narrow_at(dept: String, level: int) -> float:
	return _at(structure(struct_for(dept))["narrow_pct"], level) / 100.0


func days_mult(dept: String) -> float:
	var m := 1.0 - days_cut_at(dept, level_of(struct_for(dept))) - float(staff_mod.get(dept + ".days", 0.0))
	if dept == "aero":
		return clampf(clampf(m, 0.4, 1.0) / maxf(atr, 0.5), 0.35, 1.6)  # menos tempo de túnel = mais dias
	return clampf(m, 0.4, 1.0)


## Aperto da faixa do projeto: estrutura + equipe técnica (+ restrição de túnel na aero).
func narrow(dept: String) -> float:
	var n := narrow_at(dept, level_of(struct_for(dept))) + float(staff_mod.get(dept + ".success", 0.0)) / 100.0
	if dept == "aero":
		n += (atr - 1.0) * 0.2
	return maxf(n, 0.0)


## Só a parte da equipe técnica no aperto (para a tela "quem aperta a faixa").
func staff_narrow(dept: String) -> float:
	return float(staff_mod.get(dept + ".success", 0.0)) / 100.0


static func practice_pct_at(level: int) -> int:
	return int(_at(structure("sim")["practice_gain_pct"], level))


func practice_gain_mult() -> float:
	return 1.0 + practice_pct_at(level_of("sim")) / 100.0


static func offer_pct_at(level: int) -> int:
	return int(_at(structure("media")["offer_pct"], level))


static func goals_at(level: int) -> int:
	return int(_at(structure("media")["goals"], level))


## Multiplicador das ofertas de patrocínio, relativo ao nível de marketing com que a equipe começou (o patrocínio
## inicial já foi escalado para o equilíbrio financeiro da equipe).
func sponsor_mult() -> float:
	return (1.0 + offer_pct_at(level_of("media")) / 100.0) / (1.0 + offer_pct_at(media_start) / 100.0)


func goals_per_offer() -> int:
	return goals_at(level_of("media"))


func influence() -> int:
	return int(_at(structure("media")["influence"], level_of("media")))


## Confiabilidade agora vem das peças (projetos de confiabilidade); a fábrica não muda as quebras.
func failure_mult() -> float:
	return 1.0


## Manutenção da fábrica por corrida (US$ mi), somada à base da campanha.
func upkeep_per_race() -> float:
	var total := 0.0
	for s: String in STRUCT_ORDER:
		total += float(structure(s)["upkeep_per_level"]) * level_of(s)
	return total


## Efeitos da estrutura num nível, uma frase por linha (os números já escritos), para os cartões da fábrica.
static func effect_lines(struct_id: String, level: int) -> Array[String]:
	var out: Array[String] = []
	match struct_id:
		"wind":
			out.append("Aero: −%d%% de dias por projeto" % roundi(days_cut_at("aero", level) * 100.0))
			out.append("Aero: faixa do ganho +%d%%" % roundi(narrow_at("aero", level) * 100.0))
		"parts":
			out.append("%d projetos ao mesmo tempo" % slots_at(level))
			out.append("Mecânica: −%d%% de dias" % roundi(days_cut_at("chassis", level) * 100.0))
			out.append("Mecânica: faixa +%d%%" % roundi(narrow_at("chassis", level) * 100.0))
		"sim":
			out.append("Acerto dos treinos +%d%%" % practice_pct_at(level))
		_:
			out.append("Ofertas de patrocínio +%d%%" % offer_pct_at(level))
			out.append("%d meta%s por oferta" % [goals_at(level), "s" if goals_at(level) > 1 else ""])
	return out


## Os mesmos efeitos em texto (BBCode: os números em [b]), uma linha por efeito.
static func effect_text(struct_id: String, level: int) -> String:
	var rx := RegEx.create_from_string("([+−-]?\\d+%?)")
	var out: Array[String] = []
	for l: String in effect_lines(struct_id, level):
		out.append(rx.sub(l, "[b]$1[/b]", true))
	return "\n".join(out)


# --- obras ---------------------------------------------------------------------------------

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
	info["cost"] = float(structure(struct_id)["cost_musd"][lv - 1])
	info["days"] = int(factory_data()["days_to_level"][lv - 1])
	if not work_of(struct_id).is_empty():
		info["reason"] = "works"
		return info
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


# --- projetos (vagas) ------------------------------------------------------------------------

## Bônus na nota do carro atual (somado ao car_rating da equipe): o que foi herdado dos carros anteriores.
func rating_bonus() -> float:
	return carry


## Vagas de projeto ocupadas (projetos de peça em andamento).
func busy() -> int:
	return parts_busy


# --- passagem do tempo --------------------------------------------------------------------

## Avança n dias: obras andam; no modo Essencial o diretor técnico começa projetos. Devolve as mensagens novas.
func tick(camp: Campaign, n: int) -> Array[String]:
	var msgs: Array[String] = []
	for _d in n:
		camp_day_step(camp, msgs)
	if camp.detail == "essential":
		_auto_plan(camp)
	return msgs


func camp_day_step(camp: Campaign, msgs: Array[String]) -> void:
	for w: Dictionary in works.duplicate():
		w["days_left"] = int(w["days_left"]) - 1
		if int(w["days_left"]) <= 0:
			works.erase(w)
			levels[w["struct"]] = int(w["to"])
			camp.sync_factory_level()
			var text := "Obra concluída: %s agora é nível %d." % [structure(w["struct"])["name"], int(w["to"])]
			msgs.append(text)
			_log(text)


func _log(text: String) -> void:
	news.push_front(text)
	while news.size() > 8:
		news.pop_back()


# --- modo Essencial: o diretor técnico escolhe os projetos ----------------------------------

const AUTO_RESERVE_MUSD := 25.0


## Verba do mês para o diretor técnico: o caixa acima de uma reserva, mais o que a temporada ainda deve render, dividido
## pelos meses que faltam — e nunca além do teto livre para P&D. Assim o gasto se espalha pelo ano.
func auto_allowance(camp: Campaign) -> float:
	var races := camp.races_left_in_season()
	var months := maxf(ceilf(races / 2.2), 1.0)  # ~2,2 corridas por mês
	var future := (camp.sponsor_per_race() - camp.cost_per_race()) * races
	var free_cash := camp.budget_musd - AUTO_RESERVE_MUSD + future
	return clampf(minf(free_cash, camp.cap_left_rd()) / months, 0.0, AUTO_CAP_MUSD)


func _auto_plan(camp: Campaign) -> void:
	var month := camp.day / 30
	if month != auto_month:
		auto_month = month
		auto_spent = 0.0
	var cp := camp.my_parts()
	if cp != null:
		auto_spent += cp.auto_projects(camp, auto_allowance(camp) - auto_spent)


# --- virada de temporada --------------------------------------------------------------------

## O carro do ano seguinte vira o carro atual: herda uma fração do que o carro velho tinha (herança + peças) e tudo o
## que foi desenvolvido para ele durante o ano (next_bank das peças).
func rollover(parts_gain: float = 0.0, next_bank: float = 0.0) -> void:
	carry = (carry + parts_gain) * CARRY_SHARE + next_bank


## Prévia da nota herdada pelo carro do ano seguinte (mesma conta da virada).
func next_car_estimate(parts_gain: float, next_bank: float) -> float:
	return (carry + parts_gain) * CARRY_SHARE + next_bank


# --- salvar / carregar -------------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"levels": levels, "media_start": media_start, "works": works, "carry": carry, "auto_spent": auto_spent,
		"auto_month": auto_month, "news": news, "v": 42}


static func from_dict(d: Dictionary) -> CarDevelopment:
	var c := CarDevelopment.new()
	for k: String in d.get("levels", {}):
		c.levels[k] = int(d["levels"][k])
	c.media_start = int(d.get("media_start", 1))
	c.works = d.get("works", [])
	for w: Dictionary in c.works:
		w["days_left"] = int(w["days_left"])
		w["days_total"] = int(w["days_total"])
		w["to"] = int(w["to"])
	c.carry = float(d.get("carry", 0.0))
	c.auto_spent = float(d.get("auto_spent", 0.0))
	c.auto_month = int(d.get("auto_month", -1))
	c.news = d.get("news", [])
	if int(d.get("v", 0)) < 42:
		c.carry += migrate_tree(d)
	return c


## Save de antes da v42: os nós da árvore de P&D já prontos viram nota do carro. "perf" do carro atual entra agora; o do
## carro do ano seguinte também (o jogador já tinha pago por ele; simplificação aceita). Projetos de nó em andamento
## são encerrados (o dinheiro já tinha sido gasto: vira nota proporcional ao tempo andado).
static func migrate_tree(d: Dictionary) -> float:
	var tree_path := GameData.DATA_DIR + "rd_tree_legacy.json"
	if not FileAccess.file_exists(tree_path):
		return 0.0
	var tree: Dictionary = GameData.load_json(tree_path)
	var perf := {}  # id do nó -> efeito perf
	for dep: Dictionary in tree.get("departments", []):
		var arms: Array = dep.get("arms", [])
		for a in arms.size():
			if String(arms[a].get("effect", "")) != "perf":
				continue
			var nodes: Array = arms[a].get("nodes", [])
			for i in nodes.size():
				var kind: Dictionary = tree.get("kinds", {}).get(String(nodes[i].get("k", "")), {})
				perf["%s.%d.%d" % [dep["id"], a, i]] = float(kind.get("perf", 0.0))
	var total := 0.0
	var done: Dictionary = d.get("done", {})
	for car: String in ["cur", "next"]:
		var nodes_done: Dictionary = done.get(car, {})
		for id: String in nodes_done:
			total += float(perf.get(id, 0.0)) * (1.0 if nodes_done[id] == "full" else 0.5)
	for p: Dictionary in d.get("projects", []):
		var frac := 1.0 - float(p.get("days_left", 0)) / maxf(float(p.get("days_total", 1)), 1.0)
		total += float(perf.get(String(p.get("id", "")), 0.0)) * frac
	return total * TREE_PERF_TO_RATING
