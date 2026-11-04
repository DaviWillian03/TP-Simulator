class_name CarParts
extends RefCounted
## Peças físicas do carro de UMA equipe (decisões do usuário, 2026-11-04 — docs/DECISIONS.md):
##  - a pesquisa libera uma ESPECIFICAÇÃO (versão B, C...) numa direção escolhida (alta carga, baixo arrasto, ousada...);
##  - a fábrica produz UNIDADES (custo e prazo por unidade); cada unidade é instalada num carro (0 ou 1) ou fica no estoque;
##  - só o carro equipado ganha o efeito. Peça no estoque não melhora nada;
##  - o upgrade pode dar errado: a chance de acerto vem da equipe técnica e da fábrica (CarDevelopment.success_chance),
##    menos o risco da direção. O resultado REAL só é revelado depois da primeira corrida com a peça;
##  - a IA usa exatamente a mesma regra (pesquisa, produção, instalação, erro), então a ordem de forças muda no ano.
## O efeito das peças entra em pontos de característica (reta, curvas lentas, curvas rápidas, confiabilidade); o perfil
## da pista pondera reta/lentas/rápidas (soma 1). Sem dependência de tela. Valores PROVISÓRIOS (data/car_parts.json).

const PERF := ["straight", "slow", "fast"]
const TRAITS := ["straight", "slow", "fast", "rel"]
const NEUTRAL := {"straight": 1.0 / 3.0, "slow": 1.0 / 3.0, "fast": 1.0 / 3.0}
const REL_NEUTRAL := 80.0
const REL_FAIL_K := 0.03  ## cada ponto de confiabilidade abaixo de 80 = +3% de quebras
const WEAR_SOFT := 60.0  ## a partir deste desgaste a unidade começa a perder rendimento
const WEAR_PENALTY := 0.6  ## nota perdida por unidade no fim da vida (100%)
const OUTCOME_SMALL := 0.4  ## "ganho menor": rende 40% do prometido
const OUTCOME_BAD := -0.5  ## "piora": o ganho prometido vira perda de metade; os efeitos negativos continuam
const SMALL_SHARE := 0.65  ## do que não acerta, 65% vira ganho menor e 35% piora
const KNOWLEDGE_K := 0.15  ## cada ponto de "perf" da árvore de P&D no departamento: +15% no tamanho das peças novas
const FIX_COST_K := 0.35
const FIX_DAYS_K := 0.5
const SPARE_A := 1  ## reservas da versão A (asas, assoalho, suspensão) no começo do ano
const AI_BOLD_CHANCE := 0.2
const AI_REPLACE_WEAR := 70.0

## Estado (salvo na campanha)
var team_id := ""
var specs: Dictionary = {}  ## peça -> [{v, dir, fx (prometido), real, outcome: base|good|small|bad, revealed, fixed}]
var units: Array = []  ## [{uid, part, spec, wear, car: -1 (estoque) | 0 | 1, races}]
var research: Array = []  ## [{part, dir, days_left, days_total, cost, fix (índice da spec ou -1)}]
var queue: Array = []  ## produção: [{part, spec, days_left, days_total, install: -1|0|1}]
var reveals: Array = []  ## revelações ainda não vistas pelo jogador: [{part, spec}]
var done_research: Array = []  ## pesquisas concluídas ainda não vistas pelo jogador: [{part, spec}]
var next_uid := 1
var ai_cursor := 0
var gain_k := 1.0  ## IA: tamanho das peças (dificuldade, ranking, sorte do ano, corpo técnico)

static var _data: Dictionary = {}


# --- dados -------------------------------------------------------------------------------

static func data() -> Dictionary:
	if _data.is_empty():
		_data = GameData.load_json(GameData.DATA_DIR + "car_parts.json")
	return _data


static func part_ids() -> Array:
	return data()["parts"].map(func(p: Dictionary) -> String: return p["id"])


static func part(id: String) -> Dictionary:
	for p: Dictionary in data()["parts"]:
		if p["id"] == id:
			return p
	return {}


static func direction(part_id: String, dir_id: String) -> Dictionary:
	for d: Dictionary in part(part_id).get("dirs", []):
		if d["id"] == dir_id:
			return d
	return {}


