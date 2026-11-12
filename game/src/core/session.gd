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
##   --campaign / --creator / --hub   entrada da campanha, criação da equipe, sede (campanha salva)
##   --car (peças) / --rd (árvore) / --factory / --staff / --sponsors / --finance     árvore de P&D, fábrica e pessoal da campanha salva (+ --fresh --demo --team=<id>)
##   --gp                   abre a configuração do Grande Prêmio
##   --weekend [--skip=<n>] abre o fim de semana (com --circuit/--team), simulando n sessões
##   --play                 abre a sessão atual do fim de semana (depois do --skip)

const TITLE_SCENE := "res://src/ui/title_screen.tscn"
const RACE_SCENE := "res://src/ui/race_screen.tscn"
const GP_SETUP_SCENE := "res://src/ui/gp_setup_screen.tscn"
const WEEKEND_SCENE := "res://src/ui/weekend_screen.tscn"
const QUALI_SCENE := "res://src/ui/quali_screen.tscn"
const CAMPAIGN_HISTORY_SCENE := "res://src/ui/campaign_history_screen.tscn"  ## Histórico (v24)
const CAMPAIGN_FEEDER_HUB_SCENE := "res://src/ui/campaign_feeder_hub_screen.tscn"  ## sede na F2/F3 (v23-3)
const STRATEGY_SCENE := "res://src/ui/strategy_screen.tscn"  ## estratégia antes da largada (v22-2)
const GRID_SCENE := "res://src/ui/grid_screen.tscn"  ## grid de largada fila a fila (v22-4)
const TEAM_SELECT_SCENE := "res://src/ui/team_select_screen.tscn"
const CAMPAIGN_ENTRY_SCENE := "res://src/ui/campaign_entry_screen.tscn"
const TEAM_CREATOR_SCENE := "res://src/ui/team_creator_screen.tscn"
const CAMPAIGN_HUB_SCENE := "res://src/ui/campaign_hub_screen.tscn"
const CAMPAIGN_STANDINGS_SCENE := "res://src/ui/campaign_standings_screen.tscn"
const CAMPAIGN_CALENDAR_SCENE := "res://src/ui/campaign_calendar_screen.tscn"
const CAMPAIGN_TEAM_SCENE := "res://src/ui/campaign_team_screen.tscn"
const CAMPAIGN_HQ_SCENE := "res://src/ui/campaign_hq_screen.tscn"
const CAMPAIGN_SPONSORS_SCENE := "res://src/ui/campaign_sponsors_screen.tscn"
const CAMPAIGN_COUNCIL_SCENE := "res://src/ui/campaign_council_screen.tscn"
const CAMPAIGN_FINANCE_SCENE := "res://src/ui/campaign_finance_screen.tscn"
const CAMPAIGN_STAFF_SCENE := "res://src/ui/campaign_staff_screen.tscn"
const CAMPAIGN_CAR_SCENE := "res://src/ui/campaign_parts_screen.tscn"  ## Carro: peças (carro interativo)
const CAMPAIGN_STUDIO_SCENE := "res://src/ui/campaign_studio_screen.tscn"  ## estúdio de design
const CAMPAIGN_RD_SCENE := "res://src/ui/campaign_car_screen.tscn"  ## árvore de P&D
const CAMPAIGN_FACTORY_SCENE := "res://src/ui/campaign_factory_screen.tscn"
const CAMPAIGN_REPORT_SCENE := "res://src/ui/campaign_report_screen.tscn"
const WORLD_HUB_SCENE := "res://src/ui/world_hub_screen.tscn"  ## painel do Campeonato Mundial F1 (v29)
const WORLD_FINAL_SCENE := "res://src/ui/world_final_screen.tscn"
const SETTINGS_SCENE := "res://src/ui/settings_screen.tscn"
const SLOTS_SCENE := "res://src/ui/slots_screen.tscn"
const WORLD_TABLE_SCENE := "res://src/ui/world_table_screen.tscn"  ## campeonato do Mundial em tela cheia + estatísticas (v34)
const WORLD_RESULT_SCENE := "res://src/ui/world_result_screen.tscn"  ## resultado de cada GP + estatísticas (v30)

