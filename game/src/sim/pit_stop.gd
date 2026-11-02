class_name PitStop
extends RefCounted
## Regras da parada no box: plano escolhido pelo jogador, custos em tempo parado e estoque de pneus.
## Valores PROVISÓRIOS (balancear depois). Sem dependência de tela.

const BASE_S := 2.4  ## troca dos 4 pneus
const WING_STEP_S := 0.3  ## cada passo de ajuste da asa dianteira
const FLOOR_REPAIR_S := 1.2  ## reparo parcial do assoalho (recupera metade do dano)
const TAP_PERFECT_S := -0.3  ## mini-jogo: toque perfeito
const TAP_MISS_S := 0.6  ## mini-jogo: toque longe do verde (ou sem toque com a tela aberta)
const QUEUE_GAP_S := 0.5  ## folga de segurança entre dois carros da equipe no box
const USED_SET_WEAR := 0.15  ## jogo usado já rodou na classificação
const WING_MIN := -1
const WING_MAX := 2
## Efeito de cada passo de asa dianteira (positivo = mais pressão aerodinâmica)
const WING_LAP_S := 0.06  ## segundos por volta mais rápido
const WING_WEAR := 0.05  ## 5% mais desgaste de pneu

## Estoque padrão por piloto (corrida rápida); no GP desce da classificação (WeekendSim).
const DEFAULT_STOCK := {
	"soft": {"new": 3, "used": 0}, "medium": {"new": 3, "used": 0}, "hard": {"new": 2, "used": 0},
	"inter": {"new": 3, "used": 0}, "wet": {"new": 2, "used": 0},
}


static func default_stock() -> Dictionary:
	return DEFAULT_STOCK.duplicate(true)


## Plano de parada. compound: composto a montar; use_used: gastar um jogo usado (se houver).
static func make_plan(compound: String, use_used := false, wing_step := 0, repair_wing := false,
		repair_floor := false, serve_penalty := true) -> Dictionary:
	return {"compound": compound, "use_used": use_used, "wing_step": clampi(wing_step, WING_MIN, WING_MAX),
		"repair_wing": repair_wing, "repair_floor": repair_floor, "serve_penalty": serve_penalty}


## Custos do plano em segundos parado (sem a sorte da parada). Devolve cada parcela e o total.
static func estimate(car: CarState, plan: Dictionary) -> Dictionary:
	var wing_change := RaceControl.WING_CHANGE_S if plan.get("repair_wing", false) else 0.0
	var wing_adj := absf(float(plan.get("wing_step", car.wing_step) - car.wing_step)) * WING_STEP_S
	var floor_fix := FLOOR_REPAIR_S if plan.get("repair_floor", false) else 0.0
	var penalty := car.penalty_pending_s if plan.get("serve_penalty", true) else 0.0
	var total := BASE_S + wing_change + wing_adj + floor_fix + penalty
	return {"base": BASE_S, "wing_change": wing_change, "wing_adjust": wing_adj, "floor": floor_fix, "penalty": penalty, "total": total}


## O jogo pedido existe no estoque? (estoque vazio = ilimitado, caso da IA)
static func has_set(car: CarState, compound: String, use_used: bool) -> bool:
	if car.tyre_stock.is_empty():
		return true
	var st: Dictionary = car.tyre_stock.get(compound, {"new": 0, "used": 0})
	return int(st["used" if use_used else "new"]) > 0


## Gasta um jogo do estoque. Devolve true se o jogo era usado (o pneu começa com desgaste).
static func take_set(car: CarState, compound: String, use_used: bool) -> bool:
	if car.tyre_stock.is_empty():
		return false
	var st: Dictionary = car.tyre_stock.get(compound, {"new": 0, "used": 0})
	var key := "used" if use_used else "new"
	if int(st[key]) <= 0:  # o pedido acabou: usa o outro tipo, se houver
		key = "new" if key == "used" else "used"
	if int(st[key]) > 0:
		st[key] = int(st[key]) - 1
	return key == "used"


## Soma de jogos do composto (novos + usados).
static func sets_left(car: CarState, compound: String) -> int:
	if car.tyre_stock.is_empty():
		return 99
	var st: Dictionary = car.tyre_stock.get(compound, {"new": 0, "used": 0})
	return int(st["new"]) + int(st["used"])


## Toque do mini-jogo: accuracy 1 = no centro do verde, 0 = longe. Devolve o ajuste em segundos.
static func tap_delta(accuracy: float) -> float:
	return lerpf(TAP_MISS_S, TAP_PERFECT_S, clampf(accuracy, 0.0, 1.0))
