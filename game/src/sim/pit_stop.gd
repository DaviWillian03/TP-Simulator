class_name PitStop
extends RefCounted
## Regras da parada no box: plano escolhido pelo jogador, custos em tempo parado e estoque de pneus.
## Valores PROVISÓRIOS (balancear depois). Sem dependência de tela.

const BASE_S := 2.4  ## troca dos 4 pneus
## Mini-jogo (ajuste de 2026-11-14: verde escuro ganha bem mais que o claro; cinza e "deixar passar" punem mais)
const TAP_PERFECT_S := -0.4  ## toque no verde escuro
const TAP_GOOD_BEST_S := -0.15  ## verde claro, colado no escuro (na borda de fora do verde claro: 0)
const TAP_MISS_S := 1.0  ## toque na área cinza
const TAP_NONE_S := 1.6  ## deixou o marcador passar sem tocar (mini-jogo aberto)
const QUEUE_GAP_S := 1.2  ## double stack: a equipe prepara o 2º jogo e reposiciona os macacos antes do carro de trás
const STACK_FUMBLE_CHANCE := 0.25  ## double stack: chance de a equipe, apressada, atrasar o carro de trás
## Erros de pit da IA (o jogador tem o mini-jogo): [chance acumulada, atraso mín., atraso máx., tipo]
const AI_PIT_ERRORS := [
	[0.012, 5.0, 10.0, "stuck"],  # porca/roda presa
	[0.06, 2.0, 4.5, "slow"],  # parada lenta
	[0.20, 0.5, 1.4, "small"],  # pequeno atraso
]
const USED_SET_WEAR := 0.15  ## jogo usado já rodou na classificação

## Estoque padrão por piloto (corrida rápida); no GP desce da classificação (WeekendSim).
const DEFAULT_STOCK := {
	"soft": {"new": 3, "used": 0}, "medium": {"new": 3, "used": 0}, "hard": {"new": 2, "used": 0},
	"inter": {"new": 3, "used": 0}, "wet": {"new": 2, "used": 0},
}


static func default_stock() -> Dictionary:
	return DEFAULT_STOCK.duplicate(true)


## Plano de parada. compound: composto a montar; use_used: gastar um jogo usado (se houver).
static func make_plan(compound: String, use_used := false, repair_wing := false, serve_penalty := true) -> Dictionary:
	return {"compound": compound, "use_used": use_used, "repair_wing": repair_wing, "serve_penalty": serve_penalty}


## Custos do plano em segundos parado (sem a sorte da parada). Devolve cada parcela e o total.
static func estimate(car: CarState, plan: Dictionary) -> Dictionary:
	var wing_change := RaceControl.WING_CHANGE_S if plan.get("repair_wing", false) else 0.0
	var penalty := car.penalty_pending_s if plan.get("serve_penalty", true) else 0.0
	var total := BASE_S + wing_change + penalty
	return {"base": BASE_S, "wing_change": wing_change, "penalty": penalty, "total": total}


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
## Verde escuro (1) = TAP_PERFECT_S; verde claro (0..1) = de 0 a TAP_GOOD_BEST_S; cinza (0) = TAP_MISS_S.
static func tap_delta(accuracy: float) -> float:
	if accuracy >= 1.0:
		return TAP_PERFECT_S
	if accuracy <= 0.0:
		return TAP_MISS_S
	return lerpf(0.0, TAP_GOOD_BEST_S, accuracy)


## Sorteia um erro de pit da IA: {"extra": segundos, "kind": "" | small | slow | stuck}.
static func ai_error(rng: RandomNumberGenerator) -> Dictionary:
	var r := rng.randf()
	for e: Array in AI_PIT_ERRORS:
		if r < float(e[0]):
			return {"extra": rng.randf_range(float(e[1]), float(e[2])), "kind": String(e[3])}
	return {"extra": 0.0, "kind": ""}
