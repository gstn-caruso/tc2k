extends SceneTree
## godot --headless --path . --script res://tools/bake_track.gd
func _initialize() -> void:
	_bake.call_deferred()


func _bake() -> void:
	var track := CircuitTrack.new()
	track.name = "Galvez8"
	var path := Path3D.new()
	path.name = "Centerline"
	path.curve = load("res://assets/tracks/galvez_8/centerline.tres")
	track.add_child(path)
	path.owner = track
	root.add_child(track)
	track.rebuild()
	var scene := PackedScene.new()
	assert(scene.pack(track) == OK)
	assert(ResourceSaver.save(scene, "res://scenes/race/galvez_8.tscn") == OK)
	print("Baked Gálvez 8: ", path.curve.get_baked_length(), " m, ", track.gate_distances.size(), " ordered gates")
	quit()
