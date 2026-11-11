class_name WorldTableScreen
extends Control
## Campeonato do Mundial em tela cheia (mockup v34, aprovado em 2026-11-10): classificação completa de pilotos e construtores,
## estatísticas clicáveis e ranking completo de cada uma. Aberto pelo botão de ampliar do painel ou por "Estatísticas".

const W := 1280.0
const H := 720.0
const GOLD := Color("#F5C542")

var world: WorldChampionship
var tables: WorldTables


func _ready() -> void:
	world = Session.world
	if world == null:
		Session.go_to_title.call_deferred()
		return
	var team := GameData.team_by_id(GameData.teams(), world.player_team)
	var page := ScreenKit.garage_page(self, world.player_team)
	(page["backdrop"] as GarageBackdrop).set_glow(Color(team["color"]))
	var layer: Control = page["layer"]
	var stage := Control.new()
	stage.set_anchors_preset(Control.PRESET_CENTER)
	stage.offset_left = -W / 2.0
	stage.offset_right = W / 2.0
	stage.offset_top = -H / 2.0
	stage.offset_bottom = H / 2.0
	layer.add_child(stage)
	var back := ScreenKit.round_button("back", 48, "Voltar ao painel")
	back.pressed.connect(Session.open_world_hub)
	back.position = Vector2(18, 14)
	stage.add_child(back)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -2)
	v.add_child(UiStyle.g_caption("Mundial F1 · temporada %d" % world.season))
	v.add_child(UiStyle.g_label("Campeonato", 26, GOLD, "black"))
	v.position = Vector2(78, 8)
	stage.add_child(v)
	tables = WorldTables.new()
	tables.position = Vector2(40, 84)
	tables.size = Vector2(W - 80, H - 84 - 30)
	stage.add_child(tables)
	tables.setup(world, ["drivers", "teams", "mates", "stats"], Session.world_table_mode, Session.world_table_stat)
	layer.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(layer, "modulate:a", 1.0, 0.18)
