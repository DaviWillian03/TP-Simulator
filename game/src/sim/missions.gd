class_name Missions
extends RefCounted
## Missões do stint (decisões de 2026-11-09, mockups v25): o jogador dá o OBJETIVO e o piloto dosa ritmo, bateria e pneus
## volta a volta (os modos Poupar/Normal/Atacar e Carregar/Equil./Usar continuam existindo por baixo, mas quem escolhe é
## o piloto). Uma missão DE BASE vale o stint inteiro; uma missão CURTA tem fim automático e, quando acaba, volta a base.
## A dosagem depende das notas: regularidade (errar a mão), gestão de pneus (aliviar na hora certa) e ultrapassagem.
## A IA usa as mesmas missões. Sem tela.

const KINDS := ["save", "attack", "defend", "push", "safe", "normal"]
## Nomes da tela (2026-11-12: missões viraram "Ritmo"): Trazendo pra casa, Conservador, Ritmo normal, Agressivo, Potência máxima.
const NAMES := {"save": "Conservador", "attack": "Agressivo", "defend": "Defender", "push": "Potência máxima",
	"safe": "Trazendo pra casa", "normal": "Ritmo normal"}
const RITMO := ["safe", "save", "normal", "attack", "push"]  ## ordem na tela, do mais calmo ao mais forte
const RITMO_ICONS := {"safe": "home", "save": "leaf", "normal": "gauge", "attack": "chev2", "push": "bolt"}
## Abordagem na direção: soma à nota de ultrapassagem e defesa e muda a chance de toque ao atacar.
const APPROACH_POINTS := 10.0
const APPROACH_NAMES := {-1: "Sem riscos", 0: "Normal", 1: "Agressivo"}
const APPROACH_ICONS := {-1: "shield", 0: "target", 1: "fire"}
const APPROACH_CONTACT := {-1: 0.6, 0: 1.0, 1: 1.5}
const WEAR_LIMIT := 0.78  ## "o pneu chega": desgaste abaixo disso na volta-alvo (antes do penhasco)
const ATTACK_TYRE_LIMIT := 0.72  ## atacando, um bom piloto alivia acima disso se não estiver a menos de 1 s
const MISTAKE_K := 0.004  ## chance (por avaliação) de errar a mão, por ponto de regularidade abaixo de 100


static func base_mission(kind: String, until_lap: int = 0) -> Dictionary:
	return {"kind": kind, "until": until_lap}


## Missão curta: termina sozinha em `end_lap` (volta completada) e volta a base.
static func short_mission(kind: String, start_lap: int, laps: int, target := "") -> Dictionary:
	return {"kind": kind, "start": start_lap, "end": start_lap + maxi(laps, 1), "target": target}


## Missão em vigor agora (a curta, se ativa; senão a base). Limpa a curta vencida.
static func active(car: CarState) -> Dictionary:
	if not car.mission_short.is_empty():
		if car.laps_done >= int(car.mission_short["end"]):
			car.mission_short = {}
		elif car.laps_done >= int(car.mission_short.get("start", 0)):
			return car.mission_short
	return car.mission_base if not car.mission_base.is_empty() else base_mission("normal")


## Desgaste por volta no ritmo dado (com o multiplicador da corrida).
static func wear_per_lap(sim: RaceSim, car: CarState, mode: CarState.PaceMode) -> float:
	return sim.tyres.wear_per_lap(car.tyre) * sim.wear_multiplier() * float(RaceSim.PACE_WEAR[mode]) * car.wear_factor


## Volta prevista em que o pneu passa do limite, no ritmo dado.
static func projected_limit_lap(sim: RaceSim, car: CarState, mode: CarState.PaceMode) -> int:
	var per := maxf(wear_per_lap(sim, car, mode), 0.0001)
	return car.laps_done + int(floor(maxf(WEAR_LIMIT - car.tyre_wear, 0.0) / per))


## O piloto decide ritmo e bateria conforme a missão e a situação (chamado periodicamente para todos os carros).
static func drive(sim: RaceSim, car: CarState) -> void:
	if car.finished or car.retired or car.in_pit:
		return
	var m := active(car)
	var gap_ahead := sim.gap_to_car_ahead_s(car)
	var close_ahead := gap_ahead >= 0.0 and gap_ahead < 1.0
	var behind := attacker_gap(sim, car)
	var close_behind := behind >= 0.0 and behind < 1.0
	var tyres := DriverStats.attr(car.driver, "tyres")
	var pace := CarState.PaceMode.NORMAL
	var energy := CarState.EnergyMode.BALANCED
	car.defend_hard = false
	match String(m.get("kind", "normal")):
		"save":
			var until := int(m.get("until", sim.total_laps))
			# poupa o necessário para o pneu chegar à volta-alvo; defende por um momento se alguém encostar
			if projected_limit_lap(sim, car, CarState.PaceMode.NORMAL) < until:
				pace = CarState.PaceMode.CONSERVE
			energy = CarState.EnergyMode.HARVEST if car.battery < 0.45 else CarState.EnergyMode.BALANCED
			if close_behind and behind < 0.6 and car.battery > 0.4:
				energy = CarState.EnergyMode.DEPLOY
		"attack":
			pace = CarState.PaceMode.ATTACK
			energy = CarState.EnergyMode.DEPLOY if close_ahead and car.battery > 0.25 else CarState.EnergyMode.BALANCED
			# preso atrás com o pneu indo embora: o bom piloto alivia umas voltas e volta a atacar
			if not close_ahead and car.tyre_wear > ATTACK_TYRE_LIMIT and sim.rng.randf() < tyres / 100.0:
				pace = CarState.PaceMode.NORMAL
		"defend":
			car.defend_hard = close_behind
			pace = CarState.PaceMode.ATTACK if close_behind else CarState.PaceMode.NORMAL
			# guarda bateria para as zonas de ultrapassagem e usa quando o rival encosta
			energy = CarState.EnergyMode.DEPLOY if close_behind and car.battery > 0.3 else (CarState.EnergyMode.HARVEST if car.battery < 0.6 else CarState.EnergyMode.BALANCED)
		"push":
			pace = CarState.PaceMode.ATTACK
			energy = CarState.EnergyMode.DEPLOY if car.battery > 0.2 else CarState.EnergyMode.BALANCED
		"safe":
			pace = CarState.PaceMode.CONSERVE
			energy = CarState.EnergyMode.HARVEST if car.battery < 0.5 else CarState.EnergyMode.BALANCED
		_:
			pace = CarState.PaceMode.ATTACK if close_ahead and car.tyre_wear < 0.6 else CarState.PaceMode.NORMAL
			if car.battery < 0.25:
				energy = CarState.EnergyMode.HARVEST
			elif close_ahead and car.battery > 0.4:
				energy = CarState.EnergyMode.DEPLOY
	# piloto irregular erra a mão de vez em quando (um degrau acima ou abaixo)
	var miss := (100.0 - DriverStats.attr(car.driver, "consistency")) * MISTAKE_K
	if sim.rng.randf() < miss:
		pace = clampi(pace + (1 if sim.rng.randf() < 0.5 else -1), 0, 2) as CarState.PaceMode
	if sim.energy_k <= 0.0:  # F2/F3: sem híbrido
		energy = CarState.EnergyMode.BALANCED
	car.pace_mode = pace
	car.energy_mode = energy


