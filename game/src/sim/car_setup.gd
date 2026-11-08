class_name CarSetup
extends RefCounted
## Acerto do carro num fim de semana: o quanto a equipe já se aproximou do acerto ideal
## deste circuito em cada área (0..1, mostrado em %). Os treinos livres aumentam esses valores;
## o resultado vale para a classificação e para a corrida.
##
## Valores de tempo PROVISÓRIOS (pesquisa de atributos pendente).

const AERO_S := 0.35  ## s/volta perdidos com acerto aerodinâmico em 0%
const MECH_S := 0.30  ## s/volta perdidos com acerto mecânico em 0%
const BALANCE_S := 0.15  ## s/volta perdidos com equilíbrio em 0%
const RACE_WEAR_GAIN := 0.08  ## simulação de corrida completa: até 8% menos desgaste de pneu
const QUALI_GAIN_S := 0.12  ## preparação de volta rápida completa: até 0,12 s na classificação

var aero := 0.4
var mech := 0.4
var balance := 0.4
var race_prep := 0.0
var quali_prep := 0.0


## Ponto de partida de cada carro ao chegar no circuito (simulador e dados de anos anteriores).
static func random_start(rng: RandomNumberGenerator) -> CarSetup:
	var s := CarSetup.new()
	s.aero = rng.randf_range(0.3, 0.55)
	s.mech = rng.randf_range(0.3, 0.55)
	s.balance = rng.randf_range(0.35, 0.6)
	return s


## Tempo perdido por volta por causa do acerto (0 = acerto perfeito).
func lap_penalty_s() -> float:
	return (1.0 - aero) * AERO_S + (1.0 - mech) * MECH_S + (1.0 - balance) * BALANCE_S


## Ganho na classificação pela preparação de volta rápida.
func quali_bonus_s() -> float:
	return quali_prep * QUALI_GAIN_S


## Multiplicador do desgaste de pneu na corrida (menor = gasta menos).
func wear_factor() -> float:
	return 1.0 - race_prep * RACE_WEAR_GAIN


## Aplica o acerto no carro de uma corrida.
func apply_to(car: CarState) -> void:
	car.setup_penalty_s = lap_penalty_s()
	car.wear_factor = wear_factor()


## Qualidade do acerto (0..1): média de aerodinâmica, mecânico e equilíbrio.
func quality() -> float:
	return (aero + mech + balance) / 3.0


## Nota do acerto para a tela (decisão de 2026-11-08): A ótimo, B bom, C regular, D ruim.
static func grade(q: float) -> String:
	if q >= 0.75:
		return "A"
	if q >= 0.6:
		return "B"
	if q >= 0.45:
		return "C"
	return "D"


## O que o piloto diz do carro: fala da área mais longe do ideal.
func feedback() -> String:
	var worst := minf(aero, minf(mech, balance))
	if worst >= 0.85:
		return "O carro está ótimo. Não mexam em nada."
	if worst == aero:
		return "Falta asa nas curvas rápidas, a traseira fica solta."
	if worst == mech:
		return "O carro sai de frente nas curvas lentas e pula nas zebras."
	return "O equilíbrio muda muito de uma curva para outra."


func copy() -> CarSetup:
	var s := CarSetup.new()
	s.aero = aero
	s.mech = mech
	s.balance = balance
	s.race_prep = race_prep
	s.quali_prep = quali_prep
	return s
