extends GutTest
## Conselho de regras: propostas, votação, aplicação e efeito nos fins de semana.

var camp: Campaign


func before_each() -> void:
	camp = Campaign.new_real("williams")
	camp.detail = "advanced"
	camp.events.freq = "off"


func _prop(id: String) -> Dictionary:
	for p: Dictionary in Regulations.data()["proposals"]:
		if p["id"] == id:
			return p
	return {}


func _force(id: String, yes: int, no: int, mine: String) -> void:
	camp.regs.proposals = [_prop(id)]
	var v := {}
	var i := 0
	for t: Dictionary in camp.teams():
		if t["id"] == camp.player_team:
			continue
		v[t["id"]] = "y" if i < yes else ("n" if i < yes + no else "w")
		i += 1
	camp.regs.votes = {id: v}
	camp.regs.player_votes = {id: mine}


func test_regulamento_inicial_tem_seis_sprints_e_pontos_padrao() -> void:
	assert_eq(camp.regs.sprint_ids.size(), 6)
	assert_eq(camp.regs.points_race, RaceSim.RACE_POINTS)
	assert_eq(camp.regs.min_dry_compounds, 2)
	assert_true(camp.regs.is_sprint("shanghai"))
	assert_false(camp.regs.is_sprint("monaco"))


func test_votacao_so_abre_no_fim_da_temporada() -> void:
	assert_false(camp.regs.vote_open(camp))
	camp.round = 22
	assert_true(camp.regs.vote_open(camp))


func test_abrir_votacao_traz_uma_proposta_por_tipo_e_voto_da_ia() -> void:
	camp.regs.open_vote(camp)
	assert_eq(camp.regs.proposals.size(), 4, "3 esportivas + 1 técnica")
	var kinds := camp.regs.proposals.map(func(p: Dictionary) -> String: return p["kind"])
	assert_eq(kinds, ["points", "sprint", "tyres", "tech"])
	for p: Dictionary in camp.regs.proposals:
		assert_eq((camp.regs.votes[p["id"]] as Dictionary).size(), 10, "10 equipes da IA votam")
		assert_false((camp.regs.votes[p["id"]] as Dictionary).has("williams"))
		assert_eq(camp.regs.player_votes[p["id"]], "w", "começa abstendo")


func test_equipes_fortes_e_fracas_votam_de_lados_opostos() -> void:
	var p := _prop("sprints_more")  # favors: top
	var top: String = camp.regs._ai_vote(camp, "mercedes", p)
	var low: String = camp.regs._ai_vote(camp, "cadillac", p)
	if top == low:
		assert_eq(top, "w", "se o ruído inverter um dos lados, nunca vira o mesmo voto forte")
	assert_ne(top + low, "nn")


func test_placar_maioria_simples_e_empate_barra() -> void:
	_force("points_top12", 5, 5, "w")
	var t: Dictionary = camp.regs.tally("points_top12")
	assert_eq(t["y"], 5)
	assert_false(t["passed"], "empate barra")
	camp.regs.cast("points_top12", "y")
	assert_true(camp.regs.tally("points_top12")["passed"], "o voto do jogador desempata")
	camp.regs.cast("points_top12", "n")
	assert_false(camp.regs.tally("points_top12")["passed"])
	_force("points_top12", 4, 0, "w")
	assert_true(camp.regs.tally("points_top12")["passed"], "abstenção não conta")


func test_aprovada_muda_a_pontuacao_e_rejeitada_nao() -> void:
	_force("points_top12", 7, 3, "y")
	camp.regs.apply_passed(camp)
	assert_eq(camp.regs.points_race.size(), 12)
	assert_eq(camp.regs.points_for(12, false), 1)
	assert_eq(camp.regs.points_for(13, false), 0)
	_force("points_winner", 3, 7, "n")
	camp.regs.apply_passed(camp)
	assert_eq(camp.regs.points_race.size(), 12, "rejeitada não muda")
	assert_eq(camp.regs.history.size(), 2)


func test_sprints_mais_e_menos_mudam_os_fins_de_semana() -> void:
	_force("sprints_more", 8, 2, "y")
	camp.regs.apply_passed(camp)
	assert_eq(camp.regs.sprint_ids.size(), 8)
	assert_true(camp.regs.is_sprint("austin"))
	_force("sprints_fewer", 8, 2, "y")
	camp.regs.apply_passed(camp)
	assert_eq(camp.regs.sprint_ids.size(), 6)
	assert_false(camp.regs.is_sprint("austin"))


func test_regra_de_pneus_vai_para_a_simulacao_do_fim_de_semana() -> void:
	_force("tyres_three", 8, 2, "y")
	camp.regs.apply_passed(camp)
	assert_eq(camp.regs.min_dry_compounds, 3)
	var w := WeekendSim.new("monaco", camp.weekend_options({"weather": "dry", "incident_rate": 0.0, "format": "race_only"}))
	assert_eq(w.tyres.min_dry_compounds, 3)
	assert_true(w.tyres.rule_satisfied(["soft", "medium", "hard"]))
	assert_false(w.tyres.rule_satisfied(["soft", "medium"]))


func test_sprint_do_conselho_troca_o_formato_do_fim_de_semana() -> void:
	_force("sprints_more", 8, 2, "y")
	camp.regs.apply_passed(camp)
	camp.round = 16  # austin é a rodada 17 do calendário
	var o := camp.weekend_options({"weather": "dry", "incident_rate": 0.0})
	assert_eq(o["sprint"], true)
	var w := WeekendSim.new(camp.next_round()["id"], o)
	assert_true(w.sprint_weekend)
	assert_true(w.sessions.has("sprint"))


func test_pontos_do_conselho_entram_no_resultado_da_corrida() -> void:
	_force("points_winner", 8, 2, "y")
	camp.regs.apply_passed(camp)
	var w := WeekendSim.new("interlagos", camp.weekend_options({"duration_pct": 0.25, "weather": "dry", "incident_rate": 0.0, "format": "race_only"}))
	w.simulate_current()
	var winner: String = w.results["race"][0]
	assert_eq(int(w.points[winner]), 30)


func test_propostas_se_aplicam_na_virada_e_viram_noticia() -> void:
	camp.round = 22
	camp.regs.open_vote(camp)
	for p: Dictionary in camp.regs.proposals:
		camp.regs.cast(p["id"], "y")
	camp.start_next_season()
	assert_true(camp.regs.proposals.is_empty())
	assert_gt(camp.regs.history.size(), 0)
	var ids: Array = camp.events.news.map(func(n: Dictionary) -> String: return n["id"])
	assert_has(ids, "council", "virou notícia (técnica aprovada também gera 'ano de virada')")


func test_salvar_e_carregar_guarda_regras_e_votacao() -> void:
	camp.round = 22
	camp.regs.open_vote(camp)
	camp.regs.cast(camp.regs.proposals[0]["id"], "y")
	var copy := Campaign.from_dict(JSON.parse_string(JSON.stringify(camp.to_dict())))
	assert_eq(copy.regs.proposals.size(), 4)
	assert_eq(copy.regs.player_votes[camp.regs.proposals[0]["id"]], "y")
	assert_eq(copy.regs.sprint_ids, camp.regs.sprint_ids)
