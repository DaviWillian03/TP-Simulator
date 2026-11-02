class_name RadioSystem
extends RefCounted
## Rádio dos pilotos do jogador: mensagens, sugestões e perguntas em momentos-chave.
##
## Uma pergunta tem opções; a resposta executa uma ação (ex.: chamar para o box) e afeta a
## confiança do piloto: resposta certa para a situação = um pouco mais rápido por algumas
## voltas; errada = um pouco mais lento. Sem resposta até o prazo, o piloto decide sozinho.

const ANSWER_WINDOW_LAPS := 2
const CONFIDENCE_LAPS := 5
const CONFIDENCE_S := 0.08  ## s/volta por ponto de confiança

var _sim_ref: WeakRef  # referência fraca: evita ciclo RaceSim <-> módulo (vazaria memória)
var sim: RaceSim:
	get:
		return _sim_ref.get_ref()
var enabled := true
var messages: Array[Dictionary] = []
var _next_id := 1
var _cooldown_until: Dictionary = {}  # car.index -> volta em que pode perguntar de novo
var _cooldown_laps := 8


func _init(p_sim: RaceSim) -> void:
	_sim_ref = weakref(p_sim)
	# corridas curtas comprimem os acontecimentos: perguntas um pouco mais próximas
	_cooldown_laps = 8 if sim.duration_pct >= 0.5 else 4


## Pergunta ainda sem resposta deste carro (ou vazio).
func pending_for(car: CarState) -> Dictionary:
	for m in messages:
		if m["car"] == car and m["kind"] == "question" and not m["answered"]:
			return m
	return {}


func info(car: CarState, text: String) -> void:
	var m := {"id": _next_id, "car": car, "kind": "info", "text": text, "options": [], "answered": true, "auto": false}
	_next_id += 1
	messages.append(m)
	sim.radio_message.emit(m)


func ask(car: CarState, text: String, options: Array, best: int) -> void:
	if not pending_for(car).is_empty():
		return
	var m := {"id": _next_id, "car": car, "kind": "question", "text": text, "options": options,
		"best": best, "answered": false, "auto": false, "expires_lap": car.laps_done + ANSWER_WINDOW_LAPS, "choice": -1}
	_next_id += 1
	messages.append(m)
	_cooldown_until[car.index] = car.laps_done + _cooldown_laps
	sim.radio_message.emit(m)


## Resposta do jogador (índice da opção).
func answer(message_id: int, option: int) -> void:
	for m in messages:
		if m["id"] == message_id and not m["answered"]:
			_resolve(m, option, false)
			return


# --- gatilhos (chamados a cada volta completada por um carro do jogador) ----------------

func on_lap(car: CarState) -> void:
	if not enabled:
		return
	_expire(car)
	if car.finished or car.retired or not pending_for(car).is_empty():
		return
	if car.laps_done < int(_cooldown_until.get(car.index, 0)):
		return
	var remaining := sim.total_laps - car.laps_done
	if remaining <= 1 or car.in_pit or car.pit_requested:
		return
	var w := sim.weather.wetness
	var trend := sim.weather.rain_now()
	var best_class := sim.tyres.tyre_class(sim.tyres.best_for_wetness(w + (0.08 if trend > 0.08 else -0.05)))
	var cls := sim.tyres.tyre_class(car.tyre)
	var who := car.display_name().get_slice(" ", 0)
	if cls == "slick" and best_class != "slick":
		ask(car, "Está começando a chover e a pista ficou escorregadia. Paro para intermediários?",
			[_opt("Box: intermediários", "pit", "inter"), _opt("Fica na pista", "stay")], 0)
	elif cls == "inter" and best_class == "wet":
		ask(car, "Está alagando! Não dá para segurar com intermediário. Pneu de chuva?",
			[_opt("Box: chuva", "pit", "wet"), _opt("Fica com intermediário", "stay")], 0)
	elif cls != "slick" and best_class == "slick":
		var slick := StrategyAI.choose_compound(sim, car, remaining)
		ask(car, "A pista está secando, já aparece o traçado seco. Volto para slicks?",
			[_opt("Box: %s" % sim.tyres.compounds[slick]["name"].to_lower(), "pit", slick), _opt("Mais um pouco", "stay")], 0)
	elif cls == "slick" and car.tyre_wear >= 0.72:
		var next := StrategyAI.choose_compound(sim, car, remaining)
		var pit_is_right := remaining > 3 or not sim.compound_rule_ok(car)
		ask(car, "Os pneus acabaram, estou perdendo muito tempo. Box nesta volta?",
			[_opt("Box: %s" % sim.tyres.compounds[next]["name"].to_lower(), "pit", next), _opt("Mais 2 voltas", "stay")],
			0 if pit_is_right else 1)
	elif _teammate_slower_ahead(car):
		var mate := sim.teammate_of(car)
		ask(car, "Estou mais rápido que o %s. Pede para ele abrir?" % mate.display_name().get_slice(" ", 0),
			[_opt("Sim, troca as posições", "swap"), _opt("Não, segura aí", "stay")], 0)
	elif car.gap_ahead_s < 0.0 and _attacked_from_behind(car):
		ask(car, "Tem um carro colado atrás de mim. Defendo forte?",
			[_opt("Defende forte", "defend"), _opt("Não arrisca", "safe")], -1)
	elif car.battery < 0.12 and car.energy_mode == CarState.EnergyMode.DEPLOY:
		info(car, "%s: \"Bateria quase vazia, vou recarregar um pouco.\"" % who)
		car.energy_mode = CarState.EnergyMode.HARVEST


