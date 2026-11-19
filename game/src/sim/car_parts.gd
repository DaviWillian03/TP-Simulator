class_name CarParts
extends RefCounted
## Peças físicas do carro de UMA equipe (2026-11-04; projetos diretos desde a v42, 2026-11-19 — docs/DECISIONS.md):
##  - o PROJETO escolhe uma área (asa dianteira, assoalho, motor...) e um tamanho (P/M/G): custo, prazo e ganho esperado
##    aparecem antes. Ao terminar, a nova versão entra nos dois carros (e nas reservas) e o ganho real aparece na entrega:
##    sempre positivo, entre 60% e 120% do esperado (equipe técnica e fábrica sobem o piso);
##  - as unidades físicas continuam: desgaste, reservas, limite de motor/câmbio; a equipe troca as gastas sozinha;
##  - a IA usa exatamente a mesma regra, então a ordem de forças muda no ano.
## O efeito das peças entra em pontos de característica (reta, curvas lentas, curvas rápidas, confiabilidade); o perfil
## da pista pondera reta/lentas/rápidas (soma 1). Sem dependência de tela. Valores PROVISÓRIOS (data/car_parts.json).

const PERF := ["straight", "slow", "fast"]
const TRAITS := ["straight", "slow", "fast", "rel"]
const NEUTRAL := {"straight": 1.0 / 3.0, "slow": 1.0 / 3.0, "fast": 1.0 / 3.0}
const REL_NEUTRAL := 80.0
const REL_FAIL_K := 0.03  ## cada ponto de confiabilidade abaixo de 80 = +3% de quebras
const WEAR_SOFT := 60.0  ## a partir deste desgaste a unidade começa a perder rendimento
const WEAR_PENALTY := 0.6  ## nota perdida por unidade no fim da vida (100%)
const SPARE_A := 1  ## reservas da versão A (asas, assoalho, suspensão) no começo do ano
const AI_REPLACE_WEAR := 70.0
## Limite por temporada (decisão de 2026-11-10): unidades de motor e câmbio por carro. Passou do limite, punição de grid
## na corrida em que a unidade nova estreia: motor 10 posições na primeira vez e 5 nas seguintes; câmbio 5; mais de 15
## posições = largada do fundo. Valores PROVISÓRIOS.
const LIMITS := {"pu": 4, "gearbox": 4}
const PENALTY_FIRST := {"pu": 10, "gearbox": 5}
const PENALTY_NEXT := {"pu": 5, "gearbox": 5}
const BACK_OF_GRID := 15
const LIMIT_REPLACE_WEAR := 95.0  ## já no limite: só troca com a unidade quase quebrando
const WORN_FAIL_FROM := 80.0  ## motor/câmbio acima disto quebram mais

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
var used: Dictionary = {}  ## "carro|peça" -> [uids] de motor/câmbio que já correram nesta temporada
var deliveries: Array = []  ## projetos entregues (mais novo primeiro): [{area, size, part, v, expected, real (total), now (no carro atual), ratio, share, round, season}]
var next_share := 0.0  ## fatia do esforço para o carro do ano seguinte (0..1; o jogador escolhe na tela Carro)
var next_bank := 0.0  ## nota já garantida para o carro do ano seguinte (entra na base na virada)

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
	used = {}
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


# --- projetos de peça (v42) --------------------------------------------------------------------
# O jogador (e a IA, com a mesma regra) escolhe uma ÁREA (asa dianteira, assoalho, motor...) e um TAMANHO (pequeno,
# médio, grande). Custo, prazo e ganho esperado aparecem antes; quando o projeto termina, a nova versão da peça entra nos
# dois carros e o ganho REAL (sempre positivo, entre 60% e 120% do esperado) aparece na entrega. A equipe técnica e a
# fábrica sobem o piso dessa faixa. Uma fatia do esforço (next_share) pode ir para o carro do ano seguinte: rende mais
# (next_k), mas só na virada.

static func projects_cfg() -> Dictionary:
	return data()["projects"]


static func areas() -> Array:
	return projects_cfg()["areas"]


static func area(id: String) -> Dictionary:
	for a: Dictionary in areas():
		if a["id"] == id:
			return a
	return {}


static func sizes() -> Array:
	return projects_cfg()["sizes"]


static func size_of(id: String) -> Dictionary:
	for s: Dictionary in sizes():
		if s["id"] == id:
			return s
	return sizes()[1]