static func letter(index: int) -> String:
	return String.chr(65 + index)


## Perfil da pista (reta/lentas/rápidas); circuito sem perfil = neutro.
static func profile_of(circuit: Dictionary) -> Dictionary:
	var p: Dictionary = circuit.get("profile", {})
	if p.is_empty():
		return NEUTRAL
	return {"straight": float(p.get("straight", 0.0)), "slow": float(p.get("slow", 0.0)), "fast": float(p.get("fast", 0.0))}


## Desvio das características de fábrica do carro (dados da equipe) ponderado pela pista, em pontos de nota.
static func traits_effect(team: Dictionary, profile: Dictionary) -> float:
	var t: Dictionary = team.get("car_traits", {})
	var v := 0.0
	for k: String in PERF:
		v += float(profile.get(k, 0.0)) * float(t.get(k, 0.0))
	return v


## Multiplicador de quebras pela confiabilidade (80 = normal).
static func rel_mult(rel: float) -> float:
	return clampf(1.0 + (REL_NEUTRAL - rel) * REL_FAIL_K, 0.5, 1.8)


# --- início ---------------------------------------------------------------------------------

func setup(p_team_id: String) -> void:
	team_id = p_team_id
	specs = {}
	units = []
	research = []
	queue = []
	reveals = []
	done_research = []
	next_uid = 1
	for pid: String in part_ids():
		specs[pid] = [{"v": "A", "dir": "", "fx": {}, "real": {}, "outcome": "base", "revealed": true, "fixed": false}]
		for car in 2:
			_add_unit(pid, 0, car)
		if int(part(pid).get("wear", 0)) > 0:
			for i in SPARE_A:
				_add_unit(pid, 0, -1)


func _add_unit(pid: String, spec_i: int, car: int) -> Dictionary:
	var u := {"uid": next_uid, "part": pid, "spec": spec_i, "wear": 0.0, "car": car, "races": 0}
	next_uid += 1
	units.append(u)
	return u


# --- consultas ------------------------------------------------------------------------------

func spec_list(pid: String) -> Array:
	return specs.get(pid, [])


func spec(pid: String, index: int) -> Dictionary:
	var l := spec_list(pid)
	return l[index] if index >= 0 and index < l.size() else {}


func latest_spec(pid: String) -> int:
	return spec_list(pid).size() - 1


func unit_on(pid: String, car: int) -> Dictionary:
	for u: Dictionary in units:
		if u["part"] == pid and int(u["car"]) == car:
			return u
	return {}


func stock(pid: String, spec_index: int = -1) -> Array:
	return units.filter(func(u: Dictionary) -> bool: return u["part"] == pid and int(u["car"]) == -1 and (spec_index < 0 or int(u["spec"]) == spec_index))


func unit_by_uid(uid: int) -> Dictionary:
	for u: Dictionary in units:
		if int(u["uid"]) == uid:
			return u
	return {}


func research_of(pid: String) -> Dictionary:
	for r: Dictionary in research:
		if r["part"] == pid:
			return r
	return {}


func queued(pid: String) -> Array:
	return queue.filter(func(q: Dictionary) -> bool: return q["part"] == pid)


## Rendimento da unidade pelo desgaste (1 = nova).
static func wear_factor(wear: float) -> float:
	return 1.0 - maxf(0.0, wear - WEAR_SOFT) / (100.0 - WEAR_SOFT) * 0.5


## Pontos de característica que a unidade dá, AGORA (real, com desgaste).
func unit_fx(u: Dictionary, tkey: String) -> float:
	var s := spec(u["part"], int(u["spec"]))
	return float((s.get("real", {}) as Dictionary).get(tkey, 0.0)) * wear_factor(float(u["wear"]))


## O que o jogador VÊ: real se já revelado; senão o prometido.
func known_fx(pid: String, spec_index: int, tkey: String) -> float:
	var s := spec(pid, spec_index)
	var src: Dictionary = s.get("real", {}) if bool(s.get("revealed", true)) else s.get("fx", {})
	return float(src.get(tkey, 0.0))


