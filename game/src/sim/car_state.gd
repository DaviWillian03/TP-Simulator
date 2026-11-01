class_name CarState
extends RefCounted
## Estado de um carro durante a corrida. Só dados: quem decide e movimenta é a RaceSim.

enum PaceMode { CONSERVE, NORMAL, ATTACK }
enum EnergyMode { HARVEST, BALANCED, DEPLOY }

var index := 0
var driver: Dictionary = {}
var team: Dictionary = {}
var is_player := false
var grid_position := 0

# posição na corrida
var distance := 0.0  ## metros percorridos desde a linha (negativo no grid de largada)
var speed := 0.0  ## m/s no passo atual
var gap_ahead_s := -1.0  ## segundos até o carro à frente na mesma faixa (-1 = ninguém)
var laps_done := 0
var lap_start_time := 0.0
var last_lap_time := 0.0
var best_lap_time := INF
var lap_noise := 0.0  ## variação aleatória do ritmo nesta volta

# pneus e energia
var tyre := "medium"
var tyre_wear := 0.0  ## 0 = novo, 1 = totalmente gasto
var tyre_laps := 0
var compounds_used: Array[String] = []
var battery := 0.6  ## carga da bateria (0..1)

# ordens (definidas pelo jogador nos carros dele; pela IA nos demais)
var pace_mode := PaceMode.NORMAL
var energy_mode := EnergyMode.BALANCED

# pit stop
var pit_requested := false
var pit_compound := "hard"
var in_pit := false
var pit_speed := 0.0
var pit_service_done := false
var pit_stationary_s := 2.4
var pit_stops := 0
var ai_pit_wear := 0.7  ## desgaste em que a IA decide parar (varia por carro)

# final
var finished := false
var finish_time := 0.0
var disqualified := false


func code() -> String:
	return driver["code"]


func display_name() -> String:
	return driver["name"]


func team_color() -> Color:
	return Color(team["color"])


func team_color2() -> Color:
	return Color(team["color2"])