var circuit_id := "interlagos"
var player_team := "mclaren"
var duration_pct := 0.25
var race_seed := 0
var debug_advance_s := 0.0
var debug_pause := false  ## --pause: começa pausado (capturas do grid parado)
var debug_sc := false  ## --sc: aciona o safety car logo após o --advance
var debug_open_data := false  ## --data: abre o menu DADOS (--data=3 abre na aba Clima)
var debug_data_tab := 0
var slow_on_decisions := true  ## desacelera a sessão quando surge uma decisão importante (opção do jogador)
var debug_skip_podium := false  ## --no-podium: vai direto à tabela de resultados (capturas)
var debug_profile := ""  ## --profile=<id do piloto>: abre a ficha na tela Pessoal
var debug_pit := false  ## --pit: abre a tela do box na corrida
var debug_tap := false  ## --tap: leva um carro ao box e abre o mini-jogo de toque
var category := "F1"  ## categoria escolhida (F1/F2/F3) para o Grande Prêmio (e a campanha); decisões de 2026-11-08
var team_select_mode := "gp"  ## escolha de equipe: "campaign" | "gp" | "world"
var debug_ui := ""  ## --ui=team (abre a folha na tela inicial) · --ui=gallery (estados dos componentes)
var debug_view_only := false  ## --view-only: só o cenário 3D em tela cheia (base para mockups)
var debug_camera: Dictionary = {}  ## --yaw --pitch --dist --cam=<n> (capturas da vista 3D)
var sim_overrides: Dictionary = {}  ## opções extras da RaceSim (testes: clima, incidentes)
var weekend: WeekendSim = null:  ## Grande Prêmio em andamento (null = corrida rápida)
	set(v):
		weekend = v
		if v != null and not v.session_done.is_connected(_on_session_done):
			v.session_done.connect(_on_session_done)
var campaign: Campaign = null  ## campanha em andamento (carregada do arquivo salvo)
var world: WorldChampionship = null  ## Campeonato Mundial F1 em andamento (save separado, v29)
var campaign_open_news := false  ## o sino da barra do topo pede as notícias ao abrir o Início
var gp_weather := "realistic"  ## escolhas da configuração do GP
var gp_format := "full"

var _screenshot_path := ""
var _screenshot_frames := 0


