extends Node
## Stable circuit IDs are independent from translated interface text.

signal track_confirmed(track_id: String)

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
var confirmed := false


func select_track(index: int) -> void:
	selected_index = wrapi(index, 0, TRACKS.size())
	confirmed = false


func confirm_track() -> void:
	confirmed = true
	track_confirmed.emit(TRACKS[selected_index]["id"])
