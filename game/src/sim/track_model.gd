class_name TrackModel
extends RefCounted
## Circuito: dados de corrida (voltas, box, ultrapassagem) e o traçado em metros.
## "frac" = posição ao longo da volta, de 0 (linha de chegada) a 1, no sentido de corrida.

var id := ""
var name := ""
var short_name := ""
var grand_prix := ""
var country_code := ""  ## ISO de 2 letras (bandeira do país na interface)
var length_m := 0.0
var laps := 0
var base_lap_time_s := 0.0
var pit_lane_loss_s := 0.0
var pit_entry_frac := 0.0
var pit_box_frac := 0.0
var pit_exit_frac := 0.0
var tyre_wear_factor := 1.0
var overtaking_difficulty := 0.5
var overtaking_zones: Array = []
var rain_probability := 0.0
var points := PackedVector2Array()
var elevation: Array = []  ## [[fração, metros], ...] (aproximado); vazio = plana
var night := false
var scenery: Dictionary = {}

var _cum := PackedFloat64Array()  # distância acumulada até cada ponto do traçado
var _poly_length := 0.0


func _init(d: Dictionary) -> void:
	id = d["id"]
	name = d["name"]
	short_name = d["short_name"]
	grand_prix = d["grand_prix"]
	country_code = String(d.get("country_code", ""))
	length_m = float(d["length_m"])
	laps = int(d["laps"])
	base_lap_time_s = float(d["base_lap_time_s"])
	pit_lane_loss_s = float(d["pit_lane_loss_s"])
	pit_entry_frac = float(d["pit_entry_frac"])
	pit_box_frac = float(d["pit_box_frac"])
	pit_exit_frac = float(d["pit_exit_frac"])
	tyre_wear_factor = float(d["tyre_wear_factor"])
	overtaking_difficulty = float(d["overtaking_difficulty"])
	overtaking_zones = d["overtaking_zones"]
	rain_probability = float(d.get("rain_probability", 0.0))
	elevation = d.get("elevation", [])
	night = bool(d.get("night", false))
	scenery = d.get("scenery", {"theme": "park", "landmark": ""})
	for p: Array in d["points"]:
		points.append(Vector2(float(p[0]), float(p[1])))
	_build_lengths()


func _build_lengths() -> void:
	_cum.resize(points.size() + 1)
	_cum[0] = 0.0
	for i in points.size():
		_cum[i + 1] = _cum[i] + points[i].distance_to(points[(i + 1) % points.size()])
	_poly_length = _cum[points.size()]


## Comprimento do trecho do pit lane (da entrada à saída), em metros.
func pit_lane_length_m() -> float:
	return (1.0 - pit_entry_frac + pit_exit_frac) * length_m


## Ponto do traçado (em metros) correspondente à fração da volta.
func position_at(frac: float) -> Vector2:
	var d := fposmod(frac, 1.0) * _poly_length
	var i := clampi(_cum.bsearch(d, false) - 1, 0, points.size() - 1)
	var seg := _cum[i + 1] - _cum[i]
	var t := 0.0 if seg <= 0.0 else (d - _cum[i]) / seg
	return points[i].lerp(points[(i + 1) % points.size()], t)


## Direção do traçado (vetor unitário) na fração dada.
func direction_at(frac: float) -> Vector2:
	var a := position_at(frac - 0.002)
	var b := position_at(frac + 0.002)
	return (b - a).normalized()


## Altura (metros) do traçado na fração dada, interpolando o perfil de relevo.
func height_at(frac: float) -> float:
	if elevation.size() < 2:
		return 0.0
	var f := fposmod(frac, 1.0)
	for i in range(1, elevation.size()):
		var a: Array = elevation[i - 1]
		var b: Array = elevation[i]
		if f <= float(b[0]):
			var t := (f - float(a[0])) / maxf(float(b[0]) - float(a[0]), 0.0001)
			return lerpf(float(a[1]), float(b[1]), smoothstep(0.0, 1.0, t))
	return float(elevation[elevation.size() - 1][1])


func bounds() -> Rect2:
	var r := Rect2(points[0], Vector2.ZERO)
	for p in points:
		r = r.expand(p)
	return r
