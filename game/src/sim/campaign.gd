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
var livery: Livery  ## pintura, especiais, capacete e lançamento do carro (estúdio de design)
const COST_CAP_MUSD := 150.0  ## teto de gastos anual, igual para todas (PROVISÓRIO; decisão 2026-11-04: trava rígida)
const CAP_CATEGORIES := ["ops", "upkeep", "rd"]  ## o que conta no teto (salários, obras e juros ficam de fora)
const BANK_LIMIT_MUSD := 45.0
const BANK_TERMS := [[5, 0.04], [11, 0.08], [0, 0.15]]  ## [corridas, juros]; 0 = até o fim da temporada seguinte
const DEBT_TRUST_LIMIT := 40.0  ## dívida acima disso: −3 de confiança ao pedir
const ADVANCE_SHARE := 0.5  ## adiantamento: até 50% do patrocínio que ainda falta receber nesta temporada
const ATR_RANGE := [0.70, 1.15]  ## tempo de pesquisa aerodinâmica do 1º ao último do ano anterior
const PERMANENT_NUMBERS := {"norris": 4}  ## número de carreira de quem começa 2026 com o 1 (campeão de 2025)
const KEEP_SERIES_NUMBER_CHANCE := 0.5  ## novato: 50% mantém o número da categoria de base, 50% herda o de quem saiu
var freed_numbers: Array = []  ## números de quem saiu da F1 (mais recentes primeiro): novatos podem herdar
var series: Dictionary = {}  ## "F2"/"F3" -> Series (campeonatos de base correndo em paralelo; 3 categorias fase 1)
var moves: Dictionary = {}  ## acesso/rebaixamento decididos no fim do ano: {up_f1, down_f2, up_f2, down_f3}
const ENTRY_GRANT_MUSD := 60.0  ## verba de entrada de quem sobe para a F1 (só importa para o jogador; fase 2)
var loans: Array = []  ## banco: [{principal, total, per_race, races_left}]
var advance: Dictionary = {}  ## adiantamento: {amount, cut, races_left}
var last_positions: Dictionary = {}  ## id da equipe -> posição nos construtores do ano anterior (restrição de túnel)
var parts: Dictionary = {}  ## id da equipe -> CarParts (jogador e IA usam as mesmas regras)
var rival_carry: Dictionary = {}  ## id da equipe da IA -> bônus herdado das temporadas anteriores
var _file_ratings: Dictionary = {}  ## id -> nota do carro nos dados (sem evolução)
var _teams: Array = []
var _drivers: Array = []
var feeder: FeederCareer = null  ## campanha na F2/F3 (decisões de 2026-11-08); null = equipe na F1
const F1_ENTRY_MUSD := 45.0  ## verba de entrada de quem sobe da F2 para a F1 (decisão de 2026-11-08; PROVISÓRIO)
const AUTO_F1_NOISE_S := 0.45  ## F1 simulada com o jogador na base: sorte da corrida (s/volta de desvio no ritmo)
const AUTO_F1_DNF := 0.07


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


## Campanha na F2 ou F3 com uma equipe real da categoria (a F1 e a outra categoria correm simuladas).
static func new_feeder(team_id: String, options: Dictionary = {}) -> Campaign:
	var cat := GameData.category_of(team_id)
	var c := new_real(team_id, options)  # F1 completa (IA) + base; a equipe do jogador fica no campeonato da categoria
	var s: Series = c.series[cat]
	c.feeder = FeederCareer.make(cat, s.team(team_id), s.teams)
	c.budget_musd = 0.0
	c.trust = 60.0
	c.board_patience = 3
	c._sync_feeder_rating()
	c.catch_up()
	return c


func is_feeder() -> bool:
	return feeder != null


## Categoria em que a equipe do jogador corre.
func category() -> String:
	return feeder.cat if feeder != null else "F1"


func my_series() -> Series:
	return series.get(feeder.cat) if feeder != null else null


## Pilotos da equipe do jogador na categoria de base (dados da base, com nota).
func my_feeder_drivers() -> Array:
	if feeder == null:
		return []
	var out: Array = []
	for id: String in my_series().team_drivers(player_team):
		var p := _prospect(id)
		if not p.is_empty():
			out.append(p)
	return out


func _sync_feeder_rating() -> void:
	var t := my_series().team(player_team)
	if not t.is_empty():
		t["car_rating"] = feeder.car_rating()


func feeder_upgrade(area: String) -> String:
	var msg := feeder.upgrade(area)
	if msg != "":
		_sync_feeder_rating()
	return msg


## Etapas da categoria do jogador no calendário (índices da F1).
func feeder_rounds() -> Array:
	return my_series().rounds if feeder != null else []


## Na F2/F3, as rodadas em que a categoria do jogador não corre passam sozinhas (F1 e a outra base simuladas).
func catch_up() -> void:
	if feeder == null:
		return
	while not season_over() and not feeder_rounds().has(round):
		_auto_f1_round()


## Simula a rodada atual da F1 sem o jogador, de forma estatística e rápida (ritmo de carro e piloto como na corrida,
## mais sorte e abandonos), e registra os pontos. A corrida completa levaria segundos por rodada no celular.
func _auto_f1_round(skip_cat: String = "") -> void:
	var cid := String(next_round()["id"])
	var track := TrackModel.new(GameData.circuit(cid))
	var gp_teams := CarForm.apply(teams_for_gp(cid), cid, season * 100 + round, 1.0, CarParts.profile_of(GameData.circuit(cid)))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("autof1|%d|%d" % [season, round])
	var points := {}
	var results := {}
	for kind: String in (["sprint", "race"] if regs.is_sprint(cid) else ["race"]):
		var score := {}
		var out: Array = []
		for d: Dictionary in _drivers:
			var t := GameData.team_by_id(gp_teams, String(d["team"]))
			if t.is_empty():
				continue
			if rng.randf() < AUTO_F1_DNF * (0.5 if kind == "sprint" else 1.0):
				out.append(d["id"])
				continue
			score[d["id"]] = RaceSim.base_lap_time(track, t, d) + rng.randfn(0.0, AUTO_F1_NOISE_S)
		var order: Array = score.keys()
		order.sort_custom(func(a: String, b: String) -> bool: return float(score[a]) < float(score[b]))
		var table: Array = regs.points_sprint if kind == "sprint" else regs.points_race
		for i in order.size():
			if i < table.size():
				points[order[i]] = int(points.get(order[i], 0)) + int(table[i])
		results[kind] = order + out
	_record_auto_f1(points, results.get("race", []), cid, skip_cat)


