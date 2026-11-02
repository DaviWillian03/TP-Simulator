class_name Regulations
extends RefCounted
## Regulamento da campanha e Conselho de regras (mockup v13-2). Regras mutáveis na 1ª versão: pontuação, número de fins
## de semana sprint e regra de compostos de pneu. A cada fim de temporada o Conselho põe 3 propostas em votação (uma por
## tipo); todas as equipes votam (a IA pelo interesse: equipes fortes ou fracas, conforme a proposta), o jogador só vota
## (sem lobby), maioria simples (empate barra). As aprovadas valem na temporada seguinte. Valores PROVISÓRIOS (data/rules.json).

const KINDS := ["points", "sprint", "tyres"]
const AI_NOISE_PCT := 15  ## chance de a IA votar contra o próprio interesse

var points_race: Array = RaceSim.RACE_POINTS.duplicate()
var points_sprint: Array = RaceSim.SPRINT_POINTS.duplicate()
var sprint_ids: Array = []  ## circuitos com fim de semana sprint
var min_dry_compounds := 2
var proposals: Array = []  ## propostas em votação (cópias dos dados)
var votes: Dictionary = {}  ## id da proposta -> {id da equipe: "y"/"n"/"w"} (só a IA)
var player_votes: Dictionary = {}  ## id da proposta -> "y"/"n"/"w"
var vote_season := 0
var history: Array = []  ## [{season, id, title, passed, yes, no}]

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		_data = GameData.load_json(GameData.DATA_DIR + "rules.json")
	return _data


func setup() -> void:
	sprint_ids.clear()
	for r: Dictionary in Campaign.calendar():
		if r.get("sprint", false):
			sprint_ids.append(r["id"])
	points_race = RaceSim.RACE_POINTS.duplicate()
	points_sprint = RaceSim.SPRINT_POINTS.duplicate()
	min_dry_compounds = 2
	proposals.clear()
	votes.clear()
	player_votes.clear()
	history.clear()


func is_sprint(circuit_id: String) -> bool:
	return sprint_ids.has(circuit_id)


func points_for(position: int, is_sprint_race: bool) -> int:
	var table: Array = points_sprint if is_sprint_race else points_race
	return int(table[position - 1]) if position >= 1 and position <= table.size() else 0


## Linhas da lista "regras em vigor" (rótulo, valor).
func rule_lines(season: int) -> Array:
	var race := "-".join(points_race.map(func(p: Variant) -> String: return str(int(p))))
	var spr := "-".join(points_sprint.map(func(p: Variant) -> String: return str(int(p))))
	return [["Pontuação da corrida", race], ["Pontuação da sprint", spr], ["Fins de semana sprint", "%d de %d" % [sprint_ids.size(), Campaign.calendar().size()]],
		["Compostos secos obrigatórios", str(min_dry_compounds)], ["Motor", "Híbrido 2026 (V6)"], ["Valem para", "Temporada %d" % season]]


# --- votação -----------------------------------------------------------------------------------

func vote_open(camp: Campaign) -> bool:
	return camp.season_over()


## Abre (ou reabre) a votação do fim de temporada: escolhe uma proposta por tipo e calcula o voto da IA.
func open_vote(camp: Campaign) -> void:
	if vote_season == camp.season and not proposals.is_empty():
		return
	vote_season = camp.season
	proposals.clear()
	votes.clear()
	player_votes.clear()
	for kind: String in KINDS:
		var options: Array = []
		for p: Dictionary in data()["proposals"]:
			if p["kind"] == kind and _applicable(p):
				options.append(p)
		if options.is_empty():
			continue
		proposals.append(options[absi(hash("%d|%s" % [camp.season, kind])) % options.size()])
	for p: Dictionary in proposals:
		var v: Dictionary = {}
		for t: Dictionary in camp.teams():
			if t["id"] != camp.player_team:
				v[t["id"]] = _ai_vote(camp, t["id"], p)
		votes[p["id"]] = v
		player_votes[p["id"]] = "w"


