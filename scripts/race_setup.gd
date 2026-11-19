extends Node
## Stable circuit, car and mode IDs are independent from translated interface text.

signal track_confirmed(track_id: String)
signal car_confirmed(car_id: String)
signal mode_confirmed(mode_id: String)

const MODES: Array[Dictionary] = [
	{"id": "practice", "name": "MODE_PRACTICE", "description": "PRACTICE_DESCRIPTION", "rules": "PRACTICE_RULES"},
	{"id": "competition", "name": "MODE_COMPETITION", "description": "COMPETITION_DESCRIPTION", "rules": "COMPETITION_RULES"},
]

const CARS: Array[Dictionary] = [
	{
		"id": "renault_fuego", "name": "Renault Fuego", "description": "FUEGO_LIVERY",
		"scene": "res://scenes/cars/renault_fuego.tscn", "color": Color("efb21d"),
	},
	{
		"id": "ford_sierra_xr4", "name": "Ford Sierra XR4", "description": "SIERRA_LIVERY",
		"scene": "res://scenes/cars/ford_sierra_xr4.tscn", "color": Color("ce271e"),
	},
	{
		"id": "volkswagen_gol", "name": "Volkswagen Gol", "description": "GOL_LIVERY",
		"scene": "res://scenes/cars/volkswagen_gol.tscn", "color": Color("2455b1"),
	},
	{
		"id": "peugeot_405", "name": "Peugeot 405", "description": "PEUGEOT_LIVERY",
		"scene": "res://scenes/cars/peugeot_405.tscn", "color": Color("f0f0e5"),
	},
	{
		"id": "honda_civic", "name": "Honda Civic Coupé", "description": "CIVIC_LIVERY",
		"scene": "res://scenes/cars/honda_civic.tscn", "color": Color("30343e"),
	},
	{
		"id": "chevrolet_astra", "name": "Chevrolet Astra", "description": "ASTRA_LIVERY",
		"scene": "res://scenes/cars/chevrolet_astra.tscn", "color": Color("173e91"),
	},
]

const TRACKS: Array[Dictionary] = [
	{
		"id": "galvez_8", "name": "Oscar y Juan Gálvez", "city": "Buenos Aires",
		"scene": "res://scenes/race/galvez_8.tscn", "hud_name": "GÁLVEZ",
		"variant": "CIRCUIT_8", "difficulty": "DIFFICULTY_LOW", "color": Color("245dcc"),
		"map": "res://assets/tracks/galvez_8.svg", "terrain": Color("569b58"),
	},
	{
		"id": "cabalen_3", "name": "Oscar Cabalén", "city": "Córdoba",
		"scene": "res://scenes/race/cabalen_3.tscn", "hud_name": "OSCAR CABALÉN",
		"variant": "CIRCUIT_3", "difficulty": "DIFFICULTY_MEDIUM", "color": Color("338735"),
		"map": "res://assets/tracks/cabalen_3.svg", "terrain": Color("a88d62"),
	},
	{
		"id": "el_zonda", "name": "El Zonda", "city": "San Juan",
		"scene": "res://scenes/race/el_zonda.tscn", "hud_name": "EL ZONDA",
		"variant": "EDUARDO_COPELLO", "difficulty": "DIFFICULTY_HIGH", "color": Color("bd3329"),
		"map": "res://assets/tracks/el_zonda.svg", "terrain": Color("bb9d76"),
	},
]

var selected_index := 0
var selected_car_index := 0
var selected_mode_index := 0
var confirmed := false


func select_track(index: int) -> void:
	selected_index = wrapi(index, 0, TRACKS.size())
	confirmed = false


func confirm_track() -> void:
	confirmed = true
	track_confirmed.emit(TRACKS[selected_index]["id"])


func select_car(index: int) -> void:
	selected_car_index = wrapi(index, 0, CARS.size())


func confirm_car() -> void:
	car_confirmed.emit(CARS[selected_car_index]["id"])


func select_mode(index: int) -> void:
	selected_mode_index = wrapi(index, 0, MODES.size())


func confirm_mode() -> void:
	mode_confirmed.emit(MODES[selected_mode_index]["id"])
