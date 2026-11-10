class_name WeekendSim
extends RefCounted
## Fim de semana de Grande Prêmio: a ordem das sessões, a previsão do tempo por dia, o acerto
## dos carros (que passa dos treinos para a classificação e a corrida), os grids e os pontos.
##
## Formatos (2026):
##   normal  — TL1, TL2 (sexta) · TL3, Classificação (sábado) · Corrida (domingo)
##   sprint  — TL1, Classificação sprint (sexta) · Sprint, Classificação (sábado) · Corrida
##   só a corrida — apenas a corrida, com grid sorteado pelo ritmo (como a corrida rápida)
##
## Cada sessão cria a sua simulação (PracticeSession, QualiSim ou RaceSim); a tela roda a
## simulação e devolve aqui com finish_*(). A semente de cada sessão vem da semente do fim
## de semana, então o mesmo fim de semana pode ser repetido igual.

const SESSION_NAMES := {
	"fp1": "Treino livre 1", "fp2": "Treino livre 2", "fp3": "Treino livre 3",
	"sprint_quali": "Classificação sprint", "sprint": "Sprint",
	"quali": "Classificação", "race": "Corrida",
}
const SESSION_SHORT := {
	"fp1": "TL1", "fp2": "TL2", "fp3": "TL3", "sprint_quali": "CL. SPRINT",
	"sprint": "SPRINT", "quali": "CLASS", "race": "CORRIDA",
}
const NORMAL := ["fp1", "fp2", "fp3", "quali", "race"]
const FEEDER_FORMAT := ["fp1", "quali", "sprint", "race"]  ## F2/F3: um treino, classificação única, sprint invertida e principal
const SPRINT_FORMAT := ["fp1", "sprint_quali", "sprint", "quali", "race"]
const DAYS := ["Sexta", "Sábado", "Domingo"]
## Modos de clima da configuração do GP
const WEATHER_MODES := ["realistic", "dry", "rain", "variable"]

var circuit: Dictionary = {}
var track: TrackModel
var tyres: TyreModel
var teams: Array = []
var drivers: Array = []
var player_team := ""
var grid_penalties: Dictionary = {}  ## driver id -> {places, back, parts} (campanha: motor/câmbio além do limite)
var duration_pct := 1.0
var weather_mode := "realistic"
var race_only := false
var sprint_weekend := false
var points_race: Array = RaceSim.RACE_POINTS  ## tabela de pontos da corrida (campanha: do regulamento)
var points_sprint: Array = RaceSim.SPRINT_POINTS
var seed_value := 1
var championship: Dictionary = {}
var tech: Dictionary = {}  ## regulamento técnico da campanha (TechRules)  ## campanha: driver id -> posição no campeonato (classificação usa)
var incident_rate := 1.0
var campaign := false  ## fim de semana de uma campanha (volta para a sede ao terminar)
var world := false  ## fim de semana do Campeonato Mundial F1 (volta para o painel da temporada ao terminar)

var sessions: Array[String] = []
var current := 0
var setups: Dictionary = {}  ## id do piloto -> CarSetup
var programs: Dictionary = {}  ## id do piloto -> programa do próximo treino (jogador)
var results: Dictionary = {}  ## sessão -> Array de ids na ordem final
var summaries: Dictionary = {}  ## sessão -> texto curto para o painel ("ALB 3º, SAI 7º")
var tyre_alloc: TyreAllocation  ## jogos de pneus de cada piloto no fim de semana (regra real de 2026, v22)
var grids: Dictionary = {}  ## "sprint"/"race" -> Array de ids na ordem de largada
var points: Dictionary = {}  ## id do piloto -> pontos no fim de semana
var forecast: Array[float] = []  ## chance de chuva por dia (sexta, sábado, domingo)
var rng := RandomNumberGenerator.new()
var retired: Dictionary = {}  ## "race"/"sprint" -> [ids] que abandonaram ou foram desclassificados
var quali_times: Dictionary = {}  ## "race"/"sprint" -> {id do piloto: {time, part}} (melhor volta na classificação; grid)
var category := "F1"  ## "F1", "F2" ou "F3" (CategoryRules; decisões de 2026-11-08)
var strategy: Dictionary = {}  ## id do piloto -> plano da corrida atual (RaceStrategy; passo antes da largada, v22-2)
var show_practice_report := false  ## a tela do fim de semana abre a folha de resultado do treino (uma vez)
var last_practice: Dictionary = {}  ## resultado do último treino (tela de resultado, v21): {session, drivers: {id: resumo}, times}


