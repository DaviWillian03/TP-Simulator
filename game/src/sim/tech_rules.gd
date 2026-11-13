class_name TechRules
extends RefCounted
## Regulamento técnico da campanha (decisão do usuário, 2026-11-04): motor, aerodinâmica, chassi/peso, reabastecimento e
## número de corridas mudam pelo Conselho e valem na temporada seguinte. Cada regra tem efeito REAL na corrida
## (não só na nota dos carros). Mudanças de motor, aerodinâmica e chassi são "anos de virada" (Campaign.regulation_reset).
## Valores PROVISÓRIOS.

const DEFAULT := {"engine": "v6h", "aero": "active", "chassis": "std", "refuel": false, "races": 23}

## lap: s/volta para todos; energy_k: peso dos modos de energia e da bateria; pitch: som do motor
const ENGINE := {
	"v6h": {"name": "V6 turbo híbrido (2026)", "lap": 0.0, "energy_k": 1.0, "pitch": 1.0},
	"v8": {"name": "V8 aspirado (combustível sustentável)", "lap": -0.4, "energy_k": 0.5, "pitch": 1.18},
	"v10": {"name": "V10 aspirado (combustível sustentável)", "lap": -0.8, "energy_k": 0.35, "pitch": 1.32},
	"hybrid_plus": {"name": "V6 híbrido com mais elétrico", "lap": -0.2, "energy_k": 1.5, "pitch": 0.94},
}
## overtake_k: multiplica a vantagem exigida para ultrapassar; dirty_k: perda andando colado
const AERO := {
	"active": {"name": "Aerodinâmica ativa (2026)", "lap": 0.0, "overtake_k": 1.0, "dirty_k": 1.0},
	"ground": {"name": "Efeito solo", "lap": -0.3, "overtake_k": 0.75, "dirty_k": 0.6},
	"drs": {"name": "Asas fixas com DRS", "lap": 0.0, "overtake_k": 0.85, "dirty_k": 1.3},
}
## wear_k: desgaste dos pneus
const CHASSIS := {
	"std": {"name": "Padrão 2026 (768 kg)", "lap": 0.0, "wear_k": 1.0},
	"light": {"name": "Carro menor e mais leve", "lap": -0.8, "wear_k": 0.9},
	"heavy": {"name": "Carro maior e mais pesado", "lap": 0.6, "wear_k": 1.15},
}
const REFUEL_FUEL_K := 0.35  ## com reabastecimento os carros largam leves (o peso do combustível pesa bem menos)
const REFUEL_WINDOW := 0.42  ## o tanque dura ~42% da corrida: pelo menos 2 paradas
const REFUEL_S := 3.5  ## segundos a mais parado para abastecer
const RESET_KINDS := ["engine", "aero", "chassis"]


static func merged(tech: Dictionary) -> Dictionary:
	var t := DEFAULT.duplicate()
	t.merge(tech, true)
	return t


## Botões da corrida (RaceSim/QualiSim) para um regulamento.
static func knobs(tech: Dictionary) -> Dictionary:
	var t := merged(tech)
	var e: Dictionary = ENGINE.get(t["engine"], ENGINE["v6h"])
	var a: Dictionary = AERO.get(t["aero"], AERO["active"])
	var c: Dictionary = CHASSIS.get(t["chassis"], CHASSIS["std"])
	return {"lap_s": float(e["lap"]) + float(a["lap"]) + float(c["lap"]), "energy_k": float(e["energy_k"]), "pitch": float(e["pitch"]),
		"overtake_k": float(a["overtake_k"]), "dirty_k": float(a["dirty_k"]), "wear_k": float(c["wear_k"]), "refuel": bool(t["refuel"])}


static func label(kind: String, value: Variant) -> String:
	match kind:
		"engine":
			return String(ENGINE.get(value, {}).get("name", value))
		"aero":
			return String(AERO.get(value, {}).get("name", value))
		"chassis":
			return String(CHASSIS.get(value, {}).get("name", value))
		"refuel":
			return "Permitido" if bool(value) else "Proibido"
		"races":
			return "%d corridas" % int(value)
	return str(value)
