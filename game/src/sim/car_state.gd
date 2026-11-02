class_name CarState
extends RefCounted
## Estado de um carro durante a corrida. Só dados: quem decide e movimenta é a RaceSim.

enum PaceMode { CONSERVE, NORMAL, ATTACK }
enum EnergyMode { HARVEST, BALANCED, DEPLOY }
enum TeamOrder { FREE, HOLD, LET_BY }  ## liberado · não brigar · deixar o companheiro passar

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
var lap_times := PackedFloat32Array()  ## histórico de tempos de volta (menu DADOS)
var lap_noise := 0.0  ## variação aleatória do ritmo nesta volta
var setup_penalty_s := 0.0  ## tempo perdido por volta pelo acerto (CarSetup)
var wear_factor := 1.0  ## multiplicador de desgaste (simulação de corrida nos treinos)

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

# ordens de equipe e rádio
var team_order := TeamOrder.FREE
var defend_hard := false  ## resposta "defender forte" no rádio: mais difícil passar, mais risco
var confidence := 0  ## +1 confiante / -1 irritado (efeito no ritmo por algumas voltas)
var confidence_until_lap := 0

# incidentes, danos e punições
var stall_s := 0.0  ## rodou/saiu da pista: parado ou fora do traçado por alguns segundos
var damage_wing := 0.0  ## 0..1 (reparável no box trocando a asa)
var damage_floor := 0.0  ## 0..1 (não reparável)
var repair_wing := false  ## trocar a asa na próxima parada
var penalty_pending_s := 0.0  ## punição de tempo ainda não cumprida
var penalties_total_s := 0.0
var drive_through := false
var license_points := 0
var retired := false
var retire_reason := ""

# final
var finished := false
var finish_time := 0.0
var disqualified := false


## Tempo que vale para a classificação: chegada + punições não cumpridas.
func classified_time() -> float:
	return finish_time + penalty_pending_s


## Fora da disputa por posição neste momento (no box ou fora do traçado).
func lane() -> int:
	if in_pit:
		return 1
	if stall_s > 0.0:
		return 2
	return 0


func code() -> String:
	return driver["code"]


func display_name() -> String:
	return driver["name"]


func team_color() -> Color:
	return Color(team["color"])


func team_color2() -> Color:
	return Color(team["color2"])
