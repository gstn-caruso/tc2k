extends SceneTree
## Imported geometry must keep its scale, front axle and independent wheel pivots.


func _initialize() -> void:
	_run.call_deferred()


func _bounds(visual: CarVisual) -> AABB:
	var bounds := AABB()
	var first := true
	for node in visual.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var transform := visual.global_transform.affine_inverse() * mesh.global_transform
		var box := transform * mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	return bounds


func _run() -> void:
	var setup := root.get_node("RaceSetup")
	for definition: Dictionary in setup.CARS:
		var scene := load(definition["scene"]) as PackedScene
		var visual := scene.instantiate() as CarVisual
		root.add_child(visual)
		assert(visual._wheel_meshes.size() == 4 and visual._front_wheels.size() == 2)
		var bounds := _bounds(visual)
		assert(bounds.position.y >= -0.02 and bounds.position.y < 0.05)
		assert(bounds.size.x > 1.8 and bounds.size.x < 2.3)
		assert(bounds.size.z > 4.0 and bounds.size.z < 4.7)
		assert(bounds.size.y > 1.2 and bounds.size.y < 1.6)
		for pivot in visual._front_wheels:
			assert(visual.to_local(pivot.global_position).z < -1.0)
		var wheel_positions: Array[Vector3] = []
		var wheel_bases: Array[Basis] = []
		var wheel_forward_axes: Array[Vector3] = []
		for wheel in visual._wheel_meshes:
			wheel_positions.append(wheel.global_position)
			wheel_bases.append(wheel.basis)
			wheel_forward_axes.append(wheel.get_parent().global_basis.inverse() * visual.global_basis * Vector3.FORWARD)
		visual.update_wheels(0.3, 0.25)
		for index in 4:
			var wheel := visual._wheel_meshes[index]
			assert(wheel.global_position.is_equal_approx(wheel_positions[index]))
			assert(not wheel.basis.is_equal_approx(wheel_bases[index]))
			var forward: Vector3 = visual.global_basis.inverse() * wheel.get_parent().global_basis * wheel_forward_axes[index]
			assert(forward.x > 0.1 if wheel.get_parent() in visual._front_wheels else absf(forward.x) < 0.001)
		visual.update_wheels(0.0, 0.0)
		for pivot in visual._front_wheels:
			assert(is_zero_approx(pivot.rotation.y))
		visual.free()
	print("Car tests passed: imported scale, ground contact, forward orientation, separate steering/rolling pivots and stationary rear steering.")
	quit()