## options: player_team, duration_pct, weather ("realistic"/"dry"/"rain"/"variable"),
##          format ("full"/"race_only"), seed, incident_rate, teams/drivers (grid da campanha), category ("F1"/"F2"/"F3").
func _init(circuit_id: String, options: Dictionary = {}) -> void:
	circuit = GameData.circuit(circuit_id)
	track = TrackModel.new(circuit)
	tyres = TyreModel.new(GameData.tyres())
	category = String(options.get("category", "F1"))
	var feeder := CategoryRules.is_feeder(category)
	var grid: Dictionary = CategoryRules.feeder_grid(category) if feeder and not options.has("teams") else {}
	teams = options.get("teams", grid.get("teams", GameData.teams()))  # campanha: grid com a equipe criada
	drivers = options.get("drivers", grid.get("drivers", GameData.drivers()))
	if feeder:
		tyres.restrict_to(category)
		for t: Dictionary in teams:
			t["category"] = category
	player_team = options.get("player_team", "")
	grid_penalties = options.get("grid_penalties", {})
	seed_value = int(options.get("seed", 1))
	# forma do fim de semana: cada equipe chega um pouco acima/abaixo da nota do carro (CarForm); "form": 0 desliga
	# F2/F3: chassi igual — a forma da equipe no GP pesa bem menos (senão engoliria a diferença pequena entre os carros)
	var form_scale := float(options.get("form", 1.0)) * float(CategoryRules.of(category).get("form_scale", 1.0))
	teams = CarForm.apply(teams, circuit_id, seed_value, form_scale, {} if feeder else CarParts.profile_of(circuit))
	for t: Dictionary in teams:  # fora da campanha: diretor de pista e engenheiros de corrida de 2026 acertam o carro
		if not t.has("practice_skills"):
			var ids: Array = drivers.filter(func(d: Dictionary) -> bool: return d["team"] == t["id"]).map(func(d: Dictionary) -> String: return d["id"])
			t["practice_skills"] = Personnel.practice_skills_for(null, String(t["id"]), ids)
	duration_pct = float(options.get("duration_pct", 1.0))
	weather_mode = options.get("weather", "realistic")
	race_only = options.get("format", "full") == "race_only"
	incident_rate = float(options.get("incident_rate", 1.0))
	campaign = bool(options.get("campaign", false))
	world = bool(options.get("world", false))
	seed_value = int(options.get("seed", 1))
	championship = options.get("championship", {})
	tech = options.get("tech", {})
	rng.seed = seed_value
	sprint_weekend = bool(options.get("sprint", circuit.get("sprint", false)))  # campanha: o Conselho pode mudar quais GPs têm sprint
	points_race = options.get("points_race", RaceSim.RACE_POINTS)
	points_sprint = options.get("points_sprint", RaceSim.SPRINT_POINTS)
	if feeder:  # F2/F3: pontos da categoria; sempre tem sprint (grid invertido) e corrida principal
		var sd: Dictionary = Series.data()["series"][category]
		points_race = sd["points_feature"]
		points_sprint = sd["points_sprint"]
		sprint_weekend = false
	tyres.min_dry_compounds = int(options.get("min_dry_compounds", tyres.min_dry_compounds))
	if feeder and not bool(CategoryRules.of(category).get("compound_rule", true)):
		tyres.min_dry_compounds = 1
	if race_only:
		sessions = ["race"]
	elif feeder:
		sessions.assign(FEEDER_FORMAT)
	else:
		sessions.assign(SPRINT_FORMAT if sprint_weekend else NORMAL)
	tyre_alloc = TyreAllocation.make(drivers.map(func(x: Dictionary) -> String: return x["id"]), sprint_weekend, category)
	for d: Dictionary in drivers:
		setups[d["id"]] = CarSetup.random_start(rng)
		points[d["id"]] = 0
	_make_forecast()


func _make_forecast() -> void:
	for day in 3:
		match weather_mode:
			"dry":
				forecast.append(0.0)
			"rain":
				forecast.append(1.0)
			"variable":
				forecast.append(0.6)
			_:
				var p := track.rain_probability + rng.randf_range(-0.15, 0.2)
				forecast.append(snappedf(clampf(p, 0.0, 0.95), 0.05))


# --- sessão atual -----------------------------------------------------------------------

func session_id() -> String:
	return sessions[current] if current < sessions.size() else ""


func is_over() -> bool:
	return current >= sessions.size()


func day_of(id: String) -> int:
	if id == "race":
		return 2
	if CategoryRules.is_feeder(category):
		return 0 if id in ["fp1", "quali"] else (1 if id == "sprint" else 2)
	if sprint_weekend:
		return 0 if id in ["fp1", "sprint_quali"] else 1
	return 0 if id in ["fp1", "fp2"] else 1


func is_practice(id: String) -> bool:
	return id.begins_with("fp")


func is_quali(id: String) -> bool:
	return id in ["quali", "sprint_quali"]


func is_race(id: String) -> bool:
	return id in ["race", "sprint"]


