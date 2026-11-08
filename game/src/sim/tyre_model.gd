class_name TyreModel
extends RefCounted
## Regras e comportamento dos pneus: perda de tempo por composto e desgaste,
## taxa de desgaste e a regra de compostos obrigatórios da F1 2026.

const WORN_OUT_PENALTY_S := 5.0  ## pneu totalmente gasto: perda grande e imediata

var compounds: Dictionary = {}
var min_dry_compounds := 2
var exempt_if_wet_used := true
var allowed: Array = []  ## compostos da categoria (F2: duro/macio/chuva; F3: médio/chuva); vazio = todos


## Limita os compostos aos da categoria (CategoryRules: chaves de "dry" e "wet").
func restrict_to(cat: String) -> void:
	var r := CategoryRules.of(cat)
	allowed = (r["dry"] as Dictionary).keys() + (r["wet"] as Dictionary).keys()
	if not bool(r.get("compound_rule", true)):
		min_dry_compounds = 1


func has_compound(id: String) -> bool:
	return compounds.has(id) and (allowed.is_empty() or allowed.has(id))


func _init(data: Dictionary) -> void:
	compounds = data["compounds"]
	min_dry_compounds = int(data["rule"]["min_dry_compounds"])
	exempt_if_wet_used = bool(data["rule"]["exempt_if_wet_compound_used"])


func dry_compounds() -> Array[String]:
	var out: Array[String] = []
	for id: String in ["soft", "medium", "hard"]:
		if has_compound(id):
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


## Segundos perdidos por volta por estar com este composto na umidade dada
## (interpolação da curva "wet_curve" do arquivo de dados).
func wet_penalty(compound: String, wetness: float) -> float:
	var curve: Array = compounds[compound].get("wet_curve", [0, 0, 0, 0, 0, 0])
	var x := clampf(wetness, 0.0, 1.0) * (curve.size() - 1)
	var i := mini(floori(x), curve.size() - 2)
	return lerpf(float(curve[i]), float(curve[i + 1]), x - i)


## Pneus de chuva gastam muito mais quando a pista está mais seca que o ideal (superaquecem).
func wet_wear_multiplier(compound: String, wetness: float) -> float:
	var c: Dictionary = compounds[compound]
	if not c.has("wet_optimum"):
		return 1.0
	return 1.0 + 3.0 * maxf(0.0, float(c["wet_optimum"]) - wetness)


## Composto mais rápido para a umidade dada, entre os candidatos (padrão: todos).
func best_for_wetness(wetness: float, candidates: Array = []) -> String:
	var list: Array = (candidates if not candidates.is_empty() else compounds.keys()).filter(func(c: String) -> bool: return has_compound(c))
	if list.is_empty():  # categoria sem intermediário (F2/F3): só o de chuva
		list = compounds.keys().filter(func(c: String) -> bool: return has_compound(c))
	var best := ""
	var best_t := INF
	for c: String in list:
		var t := wet_penalty(c, wetness) + float(compounds[c]["pace_offset_s"])
		if t < best_t:
			best_t = t
			best = c
	return best


## "slick", "inter" ou "wet": o tipo de pneu, sem considerar o composto seco.
func tyre_class(compound: String) -> String:
	return "slick" if is_dry(compound) else compound


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
