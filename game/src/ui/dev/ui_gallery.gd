extends Control
## Galeria de desenvolvimento (--ui=gallery): os componentes da Garagem em todos os estados,
## para conferir por captura de tela. Não aparece no jogo.


func _ready() -> void:
	var page := ScreenKit.garage_page(self, "redbull")
	var bd: GarageBackdrop = page["backdrop"]
	bd.floor_ratio = 1.0
	bd.show_lamps = false
	bd.cone_x = -1.0
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 14)
	ScreenKit.place(grid, page["layer"], Control.PRESET_TOP_LEFT, Vector2(36, 20))

	_row(grid, "Bloco principal · normal / pressionado", [_tile("main", false), _tile("main", true)])
	_row(grid, "Bloco secundário · normal / pressionado", [_tile("alt", false), _tile("alt", true)])
	_row(grid, "Ação principal · normal / pressionada / desabilitada", [_cta(0), _cta(1), _cta(2)])
	var seg := ScreenKit.segmented([[0, "25%"], [1, "50%"], [2, "100%"]], 1, func(_v: int) -> void: pass)
	seg.custom_minimum_size = Vector2(360, 0)
	var dis := ScreenKit.segmented([[0, "Fim de semana"], [1, "Só a corrida"]], 0, func(_v: int) -> void: pass)
	dis.custom_minimum_size = Vector2(360, 0)
	(dis.get_child(0).get_child(1) as Button).disabled = true
	_row(grid, "Segmentado · selecionado no meio / opção desabilitada", [seg, dis])
	var tiles := ScreenKit.choice_tiles([["a", "Realista", "globe"], ["b", "Seco", "sun"], ["c", "Chuva", "rain"], ["d", "Variável", "mixed"]], "c", func(_v: String) -> void: pass)
	tiles.custom_minimum_size = Vector2(360, 0)
	_row(grid, "Opções com ícone · selecionada", [tiles, ScreenKit.round_button("swap"), ScreenKit.round_button("back", 52)])
	_row(grid, "Nomes longos", [ScreenKit.team_pill("racingbulls"), ScreenKit.team_pill("audi"), ScreenKit.team_pill("redbull")])
	_row(grid, "Indisponível", [_sized(ScreenKit.locked_row("Corrida Caótica"), 420)])


func _row(grid: GridContainer, label: String, items: Array) -> void:
	var cap := UiStyle.g_caption(label)
	cap.custom_minimum_size = Vector2(250, 0)
	cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	grid.add_child(cap)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	for it: Control in items:
		h.add_child(it)
	grid.add_child(h)


func _tile(kind: String, pressed: bool) -> Button:
	var b := ScreenKit.mode_tile("Grande Prêmio" if kind == "main" else "Corrida rápida", "Interlagos · direto para a largada", kind)
	b.custom_minimum_size.x = 380
	if pressed:
		b.toggle_mode = true
		b.button_pressed = true
	return b


func _cta(state: int) -> CutButton:
	var b := CutButton.new()
	b.text = "COMEÇAR"
	b.custom_minimum_size.x = 230
	if state == 1:
		b.toggle_mode = true
		b.button_pressed = true
	elif state == 2:
		b.disabled = true
	return b


func _sized(c: Control, w: float) -> Control:
	c.custom_minimum_size.x = w
	return c
