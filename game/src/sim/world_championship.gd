class_name WorldChampionship
extends RefCounted
## Modo "Campeonato Mundial F1" (decisões de 2026-11-10): temporada completa de 2026 (22 GPs), pontos, tabelas e
## estatísticas, SEM desenvolvimento de carro. A força de cada carro em cada pista vem da temporada real
## (`data/real_form_2026.json`, gerado por tools/make_real_form.py, já com o grid ~40% mais equilibrado). Motor e câmbio
## têm limite por temporada com punição de grid (WorldParts). Pilotos e contratos são os reais de 2026.

const SAVE_PATH := "user://world_championship.json"  ## (legado: antes dos slots; hoje o save fica em SaveSlots.world_path())
const FORM_WITH_DATA := 0.3  ## variação aleatória do fim de semana quando já há resultado real da pista
const FORM_NO_DATA := 0.8  ## pista ainda sem resultado real: só a nota base + variação normal

var season := 2026
var season_id := Season.DEFAULT  ## pacote de temporada (data/seasons/<id>): 2026 ou temporada extra (2012…)
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
var season_log: Dictionary = {}  ## id do piloto -> {wins, podiums, poles} (mesmo formato da campanha: a corrida lê daqui)
var champions_log: Array = []  ## o Mundial tem uma temporada só por enquanto (sem histórico de campeões anteriores)
var _real: Dictionary = {}


static func start(team_id: String, sid: String = Season.DEFAULT) -> WorldChampionship:
	var w := WorldChampionship.new()
	w.season_id = sid
	w.season = Season.year(sid)
	w.player_team = team_id
	w.seed_base = randi() % 1_000_000 + 1
	w.parts.limits = Season.parts_limits(sid).duplicate()
	w.parts.setup(w.teams(), w.seed_base)
	return w


# --- calendário e tabelas ------------------------------------------------------------------

## Calendário da temporada 2026 (uso estático antigo); o da temporada deste Mundial é `cal()`.
static func calendar() -> Array:
	return Campaign.calendar()


## Etapas sem traçado ainda (2012: Valência, Coreia e Índia, `missing` no calendário) ficam de fora por enquanto
## (decisão de 2026-11-12: Mundial 2012 com 17 GPs até as pistas existirem).
func cal() -> Array:
	return Season.calendar(season_id).filter(func(r: Dictionary) -> bool: return not bool(r.get("missing", false)))


func season_over() -> bool:
	return round >= cal().size()


func next_round() -> Dictionary:
	return {} if season_over() else cal()[round]


func drivers() -> Array:
	return Season.drivers(season_id)


func teams() -> Array:
	return Season.teams(season_id)


func is_feeder() -> bool:
	return false


## Etapas que ainda restam depois da corrida atual (contrato igual ao da campanha: o campeonato ao vivo da corrida usa).
func remaining_after_current() -> Dictionary:
	var cal := cal()
	var races := 0
	var sprints := 0
	for i in range(round + 1, cal.size()):
		races += 1
		if bool(cal[i].get("sprint", false)):
			sprints += 1
	return {"races": races, "sprints": sprints}


## Carreira do piloto: títulos que ele já tinha antes de 2026 (dos dados) mais as vitórias/pódios/poles desta temporada.
func career_of(d: Dictionary) -> Dictionary:
	var base: Dictionary = d.get("career_2025", {})
	var lg: Dictionary = season_log.get(String(d.get("id", "")), {})
	var out := {}
	for k: String in ["starts", "wins", "podiums", "poles", "titles"]:
		out[k] = int(base.get(k, d.get("titles", 0) if k == "titles" else 0)) + (int(lg.get(k, 0)) if k != "titles" else 0)
	return out