func trait_delta(car: int, tkey: String) -> float:
	var v := 0.0
	for u: Dictionary in units:
		if int(u["car"]) == car:
			v += unit_fx(u, tkey)
	return v


## Delta que o jogador vê (prometido nas peças ainda não reveladas), sem desgaste.
func known_trait_delta(car: int, tkey: String) -> float:
	var v := 0.0
	for u: Dictionary in units:
		if int(u["car"]) == car:
			v += known_fx(u["part"], int(u["spec"]), tkey)
	return v


func wear_penalty(car: int) -> float:
	var p := 0.0
	for u: Dictionary in units:
		if int(u["car"]) == car:
			p += WEAR_PENALTY * maxf(0.0, float(u["wear"]) - WEAR_SOFT) / (100.0 - WEAR_SOFT)
	return p


## Efeito das peças do carro na nota, para um perfil de pista.
func car_effect(car: int, profile: Dictionary = NEUTRAL) -> float:
	var v := 0.0
	for k: String in PERF:
		v += float(profile.get(k, 0.0)) * trait_delta(car, k)
	return v - wear_penalty(car)


func avg_effect(profile: Dictionary = NEUTRAL) -> float:
	return (car_effect(0, profile) + car_effect(1, profile)) * 0.5


# --- pesquisa -------------------------------------------------------------------------------

func can_develop(camp: Campaign, pid: String) -> bool:
	if bool(part(pid).get("own_engine", false)):
		return camp.has_own_engine() if team_id == camp.player_team else CarDevelopment.factory_data()["own_engine_teams"].has(team_id)
	return true


## Tamanho das peças novas do departamento: conhecimento da árvore de P&D (jogador) ou fator da IA.
func gain(camp: Campaign, dept: String) -> float:
	if team_id == camp.player_team:
		return 1.0 + KNOWLEDGE_K * camp.dev.effect_sum("cur", "perf", dept)
	return gain_k


func promised_fx(camp: Campaign, pid: String, dir_id: String) -> Dictionary:
	var g := gain(camp, String(part(pid)["dept"]))
	var out := {}
	var fx: Dictionary = direction(pid, dir_id).get("fx", {})
	for k: String in fx:
		var v := float(fx[k])
		out[k] = snappedf(v * g if v > 0.0 else v, 0.1)
	return out


## Chance de acerto (0..1) de uma direção: equipe técnica + fábrica − risco.
func success_chance(camp: Campaign, pid: String, dir_id: String) -> float:
	var base: float
	if team_id == camp.player_team:
		base = camp.dev.success_chance(String(part(pid)["dept"]))
	else:
		base = _ai_success(camp)
	return clampf(base - float(direction(pid, dir_id).get("risk", 0)) / 100.0, 0.05, 0.95)


## {good, small, bad} (somam 1).
func outcome_odds(camp: Campaign, pid: String, dir_id: String) -> Dictionary:
	var s := success_chance(camp, pid, dir_id)
	return {"good": s, "small": (1.0 - s) * SMALL_SHARE, "bad": (1.0 - s) * (1.0 - SMALL_SHARE)}


func research_cost(pid: String, dir_id: String) -> float:
	return snappedf(float(part(pid)["research_cost"]) * float(direction(pid, dir_id).get("cost_k", 1.0)), 0.1)


func research_days(camp: Campaign, pid: String, dir_id: String) -> int:
	var d := float(part(pid)["research_days"]) * float(direction(pid, dir_id).get("days_k", 1.0))
	if team_id == camp.player_team:
		d *= camp.dev.days_mult(String(part(pid)["dept"]))
	else:
		d /= _ai_staff_k(camp)
	return maxi(3, ceili(d))


## {ok, reason, cost, days, odds}
func research_info(camp: Campaign, pid: String, dir_id: String) -> Dictionary:
	var out := {"ok": false, "reason": "", "cost": research_cost(pid, dir_id), "days": research_days(camp, pid, dir_id),
		"odds": outcome_odds(camp, pid, dir_id)}
	if not can_develop(camp, pid):
		out["reason"] = "engine"
	elif not research_of(pid).is_empty():
		out["reason"] = "now"
	elif team_id == camp.player_team and camp.dev.busy() >= camp.dev.slots():
		out["reason"] = "slots"
	elif team_id == camp.player_team and camp.budget_musd - float(out["cost"]) < CarDevelopment.RESERVE_MUSD:
		out["reason"] = "cash"
	else:
		out["ok"] = true
	return out