func _ready() -> void:
	Settings.load_all()
	Settings.apply_audio()
	slow_on_decisions = Settings.slow_on_decisions
	SaveSlots.migrate_legacy()
	AllCaps.install(get_tree())
	if DisplayServer.get_name() != "headless":  # (testes e relatórios não tocam som)
		var ui_sound := UiSound.new()
		add_child(ui_sound)
		ui_sound.install(get_tree())
	SafeArea.install(get_tree())
	RenderingServer.set_default_clear_color(Color(0.043, 0.051, 0.071))  # faixas da área segura: mesmo tom escuro da interface
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	dev_flags = not args.is_empty()
	player_team = args.get("team", player_team)
	category = String(args.get("category", GameData.category_of(player_team)))  # --category=F2 (com --team=f2_...)
	if args.has("season"):  # (capturas) --season=2012: Grande Prêmio/corrida com as regras da temporada extra
		gp_season = String(args["season"])
		sim_overrides["category"] = Season.category(gp_season)
	duration_pct = float(args.get("pct", duration_pct))
	debug_advance_s = float(args.get("advance", "0"))
	debug_pause = args.has("pause")
	if args.has("rain-at"):
		var t := float(args["rain-at"])
		sim_overrides["weather"] = [{"start_s": t, "end_s": t + 5000.0, "intensity": float(args.get("rain", "0.8"))}]
	elif args.has("weather"):
		sim_overrides["weather"] = args["weather"]
	for k: String in ["yaw", "pitch", "dist", "look"]:
		if args.has(k):
			debug_camera[k] = float(args[k])
	if args.has("cam"):
		debug_camera["mode"] = int(args["cam"])
	if args.has("circuit"):
		circuit_id = args["circuit"]
	debug_sc = args.has("sc")
	debug_open_data = args.has("data")
	debug_data_tab = int(str(args.get("data", "0")))
	debug_skip_podium = args.has("no-podium")
	debug_pit = args.has("pit")
	debug_profile = args.get("profile", "")
	debug_tap = args.has("tap")
	debug_view_only = args.has("view-only")
	debug_ui = args.get("ui", "")
	if args.has("cutout"):  # --cutout=44 ou --cutout=esq,topo,dir,base: simula o furo da câmera no PC
		var cv := String(args["cutout"]).split_floats(",")
		SafeArea.debug = Vector4(cv[0], 0, 0, 0) if cv.size() == 1 else Vector4(cv[0], cv[1], cv[2], cv[3])
	if debug_ui == "gallery":
		get_tree().change_scene_to_file.call_deferred("res://src/ui/dev/ui_gallery.tscn")
	if args.has("incidents"):
		sim_overrides["incident_rate"] = float(args["incidents"])
	_screenshot_path = args.get("screenshot", "")
	_screenshot_frames = int(args.get("frames", "30"))
	if args.has("race"):
		race_seed = int(args.get("seed", "1"))
		get_tree().change_scene_to_file.call_deferred(RACE_SCENE)
	elif args.has("teamselect"):  # (capturas) --teamselect=campaign|gp
		open_team_select.call_deferred(String(args["teamselect"]) if String(args["teamselect"]) != "" else "gp")
	elif args.has("campaign"):
		get_tree().change_scene_to_file.call_deferred(CAMPAIGN_ENTRY_SCENE)
	elif args.has("creator"):
		get_tree().change_scene_to_file.call_deferred(TEAM_CREATOR_SCENE)
	elif args.has("history"):  # (capturas) Histórico da campanha salva; --demo-history cria campeões de exemplo
		var ch := Campaign.load_saved()
		if ch != null:
			campaign = ch
			player_team = ch.player_team
			if args.has("demo-history"):
				for i in 2:
					while not ch.season_over():
						if ch.is_feeder():
							ch._auto_f1_round()
						else:
							break
					if ch.is_feeder():
						ch.feeder_close_season()
						ch.feeder_start_next_season()
			open_campaign_history.call_deferred()
	elif args.has("standings"):
		var c2 := Campaign.load_saved()
		if c2 != null:
			campaign = c2
			player_team = c2.player_team
			if c2.mode == "created":
				TeamEmblems.register_custom(c2.team())
			open_campaign_standings.call_deferred()
	elif args.has("car") or args.has("rd") or args.has("studio") or args.has("factory") or args.has("staff") or args.has("sponsors") or args.has("finance") or args.has("council") or args.has("calendar") or args.has("teamview") or args.has("hq"):  # (capturas) árvore de P&D / fábrica da campanha salva
		var c4 := Campaign.load_saved()
		if args.has("fresh"):  # (captura) campanha nova da equipe --team, com --demo = P&D e obras de exemplo
			c4 = Campaign.new_real(player_team)
			c4.budget_musd = 176.0
			if args.has("demo"):
				for id in ["aero.0.0", "aero.0.1", "aero.0.2", "aero.0.3", "aero.1.0", "aero.1.1", "chassis.0.0", "durability.0.0"]:
					c4.dev.done["cur"][id] = "full"
				c4.dev.done["cur"]["aero.2.0"] = "partial"
				c4.detail = "advanced"
				c4.dev.start_project(c4, "cur", "aero.0.4")
				c4.dev.start_project(c4, "cur", "chassis.0.1")
				c4.dev.start_upgrade(c4, "media")
				# peças de exemplo: asa dianteira B pronta no estoque, asa traseira em pesquisa, câmbio gasto
				var cp := c4.my_parts()
				cp.research.append({"part": "fwing", "dir": "high", "days_left": 1, "days_total": 16, "cost": 2.2, "fix": -1})
				c4.day += 1
				cp.day_step(c4)
				cp.done_research.clear()
				cp.order_units(c4, "fwing", 1, 1)
				for i in 8:
					c4.day += 1
					cp.day_step(c4)
				cp.start_research(c4, "rwing", "high")
				cp.unit_on("gearbox", 0)["wear"] = 64.0
				for u: Dictionary in cp.units:
					if int(u["car"]) >= 0:
						u["races"] = 6
						if u["part"] != "gearbox":
							u["wear"] = 30.0 + 8.0 * int(u["car"])
				c4.refresh_rating()
		if c4 != null:
			campaign = c4
			player_team = c4.player_team
			if c4.mode == "created":
				TeamEmblems.register_custom(c4.team())
			if args.has("council"):
				if args.has("endseason"):
					c4.round = 22  # (captura) abre a votação do fim de temporada
				open_campaign_council.call_deferred()
			elif args.has("sponsors"):
				open_campaign_sponsors.call_deferred()
			elif args.has("finance"):
				open_campaign_finance.call_deferred()
			elif args.has("staff"):
				open_campaign_staff.call_deferred()
			elif args.has("car"):
				open_campaign_car.call_deferred()
			elif args.has("rd"):
				open_campaign_rd.call_deferred()
			elif args.has("studio"):
				open_campaign_studio.call_deferred()
			elif args.has("calendar"):
				open_campaign_calendar.call_deferred()
			elif args.has("teamview"):
				open_campaign_team.call_deferred()
			elif args.has("hq"):
				open_campaign_hq.call_deferred()
			else:
				open_campaign_factory.call_deferred()
	elif args.has("report"):
		var c3 := Campaign.load_saved()
		if c3 != null:
			campaign = c3
			player_team = c3.player_team
			if c3.mode == "created":
				TeamEmblems.register_custom(c3.team())
			if args.get("report", "") == "fired":
				c3.trust = 0.0  # (captura) a confiança zerada vira demissão
				c3.goal_shift = -20  # (captura) meta impossível: a demissão não é salva pelo resultado
			c3.round = 22
			c3.close_season()
			open_campaign_report.call_deferred()
	elif args.has("camp-race"):  # (capturas) corrida da próxima rodada da campanha salva
		campaign = Campaign.load_saved()
		if campaign != null:
			if campaign.mode == "created":
				TeamEmblems.register_custom(campaign.team())
			player_team = campaign.player_team
			weekend = WeekendSim.new(campaign.next_round()["id"], campaign.weekend_options({"duration_pct": duration_pct, "format": "race_only",
				"weather": args.get("weather", "realistic")}))
			play_session.call_deferred()
	elif args.has("worldrace"):  # (capturas) corrida do próximo GP do Mundial (equipe --team), com as sessões anteriores simuladas
		world = WorldChampionship.start(player_team)
		weekend = WeekendSim.new(world.next_round()["id"], world.weekend_options({"duration_pct": duration_pct}))
		circuit_id = String(world.next_round()["id"])
		while weekend.session_id() != "race":
			weekend.simulate_current()
		var wplans := weekend.engineer_strategy()
		for wd: String in wplans:
			weekend.strategy[wd] = wplans[wd][0]
		start_race_from_grid.call_deferred(weekend.make_race())
	elif args.has("worldresume"):  # (capturas) retoma o fim de semana do Mundial salvo (rodada 1)
		world = WorldChampionship.start(player_team)
		resume_weekend.call_deferred("world")
	elif args.has("settings"):  # (capturas) tela de configurações
		open_settings.call_deferred()
	elif args.has("slots"):  # (capturas) --slots[=world]: escolha de slot
		open_slots.call_deferred(String(args["slots"]) if String(args["slots"]) != "" else "campaign")
	elif args.has("world"):  # (capturas) --world --team=<id> [--rounds=<n>]: painel do Mundial com n GPs já simulados (não salva)
		world = WorldChampionship.start(player_team)
		for i in int(args.get("rounds", "0")):
			var wk := WeekendSim.new(world.next_round()["id"], world.weekend_options({"duration_pct": 0.1, "weather": "dry", "incident_rate": 0.5}))
			var guard := 0
			while not wk.is_over() and guard < 20:
				wk.simulate_current()
				guard += 1
			world.record_weekend(wk)
		if debug_ui in ["wtable", "wteams", "wmates", "wstats", "wrank"]:  # (captura) campeonato em tela cheia: pilotos | equipes | estatísticas | ranking de vitórias
			open_world_table.call_deferred({"wtable": "drivers", "wteams": "teams", "wmates": "mates"}.get(debug_ui, "stats"), "wins" if debug_ui == "wrank" else "")
		elif debug_ui in ["result", "champ", "stats"]:  # (captura) --ui=result|champ|stats abre o resultado do último GP
			world_result_tab = debug_ui
			open_world_result.call_deferred()
		else:
			open_world_hub.call_deferred()
	elif args.has("hub"):
		var c := Campaign.load_saved()
		if args.has("fresh"):  # (captura) campanha nova da equipe --team; --event=<id> aplica um evento de exemplo
			c = Campaign.new_feeder(player_team) if GameData.category_of(player_team) != "F1" else Campaign.new_real(player_team)
		if c != null and args.has("event"):
			var rng := RandomNumberGenerator.new()
			rng.seed = 7
			c.events._add(c, c.events._apply(c, CampaignEvents.event_def(args["event"]), rng, c.day))
		if c != null:
			start_campaign.call_deferred(c)
	elif args.has("gp"):
		get_tree().change_scene_to_file.call_deferred(GP_SETUP_SCENE)
	elif args.has("weekend") or args.has("practice") or args.has("quali") or args.has("play") or args.has("grid") or args.has("live"):
		var opts := {"player_team": player_team, "duration_pct": duration_pct, "seed": int(args.get("seed", "1")),
			"weather": args.get("weather", "realistic"), "category": category}
		opts.merge(sim_overrides.duplicate(), false)
		weekend = WeekendSim.new(circuit_id, opts)
		for i in int(args.get("skip", "0")):
			weekend.simulate_current()
		if args.has("grid"):  # (captura) --grid abre a animação do grid da corrida atual
			get_tree().change_scene_to_file.call_deferred(GRID_SCENE)
		elif args.has("live") and weekend.is_race(weekend.session_id()):  # (captura) --live: corrida direto, plano dos engenheiros
			var plans := weekend.engineer_strategy()
			for did: String in plans:
				weekend.strategy[did] = plans[did][0]
			start_race_from_grid.call_deferred(weekend.make_race())
		elif args.has("practice") or args.has("quali") or args.has("play"):
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
	debug_pit = false
	debug_tap = false
	get_tree().change_scene_to_file(RACE_SCENE)


