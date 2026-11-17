class_name ArcadeCar
extends CharacterBody3D

@export var tuning: CarTuning = CarTuning.new()
var track: CircuitTrack
var driving_enabled := false
var steering := 0.0
var speed := 0.0
var on_asphalt := true
var _visual: Node3D
var _wheels: Array[MeshInstance3D] = []


func _ready() -> void:
	floor_snap_length = 1.5
	floor_stop_on_slope = true
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.75, 1.1, 4.0)
	shape.shape = box
	shape.position.y = 0.55
	add_child(shape)
	_build_model()


func _physics_process(delta: float) -> void:
	if not driving_enabled:
		return
	var throttle := Input.get_action_strength("drive_accelerate")
	var brake := Input.get_action_strength("drive_brake")
	var turn := Input.get_axis("drive_left", "drive_right")
	steering = move_toward(steering, turn, (tuning.steering_return if is_zero_approx(turn) else tuning.steering_rate) * delta)
	on_asphalt = track.is_on_road(global_position) if track else true
	var forward := -global_basis.z
	var longitudinal := maxf(0.0, velocity.dot(forward))
	var maximum := tuning.top_speed if on_asphalt else tuning.grass_top_speed
	if brake > 0.0:
		longitudinal = move_toward(longitudinal, 0.0, tuning.braking * brake * delta)
	elif throttle > 0.0:
		if longitudinal < maximum:
			longitudinal = minf(maximum, longitudinal + tuning.acceleration * throttle * (1.0 - 0.55 * longitudinal / tuning.top_speed) * delta)
	else:
		longitudinal = move_toward(longitudinal, 0.0, (0.7 + longitudinal * 0.022) * delta)
	if longitudinal > maximum:
		longitudinal = move_toward(longitudinal, maximum, tuning.grass_deceleration * delta)
	longitudinal = minf(longitudinal, tuning.top_speed)
	var grip := tuning.grip if on_asphalt else tuning.grass_grip
	var steering_angle := lerpf(0.5, 0.11, clampf(longitudinal / tuning.top_speed, 0, 1))
	var yaw := longitudinal / tuning.wheelbase * tan(steering * steering_angle)
	yaw = clampf(yaw, -grip / maxf(longitudinal, 1), grip / maxf(longitudinal, 1))
	rotate_y(-yaw * delta)
	forward = -global_basis.z
	var horizontal := Vector3(velocity.x, 0, velocity.z)
	var lateral := horizontal - forward * horizontal.dot(forward)
	horizontal = forward * longitudinal + lateral * exp(-grip * 0.7 * delta)
	velocity = Vector3(horizontal.x, velocity.y - 24.0 * delta, horizontal.z)
	if is_on_floor():
		velocity.y = -0.5
	move_and_slide()
	for i in get_slide_collision_count():
		var hit := get_slide_collision(i)
		if absf(hit.get_normal().y) < 0.5:
			velocity *= 0.65
	speed = Vector2(velocity.x, velocity.z).length()
	if is_on_floor():
		var normal := global_basis.inverse() * get_floor_normal()
		_visual.rotation.x = lerpf(_visual.rotation.x, atan2(normal.z, normal.y), 1.0 - exp(-8 * delta))
	_visual.rotation.z = lerpf(_visual.rotation.z, -steering * minf(speed / 250, 0.055), 1.0 - exp(-8 * delta))
	for wheel in _wheels:
		if wheel.position.z < 0.0:
			wheel.rotation.y = -steering * steering_angle


func reset_to(pose: Transform3D) -> void:
	# Steering stays around world up; only the bodywork pitches with the floor.
	var heading := -pose.basis.z
	heading.y = 0.0
	global_transform = Transform3D(Basis.looking_at(heading.normalized(), Vector3.UP), pose.origin)
	global_position.y += 0.08
	velocity = Vector3.ZERO
	steering = 0.0
	speed = 0.0
	if _visual:
		_visual.rotation.x = 0.0
		_visual.rotation.z = 0.0


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	return material


func _box(parent: Node3D, dimensions: Vector3, location: Vector3, material: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	part.mesh = mesh
	part.material_override = material
	part.position = location
	parent.add_child(part)
	return part


func _build_model() -> void:
	_visual = Node3D.new()
	_visual.name = "Bodywork"
	add_child(_visual)
	var blue := _material(Color("2676c7"))
	var white := _material(Color("f4ead3"))
	var glass := _material(Color("203546"))
	var rubber := _material(Color("171e25"))
	var metal := _material(Color("b6c4c5"))
	_box(_visual, Vector3(1.85, 0.52, 4.2), Vector3(0, 0.6, 0), blue)
	_box(_visual, Vector3(1.9, 0.16, 4.25), Vector3(0, 0.38, 0), white)
	_box(_visual, Vector3(1.58, 0.56, 1.85), Vector3(0, 1.12, 0.15), glass)
	_box(_visual, Vector3(1.62, 0.09, 1.45), Vector3(0, 1.43, 0.3), white)
	_box(_visual, Vector3(0.35, 0.035, 1.2), Vector3(0, 0.88, -1.4), white)
	_box(_visual, Vector3(1.98, 0.12, 0.35), Vector3(0, 1.04, 1.9), blue)
	for side in [-1.0, 1.0]:
		_box(_visual, Vector3(0.05, 0.44, 0.63), Vector3(side * 0.945, 0.68, 0.15), white)
		_box(_visual, Vector3(0.11, 0.22, 0.45), Vector3(side * 0.81, 1.02, -0.5), blue)
		_box(_visual, Vector3(0.51, 0.18, 0.04), Vector3(side * 0.57, 0.68, -2.12), white)
		_box(_visual, Vector3(0.57, 0.17, 0.04), Vector3(side * 0.56, 0.65, 2.13), _material(Color("c63329")))
		for axle in [-1.3, 1.35]:
			var wheel := MeshInstance3D.new()
			var tyre := CylinderMesh.new()
			tyre.top_radius = 0.36
			tyre.bottom_radius = 0.36
			tyre.height = 0.28
			tyre.radial_segments = 8
			wheel.mesh = tyre
			wheel.material_override = rubber
			wheel.position = Vector3(side * 0.94, 0.36, axle)
			wheel.rotation.z = PI / 2
			_visual.add_child(wheel)
			_wheels.append(wheel)
			var hub := MeshInstance3D.new()
			var hub_mesh := CylinderMesh.new()
			hub_mesh.top_radius = 0.2
			hub_mesh.bottom_radius = 0.2
			hub_mesh.height = 0.29
			hub_mesh.radial_segments = 6
			hub.mesh = hub_mesh
			hub.material_override = metal
			wheel.add_child(hub)
