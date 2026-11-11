extends GutTest
## Telas do Campeonato Mundial F1: painel (v29), fim de temporada e a escolha de equipe do modo.

var _prev_world: WorldChampionship


func before_each() -> void:
	_prev_world = Session.world
	Session.world = WorldChampionship.start("williams")
	Session.player_team = "williams"


func after_each() -> void:
	Session.world = _prev_world


func _open(path: String) -> Control:
	var s: Control = load(path).instantiate()
	add_child_autofree(s)
	await wait_process_frames(3)
	return s


func test_painel_mostra_proximo_gp_tabela_e_pecas() -> void:
	var hub: WorldHub = await _open("res://src/ui/world_hub_screen.tscn")
	assert_eq(hub.world.next_round()["id"], "albertpark")
	assert_eq(hub._standings_box.get_child_count(), hub.world.drivers().size(), "tabela com todos os pilotos (rola com o dedo)")
	hub._set_tab("teams")
	await wait_process_frames(2)
	assert_eq(hub._standings_box.get_child_count(), GameData.teams().size(), "tabela com todos os construtores")


func test_painel_avisa_a_punicao_de_grid_do_motor() -> void:
	Session.world.parts.unit("williams", 0, "pu")["n"] = 5
	Session.world.parts.unit("williams", 0, "pu")["fresh"] = true
	var hub: WorldHub = await _open("res://src/ui/world_hub_screen.tscn")
	var found := false
	var stack: Array = [hub]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Label and String((n as Label).text).to_upper().contains("MOTOR") and String((n as Label).text).to_upper().contains("GRID"):
			found = true
		stack.append_array(n.get_children())
	assert_true(found, "chip vermelho: 5º motor, posições a menos no grid")


func test_fim_de_temporada_mostra_campeoes() -> void:
	Session.world.round = 22
	Session.world.driver_points["antonelli"] = 300
	Session.world.team_points["mercedes"] = 500
	var fin: WorldFinal = await _open("res://src/ui/world_final_screen.tscn")
	assert_eq(fin.world.champions()["driver"], "antonelli")
	assert_eq(fin.world.champions()["team"], "mercedes")


func test_escolha_de_equipe_do_mundial_nao_mostra_f2_f3() -> void:
	Session.team_select_mode = "world"
	var sel: Control = await _open("res://src/ui/team_select_screen.tscn")
	assert_eq(sel._mode, "world")
	var has_seg := false
	var stack: Array = [sel]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Button and (n as Button).text == "F2":
			has_seg = true
		stack.append_array(n.get_children())
	assert_false(has_seg, "o Mundial é só F1")
	Session.team_select_mode = "gp"


func test_corrida_do_mundial_tem_campeonato_ao_vivo_e_animacao_de_titulo() -> void:
	var w := Session.world
	w.round = 21  # última etapa: Abu Dhabi
	w.driver_points["antonelli"] = 500  # título de pilotos já matematicamente decidido
	w.team_points["mercedes"] = 900
	var wk := WeekendSim.new(w.next_round()["id"], w.weekend_options({"weather": "dry", "incident_rate": 0.0, "duration_pct": 0.1}))
	while wk.session_id() != "race":
		wk.simulate_current()
	Session.weekend = wk
	var screen: Control = await _open("res://src/ui/race_screen.tscn")
	screen.paused = true
	assert_not_null(screen._champ, "campeonato ao vivo ligado no Mundial")
	assert_eq(screen._season(), w, "a corrida lê pontos e calendário do Mundial")
	assert_eq(int(w.remaining_after_current()["races"]), 0, "na última etapa não resta nada")
	var titles: Array = screen._titles_decided_now()
	assert_true(titles.size() >= 1, "o título decidido dispara a animação de campeão")
	Session.weekend = null


func test_mundial_guarda_vitorias_para_a_animacao_de_campeao() -> void:
	var w := Session.world
	var wk := WeekendSim.new(w.next_round()["id"], w.weekend_options({"weather": "dry", "incident_rate": 0.0, "duration_pct": 0.1}))
	var guard := 0
	while not wk.is_over() and guard < 20:
		wk.simulate_current()
		guard += 1
	w.record_weekend(wk)
	var winner: String = wk.results["race"][0]
	assert_eq(int(w.season_log[winner]["wins"]), 1)
	var d := {}
	for dd: Dictionary in w.drivers():
		if dd["id"] == winner:
			d = dd
	assert_gte(int(w.career_of(d)["wins"]), 1)


func _play_one_round() -> void:
	var w := Session.world
	var wk := WeekendSim.new(w.next_round()["id"], w.weekend_options({"weather": "dry", "incident_rate": 0.0, "duration_pct": 0.1}))
	var guard := 0
	while not wk.is_over() and guard < 20:
		wk.simulate_current()
		guard += 1
	w.record_weekend(wk)