func restart_race() -> void:
	start_race()


func go_to_title() -> void:
	weekend = null
	get_tree().change_scene_to_file(TITLE_SCENE)


# --- Escolha de equipe (dentro de cada modo) ----------------------------------------------

func open_team_select(mode: String) -> void:
	team_select_mode = mode
	get_tree().change_scene_to_file(TEAM_SELECT_SCENE)


# --- Grande Prêmio ----------------------------------------------------------------------

func open_gp_setup() -> void:
	if weekend != null and weekend.is_over():  # GP avulso terminado: o save do fim de semana não serve mais
		SaveSlots.delete_weekend("gp")
	get_tree().change_scene_to_file(GP_SETUP_SCENE)


## Cria o fim de semana com as escolhas da configuração e abre o painel.
## Tipo do fim de semana em andamento para o save: "gp" (avulso), "campaign" ou "world".
func _weekend_kind() -> String:
	if weekend != null and weekend.world:
		return "world"
	return "campaign" if weekend != null and weekend.campaign else "gp"


## Rodada do campeonato a que o fim de semana pertence (o save é descartado se o campeonato já passou dela).
func _weekend_ctx() -> int:
	match _weekend_kind():
		"world":
			return world.round if world != null else 0
		"campaign":
			return campaign.round if campaign != null else 0
	return 0