## Área de um projeto antigo (save de antes da v42): a primeira área da peça.
static func area_of_part(pid: String) -> String:
	for a: Dictionary in areas():
		if a["part"] == pid:
			return a["id"]
	return ""


## Pontos de nota que um conjunto de características vale numa pista (perfil); confiabilidade não entra.
static func fx_rating(fx: Dictionary, profile: Dictionary = NEUTRAL) -> float:
	var v := 0.0
	for k: String in PERF:
		v += float(profile.get(k, 0.0)) * float(fx.get(k, 0.0))
	return v


## Segundos por volta que um conjunto de características vale (positivo = mais rápido).
static func fx_seconds(fx: Dictionary, profile: Dictionary = NEUTRAL) -> float:
	return fx_rating(fx, profile) * RaceSim.CAR_K


## Perfil "puro" do tipo de pista em que a área ajuda (para mostrar o ganho onde ele conta).
static func area_profile(area_id: String) -> Dictionary:
	var fx: Dictionary = area(area_id).get("fx", {})
	var total := 0.0
	for k: String in PERF:
		total += float(fx.get(k, 0.0))
	if total <= 0.0:
		return NEUTRAL
	var out := {}
	for k: String in PERF:
		out[k] = float(fx.get(k, 0.0)) / total
	return out


## Menos quebras (fração) que pontos de confiabilidade dão.
static func rel_fail_cut(rel_points: float) -> float:
	return rel_points * REL_FAIL_K


func can_develop(camp: Campaign, pid: String) -> bool:
	if bool(part(pid).get("own_engine", false)):
		return camp.has_own_engine() if team_id == camp.player_team else CarDevelopment.factory_data()["own_engine_teams"].has(team_id)
	return true


func area_available(camp: Campaign, area_id: String) -> bool:
	var a := area(area_id)
	return not a.is_empty() and can_develop(camp, String(a["part"]))


## Quanto a equipe técnica e a fábrica sobem o piso da faixa (0..max_narrow).
func narrow(camp: Campaign, dept: String) -> float:
	var n: float
	if team_id == camp.player_team:
		n = camp.dev.narrow(dept)
	else:  # IA: estrutura média (nível 3) + corpo técnico; aero sofre a restrição de túnel
		n = 0.12 + (_ai_staff_k(camp) - 1.0) * 0.3
		if dept == "aero":
			n += (camp.atr_mult(team_id) - 1.0) * 0.2
	return clampf(n, 0.0, float(projects_cfg()["max_narrow"]))


## Faixa do ganho real em fração do esperado: [piso, teto].
func band(camp: Campaign, area_id: String) -> Array:
	var cfg := projects_cfg()
	var dept := String(part(String(area(area_id)["part"]))["dept"])
	return [float(cfg["band_lo"]) + narrow(camp, dept), float(cfg["band_hi"])]


## Tamanho das peças: jogador 1; IA: dificuldade, ranking, sorte do ano e corpo técnico (gain_k).
func gain(camp: Campaign) -> float:
	return 1.0 if team_id == camp.player_team else gain_k


## Ganho esperado (pontos de característica) de um projeto, antes da divisão com o carro do ano seguinte.
func project_fx(camp: Campaign, area_id: String, size_id: String) -> Dictionary:
	var k := float(projects_cfg()["fx_k"]) * float(size_of(size_id)["gain_k"]) * gain(camp)
	var out := {}
	var fx: Dictionary = area(area_id).get("fx", {})
	for t: String in fx:
		out[t] = snappedf(float(fx[t]) * k, 0.01)
	return out


func project_cost(area_id: String, size_id: String) -> float:
	return snappedf(float(area(area_id)["cost"]) * float(size_of(size_id)["cost_k"]), 0.1)


func project_days(camp: Campaign, area_id: String, size_id: String) -> int:
	var dept := String(part(String(area(area_id)["part"]))["dept"])
	var d := float(area(area_id)["days"]) * float(size_of(size_id)["days_k"])
	if team_id == camp.player_team:
		d *= camp.dev.days_mult(dept)
	else:
		d /= _ai_staff_k(camp)
		if dept == "aero":
			d /= maxf(camp.atr_mult(team_id), 0.5)
	return maxi(3, ceili(d))


