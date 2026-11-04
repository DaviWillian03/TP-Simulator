class_name Series
extends RefCounted
## Um campeonato de base (F2 ou F3) correndo em paralelo à F1 na campanha (3 categorias, fase 1 — decisão 2026-11-04).
## Simulação estatística de cada rodada (classificação, sprint com os 10 primeiros invertidos e corrida principal), com o
## equilíbrio da categoria: ~30% carro, 50% piloto, 20% acaso/decisões. Os pilotos são os da base da campanha
## (Personnel.prospects); as vagas de cada equipe são preenchidas no começo do ano. Sem tela.

const CAR_W := 0.3
const DRIVER_W := 0.5
const NOISE := 5.5  ## desvio do "acaso" (largada, estratégia, erros) em pontos de nota
const DNF_CHANCE := 0.06
const REVERSE_TOP := 10

var cat := "F2"
var teams: Array = []  ## [{id, base_id, name, color, color2, shape, short_name, car_rating}]
var seats := 2
var rounds: Array = []  ## índices das rodadas da F1 em que a categoria corre
var seat_of: Dictionary = {}  ## id do piloto -> id da equipe
var points_d: Dictionary = {}
var points_t: Dictionary = {}
var results: Array = []  ## [{round (índice da F1), sprint: [ids], feature: [ids], out: [ids]}]
var pts_feature: Array = []
var pts_sprint: Array = []

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		_data = GameData.load_json(GameData.DATA_DIR + "feeder_teams_2026.json")
	return _data


static func make(category: String) -> Series:
	var s := Series.new()
	var d: Dictionary = data()["series"][category]
	s.cat = category
	s.seats = int(d["seats"])
	s.teams = (d["teams"] as Array).duplicate(true)
	s.rounds = (d["rounds"] as Array).map(func(x: Variant) -> int: return int(x))
	s.pts_feature = d["points_feature"]
	s.pts_sprint = d["points_sprint"]
	return s


func team(id: String) -> Dictionary:
	for t: Dictionary in teams:
		if t["id"] == id:
			return t
	return {}


## Pilotos da categoria que estão com vaga (os que correm).
func drivers_on_grid() -> Array:
	return seat_of.keys()


func team_drivers(team_id: String) -> Array:
	return seat_of.keys().filter(func(id: String) -> bool: return seat_of[id] == team_id)


## Começo do ano: quem continua na categoria mantém a vaga; as vagas livres vão para os melhores sem vaga (pilotos com
## equipe real de 2026 entram nela primeiro).
func assign_seats(prospects: Array) -> void:
	var in_cat := {}
	for p: Dictionary in prospects:
		if String(p.get("category", "")) == cat:
			in_cat[p["id"]] = p
	for id: String in seat_of.keys():
		if not in_cat.has(id) or team(String(seat_of[id])).is_empty():
			seat_of.erase(id)
	var count := {}
	for id: String in seat_of:
		count[seat_of[id]] = int(count.get(seat_of[id], 0)) + 1
	var free: Array = []
	for id: String in in_cat:
		if seat_of.has(id):
			continue
		var p: Dictionary = in_cat[id]
		var wanted := "%s_%s" % [cat.to_lower(), String(p.get("series_team_id", ""))]
		if not team(wanted).is_empty() and int(count.get(wanted, 0)) < seats:
			seat_of[id] = wanted
			count[wanted] = int(count.get(wanted, 0)) + 1
		else:
			free.append(p)
	free.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("rating", 0)) > int(b.get("rating", 0)))
	for t: Dictionary in teams:
		while int(count.get(t["id"], 0)) < seats and not free.is_empty():
			var p: Dictionary = free.pop_front()
			seat_of[p["id"]] = t["id"]
			count[t["id"]] = int(count.get(t["id"], 0)) + 1


func reset_season() -> void:
	points_d = {}
	points_t = {}
	results = []


func runs_on(f1_round: int) -> bool:
	return rounds.has(f1_round)


func rounds_done() -> int:
	return results.size()


