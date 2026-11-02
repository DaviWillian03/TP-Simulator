extends GutTest
## A IA rival também desenvolve o carro ao longo da temporada (campanha).

var camp: Campaign


func before_each() -> void:
	camp = Campaign.new_real("williams")
	camp.detail = "advanced"


func _rating(c: Campaign, id: String) -> float:
	return float(GameData.team_by_id(c.teams(), id)["car_rating"])


func test_no_inicio_da_temporada_as_notas_sao_as_dos_dados() -> void:
	for t: Dictionary in GameData.teams():
		assert_almost_eq(_rating(camp, t["id"]), float(t["car_rating"]), 0.0001, t["id"])


func test_equipes_da_ia_evoluem_com_o_calendario() -> void:
	var before := _rating(camp, "mclaren")
	camp.day = camp._season_start_day() + 150
	camp.refresh_rating()
	assert_gt(_rating(camp, "mclaren"), before)
	assert_gt(camp.season_progress(), 0.2)


func test_evolucao_e_deterministica_e_varia_por_equipe() -> void:
	var other := Campaign.new_real("williams")
	camp.day += 200
	other.day += 200
	camp.refresh_rating()
	other.refresh_rating()
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
	var potential := camp.rival_potential("ferrari")
	camp.start_next_season()
	assert_almost_eq(float(camp.rival_carry["ferrari"]), potential * 0.5, 0.0001)
	assert_false(camp.rival_carry.has("williams"), "o jogador usa a própria árvore")
	assert_gt(_rating(camp, "ferrari"), 90.0, "começa a nova temporada acima da nota anterior")


func test_heranca_da_ia_e_salva_e_carregada() -> void:
	camp.start_next_season()
	var copy := Campaign.from_dict(JSON.parse_string(JSON.stringify(camp.to_dict())))
	assert_almost_eq(float(copy.rival_carry["ferrari"]), float(camp.rival_carry["ferrari"]), 0.0001)
	assert_almost_eq(_rating(copy, "ferrari"), _rating(camp, "ferrari"), 0.0001)
