class_name GameData
extends RefCounted
## Carrega os dados do jogo (arquivos JSON em res://data).
##
## O jogo é orientado a dados: equipes, pilotos, pneus e circuitos ficam em arquivos,
## não no código. Isso permite balancear valores sem programar e, no futuro, aplicar o
## arquivo de importação do Modo Edição por cima destes dados.

const DATA_DIR := "res://data/"


static func load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("GameData: arquivo não encontrado: %s" % path)
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed == null:
		push_error("GameData: JSON inválido em %s" % path)
	return parsed


static func teams() -> Array:
	return f1_spread(load_json(DATA_DIR + "teams_2026.json")["teams"])


## F1 10% mais desequilibrada (pedido de 2026-11-14, 2026 e 2012; F2/F3 não): a distância de cada carro até a média
## das notas cresce 10%. A ordem continua a da vida real.
const F1_SPREAD := 1.10


static func f1_spread(teams: Array) -> Array:
	if teams.is_empty():
		return teams
	var mean := 0.0
	for t: Dictionary in teams:
		mean += float(t["car_rating"])
	mean /= teams.size()
	for t: Dictionary in teams:
		t["car_rating"] = snappedf(mean + (float(t["car_rating"]) - mean) * F1_SPREAD, 0.01)
	return teams


## O mesmo para um dicionário equipe -> nota (base do Mundial).
static func f1_spread_map(ratings: Dictionary) -> Dictionary:
	if ratings.is_empty():
		return ratings
	var mean := 0.0
	for k: String in ratings:
		mean += float(ratings[k])
	mean /= ratings.size()
	var out := {}
	for k: String in ratings:
		out[k] = mean + (float(ratings[k]) - mean) * F1_SPREAD
	return out


static func drivers() -> Array:
	return load_json(DATA_DIR + "drivers_2026.json")["drivers"]


static func tyres() -> Dictionary:
	return load_json(DATA_DIR + "tyres_2026.json")


static func circuit(circuit_id: String) -> Dictionary:
	return load_json(DATA_DIR + "circuits/%s.json" % circuit_id)


static func team_by_id(team_list: Array, team_id: String) -> Dictionary:
	for t: Dictionary in team_list:
		if t["id"] == team_id:
			return t
	return {}


## Categoria de uma equipe pelo id ("f2_..." / "f3_..." = categorias de base; o resto é F1).
static func category_of(team_id: String) -> String:
	if team_id.begins_with("f2_"):
		return "F2"
	if team_id.begins_with("f3_"):
		return "F3"
	return "F1"


## Equipes e pilotos de 2026 de uma categoria (F1 dos dados; F2/F3 do grid real das categorias de base).
static func category_teams(cat: String) -> Array:
	return teams() if not CategoryRules.is_feeder(cat) else CategoryRules.feeder_grid(cat)["teams"]


static func category_drivers(cat: String) -> Array:
	return drivers() if not CategoryRules.is_feeder(cat) else CategoryRules.feeder_grid(cat)["drivers"]


## Equipe de qualquer categoria pelo id.
static func any_team(team_id: String) -> Dictionary:
	if Season.active != Season.DEFAULT and category_of(team_id) == "F1":  # temporada extra (2012): cores daquele ano
		var t := team_by_id(Season.teams(Season.active), team_id)
		if not t.is_empty():
			return t
	return team_by_id(category_teams(category_of(team_id)), team_id)