func _record_auto_f1(points: Dictionary, race: Array, circuit_id: String, skip_cat: String) -> void:
	for id: String in points:
		driver_points[id] = int(driver_points.get(id, 0)) + int(points[id])
		var team_id := team_of(id)
		team_points[team_id] = int(team_points.get(team_id, 0)) + int(points[id])
	if not race.is_empty():
		wins[race[0]] = int(wins.get(race[0], 0)) + 1
	history.append({"round": round + 1, "circuit": circuit_id, "results": race})
	for cp: CarParts in parts.values():
		cp.after_race(self)
	_run_series(round, skip_cat)
	round += 1
	var nd := round_day(round - 1) + 1
	_dev_tick(nd - day, nd)
	day = nd
	_skip_cancelled()


## Opções do fim de semana da categoria de base do jogador: equipes e pilotos do campeonato atual.
func feeder_weekend_options(extra: Dictionary = {}) -> Dictionary:
	var s := my_series()
	var teams: Array = []
	for t: Dictionary in s.teams:
		var c := t.duplicate(true)
		c["category"] = feeder.cat
		if c["id"] == player_team:
			c.merge(feeder.team_effects(), true)
		teams.append(c)
	var drivers: Array = []
	var n := 1
	for t: Dictionary in teams:
		for id: String in s.team_drivers(t["id"]):
			var p := _prospect(id)
			if p.is_empty():
				continue
			drivers.append({"id": id, "name": p["name"], "code": driver_code(String(p["name"])), "number": n, "team": t["id"],
				"nationality": p.get("nationality", ""), "rating": int(p.get("rating", 60)), "birth": p.get("birth", ""), "category": feeder.cat})
			n += 1
	var mine: Array = drivers.filter(func(d: Dictionary) -> bool: return d["team"] == player_team).map(func(d: Dictionary) -> String: return d["id"])
	for t: Dictionary in teams:
		if t["id"] == player_team:
			t["practice_skills"] = feeder.practice_skills(mine)
	var o := {"category": feeder.cat, "teams": teams, "drivers": drivers, "player_team": player_team, "campaign": true,
		"seed": season * 100 + round + 1}
	o.merge(extra, true)
	return o


## Fim do fim de semana jogado na F2/F3: resultado no campeonato da categoria, contas da etapa, a F1 da mesma rodada
## (simulada) e as rodadas seguintes sem a categoria do jogador.
func record_feeder_weekend(w: WeekendSim) -> void:
	var s := my_series()
	var sprint: Array = w.results.get("sprint", [])
	var feature: Array = w.results.get("race", [])
	s.record_played(round, sprint, feature, w.retired.get("sprint", []), w.retired.get("race", []))
	var bal := feeder.settle_round(my_feeder_drivers(), feeder_rounds().size())
	cash_log.append({"r": round + 1, "cash": feeder.cash, "bal": bal})
	_auto_f1_round(feeder.cat)
	catch_up()
	if feeder.cash < 0.0:
		state = "bankrupt"


## Fim do ano na F2/F3: prêmio pela posição e acesso/rebaixamento de todas as categorias (decide_moves).
func feeder_close_season() -> Dictionary:
	var pos := feeder_position()
	var prize := feeder.prize_for(pos)
	feeder.cash += prize
	decide_moves()
	var up := String(moves.get("up_f2" if feeder.cat == "F3" else "up_f1", "")) == player_team
	var down := feeder.cat == "F2" and String(moves.get("down_f3", "")) == player_team
	var report := {"season": season, "category": feeder.cat, "position": pos, "points": _feeder_points(), "prize": prize,
		"cash": feeder.cash, "promoted": up, "relegated": down, "verdict": "promoted" if up else ("relegated" if down else "stay")}
	seasons.append(report)
	return report


func _feeder_points() -> int:
	for row: Array in my_series().team_standings():
		if row[0] == player_team:
			return int(row[1])
	return 0


## Começa o ano seguinte na F2/F3: aplica as subidas/descidas (a equipe do jogador muda de categoria se for o caso),
## refaz os grids da base e zera os campeonatos. A F1 do ano seguinte continua simulada.
func feeder_start_next_season() -> void:
	var was := feeder.cat
	if was == "F2" and String(moves.get("up_f1", "")) == player_team:
		_enter_f1_from_feeder()
		return
	apply_moves()
	for cat: String in series:
		if not (series[cat] as Series).team(player_team).is_empty():
			feeder.cat = cat
	if feeder.cat != was:
		var entry := float(FeederCareer.ECON[was]["entry_up"])
		if feeder.cat == "F2" and was == "F3":
			feeder.cash += entry  # verba de entrada ao subir (decisão de 2026-11-08)
			feeder.log.append("Subimos para a F2: verba de entrada de US$ %s mi." % String.num(entry, 1).replace(".", ","))
		feeder.base_rating = float(my_series().team(player_team)["car_rating"]) - feeder.level_bonus()
		var roles := feeder.staff_roles()
		for role: String in roles:  # F3 → F2: um engenheiro a menos; F2 → F3: contrata o terceiro
			if not feeder.staff.has(role):
				var p := Personnel.generic_person("%s|%s|%s|%d" % [feeder.cat, player_team, role, season])
				p["salary"] = feeder.salary_for(int(p["skill"]))
				feeder.staff[role] = p
		for k: String in feeder.staff.keys():
			if not roles.has(k):
				feeder.staff.erase(k)
	for s: Series in series.values():
		s.reset_season()
		s.assign_seats(personnel.feeder())
	_sync_feeder_rating()
	season += 1
	round = 0
	driver_points = {}
	team_points = {}
	wins = {}
	history = []
	day = _season_start_day()
	catch_up()


