class_name ArcadeCar
extends CharacterBody3D

@export var tuning: CarTuning = CarTuning.new()
var model_scene: PackedScene = preload("res://scenes/cars/renault_fuego.tscn")
var model_id := "renault_fuego"
var track: CircuitTrack
var driving_enabled := false
var steering := 0.0
var speed := 0.0
var on_asphalt := true
var _visual: CarVisual


func _ready() -> void:
	floor_snap_length = 1.5
	floor_stop_on_slope = true
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.75, 1.1, 4.0)
	shape.shape = box
	shape.position.y = 0.55
	add_child(shape)
	_visual = model_scene.instantiate() as CarVisual
	add_child(_visual)


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
	_visual.update_wheels(steering * steering_angle, speed * delta)


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
		_visual.update_wheels(0.0, 0.0)