func test_historico_guarda_pole_melhor_volta_e_posicoes() -> void:
	_play_one_round()
	var h: Dictionary = Session.world.history.back()
	assert_ne(String(h["pole"]), "")
	assert_gt(float(h["pole_time"]), 0.0, "tempo da pole")
	assert_false((h["fastest"] as Dictionary).is_empty(), "melhor volta da corrida")
	assert_true((h["gains"] as Dictionary).has(String(h["results"][0])))
	assert_eq((h["before_drivers"] as Dictionary).size(), 22, "posições antes da corrida, para mostrar quem subiu")


func test_estatisticas_por_piloto_e_por_equipe() -> void:
	_play_one_round()
	var w := Session.world
	var by_driver := w.stat_table("wins")
	assert_eq(by_driver.size(), 1)
	assert_eq(int(by_driver[0][1]), 1)
	var by_team := w.stat_table("wins", true)
	assert_eq(by_team[0][0], w.team_of(String(by_driver[0][0])))
	assert_gte(w.stat_table("podiums").size(), 3)


func test_tela_de_resultado_tem_as_tres_abas() -> void:
	_play_one_round()
	for tab: String in ["result", "champ", "stats"]:
		Session.world_result_tab = tab
		var scr: WorldResult = await _open("res://src/ui/world_result_screen.tscn")
		assert_eq(scr._tab, tab)
		assert_gt(scr._body.get_child_count(), 0, "aba %s montou o conteúdo" % tab)
		scr.queue_free()
		await wait_process_frames(2)
	Session.world_result_tab = "result"


func test_tabela_ampliada_tem_todos_os_pilotos_e_equipes() -> void:
	_play_one_round()
	Session.world_table_mode = "drivers"
	Session.world_table_stat = ""
	var scr: WorldTableScreen = await _open("res://src/ui/world_table_screen.tscn")
	var t := scr.tables
	assert_eq(_count_rows(t), Session.world.drivers().size(), "pilotos")
	t.mode = "teams"
	t._render()
	assert_eq(_count_rows(t), GameData.teams().size(), "construtores")


func test_estatisticas_sao_clicaveis_e_o_ranking_traz_todo_mundo() -> void:
	_play_one_round()
	Session.world_table_mode = "stats"
	Session.world_table_stat = ""
	var scr: WorldTableScreen = await _open("res://src/ui/world_table_screen.tscn")
	var t := scr.tables
	var tiles: Array[Button] = []
	_collect_tiles(t, tiles)
	assert_eq(tiles.size(), 4, "vitórias, poles, pódios e abandonos")
	tiles[0].emit_signal("pressed")
	assert_eq(t.stat, "wins", "tocar no quadro abre o ranking")
	assert_eq(t.ranking("wins").size(), Session.world.drivers().size(), "ranking inclui quem tem zero")
	t.by_team = true
	assert_eq(t.ranking("wins").size(), GameData.teams().size(), "por equipe")
	assert_eq(int(t.ranking("wins")[0][1]), int(Session.world.stat_table("wins", true)[0][1]), "o líder bate com a estatística")


func test_painel_abre_a_tela_ampliada_pelo_botao() -> void:
	var hub: WorldHub = await _open("res://src/ui/world_hub_screen.tscn")
	var found := false
	for b in _buttons(hub):
		if b.tooltip_text == "Ampliar o campeonato":
			found = true
	assert_true(found, "botão de ampliar no cartão da tabela")


func _count_rows(t: WorldTables) -> int:
	for c in t.find_children("*", "VBoxContainer", true, false):
		if c.get_parent() is DragScroll:
			return c.get_child_count()
	return 0


func _collect_tiles(n: Node, out: Array[Button]) -> void:
	for c in n.get_children():
		if c is Button and (c as Button).has_meta("stat"):
			out.append(c)
		_collect_tiles(c, out)


func _buttons(n: Node) -> Array[Button]:
	var out: Array[Button] = []
	for c in n.get_children():
		if c is Button:
			out.append(c)
		out.append_array(_buttons(c))
	return out


func test_duelo_de_companheiros_conta_quali_corrida_e_pontos() -> void:
	_play_one_round()
	_play_one_round()
	var w := Session.world
	assert_true((w.history[0] as Dictionary).has("quali"), "histórico guarda os tempos da classificação")
	for t: Dictionary in GameData.teams():
		var d := w.teammate_duel(String(t["id"]))
		assert_eq(int(d["quali"][0]) + int(d["quali"][1]), 2, "um vencedor de classificação por GP (%s)" % t["id"])
		assert_lte(int(d["race"][0]) + int(d["race"][1]), 2)
		assert_eq(int(d["points"][0]), int(w.driver_points.get(d["a"], 0)))
		if int(d["quali"][0]) == 2:
			assert_gt(float(d["gap"]), 0.0, "quem venceu as duas classificações tem vantagem média positiva")
	Session.world_table_mode = "mates"
	var scr: WorldTableScreen = await _open("res://src/ui/world_table_screen.tscn")
	assert_eq(_count_rows(scr.tables), GameData.teams().size(), "um cartão por equipe")
