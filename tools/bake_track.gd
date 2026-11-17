extends SceneTree
## godot --headless --path . --script res://tools/bake_track.gd -- cabalen_3
func _initialize() -> void:
	_bake.call_deferred()


func _bake() -> void:
	var arguments := OS.get_cmdline_user_args()
	var track_id := arguments[0] if not arguments.is_empty() else "galvez_8"
	if track_id not in ["galvez_8", "cabalen_3"]:
		push_error("Unknown circuit: " + track_id)
		quit(1)
		return
	var track := CircuitTrack.new()
	track.name = "Galvez8" if track_id == "galvez_8" else "Cabalen3"
	if track_id == "cabalen_3":
		track.ground_color = Color("8e9763")
		track.shoulder_color = Color("c1aa7d")
		track.rail_color = Color("4c8752")
		track.foliage_color = Color("586a36")
	var path := Path3D.new()
	path.name = "Centerline"
	path.curve = load("res://assets/tracks/" + track_id + "/centerline.tres")
	track.add_child(path)
	path.owner = track
	root.add_child(track)
	track.rebuild()
	var scene := PackedScene.new()
	assert(scene.pack(track) == OK)
	assert(ResourceSaver.save(scene, "res://scenes/race/" + track_id + ".tscn") == OK)
	print("Baked ", track_id, ": ", path.curve.get_baked_length(), " m")
	quit()
