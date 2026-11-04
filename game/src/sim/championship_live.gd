class_name ChampionshipLive
extends RefCounted
## Campeonato ao vivo durante a corrida da campanha (pedido #1 do usuário; mockups v17 aprovados, 2026-11-04):
## "se terminar assim" — soma os pontos da posição atual de cada carro aos pontos de antes da corrida, para pilotos e
## construtores, e diz se o título fica decidido (vantagem maior do que os pontos que ainda restam). Sem tela.

var driver_points: Dictionary = {}  ## antes desta corrida
var team_points: Dictionary = {}
var team_of: Dictionary = {}  ## id do piloto -> id da equipe
var table: Array = RaceSim.RACE_POINTS  ## tabela desta corrida (corrida ou sprint)
var races_left := 0  ## corridas principais que ainda restam DEPOIS desta
var sprints_left := 0
var race_top := 25
var sprint_top := 8


func setup(p_driver_points: Dictionary, p_team_points: Dictionary, p_team_of: Dictionary, p_table: Array, p_races_left: int,
		p_sprints_left: int, race_table: Array = RaceSim.RACE_POINTS, sprint_table: Array = RaceSim.SPRINT_POINTS) -> void:
	driver_points = p_driver_points.duplicate()
	team_points = p_team_points.duplicate()
	team_of = p_team_of
	table = p_table
	races_left = p_races_left
	sprints_left = p_sprints_left
	race_top = int(race_table[0]) if not race_table.is_empty() else 25
	sprint_top = int(sprint_table[0]) if not sprint_table.is_empty() else 8


## Projeção para a ordem atual (ids, do 1º ao último; `out` = ids fora da corrida, que não pontuam).
## {drivers: [[id, antes, depois], ...] ordenado por "depois"; teams: idem}
func project(order: Array, out: Dictionary = {}) -> Dictionary:
	var d_after := driver_points.duplicate()
	var t_after := team_points.duplicate()
	for id: String in team_of:
		if not d_after.has(id):
			d_after[id] = 0
	for i in order.size():
		var id: String = order[i]
		var pts := int(table[i]) if i < table.size() and not out.has(id) else 0
		d_after[id] = int(d_after.get(id, 0)) + pts
		var tid := String(team_of.get(id, ""))
		if tid != "":
			t_after[tid] = int(t_after.get(tid, 0)) + pts
	return {"drivers": _rows(driver_points, d_after), "teams": _rows(team_points, t_after)}


func _rows(before: Dictionary, after: Dictionary) -> Array:
	var rows: Array = []
	for id: String in after:
		rows.append([id, int(before.get(id, 0)), int(after[id])])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[2] > b[2] if a[2] != b[2] else a[1] > b[1])
	return rows


## Pontos que ainda estarão em disputa depois desta corrida (por piloto).
func max_remaining() -> int:
	return races_left * race_top + sprints_left * sprint_top


## Ordem (ids) dos n primeiros de antes da corrida.
func before_order(kind: String, n: int) -> Array:
	var src := driver_points if kind == "drivers" else team_points
	var rows := _rows(src, src)
	return rows.slice(0, n).map(func(r: Array) -> String: return r[0])


## Título decidido "se terminar assim"? {id, lead, left} ou {}. Construtores: dois carros por equipe (o dobro).
func clinch(rows: Array, kind: String = "drivers") -> Dictionary:
	if rows.size() < 2:
		return {}
	var left := max_remaining() * (2 if kind == "teams" else 1)
	var lead: int = int(rows[0][2]) - int(rows[1][2])
	if lead > left:
		return {"id": rows[0][0], "lead": lead, "left": left, "rival": rows[1][0]}
	return {}
