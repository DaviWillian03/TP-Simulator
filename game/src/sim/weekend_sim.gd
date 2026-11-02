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
var duration_pct := 1.0
var weather_mode := "realistic"
var race_only := false
var sprint_weekend := false
var seed_value := 1
var incident_rate := 1.0

var sessions: Array[String] = []
var current := 0
var setups: Dictionary = {}  ## id do piloto -> CarSetup
var programs: Dictionary = {}  ## id do piloto -> programa do próximo treino (jogador)
var results: Dictionary = {}  ## sessão -> Array de ids na ordem final
var summaries: Dictionary = {}  ## sessão -> texto curto para o painel ("ALB 3º, SAI 7º")
var grids: Dictionary = {}  ## "sprint"/"race" -> Array de ids na ordem de largada
var points: Dictionary = {}  ## id do piloto -> pontos no fim de semana
var forecast: Array[float] = []  ## chance de chuva por dia (sexta, sábado, domingo)
var rng := RandomNumberGenerator.new()


## options: player_team, duration_pct, weather ("realistic"/"dry"/"rain"/"variable"),
##          format ("full"/"race_only"), seed, incident_rate.
func _init(circuit_id: String, options: Dictionary = {}) -> void:
	circuit = GameData.circuit(circuit_id)
	track = TrackModel.new(circuit)
	tyres = TyreModel.new(GameData.tyres())
	teams = GameData.teams()
	drivers = GameData.drivers()
	player_team = options.get("player_team", "")
	duration_pct = float(options.get("duration_pct", 1.0))
	weather_mode = options.get("weather", "realistic")
	race_only = options.get("format", "full") == "race_only"
	incident_rate = float(options.get("incident_rate", 1.0))
	seed_value = int(options.get("seed", 1))
	rng.seed = seed_value
	sprint_weekend = bool(circuit.get("sprint", false))
	if race_only:
		sessions = ["race"]
	else:
		sessions.assign(SPRINT_FORMAT if sprint_weekend else NORMAL)
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
	programs[driver_id] = PracticeSession.valid_program(blocks)


func program_of(driver_id: String) -> Array:
	return programs.get(driver_id, PracticeSession.DEFAULT_PROGRAM)


func make_practice() -> PracticeSession:
	var own: Dictionary = {}
	for d: Dictionary in drivers:
		if d["team"] == player_team:
			own[d["id"]] = program_of(d["id"])
	return PracticeSession.new(track, tyres, teams, drivers, setups, own, session_options(session_id()))


func make_quali(auto_player: bool = false) -> QualiSim:
	var opts := session_options(session_id())
	opts["sprint"] = session_id() == "sprint_quali"
	opts["auto_player"] = auto_player
	return QualiSim.new(track, tyres, teams, drivers, setups, opts)


func make_race(extra: Dictionary = {}) -> RaceSim:
	var id := session_id()
	var opts := session_options(id)
	opts["duration_pct"] = duration_pct
	opts["sprint"] = id == "sprint"
	opts["setups"] = setups
	if grids.has(id):
		opts["grid"] = grids[id]
	opts.merge(extra, true)
	return RaceSim.new(track, tyres, teams, drivers, opts)


# --- fim de cada sessão -----------------------------------------------------------------

func finish_practice(p: PracticeSession) -> void:
	_store(p.standings())
	_next()


func finish_quali(q: QualiSim) -> void:
	var order := q.standings()
	_store(order)
	grids["sprint" if session_id() == "sprint_quali" else "race"] = q.grid_ids()
	_next()


func finish_race(sim: RaceSim) -> void:
	var order := sim.standings()
	_store(order)
	for i in order.size():
		var car := order[i]
		if not (car.retired or car.disqualified):
			points[car.driver["id"]] += RaceSim.points_for(i + 1, sim.sprint)
	_next()


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