## Opções comuns às simulações da sessão: semente própria e clima do dia.
func session_options(id: String) -> Dictionary:
	var opts := {
		"seed": seed_value * 1000 + sessions.find(id) * 17 + 3,
		"player_team": player_team,
		"incident_rate": incident_rate,
	}
	match weather_mode:
		"dry":
			opts["weather"] = "dry"
		"rain":
			opts["weather"] = "rain"
		"variable":
			opts["weather"] = "variable"
		_:
			opts["rain_probability"] = forecast[day_of(id)]
	return opts


## Programa do treino para um piloto do jogador (os outros usam o da IA).
func set_program(driver_id: String, blocks: Array) -> void:
	programs[driver_id] = PracticeSession.valid_program(blocks, practice_minutes())


## Duração do treino livre (F1 60 min; F2/F3 45 min).
func practice_minutes() -> int:
	return int(CategoryRules.of(category)["practice_min"])


## Nome da sessão na categoria ("Corrida principal" na F2/F3).
func session_name(id: String) -> String:
	if CategoryRules.is_feeder(category):
		match id:
			"fp1":
				return "Treino livre"
			"race":
				return "Corrida principal"
	return String(SESSION_NAMES.get(id, id))


func session_short(id: String) -> String:
	if CategoryRules.is_feeder(category):
		match id:
			"fp1":
				return "TL"
			"race":
				return "PRINCIPAL"
	return String(SESSION_SHORT.get(id, id))


func program_of(driver_id: String) -> Array:
	return programs.get(driver_id, PracticeSession.DEFAULT_PROGRAM)


func make_practice() -> PracticeSession:
	var own: Dictionary = {}
	for d: Dictionary in drivers:
		if d["team"] == player_team:
			own[d["id"]] = program_of(d["id"])
	var opts := session_options(session_id())
	opts["minutes"] = practice_minutes()
	return PracticeSession.new(track, tyres, teams, drivers, setups, own, opts)


func make_quali(auto_player: bool = false) -> QualiSim:
	var opts := session_options(session_id())
	opts["sprint"] = session_id() == "sprint_quali"
	opts["auto_player"] = auto_player
	opts["championship"] = championship
	opts["tech"] = tech
	opts["tyre_alloc"] = tyre_alloc
	if CategoryRules.is_feeder(category):  # F2/F3: sessão única
		opts["single"] = true
		opts["single_minutes"] = float(CategoryRules.of(category)["quali_min"])
	return QualiSim.new(track, tyres, teams, drivers, setups, opts)


## Contexto para montar a estratégia da corrida (ou sprint) atual: voltas, desgaste e perda no box.
func race_context() -> Dictionary:
	var id := session_id()
	var is_sprint := id == "sprint"
	var total := maxi(3, roundi(track.laps * duration_pct / (RaceSim.SPRINT_DISTANCE if is_sprint else 1.0)))
	if CategoryRules.is_feeder(category):
		total = maxi(3, roundi(CategoryRules.race_laps(category, track, is_sprint) * duration_pct))
	var wear := track.tyre_wear_factor / pow(duration_pct, RaceSim.WEAR_SHORT_RACE_EXP) * float(TechRules.knobs(tech)["wear_k"])
	var no_rule := is_sprint or not bool(CategoryRules.of(category).get("compound_rule", true))
	var ctx := RaceStrategy.context(total, wear, track.pit_lane_loss_s, no_rule, RaceSim.tyre_pace_k_for(duration_pct))
	ctx["is_sprint"] = is_sprint
	return ctx


## Planos dos engenheiros para os pilotos do jogador (a tela de estratégia começa por eles).
func engineer_strategy() -> Dictionary:
	var ctx := race_context()
	var stocks := race_tyre_stock(session_id() != "sprint")
	var out := {}
	for d: Dictionary in drivers:
		if d["team"] == player_team:
			out[d["id"]] = RaceStrategy.engineer_plans(tyres, ctx, stocks[d["id"]])
	return out


func make_race(extra: Dictionary = {}) -> RaceSim:
	var id := session_id()
	var opts := session_options(id)
	if not strategy.is_empty():  # estratégia do jogador: pneu de largada e voltas planejadas das paradas (só avisa)
		var starts := {}
		var plans := {}
		for did: String in strategy:
			var p: Dictionary = strategy[did]
			starts[did] = String(p["stints"][0]["compound"])
			plans[did] = p
		opts["start_tyres"] = starts
		opts["player_plans"] = plans
	opts["duration_pct"] = duration_pct
	opts["sprint"] = id == "sprint"
	opts["category"] = category
	if CategoryRules.is_feeder(category):
		opts["laps"] = race_context()["total_laps"]
	opts["setups"] = setups
	opts["tyre_stock"] = race_tyre_stock(id != "sprint")
	opts["tech"] = tech
	if grids.has(id):
		opts["grid"] = grids[id]
	if id == "race" and not grid_penalties.is_empty():  # motor/câmbio além do limite (só a corrida principal)
		opts["grid_penalties"] = grid_penalties
	opts.merge(extra, true)
	return RaceSim.new(track, tyres, teams, drivers, opts)


