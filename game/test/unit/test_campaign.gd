extends GutTest
## Campanha (1ª camada): equipe real ou criada, 12ª equipe com 24 carros, salvar e carregar.

const SPEC := {"origin": "manufacturer", "name": "Aurora Racing", "short": "aur", "color": "#0E7C66", "color2": "#F2A900",
	"shape": "hex", "country": "Brasil", "engine": "Ferrari", "objective": {"id": "win"}, "detail": "essential",
	"ai_difficulty": "normal", "drivers": ["rafael_camara", "colton_herta"]}


func test_base_de_pilotos_da_f2_e_f3_e_valida() -> void:
	var pool := Campaign.feeder_drivers()
	assert_gt(pool.size(), 40)
	var ids := {}
	for d: Dictionary in pool:
		assert_has(["F2", "F3"], d["category"])
		ids[d["id"]] = true
	assert_eq(ids.size(), pool.size(), "ids únicos")


func test_equipe_real_mantem_o_grid_de_22_carros() -> void:
	var c := Campaign.new_real("williams")
	assert_eq(c.teams().size(), 11)
	assert_eq(c.drivers().size(), 22)
	assert_eq(c.team()["name"], "Williams")


func test_equipe_criada_entra_como_12a_com_24_carros() -> void:
	var c := Campaign.new_created(SPEC)
	assert_true(c.is_valid())
	assert_eq(c.teams().size(), 12)
	assert_eq(c.drivers().size(), 24)
	var t := c.team()
	assert_eq(t["name"], "Aurora Racing")
	assert_eq(t["short_name"], "AUR")
	assert_eq(c.engine, "own", "montadora estreante sempre tem motor próprio")
	var numbers := {}
	for d: Dictionary in c.drivers():
		numbers[int(d["number"])] = true
	assert_eq(numbers.size(), 24, "números de carro sem repetição")
	var mine := c.drivers().filter(func(d: Dictionary) -> bool: return d["team"] == Campaign.CUSTOM_ID)
	assert_eq(mine.map(func(d: Dictionary) -> String: return d["code"]), ["CAM", "HER"])


func test_origem_define_as_condicoes_iniciais() -> void:
	var garage := SPEC.duplicate()
	garage["origin"] = "garage"
	var rescue := SPEC.duplicate()
	rescue["origin"] = "rescue"
	var g := Campaign.new_created(garage)
	var r := Campaign.new_created(rescue)
	assert_eq(g.engine, "Ferrari", "garagem compra motor")
	assert_lt(g.budget_musd, Campaign.new_created(SPEC).budget_musd)
	assert_gt(r.debt_musd, 0.0, "resgate começa com dívidas")


func test_criacao_invalida_sem_dois_pilotos_diferentes() -> void:
	var bad := SPEC.duplicate()
	bad["drivers"] = ["rafael_camara", "rafael_camara"]
	assert_false(Campaign.new_created(bad).is_valid())


func test_salvar_e_carregar_mantem_a_campanha() -> void:
	var path := "user://test_campaign.json"
	var c := Campaign.new_created(SPEC)
	assert_true(c.save(path))
	var l := Campaign.load_saved(path)
	assert_not_null(l)
	assert_eq(l.team()["name"], "Aurora Racing")
	assert_eq(l.drivers().size(), 24)
	assert_eq(l.objective_text(), "Vencer uma corrida")
	DirAccess.remove_absolute(path)


func test_classificacao_com_24_carros_corta_7_e_7() -> void:
	var c := Campaign.new_created(SPEC)
	var q := QualiSim.new(TrackModel.new(GameData.circuit("interlagos")), TyreModel.new(GameData.tyres()), c.teams(), c.drivers(), {},
		{"weather": "dry", "incident_rate": 0.0, "seed": 3, "auto_player": true})
	var out := [0, 0, 0]
	q.segment_finished.connect(func(s: int, e: Array) -> void: out[s] = e.size())
	q.run_to_end()
	assert_eq(out, [7, 7, 0])
	assert_eq(q.grid_ids().size(), 24)


func test_fim_de_semana_da_campanha_corre_com_a_equipe_criada() -> void:
	var c := Campaign.new_created(SPEC)
	var w := WeekendSim.new("interlagos", {"player_team": Campaign.CUSTOM_ID, "teams": c.teams(), "drivers": c.drivers(),
		"duration_pct": 0.25, "weather": "dry", "incident_rate": 0.0, "seed": 2, "format": "race_only"})
	w.simulate_current()
	assert_eq(w.results["race"].size(), 24)
	assert_has(w.results["race"], "rafael_camara")


func test_arte_da_equipe_criada_e_gerada() -> void:
	var c := Campaign.new_created(SPEC)
	assert_not_null(CarArt.car_texture(c.team()))
	assert_not_null(CarArt.emblem_texture("shield", "#0E7C66", "#F2A900", "AUR"))


