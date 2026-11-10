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
	assert_gte(hub._standings_box.get_child_count(), 8, "tabela de pilotos com o topo e os seus")
	hub._set_tab("teams")
	await wait_process_frames(2)
	assert_gte(hub._standings_box.get_child_count(), 8, "tabela de construtores")


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