## Salvamento automático: depois de cada treino, classificação, sprint (e da corrida, para a tela de resultado).
func _on_session_done() -> void:
	if weekend == null or DisplayServer.get_name() == "headless":  # (testes e relatórios não gravam)
		return
	SaveSlots.save_weekend(weekend, _weekend_kind(), _weekend_ctx())


## Retoma o fim de semana salvo do tipo dado (devolve true e abre o painel); false se não houver.
func resume_weekend(kind: String) -> bool:
	var ctx := 0
	if kind == "world" and world != null:
		ctx = world.round
	elif kind == "campaign" and campaign != null:
		ctx = campaign.round
	var w := SaveSlots.load_weekend(kind, ctx)
	if w == null:
		return false
	weekend = w
	circuit_id = String(w.circuit.get("id", circuit_id))
	player_team = w.player_team
	go_to_weekend()
	return true


func start_gp() -> void:
	SaveSlots.delete_weekend("gp")  # começar outro GP descarta o fim de semana salvo
	var opts := {"player_team": player_team, "duration_pct": duration_pct, "weather": gp_weather,
		"format": gp_format, "seed": randi(), "category": category}
	if gp_season != Season.DEFAULT and category == "F1":  # temporada extra (2012…): grid, pilotos e regras daquele ano
		opts["teams"] = Season.teams(gp_season)
		opts["drivers"] = Season.drivers(gp_season)
		opts["category"] = Season.category(gp_season)
		for rd: Dictionary in Season.calendar(gp_season):
			if String(rd["id"]) == circuit_id and rd.has("compounds"):
				opts["dry_pair"] = rd["compounds"]
	opts.merge(sim_overrides.duplicate(), false)
	weekend = WeekendSim.new(circuit_id, opts)
	go_to_weekend()


