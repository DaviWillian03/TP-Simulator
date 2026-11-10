class_name WorldChampionship
extends RefCounted
## Modo "Campeonato Mundial F1" (decisões de 2026-11-10): temporada completa de 2026 (22 GPs), pontos, tabelas e
## estatísticas, SEM desenvolvimento de carro. A força de cada carro em cada pista vem da temporada real
## (`data/real_form_2026.json`, gerado por tools/make_real_form.py, já com o grid ~40% mais equilibrado). Motor e câmbio
## têm limite por temporada com punição de grid (WorldParts). Pilotos e contratos são os reais de 2026.

const SAVE_PATH := "user://world_championship.json"
const FORM_WITH_DATA := 0.3  ## variação aleatória do fim de semana quando já há resultado real da pista
const FORM_NO_DATA := 0.8  ## pista ainda sem resultado real: só a nota base + variação normal

var season := 2026
var player_team := ""
var round := 0  ## próxima rodada do calendário (0 = primeira)
var seed_base := 1
var driver_points: Dictionary = {}  ## id do piloto -> pontos
var team_points: Dictionary = {}  ## id da equipe -> pontos
var wins: Dictionary = {}
var poles: Dictionary = {}
var podiums: Dictionary = {}
var dnfs: Dictionary = {}
var history: Array = []  ## [{round, circuit, results: [ids], pole, retired: [ids]}]
var news: Array = []  ## [{round, text}] punições de grid etc.
var parts := WorldParts.new()
var _real: Dictionary = {}


static func start(team_id: String) -> WorldChampionship:
	var w := WorldChampionship.new()
	w.player_team = team_id
	w.seed_base = randi() % 1_000_000 + 1
	w.parts.setup(GameData.teams(), w.seed_base)
	return w


# --- calendário e tabelas ------------------------------------------------------------------

static func calendar() -> Array:
	return Campaign.calendar()


func season_over() -> bool:
	return round >= calendar().size()


func next_round() -> Dictionary:
	return {} if season_over() else calendar()[round]


func drivers() -> Array:
	return GameData.drivers()


func driver_ids_of(team_id: String) -> Array:
	var out: Array = []
	for d: Dictionary in drivers():
		if d["team"] == team_id and out.size() < 2:
			out.append(d["id"])
	return out


func team_of(driver_id: String) -> String:
	for d: Dictionary in drivers():
		if d["id"] == driver_id:
			return d["team"]
	return ""


## [[id, pontos], ...] do primeiro ao último (desempate: vitórias, depois nome).
func driver_standings() -> Array:
	var rows: Array = []
	for d: Dictionary in drivers():
		rows.append([d["id"], int(driver_points.get(d["id"], 0))])
	rows.sort_custom(func(a: Array, b: Array) -> bool:
		if a[1] != b[1]:
			return a[1] > b[1]
		var wa := int(wins.get(a[0], 0))
		var wb := int(wins.get(b[0], 0))
		return wa > wb if wa != wb else String(a[0]) < String(b[0]))
	return rows


func team_standings() -> Array:
	var rows: Array = []
	for t: Dictionary in GameData.teams():
		rows.append([t["id"], int(team_points.get(t["id"], 0))])
	rows.sort_custom(func(a: Array, b: Array) -> bool:
		return a[1] > b[1] if a[1] != b[1] else String(a[0]) < String(b[0]))
	return rows


func driver_position(id: String) -> int:
	var rows := driver_standings()
	for i in rows.size():
		if rows[i][0] == id:
			return i + 1
	return 0


func team_position(id: String) -> int:
	var rows := team_standings()
	for i in rows.size():
		if rows[i][0] == id:
			return i + 1
	return 0


# --- força dos carros (temporada real) ------------------------------------------------------

func real_form() -> Dictionary:
	if _real.is_empty():
		_real = GameData.load_json(GameData.DATA_DIR + "real_form_2026.json")
	return _real


func has_real_data(circuit_id: String) -> bool:
	return (real_form().get("rounds", {}) as Dictionary).has(circuit_id)


## Cópia das equipes para o GP: nota = base real equilibrada + desvio real da pista; carros levam o fator de
## quebra pelo desgaste do motor/câmbio.
func teams_for_gp(circuit_id: String) -> Array:
	var rf := real_form()
	var base: Dictionary = rf.get("base", {})
	var offs: Dictionary = (rf.get("rounds", {}) as Dictionary).get(circuit_id, {})
	var out: Array = []
	for t: Dictionary in GameData.teams():
		var c := t.duplicate()
		var id := String(t["id"])
		c["car_rating"] = float(base.get(id, t["car_rating"])) + float(offs.get(id, 0.0))
		var fail := {}
		var ids := driver_ids_of(id)
		for i in mini(ids.size(), 2):
			fail[ids[i]] = parts.worn_fail_mult(id, i)
		c["failure_by_driver"] = fail
		out.append(c)
	return out


