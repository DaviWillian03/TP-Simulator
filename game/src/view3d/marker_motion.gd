class_name MarkerMotion
extends RefCounted
## Animações dos marcadores na pista 3D (só apresentação; a simulação não muda):
## - ULTRAPASSAGEM: a simulação troca os carros de lugar de uma vez; aqui o de trás desliza por dentro do
##   outro (desvio lateral em arco) e os dois "correm" até a nova posição em ~1,2 s, como no Motorsport Manager.
## - RODADA / ESCAPADA: o carro sai da pista, fica parado fora (enquanto perde tempo na simulação) e volta.
## - BATIDA / QUEBRA: o carro desliza para fora da pista e fica parado ali, apagado, por alguns segundos.

const PASS_TIME := 1.2  ## segundos (reais) da animação da ultrapassagem
const PASS_SIDE_M := 6.0  ## quanto o carro que ataca vai para o lado
const WRECK_TIME := 14.0  ## quanto tempo (real) o carro batido/quebrado fica visível parado fora da pista

var _dist_off: Dictionary = {}  ## CarState -> metros de atraso/adiantamento a recuperar (some aos poucos)
var _pass: Dictionary = {}  ## CarState -> [tempo decorrido, lado (+1/-1), duração]
var _stall_max: Dictionary = {}  ## CarState -> maior perda de tempo registrada nesta rodada/escapada
var _stall_out: Dictionary = {}  ## CarState -> quanto sai da pista (m) nesta rodada
var _wreck: Dictionary = {}  ## CarState -> [distância onde parou, tempo decorrido, quanto sai (m)]
var _rng := RandomNumberGenerator.new()


## Chamado no sinal de ultrapassagem (os carros já trocaram de lugar na simulação).
func on_overtake(att: CarState, def: CarState) -> void:
	var gap := att.distance - def.distance  # depois da troca: quanto o atacante "pulou" à frente
	if gap <= 0.0 or gap > 300.0:
		return
	_dist_off[att] = float(_dist_off.get(att, 0.0)) - gap * 0.85  # aparece onde estava e avança
	_dist_off[def] = float(_dist_off.get(def, 0.0)) + gap * 0.6  # o passado "cai" para trás aos poucos
	_pass[att] = [0.0, 1.0 if _rng.randf() < 0.5 else -1.0, PASS_TIME]


## Chamado nos incidentes da corrida.
func on_incident(car: CarState, kind: String, track_width: float, distance: float) -> void:
	match kind:
		"spin", "damage":
			_stall_out[car] = track_width * _rng.randf_range(1.3, 1.8) * (1.0 if _rng.randf() < 0.5 else -1.0)
			_stall_max[car] = car.stall_s  # o sinal chega com a perda de tempo já definida
		"lockup":
			_stall_out[car] = track_width * 0.9 * (1.0 if _rng.randf() < 0.5 else -1.0)
			_stall_max[car] = car.stall_s
		"crash", "failure":
			var side := 1.0 if _rng.randf() < 0.5 else -1.0
			_wreck[car] = [distance, 0.0, track_width * (1.9 if kind == "crash" else 1.2) * side]


func is_wreck_visible(car: CarState) -> bool:
	return _wreck.has(car) and float(_wreck[car][1]) < WRECK_TIME


func wreck_distance(car: CarState) -> float:
	return float(_wreck[car][0])


## Opacidade do carro batido (apaga no fim).
func wreck_alpha(car: CarState) -> float:
	var t: float = _wreck[car][1]
	return clampf((WRECK_TIME - t) / 2.0, 0.0, 1.0) * 0.6


func step(delta: float) -> void:
	for car: CarState in _dist_off.keys():
		var v: float = _dist_off[car] * pow(0.08, delta / PASS_TIME)  # recupera ~92% em PASS_TIME
		if absf(v) < 0.3:
			_dist_off.erase(car)
		else:
			_dist_off[car] = v
	for car: CarState in _pass.keys():
		_pass[car][0] = float(_pass[car][0]) + delta
		if float(_pass[car][0]) >= float(_pass[car][2]):
			_pass.erase(car)
	for car: CarState in _wreck.keys():
		_wreck[car][1] = float(_wreck[car][1]) + delta


## Ajuste na distância ao longo da pista (m).
func distance_offset(car: CarState) -> float:
	return float(_dist_off.get(car, 0.0))


## Deslocamento lateral (m, + = direita da pista) neste quadro.
func lateral(car: CarState) -> float:
	var out := 0.0
	if _pass.has(car):
		var p: Array = _pass[car]
		out += float(p[1]) * PASS_SIDE_M * sin(PI * float(p[0]) / float(p[2]))
	if car.stall_s > 0.0 and _stall_out.has(car):
		var m := maxf(float(_stall_max.get(car, 0.0)), car.stall_s)
		_stall_max[car] = m
		var prog := 1.0 - car.stall_s / maxf(m, 0.01)  # 0 = acabou de rodar, 1 = voltando
		var k := 1.0
		if prog < 0.2:
			k = ease(prog / 0.2, 0.4)  # escorrega para fora
		elif prog > 0.75:
			k = 1.0 - ease((prog - 0.75) / 0.25, 1.6)  # volta para a pista
		out += float(_stall_out[car]) * k
	elif car.stall_s <= 0.0 and _stall_max.has(car):
		_stall_max.erase(car)
		_stall_out.erase(car)
	return out


## Deslocamento lateral do carro batido (escorrega para fora no primeiro meio segundo).
func wreck_lateral(car: CarState) -> float:
	var w: Array = _wreck[car]
	return float(w[2]) * ease(clampf(float(w[1]) / 0.6, 0.0, 1.0), 0.4)


## O carro está fora da pista agora (rodada/escapada): o marcador mostra um aviso.
func is_off_track(car: CarState) -> bool:
	return car.stall_s > 0.0 and _stall_out.has(car)
