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
##   --gp                   abre a configuração do Grande Prêmio
##   --weekend [--skip=<n>] abre o fim de semana (com --circuit/--team), simulando n sessões
##   --play                 abre a sessão atual do fim de semana (depois do --skip)

const TITLE_SCENE := "res://src/ui/title_screen.tscn"
const RACE_SCENE := "res://src/ui/race_screen.tscn"
const GP_SETUP_SCENE := "res://src/ui/gp_setup_screen.tscn"
const WEEKEND_SCENE := "res://src/ui/weekend_screen.tscn"
const PRACTICE_SCENE := "res://src/ui/practice_screen.tscn"
const QUALI_SCENE := "res://src/ui/quali_screen.tscn"

var circuit_id := "interlagos"
var player_team := "mclaren"
var duration_pct := 0.25
var race_seed := 0
var debug_advance_s := 0.0
var debug_pause := false  ## --pause: começa pausado (capturas do grid parado)
var debug_sc := false  ## --sc: aciona o safety car logo após o --advance
var debug_open_data := false  ## --data: abre o menu DADOS
var debug_view_only := false  ## --view-only: só o cenário 3D em tela cheia (base para mockups)
var debug_camera: Dictionary = {}  ## --yaw --pitch --dist --cam=<n> (capturas da vista 3D)
var sim_overrides: Dictionary = {}  ## opções extras da RaceSim (testes: clima, incidentes)
var weekend: WeekendSim = null  ## Grande Prêmio em andamento (null = corrida rápida)
var gp_weather := "realistic"  ## escolhas da configuração do GP
var gp_format := "full"

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
	debug_view_only = args.has("view-only")
	if args.has("incidents"):
		sim_overrides["incident_rate"] = float(args["incidents"])
	_screenshot_path = args.get("screenshot", "")
	_screenshot_frames = int(args.get("frames", "30"))
	if args.has("race"):
		race_seed = int(args.get("seed", "1"))
		get_tree().change_scene_to_file.call_deferred(RACE_SCENE)
	elif args.has("gp"):
		get_tree().change_scene_to_file.call_deferred(GP_SETUP_SCENE)
	elif args.has("weekend") or args.has("practice") or args.has("quali") or args.has("play"):
		var opts := {"player_team": player_team, "duration_pct": duration_pct, "seed": int(args.get("seed", "1")),
			"weather": args.get("weather", "realistic")}
		opts.merge(sim_overrides.duplicate(), false)
		weekend = WeekendSim.new(circuit_id, opts)
		for i in int(args.get("skip", "0")):
			weekend.simulate_current()
		if args.has("practice") or args.has("quali") or args.has("play"):
			play_session.call_deferred()
		else:
			get_tree().change_scene_to_file.call_deferred(WEEKEND_SCENE)


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
	weekend = null
	get_tree().change_scene_to_file(TITLE_SCENE)


# --- Grande Prêmio ----------------------------------------------------------------------

func open_gp_setup() -> void:
	get_tree().change_scene_to_file(GP_SETUP_SCENE)


## Cria o fim de semana com as escolhas da configuração e abre o painel.
func start_gp() -> void:
	var opts := {"player_team": player_team, "duration_pct": duration_pct, "weather": gp_weather,
		"format": gp_format, "seed": randi()}
	opts.merge(sim_overrides.duplicate(), false)
	weekend = WeekendSim.new(circuit_id, opts)
	go_to_weekend()


func go_to_weekend() -> void:
	if weekend == null:
		go_to_title()
		return
	if weekend.race_only and weekend.session_id() == "race":
		play_session()  # "só a corrida": direto para a largada
		return
	get_tree().change_scene_to_file(WEEKEND_SCENE)


## Abre a tela da sessão atual do fim de semana (treino, classificação ou corrida).
func play_session() -> void:
	var id := weekend.session_id()
	if weekend.is_practice(id):
		get_tree().change_scene_to_file(PRACTICE_SCENE)
	elif weekend.is_quali(id):
		get_tree().change_scene_to_file(QUALI_SCENE)
	elif weekend.is_race(id):
		get_tree().change_scene_to_file(RACE_SCENE)