## Segundos do carro de trás mais próximo na mesma faixa (-1 = ninguém perto).
static func attacker_gap(sim: RaceSim, car: CarState) -> float:
	var best := -1.0
	for o in sim.cars:
		if o == car or o.finished or o.retired or o.in_pit:
			continue
		var d := car.distance - o.distance
		if d > 0.0:
			var s := d / maxf(o.speed, 1.0)
			if s < 3.0 and (best < 0.0 or s < best):
				best = s
	return best


# --- IA ----------------------------------------------------------------------------------------------

## A IA escolhe as próprias missões: poupar até a parada planejada; atacar curto quando encosta com pneu bom;
## ritmo seguro com dano ou pneu no fim e poucas voltas.
static func ai_choose(sim: RaceSim, car: CarState) -> void:
	var next_stop := sim.total_laps
	for l: int in car.ai_plan:
		if l > car.laps_done:
			next_stop = l
			break
	car.mission_base = base_mission("save", next_stop) if next_stop < sim.total_laps else base_mission("normal")
	if car.damage_wing > 0.3:
		car.mission_base = base_mission("safe")
	var gap_ahead := sim.gap_to_car_ahead_s(car)
	if car.mission_short.is_empty() and gap_ahead >= 0.0 and gap_ahead < 0.9 and car.tyre_wear < 0.55:
		car.mission_short = short_mission("attack", car.laps_done, 3)


# --- textos da tela -----------------------------------------------------------------------------------

## Título da missão ("Poupar pneus até a volta 30", "Atacar · 3 voltas").
static func title(m: Dictionary) -> String:
	var k := String(m.get("kind", "normal"))
	if k == "save":
		return "Conservador · até a volta %d" % int(m.get("until", 0))
	if m.has("end"):
		var tgt := String(m.get("target", ""))
		return "%s%s · %d voltas" % [NAMES[k], (" " + tgt) if tgt != "" else "", int(m["end"]) - int(m["start"])]
	return String(NAMES.get(k, k))


## Situação da missão para o cartão: {text, progress (0..1), ok}.
static func status(sim: RaceSim, car: CarState, m: Dictionary) -> Dictionary:
	var k := String(m.get("kind", "normal"))
	if m.has("end"):  # curta: andamento
		var total := maxi(int(m["end"]) - int(m["start"]), 1)
		var done := clampi(car.laps_done - int(m["start"]), 0, total)
		var gap := sim.gap_to_car_ahead_s(car)
		var txt := ""
		match k:
			"attack":
				txt = ("a %s s · bateria nas retas" % _s(gap)) if gap >= 0.0 else "sem ninguém à frente"
			"defend":
				var b := attacker_gap(sim, car)
				txt = ("carro a %s s atrás" % _s(b)) if b >= 0.0 else "ninguém encostando"
			"push":
				txt = "voltas fortes no ar limpo"
			_:
				txt = ""
		return {"text": "%s · %d de %d" % [txt, done, total], "progress": float(done) / total, "ok": true}
	match k:
		"save":
			var until := int(m.get("until", sim.total_laps))
			var lap := projected_limit_lap(sim, car, car.pace_mode)
			var ok := lap >= until
			return {"text": ("cumprindo · pneu chega à volta %d" % mini(lap, 999)) if ok else ("não chega · pneu acaba na volta %d" % lap),
				"progress": clampf(float(lap - car.laps_done) / maxf(float(until - car.laps_done), 1.0), 0.0, 1.0), "ok": ok}
		"safe":
			return {"text": "sem riscos · trazendo o carro", "progress": 1.0, "ok": true}
		"attack":
			return {"text": "atacando o carro da frente", "progress": 1.0 - car.tyre_wear, "ok": car.tyre_wear < 0.75}
		"defend":
			return {"text": "defendendo a posição", "progress": 1.0 - car.tyre_wear, "ok": true}
		"push":
			return {"text": "ritmo forte", "progress": 1.0 - car.tyre_wear, "ok": car.tyre_wear < 0.75}
	return {"text": "o piloto decide o ritmo", "progress": 1.0 - car.tyre_wear, "ok": true}


static func _s(v: float) -> String:
	return String.num(v, 1).replace(".", ",")