## Campeã da F2: a equipe do jogador entra na F1 (carro mais fraco, motor de fornecedor, os pilotos de contrato) e a
## campanha passa a ser a da F1, com o caixa da base + a verba de entrada.
func _enter_f1_from_feeder() -> void:
	var carry := feeder.cash
	var name := String(my_series().team(player_team).get("name", ""))
	feeder = null
	budget_musd = carry + F1_ENTRY_MUSD
	start_next_season()  # aplica as subidas/descidas (a equipe entra no grid da F1) e vira o ano como na F1
	factory_level = 1
	dev.set_all_levels(1)
	base_rating = float(team().get("car_rating", 75.0))
	livery = Livery.new()
	livery.setup(team())
	objective = {"id": "board"}
	trust = 60.0
	board_patience = 3
	cash_log = [{"r": 0, "cash": budget_musd}]
	sync_factory_level()
	refresh_rating()
	events._add(self, {"day": day, "cat": "calendar", "id": "promotion", "title": "%s CHEGA À F1" % name.to_upper(),
		"text": "A equipe sobe com o carro mais fraco do grid, motor de fornecedor e US$ %d mi de verba de entrada." % int(F1_ENTRY_MUSD), "chips": []})


## Posição da equipe do jogador no campeonato de equipes da categoria.
func feeder_position() -> int:
	var rows := my_series().team_standings()
	for i in rows.size():
		if rows[i][0] == player_team:
			return i + 1
	return rows.size()


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
		var cp: CarParts = parts.get(t["id"])
		var pe := cp.avg_effect() if cp != null else 0.0
		if t["id"] == player_team:
			t["car_rating"] = base_rating + dev.rating_bonus() + pe
			if livery != null and not livery.main.is_empty():
				t["livery_paint"] = livery.paint_for_round(round)  # o carro desenhado nas telas usa a pintura do estúdio
			t["failure_mult"] = dev.failure_mult()
			dev.staff_mod = personnel.staff_effects(self)
			dev.atr = atr_mult(player_team)
			t["practice_gain_mult"] = dev.practice_gain_mult()  # simulador da fábrica; o pessoal entra em practice_skills
		else:  # equipes da IA também desenvolvem o carro ao longo da temporada (mais rápido com um bom corpo técnico)
			t["car_rating"] = float(_file_ratings.get(t["id"], t["car_rating"])) + float(rival_carry.get(t["id"], 0.0)) + pe
			t["practice_gain_mult"] = 1.0
		if personnel != null:
			t["practice_skills"] = Personnel.practice_skills_for(self, t["id"], team_driver_ids(t["id"]))


## Quanto da temporada já passou (0 = véspera da primeira rodada, 1 = depois da última).
func season_progress() -> float:
	var start := _season_start_day()
	var end_day := round_day(calendar().size() - 1) + 1
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
	var staff_k := personnel.ai_dev_factor(self, team_id) if personnel != null and not personnel.contracts.is_empty() else 1.0
	return float(cfg["yearly_gain"][ai_difficulty]) * rank_factor * luck * staff_k


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
	_init_parts()
	livery = Livery.new()
	livery.setup(team())
	_init_series()
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


## Peças de todas as equipes, versão A. A IA ganha o "tamanho" das suas peças do ano (dificuldade, ranking, sorte, técnicos).
func _init_parts() -> void:
	parts = {}
	for t: Dictionary in _teams:
		var cp := CarParts.new()
		cp.setup(t["id"])
		parts[t["id"]] = cp
	_set_ai_gain()


func _set_ai_gain() -> void:
	var yearly: float = float(origins_data()["rivals"]["yearly_gain"]["normal"])
	for tid: String in parts:
		if tid != player_team:
			(parts[tid] as CarParts).gain_k = rival_potential(tid) / yearly


func my_parts() -> CarParts:
	return parts.get(player_team)


## Perfil médio das próximas n pistas (a IA escolhe a direção das peças por ele).
func upcoming_profile(n: int) -> Dictionary:
	var cal := calendar()
	var acc := {"straight": 0.0, "slow": 0.0, "fast": 0.0}
	var cnt := 0
	for i in range(round, mini(round + n, cal.size())):
		var p := track_profile(String(cal[i]["id"]))
		for k: String in acc:
			acc[k] += float(p[k])
		cnt += 1
	if cnt == 0:
		return CarParts.NEUTRAL
	for k: String in acc:
		acc[k] /= cnt
	return acc


static var _profiles: Dictionary = {}


static func track_profile(circuit_id: String) -> Dictionary:
	if not _profiles.has(circuit_id):
		_profiles[circuit_id] = CarParts.profile_of(GameData.circuit(circuit_id))
	return _profiles[circuit_id]


## Primeira corrida (da rodada atual em diante) que acontece pelo menos `days` dias a partir de hoje; {} se nenhuma.
func race_after(days: int) -> Dictionary:
	var cal := calendar()
	for i in range(round, cal.size()):
		if round_day(i) >= day + days and not events.cancelled.has(i) and not regs.is_dropped(String(cal[i]["id"])):
			return cal[i]
	return {}


## Nota efetiva do carro de uma equipe numa pista (sem a forma aleatória do fim de semana): base + características de
## fábrica no perfil da pista + média das peças dos dois carros.
func track_rating(team_id: String, circuit_id: String) -> float:
	var t := GameData.team_by_id(_teams, team_id)
	var cp: CarParts = parts.get(team_id)
	var prof := track_profile(circuit_id)
	var pe := cp.avg_effect() if cp != null else 0.0
	return float(t["car_rating"]) - pe + CarParts.traits_effect(t, prof) + (cp.avg_effect(prof) if cp != null else 0.0)


## Posição (1..) do carro do jogador entre os carros do grid numa pista.
func track_rank(circuit_id: String) -> int:
	var mine := track_rating(player_team, circuit_id)
	var rank := 1
	for t: Dictionary in _teams:
		if t["id"] != player_team and track_rating(t["id"], circuit_id) > mine:
			rank += 1
	return rank


## Ponto forte/fraco da pista para o carro do jogador (efeito do perfil em relação a uma pista neutra).
func track_fit(circuit_id: String) -> float:
	var t := team()
	var cp := my_parts()
	var prof := track_profile(circuit_id)
	return CarParts.traits_effect(t, prof) - CarParts.traits_effect(t, CarParts.NEUTRAL) + (cp.avg_effect(prof) - cp.avg_effect() if cp != null else 0.0)