## Fatia do ganho que vai para o carro do ano seguinte (confiabilidade fica toda no carro atual).
func share_for(area_id: String) -> float:
	return 0.0 if area_id == "rel" else next_share


func project_of(area_id: String) -> Dictionary:
	for r: Dictionary in research:
		if String(r.get("area", "")) == area_id:
			return r
	return {}


## {ok, reason, cost, days, fx, lo, hi, share, sec (s/volta no tipo de pista da área), sec_avg, rel_cut}
func project_info(camp: Campaign, area_id: String, size_id: String) -> Dictionary:
	var fx := project_fx(camp, area_id, size_id)
	var b := band(camp, area_id) if not area(area_id).is_empty() else [0.6, 1.2]
	var share := share_for(area_id)
	var prof := area_profile(area_id)
	var out := {"ok": false, "reason": "", "cost": project_cost(area_id, size_id), "days": project_days(camp, area_id, size_id),
		"fx": fx, "lo": b[0], "hi": b[1], "share": share, "sec": fx_seconds(fx, prof) * (1.0 - share),
		"sec_avg": fx_seconds(fx) * (1.0 - share), "rel_cut": rel_fail_cut(float(fx.get("rel", 0.0)))}
	var pid := String(area(area_id).get("part", ""))
	if pid == "":
		out["reason"] = "invalid"
	elif not area_available(camp, area_id):
		out["reason"] = "engine"
	elif not research_of(pid).is_empty():
		out["reason"] = "now"
	elif team_id == camp.player_team and camp.dev.busy() >= camp.dev.slots():
		out["reason"] = "slots"
	elif team_id == camp.player_team and camp.budget_musd - float(out["cost"]) < CarDevelopment.RESERVE_MUSD:
		out["reason"] = "cash"
	elif team_id == camp.player_team and not camp.cap_allows(float(out["cost"])):
		out["reason"] = "cap"
	else:
		out["ok"] = true
	return out


func start_project(camp: Campaign, area_id: String, size_id: String) -> bool:
	var info := project_info(camp, area_id, size_id)
	if not info["ok"]:
		return false
	if team_id == camp.player_team:
		camp.budget_musd -= float(info["cost"])
		camp.record("rd", float(info["cost"]))
	research.append({"part": String(area(area_id)["part"]), "area": area_id, "size": size_id, "days_left": int(info["days"]),
		"days_total": int(info["days"]), "cost": float(info["cost"]), "fx": info["fx"], "fix": -1})
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


## Entrega: sorteia o ganho real dentro da faixa, cria a nova versão e põe nos dois carros (e nas reservas).
func _finish_research(camp: Campaign, r: Dictionary) -> void:
	var pid: String = r["part"]
	var area_id := String(r.get("area", area_of_part(pid)))
	var size_id := String(r.get("size", "M"))
	var fx: Dictionary = r.get("fx", {})
	if fx.is_empty():
		fx = project_fx(camp, area_id, size_id)
	var b := band(camp, area_id)
	var ratio := _rng(camp, "proj|%s|%s" % [pid, size_id]).randf_range(float(b[0]), float(b[1]))
	var share := share_for(area_id)
	var real := {}
	var full := {}
	for k: String in fx:
		full[k] = float(fx[k]) * ratio
		real[k] = snappedf(float(full[k]) * (1.0 - share), 0.01)
	var on_car := unit_on(pid, 0)  # a versão nova soma em cima da que está no carro
	var base := spec(pid, int(on_car["spec"]) if not on_car.is_empty() else latest_spec(pid))
	var stacked := {}
	for k: String in TRAITS:
		var v := float((base.get("real", {}) as Dictionary).get(k, 0.0)) + float(real.get(k, 0.0))
		if v != 0.0:
			stacked[k] = snappedf(v, 0.01)
	var l := spec_list(pid)
	l.append({"v": letter(l.size()), "dir": area_id, "fx": stacked, "real": stacked, "outcome": "good", "revealed": true, "fixed": false})
	var si := l.size() - 1
	for u: Dictionary in units:  # atualização: as unidades da peça (carros e reservas) recebem a versão nova
		if u["part"] == pid:
			u["spec"] = si
	for q: Dictionary in queue:
		if q["part"] == pid:
			q["spec"] = si
	if share > 0.0:
		next_bank += fx_rating(full) * share * float(projects_cfg()["next_k"])
	var full_s := {}
	for k: String in full:
		full_s[k] = snappedf(float(full[k]), 0.01)
	var entry := {"area": area_id, "size": size_id, "part": pid, "v": letter(si), "expected": fx, "real": full_s, "now": real, "ratio": snappedf(ratio, 0.01),
		"share": share, "round": camp.round, "season": camp.season}
	deliveries.push_front(entry)
	while deliveries.size() > 30:
		deliveries.pop_back()
	if team_id == camp.player_team:
		done_research.append({"part": pid, "spec": si, "fix": false})
		camp.refresh_rating()

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
		if camp.budget_musd - cost < CarDevelopment.RESERVE_MUSD or not camp.cap_allows(cost):
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
		if camp.budget_musd - cost < CarDevelopment.RESERVE_MUSD or not camp.cap_allows(cost):
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


