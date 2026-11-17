extends SceneTree
## godot --headless --path . --script res://tools/bake_track.gd -- cabalen_3
func _initialize() -> void:
	_bake.call_deferred()


func _bake() -> void:
	var arguments := OS.get_cmdline_user_args()
	var track_id := arguments[0] if not arguments.is_empty() else "galvez_8"
	if track_id not in ["galvez_8", "cabalen_3", "el_zonda"]:
		push_error("Unknown circuit: " + track_id)
		quit(1)
		return
	var track := CircuitTrack.new()
	track.name = {"galvez_8": "Galvez8", "cabalen_3": "Cabalen3", "el_zonda": "ElZonda"}[track_id]
	if track_id == "cabalen_3":
		track.ground_color = Color("8e9763")
		track.shoulder_color = Color("c1aa7d")
		track.rail_color = Color("4c8752")
		track.foliage_color = Color("586a36")
	elif track_id == "el_zonda":
		track.ground_color = Color("bba078")
		track.shoulder_color = Color("ceb186")
		track.rail_color = Color("a85d45")
		track.foliage_color = Color("7b8053")
		track.terrain_rise = 24.0
		track.rail_offset = 13.0
		track.vegetation_count = 55
		track.vegetation_scale = 0.4
	var path := Path3D.new()
	path.name = "Centerline"
	path.curve = load("res://assets/tracks/" + track_id + "/centerline.tres")
	if track_id == "el_zonda":
		track.bridge_distance = path.curve.get_closest_offset(path.curve.get_point_position(36)) + 12.0
	track.add_child(path)
	path.owner = track
	root.add_child(track)
	track.rebuild()
	var scene := PackedScene.new()
	assert(scene.pack(track) == OK)
	assert(ResourceSaver.save(scene, "res://scenes/race/" + track_id + ".tscn") == OK)
	print("Baked ", track_id, ": ", path.curve.get_baked_length(), " m")
	quit()
