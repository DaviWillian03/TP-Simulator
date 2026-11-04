extends GutTest
## A IA rival também desenvolve o carro ao longo da temporada (campanha) — desde 2026-11-04 com peças físicas
## (CarParts), as mesmas regras do jogador, inclusive upgrades que dão errado.

var camp: Campaign


func before_each() -> void:
	camp = Campaign.new_real("williams")
	camp.detail = "advanced"


func _rating(c: Campaign, id: String) -> float:
	return float(GameData.team_by_id(c.teams(), id)["car_rating"])


func test_no_inicio_da_temporada_as_notas_sao_as_dos_dados() -> void:
	for t: Dictionary in GameData.teams():
		assert_almost_eq(_rating(camp, t["id"]), float(t["car_rating"]), 0.0001, t["id"])


## Passa n dias só para as peças (sem eventos aleatórios da campanha).
func _parts_days(c: Campaign, n: int) -> void:
	for i in n:
		c.day += 1
		for cp: CarParts in c.parts.values():
			cp.day_step(c)
	c.refresh_rating()


func _ai_mean(c: Campaign) -> float:
	var s := 0.0
	var n := 0
	for t: Dictionary in c.teams():
		if t["id"] != c.player_team:
			s += float(t["car_rating"])
			n += 1
	return s / n


func test_equipes_da_ia_evoluem_com_o_calendario() -> void:
	var before := _ai_mean(camp)
	_parts_days(camp, 150)
	assert_gt(_ai_mean(camp), before, "na média a IA melhora (com acertos e erros)")
	var specs := 0
	for cp: CarParts in camp.parts.values():
		if cp.team_id != camp.player_team:
			for pid: String in CarParts.part_ids():
				specs += cp.spec_list(pid).size() - 1
	assert_gt(specs, 20, "as equipes da IA pesquisaram várias peças")


func test_evolucao_e_deterministica_e_varia_por_equipe() -> void:
	var other := Campaign.new_real("williams")
	_parts_days(camp, 120)
	_parts_days(other, 120)
	assert_eq(_rating(camp, "ferrari"), _rating(other, "ferrari"))
	assert_ne(camp.rival_potential("ferrari"), camp.rival_potential("haas"), "cada equipe tem a sua sorte")


func test_dificuldade_aumenta_o_ganho_da_ia() -> void:
	var easy := Campaign.new_real("williams", {"ai_difficulty": "easy"})
	var hard := Campaign.new_real("williams", {"ai_difficulty": "hard"})
	assert_gt(hard.rival_potential("ferrari"), easy.rival_potential("ferrari"))


func test_a_equipe_do_jogador_nao_e_mexida_pela_ia() -> void:
	var before := _rating(camp, "williams")
	camp.day += 250
	camp.refresh_rating()
	assert_almost_eq(_rating(camp, "williams"), before + camp.dev.rating_bonus(), 0.0001)


func test_meta_da_diretoria_nao_muda_no_meio_da_temporada() -> void:
	var goal := camp.season_goal()
	camp.day += 280
	camp.refresh_rating()
	assert_eq(camp.season_goal(), goal)


func test_virada_guarda_parte_do_ganho_da_ia() -> void:
	_parts_days(camp, 200)
	var got := (camp.parts["ferrari"] as CarParts).avg_effect()
	camp.start_next_season()
	assert_almost_eq(float(camp.rival_carry["ferrari"]), got * 0.5, 0.0001)
	assert_false(camp.rival_carry.has("williams"), "o jogador usa a própria árvore")
	assert_almost_eq(_rating(camp, "ferrari"), 89.1 + got * 0.5, 0.0001, "peças zeradas; fica a herança")
	assert_eq((camp.parts["ferrari"] as CarParts).spec_list("fwing").size(), 1, "carro novo: versão A")


func test_heranca_da_ia_e_salva_e_carregada() -> void:
	camp.start_next_season()
	var copy := Campaign.from_dict(JSON.parse_string(JSON.stringify(camp.to_dict())))
	assert_almost_eq(float(copy.rival_carry["ferrari"]), float(camp.rival_carry["ferrari"]), 0.0001)
	assert_almost_eq(_rating(copy, "ferrari"), _rating(camp, "ferrari"), 0.0001)
