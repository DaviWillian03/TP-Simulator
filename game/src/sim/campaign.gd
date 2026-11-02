class_name Campaign
extends RefCounted
## Campanha: a equipe do jogador (real ou criada), o grid da temporada e as condições iniciais.
## Sem dependência de tela. Salva/carrega em user://campaign.json (dicionário simples).
##
## Equipe criada = 12ª equipe do grid (24 carros), com pilotos reais da F2/F3 (decisão do
## usuário). Os valores das origens vêm de data/campaign_origins.json (PROVISÓRIOS).

const SAVE_PATH := "user://campaign.json"
const CUSTOM_ID := "custom"

var mode := "real"  ## "real" ou "created"
var season := 2026
var player_team := ""
var origin: Dictionary = {}
var identity: Dictionary = {}  ## equipe criada: name, short, color, color2, shape, country
var engine := ""  ## fornecedor ou "own"
var objective: Dictionary = {}  ## {id, seasons?}
var detail := "essential"  ## "essential" ou "advanced"
var ai_difficulty := "normal"  ## "easy", "normal", "hard"
var budget_musd := 0.0
var debt_musd := 0.0
var factory_level := 0
var morale := 3
var board_patience := 3
var driver_ids: Array[String] = []  ## pilotos da equipe criada (da base F2/F3)
var round := 0  ## próxima rodada do calendário (0 = primeira)
var day := 0  ## dia atual da temporada (dias desde 1970-01-01)
var trust := 60.0  ## confiança da diretoria (0-100)
var state := "active"  ## "active", "fired" ou "bankrupt"
var wins: Dictionary = {}  ## id do piloto -> vitórias na temporada
var best_finish := 99  ## melhor chegada da equipe na temporada
var seasons: Array = []  ## relatórios das temporadas encerradas
var goal_shift := 0  ## ajuste acumulado da meta da diretoria (negativo = mais exigente)
var driver_points: Dictionary = {}  ## id do piloto -> pontos na temporada
var team_points: Dictionary = {}  ## id da equipe -> pontos na temporada
var history: Array = []  ## [{round, circuit, results: [ids]}]

var dev := CarDevelopment.new()  ## árvore de P&D e fábrica
var personnel := Personnel.new()  ## contratos de pilotos e técnicos
var sponsors := Sponsorship.new()  ## patrocínios por zona do carro
var regs := Regulations.new()  ## regulamento e Conselho de regras
var events := CampaignEvents.new()  ## eventos inesperados
var ledger: Dictionary = {}  ## categoria -> total da temporada (US$ mi): sponsors, bonus, prize, ops, payroll, upkeep, rd, works, contracts, debt
var cash_log: Array = []  ## [{r: rodada, cash}] caixa depois de cada rodada
var base_rating := 0.0  ## nota do carro da equipe sem os upgrades
var rival_carry: Dictionary = {}  ## id da equipe da IA -> bônus herdado das temporadas anteriores
var _file_ratings: Dictionary = {}  ## id -> nota do carro nos dados (sem evolução)
var _teams: Array = []
var _drivers: Array = []


static func origins_data() -> Dictionary:
	return GameData.load_json(GameData.DATA_DIR + "campaign_origins.json")


static func feeder_drivers() -> Array:
	return GameData.load_json(GameData.DATA_DIR + "drivers_feeder_2026.json")["drivers"]


static func origin_by_id(id: String) -> Dictionary:
	for o: Dictionary in origins_data()["origins"]:
		if o["id"] == id:
			return o
	return {}


## Assumir uma das 11 equipes reais.
static func new_real(team_id: String, options: Dictionary = {}) -> Campaign:
	var c := Campaign.new()
	c.mode = "real"
	c.player_team = team_id
	c.ai_difficulty = options.get("ai_difficulty", "normal")
	c.detail = options.get("detail", "essential")
	c.objective = {"id": "board"}
	c.budget_musd = 140.0  # PROVISÓRIO: orçamento padrão das equipes reais até a camada de finanças
	c.factory_level = 3
	c._build_grid()
	c._init_dev(3)
	c.board_patience = clampi(1 + int((c.rating_rank(team_id) - 1) / 3.0), 1, 5)
	c.trust = c._start_trust()
	c.day = c._season_start_day()
	return c