func _rebuild_log() -> void:
	season_log.clear()
	for k: String in ["wins", "podiums", "poles"]:
		var src: Dictionary = get(k)
		for id: String in src:
			var row: Dictionary = season_log.get(id, {"wins": 0, "podiums": 0, "poles": 0})
			row[k] = int(src[id])
			season_log[id] = row


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
	for t: Dictionary in teams():
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
		_real = Season.real_form(season_id)
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
	for t: Dictionary in teams():
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
	for t: Dictionary in teams():
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
		"teams": teams_for_gp(cid), "drivers": drivers(), "category": Season.category(season_id), "form": FORM_WITH_DATA if has_real_data(cid) else FORM_NO_DATA}
	if not rd.is_empty():
		o["sprint"] = bool(rd.get("sprint", false))
		if rd.has("compounds"):
			o["dry_pair"] = rd["compounds"]
		o["grid_penalties"] = grid_penalties()
		if round >= cal().size() / 2:  # quem briga pelo título arrisca menos na classificação
			var champ := {}
			var rows := driver_standings()
			for i in rows.size():
				champ[rows[i][0]] = i + 1
			o["championship"] = champ
	o.merge(extra, true)
	return o


# --- fim de semana ----------------------------------------------------------------------------

func record_weekend(w: WeekendSim) -> void:
	var before_drivers := _positions(driver_standings())  # para mostrar quem subiu e quem desceu
	var before_teams := _positions(team_standings())
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
	var pole_time := 0.0
	if pole != "" and w.quali_times.has("race"):
		pole_time = float((w.quali_times["race"] as Dictionary).get(pole, {}).get("time", 0.0))
	var gains: Dictionary = {}  # posições ganhas/perdidas em relação à largada
	var grid: Array = w.grids.get("race", [])
	for i in race.size():
		var gi := grid.find(race[i])
		if gi >= 0:
			gains[race[i]] = gi - i
	var race_pts: Dictionary = {}
	for id: String in w.points:
		race_pts[id] = int(w.points[id])
	var quali: Dictionary = {}  # melhor volta de cada piloto na classificação (duelo de companheiros)
	for id: String in (w.quali_times.get("race", {}) as Dictionary):
		var qt := float((w.quali_times["race"][id] as Dictionary).get("time", 0.0))
		if qt > 0.0 and qt < 100000.0:
			quali[id] = qt
	history.append({"quali": quali, "round": round + 1, "circuit": String(w.circuit.get("id", "")), "results": race, "pole": pole, "pole_time": pole_time,
		"retired": out, "fastest": w.fastest_laps.get("race", {}), "grid": grid, "gains": gains, "points": race_pts,
		"before_drivers": before_drivers, "before_teams": before_teams, "sprint": (w.results.get("sprint", []) as Array)})
	for did: String in w.grid_penalties:  # punição de grid dos seus carros vira notícia
		if team_of(did) != player_team:
			continue
		var pen: Dictionary = w.grid_penalties[did]
		var what: Array = (pen["parts"] as Array).map(func(x: Dictionary) -> String: return "%dº %s" % [int(x["n"]), "motor" if x["part"] == "pu" else "câmbio"])
		news.append({"round": round + 1, "text": "%s largou %s por usar o %s (limite: 4)." % [did, "do fundo do grid" if bool(pen["back"]) else "%d posições atrás" % int(pen["places"]), ", ".join(what)]})
	_rebuild_log()
	parts.after_race(teams())
	round += 1


func _positions(rows: Array) -> Dictionary:
	var out := {}
	for i in rows.size():
		out[rows[i][0]] = i + 1
	return out


## Contagens da temporada por piloto ou equipe: stat = wins | poles | podiums | dnfs. [[id, n], ...] do maior ao menor (só quem tem n > 0).
func stat_table(stat: String, by_team: bool = false) -> Array:
	var src: Dictionary = {"wins": wins, "poles": poles, "podiums": podiums, "dnfs": dnfs}.get(stat, {})
	var acc: Dictionary = {}
	for id: String in src:
		var key := team_of(id) if by_team else id
		acc[key] = int(acc.get(key, 0)) + int(src[id])
	var rows: Array = []
	for k: String in acc:
		if int(acc[k]) > 0:
			rows.append([k, int(acc[k])])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1] if a[1] != b[1] else String(a[0]) < String(b[0]))
	return rows


