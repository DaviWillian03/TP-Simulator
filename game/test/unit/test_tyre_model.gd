extends GutTest
## Modelo de pneus e regra de compostos de 2026.

var tyres: TyreModel


func before_each() -> void:
	tyres = TyreModel.new(GameData.tyres())


func test_pneu_mais_macio_e_mais_rapido_quando_novo() -> void:
	assert_lt(tyres.pace_penalty("soft", 0.0), tyres.pace_penalty("medium", 0.0))
	assert_lt(tyres.pace_penalty("medium", 0.0), tyres.pace_penalty("hard", 0.0))


func test_pneu_mais_macio_gasta_mais_rapido() -> void:
	assert_gt(tyres.wear_per_lap("soft"), tyres.wear_per_lap("medium"))
	assert_gt(tyres.wear_per_lap("medium"), tyres.wear_per_lap("hard"))


func test_desgaste_sempre_aumenta_a_perda_de_tempo() -> void:
	for c: String in tyres.dry_compounds():
		var previous := -1.0
		for i in 11:
			var p := tyres.pace_penalty(c, i / 10.0)
			assert_gt(p, previous, "%s com desgaste %.1f" % [c, i / 10.0])
			previous = p


func test_penhasco_pune_mais_que_o_desgaste_normal() -> void:
	var before_cliff := tyres.pace_penalty("soft", 0.7) - tyres.pace_penalty("soft", 0.6)
	var after_cliff := tyres.pace_penalty("soft", 0.95) - tyres.pace_penalty("soft", 0.85)
	assert_gt(after_cliff, before_cliff)


func test_regra_exige_dois_compostos_secos() -> void:
	assert_false(tyres.rule_satisfied(["medium"]))
	assert_false(tyres.rule_satisfied(["medium", "medium"]))
	assert_true(tyres.rule_satisfied(["medium", "hard"]))


func test_regra_isenta_quem_usou_pneu_de_chuva() -> void:
	assert_true(tyres.rule_satisfied(["inter"]))
	assert_true(tyres.rule_satisfied(["medium", "wet"]))


func test_corrida_mais_curta_reduz_a_vida_do_pneu_proporcionalmente() -> void:
	var full := tyres.expected_life_laps("medium", 1.0)
	var quarter := tyres.expected_life_laps("medium", 4.0)
	assert_almost_eq(quarter, full / 4.0, 0.01)