# --- F2 e F3 em paralelo; acesso e rebaixamento (3 categorias, fase 1) --------------------------

func _init_series() -> void:
	series = {}
	for cat: String in ["F2", "F3"]:
		var s := Series.make(cat)
		s.assign_seats(personnel.feeder())
		series[cat] = s


func _prospect_ratings() -> Dictionary:
	var r := {}
	for p: Dictionary in personnel.feeder():
		r[p["id"]] = int(p.get("rating", 60))
	return r


## Depois de cada GP da F1: as categorias de base que correm nesse fim de semana também correm.
func _run_series(f1_round: int, skip_cat: String = "") -> void:
	var ratings := _prospect_ratings()
	for s: Series in series.values():
		if s.cat == skip_cat:
			continue  # campanha na F2/F3: a etapa da categoria do jogador foi jogada
		if s.runs_on(f1_round):
			s.simulate_round(f1_round, ratings, season * 100 + int(dev.seed_base))


## Fim do ano: quem sobe e quem desce (campeão da F3 ↑ F2, último da F2 ↓ F3; campeão da F2 ↑ F1, último da F1 ↓ F2).
func decide_moves() -> Dictionary:
	moves = {}
	if series.is_empty():
		return moves
	var f2: Series = series["F2"]
	var f3: Series = series["F3"]
	var t3 := f3.team_standings()
	var t2 := f2.team_standings()
	var t1 := team_standings()
	if not t3.is_empty() and not t2.is_empty():
		moves["up_f2"] = t3[0][0]
		moves["down_f3"] = t2[t2.size() - 1][0]
	if not t2.is_empty() and not t1.is_empty():
		moves["up_f1"] = t2[0][0]
		moves["down_f2"] = t1[t1.size() - 1][0]
	return moves


## Número do novato que chega à F1: herda o de um piloto que saiu ou mantém o da categoria anterior (sorteado, as duas
## opções valem — decisão do usuário). Nunca o 1 (é do campeão) nem um número em uso.
func rookie_number(p: Dictionary) -> int:
	var used := {1: true}
	for d: Dictionary in _drivers:
		used[int(d.get("number", 0))] = true
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("num|%s|%d" % [String(p.get("id", "")), season])
	var own := int(p.get("number", 0))
	if own <= 1:
		own = 2 + absi(hash("serie|" + String(p.get("id", "")))) % 98  # número que usava na base
	var inherited := -1
	for n: int in freed_numbers:
		if not used.has(n):
			inherited = n
			break
	var pick := own if (rng.randf() < KEEP_SERIES_NUMBER_CHANCE or inherited < 0) else inherited
	if used.has(pick):
		pick = inherited if inherited > 0 and not used.has(inherited) else _free_number()
	freed_numbers.erase(pick)
	return pick


func free_number(n: int) -> void:
	if n > 1 and not freed_numbers.has(n):
		freed_numbers.push_front(n)


## Virada: o campeão de pilotos usa o 1; quem tinha o 1 e não ganhou volta ao seu número de carreira.
func _apply_champion_number(champion: String) -> void:
	var holder := {}
	var champ := {}
	for d: Dictionary in _drivers:
		if int(d.get("number", 0)) == 1:
			holder = d
		if d["id"] == champion:
			champ = d
	if not holder.is_empty() and holder != champ:
		var back := int(holder.get("perm_number", PERMANENT_NUMBERS.get(holder["id"], 0)))
		var taken := _drivers.any(func(x: Dictionary) -> bool: return x != holder and int(x.get("number", 0)) == back)
		holder["number"] = back if back > 1 and not taken else _free_number()
	if not champ.is_empty() and int(champ.get("number", 0)) != 1:
		champ["perm_number"] = int(champ["number"])
		free_number(int(champ["number"]))
		champ["number"] = 1


func _free_number() -> int:
	var used := {}
	for d: Dictionary in _drivers:
		used[int(d.get("number", 0))] = true
	var n := 2
	while used.has(n) or n == 17:
		n += 1
	return n


## Aplica o acesso/rebaixamento decidido (chamado na virada, antes do mercado).
func apply_moves() -> void:
	if moves.is_empty():
		return
	var f2: Series = series["F2"]
	var f3: Series = series["F3"]
	# F3 ↔ F2: as equipes trocam de categoria com os pilotos de contrato
	_swap_series_team(f3, f2, String(moves.get("up_f2", "")))
	_swap_series_team(f2, f3, String(moves.get("down_f3", "")))
	# F2 → F1 e F1 → F2
	var up := String(moves.get("up_f1", ""))
	var down := String(moves.get("down_f2", ""))
	if up != "" and down != "" and not GameData.team_by_id(_teams, down).is_empty():
		_relegate_from_f1(down, f2)
		_promote_to_f1(up, f2)
	moves = {}


func _swap_series_team(from: Series, to: Series, team_id: String) -> void:
	var t := from.team(team_id)
	if t.is_empty():
		return
	from.teams.erase(t)
	to.teams.append(t)
	t["car_rating"] = float(t["car_rating"]) + (2.0 if to.cat == "F2" else -2.0)
	for id: String in from.team_drivers(team_id):
		from.seat_of.erase(id)
		var p := _prospect(id)
		if not p.is_empty():
			p["category"] = to.cat
			to.seat_of[id] = team_id


func _prospect(id: String) -> Dictionary:
	for p: Dictionary in personnel.feeder():
		if p["id"] == id:
			return p
	return {}


## A última da F1 desce para a F2 com os pilotos (que viram pilotos da base).
func _relegate_from_f1(team_id: String, f2: Series) -> void:
	var t := GameData.team_by_id(_teams, team_id)
	_teams.erase(t)
	f2.teams.append({"id": team_id, "base_id": team_id, "name": t["name"], "color": t.get("color", "#888888"), "color2": t.get("color2", "#FFFFFF"),
		"shape": t.get("shape", "hex"), "short_name": t.get("short_name", String(t["name"]).left(2).to_upper()), "car_rating": 61.0, "from_f1": t})
	for d: Dictionary in _drivers.duplicate():
		if d["team"] != team_id:
			continue
		_drivers.erase(d)
		var p := {"id": d["id"], "name": d["name"], "nationality": d.get("nationality", ""), "category": "F2", "rating": int(d.get("rating", 75)),
			"birth": d.get("birth", ""), "potential": int(d.get("rating", 75)), "series_team": t["name"]}
		personnel.feeder().append(p)
		f2.seat_of[d["id"]] = team_id
		if personnel.contracts.has(d["id"]):
			personnel.contracts[d["id"]]["team"] = "F2"
	parts.erase(team_id)
	rival_carry.erase(team_id)
	_file_ratings.erase(team_id)