func start_research(camp: Campaign, pid: String, dir_id: String) -> bool:
	var info := research_info(camp, pid, dir_id)
	if not info["ok"]:
		return false
	if team_id == camp.player_team:
		camp.budget_musd -= float(info["cost"])
		camp.record("rd", float(info["cost"]))
	research.append({"part": pid, "dir": dir_id, "days_left": int(info["days"]), "days_total": int(info["days"]), "cost": float(info["cost"]), "fix": -1})
	_sync_busy(camp)
	return true


## Corrigir uma especificação que deu errado (depois de revelada): pesquisa curta; pode dar certo ou não.
func fix_info(camp: Campaign, pid: String, spec_index: int) -> Dictionary:
	var s := spec(pid, spec_index)
	var base_info := research_info(camp, pid, String(s.get("dir", "")))
	var out := {"ok": base_info["ok"], "reason": base_info["reason"], "cost": snappedf(float(base_info["cost"]) * FIX_COST_K, 0.1),
		"days": maxi(3, ceili(float(base_info["days"]) * FIX_DAYS_K)), "odds": base_info["odds"]}
	if s.is_empty() or s["outcome"] == "good" or s["outcome"] == "base" or not bool(s["revealed"]):
		out["ok"] = false
		out["reason"] = "nofix"
	elif out["ok"] and team_id == camp.player_team and camp.budget_musd - float(out["cost"]) < CarDevelopment.RESERVE_MUSD:
		out["ok"] = false
		out["reason"] = "cash"
	return out


func start_fix(camp: Campaign, pid: String, spec_index: int) -> bool:
	var info := fix_info(camp, pid, spec_index)
	if not info["ok"]:
		return false
	if team_id == camp.player_team:
		camp.budget_musd -= float(info["cost"])
		camp.record("rd", float(info["cost"]))
	research.append({"part": pid, "dir": spec(pid, spec_index)["dir"], "days_left": int(info["days"]), "days_total": int(info["days"]),
		"cost": float(info["cost"]), "fix": spec_index})
	_sync_busy(camp)
	return true


func cancel_research(camp: Campaign, pid: String) -> bool:
	var r := research_of(pid)
	if r.is_empty():
		return false
	if team_id == camp.player_team:
		camp.budget_musd += float(r["cost"]) * 0.5
		camp.record("rd", -float(r["cost"]) * 0.5)
	research.erase(r)
	_sync_busy(camp)
	return true


func _sync_busy(camp: Campaign) -> void:
	if team_id == camp.player_team:
		camp.dev.parts_busy = research.size()