# --- fim de cada sessão -----------------------------------------------------------------

func finish_practice(p: PracticeSession) -> void:
	var own := {}
	for c in p.cars:
		if c.team["id"] == player_team:
			own[c.driver["id"]] = p.summary_of(c.driver["id"])
	var times: Array = []
	for c in p.standings():
		times.append({"id": c.driver["id"], "code": String(c.driver.get("code", "")), "team": c.team["id"], "best": c.best_lap_time})
	last_practice = {"session": session_id(), "drivers": own, "times": times}
	for did: String in p.block_log:  # o treino gasta jogos sozinho e devolve 2 no fim (regra real)
		tyre_alloc.consume_practice(did, p.block_log[did])
		tyre_alloc.return_after_practice(did)
	_store(p.standings())
	_next()


func finish_quali(q: QualiSim) -> void:
	if session_id() == "quali":  # quem disputou o Q3 devolve o macio guardado
		for car in q.cars:
			tyre_alloc.after_quali(car.driver["id"], q.eliminated_in[car] < 0 and not q.crashed.has(car))
	var order := q.standings()
	_store(order)
	var times := {}
	for car in q.cars:
		var part: int = q.eliminated_in[car] if q.eliminated_in[car] >= 0 else q.segments.size() - 1
		var t: float = q.best[car][part]
		if t < INF:
			times[car.driver["id"]] = {"time": t, "part": String(q.segments[part]["name"])}
	quali_times["sprint" if session_id() == "sprint_quali" else "race"] = times
	grids["sprint" if session_id() == "sprint_quali" else "race"] = q.grid_ids()
	var rev := int(CategoryRules.of(category).get("reverse_top", 0))
	if rev > 0 and CategoryRules.is_feeder(category):  # F2/F3: a sprint larga com os N primeiros invertidos
		var g: Array = q.grid_ids()
		var top := g.slice(0, rev)
		top.reverse()
		grids["sprint"] = top + g.slice(rev)
	_next()


## Pontos da posição pela tabela do regulamento deste fim de semana.
func points_for(position: int, is_sprint_race: bool) -> int:
	var table: Array = points_sprint if is_sprint_race else points_race
	return int(table[position - 1]) if position >= 1 and position <= table.size() else 0


func finish_race(sim: RaceSim) -> void:
	strategy = {}
	var order := sim.standings()
	_store(order)
	retired[session_id()] = order.filter(func(c: CarState) -> bool: return c.retired or c.disqualified).map(func(c: CarState) -> String: return c.driver["id"])
	if sim.sprint:  # depois da sprint: os jogos gastos viram usados e o de mais voltas é devolvido
		for car in sim.cars:
			tyre_alloc.after_sprint(car.driver["id"], car.stint_history())
	for i in order.size():
		var car := order[i]
		if not (car.retired or car.disqualified):
			points[car.driver["id"]] += points_for(i + 1, sim.sprint)
	_next()


## Estoque de pneus de cada piloto na corrida (o que sobrou dos jogos do fim de semana; 0 volta = novo).
## Na sprint o macio guardado para o Q3 ainda não entra.
func race_tyre_stock(include_q3: bool = true) -> Dictionary:
	var out := {}
	for d: Dictionary in drivers:
		out[d["id"]] = tyre_alloc.race_stock(d["id"], include_q3)
	return out


## Pula a sessão atual simulando tudo (treinos com os programas atuais).
func simulate_current() -> void:
	var id := session_id()
	if is_practice(id):
		var p := make_practice()
		p.run_to_end()
		finish_practice(p)
	elif is_quali(id):
		var q := make_quali(true)
		q.run_to_end()
		finish_quali(q)
	elif is_race(id):
		# simulando, a estratégia da equipe decide também pelos carros do jogador
		var sim := make_race({"radio": false, "player_team": ""})
		sim.run_to_end()
		finish_race(sim)


func _store(order: Array) -> void:
	var id := session_id()
	var ids: Array[String] = []
	var mine: Array[String] = []
	for i in order.size():
		var car: CarState = order[i]
		ids.append(car.driver["id"])
		if car.team["id"] == player_team:
			mine.append("%s %dº" % [car.code(), i + 1])
	results[id] = ids
	summaries[id] = ", ".join(mine)


func _next() -> void:
	current += 1


## Pontos do fim de semana em ordem decrescente: [[id, pontos], ...].
func points_table() -> Array:
	var rows: Array = []
	for id: String in points:
		rows.append([id, points[id]])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1])
	return rows