## Plano da preparação recomendada para uma pista: em cada peça, as melhores unidades disponíveis para cada carro
## (efeito conhecido, desgaste descontado; peça revelada ruim perde para a anterior). [{part, car, uid, spec}]
func prepare_plan(profile: Dictionary = NEUTRAL) -> Array:
	var plan: Array = []
	for pid: String in part_ids():
		var taken := {}
		for car in 2:
			var cur := unit_on(pid, car)
			var best := {}
			var best_v := _unit_value(cur, profile) + 0.05
			for u: Dictionary in stock(pid):
				if taken.has(int(u["uid"])):
					continue
				var v := _unit_value(u, profile)
				if v > best_v:
					best_v = v
					best = u
			if not best.is_empty():
				taken[int(best["uid"])] = true
				plan.append({"part": pid, "car": car, "uid": int(best["uid"]), "spec": int(best["spec"])})
	return plan


## Aplica a preparação recomendada. Devolve quantas trocas fez.
func auto_prepare(profile: Dictionary = NEUTRAL) -> int:
	var plan := prepare_plan(profile)
	for p: Dictionary in plan:
		install(int(p["uid"]), int(p["car"]))
	return plan.size()


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
			else:
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
# --- limite de motor e câmbio ----------------------------------------------------------------------------

func used_count(car: int, pid: String) -> int:
	return (used.get("%d|%s" % [car, pid], []) as Array).size()


## Punição de grid se o carro correr agora com as unidades instaladas: {places, back, parts: [{part, n}]}.
func penalty_for(car: int) -> Dictionary:
	var out := {"places": 0, "back": false, "parts": []}
	for pid: String in LIMITS:
		var u := unit_on(pid, car)
		if u.is_empty():
			continue
		var list: Array = used.get("%d|%s" % [car, pid], [])
		if list.has(int(u["uid"])):
			continue
		var n := list.size() + 1
		if n > int(LIMITS[pid]):
			out["places"] = int(out["places"]) + (int(PENALTY_FIRST[pid]) if n == int(LIMITS[pid]) + 1 else int(PENALTY_NEXT[pid]))
			out["parts"].append({"part": pid, "n": n})
	out["back"] = int(out["places"]) > BACK_OF_GRID
	return out


## Multiplicador de quebras pelo desgaste do motor e do câmbio do carro (1 = novo).
func worn_fail_mult(car: int) -> float:
	var m := 1.0
	for pid: String in LIMITS:
		var u := unit_on(pid, car)
		if not u.is_empty():
			m *= 1.0 + maxf(0.0, float(u["wear"]) - WORN_FAIL_FROM) / (100.0 - WORN_FAIL_FROM) * 0.8
	return m


func after_race(camp: Campaign) -> Array:
	for car in 2:  # motor e câmbio que correram entram na conta do limite
		for pid: String in LIMITS:
			var cu := unit_on(pid, car)
			var key := "%d|%s" % [car, pid]
			if not cu.is_empty():
				var list: Array = used.get(key, [])
				if not list.has(int(cu["uid"])):
					list.append(int(cu["uid"]))
				used[key] = list
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
		_replace_worn(camp)  # desde a v42 a equipe troca as peças gastas sozinha (jogador e IA)
	else:
		_ai_after_race(camp)
	return out