## A campeã da F2 sobe com o carro mais fraco do grid, motor de fornecedor e os pilotos de contrato.
func _promote_to_f1(team_id: String, f2: Series) -> void:
	var st := f2.team(team_id)
	if st.is_empty():
		return
	f2.teams.erase(st)
	var weakest := 999.0
	for t: Dictionary in _teams:
		weakest = minf(weakest, float(_file_ratings.get(t["id"], t["car_rating"])) + float(rival_carry.get(t["id"], 0.0)))
	var back: Dictionary = st.get("from_f1", {})
	var nt := back.duplicate(true) if not back.is_empty() else {"id": team_id, "name": st["name"], "short_name": st.get("short_name", ""),
		"color": st["color"], "color2": st["color2"], "shape": st.get("shape", "hex"), "custom": true, "power_unit": "Mercedes",
		"car_traits": {"straight": 0.0, "slow": 0.0, "fast": 0.0, "rel": 76.0}, "principal": null, "technical_director": null,
		"debut": season + 1, "constructors_titles": 0}
	nt["car_rating"] = weakest - 1.0
	_teams.append(nt)
	_file_ratings[team_id] = weakest - 1.0
	var cp := CarParts.new()
	cp.setup(team_id)
	parts[team_id] = cp
	for id: String in f2.team_drivers(team_id):
		f2.seat_of.erase(id)
		var p := _prospect(id)
		if p.is_empty():
			continue
		personnel.feeder().erase(p)
		_drivers.append({"id": p["id"], "name": p["name"], "code": driver_code(String(p["name"])), "number": rookie_number(p),
			"nationality": p.get("nationality", ""), "team": team_id, "rating": int(p.get("rating", 70)), "birth": p.get("birth", ""), "from": "F2"})
		personnel.contracts[p["id"]] = {"team": team_id, "salary": Personnel.driver_ask(float(p.get("rating", 70))), "until": season + 2}
	events._add(self, {"day": day, "cat": "calendar", "id": "promotion", "title": "%s SOBE PARA A F1" % String(st["name"]).to_upper(),
		"text": "A campeã da F2 entra no grid com o carro mais fraco e motor de fornecedor.", "chips": []})


# --- teto de gastos, túnel de vento e crédito (item 5, 2026-11-04) -------------------------------

## Quanto do teto de gastos já foi usado nesta temporada.
func cap_spent() -> float:
	var s := 0.0
	for k: String in CAP_CATEGORIES:
		s += float(ledger.get(k, 0.0))
	return maxf(s, 0.0)


func cap_left() -> float:
	return maxf(COST_CAP_MUSD - cap_spent(), 0.0)


## Teto livre para P&D e peças: o que resta, menos a operação e a manutenção que ainda serão pagas até o fim do ano
## (gastos obrigatórios também contam no teto, então ficam reservados).
func cap_left_rd() -> float:
	var mandatory := (float(origins_data()["finance"]["cost_base"]) + dev.upkeep_per_race()) * races_left_in_season()
	return maxf(COST_CAP_MUSD - cap_spent() - mandatory, 0.0)


## Trava rígida: um gasto de P&D/peças só passa se couber no teto livre para P&D.
func cap_allows(cost: float) -> bool:
	return cost <= cap_left_rd() + 0.0001


## Restrição de túnel de vento (tempo de pesquisa aerodinâmica) pela posição do ano anterior; no 1º ano, pela nota do carro.
func atr_mult(team_id: String) -> float:
	var n := maxi(_teams.size() - 1, 1)
	var pos := int(last_positions.get(team_id, rating_rank(team_id)))
	return lerpf(float(ATR_RANGE[0]), float(ATR_RANGE[1]), float(pos - 1) / n)


func debt_total() -> float:
	var s := 0.0
	for l: Dictionary in loans:
		s += float(l["per_race"]) * int(l["races_left"])
	return s


func races_left_in_season() -> int:
	return int(remaining_after_current()["races"]) + (0 if season_over() else 1)


## Empréstimo do banco: {ok, reason, total, per_race, races, rate}
func loan_info(amount: float, term: int) -> Dictionary:
	var t: Array = BANK_TERMS[clampi(term, 0, BANK_TERMS.size() - 1)]
	var races := int(t[0]) if int(t[0]) > 0 else races_left_in_season() + calendar().size()
	var total := snappedf(amount * (1.0 + float(t[1])), 0.1)
	var out := {"ok": true, "reason": "", "total": total, "per_race": snappedf(total / races, 0.01), "races": races, "rate": float(t[1])}
	var taken := 0.0
	for l: Dictionary in loans:
		taken += float(l["principal"])
	if amount <= 0.0 or taken + amount > BANK_LIMIT_MUSD + 0.001:
		out["ok"] = false
		out["reason"] = "limit"
	return out


func bank_room() -> float:
	var taken := 0.0
	for l: Dictionary in loans:
		taken += float(l["principal"])
	return maxf(BANK_LIMIT_MUSD - taken, 0.0)


func take_loan(amount: float, term: int) -> bool:
	var info := loan_info(amount, term)
	if not info["ok"]:
		return false
	loans.append({"principal": amount, "total": info["total"], "per_race": info["per_race"], "races_left": info["races"]})
	budget_musd += amount
	record("loan", amount)
	if debt_total() > DEBT_TRUST_LIMIT:
		trust = clampf(trust - 3.0, 0.0, 100.0)
	return true


## Adiantamento de patrocínio: máximo que dá para receber agora.
func advance_room() -> float:
	if not advance.is_empty():
		return 0.0
	return snappedf(sponsor_per_race() * races_left_in_season() * ADVANCE_SHARE, 0.1)


