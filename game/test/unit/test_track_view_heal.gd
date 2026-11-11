extends GutTest
## Vigia da pista 3D: se o alvo de renderização fica com tamanho errado, a vista se conserta sozinha.


func test_vista_3d_corrige_o_tamanho_do_alvo() -> void:
	var sim := RaceSim.new(TrackModel.new(GameData.circuit("interlagos")), TyreModel.new(GameData.tyres()),
		GameData.teams(), GameData.drivers(), {"duration_pct": 0.25, "seed": 1, "weather": "dry", "incident_rate": 0.0})
	var holder := Control.new()
	holder.size = Vector2(640, 360)
	add_child_autofree(holder)
	var view := TrackView3D.new()
	holder.add_child(view)
	view.setup(sim)
	view.size = Vector2(640, 360)
	await wait_process_frames(2)
	assert_false(view.heal_viewport(), "tamanho certo: nada a fazer")
	view.stretch = false
	view._vp.size = Vector2i(2, 2)
	assert_true(view.heal_viewport(), "alvo com tamanho errado é corrigido")
	assert_eq(view._vp.size, Vector2i(640, 360))
	assert_eq(view._vp.render_target_update_mode, SubViewport.UPDATE_ALWAYS)