# --- Campanha ---------------------------------------------------------------------------

func open_campaign() -> void:
	get_tree().change_scene_to_file(CAMPAIGN_ENTRY_SCENE)


func open_team_creator() -> void:
	get_tree().change_scene_to_file(TEAM_CREATOR_SCENE)


## Começa (ou retoma) uma campanha: registra a arte da equipe criada, salva e abre a sede.
func start_campaign(c: Campaign) -> void:
	campaign = c
	player_team = c.player_team
	if c.mode == "created":
		TeamEmblems.register_custom(c.team())
		CarModel3D._cache.erase(c.player_team)
	c.save()
	if resume_weekend("campaign"):  # parou no meio de um fim de semana: volta de onde parou
		return
	get_tree().change_scene_to_file(CAMPAIGN_FEEDER_HUB_SCENE if c.is_feeder() else CAMPAIGN_HUB_SCENE)


func open_campaign_hub() -> void:
	get_tree().change_scene_to_file(CAMPAIGN_FEEDER_HUB_SCENE if campaign != null and campaign.is_feeder() else CAMPAIGN_HUB_SCENE)


func open_campaign_history() -> void:
	get_tree().change_scene_to_file(CAMPAIGN_HISTORY_SCENE)


func open_campaign_standings() -> void:
	get_tree().change_scene_to_file(CAMPAIGN_STANDINGS_SCENE)


func open_campaign_sponsors() -> void:
	get_tree().change_scene_to_file(CAMPAIGN_SPONSORS_SCENE)