func take_advance(amount: float) -> bool:
	if amount <= 0.0 or amount > advance_room() + 0.001:
		return false
	var races := maxi(races_left_in_season(), 1)
	advance = {"amount": amount, "cut": snappedf(amount / races, 0.01), "races_left": races}
	budget_musd += amount
	record("loan", amount)
	return true


## Depois de cada corrida: parcelas do banco e o desconto do adiantamento no patrocínio.
func _pay_credit() -> void:
	for l: Dictionary in loans.duplicate():
		budget_musd -= float(l["per_race"])
		record("debt", float(l["per_race"]))
		l["races_left"] = int(l["races_left"]) - 1
		if int(l["races_left"]) <= 0:
			loans.erase(l)
	if not advance.is_empty():
		budget_musd -= float(advance["cut"])
		record("sponsors", -float(advance["cut"]))
		advance["races_left"] = int(advance["races_left"]) - 1
		if int(advance["races_left"]) <= 0:
			advance = {}
	debt_musd = debt_total()


## Data (dia) de uma rodada, já com adiamento por evento.
func round_day(i: int) -> int:
	return _day_of(String(calendar()[i]["date"])) + int(events.postponed.get(i, 0))


# --- demissão: propostas de outras equipes (#17) ------------------------------------------------

## Demitido: até 3 equipes da metade de baixo do grid (por nota do carro) oferecem o cargo de chefe. Determinístico.
func job_offers() -> Array:
	var rated := _teams.filter(func(t: Dictionary) -> bool: return t["id"] != player_team)
	rated.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(_file_ratings.get(a["id"], a["car_rating"])) + float(rival_carry.get(a["id"], 0.0)) > float(_file_ratings.get(b["id"], b["car_rating"])) + float(rival_carry.get(b["id"], 0.0)))
	var pool: Array = rated.slice(rated.size() / 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("offers|%d|%s" % [season, player_team])
	var out: Array = []
	while not pool.is_empty() and out.size() < 3:
		var t: Dictionary = pool.pop_at(rng.randi() % pool.size())
		out.append(t["id"])
	return out


## Aceita a proposta: a carreira continua em outra equipe (mesmo mundo: grid, histórico, regras). A equipe antiga
## passa para a IA com o carro que tinha.
func switch_team(team_id: String) -> void:
	var old := player_team
	_file_ratings[old] = base_rating
	rival_carry[old] = dev.carry
	player_team = team_id
	mode = "real"
	base_rating = float(_file_ratings.get(team_id, team()["car_rating"])) + float(rival_carry.get(team_id, 0.0))
	rival_carry.erase(team_id)
	dev = CarDevelopment.new()
	dev.set_all_levels(3)
	dev.seed_base = season
	sync_factory_level()
	personnel.staff.clear()
	for role: String in Personnel.ROLES:
		personnel.staff[role] = ""
		for id: String in personnel.contracts:
			var c: Dictionary = personnel.contracts[id]
			if String(c.get("team", "")) == team_id and String(personnel.person(id).get("role", "")) == role:
				personnel.staff[role] = id
				break
	sponsors = Sponsorship.new()
	sponsors.setup(self, _base_sponsor_target())
	livery = Livery.new()
	livery.setup(team())
	budget_musd = 140.0  # PROVISÓRIO: orçamento padrão das equipes reais
	debt_musd = 0.0
	goal_shift = 0
	state = "active"
	board_patience = clampi(1 + int((rating_rank(team_id) - 1) / 3.0), 1, 5)
	trust = _start_trust()
	if not seasons.is_empty():
		seasons.back()["new_team"] = team_id
	events._add(self, {"day": day, "cat": "team", "id": "new_job", "title": "NOVO CHEFE NA %s" % String(team()["name"]).to_upper(),
		"text": "Depois da demissão, você assume a %s para a próxima temporada." % team()["name"], "chips": []})
	refresh_rating()


## Corridas e sprints que ainda restam DEPOIS da rodada atual (sem as canceladas): {races, sprints}.
func remaining_after_current() -> Dictionary:
	var cal := calendar()
	var races := 0
	var sprints := 0
	for i in range(round + 1, cal.size()):
		if events.cancelled.has(i) or regs.is_dropped(String(cal[i]["id"])):
			continue
		races += 1
		if regs.is_sprint(String(cal[i]["id"])):
			sprints += 1
	return {"races": races, "sprints": sprints}


## Pilotos titulares de uma equipe, na ordem dos carros (carro 0, carro 1).
func team_driver_ids(team_id: String) -> Array:
	var out: Array = []
	for d: Dictionary in _drivers:
		if d.get("team", "") == team_id and out.size() < 2:
			out.append(d["id"])
	return out


func _dev_tick(n: int, last_day: int = -1) -> void:
	if n > 0:
		var end_day := day if last_day < 0 else last_day
		if feeder == null:  # eventos e P&D são da equipe da F1 do jogador
			for i in n:
				events.tick_day(self, end_day - n + 1 + i)
			dev.tick(self, n)
		for i in n:
			for cp: CarParts in parts.values():
				cp.day_step(self)
		refresh_rating()
		_skip_cancelled()


## Rodadas canceladas por eventos são puladas: não há fim de semana, pontos nem patrocínio.
func _skip_cancelled() -> void:
	var n := calendar().size()
	while round < n and (events.cancelled.has(round) or regs.is_dropped(String(calendar()[round]["id"]))):
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
		"best_finish": best_finish, "seasons": seasons, "goal_shift": goal_shift, "dev": dev.to_dict(), "rival_carry": rival_carry, "personnel": personnel.to_dict(), "drivers_grid": _drivers, "sponsors": sponsors.to_dict(), "ledger": ledger, "cash_log": cash_log, "regs": regs.to_dict(), "events": events.to_dict(),
		"series": series.keys().reduce(func(acc: Dictionary, k: String) -> Dictionary: acc[k] = (series[k] as Series).to_dict(); return acc, {}),
		"moves": moves, "teams_grid": _teams, "freed_numbers": freed_numbers, "file_ratings": _file_ratings,
		"livery": livery.to_dict(), "loans": loans, "advance": advance, "last_positions": last_positions,
		"parts": parts.keys().reduce(func(acc: Dictionary, k: String) -> Dictionary: acc[k] = (parts[k] as CarParts).to_dict(); return acc, {}),
		"feeder": feeder.to_dict() if feeder != null else {}}


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
		c.personnel.sync_with_grid(c)
		c.personnel.repair_staff(c)
	if d.has("sponsors"):
		c.sponsors = Sponsorship.from_dict(d["sponsors"])
	if d.has("regs"):
		c.regs = Regulations.from_dict(d["regs"])
	if d.has("events"):
		c.events = CampaignEvents.from_dict(d["events"])
		for tid: String in c.events.principals:  # chefes trocados por evento
			var tt := GameData.team_by_id(c._teams, tid)
			if not tt.is_empty():
				tt["principal"] = c.events.principals[tid]
	c.ledger = d.get("ledger", {})
	if d.has("cash_log"):
		c.cash_log = d["cash_log"]
	if d.has("teams_grid"):  # equipes que subiram/desceram (3 categorias)
		c._teams = d["teams_grid"]
		for t: Dictionary in c._teams:
			t["car_rating"] = float(t["car_rating"])
		for k: String in d.get("file_ratings", {}):
			c._file_ratings[k] = float(d["file_ratings"][k])
		for t: Dictionary in c._teams:
			if not c.parts.has(t["id"]):
				var cp := CarParts.new()
				cp.setup(t["id"])
				c.parts[t["id"]] = cp
	if d.has("series"):
		for k: String in d["series"]:
			c.series[k] = Series.from_dict(d["series"][k])
	c.moves = d.get("moves", {})
	c.freed_numbers = (d.get("freed_numbers", []) as Array).map(func(x: Variant) -> int: return int(x))
	c.loans = d.get("loans", [])
	for l: Dictionary in c.loans:
		l["races_left"] = int(l["races_left"])
	c.advance = d.get("advance", {})
	if not c.advance.is_empty():
		c.advance["races_left"] = int(c.advance["races_left"])
	c.last_positions = d.get("last_positions", {})
	for k: String in c.last_positions:
		c.last_positions[k] = int(c.last_positions[k])
	if d.has("livery") and not (d["livery"] as Dictionary).get("main", {}).is_empty():
		c.livery = Livery.from_dict(d["livery"])
	if d.has("parts"):
		for k: String in d["parts"]:
			if c.parts.has(k):
				c.parts[k] = CarParts.from_dict(d["parts"][k])
	if d.has("dev"):
		c.dev = CarDevelopment.from_dict(d["dev"])
		var mp := c.my_parts()
		c.dev.parts_busy = mp.research.size() if mp != null else 0
		c.sync_factory_level()
		c.refresh_rating()
	c.trust = float(d.get("trust", c._start_trust()))
	c.day = int(d.get("day", c._season_start_day()))
	if not (d.get("feeder", {}) as Dictionary).is_empty():
		c.feeder = FeederCareer.from_dict(d["feeder"])
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
	var o := {"player_team": player_team, "drivers": _drivers, "seed": season * 100 + round + 1, "campaign": true,
		"points_race": regs.points_race, "points_sprint": regs.points_sprint, "min_dry_compounds": regs.min_dry_compounds,
		"tech": regs.tech_options(), "teams": teams_for_gp(String(next_round().get("id", "")) if not season_over() else "")}
	if not season_over():
		o["sprint"] = regs.is_sprint(next_round()["id"])
	# posição de cada piloto no campeonato, a partir da metade da temporada: quem briga pelo título arrisca
	# menos na classificação (QualiSim.choose_lap_mode)
	if round >= calendar().size() / 2:
		var champ := {}
		var rows := driver_standings()
		for i in rows.size():
			champ[rows[i][0]] = i + 1
		o["championship"] = champ
	o.merge(extra, true)
	return o


