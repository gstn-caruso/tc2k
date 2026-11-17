extends SceneTree
## Each available circuit must be drivable, correctly labelled and independent.

const LapDriver = preload("res://tests/lap_driver.gd")

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var setup := root.get_node("RaceSetup")
	var records := ConfigFile.new()
	records.set_value("galvez_8", "best_lap", 123.456)
	assert(records.save(RaceController.RECORDS_PATH) == OK)
	for index in range(1, setup.TRACKS.size()):
		var definition: Dictionary = setup.TRACKS[index]
		if definition["scene"].is_empty():
			continue
		setup.select_track(index)
		assert(change_scene_to_file("res://scenes/race/race.tscn") == OK)
		await process_frame
		await process_frame
		var race := current_scene as RaceController
		assert(race.track_id == definition["id"] and race.track.scene_file_path == definition["scene"])
		assert(race.best_time == 0.0 and race.state == RaceController.State.COUNTDOWN)
		var length := race.lap.route_length
		assert(length > 2500 and length < 5000)
		assert(race.track.frame_at(0).origin.distance_to(race.track.frame_at(length - 0.01).origin) < 0.1)
		var hud := race.get_node("HUD")
		for point in race.track.path.curve.get_baked_points():
			assert(Rect2(764, 502, 167, 167).has_point(hud._map_point(point)))
		for i in 185:
			await physics_frame
		if definition["id"] == "el_zonda":
			_check_bridge(race.track)
			await _check_runoff(race)
			race = current_scene as RaceController
			for i in 185:
				await physics_frame
		var result := await LapDriver.drive(self, race)
		assert(race.state == RaceController.State.FINISHED and not race.lap.invalid)
		assert(race.lap.elapsed > 60 and race.lap.elapsed < 300)
		assert(result.max_error < 8.5 and result.grounded_ticks > result.frames * 0.95)
		assert(race.new_record and race.best_time == race.lap.elapsed)
		var record := race.best_time
		assert(records.load(RaceController.RECORDS_PATH) == OK)
		assert(records.get_value("galvez_8", "best_lap") == 123.456)
		assert(records.get_value(race.track_id, "best_lap") == record)
		race._retry()
		await process_frame
		await process_frame
		race = current_scene as RaceController
		assert(race.track_id == definition["id"] and race.best_time == record and not race.lap.started)
		race._back_to_selection()
		await process_frame
		await process_frame
		assert(current_scene.name == "TrackSelection" and setup.selected_index == index and not paused)
	print("Circuit tests passed: scene selection, closed routes, minimaps, physical laps, per-track records, retries and return menus.")
	quit()


func _check_bridge(track: CircuitTrack) -> void:
	var upper := track.frame_at(track.bridge_distance).origin
	var lower := upper
	var best_distance := 1000.0
	var offset := 0.0
	while offset < track.path.curve.get_baked_length():
		var point := track.frame_at(offset).origin
		var separation := Vector2(point.x - upper.x, point.z - upper.z).length()
		if point.y < upper.y - 5 and separation < best_distance:
			lower = point
			best_distance = separation
		offset += 1.0
	assert(best_distance < 4 and upper.y - lower.y > 6)
	var space := track.get_world_3d().direct_space_state
	for point in [lower, upper]:
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(point + Vector3.UP * 2, point - Vector3.UP * 2))
		assert(not hit.is_empty() and absf(hit.position.y - point.y) < 0.2)
	assert(absf(track.nearest_distance(lower) - track.nearest_distance(upper)) > 200)


func _check_runoff(race: RaceController) -> void:
	var car := race.car
	car.reset_to(race.track.frame_at(350) * Transform3D(Basis.IDENTITY, Vector3(10, 0, 0)))
	race._previous_position = car.global_position
	var grass_ticks := 0
	for i in 240:
		var offset := race.track.nearest_distance(car.global_position)
		var target := race.track.frame_at(offset + 12).origin
		var wanted := Vector3(target.x - car.global_position.x, 0, target.z - car.global_position.z).normalized()
		var turn := clampf(-(-car.global_basis.z).signed_angle_to(wanted, Vector3.UP) * 3, -1, 1)
		Input.action_press("drive_left", maxf(-turn, 0))
		Input.action_press("drive_right", maxf(turn, 0))
		Input.action_press("drive_accelerate", 1.0 if car.speed < 16 else 0.0)
		Input.action_press("drive_brake", 1.0 if car.speed > 18 else 0.0)
		await physics_frame
		if not car.on_asphalt:
			grass_ticks += 1
	for action in ["drive_left", "drive_right", "drive_accelerate", "drive_brake"]:
		Input.action_release(action)
	assert(grass_ticks > 0 and car.on_asphalt and car.is_on_floor() and car.speed > 10)
	print("Sloped runoff recovery passed; grass ticks=", grass_ticks)
	race._retry()
	await process_frame
	await process_frame
