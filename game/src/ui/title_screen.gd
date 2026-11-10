extends Control
## Menu principal em mosaico (mockup v26-1 aprovado em 2026-11-09): bloco grande da Campanha (carro da equipe salva e
## CONTINUAR, ou começar), bloco do Grande Prêmio com uma pista 3D e blocos menores (História, Nova equipe, Corrida
## caótica apagada). A escolha de equipe fica dentro de cada modo.

const LOGO := preload("res://assets/branding/logo.svg")
const GP_ART := ["spa", "suzuka", "interlagos", "monaco", "silverstone", "zandvoort"]

var _page: Dictionary
var _gp_tile: Button
var _camp_tile: Button


func _ready() -> void:
	var latest_c := SaveSlots.latest("campaign")
	var saved: Campaign = Campaign.load_saved(SaveSlots.campaign_path(latest_c)) if latest_c > 0 else null
	var team_id := saved.player_team if saved != null else Session.player_team
	_page = ScreenKit.garage_page(self, team_id)
	var bd: GarageBackdrop = _page["backdrop"]
	bd.set_glow(Color("#2a3346"), 0.35)
	var layer: Control = _page["layer"]

	var logo := TextureRect.new()
	logo.texture = LOGO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ScreenKit.place(logo, layer, Control.PRESET_TOP_LEFT, Vector2(36, 18), Vector2(240, 74))
	ScreenKit.place(UiStyle.g_caption("Temporada 2026"), layer, Control.PRESET_TOP_RIGHT, Vector2(-170, 46))
	var gear := ScreenKit.round_button("gear", 48, "Configurações")
	gear.pressed.connect(Session.open_settings)
	ScreenKit.place(gear, layer, Control.PRESET_TOP_RIGHT, Vector2(-44, 28))
	var help := ScreenKit.round_button("help", 48, "Ajuda")
	help.pressed.connect(func() -> void: HelpSheet.open(self))
	ScreenKit.place(help, layer, Control.PRESET_TOP_RIGHT, Vector2(-100, 28))
	if Session.debug_ui == "help":  # (captura) --ui=help abre a ajuda
		HelpSheet.open.call_deferred(self)
	else:
		Tips.show_once.call_deferred(self, "title")

	_camp_tile = _campaign_tile(saved, Rect2(40, 110, 700, 570))
	layer.add_child(_camp_tile)
	_gp_tile = _gp_block(Rect2(760, 110, 480, 186))
	layer.add_child(_gp_tile)
	layer.add_child(_world_tile(Rect2(760, 308, 480, 112)))
	var hist := _small(Rect2(760, 432, 152, 248), "crown", "HISTÓRIA", "15 lendas", UiStyle.SECTION["hist"])
	if saved != null:
		hist.pressed.connect(func() -> void:
			Session.campaign = saved
			Session.player_team = saved.player_team
			Session.open_campaign_history())
	else:
		hist.disabled = true
	layer.add_child(hist)
	var new_team := _small(Rect2(924, 432, 152, 248), "plus", "NOVA EQUIPE", "12ª do grid", UiStyle.SECTION["hq"])
	new_team.pressed.connect(Session.open_team_creator)
	layer.add_child(new_team)
	var chaos := _small(Rect2(1088, 432, 152, 248), "lock", "CAÓTICA", "em breve", UiStyle.G_TEXT_OFF)
	chaos.disabled = true
	layer.add_child(chaos)

	layer.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(layer, "modulate:a", 1.0, 0.18)


## Bloco do Campeonato Mundial F1 (mockup v29-1): temporada real de 2026, sem desenvolvimento de carro.
func _world_tile(r: Rect2) -> Button:
	var gold := Color("#F5C542")
	var b := _tile(r, Color("#171a21").lerp(gold, 0.1))
	var st := UiStyle.g_box(Color("#171a21").lerp(gold, 0.1), 22, 0, 0)
	st.set_border_width_all(3)
	st.border_color = gold
	for s: String in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(s, st)
	b.pressed.connect(Session.open_slots.bind("world"))
	var sq := PanelContainer.new()
	sq.add_theme_stylebox_override("panel", UiStyle.g_box(gold, 18, 13, 13))
	sq.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sq.add_child(ScreenKit.icon("globe", 34, UiStyle.G_INK))
	sq.position = Vector2(18, 18)
	b.add_child(sq)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(UiStyle.g_label("Campeonato Mundial F1", 22, UiStyle.G_TEXT, "black"))
	var latest_w := SaveSlots.latest("world")
	var saved: WorldChampionship = WorldChampionship.load_saved(SaveSlots.world_path(latest_w)) if latest_w > 0 else null
	var sub := "22 GPs · sem desenvolvimento"
	if saved != null:
		sub = "%s · rodada %d/22 · %dº" % [String(GameData.team_by_id(GameData.teams(), saved.player_team).get("name", "")), mini(saved.round + 1, 22), saved.team_position(saved.player_team)]
	var sl := UiStyle.g_label(sub, 13, Color("#c9b27a"), "bold")
	sl.clip_text = true
	v.add_child(sl)
	v.position = Vector2(94, 20)
	v.size = Vector2(r.size.x - 94 - 70, 0)
	b.add_child(v)
	var play := PanelContainer.new()
	play.add_theme_stylebox_override("panel", UiStyle.g_box(Color.WHITE, 23, 12, 12))
	play.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play.add_child(ScreenKit.icon("play", 22, UiStyle.G_INK))
	play.position = Vector2(r.size.x - 66, 33)
	b.add_child(play)
	return b


