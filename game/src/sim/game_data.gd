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
	return load_json(DATA_DIR + "teams_2026.json")["teams"]


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