## Safety car/VSC acionado: momento-chave, pergunta mesmo fora do intervalo normal.
func on_neutralization(car: CarState) -> void:
	if not enabled or car.in_pit or car.pit_requested or not pending_for(car).is_empty():
		return
	var remaining := sim.total_laps - car.laps_done
	if remaining <= 2:
		return
	var best := sim.tyres.best_for_wetness(sim.weather.wetness)
	var next := best if not sim.tyres.is_dry(best) else StrategyAI.choose_compound(sim, car, remaining)
	var worth := car.tyre_wear > 0.3 or sim.tyres.tyre_class(best) != sim.tyres.tyre_class(car.tyre) \
		or not sim.compound_rule_ok(car) or car.damage_wing > 0.15
	var kind := "Safety car" if sim.control.flag == RaceControl.Flag.SC else "Safety car virtual"
	var m_count := messages.size()
	_cooldown_until.erase(car.index)
	ask(car, "%s na pista! Parar agora custa bem menos. Aproveito?" % kind,
		[_opt("Box: %s" % sim.tyres.compounds[next]["name"].to_lower(), "pit", next), _opt("Fica na pista", "stay")],
		0 if worth else 1)
	if messages.size() > m_count:
		messages[messages.size() - 1]["expires_lap"] = car.laps_done + 1


func _opt(label: String, action: String, arg: String = "") -> Dictionary:
	return {"label": label, "action": action, "arg": arg}


func _teammate_slower_ahead(car: CarState) -> bool:
	var mate := sim.teammate_of(car)
	if mate == null or mate.retired or mate.finished or mate.lane() != 0:
		return false
	var gap := (mate.distance - car.distance) / maxf(car.speed, 1.0)
	return gap > 0.0 and gap < 1.2 and sim.ideal_pace(car) < sim.ideal_pace(mate) - 0.3


func _attacked_from_behind(car: CarState) -> bool:
	for other in sim.cars:
		if other != car and other.lane() == 0 and not other.finished and not other.retired:
			var gap := (car.distance - other.distance) / maxf(other.speed, 1.0)
			if gap > 0.0 and gap < 0.6:
				return true
	return false


# --- respostas ---------------------------------------------------------------------

func _expire(car: CarState) -> void:
	for m in messages:
		if m["car"] == car and m["kind"] == "question" and not m["answered"] and car.laps_done >= int(m["expires_lap"]):
			# o piloto decide sozinho: acerta a melhor opção na maioria das vezes
			var pick: int = m["best"] if int(m["best"]) >= 0 and sim.rng.randf() < 0.7 else (m["options"].size() - 1)
			_resolve(m, pick, true)


func _resolve(m: Dictionary, option: int, auto: bool) -> void:
	var car: CarState = m["car"]
	m["answered"] = true
	m["auto"] = auto
	m["choice"] = option
	var opt: Dictionary = m["options"][option]
	match opt["action"]:
		"pit":
			sim.request_pit(car, opt["arg"])
		"swap":
			var mate := sim.teammate_of(car)
			if mate != null:
				sim.set_team_order(mate, CarState.TeamOrder.LET_BY)
		"defend":
			car.defend_hard = true
		"safe":
			car.defend_hard = false
	var best := int(m["best"])
	if best >= 0 and not auto:
		car.confidence = 1 if option == best else -1
		car.confidence_until_lap = car.laps_done + CONFIDENCE_LAPS
	var who := car.display_name().get_slice(" ", 0)
	var reply := ""
	if auto:
		reply = "%s decidiu sozinho: %s." % [who, opt["label"].to_lower()]
	elif best >= 0:
		reply = "%s: \"Entendido, boa!\"" % who if option == best else "%s: \"Tem certeza? ...Ok.\"" % who
	if reply != "":
		info(car, reply)
	sim.radio_answered.emit(m)


## Efeito da confiança no tempo de volta (negativo = mais rápido).
func confidence_delta_s(car: CarState) -> float:
	if car.confidence == 0 or car.laps_done >= car.confidence_until_lap:
		return 0.0
	return -CONFIDENCE_S * car.confidence
