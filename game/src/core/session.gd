extends Node
## Autoload "Session": guarda as escolhas feitas no menu para a próxima corrida.
##
## Também aceita opções de desenvolvimento pela linha de comando (depois de "--"):
##   --race                 abre direto a tela de corrida
##   --team=<id>            equipe do jogador (ex.: williams)
##   --pct=<0.25|0.5|1.0>   duração da corrida
##   --seed=<n>             semente da corrida
##   --advance=<segundos>   avança a corrida antes de mostrar (para capturas de tela)
##   --pause                começa pausado
##   --rain-at=<segundos> [--rain=<0..1>]   força chuva a partir desse instante
##   --weather=dry          sem chuva · --incidents=<0..n> multiplicador de incidentes
##   --screenshot=<arquivo.png> --frames=<n>   salva a tela após n quadros e fecha o jogo

const TITLE_SCENE := "res://src/ui/title_screen.tscn"
const RACE_SCENE := "res://src/ui/race_screen.tscn"

var circuit_id := "interlagos"
var player_team := "mclaren"
var duration_pct := 0.25
var race_seed := 0
var debug_advance_s := 0.0
var debug_pause := false  ## --pause: começa pausado (capturas do grid parado)
var debug_sc := false  ## --sc: aciona o safety car logo após o --advance
var debug_open_data := false  ## --data: abre o menu DADOS
var debug_camera: Dictionary = {}  ## --yaw --pitch --dist --cam=<n> (capturas da vista 3D)
var sim_overrides: Dictionary = {}  ## opções extras da RaceSim (testes: clima, incidentes)

var _screenshot_path := ""
var _screenshot_frames := 0


func _ready() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	player_team = args.get("team", player_team)
	duration_pct = float(args.get("pct", duration_pct))
	debug_advance_s = float(args.get("advance", "0"))
	debug_pause = args.has("pause")
	if args.has("rain-at"):
		var t := float(args["rain-at"])
		sim_overrides["weather"] = [{"start_s": t, "end_s": t + 5000.0, "intensity": float(args.get("rain", "0.8"))}]
	elif args.has("weather"):
		sim_overrides["weather"] = args["weather"]
	for k: String in ["yaw", "pitch", "dist"]:
		if args.has(k):
			debug_camera[k] = float(args[k])
	if args.has("cam"):
		debug_camera["mode"] = int(args["cam"])
	if args.has("circuit"):
		circuit_id = args["circuit"]
	debug_sc = args.has("sc")
	debug_open_data = args.has("data")
	if args.has("incidents"):
		sim_overrides["incident_rate"] = float(args["incidents"])
	_screenshot_path = args.get("screenshot", "")
	_screenshot_frames = int(args.get("frames", "30"))
	if args.has("race"):
		race_seed = int(args.get("seed", "1"))
		get_tree().change_scene_to_file.call_deferred(RACE_SCENE)


func _process(_delta: float) -> void:
	if _screenshot_path.is_empty():
		return
	_screenshot_frames -= 1
	if _screenshot_frames == 0:
		get_viewport().get_texture().get_image().save_png(_screenshot_path)
		get_tree().quit()


func start_race() -> void:
	race_seed = randi()
	debug_advance_s = 0.0
	debug_pause = false
	get_tree().change_scene_to_file(RACE_SCENE)


func restart_race() -> void:
	start_race()


func go_to_title() -> void:
	get_tree().change_scene_to_file(TITLE_SCENE)