func _rng(camp: Campaign, tag: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|%s|%d|%d|%d" % [tag, team_id, camp.season, camp.day, int(camp.dev.seed_base)])
	return rng


## Resolve o resultado (escondido) de uma pesquisa concluída.
func _finish_research(camp: Campaign, r: Dictionary) -> void:
	var pid: String = r["part"]
	var rng := _rng(camp, "spec|%s|%d" % [pid, int(r["fix"])])
	var odds := outcome_odds(camp, pid, String(r["dir"]))
	var roll := rng.randf()
	if int(r["fix"]) >= 0:  # correção: ou recupera o prometido, ou fica como estava
		var s := spec(pid, int(r["fix"]))
		if roll < float(odds["good"]) + float(odds["small"]) * 0.5:
			s["real"] = (s["fx"] as Dictionary).duplicate()
			s["outcome"] = "good"
		s["revealed"] = false  # volta a ser testada na próxima corrida
		s["fixed"] = true
		if team_id == camp.player_team:
			done_research.append({"part": pid, "spec": int(r["fix"]), "fix": true})
		return
	var fx := promised_fx(camp, pid, String(r["dir"]))
	var outcome := "good" if roll < float(odds["good"]) else ("small" if roll < float(odds["good"]) + float(odds["small"]) else "bad")
	var real := {}
	for k: String in fx:
		var v := float(fx[k])
		if v > 0.0:
			v *= 1.0 if outcome == "good" else (OUTCOME_SMALL if outcome == "small" else OUTCOME_BAD)
		real[k] = snappedf(v, 0.1)
	var l := spec_list(pid)
	l.append({"v": letter(l.size()), "dir": r["dir"], "fx": fx, "real": real, "outcome": outcome, "revealed": false, "fixed": false})
	if team_id == camp.player_team:
		done_research.append({"part": pid, "spec": l.size() - 1, "fix": false})
		if camp.detail == "essential":
			order_units(camp, pid, l.size() - 1, 2)
	else:
		order_units(camp, pid, l.size() - 1, 2)


# --- produção e instalação ------------------------------------------------------------------------

func unit_cost(pid: String) -> float:
	return float(part(pid)["unit_cost"])


## Dias por unidade: a fábrica de peças mais avançada produz mais rápido.
func unit_days(camp: Campaign, pid: String) -> int:
	var lv := camp.dev.level_of("parts") if team_id == camp.player_team else 3
	return maxi(2, ceili(float(part(pid)["unit_days"]) * (1.0 - 0.07 * (lv - 1))))


## Linhas de produção em paralelo.
func lines(camp: Campaign) -> int:
	var lv := camp.dev.level_of("parts") if team_id == camp.player_team else 3
	return 1 if lv < 3 else 2


## Dias até a n-ésima unidade nova (n = 1, 2...) ficar pronta, se encomendada agora.
func ready_in(camp: Campaign, pid: String, n: int) -> int:
	var busy: Array[int] = []
	for i in lines(camp):
		busy.append(0)
	var all_q := queue.duplicate()
	for i in n:
		all_q.append({"part": pid, "days_left": unit_days(camp, pid)})
	var finish := 0
	for q: Dictionary in all_q:
		var li := busy.find(busy.min())
		busy[li] += int(q["days_left"])
		finish = busy[li]
	return finish


func order_units(camp: Campaign, pid: String, spec_index: int, n: int, install_on: Array = []) -> bool:
	var cost := unit_cost(pid) * n
	if team_id == camp.player_team:
		if camp.budget_musd - cost < CarDevelopment.RESERVE_MUSD:
			return false
		camp.budget_musd -= cost
		camp.record("rd", cost)
	for i in n:
		var d := unit_days(camp, pid)
		queue.append({"part": pid, "spec": spec_index, "days_left": d, "days_total": d, "install": int(install_on[i]) if i < install_on.size() else -1})
	return true


## Turno extra: a próxima unidade da peça na fila fica pronta amanhã.
func rush_cost(pid: String) -> float:
	return snappedf(unit_cost(pid) * 2.0, 0.1)


func rush(camp: Campaign, pid: String) -> bool:
	var q := queued(pid)
	if q.is_empty():
		return false
	var cost := rush_cost(pid)
	if team_id == camp.player_team:
		if camp.budget_musd - cost < CarDevelopment.RESERVE_MUSD:
			return false
		camp.budget_musd -= cost
		camp.record("rd", cost)
	for item: Dictionary in q:
		item["days_left"] = 1
	return true


## Instala uma unidade num carro; a que estava lá volta para o estoque.
func install(uid: int, car: int) -> bool:
	var u := unit_by_uid(uid)
	if u.is_empty() or car < 0 or car > 1:
		return false
	var old := unit_on(u["part"], car)
	if not old.is_empty():
		old["car"] = -1
	u["car"] = car
	return true


## A melhor unidade do estoque para uma peça (maior efeito conhecido, já descontado o desgaste).
func best_stock_unit(pid: String, profile: Dictionary = NEUTRAL) -> Dictionary:
	var best := {}
	var best_v := -INF
	for u: Dictionary in stock(pid):
		var v := _unit_value(u, profile)
		if v > best_v:
			best_v = v
			best = u
	return best


func _unit_value(u: Dictionary, profile: Dictionary) -> float:
	if u.is_empty():
		return -INF
	var v := 0.0
	for k: String in PERF:
		v += float(profile.get(k, 0.0)) * known_fx(u["part"], int(u["spec"]), k) * wear_factor(float(u["wear"]))
	v += known_fx(u["part"], int(u["spec"]), "rel") * 0.05
	return v - WEAR_PENALTY * maxf(0.0, float(u["wear"]) - WEAR_SOFT) / (100.0 - WEAR_SOFT)


## Preparação recomendada para uma pista: em cada peça, coloca nos carros as melhores unidades disponíveis
## (efeito conhecido; peça já revelada como ruim não entra). Devolve quantas trocas fez.
func auto_prepare(profile: Dictionary = NEUTRAL) -> int:
	var changes := 0
	for pid: String in part_ids():
		for car in 2:
			var cur := unit_on(pid, car)
			var best := best_stock_unit(pid, profile)
			if not best.is_empty() and _unit_value(best, profile) > _unit_value(cur, profile) + 0.05:
				install(int(best["uid"]), car)
				changes += 1
	return changes


# --- passagem do tempo e corridas ------------------------------------------------------------------

## Um dia: pesquisas e produção andam; a IA decide o que pesquisar.
func day_step(camp: Campaign) -> void:
	for r: Dictionary in research.duplicate():
		r["days_left"] = int(r["days_left"]) - 1
		if int(r["days_left"]) <= 0:
			research.erase(r)
			_finish_research(camp, r)
			_sync_busy(camp)
	var free := lines(camp)
	for q: Dictionary in queue.duplicate():
		if free <= 0:
			break
		free -= 1
		q["days_left"] = int(q["days_left"]) - 1
		if int(q["days_left"]) <= 0:
			queue.erase(q)
			var u := _add_unit(q["part"], int(q["spec"]), -1)
			if int(q["install"]) >= 0:
				install(int(u["uid"]), int(q["install"]))
			elif team_id != camp.player_team or camp.detail == "essential":
				_auto_install_new(u)
	if team_id != camp.player_team:
		_ai_plan(camp)


## Unidade nova de spec mais recente: vai para o carro que ainda não tem essa spec (ordem: carro 0, carro 1).
func _auto_install_new(u: Dictionary) -> void:
	for car in 2:
		var cur := unit_on(u["part"], car)
		if cur.is_empty() or int(cur["spec"]) < int(u["spec"]):
			install(int(u["uid"]), car)
			return


## Depois de cada corrida: desgaste das unidades nos carros e revelação das peças novas.
## Devolve as revelações desta corrida: [{part, spec, outcome}].
func after_race(camp: Campaign) -> Array:
	var out: Array = []
	var seen := {}
	for u: Dictionary in units:
		if int(u["car"]) < 0:
			continue
		u["wear"] = minf(100.0, float(u["wear"]) + float(part(u["part"]).get("wear", 0)))
		u["races"] = int(u["races"]) + 1
		var s := spec(u["part"], int(u["spec"]))
		var key := "%s|%d" % [u["part"], int(u["spec"])]
		if not bool(s.get("revealed", true)) and not seen.has(key):
			seen[key] = true
			s["revealed"] = true
			out.append({"part": u["part"], "spec": int(u["spec"]), "outcome": s["outcome"]})
	if team_id == camp.player_team:
		reveals.append_array(out)
		if camp.detail == "essential":  # modo Essencial: o diretor técnico troca as peças gastas
			_replace_worn(camp)
	else:
		_ai_after_race(camp)
	return out


## Unidades gastas nos carros: usa uma reserva do estoque ou encomenda outra da melhor especificação.
func _replace_worn(camp: Campaign) -> void:
	for pid: String in part_ids():
		for car in 2:
			var u := unit_on(pid, car)
			if u.is_empty() or float(u["wear"]) < AI_REPLACE_WEAR or queued(pid).size() >= 2:
				continue
			var alt := best_stock_unit(pid)
			if not alt.is_empty() and float(alt["wear"]) < AI_REPLACE_WEAR:
				install(int(alt["uid"]), car)
			else:
				order_units(camp, pid, _ai_best_spec(pid), 1, [car])


# --- IA ---------------------------------------------------------------------------------------------

func _ai_staff_k(camp: Campaign) -> float:
	return camp.personnel.ai_dev_factor(camp, team_id) if camp.personnel != null and not camp.personnel.contracts.is_empty() else 1.0


func _ai_success(camp: Campaign) -> float:
	# estrutura média de uma equipe da IA (fábrica nível 3) + corpo técnico
	return clampf(float(CarDevelopment.factory_data()["base_success_pct"]) / 100.0 + 0.11 + (_ai_staff_k(camp) - 1.0) * 0.6, 0.3, 0.9)


func _ai_plan(camp: Campaign) -> void:
	if not research.is_empty():
		return
	var ids: Array = part_ids().filter(func(p: String) -> bool: return can_develop(camp, p))
	if ids.is_empty():
		return
	var pid: String = ids[ai_cursor % ids.size()]
	ai_cursor += 1
	var rng := _rng(camp, "ai_dir|%s" % pid)
	var dir_id := "bold"
	if rng.randf() >= AI_BOLD_CHANCE:
		var prof := camp.upcoming_profile(4)
		var best_v := -INF
		for d: Dictionary in part(pid)["dirs"]:
			if d["id"] == "bold":
				continue
			var v := 0.0
			for k: String in (d["fx"] as Dictionary):
				v += float(d["fx"][k]) * (float(prof.get(k, 0.0)) if k != "rel" else 0.08)
			if v > best_v:
				best_v = v
				dir_id = d["id"]
	start_research(camp, pid, dir_id)


func _ai_after_race(camp: Campaign) -> void:
	for pid: String in part_ids():
		for car in 2:
			var u := unit_on(pid, car)
			if u.is_empty():
				continue
			var s := spec(pid, int(u["spec"]))
			# peça revelada como ruim: volta para a melhor do estoque (ou a versão anterior)
			if bool(s["revealed"]) and s["outcome"] == "bad":
				var alt := best_stock_unit(pid)
				if not alt.is_empty() and _unit_value(alt, NEUTRAL) > _unit_value(u, NEUTRAL):
					install(int(alt["uid"]), car)
	_replace_worn(camp)


func _ai_best_spec(pid: String) -> int:
	var best := 0
	var best_v := -INF
	for i in spec_list(pid).size():
		var v := 0.0
		for k: String in PERF:
			v += known_fx(pid, i, k) / 3.0
		if v > best_v:
			best_v = v
			best = i
	return best


# --- virada ------------------------------------------------------------------------------------------

## Carro novo: todas as peças voltam para a versão A (o que valia entra no "carry" da equipe).
func rollover(p_team_id: String = "") -> void:
	setup(team_id if p_team_id == "" else p_team_id)


# --- salvar / carregar ---------------------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"team": team_id, "specs": specs, "units": units, "research": research, "queue": queue, "reveals": reveals,
		"done_research": done_research, "next_uid": next_uid, "ai_cursor": ai_cursor, "gain_k": gain_k}


