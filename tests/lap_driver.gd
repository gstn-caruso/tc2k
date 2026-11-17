extends RefCounted
## Test inputs only: the production car never follows the route automatically.

static func drive(tree: SceneTree, race: RaceController, grass_excursion := false) -> Dictionary:
	var car := race.car
	var result := {"frames": 0, "max_error": 0.0, "grass_ticks": 0, "grounded_ticks": 0}
	while race.state == RaceController.State.RACING and result.frames < 24000:
		var offset := race.track.nearest_distance(car.global_position)
		var grass_offset := 11.0 * smoothstep(20, 100, offset) * (1.0 - smoothstep(200, 300, offset)) if grass_excursion else 0.0
		var target := race.track.frame_at(offset + maxf(9, car.speed * 0.42)) * Vector3(grass_offset, 0, 0)
		var wanted := Vector3(target.x - car.global_position.x, 0, target.z - car.global_position.z).normalized()
		var forward := -car.global_basis.z
		forward.y = 0.0
		var angle := forward.normalized().signed_angle_to(wanted, Vector3.UP)
		var turn := clampf(-angle * 3, -1, 1)
		Input.action_press("drive_left", maxf(-turn, 0))
		Input.action_press("drive_right", maxf(turn, 0))
		var curvature := 0.001
		for sample in [0.0, 20.0, 40.0, 65.0]:
			var here := -race.track.frame_at(offset + sample).basis.z
			var ahead := -race.track.frame_at(offset + sample + 20).basis.z
			here.y = 0.0
			ahead.y = 0.0
			curvature = maxf(curvature, absf(here.normalized().signed_angle_to(ahead.normalized(), Vector3.UP)) / 20)
		var target_speed := clampf(sqrt(6.0 / curvature), 10, 44)
		if grass_excursion and offset < 340:
			target_speed = minf(target_speed, 26.0)
		Input.action_press("drive_accelerate", 1.0 if car.speed < target_speed else 0.0)
		Input.action_press("drive_brake", 1.0 if car.speed > target_speed + 1.0 else 0.0)
		var nearest := race.track.path.curve.get_closest_point(car.global_position)
		result.max_error = maxf(result.max_error, Vector2(nearest.x - car.global_position.x, nearest.z - car.global_position.z).length())
		if not car.on_asphalt:
			result.grass_ticks += 1
		if car.is_on_floor():
			result.grounded_ticks += 1
		await tree.physics_frame
		result.frames += 1
	for action in ["drive_left", "drive_right", "drive_accelerate", "drive_brake"]:
		Input.action_release(action)
	await tree.process_frame
	print(race.track_id, " physical lap: ", result, "; time=", race.lap.elapsed, "; progress=", race.lap.progress)
	return result
