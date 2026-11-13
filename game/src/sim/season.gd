class_name Season
extends RefCounted
## Pacote de temporada do Campeonato Mundial (2026-11-12): cada temporada (2026, 2012…) é uma pasta `data/seasons/<id>/` com
## `season.json` apontando para equipes, pilotos, calendário e forma real, mais a categoria de regras (categories.json:
## "F1" = 2026, "F1_2012" = V8 + KERS + DRS…). O Mundial passa equipes e pilotos ao fim de semana; nada de chave global.

const DEFAULT := "2026"

static var _cache: Dictionary = {}
## Temporada em jogo fora da campanha (Grande Prêmio/Mundial). TeamEmblems.use_season ajusta; GameData.any_team e o
## pessoal do treino consultam para não misturar 2012 com 2026 (cores, engenheiros).
static var active := DEFAULT


static func ids() -> Array:
	return ["2026", "2012"]


static func info(id: String) -> Dictionary:
	if not _cache.has(id):
		var path := GameData.DATA_DIR + "seasons/%s/season.json" % id
		_cache[id] = GameData.load_json(path) if FileAccess.file_exists(path) else {}
	return _cache[id]


static func is_ready(id: String) -> bool:
	return bool(info(id).get("ready", false))


static func year(id: String) -> int:
	return int(info(id).get("year", int(id) if id.is_valid_int() else 2026))


static func category(id: String) -> String:
	return String(info(id).get("category", "F1"))


static func _file(id: String, key: String) -> Variant:
	var path := String(info(id).get(key, ""))
	return GameData.load_json(path) if path != "" and FileAccess.file_exists(path) else null


static func teams(id: String) -> Array:
	var d: Variant = _file(id, "teams_file")
	return GameData.f1_spread((d as Dictionary).get("teams", [])) if d is Dictionary else GameData.teams()  # F1 +10% de diferença


static func drivers(id: String) -> Array:
	var d: Variant = _file(id, "drivers_file")
	return (d as Dictionary).get("drivers", []) if d is Dictionary else GameData.drivers()


static func calendar(id: String) -> Array:
	var d: Variant = _file(id, "calendar_file")
	return (d as Dictionary).get("rounds", []) if d is Dictionary else Campaign.calendar()


static func real_form(id: String) -> Dictionary:
	var d: Variant = _file(id, "real_form_file")
	return d if d is Dictionary else {}


## Par de compostos secos de uma pista na temporada (calendário daquele ano; pistas de outros anos: "other_tracks").
## Vazio = a temporada não restringe por pista.
static func compounds_for(id: String, circuit_id: String) -> Array:
	for rd: Dictionary in calendar(id):
		if String(rd["id"]) == circuit_id and rd.has("compounds"):
			return rd["compounds"]
	var d: Variant = _file(id, "calendar_file")
	var other: Dictionary = (d as Dictionary).get("other_tracks", {}) if d is Dictionary else {}
	return other.get(circuit_id, [])


## Engenheiros de corrida reais da temporada, por piloto ({id: {name, skill}}); vazio = genéricos.
static func engineers(id: String) -> Dictionary:
	var d: Variant = _file(id, "staff_file")
	return (d as Dictionary).get("engineers", {}) if d is Dictionary else {}


## Limites de motor e câmbio da temporada (regras da categoria; padrão = os de 2026).
static func parts_limits(id: String) -> Dictionary:
	return CategoryRules.of(category(id)).get("parts_limits", CarParts.LIMITS)
