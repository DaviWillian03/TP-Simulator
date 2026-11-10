class_name WorldParts
extends RefCounted
## Controle de motor e câmbio do Campeonato Mundial (sem desenvolvimento de carro). Cada carro tem limite de
## unidades na temporada (CarParts.LIMITS); passou do limite, o carro larga atrás (CarParts.PENALTY_*).
## Todas as equipes seguem a mesma regra automática: troca a unidade quando o desgaste passa de um corte
## (70% ± variação; já no limite, só com 95%). Motor novo na corrida = unidade nova para a conta do limite.

const REPLACE_AT := 70.0
const REPLACE_JITTER := 6.0  ## cada equipe/carro troca um pouco antes ou depois (sorteio fixo pela semente)

## "equipe|carro|peça" -> {n: unidades usadas, wear: desgaste da atual, fresh: ainda não correu, cut: corte de troca}
var state: Dictionary = {}


func setup(teams: Array, seed_value: int) -> void:
	state.clear()
	for t: Dictionary in teams:
		for car in 2:
			for pid: String in CarParts.LIMITS:
				var rng := RandomNumberGenerator.new()
				rng.seed = hash("wparts|%d|%s|%d|%s" % [seed_value, t["id"], car, pid])
				state[_key(String(t["id"]), car, pid)] = {"n": 1, "wear": 0.0, "fresh": true,
					"cut": REPLACE_AT + rng.randf_range(-REPLACE_JITTER, REPLACE_JITTER)}


static func _key(team_id: String, car: int, pid: String) -> String:
	return "%s|%d|%s" % [team_id, car, pid]


func unit(team_id: String, car: int, pid: String) -> Dictionary:
	return state.get(_key(team_id, car, pid), {})


## Quantas unidades o carro já usou na temporada (a atual conta se já correu ou se vai correr agora).
func used_count(team_id: String, car: int, pid: String) -> int:
	return int(unit(team_id, car, pid).get("n", 0))


## Punição de grid de cada carro se correr agora: {places, back, parts: [{part, n}]} (mesmo formato do CarParts).
func penalty_for(team_id: String, car: int) -> Dictionary:
	var out := {"places": 0, "back": false, "parts": []}
	for pid: String in CarParts.LIMITS:
		var u := unit(team_id, car, pid)
		if u.is_empty() or not bool(u["fresh"]):
			continue
		var n := int(u["n"])
		if n > int(CarParts.LIMITS[pid]):
			out["places"] = int(out["places"]) + (int(CarParts.PENALTY_FIRST[pid]) if n == int(CarParts.LIMITS[pid]) + 1 else int(CarParts.PENALTY_NEXT[pid]))
			out["parts"].append({"part": pid, "n": n})
	out["back"] = int(out["places"]) > CarParts.BACK_OF_GRID
	return out


## Multiplicador de quebras pelo desgaste (1 = novo), igual ao CarParts.worn_fail_mult.
func worn_fail_mult(team_id: String, car: int) -> float:
	var m := 1.0
	for pid: String in CarParts.LIMITS:
		var u := unit(team_id, car, pid)
		if not u.is_empty():
			m *= 1.0 + maxf(0.0, float(u["wear"]) - CarParts.WORN_FAIL_FROM) / (100.0 - CarParts.WORN_FAIL_FROM) * 0.8
	return m


## Depois da corrida: desgasta as unidades e já deixa a troca decidida para a próxima.
func after_race(teams: Array) -> void:
	for t: Dictionary in teams:
		for car in 2:
			for pid: String in CarParts.LIMITS:
				var u := unit(String(t["id"]), car, pid)
				if u.is_empty():
					continue
				u["fresh"] = false
				u["wear"] = minf(100.0, float(u["wear"]) + float(CarParts.part(pid).get("wear", 0)))
				var cut := float(u["cut"])
				if int(u["n"]) >= int(CarParts.LIMITS[pid]):
					cut = CarParts.LIMIT_REPLACE_WEAR  # no limite: estica a unidade para não tomar punição à toa
				if float(u["wear"]) >= cut:
					u["n"] = int(u["n"]) + 1
					u["wear"] = 0.0
					u["fresh"] = true


func to_dict() -> Dictionary:
	return state.duplicate(true)


func from_dict(d: Dictionary) -> void:
	state = d.duplicate(true)
