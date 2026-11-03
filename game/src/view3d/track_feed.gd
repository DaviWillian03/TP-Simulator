class_name TrackFeed
extends RefCounted
## Adaptador entre uma simulação e a pista 3D: a vista só pergunta "quais carros, onde estão, qual o
## clima" e não precisa saber se é a corrida (RaceSim) ou a classificação (QualiSim).

var track: TrackModel
var cars: Array[CarState]
var weather: WeatherModel
var _race: RaceSim
var _quali: QualiSim


static func of_race(sim: RaceSim) -> TrackFeed:
	var f := TrackFeed.new()
	f._race = sim
	f.track = sim.track
	f.cars = sim.cars
	f.weather = sim.weather
	return f


static func of_quali(q: QualiSim) -> TrackFeed:
	var f := TrackFeed.new()
	f._quali = q
	f.track = q.track
	f.cars = q.cars
	f.weather = q.weather
	return f


func standings() -> Array[CarState]:
	return _race.standings() if _race != null else _quali.standings()


## Distância (m) em que o carro deve ser desenhado; na corrida pode ser negativa (grid).
func render_distance(car: CarState) -> float:
	return _race.render_distance(car) if _race != null else _quali.render_distance(car)


func marker_visible(car: CarState) -> bool:
	return not car.retired if _race != null else _quali.marker_visible(car)


func safety_car_out() -> bool:
	return _race != null and _race.control.flag == RaceControl.Flag.SC
