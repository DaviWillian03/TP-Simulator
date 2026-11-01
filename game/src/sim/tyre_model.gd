class_name TyreModel
extends RefCounted
## Regras e comportamento dos pneus: perda de tempo por composto e desgaste,
## taxa de desgaste e a regra de compostos obrigatórios da F1 2026.

const WORN_OUT_PENALTY_S := 5.0  ## pneu totalmente gasto: perda grande e imediata

var compounds: Dictionary = {}
var min_dry_compounds := 2
var exempt_if_wet_used := true


func _init(data: Dictionary) -> void:
	compounds = data["compounds"]
	min_dry_compounds = int(data["rule"]["min_dry_compounds"])
	exempt_if_wet_used = bool(data["rule"]["exempt_if_wet_compound_used"])


func dry_compounds() -> Array[String]:
	var out: Array[String] = []
	for id: String in ["soft", "medium", "hard"]:
		if compounds.has(id):
			out.append(id)
	return out


func is_dry(compound: String) -> bool:
	return bool(compounds[compound]["dry"])


## Segundos perdidos por volta em relação ao pneu ideal (macio novo).
## Cresce com o quadrado do desgaste e acelera depois do "penhasco" (cliff).
func pace_penalty(compound: String, wear: float) -> float:
	var c: Dictionary = compounds[compound]
	var w := clampf(wear, 0.0, 1.0)
	var penalty := float(c["pace_offset_s"]) + float(c["deg_coeff"]) * w * w
	var cliff := float(c["cliff_start"])
	if w > cliff:
		penalty += float(c["cliff_coeff"]) * pow(w - cliff, 2.0)
	if wear >= 1.0:
		penalty += WORN_OUT_PENALTY_S
	return penalty


## Fração de desgaste por volta numa corrida de 100% (antes de multiplicadores).
func wear_per_lap(compound: String) -> float:
	return float(compounds[compound]["wear_per_lap"])


## Quantas voltas o composto aguenta até o início do penhasco, com o multiplicador dado.
func expected_life_laps(compound: String, wear_multiplier: float) -> float:
	var per_lap := wear_per_lap(compound) * wear_multiplier
	return float(compounds[compound]["cliff_start"]) / maxf(per_lap, 0.0001)


## Regra 2026: usar pelo menos N compostos de pista seca diferentes,
## a menos que um pneu intermediário ou de chuva tenha sido usado.
func rule_satisfied(used: Array) -> bool:
	var dry_used := {}
	for c: String in used:
		if not is_dry(c):
			if exempt_if_wet_used:
				return true
		else:
			dry_used[c] = true
	return dry_used.size() >= min_dry_compounds
