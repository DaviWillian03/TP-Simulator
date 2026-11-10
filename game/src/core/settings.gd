class_name Settings
extends RefCounted
## Configurações do jogador (mockup v32-1): volume, tamanho da letra, velocidade inicial da corrida, pausa em
## decisões e dicas de primeira vez. Salvas em user://settings.json (valem para todos os slots).

const PATH := "user://settings.json"
const TEXT_SIZES := {"small": 1.0, "normal": 1.2, "large": 1.4}  ## "normal" = escala que o jogo já usava

static var master := 0.8
static var sfx := 0.9
static var music := 0.4
static var touch_sounds := true
static var text_size := "normal"
static var start_speed := 2
static var slow_on_decisions := true
static var tips_on := true
static var tips_seen: Array = []
static var loaded := false


static func text_scale() -> float:
	return float(TEXT_SIZES.get(text_size, 1.2))


static func load_all() -> void:
	loaded = true
	if not FileAccess.file_exists(PATH):
		return
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not d is Dictionary:
		return
	master = clampf(float(d.get("master", master)), 0.0, 1.0)
	sfx = clampf(float(d.get("sfx", sfx)), 0.0, 1.0)
	music = clampf(float(d.get("music", music)), 0.0, 1.0)
	touch_sounds = bool(d.get("touch_sounds", touch_sounds))
	text_size = String(d.get("text_size", text_size)) if TEXT_SIZES.has(String(d.get("text_size", ""))) else "normal"
	start_speed = int(d.get("start_speed", start_speed)) if int(d.get("start_speed", 2)) in [1, 2, 4] else 2
	slow_on_decisions = bool(d.get("slow_on_decisions", slow_on_decisions))
	tips_on = bool(d.get("tips_on", tips_on))
	tips_seen = d.get("tips_seen", [])


static func save_all() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"master": master, "sfx": sfx, "music": music, "touch_sounds": touch_sounds, "text_size": text_size,
		"start_speed": start_speed, "slow_on_decisions": slow_on_decisions, "tips_on": tips_on, "tips_seen": tips_seen}, " "))


## Aplica o volume nos barramentos de áudio (Master / SFX / Music; cria os dois últimos se faltarem).
static func apply_audio() -> void:
	for bus_name: String in ["SFX", "Music"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus_name)
			AudioServer.set_bus_send(i, "Master")
	_set_bus("Master", master)
	_set_bus("SFX", sfx)
	_set_bus("Music", music)


static func _set_bus(bus_name: String, linear: float) -> void:
	var i := AudioServer.get_bus_index(bus_name)
	if i >= 0:
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(linear, 0.0001)))
		AudioServer.set_bus_mute(i, linear <= 0.001)


static func tip_seen(key: String) -> bool:
	return tips_seen.has(key)


static func mark_tip(key: String) -> void:
	if not tips_seen.has(key):
		tips_seen.append(key)
		save_all()


static func reset_tips() -> void:
	tips_seen = []
	tips_on = true
	save_all()
