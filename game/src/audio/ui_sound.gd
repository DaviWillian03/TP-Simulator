class_name UiSound
extends Node
## Sons de menu (mockup v32): estalo ao tocar nos botões (mais agudo nos de confirmar: CutButton) e uma música leve de
## fundo nos menus. A música para nas telas de corrida e classificação (lá vale o som dos carros). Volumes vêm de Settings
## (barramentos SFX e Music). Sons originais gerados por tools/make_sounds.py.

const TAP := preload("res://assets/audio/ui_tap.wav")
const CONFIRM := preload("res://assets/audio/ui_confirm.wav")
const BACK := preload("res://assets/audio/ui_back.wav")
const MUSIC := preload("res://assets/audio/menu_music.wav")
const QUIET_SCENES := ["race_screen", "quali_screen", "pit_screen"]

var _sfx: AudioStreamPlayer
var _music: AudioStreamPlayer
var _target_db := -80.0


func install(tree: SceneTree) -> void:
	_sfx = AudioStreamPlayer.new()
	_sfx.bus = "SFX"
	add_child(_sfx)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	var s: AudioStreamWAV = MUSIC.duplicate()
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = int(s.get_length() * s.mix_rate)
	_music.stream = s
	_music.volume_db = -80.0
	add_child(_music)
	tree.node_added.connect(_on_node_added)
	var t := Timer.new()
	t.wait_time = 0.4
	t.timeout.connect(_check_scene.bind(tree))
	add_child(t)
	t.start()


func _on_node_added(n: Node) -> void:
	if n is Button and not n.has_meta("_ui_sound"):
		n.set_meta("_ui_sound", true)
		var b := n as Button
		b.pressed.connect(_tap.bind(b))


func _tap(b: Button) -> void:
	if not Settings.touch_sounds or not is_instance_valid(_sfx):
		return
	if b is CutButton:
		_sfx.stream = CONFIRM
	elif b.tooltip_text.to_lower().begins_with("voltar"):
		_sfx.stream = BACK
	else:
		_sfx.stream = TAP
	_sfx.play()


func _check_scene(tree: SceneTree) -> void:
	var cur := tree.current_scene
	var quiet := cur != null and QUIET_SCENES.any(func(q: String) -> bool: return cur.scene_file_path.contains(q))
	_target_db = -80.0 if quiet or Settings.music <= 0.001 else 0.0
	if _target_db > -80.0 and not _music.playing:
		_music.play()


func _process(delta: float) -> void:
	if _music == null:
		return
	_music.volume_db = move_toward(_music.volume_db, _target_db, 60.0 * delta)
	if _music.playing and _music.volume_db <= -79.0 and _target_db <= -79.0:
		_music.stop()