func _applicable(p: Dictionary) -> bool:
	if p.has("points_race"):
		return p["points_race"] != points_race
	if p.has("sprint_delta"):
		var n := sprint_ids.size() + int(p["sprint_delta"])
		return n >= 2 and n <= data()["sprint_priority"].size()
	if p.has("min_dry_compounds"):
		return int(p["min_dry_compounds"]) != min_dry_compounds
	return false


func _ai_vote(camp: Campaign, team_id: String, p: Dictionary) -> String:
	var n := camp.teams().size()
	var rank := camp.rating_rank(team_id)
	var band := 0  # 0 forte, 1 meio, 2 fraca
	if rank > 2 * n / 3:
		band = 2
	elif rank > n / 3:
		band = 1
	var favors_top: bool = p["favors"] == "top"
	var vote := "w"
	if band == 0:
		vote = "y" if favors_top else "n"
	elif band == 2:
		vote = "n" if favors_top else "y"
	if absi(hash("%d|%s|%s" % [camp.season, team_id, p["id"]])) % 100 < AI_NOISE_PCT:
		vote = {"y": "n", "n": "y", "w": "w"}[vote]
	return vote


func cast(proposal_id: String, vote: String) -> void:
	if player_votes.has(proposal_id) and vote in ["y", "n", "w"]:
		player_votes[proposal_id] = vote


## Placar: {y, n, w, passed}. Abstenção não conta; empate barra.
func tally(proposal_id: String) -> Dictionary:
	var y := 0
	var n := 0
	var w := 0
	var all: Array = (votes.get(proposal_id, {}) as Dictionary).values()
	all.append(player_votes.get(proposal_id, "w"))
	for v: String in all:
		match v:
			"y":
				y += 1
			"n":
				n += 1
			_:
				w += 1
	return {"y": y, "n": n, "w": w, "passed": y > n}


## Aplica as propostas aprovadas (chamado na virada de temporada). Devolve as mensagens.
func apply_passed(camp: Campaign) -> Array[String]:
	var msgs: Array[String] = []
	for p: Dictionary in proposals:
		var t := tally(p["id"])
		history.append({"season": camp.season, "id": p["id"], "title": p["title"], "passed": t["passed"], "yes": t["y"], "no": t["n"]})
		if not t["passed"]:
			msgs.append("Conselho: rejeitada — %s" % p["title"].capitalize())
			continue
		if p.has("points_race"):
			points_race = p["points_race"].duplicate()
		if p.has("sprint_delta"):
			_change_sprints(int(p["sprint_delta"]))
		if p.has("min_dry_compounds"):
			min_dry_compounds = int(p["min_dry_compounds"])
		msgs.append("Conselho: aprovada — %s" % p["title"].capitalize())
	proposals.clear()
	votes.clear()
	player_votes.clear()
	return msgs


func _change_sprints(delta: int) -> void:
	var order: Array = data()["sprint_priority"]
	if delta > 0:
		for id: String in order:
			if delta == 0:
				break
			if not sprint_ids.has(id):
				sprint_ids.append(id)
				delta -= 1
	else:
		for i in range(order.size() - 1, -1, -1):
			if delta == 0:
				break
			if sprint_ids.has(order[i]):
				sprint_ids.erase(order[i])
				delta += 1


# --- salvar / carregar ------------------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"points_race": points_race, "points_sprint": points_sprint, "sprint_ids": sprint_ids, "min": min_dry_compounds, "proposals": proposals,
		"votes": votes, "player_votes": player_votes, "vote_season": vote_season, "history": history}


static func from_dict(d: Dictionary) -> Regulations:
	var r := Regulations.new()
	r.points_race = (d.get("points_race", RaceSim.RACE_POINTS) as Array).map(func(x: Variant) -> int: return int(x))
	r.points_sprint = (d.get("points_sprint", RaceSim.SPRINT_POINTS) as Array).map(func(x: Variant) -> int: return int(x))
	r.sprint_ids = d.get("sprint_ids", [])
	r.min_dry_compounds = int(d.get("min", 2))
	r.proposals = d.get("proposals", [])
	r.votes = d.get("votes", {})
	r.player_votes = d.get("player_votes", {})
	r.vote_season = int(d.get("vote_season", 0))
	r.history = d.get("history", [])
	return r