static func from_dict(d: Dictionary) -> CarParts:
	var c := CarParts.new()
	c.team_id = d.get("team", "")
	c.specs = d.get("specs", {})
	c.units = d.get("units", [])
	for u: Dictionary in c.units:
		u["uid"] = int(u["uid"])
		u["spec"] = int(u["spec"])
		u["car"] = int(u["car"])
		u["races"] = int(u["races"])
		u["wear"] = float(u["wear"])
	c.research = d.get("research", [])
	for r: Dictionary in c.research:
		r["days_left"] = int(r["days_left"])
		r["days_total"] = int(r["days_total"])
		r["fix"] = int(r["fix"])
	c.queue = d.get("queue", [])
	for q: Dictionary in c.queue:
		q["spec"] = int(q["spec"])
		q["days_left"] = int(q["days_left"])
		q["days_total"] = int(q["days_total"])
		q["install"] = int(q["install"])
	c.reveals = d.get("reveals", [])
	c.done_research = d.get("done_research", [])
	for l: Array in [c.reveals, c.done_research]:
		for e: Dictionary in l:
			e["spec"] = int(e["spec"])
	c.next_uid = int(d.get("next_uid", 1))
	c.ai_cursor = int(d.get("ai_cursor", 0))
	c.gain_k = float(d.get("gain_k", 1.0))
	return c