## Criar a própria equipe. spec: origin, name, short, color, color2, shape, country, engine
## ("own" ou fornecedor), objective {id, seasons}, detail, ai_difficulty, drivers [id, id].
static func new_created(spec: Dictionary) -> Campaign:
	var c := Campaign.new()
	c.mode = "created"
	c.player_team = CUSTOM_ID
	c.origin = origin_by_id(spec.get("origin", "garage"))
	c.identity = {"name": spec.get("name", "Nova Equipe"), "short": String(spec.get("short", "NOV")).to_upper().left(3),
		"color": spec.get("color", "#0E7C66"), "color2": spec.get("color2", "#F2A900"), "shape": spec.get("shape", "hex"),
		"country": spec.get("country", "Brasil")}
	c.engine = "own" if c.origin.get("own_engine", false) else String(spec.get("engine", "Mercedes"))
	c.objective = spec.get("objective", {"id": "survive"})
	c.detail = spec.get("detail", "essential")
	c.ai_difficulty = spec.get("ai_difficulty", "normal")
	c.budget_musd = float(c.origin.get("budget_musd", 50))
	c.debt_musd = float(c.origin.get("debt_musd", 0))
	c.factory_level = int(c.origin.get("factory_level", 1))
	c.morale = int(c.origin.get("morale", 3))
	c.board_patience = int(c.origin.get("board_patience", 3))
	c.driver_ids.assign(spec.get("drivers", []))
	c._build_grid()
	c._init_dev(c.factory_level)
	c.trust = c._start_trust()
	c.day = c._season_start_day()
	return c


## Equipes e pilotos da temporada (11 reais + a criada, se houver), no formato dos dados do jogo.
func teams() -> Array:
	return _teams


func drivers() -> Array:
	return _drivers


func team() -> Dictionary:
	return GameData.team_by_id(_teams, player_team)


## Equipe com motor próprio (desenvolve o departamento Motor).
func has_own_engine() -> bool:
	if mode == "created":
		return engine == "own"
	return CarDevelopment.factory_data()["own_engine_teams"].has(player_team)


func sync_factory_level() -> void:
	factory_level = dev.overall_level()


## Nota do carro = base + upgrades; também publica a confiabilidade e o ganho dos treinos na equipe.
func refresh_rating() -> void:
	for t: Dictionary in _teams:
		if t["id"] == player_team:
			t["car_rating"] = base_rating + dev.rating_bonus()
			t["failure_mult"] = dev.failure_mult()
			t["practice_gain_mult"] = dev.practice_gain_mult()
			dev.staff_mod = personnel.staff_effects(self)
		else:  # equipes da IA também desenvolvem o carro ao longo da temporada
			t["car_rating"] = float(_file_ratings.get(t["id"], t["car_rating"])) + float(rival_carry.get(t["id"], 0.0)) + rival_gain(t["id"])


## Quanto da temporada já passou (0 = véspera da primeira rodada, 1 = depois da última).
func season_progress() -> float:
	var start := _season_start_day()
	var end_day := _day_of(calendar()[calendar().size() - 1]["date"]) + 1
	return clampf(float(day - start) / maxf(float(end_day - start), 1.0), 0.0, 1.0)


