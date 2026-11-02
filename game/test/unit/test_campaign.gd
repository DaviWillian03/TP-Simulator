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
