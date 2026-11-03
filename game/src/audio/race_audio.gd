class_name RaceAudio
extends Node
## Som da corrida: ronco de fundo, carros passando (alternados, em intervalos aleatórios),
## torcida, semáforo da largada e efeitos dos eventos (ultrapassagem, box, rádio, bandeira).
##
## Fica só na apresentação: escuta os sinais do RaceSim e nunca muda a simulação. Os sons são
## gerados por `tools/make_sounds.py` (originais). Guarda o RaceSim por WeakRef (ciclo de
## referência vazaria memória, como nos outros módulos).

const DIR := "res://assets/audio/"
const BED_DB := -9.0
const CROWD_DB := -17.0
const PASSBY_DB := -4.0

static var muted := false  ## vale para a sessão inteira (botão de som da corrida)

var _sim_ref: WeakRef
var _bed: AudioStreamPlayer
var _crowd: AudioStreamPlayer
var _passby: Array[AudioStreamPlayer] = []
var _passby_streams: Array[AudioStream] = []
var _fx: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _next_passby := 1.5
var _last_passby := -1
var _paused := false
var time_scale := 1.0  ## velocidade da corrida (a tela informa); acelera a frequência das passagens
var rng := RandomNumberGenerator.new()


func setup(sim: RaceSim) -> void:
	_sim_ref = weakref(sim)
	rng.seed = 2026
	_bed = _player(_loop("engine_bed"), BED_DB)
	_crowd = _player(_loop("crowd_loop"), CROWD_DB)
	for i in 3:
		_passby_streams.append(load(DIR + "passby_%d.wav" % (i + 1)))
		_passby.append(_player(null, PASSBY_DB))
	for i in 4:
		_fx.append(_player(null, 0.0))
	for n: String in ["cheer", "light", "go", "pit_gun", "radio", "alert"]:
		_streams[n] = load(DIR + n + ".wav")
	sim.overtake.connect(_on_overtake)
	sim.pit_stop.connect(_on_pit_stop)
	sim.radio_message.connect(func(_m: Dictionary) -> void: play("radio", -6.0))
	sim.flag_changed.connect(func(_f: int, _t: String) -> void: play("alert", -14.0))
	sim.race_finished.connect(func() -> void: play("cheer", 0.0))
	_apply_mute()
	if not muted:
		_bed.play()
		_crowd.play(rng.randf() * 5.0)
	if sim.time_s < 1.0:
		_start_lights()


func _sim() -> RaceSim:
	return _sim_ref.get_ref() as RaceSim if _sim_ref != null else null


## Liga/desliga todo o som da corrida.
func set_muted(m: bool) -> void:
	muted = m
	_apply_mute()


func set_paused(p: bool) -> void:
	_paused = p
	for pl: AudioStreamPlayer in [_bed, _crowd] + _passby:
		pl.stream_paused = p


func _apply_mute() -> void:
	for pl: AudioStreamPlayer in [_bed, _crowd] + _passby + _fx:
		if muted:
			pl.stop()
	if not muted and _bed != null and not _bed.playing:
		_bed.play()
		_crowd.play()


func _process(delta: float) -> void:
	var sim := _sim()
	if sim == null or muted or _paused:
		return
	# safety car / VSC: carros devagar, ronco mais grave e baixo; bandeira vermelha: silêncio
	var flag := sim.control.flag
	var slow := flag == RaceControl.Flag.SC or flag == RaceControl.Flag.VSC
	var stopped := flag == RaceControl.Flag.RED or sim.is_over()
	var target_db := -60.0 if stopped else (BED_DB - 7.0 if slow else BED_DB)
	_bed.volume_db = move_toward(_bed.volume_db, target_db, delta * 20.0)
	_bed.pitch_scale = move_toward(_bed.pitch_scale, 0.82 if slow else 1.0, delta * 0.5)
	if stopped:
		return
	_next_passby -= delta * clampf(sqrt(time_scale), 1.0, 2.2)
	if _next_passby <= 0.0:
		_next_passby = rng.randf_range(1.4, 3.6) * (2.2 if slow else 1.0)
		_play_passby(slow)


## Um carro passando perto: alterna as três gravações sem repetir a anterior.
func _play_passby(slow: bool) -> void:
	var i := rng.randi_range(0, _passby_streams.size() - 1)
	if i == _last_passby:
		i = (i + 1) % _passby_streams.size()
	_last_passby = i
	for pl in _passby:
		if not pl.playing:
			pl.stream = _passby_streams[i]
			pl.pitch_scale = rng.randf_range(0.93, 1.07) * (0.8 if slow else 1.0)
			pl.volume_db = PASSBY_DB + rng.randf_range(-6.0, 0.0) - (6.0 if slow else 0.0)
			pl.play()
			return


## Toca um efeito curto (rádio, alerta, torcida...).
func play(sound: String, db: float = 0.0, pitch: float = 1.0) -> void:
	if muted or not _streams.has(sound):
		return
	for pl in _fx:
		if not pl.playing:
			pl.stream = _streams[sound]
			pl.volume_db = db
			pl.pitch_scale = pitch
			pl.play()
			return


func _on_overtake(attacker: CarState, defender: CarState, _zone: String) -> void:
	# a torcida vibra mais quando é com os seus carros
	if attacker.is_player or defender.is_player:
		play("cheer", -4.0)
	elif rng.randf() < 0.35:
		play("cheer", -14.0, rng.randf_range(0.95, 1.05))


func _on_pit_stop(car: CarState, _compound: String, _stationary: float) -> void:
	if car.is_player:
		play("pit_gun", -2.0)
		get_tree().create_timer(0.45).timeout.connect(func() -> void: play("pit_gun", -4.0, 1.08))


## Semáforo: cinco luzes e a largada (só som; a simulação não espera).
func _start_lights() -> void:
	for i in 5:
		get_tree().create_timer(0.15 + i * 0.35).timeout.connect(func() -> void: play("light", -6.0))
	get_tree().create_timer(0.15 + 5 * 0.35 + 0.2).timeout.connect(func() -> void:
		play("go", -4.0)
		play("cheer", -6.0))


func _loop(sound: String) -> AudioStreamWAV:
	var s: AudioStreamWAV = (load(DIR + sound + ".wav") as AudioStreamWAV).duplicate()
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = int(s.get_length() * s.mix_rate)
	return s


func _player(stream: AudioStream, db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = db
	add_child(p)
	return p
