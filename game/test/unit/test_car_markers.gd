extends GutTest
## Marcadores de carro (estilo MM3): cada equipe com cor distinta, número do piloto legível.


func test_team_colors_are_all_distinct() -> void:
	var teams := GameData.teams()
	var worst := 999.0
	var pair := ""
	for i in teams.size():
		for j in range(i + 1, teams.size()):
			var a := Color(teams[i]["color"])
			var b := Color(teams[j]["color"])
			var d := sqrt(pow(a.r - b.r, 2) + pow(a.g - b.g, 2) + pow(a.b - b.b, 2)) * 255.0
			if d < worst:
				worst = d
				pair = "%s/%s" % [teams[i]["id"], teams[j]["id"]]
	assert_gt(worst, 60.0, "duas equipes com cor quase igual no mapa: %s" % pair)


func test_marker_shows_driver_number_and_player_ring() -> void:
	var sim := RaceSim.new(TrackModel.new(GameData.circuit("interlagos")), TyreModel.new(GameData.tyres()),
		GameData.teams(), GameData.drivers(), {"weather": "dry", "incident_rate": 0.0, "player_team": "redbull"})
	var mine: CarState = null
	var other: CarState = null
	for c in sim.cars:
		if c.is_player and mine == null:
			mine = c
		elif not c.is_player and other == null:
			other = c
	var m1 := CarMarker3D.new()
	m1.setup(mine)
	add_child_autofree(m1)
	var m2 := CarMarker3D.new()
	m2.setup(other)
	add_child_autofree(m2)
	var label: Label3D = null
	for c in m1.get_children():
		if c is Label3D:
			label = c
	assert_not_null(label)
	assert_eq(label.text, str(int(mine.driver["number"])), "o número do piloto vai em cima do disco")
	assert_eq(m1.get_child_count(), m2.get_child_count() + 1, "só o carro do jogador tem o anel")


func test_ink_contrasts_with_team_color() -> void:
	assert_eq(CarMarker3D._ink_for(Color("#F2F2F2")), Color("#0b0c0f"), "disco claro: número escuro")
	assert_eq(CarMarker3D._ink_for(Color("#2B2B2B")), Color.WHITE, "disco escuro: número branco")


func test_emblem_background_comes_from_data() -> void:
	# McLaren: fundo laranja (antes caía no preto); Racing Bulls: azul-marinho com bom contraste para o logo branco
	assert_eq(TeamEmblems._frame_color(GameData.team_by_id(GameData.teams(), "mclaren")), Color("#FF8000"))
	assert_eq(TeamEmblems._frame_color(GameData.team_by_id(GameData.teams(), "racingbulls")), Color("#26398C"))
	# sem emblem_bg continua a regra antiga (cor da equipe escura o bastante)
	assert_eq(TeamEmblems._frame_color(GameData.team_by_id(GameData.teams(), "ferrari")), Color("#E8002D"))