# --- temporada --------------------------------------------------------------------------

func _played(c: Campaign, rounds: int, w_opts: Dictionary = {}) -> void:
	for i in rounds:
		c.advance_to_event()
		var o := c.weekend_options({"duration_pct": 0.25, "weather": "dry", "incident_rate": 0.0, "format": "race_only"})
		o.merge(w_opts, true)
		var w := WeekendSim.new(c.next_round()["id"], o)
		w.simulate_current()
		c.record_weekend(w)


func test_dias_avancam_ate_o_evento_e_nao_passam() -> void:
	var c := Campaign.new_real("williams")
	var days := c.days_to_event()
	assert_gt(days, 0)
	assert_eq(c.advance_days(1), 1)
	assert_eq(c.advance_days(999), days - 1, "não passa do começo do fim de semana")
	assert_true(c.event_ready())
	assert_eq(c.advance_days(5), 0)
	assert_string_contains(c.date_text(), "SEX")


func test_fim_de_semana_leva_o_dia_para_depois_da_corrida() -> void:
	var c := Campaign.new_real("williams")
	_played(c, 1)
	assert_eq(c.round, 1)
	assert_string_contains(c.date_text(), "SEG", "o dia seguinte à corrida de domingo")
	assert_gt(c.days_to_event(), 0)


func test_vitorias_e_pontos_dos_campeonatos() -> void:
	var c := Campaign.new_real("mclaren")
	_played(c, 3)
	var total := 0
	for r: Array in c.driver_standings():
		total += r[1]
	assert_gt(total, 3 * 40, "pontos distribuídos nas 3 corridas")
	var w := 0
	for id: String in c.wins:
		w += c.wins[id]
	assert_eq(w, 3)


func test_meta_da_diretoria_vem_da_origem_e_do_carro() -> void:
	var garage := Campaign.new_created(SPEC.merged({"origin": "garage"}, true))
	assert_eq(garage.season_goal(), 10)
	assert_lt(Campaign.new_real("mclaren").season_goal(), Campaign.new_real("cadillac").season_goal())


func test_caixa_acompanha_patrocinio_e_custos() -> void:
	var c := Campaign.new_created(SPEC)
	c.detail = "advanced"  # no essencial o diretor técnico também gasta com projetos de P&D
	var before := c.budget_musd
	_played(c, 1)
	assert_almost_eq(c.budget_musd, before + c.sponsor_per_race() - c.cost_per_race(), 0.001)


func test_falencia_com_caixa_negativo() -> void:
	var c := Campaign.new_created(SPEC.merged({"origin": "garage"}, true))
	c.budget_musd = -1.0
	_played(c, 1)
	assert_eq(c.state, "bankrupt")


func test_demissao_quando_a_confianca_acaba() -> void:
	var c := Campaign.new_created(SPEC.merged({"origin": "investor", "ai_difficulty": "hard"}, true))
	c.trust = 0.3
	_played(c, 1)
	assert_eq(c.state, "fired")


func test_fim_de_temporada_cumprida_sobe_a_meta_e_vira_o_ano() -> void:
	var c := Campaign.new_real("mclaren")
	c.round = 22
	c.team_points = {"mclaren": 400, "mercedes": 300}
	c.driver_points = {"norris": 200}
	var goal := c.season_goal()
	var report := c.close_season()
	assert_eq(report["verdict"], "met")
	assert_eq(report["position"], 1)
	assert_lt(report["next_goal"], goal + 1)
	c.start_next_season()
	assert_eq(c.season, 2027)
	assert_eq(c.round, 0)
	assert_true(c.driver_points.is_empty())
	assert_eq(c.seasons.size(), 1)


func test_fim_de_temporada_falhada_tira_confianca_conforme_a_paciencia() -> void:
	var impaciente := Campaign.new_created(SPEC.merged({"origin": "investor"}, true))
	var paciente := Campaign.new_created(SPEC.merged({"origin": "garage"}, true))
	for c: Campaign in [impaciente, paciente]:
		c.round = 22
		c.team_points = {}  # 12º, longe da meta
	var t_imp := impaciente.trust
	var t_pac := paciente.trust
	impaciente.close_season()
	paciente.close_season()
	assert_gt(t_imp - impaciente.trust, t_pac - paciente.trust, "diretoria impaciente pune mais")


func test_salvar_mantem_dia_confianca_e_historico() -> void:
	var path := "user://test_campaign_season.json"
	var c := Campaign.new_real("williams")
	_played(c, 2)
	assert_true(c.save(path))
	var l := Campaign.load_saved(path)
	assert_eq(l.round, 2)
	assert_eq(l.day, c.day)
	assert_almost_eq(l.trust, c.trust, 0.001)
	assert_eq(l.history.size(), 2)
	DirAccess.remove_absolute(path)
