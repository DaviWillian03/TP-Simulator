class_name CategoryRules
extends RefCounted
## Regras de cada categoria (F1, F2, F3) lidas de data/categories.json (decisões de 2026-11-08). Sem tela.
## F2/F3: chassi igual para todos (o "carro" é a operação da equipe), sem sistema híbrido, com DRS, um treino,
## classificação de sessão única, sprint com grid invertido e corrida principal.

static var _data: Dictionary = {}


static func all() -> Dictionary:
	if _data.is_empty():
		_data = GameData.load_json(GameData.DATA_DIR + "categories.json")["categories"]
	return _data


static func of(cat: String) -> Dictionary:
	return all().get(cat, all()["F1"])


static func is_feeder(cat: String) -> bool:
	return cat == "F2" or cat == "F3"


## Voltas de uma corrida da categoria nesta pista (F2/F3 pela distância em km; F1 usa as voltas da pista).
static func race_laps(cat: String, track: TrackModel, sprint: bool) -> int:
	var r := of(cat)
	if not r.has("feature_km"):
		return track.laps
	var km := float(r["sprint_km"] if sprint else r["feature_km"])
	return maxi(5, roundi(km * 1000.0 / maxf(track.length_m, 1.0)))


## Grid de uma categoria de base em 2026 (modo Grande Prêmio e corrida rápida): equipes e pilotos com vaga.
## Os números seguem a ordem das equipes nos dados (1, 2, 3...).
static func feeder_grid(cat: String) -> Dictionary:
	var sd: Dictionary = Series.data()["series"][cat]
	var teams: Array = []
	for t: Dictionary in sd["teams"]:
		var c := t.duplicate(true)
		c["category"] = cat
		c["car_rating"] = float(c["car_rating"])
		teams.append(c)
	var seats := int(sd["seats"])
	var drivers: Array = []
	var count := {}
	for d: Dictionary in GameData.load_json(GameData.DATA_DIR + "drivers_feeder_2026.json")["drivers"]:
		if String(d.get("category", "")) != cat:
			continue
		var tid := "%s_%s" % [cat.to_lower(), String(d.get("series_team_id", ""))]
		if GameData.team_by_id(teams, tid).is_empty() or int(count.get(tid, 0)) >= seats:
			continue
		count[tid] = int(count.get(tid, 0)) + 1
		var c := d.duplicate(true)
		c["team"] = tid
		drivers.append(c)
	drivers.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ia := _team_index(teams, a["team"])
		var ib := _team_index(teams, b["team"])
		return ia < ib if ia != ib else int(a.get("rating", 0)) > int(b.get("rating", 0)))
	for i in drivers.size():
		var d: Dictionary = drivers[i]
		d["number"] = i + 1
		if not d.has("code"):
			d["code"] = _code(String(d["name"]))
	return {"teams": teams, "drivers": drivers}


static func _team_index(teams: Array, id: String) -> int:
	for i in teams.size():
		if teams[i]["id"] == id:
			return i
	return 99


static func _code(name: String) -> String:
	var parts := name.split(" ", false)
	var last := String(parts[parts.size() - 1]).to_upper()
	return last.substr(0, 3)


## Rodadas (índices do calendário da F1) em que a categoria corre.
static func rounds(cat: String) -> Array:
	if not is_feeder(cat):
		return range((GameData.load_json(GameData.DATA_DIR + "calendar_2026.json")["rounds"] as Array).size())
	return (Series.data()["series"][cat]["rounds"] as Array).map(func(x: Variant) -> int: return int(x))
