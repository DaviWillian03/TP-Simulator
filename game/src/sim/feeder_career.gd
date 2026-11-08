class_name FeederCareer
extends RefCounted
## Campanha na F2/F3 (decisões de 2026-11-08, mockup v23-3): a equipe do jogador numa categoria de base. Sem tela.
## - Carro: chassi igual para todos; a diferença é o NÍVEL DE OPERAÇÃO (engenharia, mecânicos e simulador, 1 a 4).
##   Engenharia → ritmo; mecânicos → confiabilidade e paradas; simulador → ganho do treino.
## - Dinheiro: PILOTOS PAGANTES (quanto melhor o piloto, menos traz) + patrocínio pequeno; custo por etapa e salários.
## - Pessoal enxuto: chefe de engenharia + 1 engenheiro de corrida por carro (nomes genéricos), com mercado próprio.
## Valores PROVISÓRIOS.

const AREAS := ["eng", "mech", "sim"]
const AREA_NAMES := {"eng": "Engenharia", "mech": "Mecânicos", "sim": "Simulador"}
const AREA_DESC := {"eng": "acerto e ritmo do carro", "mech": "paradas e confiabilidade", "sim": "treino e classificação"}
const MAX_LEVEL := 4
const RATING_PER_LEVEL := {"eng": 0.45, "mech": 0.25, "sim": 0.3}  ## pontos de nota do carro por nível acima do 1
## Economia por categoria (US$ mi). entry_up = verba de entrada ao SUBIR desta categoria para a de cima.
const ECON := {
	"F2": {"cash": 4.8, "sponsor_year": 1.6, "cost_round": 0.35, "upgrade": [0.4, 0.6, 0.9], "salary": 0.12, "entry_up": 45.0, "prize_top": 1.2},
	"F3": {"cash": 2.2, "sponsor_year": 0.7, "cost_round": 0.2, "upgrade": [0.2, 0.3, 0.45], "salary": 0.06, "entry_up": 3.0, "prize_top": 0.5},
}

var cat := "F2"
var team_id := ""
var levels: Dictionary = {"eng": 1, "mech": 1, "sim": 1}
var base_rating := 59.0  ## nota do carro com tudo no nível 1
var cash := 0.0
var staff: Dictionary = {}  ## "chief"/"eng1"/"eng2"/"eng3" -> {name, nationality, skill, salary}
var log: Array = []  ## notícias curtas da equipe


static func make(category: String, team: Dictionary, teams: Array) -> FeederCareer:
	var f := FeederCareer.new()
	f.cat = category
	f.team_id = String(team["id"])
	f.levels = CategoryRules.operation_levels(team, teams)
	f.base_rating = float(team["car_rating"]) - f.level_bonus()
	f.cash = float(ECON[category]["cash"])
	f._hire_initial()
	return f


func econ() -> Dictionary:
	return ECON[cat]


func seats() -> int:
	return 3 if cat == "F3" else 2


func level_bonus() -> float:
	var b := 0.0
	for a: String in AREAS:
		b += (int(levels[a]) - 1) * float(RATING_PER_LEVEL[a])
	return b


## Nota do carro da equipe (vai para o Series e para o fim de semana).
func car_rating() -> float:
	return base_rating + level_bonus()


## Nota de operação mostrada (60-85 dentro da categoria).
func operation_score(teams: Array) -> int:
	var t := {"id": team_id, "car_rating": car_rating()}
	var list := teams.duplicate(true)
	for x: Dictionary in list:
		if x["id"] == team_id:
			x["car_rating"] = car_rating()
	return CategoryRules.operation_score(t, list)


func upgrade_cost(area: String) -> float:
	var lv := int(levels[area])
	if lv >= MAX_LEVEL:
		return -1.0
	return float(econ()["upgrade"][lv - 1])


## Sobe um nível de operação. Devolve o texto do resultado ("" se não deu).
func upgrade(area: String) -> String:
	var cost := upgrade_cost(area)
	if cost < 0.0 or cash < cost:
		return ""
	cash -= cost
	levels[area] = int(levels[area]) + 1
	var msg := "%s sobe para o nível %d (US$ %s mi)." % [AREA_NAMES[area], int(levels[area]), _m(cost)]
	log.append(msg)
	return msg


## Efeitos no fim de semana: confiabilidade (mecânicos) e ganho do treino (simulador).
func team_effects() -> Dictionary:
	return {"failure_mult": 1.1 - 0.06 * (int(levels["mech"]) - 1), "practice_gain_mult": 1.0 + 0.08 * (int(levels["sim"]) - 1)}