func open_campaign_council() -> void:
	get_tree().change_scene_to_file(CAMPAIGN_COUNCIL_SCENE)


func open_campaign_finance() -> void:
	get_tree().change_scene_to_file(CAMPAIGN_FINANCE_SCENE)


func open_campaign_staff() -> void:
	get_tree().change_scene_to_file(CAMPAIGN_STAFF_SCENE)


func open_campaign_car() -> void:
	get_tree().change_scene_to_file(CAMPAIGN_CAR_SCENE)


func open_campaign_studio() -> void:
	get_tree().change_scene_to_file(CAMPAIGN_STUDIO_SCENE)


func open_campaign_rd() -> void:
	get_tree().change_scene_to_file(CAMPAIGN_RD_SCENE)


## Equipe (carro grande + pilotos, v26-7).
func open_campaign_team() -> void:
	get_tree().change_scene_to_file(CAMPAIGN_TEAM_SCENE)


## Sede 3D com instalações (v26-5).
func open_campaign_hq() -> void:
	get_tree().change_scene_to_file(CAMPAIGN_HQ_SCENE)


## Agenda em cartões (v26-6).
func open_campaign_calendar() -> void:
	get_tree().change_scene_to_file(CAMPAIGN_CALENDAR_SCENE)


func open_campaign_factory() -> void:
	get_tree().change_scene_to_file(CAMPAIGN_FACTORY_SCENE)


## Fim da temporada: a sede leva ao relatório da diretoria.
func open_campaign_report() -> void:
	get_tree().change_scene_to_file(CAMPAIGN_REPORT_SCENE)


## Novo ano (ou fim da campanha, se demitido/falido): grava e volta para a sede ou para a entrada.
func finish_season_report() -> void:
	if campaign.state != "active":
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSlots.campaign_path()))  # campanha encerrada: o arquivo sai
		campaign = null
		open_campaign()
		return
	campaign.start_next_season()
	campaign.save()
	open_campaign_hub()


## Demitido: aceita a proposta de outra equipe e segue a carreira na temporada seguinte.
func accept_job_offer(team_id: String) -> void:
	campaign.switch_team(team_id)
	player_team = team_id
	campaign.start_next_season()
	campaign.save()
	open_campaign_hub()


## Fim de semana da próxima rodada da campanha.
func play_campaign_round() -> void:
	var r := campaign.next_round()
	if r.is_empty():
		return
	circuit_id = r["id"]
	if campaign.is_feeder():  # campanha na F2/F3: o fim de semana é da categoria de base
		weekend = WeekendSim.new(r["id"], campaign.feeder_weekend_options({"duration_pct": duration_pct}))
	else:
		weekend = WeekendSim.new(r["id"], campaign.weekend_options({"duration_pct": duration_pct}))
	go_to_weekend()


# --- Campeonato Mundial F1 (v29) ---------------------------------------------------------------

## Do menu: continua o campeonato salvo ou, sem save, vai escolher a equipe.
func open_world() -> void:
	var saved := WorldChampionship.load_saved()
	if saved == null:
		open_team_select("world")
		return
	world = saved
	player_team = saved.player_team
	if resume_weekend("world"):
		return
	open_world_hub()


func start_world(team_id: String) -> void:
	world = WorldChampionship.start(team_id)
	player_team = team_id
	world.save()
	open_world_hub()


func open_world_hub() -> void:
	get_tree().change_scene_to_file(WORLD_FINAL_SCENE if world != null and world.season_over() else WORLD_HUB_SCENE)


var dev_flags := false  ## alguma opção de desenvolvimento/captura foi passada (pula a abertura)
var slots_mode := "campaign"  ## o que um slot vazio começa: "campaign" | "world"
var gp_season := Season.DEFAULT  ## temporada do Grande Prêmio avulso (2026 ou extra, ex.: 2012); a Campanha não usa
var world_table_mode := "drivers"  ## aba aberta na tela do campeonato: drivers | teams | stats
var world_table_stat := ""  ## estatística aberta (wins | poles | podiums | dnfs) ou vazio
var world_result_tab := "result"  ## aba aberta ao entrar no resultado do Mundial: result | champ | stats