## Ganho total que a equipe da IA consegue na temporada: mais para quem tem mais estrutura
## (carro melhor), com a sorte de cada ano e o fator da dificuldade.
func rival_potential(team_id: String) -> float:
	var cfg: Dictionary = origins_data()["rivals"]
	var order: Array = _teams.map(func(t: Dictionary) -> float: return float(_file_ratings.get(t["id"], t["car_rating"])) + float(rival_carry.get(t["id"], 0.0)))
	order.sort()
	order.reverse()
	var mine := float(_file_ratings.get(team_id, 0.0)) + float(rival_carry.get(team_id, 0.0))
	var rank := order.find(mine)
	var rank_factor := 1.0 + float(cfg["rank_spread"]) * (0.5 - float(rank) / maxf(order.size() - 1, 1))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d|%s" % [season, team_id])
	var luck := rng.randf_range(float(cfg["luck_min"]), float(cfg["luck_max"]))
	return float(cfg["yearly_gain"][ai_difficulty]) * rank_factor * luck


func rival_gain(team_id: String) -> float:
	return rival_potential(team_id) * season_progress()


func _init_rivals() -> void:
	_file_ratings.clear()
	for t: Dictionary in _teams:
		_file_ratings[t["id"]] = float(t["car_rating"])


func _init_dev(initial_level: int) -> void:
	_init_rivals()
	dev = CarDevelopment.new()
	personnel = Personnel.new()
	sponsors = Sponsorship.new()
	regs = Regulations.new()
	regs.setup()
	events = CampaignEvents.new()
	ledger = {}
	dev.set_all_levels(initial_level)
	dev.seed_base = season
	base_rating = float(team().get("car_rating", 75))
	personnel.setup(self)
	sync_factory_level()
	sponsors.setup(self, _base_sponsor_target())
	cash_log = [{"r": 0, "cash": budget_musd}]
	refresh_rating()


## Patrocínio base por corrida da origem (real: padrão; criada: da origem). Os contratos iniciais somam isto.
func _base_sponsor_target() -> float:
	return float(origin.get("sponsor_per_race_musd", 2.0)) if mode == "created" else float(origins_data()["finance"]["sponsor_default"])


## Lança um valor no livro-caixa da temporada (positivo = quantia da categoria; devoluções entram negativas).
func record(category: String, amount: float) -> void:
	ledger[category] = float(ledger.get(category, 0.0)) + amount


func income_total() -> float:
	return float(ledger.get("sponsors", 0.0)) + float(ledger.get("bonus", 0.0)) + float(ledger.get("prize", 0.0)) + float(ledger.get("events_in", 0.0))


func expense_total() -> float:
	var t := 0.0
	for k: String in ["ops", "payroll", "upkeep", "rd", "works", "contracts", "events", "debt"]:
		t += float(ledger.get(k, 0.0))
	return t


## Caixa esperado no fim da temporada: receitas e custos fixos das rodadas que faltam + prêmio da posição atual.
func projected_cash_end() -> float:
	var left := maxi(calendar().size() - round, 0)
	var pool: Array = origins_data()["finance"]["prize_pool"]
	var prize := float(pool[mini(team_position(player_team), pool.size()) - 1])
	return budget_musd + left * (sponsor_per_race() - cost_per_race()) + prize


func _dev_tick(n: int, last_day: int = -1) -> void:
	if n > 0:
		var end_day := day if last_day < 0 else last_day
		for i in n:
			events.tick_day(self, end_day - n + 1 + i)
		dev.tick(self, n)
		refresh_rating()
		_skip_cancelled()


## Rodadas canceladas por eventos são puladas: não há fim de semana, pontos nem patrocínio.
func _skip_cancelled() -> void:
	var n := calendar().size()
	while round < n and events.cancelled.has(round):
		round += 1


func is_valid() -> bool:
	return mode == "real" or (driver_ids.size() == 2 and driver_ids[0] != driver_ids[1])