## Cópia das equipes para um GP: cada carro leva o efeito das SUAS peças nesta pista (`car_delta` por piloto, que a
## volta ideal soma) e o fator de confiabilidade das suas peças (`failure_by_driver`, multiplica o `failure_mult`). A nota da equipe volta à base sem peças.
func teams_for_gp(circuit_id: String) -> Array:
	var prof := track_profile(circuit_id) if circuit_id != "" else CarParts.NEUTRAL
	var out: Array = []
	for t: Dictionary in _teams:
		var c := t.duplicate()
		var cp: CarParts = parts.get(t["id"])
		if cp != null:
			c["car_rating"] = float(t["car_rating"]) - cp.avg_effect()
			var ids := team_driver_ids(t["id"])
			var delta := {}
			var fail := {}
			var rel0 := float((t.get("car_traits", {}) as Dictionary).get("rel", CarParts.REL_NEUTRAL))
			for i in ids.size():
				delta[ids[i]] = cp.car_effect(i, prof)
				fail[ids[i]] = CarParts.rel_mult(rel0 + cp.trait_delta(i, "rel")) / CarParts.rel_mult(rel0)
			c["car_delta"] = delta
			c["failure_by_driver"] = fail
		out.append(c)
	return out


## Soma os pontos de um fim de semana concluído, paga as contas da rodada, ajusta a confiança da
## diretoria e avança para a próxima rodada (o dia vai para o dia seguinte à corrida).
func record_weekend(w: WeekendSim, skip_cat: String = "") -> void:
	if feeder != null:  # campanha na F2/F3: o fim de semana jogado é da categoria de base
		record_feeder_weekend(w)
		return
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
	for cp: CarParts in parts.values():  # desgaste das peças e revelação dos upgrades estreados nesta corrida
		cp.after_race(self)
	_run_series(round, skip_cat)
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
	_pay_credit()
	if detail == "essential" and not sponsors.free_zones().is_empty():  # (um patrocinador pode ter saído por evento)
		sponsors.auto_fill(self)
	var pos := team_position(player_team)
	var gap := season_goal() - pos  # >= 0: dentro da meta
	var drift: float = origins_data()["board"]["drift_per_race"]
	trust = clampf(trust + (drift if gap >= 0 else float(gap) * drift * 0.5) * _difficulty_factor(), 0.0, 100.0)
	round += 1
	cash_log.append({"r": round, "cash": budget_musd})
	events.on_race_recorded(self)
	var new_day := round_day(round - 1) + 1
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
	return -1 if season_over() else round_day(round) - 2


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
	decide_moves()
	if verdict not in ["bankrupt", "fired"] and String(moves.get("down_f2", "")) == player_team:
		verdict = "relegated"  # 3 categorias (fase 1): a equipe desce; o chefe recebe propostas da F1
		state = "relegated"
	var report := {"season": season, "verdict": verdict, "position": pos, "goal": goal, "points": int(team_points.get(player_team, 0)),
		"best": best_finish, "prize": prize, "budget": budget_musd, "trust": trust, "next_goal": goal}
	if verdict == "met":
		goal_shift -= 1  # a diretoria sobe a meta (uma posição melhor), sem passar do 1º
		report["next_goal"] = season_goal()
	seasons.append(report)
	return report