func _tile(r: Rect2, fill: Color) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.clip_contents = true
	b.position = r.position
	b.size = r.size
	for st: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var box := UiStyle.g_box(fill if st in ["normal", "disabled"] else fill.lightened(0.06), 22, 0, 0)
		box.shadow_color = Color(0, 0, 0, 0.35)
		box.shadow_size = 10
		b.add_theme_stylebox_override(st, box)
	ScreenKit.press_feedback(b)
	return b


func _chip(text: String, icon_name: String, fill: Color, icon_col := UiStyle.G_TEXT) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.g_box(fill, 15, 12, 4))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	if icon_name != "":
		h.add_child(ScreenKit.icon(icon_name, 16, icon_col))
	h.add_child(UiStyle.g_label(text, 14, Color.WHITE, "black"))
	p.add_child(h)
	return p


func _campaign_tile(saved: Campaign, r: Rect2) -> Button:
	var col := UiStyle.team_color(saved.player_team) if saved != null else UiStyle.SECTION["hq"]
	var b := _tile(r, Color("#101c1b").lerp(col, 0.12))
	b.pressed.connect(Session.open_slots.bind("campaign"))  # escolhe o slot (continua o salvo ou começa uma Campanha)
	var glow := ColorRect.new()
	glow.color = Color(col, 0.08)
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(glow)
	var car := TextureRect.new()
	car.texture = CarArt.car_texture(saved.team() if saved != null else GameData.team_by_id(GameData.teams(), Session.player_team))
	car.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	car.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	car.position = Vector2(40, 230)
	car.size = Vector2(r.size.x - 80, 240)
	car.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(car)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.position = Vector2(28, 26)
	var tag := HBoxContainer.new()
	tag.add_child(_chip("CAMPANHA", "trophy", UiStyle.RED, Color.WHITE))
	v.add_child(tag)
	var name := String(saved.team().get("name", "")).to_upper() if saved != null else "SUA EQUIPE NA F1"
	v.add_child(UiStyle.g_label(name, 60 if name.length() <= 14 else 44, UiStyle.G_TEXT, "black"))
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 8)
	if saved != null:
		chips.add_child(_chip("RD %d/%d" % [mini(saved.round + 1, Campaign.calendar().size()), Campaign.calendar().size()], "cal", Color(1, 1, 1, 0.1)))
		chips.add_child(_chip("%dº" % saved.team_position(saved.player_team), "trophy", Color(1, 1, 1, 0.1), UiStyle.SECTION["hist"]))
		chips.add_child(_chip("%d mi" % int(saved.budget_musd), "money", Color(1, 1, 1, 0.1), UiStyle.SECTION["money"]))
	else:
		chips.add_child(_chip("equipe real ou criada", "users", Color(1, 1, 1, 0.1)))
	v.add_child(chips)
	b.add_child(v)
	var go := CutButton.new()
	go.text = "CONTINUAR" if saved != null else "COMEÇAR"
	go.mouse_filter = Control.MOUSE_FILTER_IGNORE
	go.add_theme_font_size_override("font_size", UiStyle.fs(22))
	go.size = Vector2(220, 64)
	go.position = Vector2(r.size.x - 28 - 220, r.size.y - 28 - 64)
	b.add_child(go)
	return b


func _gp_block(r: Rect2) -> Button:
	var b := _tile(r, Color("#171a21"))
	b.pressed.connect(Session.open_team_select.bind("gp"))
	var art := TextureRect.new()
	art.texture = CampaignHub.track_art(GP_ART[Time.get_date_dict_from_system()["day"] % GP_ART.size()])
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(art)
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(0.03, 0.04, 0.055, 0.0), Color(0.03, 0.04, 0.055, 0.92)])
	grad.offsets = PackedFloat32Array([0.3, 1.0])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_to = Vector2(0, 1)
	var shade := TextureRect.new()
	shade.texture = gt
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(shade)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tag := HBoxContainer.new()
	tag.add_child(_chip("GRANDE PRÊMIO", "flag", UiStyle.SECTION["drivers"], Color.WHITE))
	v.add_child(tag)
	v.add_child(UiStyle.g_label("1 FIM DE SEMANA", 38, UiStyle.G_TEXT, "black"))
	v.position = Vector2(22, r.size.y - 112)
	b.add_child(v)
	var play := PanelContainer.new()
	play.add_theme_stylebox_override("panel", UiStyle.g_box(UiStyle.G_LIGHT, 29, 16, 16))
	play.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play.add_child(ScreenKit.icon("play", 24, UiStyle.G_INK))
	play.position = Vector2(r.size.x - 22 - 58, r.size.y - 22 - 58)
	b.add_child(play)
	return b


func _small(r: Rect2, icon_name: String, title: String, sub: String, col: Color) -> Button:
	var b := _tile(r, Color("#171a21").lerp(col, 0.12))
	var sq := PanelContainer.new()
	sq.add_theme_stylebox_override("panel", UiStyle.g_box(col, 16, 12, 12))
	sq.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sq.add_child(ScreenKit.icon(icon_name, 28, UiStyle.G_INK))
	sq.position = Vector2(18, 20)
	b.add_child(sq)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(UiStyle.g_label(title, 19 if title.length() <= 9 else 16, UiStyle.G_TEXT, "black"))
	if sub != "":
		v.add_child(UiStyle.g_label(sub, 13, UiStyle.G_TEXT_2, "bold"))
	v.position = Vector2(18, r.size.y - 74)
	b.add_child(v)
	return b