## Simula a rodada da categoria (classificação → sprint invertida → corrida principal). ratings: id -> nota do piloto.
func simulate_round(f1_round: int, ratings: Dictionary, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|%d|%d" % [cat, f1_round, seed_value])
	var ids := drivers_on_grid()
	var base := {}
	for id: String in ids:
		var car := float(team(String(seat_of[id])).get("car_rating", 55.0))
		base[id] = DRIVER_W * float(ratings.get(id, 60)) + CAR_W * car
	# classificação (sessão única)
	var quali := ids.duplicate()
	var qscore := {}
	for id: String in quali:
		qscore[id] = float(base[id]) + rng.randfn(0.0, NOISE * 0.6)
	quali.sort_custom(func(a: String, b: String) -> bool: return float(qscore[a]) > float(qscore[b]))
	# sprint: os 10 primeiros largam invertidos
	var sprint_grid := quali.slice(0, REVERSE_TOP)
	sprint_grid.reverse()
	sprint_grid.append_array(quali.slice(REVERSE_TOP))
	var sprint := _race(sprint_grid, base, rng, 0.9)
	var feature := _race(quali, base, rng, 0.6)
	var out: Array = []
	for res: Array in [sprint, feature]:
		for id: String in res[1]:
			if not out.has(id):
				out.append(id)
	var r := {"round": f1_round, "sprint": sprint[0] + sprint[1], "feature": feature[0] + feature[1], "out_s": sprint[1], "out_f": feature[1]}
	_score(r["sprint"], sprint[1], pts_sprint)
	_score(r["feature"], feature[1], pts_feature)
	results.append(r)
	return r


## [classificados em ordem, abandonos]: a posição de largada vale (ultrapassar é difícil), o resto é ritmo e acaso.
func _race(grid: Array, base: Dictionary, rng: RandomNumberGenerator, grid_w: float) -> Array:
	var score := {}
	var dnf: Array = []
	for i in grid.size():
		var id: String = grid[i]
		if rng.randf() < DNF_CHANCE:
			dnf.append(id)
			continue
		score[id] = float(base[id]) + rng.randfn(0.0, NOISE) - float(i) * grid_w
	var fin: Array = score.keys()
	fin.sort_custom(func(a: String, b: String) -> bool: return float(score[a]) > float(score[b]))
	return [fin, dnf]


func _score(order: Array, out: Array, table: Array) -> void:
	for i in order.size():
		var id: String = order[i]
		if out.has(id) or i >= table.size():
			continue
		points_d[id] = int(points_d.get(id, 0)) + int(table[i])
		var t := String(seat_of.get(id, ""))
		points_t[t] = int(points_t.get(t, 0)) + int(table[i])


func driver_standings() -> Array:
	var rows: Array = []
	for id: String in seat_of:
		rows.append([id, int(points_d.get(id, 0))])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1])
	return rows


func team_standings() -> Array:
	var rows: Array = []
	for t: Dictionary in teams:
		rows.append([t["id"], int(points_t.get(t["id"], 0))])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1])
	return rows


## Resultado de um piloto (posição na corrida principal, 0 = não correu, -1 = abandono) em cada rodada disputada.
func driver_results(id: String) -> Array:
	var out: Array = []
	for r: Dictionary in results:
		if (r["out_f"] as Array).has(id):
			out.append(-1)
		else:
			out.append((r["feature"] as Array).find(id) + 1)
	return out


## Melhor carro da equipe em cada rodada (corrida principal).
func team_results(team_id: String) -> Array:
	var out: Array = []
	for r: Dictionary in results:
		var best := 0
		var all_out := true
		for id: String in team_drivers(team_id):
			var p: int = (r["feature"] as Array).find(id) + 1
			if p > 0 and not (r["out_f"] as Array).has(id):
				all_out = false
				best = p if best == 0 else mini(best, p)
		out.append(-1 if all_out else best)
	return out


# --- salvar / carregar --------------------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"cat": cat, "teams": teams, "seats": seats, "rounds": rounds, "seat_of": seat_of, "points_d": points_d, "points_t": points_t, "results": results}


static func from_dict(d: Dictionary) -> Series:
	var s := make(String(d.get("cat", "F2")))
	s.teams = d.get("teams", s.teams)
	for t: Dictionary in s.teams:
		t["car_rating"] = float(t["car_rating"])
	s.seat_of = d.get("seat_of", {})
	for k: String in d.get("points_d", {}):
		s.points_d[k] = int(d["points_d"][k])
	for k: String in d.get("points_t", {}):
		s.points_t[k] = int(d["points_t"][k])
	s.results = d.get("results", [])
	for r: Dictionary in s.results:
		r["round"] = int(r["round"])
	return s