func _build_grid() -> void:
	_teams = GameData.teams().duplicate(true)
	_drivers = GameData.drivers().duplicate(true)
	if mode != "created":
		return
	_teams.append({"id": CUSTOM_ID, "name": identity["name"], "short_name": identity["short"],
		"color": identity["color"], "color2": identity["color2"],
		"car_rating": int(origin.get("car_rating", 75)),
		"power_unit": identity.get("short", "") + " (próprio)" if engine == "own" else engine,
		"custom": true, "shape": identity["shape"], "country": identity["country"]})
	var used: Array = []
	for d: Dictionary in _drivers:
		used.append(int(d["number"]))
	var number := 2
	for id in driver_ids:
		for f: Dictionary in feeder_drivers():
			if f["id"] == id:
				while used.has(number):
					number += 1
				used.append(number)
				_drivers.append({"id": f["id"], "name": f["name"], "code": driver_code(f["name"]), "number": number,
					"nationality": f["nationality"], "team": CUSTOM_ID, "rating": int(f["rating"]), "from": f["category"]})


## Sigla de 3 letras pelo sobrenome, sem acentos (ex.: "Rafael Câmara" -> "CAM").
static func driver_code(full_name: String) -> String:
	var last := full_name.get_slice(" ", full_name.get_slice_count(" ") - 1)
	var plain := ""
	var map := {"á": "a", "à": "a", "â": "a", "ã": "a", "é": "e", "ê": "e", "í": "i", "ó": "o", "ô": "o", "õ": "o",
		"ú": "u", "ü": "u", "ç": "c", "ø": "o", "ł": "l", "ń": "n", "š": "s", "ž": "z", "ö": "o", "ä": "a", "ō": "o", "ū": "u"}
	for ch in last.to_lower():
		plain += map.get(ch, ch)
	return plain.left(3).to_upper()


# --- salvar / carregar ------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"version": 1, "mode": mode, "season": season, "player_team": player_team, "origin": origin.get("id", ""),
		"identity": identity, "engine": engine, "objective": objective, "detail": detail, "ai_difficulty": ai_difficulty,
		"budget_musd": budget_musd, "debt_musd": debt_musd, "factory_level": factory_level, "morale": morale,
		"board_patience": board_patience, "drivers": driver_ids, "round": round, "driver_points": driver_points,
		"team_points": team_points, "history": history, "day": day, "trust": trust, "state": state, "wins": wins,
		"best_finish": best_finish, "seasons": seasons, "goal_shift": goal_shift, "dev": dev.to_dict(), "rival_carry": rival_carry, "personnel": personnel.to_dict(), "drivers_grid": _drivers, "sponsors": sponsors.to_dict(), "ledger": ledger, "cash_log": cash_log, "regs": regs.to_dict(), "events": events.to_dict()}


static func from_dict(d: Dictionary) -> Campaign:
	var c := Campaign.new()
	c.mode = d.get("mode", "real")
	c.season = int(d.get("season", 2026))
	c.player_team = d.get("player_team", "")
	c.origin = origin_by_id(d.get("origin", ""))
	c.identity = d.get("identity", {})
	c.engine = d.get("engine", "")
	c.objective = d.get("objective", {})
	c.detail = d.get("detail", "essential")
	c.ai_difficulty = d.get("ai_difficulty", "normal")
	c.budget_musd = float(d.get("budget_musd", 0))
	c.debt_musd = float(d.get("debt_musd", 0))
	c.factory_level = int(d.get("factory_level", 0))
	c.morale = int(d.get("morale", 3))
	c.board_patience = int(d.get("board_patience", 3))
	c.driver_ids.assign(d.get("drivers", []))
	c.round = int(d.get("round", 0))
	c.driver_points = d.get("driver_points", {})
	c.team_points = d.get("team_points", {})
	c.history = d.get("history", [])
	c.wins = d.get("wins", {})
	c.best_finish = int(d.get("best_finish", 99))
	c.seasons = d.get("seasons", [])
	c.state = d.get("state", "active")
	c.goal_shift = int(d.get("goal_shift", 0))
	c._build_grid()
	c.rival_carry = d.get("rival_carry", {})
	c._init_dev(maxi(1, c.factory_level))
	if d.has("drivers_grid"):  # grid de pilotos como ficou após as viradas (contratos)
		c._drivers = d["drivers_grid"]
		for dr: Dictionary in c._drivers:
			dr["number"] = int(dr["number"])
			dr["rating"] = int(dr["rating"])
	if d.has("personnel"):
		c.personnel = Personnel.from_dict(d["personnel"])
	if d.has("sponsors"):
		c.sponsors = Sponsorship.from_dict(d["sponsors"])
	if d.has("regs"):
		c.regs = Regulations.from_dict(d["regs"])
	if d.has("events"):
		c.events = CampaignEvents.from_dict(d["events"])
	c.ledger = d.get("ledger", {})
	if d.has("cash_log"):
		c.cash_log = d["cash_log"]
	if d.has("dev"):
		c.dev = CarDevelopment.from_dict(d["dev"])
		c.sync_factory_level()
		c.refresh_rating()
	c.trust = float(d.get("trust", c._start_trust()))
	c.day = int(d.get("day", c._season_start_day()))
	c.refresh_rating()
	return c