func open_settings() -> void:
	get_tree().change_scene_to_file(SETTINGS_SCENE)


## Escolha de slot. mode vazio = só gerenciar (um slot vazio começa o último modo pedido).
func open_slots(mode: String) -> void:
	if mode != "":
		slots_mode = mode
	get_tree().change_scene_to_file(SLOTS_SCENE)


func open_world_table(mode: String = "drivers", stat_key: String = "") -> void:
	world_table_mode = mode
	world_table_stat = stat_key
	get_tree().change_scene_to_file(WORLD_TABLE_SCENE)


func open_world_result(tab: String = "") -> void:
	if tab != "":
		world_result_tab = tab
	get_tree().change_scene_to_file(WORLD_RESULT_SCENE)


func open_world_final() -> void:
	get_tree().change_scene_to_file(WORLD_FINAL_SCENE)


## Joga o próximo GP do campeonato com as notas reais da pista.
func play_world_round() -> void:
	var r := world.next_round()
	if r.is_empty():
		return
	circuit_id = r["id"]
	weekend = WeekendSim.new(r["id"], world.weekend_options({"duration_pct": duration_pct}))
	go_to_weekend()


## Recomeça a temporada do Mundial (apaga o save e escolhe a equipe de novo).
func reset_world() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSlots.world_path()))
	world = null
	open_team_select("world")


## Fim do fim de semana da campanha: soma os pontos, avança a rodada, salva e volta para a sede.
func finish_campaign_weekend() -> void:
	if world != null and weekend != null and weekend.world:
		var fresh := weekend.is_over()
		if fresh:
			world.record_weekend(weekend)
			world.save()
			SaveSlots.delete_weekend("world")  # fim de semana concluído: o save intermediário sai
		weekend = null
		world_result_tab = "result" if fresh else "champ"
		open_world_result()  # resultado do GP (pódio, campeonato e estatísticas); de lá segue para o painel
		return
	if campaign != null and weekend != null and weekend.campaign and weekend.is_over():
		campaign.record_weekend(weekend)
		campaign.save()
		SaveSlots.delete_weekend("campaign")
	weekend = null
	if campaign.is_feeder():  # a sede da F2/F3 mostra o fim de temporada
		open_campaign_hub()
	elif campaign.season_over() or campaign.state != "active":
		open_campaign_report()
	else:
		open_campaign_hub()


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
	if weekend.is_practice(id):  # treino é sempre simulado (decisão de 2026-11-08): resultado no painel do fim de semana
		weekend.simulate_current()
		weekend.show_practice_report = true
		get_tree().change_scene_to_file(WEEKEND_SCENE)
	elif weekend.is_quali(id):
		get_tree().change_scene_to_file(QUALI_SCENE)
	elif weekend.is_race(id):
		# passo antes da largada: estratégia dos dois pilotos (todos os modos; decisão de 2026-11-08)
		get_tree().change_scene_to_file(STRATEGY_SCENE if weekend.strategy.is_empty() and _has_player_cars() else GRID_SCENE)


func _has_player_cars() -> bool:
	for d: Dictionary in weekend.drivers:
		if d["team"] == weekend.player_team:
			return true
	return false


## Estratégia confirmada: segue para o grid de largada e a corrida.
func start_race_after_strategy() -> void:
	get_tree().change_scene_to_file(GRID_SCENE)


var pending_race: RaceSim = null  ## corrida já montada pelo grid de largada (a tela da corrida usa a mesma)


## Fim da animação do grid (ou PULAR): a corrida começa com a simulação já montada.
func start_race_from_grid(sim: RaceSim) -> void:
	pending_race = sim
	get_tree().change_scene_to_file(RACE_SCENE)
