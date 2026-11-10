class_name SaveSlots
extends RefCounted
## Três slots de save (mockup v32-4). Cada slot guarda UMA coisa: uma Campanha (campaign.json) ou um Campeonato Mundial
## (world.json). Os arquivos têm `save_version`: save mais novo que o jogo é recusado (não corrompe), e o antigo
## (user://campaign.json / world_championship.json, sem slots) entra sozinho no slot 1.

const SLOTS := 3
const VERSION := 2  ## 1 = antes dos slots (sem campo); 2 = com `save_version`

static var current := 1  ## slot em uso nesta sessão


static func dir(slot: int = 0) -> String:
	return "user://saves/slot%d/" % (slot if slot > 0 else current)


static func campaign_path(slot: int = 0) -> String:
	return dir(slot) + "campaign.json"


static func world_path(slot: int = 0) -> String:
	return dir(slot) + "world.json"


## Garante a pasta do slot antes de gravar.
static func ensure(slot: int = 0) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir(slot)))


## O dicionário do save pode ser lido por esta versão do jogo? (versão ausente = 1, antigo mas compatível)
static func compatible(d: Dictionary) -> bool:
	return int(d.get("save_version", 1)) <= VERSION


## Move os saves de antes dos slots para o slot 1 (só se o slot 1 estiver livre).
static func migrate_legacy() -> void:
	var moves := [["user://campaign.json", campaign_path(1)], ["user://world_championship.json", world_path(1)]]
	for m: Array in moves:
		if FileAccess.file_exists(m[0]) and not FileAccess.file_exists(campaign_path(1)) and not FileAccess.file_exists(world_path(1)):
			ensure(1)
			DirAccess.copy_absolute(ProjectSettings.globalize_path(m[0]), ProjectSettings.globalize_path(m[1]))
			DirAccess.remove_absolute(ProjectSettings.globalize_path(m[0]))


## Slot salvo mais recentemente com esse tipo ("campaign" ou "world"); 0 se não houver.
static func latest(kind: String) -> int:
	var best := 0
	var best_t := 0
	for s in range(1, SLOTS + 1):
		var path := campaign_path(s) if kind == "campaign" else world_path(s)
		if FileAccess.file_exists(path):
			var t := FileAccess.get_modified_time(path)
			if t >= best_t:
				best_t = t
				best = s
	return best


# --- fim de semana em andamento (salvamento automático entre as sessões) ---------------------------------------------

const WEEKEND_VERSION := 1


## Caminho do save do fim de semana: por slot (Campanha/Mundial) ou o do Grande Prêmio avulso (kind "gp").
static func weekend_path(kind: String, slot: int = 0) -> String:
	return "user://saves/gp_weekend.sav" if kind == "gp" else dir(slot) + "weekend.sav"


## Grava (escreve num arquivo temporário e troca, para um travamento no meio não deixar o save pela metade).
static func save_weekend(w: WeekendSim, kind: String, ctx_round: int = 0) -> bool:
	if kind != "gp":
		ensure()
	else:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves/"))
	var path := weekend_path(kind)
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_var({"version": WEEKEND_VERSION, "kind": kind, "ctx_round": ctx_round, "data": w.to_save()}, false)
	f.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path))
	return true


## Fim de semana salvo, ou null (sem arquivo, versão desconhecida, de outro tipo ou de outra rodada).
static func load_weekend(kind: String, ctx_round: int = 0) -> WeekendSim:
	var path := weekend_path(kind)
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var d: Variant = f.get_var(false)
	f.close()
	if not d is Dictionary or int(d.get("version", 0)) > WEEKEND_VERSION or String(d.get("kind", "")) != kind:
		return null
	if kind != "gp" and int(d.get("ctx_round", -1)) != ctx_round:  # o campeonato já passou desta rodada: save velho
		delete_weekend(kind)
		return null
	return WeekendSim.from_save(d["data"])


static func has_weekend(kind: String, slot: int = 0) -> bool:
	return FileAccess.file_exists(weekend_path(kind, slot))


static func delete_weekend(kind: String, slot: int = 0) -> void:
	var p := weekend_path(kind, slot)
	if FileAccess.file_exists(p):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


static func has_campaign(slot: int) -> bool:
	return FileAccess.file_exists(campaign_path(slot))


static func has_world(slot: int) -> bool:
	return FileAccess.file_exists(world_path(slot))


static func is_empty(slot: int) -> bool:
	return not has_campaign(slot) and not has_world(slot)


static func first_free() -> int:
	for s in range(1, SLOTS + 1):
		if is_empty(s):
			return s
	return 0


static func delete(slot: int) -> void:
	for p: String in [campaign_path(slot), world_path(slot), weekend_path("campaign", slot)]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


## Resumo de um slot para o cartão: {kind: "campaign"|"world"|"", team, line, chips: [..], saved: "texto"}.
static func summary(slot: int) -> Dictionary:
	if has_world(slot):
		var w := WorldChampionship.load_saved(world_path(slot))
		if w != null:
			return {"kind": "world", "team": w.player_team, "title": String(GameData.team_by_id(GameData.teams(), w.player_team).get("name", "")),
				"line": "MUNDIAL F1 · RD %d/%d" % [mini(w.round + 1, 22), 22],
				"chips": ["%dº" % w.team_position(w.player_team), "%d PTS" % int(w.team_points.get(w.player_team, 0))],
				"saved": _stamp(world_path(slot))}
	if has_campaign(slot):
		var c := Campaign.load_saved(campaign_path(slot))
		if c != null:
			return {"kind": "campaign", "team": c.player_team, "title": String(c.team().get("name", "")),
				"line": "CAMPANHA · RD %d/%d" % [mini(c.round + 1, Campaign.calendar().size()), Campaign.calendar().size()],
				"chips": ["%dº" % c.team_position(c.player_team), "US$ %d MI" % roundi(c.budget_musd)],
				"saved": _stamp(campaign_path(slot))}
	return {"kind": ""}


static func _stamp(path: String) -> String:
	var t := FileAccess.get_modified_time(path)
	if t <= 0:
		return ""
	var d := Time.get_datetime_dict_from_unix_time(t)
	return "salvo em %02d/%02d às %02d:%02d" % [d["day"], d["month"], d["hour"], d["minute"]]