func save(path: String = SAVE_PATH) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(to_dict(), " "))
	return true


static func load_saved(path: String = SAVE_PATH) -> Campaign:
	if not FileAccess.file_exists(path):
		return null
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return from_dict(d) if d is Dictionary else null


# --- temporada ------------------------------------------------------------------------

static func calendar() -> Array:
	return GameData.load_json(GameData.DATA_DIR + "calendar_2026.json")["rounds"]


func season_over() -> bool:
	return round >= calendar().size()


func next_round() -> Dictionary:
	return {} if season_over() else calendar()[round]


## Opções do fim de semana da próxima rodada (grid da campanha).
func weekend_options(extra: Dictionary = {}) -> Dictionary:
	var o := {"player_team": player_team, "teams": _teams, "drivers": _drivers, "seed": season * 100 + round + 1, "campaign": true,
		"points_race": regs.points_race, "points_sprint": regs.points_sprint, "min_dry_compounds": regs.min_dry_compounds}
	if not season_over():
		o["sprint"] = regs.is_sprint(next_round()["id"])
	o.merge(extra, true)
	return o


## Soma os pontos de um fim de semana concluído, paga as contas da rodada, ajusta a confiança da
## diretoria e avança para a próxima rodada (o dia vai para o dia seguinte à corrida).
func record_weekend(w: WeekendSim) -> void:
	for id: String in w.points:
		var pts := int(w.points[id])
		driver_points[id] = int(driver_points.get(id, 0)) + pts
		var team_id := team_of(id)
		team_points[team_id] = int(team_points.get(team_id, 0)) + pts
	var race: Array = w.results.get("race", [])
	if not race.is_empty():
		wins[race[0]] = int(wins.get(race[0], 0)) + 1
		for i in race.size():
			if team_of(race[i]) == player_team:
				best_finish = mini(best_finish, i + 1)
				break
	history.append({"round": round + 1, "circuit": w.circuit.get("id", ""), "results": race})
	var podiums := 0
	for i in mini(3, race.size()):
		if team_of(race[i]) == player_team:
			podiums += 1
	var bonus := podiums * sponsors.bonus_per_podium()
	var f: Dictionary = origins_data()["finance"]
	record("sponsors", sponsor_per_race())
	record("bonus", bonus)
	record("ops", float(f["cost_base"]))
	record("payroll", personnel.payroll_per_race(self))
	record("upkeep", dev.upkeep_per_race())
	budget_musd += sponsor_per_race() + bonus - cost_per_race()
	var pos := team_position(player_team)
	var gap := season_goal() - pos  # >= 0: dentro da meta
	var drift: float = origins_data()["board"]["drift_per_race"]
	trust = clampf(trust + (drift if gap >= 0 else float(gap) * drift * 0.5) * _difficulty_factor(), 0.0, 100.0)
	round += 1
	cash_log.append({"r": round, "cash": budget_musd})
	events.on_race_recorded(self)
	var new_day := _day_of(calendar()[round - 1]["date"]) + 1
	_dev_tick(new_day - day, new_day)
	day = new_day
	_skip_cancelled()
	if budget_musd < 0.0:
		state = "bankrupt"
	elif trust <= 0.0:
		state = "fired"