## Unidades gastas nos carros: usa uma reserva do estoque ou encomenda outra da melhor especificação.
func _replace_worn(camp: Campaign) -> void:
	for pid: String in part_ids():
		for car in 2:
			var u := unit_on(pid, car)
			var limit_wear := AI_REPLACE_WEAR
			if LIMITS.has(pid) and used_count(car, pid) >= int(LIMITS[pid]):
				limit_wear = LIMIT_REPLACE_WEAR  # no limite: estica a unidade para não tomar punição à toa
			if u.is_empty() or float(u["wear"]) < limit_wear or queued(pid).size() >= 2:
				continue
			var alt := best_stock_unit(pid)
			if not alt.is_empty() and float(alt["wear"]) < AI_REPLACE_WEAR:
				install(int(alt["uid"]), car)
			else:
				order_units(camp, pid, _ai_best_spec(pid), 1, [car])


# --- IA ---------------------------------------------------------------------------------------------

func _ai_staff_k(camp: Campaign) -> float:
	return camp.personnel.ai_dev_factor(camp, team_id) if camp.personnel != null and not camp.personnel.contracts.is_empty() else 1.0


## Valor de uma área para as próximas pistas, por dinheiro (a confiabilidade vale menos).
func _area_value(camp: Campaign, area_id: String, prof: Dictionary) -> float:
	var fx: Dictionary = area(area_id)["fx"]
	var v := fx_rating(fx, prof) + float(fx.get("rel", 0.0)) * 0.08
	return v / maxf(float(area(area_id)["cost"]), 0.1)


## Áreas livres ordenadas da mais útil para as próximas pistas à menos.
func ranked_areas(camp: Campaign) -> Array:
	var prof := camp.upcoming_profile(4)
	var ids: Array = areas().map(func(a: Dictionary) -> String: return String(a["id"])).filter(
		func(a: String) -> bool: return area_available(camp, a) and research_of(String(area(a)["part"])).is_empty())
	ids.sort_custom(func(a: String, b: String) -> bool: return _area_value(camp, a, prof) > _area_value(camp, b, prof))
	return ids


## Modo Essencial (jogador): o diretor técnico começa projetos médios (ou pequenos) nas áreas mais úteis, dentro da verba.
func auto_projects(camp: Campaign, budget: float) -> float:
	var spent := 0.0
	for area_id: String in ranked_areas(camp):
		for size_id: String in ["M", "S"]:  # médio; se a verba do mês não dá, um pequeno
			var info := project_info(camp, area_id, size_id)
			if not info["ok"]:
				if info["reason"] == "slots":
					return spent
				break
			if spent + float(info["cost"]) > budget:
				continue
			if start_project(camp, area_id, size_id):
				spent += float(info["cost"])
			break
	return spent


## IA: fatia para o carro do ano seguinte cresce no fim da temporada (como as equipes reais).
func _ai_share(camp: Campaign) -> float:
	return 0.15 if camp.season_progress() < 0.6 else 0.5


func _ai_plan(camp: Campaign) -> void:
	if not research.is_empty():
		return
	var ranked := ranked_areas(camp)
	if ranked.is_empty():
		return
	var rng := _rng(camp, "ai_proj|%d" % ai_cursor)
	ai_cursor += 1
	var pick: String = ranked[0] if rng.randf() < 0.6 or ranked.size() < 2 else ranked[1 + rng.randi() % mini(2, ranked.size() - 1)]
	var roll := rng.randf()
	var size_id := "S" if roll < 0.25 else ("L" if roll > 0.75 else "M")
	next_share = _ai_share(camp)
	start_project(camp, pick, size_id)


func _ai_after_race(camp: Campaign) -> void:
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
	next_bank = 0.0


# --- salvar / carregar ---------------------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"team": team_id, "specs": specs, "units": units, "research": research, "queue": queue, "reveals": reveals,
		"done_research": done_research, "next_uid": next_uid, "ai_cursor": ai_cursor, "gain_k": gain_k, "used": used,
		"deliveries": deliveries, "next_share": next_share, "next_bank": next_bank}


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
	c.used = d.get("used", {})
	c.deliveries = d.get("deliveries", [])
	for e: Dictionary in c.deliveries:
		e["round"] = int(e.get("round", 0))
		e["season"] = int(e.get("season", 0))
	c.next_share = float(d.get("next_share", 0.0))
	c.next_bank = float(d.get("next_bank", 0.0))
	for k: String in c.used:
		c.used[k] = (c.used[k] as Array).map(func(x: Variant) -> int: return int(x))
	return c