## Duelo entre os dois pilotos de uma equipe na temporada: placar da classificação e da corrida (quem ficou à frente),
## vantagem média de tempo na classificação (gap > 0: o piloto "a" é mais rápido) e pontos.
func teammate_duel(team_id: String) -> Dictionary:
	var ids := driver_ids_of(team_id)
	if ids.size() < 2:
		return {}
	var a := String(ids[0])
	var b := String(ids[1])
	var q := [0, 0]
	var r := [0, 0]
	var gap_sum := 0.0
	var gap_n := 0
	for h: Dictionary in history:
		var times: Dictionary = h.get("quali", {})
		var grid: Array = h.get("grid", [])
		if times.has(a) and times.has(b):
			q[0 if float(times[a]) <= float(times[b]) else 1] += 1
			gap_sum += float(times[b]) - float(times[a])
			gap_n += 1
		elif grid.has(a) and grid.has(b):  # save antigo, sem os tempos: vale a posição no grid
			q[0 if grid.find(a) < grid.find(b) else 1] += 1
		var res: Array = h.get("results", [])
		var out: Array = h.get("retired", [])
		var a_out := out.has(a) or not res.has(a)
		var b_out := out.has(b) or not res.has(b)
		if a_out and b_out:
			continue
		if a_out != b_out:
			r[1 if a_out else 0] += 1
		else:
			r[0 if res.find(a) < res.find(b) else 1] += 1
	return {"a": a, "b": b, "quali": q, "race": r, "gap": gap_sum / gap_n if gap_n > 0 else 0.0, "gap_n": gap_n,
		"points": [int(driver_points.get(a, 0)), int(driver_points.get(b, 0))]}


## Resumo do campeão no fim da temporada.
func champions() -> Dictionary:
	var d := driver_standings()
	var t := team_standings()
	return {"driver": d[0][0] if not d.is_empty() else "", "driver_points": d[0][1] if not d.is_empty() else 0,
		"team": t[0][0] if not t.is_empty() else "", "team_points": t[0][1] if not t.is_empty() else 0}


# --- save -------------------------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"save_version": SaveSlots.VERSION, "season": season, "season_id": season_id, "player_team": player_team, "round": round, "seed_base": seed_base,
		"driver_points": driver_points, "team_points": team_points, "wins": wins, "poles": poles, "podiums": podiums,
		"dnfs": dnfs, "history": history, "news": news, "parts": parts.to_dict()}


static func from_dict(d: Dictionary) -> WorldChampionship:
	var w := WorldChampionship.new()
	w.season = int(d.get("season", 2026))
	w.season_id = String(d.get("season_id", Season.DEFAULT))
	w.parts.limits = Season.parts_limits(w.season_id).duplicate()
	w.player_team = String(d.get("player_team", ""))
	w.round = int(d.get("round", 0))
	w.seed_base = int(d.get("seed_base", 1))
	for k: String in ["driver_points", "team_points", "wins", "poles", "podiums", "dnfs"]:
		var src: Dictionary = d.get(k, {})
		var dst: Dictionary = {}
		for id: String in src:
			dst[id] = int(src[id])
		w.set(k, dst)
	w._rebuild_log()
	w.history = d.get("history", [])
	w.news = d.get("news", [])
	w.parts.from_dict(d.get("parts", {}))
	if w.parts.state.is_empty():
		w.parts.setup(w.teams(), w.seed_base)
	return w


func save(path: String = "") -> bool:
	if path == "":
		path = SaveSlots.world_path()
		SaveSlots.ensure()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(to_dict(), " "))
	return true


static func load_saved(path: String = "") -> WorldChampionship:
	if path == "":
		path = SaveSlots.world_path()
	if not FileAccess.file_exists(path):
		return null
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return from_dict(d) if d is Dictionary and SaveSlots.compatible(d) else null


static func has_save(path: String = "") -> bool:
	return FileAccess.file_exists(path if path != "" else SaveSlots.world_path())