## Classificação de construtores: [[id da equipe, pontos], ...] (todas as equipes do grid).
func team_standings() -> Array:
	var rows: Array = []
	for t: Dictionary in _teams:
		rows.append([t["id"], int(team_points.get(t["id"], 0))])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1])
	return rows


func driver_standings() -> Array:
	var rows: Array = []
	for d: Dictionary in _drivers:
		rows.append([d["id"], int(driver_points.get(d["id"], 0))])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1])
	return rows


# --- dias e eventos ---------------------------------------------------------------------

static func _day_of(date: String) -> int:
	return int(floorf(Time.get_unix_time_from_datetime_string(date + "T00:00:00") / 86400.0))


func _season_start_day() -> int:
	return _day_of(calendar()[0]["date"]) - 7


## Dia em que o fim de semana da próxima rodada começa (sexta: 2 dias antes da corrida).
func event_start_day() -> int:
	return -1 if season_over() else _day_of(next_round()["date"]) - 2


func days_to_event() -> int:
	return maxi(0, event_start_day() - day)


func event_ready() -> bool:
	return not season_over() and day >= event_start_day()


## Avança n dias, sem passar do começo do próximo fim de semana. Devolve quantos dias passaram.
func advance_days(n: int) -> int:
	var target := day + n
	if not season_over():
		target = mini(target, event_start_day())
	var moved := maxi(0, target - day)
	day += moved
	_dev_tick(moved)
	return moved


func advance_to_event() -> int:
	return advance_days(days_to_event())


func date_text(d: int = -1) -> String:
	var dt := Time.get_datetime_dict_from_unix_time((day if d < 0 else d) * 86400)
	var wd: String = ["DOM", "SEG", "TER", "QUA", "QUI", "SEX", "SÁB"][int(dt["weekday"])]
	var m: String = ["", "JAN", "FEV", "MAR", "ABR", "MAI", "JUN", "JUL", "AGO", "SET", "OUT", "NOV", "DEZ"][int(dt["month"])]
	return "%s, %02d %s" % [wd, int(dt["day"]), m]


# --- diretoria, objetivo e finanças -----------------------------------------------------

func team_of(driver_id: String) -> String:
	for d: Dictionary in _drivers:
		if d["id"] == driver_id:
			return d["team"]
	return ""


## Posição (1..) da equipe no campeonato de construtores.
func team_position(team_id: String) -> int:
	var rows := team_standings()
	for i in rows.size():
		if rows[i][0] == team_id:
			return i + 1
	return rows.size()


## Posição da equipe por nota do carro (1 = o melhor carro).
func rating_rank(team_id: String) -> int:
	# nota "de base" (dados + herança): a meta da diretoria não muda no meio da temporada
	var rated := _teams.duplicate()
	var base_of := func(t: Dictionary) -> float: return float(_file_ratings.get(t["id"], t["car_rating"])) + float(rival_carry.get(t["id"], 0.0))
	rated.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return base_of.call(a) > base_of.call(b))
	for i in rated.size():
		if rated[i]["id"] == team_id:
			return i + 1
	return rated.size()


## Meta da diretoria: posição final mínima nos construtores.
func season_goal() -> int:
	if mode == "created":
		return maxi(1, int(origin.get("season_goal", 10)) + goal_shift)
	return maxi(1, rating_rank(player_team) + goal_shift)


func cost_per_race() -> float:
	var f: Dictionary = origins_data()["finance"]
	return float(f["cost_base"]) + dev.upkeep_per_race() + personnel.payroll_per_race(self)