func grid_penalties() -> Dictionary:
	var out := {}
	for t: Dictionary in GameData.teams():
		var ids := driver_ids_of(String(t["id"]))
		for i in mini(ids.size(), 2):
			var pen := parts.penalty_for(String(t["id"]), i)
			if int(pen["places"]) > 0:
				out[ids[i]] = pen
	return out


func weekend_options(extra: Dictionary = {}) -> Dictionary:
	var rd := next_round()
	var cid := String(rd.get("id", ""))
	var o := {"player_team": player_team, "seed": seed_base * 100 + round + 1, "campaign": true, "world": true,
		"teams": teams_for_gp(cid), "form": FORM_WITH_DATA if has_real_data(cid) else FORM_NO_DATA}
	if not rd.is_empty():
		o["sprint"] = bool(rd.get("sprint", false))
		o["grid_penalties"] = grid_penalties()
		if round >= calendar().size() / 2:  # quem briga pelo título arrisca menos na classificação
			var champ := {}
			var rows := driver_standings()
			for i in rows.size():
				champ[rows[i][0]] = i + 1
			o["championship"] = champ
	o.merge(extra, true)
	return o


# --- fim de semana ----------------------------------------------------------------------------

func record_weekend(w: WeekendSim) -> void:
	var race: Array = w.results.get("race", [])
	var pole := ""
	if w.quali_times.has("race") and w.grids.has("race") and not (w.grids["race"] as Array).is_empty():
		pole = String(w.grids["race"][0])
	for id: String in w.points:
		var pts := int(w.points[id])
		driver_points[id] = int(driver_points.get(id, 0)) + pts
		var tid := team_of(id)
		team_points[tid] = int(team_points.get(tid, 0)) + pts
	if not race.is_empty():
		wins[race[0]] = int(wins.get(race[0], 0)) + 1
		for i in mini(3, race.size()):
			podiums[race[i]] = int(podiums.get(race[i], 0)) + 1
	if pole != "":
		poles[pole] = int(poles.get(pole, 0)) + 1
	var out: Array = (w.retired.get("race", []) as Array).duplicate()
	for id: String in out:
		dnfs[id] = int(dnfs.get(id, 0)) + 1
	history.append({"round": round + 1, "circuit": String(w.circuit.get("id", "")), "results": race, "pole": pole, "retired": out})
	for did: String in w.grid_penalties:  # punição de grid dos seus carros vira notícia
		if team_of(did) != player_team:
			continue
		var pen: Dictionary = w.grid_penalties[did]
		var what: Array = (pen["parts"] as Array).map(func(x: Dictionary) -> String: return "%dº %s" % [int(x["n"]), "motor" if x["part"] == "pu" else "câmbio"])
		news.append({"round": round + 1, "text": "%s largou %s por usar o %s (limite: 4)." % [did, "do fundo do grid" if bool(pen["back"]) else "%d posições atrás" % int(pen["places"]), ", ".join(what)]})
	parts.after_race(GameData.teams())
	round += 1


## Resumo do campeão no fim da temporada.
func champions() -> Dictionary:
	var d := driver_standings()
	var t := team_standings()
	return {"driver": d[0][0] if not d.is_empty() else "", "driver_points": d[0][1] if not d.is_empty() else 0,
		"team": t[0][0] if not t.is_empty() else "", "team_points": t[0][1] if not t.is_empty() else 0}


# --- save -------------------------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"season": season, "player_team": player_team, "round": round, "seed_base": seed_base,
		"driver_points": driver_points, "team_points": team_points, "wins": wins, "poles": poles, "podiums": podiums,
		"dnfs": dnfs, "history": history, "news": news, "parts": parts.to_dict()}


static func from_dict(d: Dictionary) -> WorldChampionship:
	var w := WorldChampionship.new()
	w.season = int(d.get("season", 2026))
	w.player_team = String(d.get("player_team", ""))
	w.round = int(d.get("round", 0))
	w.seed_base = int(d.get("seed_base", 1))
	for k: String in ["driver_points", "team_points", "wins", "poles", "podiums", "dnfs"]:
		var src: Dictionary = d.get(k, {})
		var dst: Dictionary = {}
		for id: String in src:
			dst[id] = int(src[id])
		w.set(k, dst)
	w.history = d.get("history", [])
	w.news = d.get("news", [])
	w.parts.from_dict(d.get("parts", {}))
	if w.parts.state.is_empty():
		w.parts.setup(GameData.teams(), w.seed_base)
	return w


func save(path: String = SAVE_PATH) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(to_dict(), " "))
	return true


static func load_saved(path: String = SAVE_PATH) -> WorldChampionship:
	if not FileAccess.file_exists(path):
		return null
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return from_dict(d) if d is Dictionary else null


static func has_save(path: String = SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)
