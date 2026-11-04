extends GutTest
## Campeonato ao vivo ("se terminar assim") durante a corrida da campanha.

var live: ChampionshipLive


func before_each() -> void:
	live = ChampionshipLive.new()
	var team_of := {"a": "t1", "b": "t2", "c": "t1", "d": "t3"}
	live.setup({"a": 100, "b": 90, "c": 80, "d": 10}, {"t1": 180, "t2": 90, "t3": 10}, team_of, RaceSim.RACE_POINTS, 2, 0)


func test_projecao_soma_os_pontos_da_posicao_atual() -> void:
	var p := live.project(["b", "a", "c", "d"])
	assert_eq(p["drivers"][0], ["a", 100, 118], "a: 100 + 18 (2º)")
	assert_eq(p["drivers"][1], ["b", 90, 115], "b: 90 + 25 (1º)")
	assert_eq(p["teams"][0], ["t1", 180, 213], "t1 soma os dois carros (18 + 15)")


func test_fora_da_corrida_nao_pontua() -> void:
	var p := live.project(["b", "a", "c", "d"], {"b": true})
	var row: Array = (p["drivers"] as Array).filter(func(r: Array) -> bool: return r[0] == "b")[0]
	assert_eq(int(row[2]), 90, "b abandonou: fica com 90")


func test_titulo_decidido_quando_a_vantagem_passa_do_que_resta() -> void:
	assert_eq(live.max_remaining(), 50, "2 corridas × 25")
	live.driver_points["a"] = 160
	var p := live.project(["a", "b", "c", "d"])
	var cl := live.clinch(p["drivers"])
	assert_eq(cl.get("id", ""), "a", "185 × 108: vantagem 77 > 50")
	live.driver_points["a"] = 100
	assert_true(live.clinch(live.project(["b", "a", "c", "d"])["drivers"]).is_empty())


func test_ordem_de_antes_da_corrida() -> void:
	assert_eq(live.before_order("drivers", 3), ["a", "b", "c"])
	assert_eq(live.before_order("teams", 2), ["t1", "t2"])