## Começa a próxima temporada (mesmo grid: o mercado de pilotos chega na camada de contratos).
func start_next_season() -> void:
	var drs := driver_standings()
	var champion: String = drs[0][0] if not drs.is_empty() and int(drs[0][1]) > 0 else ""
	last_positions = {}  # restrição de túnel do ano novo: posição final deste ano
	var rows := team_standings()
	for i in rows.size():
		last_positions[rows[i][0]] = i + 1
	events.reset_for_new_season(self)  # lesionados voltam ao carro e o calendário cancelado zera antes do mercado
	apply_moves()
	personnel.rollover(self)
	if champion != "":
		_apply_champion_number(champion)
	for s: Series in series.values():
		s.reset_season()
		s.assign_seats(personnel.feeder())
	var council := regs.apply_passed(self)
	for msg: String in council:
		events._add(self, {"day": day, "cat": "calendar", "id": "council", "title": "CONSELHO DE REGRAS", "text": msg, "chips": []})
	for d: Dictionary in _drivers:  # jovens evoluem em direção ao potencial; veteranos perdem ritmo
		if DriverStats.has_attrs(d):
			DriverStats.evolve(d, season + 1, 0)
		else:  # vindos da base: só têm nota geral
			DriverCareer.evolve_prospect(d, season + 1, int(dev.seed_base))
	sponsors.expire(self)
	if detail == "essential":  # modo Essencial: zonas livres ganham patrocinador automaticamente
		sponsors.auto_fill(self)
	ledger = {}
	cash_log = [{"r": 0, "cash": budget_musd}]
	var cfg: Dictionary = origins_data()["rivals"]
	# a IA guarda parte do que desenvolveu neste ano. Calcula tudo antes de gravar: o potencial depende da
	# posição de cada equipe, e gravar uma por uma mudava a ordem das que vinham depois (carros mais próximos).
	var potentials := {}
	for t: Dictionary in _teams:
		if t["id"] != player_team:
			potentials[t["id"]] = rival_potential(t["id"])
	for tid: String in potentials:  # o que as peças da IA renderam no ano (com acertos e erros)
		var cp: CarParts = parts.get(tid)
		var got := cp.avg_effect() if cp != null else float(potentials[tid])
		rival_carry[tid] = (float(rival_carry.get(tid, 0.0)) + got) * float(cfg["carry"])
	season += 1
	round = 0
	driver_points = {}
	team_points = {}
	wins = {}
	history = []
	best_finish = 99
	dev.rollover(my_parts().avg_effect() if my_parts() != null else 0.0)
	for cp: CarParts in parts.values():
		cp.rollover()
	if not regs.pending_reset.is_empty():
		regulation_reset(regs.pending_reset)
		regs.pending_reset.clear()
	_set_ai_gain()
	livery.specials.clear()  # pinturas especiais valem por temporada
	livery.make_launch(self)  # lançamento do carro novo (a sede mostra)
	refresh_rating()
	day = _season_start_day()  # (calendário de 2027+ ainda repete as datas de 2026: PROVISÓRIO)


## "Ano de virada" (regra técnica grande mudou): as notas dos carros se aproximam e cada equipe ganha ou perde conforme
## o que preparou — o corpo técnico, a sorte do fabricante do motor (se o motor mudou) e, para o jogador, o carro do ano
## seguinte desenvolvido na P&D (que já virou o carro atual e é mantido inteiro, enquanto o desenvolvimento antigo vale
## só RESET_KEEP). Decisão do usuário: "bastante, mas com lógica".
const RESET_COMPRESS := 0.5
const RESET_KEEP := 0.4
const RESET_STAFF_K := 0.12
const RESET_NOISE := 1.0
const RESET_ENGINE_LUCK := 1.5


func regulation_reset(kinds: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("reset|%d|%s" % [season, ",".join(kinds)])
	var cur := {}
	var total := 0.0
	for t: Dictionary in _teams:
		var r := base_rating if t["id"] == player_team else float(_file_ratings.get(t["id"], t["car_rating"])) + float(rival_carry.get(t["id"], 0.0))
		cur[t["id"]] = r
		total += r
	var mean := total / maxf(_teams.size(), 1)
	var maker_luck := {}
	for t: Dictionary in _teams:
		var prep := (personnel.tech_staff_avg(self, t["id"]) - 82.0) * RESET_STAFF_K + rng.randfn(0.0, RESET_NOISE)
		if kinds.has("engine"):
			var maker := String(t.get("power_unit", t["name"]))
			if not maker_luck.has(maker):
				maker_luck[maker] = rng.randfn(0.0, RESET_ENGINE_LUCK)
			prep += float(maker_luck[maker])
		var nr := mean + (float(cur[t["id"]]) - mean) * RESET_COMPRESS + prep
		if t["id"] == player_team:
			base_rating = nr
			dev.carry *= RESET_KEEP
		else:
			_file_ratings[t["id"]] = nr
			rival_carry[t["id"]] = 0.0
	var names: Array[String] = []
	for k: String in kinds:
		names.append({"engine": "motor", "aero": "aerodinâmica", "chassis": "chassi"}.get(k, k))
	events._add(self, {"day": day, "cat": "calendar", "id": "reset", "title": "ANO DE VIRADA",
		"text": "Novo regulamento de %s: os carros se aproximam. Quem preparou o carro novo sai na frente." % ", ".join(names), "chips": []})


func objective_text() -> String:
	for o: Dictionary in origins_data()["objectives"]:
		if o["id"] == objective.get("id", ""):
			return String(o["name"]) % int(objective.get("seasons", o.get("seasons", 5))) if String(o["name"]).contains("%d") else String(o["name"])
	return "Metas da diretoria"
