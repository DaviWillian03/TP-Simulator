class_name WorldFinal
extends Control
## Fim do Campeonato Mundial F1: campeões de pilotos e construtores, tabelas finais e o resumo da sua equipe.

const W := 1280.0
const H := 720.0

var world: WorldChampionship
var _stage: Control


func _ready() -> void:
	world = Session.world
	if world == null:
		Session.go_to_title.call_deferred()
		return
	var team := GameData.team_by_id(GameData.teams(), world.player_team)
	var page := ScreenKit.garage_page(self, world.player_team)
	(page["backdrop"] as GarageBackdrop).set_glow(Color("#F5C542"))
	var layer: Control = page["layer"]
	_stage = Control.new()
	_stage.set_anchors_preset(Control.PRESET_CENTER)
	_stage.offset_left = -W / 2.0
	_stage.offset_right = W / 2.0
	_stage.offset_top = -H / 2.0
	_stage.offset_bottom = H / 2.0
	layer.add_child(_stage)
	var champs := world.champions()
	var title := UiStyle.g_label("Temporada %d encerrada" % world.season, 40, UiStyle.G_TEXT, "black")
	title.position = Vector2(40, 24)
	_stage.add_child(title)
	_stage.add_child(_champ_card(Rect2(40, 96, 600, 150), "Campeão de pilotos", String(champs["driver"]), int(champs["driver_points"]), true))
	_stage.add_child(_champ_card(Rect2(660, 96, 580, 150), "Campeão de construtores", String(champs["team"]), int(champs["team_points"]), false))
	_stage.add_child(_table(Rect2(40, 262, 600, 330), true))
	_stage.add_child(_table(Rect2(660, 262, 580, 330), false))
	_stage.add_child(_mine(Rect2(40, 606, 760, 84), team))
	var menu := ScreenKit.glass_pill_button("Menu", 120)
	menu.pressed.connect(Session.go_to_title)
	menu.position = Vector2(820, 618)
	menu.size = Vector2(120, 60)
	_stage.add_child(menu)
	var again := CutButton.new()
	again.text = "NOVA TEMPORADA"
	again.custom_minimum_size = Vector2(280, UiStyle.TOUCH_MAIN)
	again.size = again.custom_minimum_size
	again.position = Vector2(960, 620)
	again.pressed.connect(Session.reset_world)
	_stage.add_child(again)
	layer.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(layer, "modulate:a", 1.0, 0.2)


func _card(r: Rect2, fill := Color("#171a21")) -> PanelContainer:
	var c := PanelContainer.new()
	c.position = r.position
	c.custom_minimum_size = r.size
	c.size = r.size
	c.add_theme_stylebox_override("panel", UiStyle.g_box(fill, 22, 20, 14))
	return c


func _champ_card(r: Rect2, caption: String, id: String, pts: int, driver: bool) -> Control:
	var gold := Color("#F5C542")
	var c := _card(r, Color("#171a21").lerp(gold, 0.12))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	c.add_child(h)
	var team_id := world.team_of(id) if driver else id
	var team := GameData.team_by_id(GameData.teams(), team_id)
	if driver:
		var d := {}
		for dd: Dictionary in world.drivers():
			if dd["id"] == id:
				d = dd
		var av := DriverPhotos.make_avatar(d, Color(team["color"]), 96)
		av.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(av)
	else:
		var em := TeamEmblems.make_rect(team_id, 80)
		em.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(em)
	var v := VBoxContainer.new()
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.add_theme_constant_override("separation", 2)
	var badge := ScreenKit.badge(caption, gold, "trophy")
	badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(badge)
	var name_txt := String(team.get("name", id))
	if driver:
		for dd: Dictionary in world.drivers():
			if dd["id"] == id:
				name_txt = String(dd["name"])
	v.add_child(UiStyle.g_label(name_txt, 28, UiStyle.G_TEXT, "black"))
	v.add_child(UiStyle.g_label("%d pontos" % pts + (" · %d vitórias" % int(world.wins.get(id, 0)) if driver else ""), 15, UiStyle.G_TEXT_2, "bold"))
	h.add_child(v)
	return c


func _table(r: Rect2, drivers: bool) -> Control:
	var c := _card(r)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	c.add_child(v)
	v.add_child(UiStyle.g_caption("Pilotos" if drivers else "Construtores"))
	var rows: Array = world.driver_standings() if drivers else world.team_standings()
	for i in mini(9, rows.size()):
		var id := String(rows[i][0])
		var team_id := world.team_of(id) if drivers else id
		var mine := team_id == world.player_team
		var p := PanelContainer.new()
		var accent := UiStyle.team_accent(GameData.team_by_id(GameData.teams(), team_id))
		var st := UiStyle.g_box(Color(accent, 0.2) if mine else Color(1, 1, 1, 0.05), 10, 10, 0)
		p.add_theme_stylebox_override("panel", st)
		p.custom_minimum_size = Vector2(0, 28)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		var pl := UiStyle.g_label(str(i + 1), 14, UiStyle.G_TEXT_2, "black")
		pl.custom_minimum_size = Vector2(22, 0)
		h.add_child(pl)
		h.add_child(TeamEmblems.make_rect(team_id, 20))
		var label := String(GameData.team_by_id(GameData.teams(), id).get("name", id))
		if drivers:
			for d: Dictionary in world.drivers():
				if d["id"] == id:
					label = String(d["name"])
		h.add_child(UiStyle.g_label(label, 14, UiStyle.G_TEXT, "black"))
		h.add_child(UiStyle.hspacer())
		h.add_child(UiStyle.g_label(str(int(rows[i][1])), 14, UiStyle.G_TEXT, "black"))
		p.add_child(h)
		v.add_child(p)
	return c


func _mine(r: Rect2, team: Dictionary) -> Control:
	var c := _card(r, Color(UiStyle.team_accent(team), 0.18))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	c.add_child(h)
	h.add_child(TeamEmblems.make_rect(world.player_team, 44))
	var wins := 0
	var pods := 0
	var pol := 0
	for id: String in world.driver_ids_of(world.player_team):
		wins += int(world.wins.get(id, 0))
		pods += int(world.podiums.get(id, 0))
		pol += int(world.poles.get(id, 0))
	h.add_child(UiStyle.g_label("%s · %dº nos construtores" % [String(team.get("name", "")), world.team_position(world.player_team)], 20, UiStyle.G_TEXT, "black"))
	h.add_child(UiStyle.hspacer())
	for kv: Array in [["Vitórias", wins], ["Pódios", pods], ["Poles", pol]]:
		h.add_child(ScreenKit.stat(str(kv[1]), String(kv[0])))
	return c


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Session.go_to_title()
