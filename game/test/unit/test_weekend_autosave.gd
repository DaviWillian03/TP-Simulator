extends GutTest
## Salvamento automático entre as sessões: o fim de semana volta de onde parou, sem refazer treinos e classificação.

const OPTS := {"weather": "dry", "incident_rate": 0.0, "duration_pct": 0.1, "seed": 7, "player_team": "williams"}


func before_each() -> void:
	SaveSlots.current = 1
	SaveSlots.delete_weekend("gp")
	SaveSlots.delete_weekend("campaign")


func after_all() -> void:
	SaveSlots.delete_weekend("gp")
	SaveSlots.delete_weekend("campaign")


func _until(w: WeekendSim, session: String) -> void:
	while w.session_id() != session:
		w.simulate_current()


func test_fim_de_semana_salvo_depois_da_classificacao_volta_igual() -> void:
	var w := WeekendSim.new("interlagos", OPTS)
	_until(w, "race")
	assert_true(SaveSlots.save_weekend(w, "gp"))
	var r := SaveSlots.load_weekend("gp")
	assert_not_null(r)
	assert_eq(r.session_id(), "race", "retoma na corrida, sem refazer treinos e classificação")
	assert_eq(r.grids["race"], w.grids["race"], "o grid da classificação é o mesmo")
	assert_eq(r.results["quali"], w.results["quali"])
	assert_eq(r.forecast, w.forecast)
	assert_almost_eq(r.setups["albon"].aero, w.setups["albon"].aero, 0.0001, "acerto dos treinos preservado")
	assert_eq(r.tyre_alloc.sets["albon"].size(), w.tyre_alloc.sets["albon"].size(), "jogos de pneus preservados")


func test_a_corrida_retomada_e_igual_a_corrida_original() -> void:
	var w := WeekendSim.new("interlagos", OPTS)
	_until(w, "race")
	SaveSlots.save_weekend(w, "gp")
	var r := SaveSlots.load_weekend("gp")
	var a := w.make_race({"radio": false})
	var b := r.make_race({"radio": false})
	a.run_to_end()
	b.run_to_end()
	assert_eq(a.standings().map(func(c: CarState) -> String: return c.driver["id"]), b.standings().map(func(c: CarState) -> String: return c.driver["id"]), "mesmo resultado")


func test_save_de_campeonato_de_outra_rodada_e_descartado() -> void:
	var w := WeekendSim.new("interlagos", OPTS)
	_until(w, "quali")
	SaveSlots.save_weekend(w, "campaign", 4)
	assert_null(SaveSlots.load_weekend("campaign", 5), "o campeonato já está na rodada seguinte")
	assert_false(SaveSlots.has_weekend("campaign"), "o save velho foi apagado")
	SaveSlots.save_weekend(w, "campaign", 4)
	assert_not_null(SaveSlots.load_weekend("campaign", 4))


func test_tipos_diferentes_nao_se_misturam_e_apagar_slot_leva_o_save() -> void:
	var w := WeekendSim.new("interlagos", OPTS)
	SaveSlots.save_weekend(w, "world", 0)
	assert_null(SaveSlots.load_weekend("campaign", 0), "save do Mundial não abre na Campanha")
	SaveSlots.delete(1)
	assert_false(SaveSlots.has_weekend("campaign"), "apagar o slot apaga o fim de semana dele")


func test_sessao_terminada_avisa_para_salvar() -> void:
	var w := WeekendSim.new("interlagos", OPTS)
	var n := [0]
	w.session_done.connect(func() -> void: n[0] += 1)
	w.simulate_current()
	assert_eq(n[0], 1, "um treino terminado dispara o salvamento")
