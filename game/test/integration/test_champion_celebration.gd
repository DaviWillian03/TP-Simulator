extends GutTest
## Animação de campeão (decisões de 2026-11-08, mockups v24-4/5).


func _make(data: Dictionary) -> ChampionCelebration:
	var c := ChampionCelebration.new()
	add_child_autofree(c)
	c.setup(data)
	return c


func test_faixa_com_o_numero_de_titulos() -> void:
	assert_eq(_make({"kind": "drivers", "name": "Lando Norris", "titles": 2}).headline(), "NORRIS É BICAMPEÃO!")
	assert_eq(_make({"kind": "drivers", "name": "Kimi Antonelli", "titles": 1}).headline(), "ANTONELLI É CAMPEÃO!")
	assert_eq(_make({"kind": "teams", "name": "McLaren", "titles": 11}).headline(), "MCLAREN É CAMPEÃ!")


func test_pista_depois_poster_e_continuar() -> void:
	var c := _make({"kind": "drivers", "name": "Lando Norris", "titles": 2, "season": 2027, "stats": [["VITÓRIAS", 9]]})
	assert_eq(c._phase, 1, "começa na pista")
	c._process(ChampionCelebration.TRACK_S + 0.5)
	for i in 40:
		c._process(0.1)
	assert_eq(c._phase, 2, "depois vem o pôster")
	var fired := [false]
	c.done.connect(func() -> void: fired[0] = true)
	c._finish()
	assert_true(fired[0])