# --- dinheiro -----------------------------------------------------------------------------------

## Quanto os pilotos da equipe trazem por ano (pilotos pagantes).
func pay_income_year(drivers: Array) -> float:
	var total := 0.0
	for d: Dictionary in drivers:
		total += CategoryRules.pay_musd(cat, float(d.get("rating", 60)))
	return total


func payroll_year() -> float:
	var t := 0.0
	for k: String in staff:
		t += float(staff[k]["salary"])
	return t


## Contas de uma etapa: entradas (patrocínio + pilotos pagantes, divididos pelas etapas) menos custo e salários.
func round_balance(drivers: Array, rounds_in_year: int) -> float:
	var n := maxf(float(rounds_in_year), 1.0)
	return (float(econ()["sponsor_year"]) + pay_income_year(drivers) - payroll_year()) / n - float(econ()["cost_round"])


func settle_round(drivers: Array, rounds_in_year: int) -> float:
	var b := round_balance(drivers, rounds_in_year)
	cash += b
	return b


## Prêmio de fim de ano pela posição nas equipes.
func prize_for(position: int) -> float:
	return snappedf(float(econ()["prize_top"]) * clampf(1.0 - (position - 1) * 0.1, 0.0, 1.0), 0.05)


# --- pessoal --------------------------------------------------------------------------------------

func staff_roles() -> Array:
	var r := ["chief"]
	for i in seats():
		r.append("eng%d" % (i + 1))
	return r


static func role_name(role: String) -> String:
	return "chefe de engenharia" if role == "chief" else "engenheiro de corrida"


func _hire_initial() -> void:
	for role: String in staff_roles():
		var p := Personnel.generic_person("%s|%s|%s" % [cat, team_id, role])
		p["salary"] = salary_for(int(p["skill"]))
		staff[role] = p


func salary_for(skill: int) -> float:
	return snappedf(float(econ()["salary"]) * (0.6 + (skill - 55) * 0.04), 0.01)


## Candidatos do mercado próprio para um cargo (3 por temporada, fixos).
func candidates(role: String, season: int) -> Array:
	var out: Array = []
	for i in 3:
		var p := Personnel.generic_person("cand|%s|%s|%d|%d" % [cat, role, season, i])
		p["skill"] = int(p["skill"]) + 4 * i  # um mais barato, um médio e um melhor
		p["salary"] = salary_for(int(p["skill"]))
		p["fee"] = snappedf(float(p["salary"]) * 0.5, 0.01)
		out.append(p)
	return out


## Contrata um candidato no lugar de quem ocupa o cargo (paga uma taxa de metade do salário anual).
func hire(role: String, p: Dictionary) -> bool:
	var fee := float(p.get("fee", 0.0))
	if cash < fee:
		return false
	cash -= fee
	staff[role] = {"name": p["name"], "nationality": p.get("nationality", ""), "skill": int(p["skill"]), "salary": float(p["salary"])}
	log.append("%s contratado como %s." % [p["name"], role_name(role)])
	return true


## Habilidades do treino (diretor = chefe de engenharia; engenheiro do carro) por piloto.
func practice_skills(driver_ids: Array) -> Dictionary:
	var out := {}
	var chief: Dictionary = staff.get("chief", {})
	for i in driver_ids.size():
		var e: Dictionary = staff.get("eng%d" % (i + 1), {})
		out[driver_ids[i]] = {"director": float(chief.get("skill", 55)), "engineer": float(e.get("skill", 55)),
			"engineer_name": String(e.get("name", "")), "director_name": String(chief.get("name", ""))}
	return out


# --- salvar ---------------------------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"cat": cat, "team_id": team_id, "levels": levels, "base_rating": base_rating, "cash": cash, "staff": staff, "log": log}


static func from_dict(d: Dictionary) -> FeederCareer:
	var f := FeederCareer.new()
	f.cat = String(d.get("cat", "F2"))
	f.team_id = String(d.get("team_id", ""))
	for a: String in AREAS:
		f.levels[a] = int((d.get("levels", {}) as Dictionary).get(a, 1))
	f.base_rating = float(d.get("base_rating", 59.0))
	f.cash = float(d.get("cash", 0.0))
	f.staff = d.get("staff", {})
	for k: String in f.staff:
		f.staff[k]["skill"] = int(f.staff[k]["skill"])
		f.staff[k]["salary"] = float(f.staff[k]["salary"])
	f.log = d.get("log", [])
	return f


static func _m(v: float) -> String:
	return String.num(v, 1).replace(".", ",")