func sponsor_per_race() -> float:
	return sponsors.per_race_total()


func _difficulty_factor() -> float:
	return float(origins_data()["board"]["difficulty"].get(ai_difficulty, 1.0))


func _start_trust() -> float:
	var b: Dictionary = origins_data()["board"]
	return float(b["start_base"]) + board_patience * float(b["start_per_patience"])


func trust_label() -> String:
	if trust < 20.0:
		return "Crítica"
	if trust < 40.0:
		return "Preocupada"
	if trust < 70.0:
		return "Satisfeita"
	return "Muito satisfeita"


## Encerra a temporada: premia pela posição final, paga a dívida, julga a meta.
## Devolve o relatório {verdict, position, points, best, goal, prize, ...}.
func close_season() -> Dictionary:
	var b: Dictionary = origins_data()["board"]
	var f: Dictionary = origins_data()["finance"]
	var pos := team_position(player_team)
	var pool: Array = f["prize_pool"]
	var prize := float(pool[mini(pos, pool.size()) - 1])
	budget_musd += prize
	record("prize", prize)
	var service := minf(debt_musd, float(f["debt_service_musd"]))
	debt_musd -= service
	budget_musd -= service
	record("debt", service)
	var goal := season_goal()
	var met := pos <= goal
	if met:
		trust = minf(100.0, trust + float(b["met_bonus"]))
	else:
		trust = clampf(trust - float(pos - goal) * (6 - board_patience) * float(b["fail_per_pos"]) * _difficulty_factor(), 0.0, 100.0)
	var verdict := "met" if met else "failed"
	if budget_musd < 0.0:
		state = "bankrupt"
		verdict = "bankrupt"
	elif trust <= 0.0:
		state = "fired"
		verdict = "fired"
	var report := {"season": season, "verdict": verdict, "position": pos, "goal": goal, "points": int(team_points.get(player_team, 0)),
		"best": best_finish, "prize": prize, "budget": budget_musd, "trust": trust, "next_goal": goal}
	if verdict == "met":
		goal_shift -= 1  # a diretoria sobe a meta (uma posição melhor), sem passar do 1º
		report["next_goal"] = season_goal()
	seasons.append(report)
	return report


## Começa a próxima temporada (mesmo grid: o mercado de pilotos chega na camada de contratos).
func start_next_season() -> void:
	events.reset_for_new_season(self)  # lesionados voltam ao carro e o calendário cancelado zera antes do mercado
	personnel.rollover(self)
	var council := regs.apply_passed(self)
	for msg: String in council:
		events._add(self, {"day": day, "cat": "calendar", "id": "council", "title": "CONSELHO DE REGRAS", "text": msg, "chips": []})
	for d: Dictionary in _drivers:  # jovens evoluem em direção ao potencial; veteranos perdem ritmo
		DriverStats.evolve(d, season + 1, 0)
	sponsors.expire(self)
	ledger = {}
	cash_log = [{"r": 0, "cash": budget_musd}]
	var cfg: Dictionary = origins_data()["rivals"]
	for t: Dictionary in _teams:  # a IA guarda parte do que desenvolveu neste ano
		if t["id"] != player_team:
			rival_carry[t["id"]] = (float(rival_carry.get(t["id"], 0.0)) + rival_potential(t["id"])) * float(cfg["carry"])
	season += 1
	round = 0
	driver_points = {}
	team_points = {}
	wins = {}
	history = []
	best_finish = 99
	dev.rollover()
	refresh_rating()
	day = _season_start_day()  # (calendário de 2027+ ainda repete as datas de 2026: PROVISÓRIO)


func objective_text() -> String:
	for o: Dictionary in origins_data()["objectives"]:
		if o["id"] == objective.get("id", ""):
			return String(o["name"]) % int(objective.get("seasons", o.get("seasons", 5))) if String(o["name"]).contains("%d") else String(o["name"])
	return "Metas da diretoria"
