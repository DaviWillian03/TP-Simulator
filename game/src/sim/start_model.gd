class_name StartModel
extends RefCounted
## Largada parada (pedido de 2026-11-10): cada piloto tem um fator de largada sorteado por corrida.
## A maioria sai "no padrão" (diferença pequena); uma minoria faz uma largada muito boa (ganha várias posições)
## ou muito ruim (perde várias, "do nada"). A habilidade do piloto (`data/start_skill.json`, PROVISÓRIO) só muda as
## chances: quem larga bem na vida real tem mais largadas boas e menos ruins; quem larga mal, o contrário.
##
## O fator `gain` multiplica a velocidade nos primeiros segundos (perfil `bump`): +0.20 ≈ +4 posições e
## −0.30 ≈ −6 posições (medido nas simulações). Todos os carros também "arrancam" do zero (`ramp`), igual para todos.

const PHASE_S := 10.0  ## depois disso a largada acabou (volta a valer só o ritmo e as ultrapassagens normais)
const RAMP_S := 5.0  ## aceleração do zero até o ritmo de volta
const RAMP_FROM := 0.2  ## fração do ritmo no instante em que as luzes apagam
const NEUTRAL := 50.0
const GOOD_RANGE := Vector2(0.12, 0.28)
const BAD_RANGE := Vector2(0.15, 0.40)
const NORMAL_SD := 0.022
const NORMAL_CAP := 0.06

static var _skill: Dictionary = {}


static func skill_of(driver_id: String) -> float:
	if _skill.is_empty():
		_skill = (GameData.load_json(GameData.DATA_DIR + "start_skill.json") as Dictionary).get("skill", {})
	return float(_skill.get(driver_id, NEUTRAL))


## Chance de largada muito boa / muito ruim (0..1) para a habilidade dada; chuva piora (mais erro).
static func chances(skill: float, wetness: float = 0.0) -> Vector2:
	var s := clampf((skill - NEUTRAL) / 30.0, -1.0, 1.0)
	var good := clampf(0.06 + 0.07 * s, 0.01, 0.30)
	var bad := clampf(0.06 - 0.04 * s, 0.01, 0.30) * (1.0 + 0.6 * clampf(wetness, 0.0, 1.0))
	return Vector2(good, bad)


## Fator de largada do piloto nesta corrida: [gain, tipo] — tipo "great", "bad" ou "" (normal).
static func roll(driver_id: String, seed_value: int, wetness: float = 0.0) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("start|%s|%d" % [driver_id, seed_value])
	var skill := skill_of(driver_id)
	var p := chances(skill, wetness)
	var r := rng.randf()
	if r < p.x:
		return [rng.randf_range(GOOD_RANGE.x, GOOD_RANGE.y), "great"]
	if r < p.x + p.y:
		return [-rng.randf_range(BAD_RANGE.x, BAD_RANGE.y), "bad"]
	var s := clampf((skill - NEUTRAL) / 30.0, -1.0, 1.0)
	return [clampf(rng.randfn(0.012 * s, NORMAL_SD), -NORMAL_CAP, NORMAL_CAP), ""]


## Arrancada comum a todos: sobe do RAMP_FROM até 1 em RAMP_S segundos.
static func ramp(t: float) -> float:
	return RAMP_FROM + (1.0 - RAMP_FROM) * smoothstep(0.0, RAMP_S, t)


## Perfil do fator pessoal: sobe nos 3 primeiros segundos, segura até 8 s e some até PHASE_S.
static func bump(t: float) -> float:
	return smoothstep(0.0, 3.0, t) * (1.0 - smoothstep(8.0, PHASE_S, t))


## Multiplicador de velocidade na largada para um carro com o fator `gain`, `t` segundos depois das luzes.
static func speed_mult(gain: float, t: float) -> float:
	if t >= PHASE_S:
		return 1.0
	return ramp(t) * (1.0 + gain * bump(t))


static func active(t: float) -> bool:
	return t < PHASE_S
