class_name DriverCareer
extends RefCounted
## Carreira dos pilotos na campanha (decisão do usuário, 2026-11-04): aposentadoria entre 32 e 47 anos, com média
## de 36–37 (craques duram mais, os mais fracos param antes, exceções possíveis); evolução de quem ainda não tem
## atributos detalhados (base F2/F3 e outras categorias); e pilotos novos FICTÍCIOS (regens) entrando na F3 todo ano.
## Tudo determinístico pela semente da campanha e pelo ano.

const RETIRE_MIN := 32
const RETIRE_MAX := 47
## Chance de anunciar a aposentadoria ao fim da temporada, por idade (média medida na campanha ≈ 36–37 anos, com contratos e craques; tools: ret.gd).
const HAZARD := {32: 0.08, 33: 0.14, 34: 0.21, 35: 0.28, 36: 0.34, 37: 0.37, 38: 0.40, 39: 0.42, 40: 0.44, 41: 0.46,
	42: 0.48, 43: 0.50, 44: 0.52, 45: 0.56, 46: 0.65}
const STAR_RATING := 88  ## craques: risco × 0,55 (param mais tarde)
const WEAK_RATING := 76  ## fracos: risco × 1,4
const NO_SEAT_MULT := 1.8  ## sem vaga em equipe nenhuma: desiste mais cedo
const UNDER_CONTRACT_MULT := 0.4  ## com contrato para o ano seguinte: raramente para no meio

const F2_SIZE := 20
const F3_SIZE := 27
const PROMOTE_F3 := 6  ## melhores da F3 sobem para a F2 a cada ano (se houver vaga)
const F2_MAX_YEARS_AGE := 26  ## na F2 depois dos 26 sem subir: vira agente livre (sai da base)

static var _names: Dictionary = {}


static func birth_year(d: Dictionary) -> int:
	var b := String(d.get("birth", ""))
	return int(b.left(4)) if b.length() >= 4 else 0


static func age_in(d: Dictionary, year: int) -> int:
	var y := birth_year(d)
	return year - y if y > 0 else 0


## Chance de aposentar ao fim do ano `year` (idade já completada no ano).
static func retire_chance(d: Dictionary, year: int, has_seat: bool, under_contract: bool) -> float:
	var a := age_in(d, year)
	if a < RETIRE_MIN:
		return 0.0
	if a >= RETIRE_MAX:
		return 1.0
	var h: float = HAZARD.get(a, 0.6)
	var r := int(d.get("rating", 75))
	if r >= STAR_RATING:
		h *= 0.55
	elif r <= WEAK_RATING:
		h *= 1.4
	if not has_seat:
		h *= NO_SEAT_MULT
	if under_contract:
		h *= UNDER_CONTRACT_MULT
	return clampf(h, 0.0, 1.0)


static func roll(seed_text: String) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_text)
	return rng.randf()


## Evolução anual de quem só tem nota geral (base e outras categorias): jovens sobem em direção ao potencial,
## veteranos caem. Devolve a variação aplicada.
static func evolve_prospect(d: Dictionary, next_year: int, seed_value: int) -> int:
	var a := age_in(d, next_year)
	if a <= 0:
		return 0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("prospect|%s|%d|%d" % [d["id"], next_year, seed_value])
	var r := int(d.get("rating", 60))
	var pot := int(d.get("potential", r))
	var delta := 0
	if a <= 27:
		delta = clampi(roundi((pot - r) * 0.28 + rng.randf_range(-1.5, 2.0)), -1, 8)
	elif a >= 34:
		delta = -clampi(roundi((a - 33) * 0.6 + rng.randf_range(0.0, 1.0)), 0, 4)
	d["rating"] = clampi(r + delta, 35, 95)
	return delta


## Piloto novo fictício (16–18 anos) para a F3. used = nomes já usados (não repete).
static func make_regen(year: int, index: int, seed_value: int, used: Dictionary) -> Dictionary:
	if _names.is_empty():
		_names = GameData.load_json(GameData.DATA_DIR + "name_pool.json")["nationalities"]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("regen|%d|%d|%d" % [year, index, seed_value])
	var nats: Array = _names.keys()
	var name := ""
	var nat := ""
	for attempt in 30:
		nat = nats[rng.randi() % nats.size()]
		var pool: Dictionary = _names[nat]
		name = "%s %s" % [pool["first"][rng.randi() % pool["first"].size()], pool["last"][rng.randi() % pool["last"].size()]]
		if not used.has(name):
			break
	used[name] = true
	var age := rng.randi_range(16, 18)
	var rating := rng.randi_range(46, 60)
	# potencial: a maioria fica no meio do pelotão; de vez em quando surge uma joia
	var pot := rating + rng.randi_range(12, 26)
	if rng.randf() < 0.08:
		pot = rng.randi_range(88, 96)
	var id := "regen_%d_%d_%s" % [year, index, name.to_lower().replace(" ", "_").replace("'", "")]
	return {"id": id, "name": name, "nationality": nat, "category": "F3", "rating": rating, "potential": mini(pot, 96),
		"birth": "%d-01-01" % (year - age), "regen": true, "series_team": ""}
