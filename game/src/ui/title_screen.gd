extends Control
## Menu principal (mockup v16-1 aprovado, 2026-11-04): só o logo do jogo e os modos (Campanha e Grande Prêmio; o modo
## Corrida rápida saiu em 2026-11-08 — "só a corrida" continua como formato do Grande Prêmio). A escolha de equipe fica dentro de
## cada modo (tela de escolha de equipe). Modos ainda não implementados aparecem apagados, com cadeado.

const LOGO := preload("res://assets/branding/logo.svg")

var _page: Dictionary
var _gp_tile: Button
var _camp_tile: Button


func _ready() -> void:
	_page = ScreenKit.garage_page(self, Session.player_team)
	var bd: GarageBackdrop = _page["backdrop"]
	bd.set_glow(Color("#2a3346"), 0.35)
	var layer: Control = _page["layer"]

	var logo := TextureRect.new()
	logo.texture = LOGO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ScreenKit.place(logo, layer, Control.PRESET_TOP_LEFT, Vector2(420, 64), Vector2(440, 172))

	var modes := VBoxContainer.new()
	modes.add_theme_constant_override("separation", UiStyle.SP_M - 2)
	ScreenKit.place(modes, layer, Control.PRESET_TOP_LEFT, Vector2(405, 272), Vector2(470, 0))
	var saved := Campaign.load_saved()
	_camp_tile = ScreenKit.mode_tile("Campanha", ("Continuar: %s · RD %d" % [saved.team().get("name", ""), mini(saved.round + 1, 22)]) if saved != null else "Assuma uma equipe ou crie a sua", "main")
	_camp_tile.pressed.connect(Session.open_campaign)
	modes.add_child(_camp_tile)
	_gp_tile = ScreenKit.mode_tile("Grande Prêmio", "Um fim de semana avulso", "alt")
	_gp_tile.pressed.connect(Session.open_team_select.bind("gp"))
	modes.add_child(_gp_tile)
	modes.add_child(ScreenKit.locked_row("Corrida Caótica"))
	ScreenKit.place(UiStyle.g_caption("Temporada 2026 · 22 Grandes Prêmios"), layer, Control.PRESET_BOTTOM_RIGHT, Vector2(-44, -34))

	layer.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(layer, "modulate:a", 1.0, 0.18)
