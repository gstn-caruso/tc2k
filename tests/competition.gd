extends SceneTree
## Real CPU laps on every circuit, mode navigation, shared race state and standings.

const LapDriver = preload("res://tests/lap_driver.gd")


func _initialize() -> void:
	_run.call_deferred()


func _ticks(count: int) -> void:
	for i in count:
		await physics_frame
	await process_frame


func _tap(key: Key, echo := false) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	event.echo = echo
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.keycode = key
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame


func _run() -> void:
	var setup := root.get_node("RaceSetup")
	assert(setup.selected_mode_index == 0 and setup.MODES[0]["id"] == "practice")
	setup.select_track(1)
	setup.select_car(1)
	assert(change_scene_to_file("res://scenes/mode_selection.tscn") == OK)
	await process_frame
	await process_frame
	var selection := current_scene
	await _tap(KEY_LEFT, true)
	await _tap(KEY_ENTER, true)
	await _tap(KEY_SPACE)
	assert(current_scene == selection and setup.selected_mode_index == 0)
	await _tap(KEY_LEFT)
	assert(setup.selected_mode_index == 1)
	await _tap(KEY_RIGHT)
	assert(setup.selected_mode_index == 0)
	await _tap(KEY_RIGHT)
	await _tap(KEY_ESCAPE)
	await process_frame
	assert(current_scene.name == "CarSelection" and setup.selected_car_index == 1 and setup.selected_index == 1)
	await _tap(KEY_ENTER)
	await process_frame
	assert(current_scene.name == "ModeSelection" and setup.selected_mode_index == 1)
	await _tap(KEY_KP_ENTER)
	await process_frame
	assert(current_scene.name == "Race" and current_scene.is_competition())
	current_scene._back_to_selection()
	await process_frame
	await process_frame
	# Every car must work as the player and appear among the CPU models.
	for car_index in setup.CARS.size():
		setup.select_car(car_index)
		assert(change_scene_to_file("res://scenes/race/race.tscn") == OK)
		await process_frame
		await process_frame
		var grid_race := current_scene as RaceController
		assert(grid_race.car.model_id == setup.CARS[car_index]["id"])
		for cpu_index in grid_race.opponents.size():
			var definition: Dictionary = setup.CARS[(car_index + cpu_index + 1) % setup.CARS.size()]
			var opponent := grid_race.opponents[cpu_index]
			assert(opponent.model_id == definition["id"])
			assert(opponent._visual.scene_file_path == definition["scene"])
			assert(opponent._visual._wheel_meshes.size() == 4)
		grid_race.countdown = 0.0
		var start := grid_race.opponents[0].global_position
		await _ticks(120)
		assert(grid_race.opponents[0].global_position.distance_to(start) > 5.0)
	# Competition must leave practice records untouched.
	var records := ConfigFile.new()
	for definition: Dictionary in setup.TRACKS:
		records.set_value(definition["id"], "best_lap", 999.0)
	assert(records.save(RaceController.RECORDS_PATH) == OK)
	for index in setup.TRACKS.size():
		setup.select_track(index)
		setup.select_car(setup.CARS.size() - 1 - index)
		assert(change_scene_to_file("res://scenes/race/race.tscn") == OK)
		await process_frame
		await process_frame
		var race := current_scene as RaceController
		assert(race.mode_id == "competition" and race.opponents.size() == 3)
		assert(race.car.model_id == setup.CARS[setup.selected_car_index]["id"])
		assert(race.car._visual.scene_file_path == setup.CARS[setup.selected_car_index]["scene"])
		assert(race.player_position() >= 3 and race.player_position() <= 4)
		var grid: Array[Vector3] = []
		for opponent in race.opponents:
			grid.append(opponent.global_position)
			assert(not opponent.driving_enabled)
			assert(opponent.global_position.distance_to(race.car.global_position) > 4.5)
			for other in race.opponents:
				assert(other == opponent or other.global_position.distance_to(opponent.global_position) > 4.5)
		for cpu_index in race.opponents.size():
			assert(race.opponents[cpu_index].model_id == setup.CARS[(setup.selected_car_index + cpu_index + 1) % setup.CARS.size()]["id"])
		_check_map_markers(race)
		Input.action_press("drive_accelerate")
		await _ticks(45)
		for cpu_index in race.opponents.size():
			assert(race.opponents[cpu_index].global_position == grid[cpu_index])
		Input.action_release("drive_accelerate")
		# Pause and resume the countdown as well as the race itself.
		race.pause_race()
		var countdown := race.countdown
		await _ticks(15)
		assert(is_equal_approx(race.countdown, countdown))
		race._resume()
		await _ticks(145)
		assert(race.state == RaceController.State.RACING)
		# Player keyboard braking/steering must not control any CPU driver.
		Input.action_press("drive_brake")
		Input.action_press("drive_left")
		await _ticks(120)
		for cpu_index in race.opponents.size():
			var opponent := race.opponents[cpu_index]
			assert(opponent.lap.started and opponent.speed > 8.0)
			assert(opponent.global_position.distance_to(grid[cpu_index]) > 10.0)
		Input.action_release("drive_brake")
		Input.action_release("drive_left")
		race.pause_race()
		var race_time := race.race_time
		var cpu_position := race.opponents[0].global_position
		var cpu_time := race.opponents[0].lap.elapsed
		await _ticks(30)
		assert(race.race_time == race_time and race.opponents[0].lap.elapsed == cpu_time)
		assert(race.opponents[0].global_position == cpu_position)
		race._resume()
		var frames := 0
		while race.finish_order.size() < 3 and frames < 18000:
			await physics_frame
			frames += 1
		for opponent in race.opponents:
			print(race.track_id, " ", opponent.name, ": progress=", opponent.lap.progress,
				"; time=", opponent.lap.elapsed, "; position=", opponent.global_position)
			assert(opponent.lap.finished and not opponent.lap.invalid)
			assert(opponent.lap.elapsed > 60 and opponent.lap.elapsed < 300)
		assert(race.player_position() == 4 and race.state == RaceController.State.RACING)
		# Finish order must stay stable even after the leaders drive past the line.
		var order := race.finish_order.duplicate()
		await _ticks(30)
		assert(race.finish_order == order and race.player_position() == 4)
		await LapDriver.drive(self, race)
		assert(race.state == RaceController.State.FINISHED and race.lap.finished)
		assert(race.player_position() == 4 and race.finish_order.back() == race.car)
		assert(not race.new_record and race.best_time == 999.0)
		for opponent in race.opponents:
			assert(not opponent.driving_enabled)
		assert(records.load(RaceController.RECORDS_PATH) == OK)
		assert(records.get_value(race.track_id, "best_lap") == 999.0)
		race._retry()
		await process_frame
		await process_frame
		race = current_scene as RaceController
		assert(race.is_competition() and race.car.model_id == setup.CARS[setup.selected_car_index]["id"])
		assert(race.opponents.size() == 3 and race.finish_order.is_empty() and race.race_time == 0.0)
		for opponent in race.opponents:
			assert(not opponent.lap.started and not opponent.driving_enabled)
		# Standings use continuous progress; relocating cannot manufacture an overtake.
		race.state = RaceController.State.RACING
		race.lap.started = true
		race.lap.progress = 150.0
		for cpu_index in race.opponents.size():
			race.opponents[cpu_index].lap.started = true
			race.opponents[cpu_index].lap.progress = 100.0 + cpu_index * 50.0
		assert(race.player_position() == 3)
		race.reset_car()
		assert(race.player_position() == 3 and race.lap.progress == 150.0)
		race.lap.progress = 250.0
		assert(race.player_position() == 1)
		race.finish_order.append(race.car)
		race._finish()
		assert(race.player_position() == 1 and not race.new_record)
		race._back_to_selection()
		await process_frame
		await process_frame
		assert(current_scene.name == "TrackSelection" and setup.selected_mode_index == 1 and not paused)
	print("Competition tests passed: mode controls, grid/countdown, independent CPU inputs, pause, complete CPU/player laps on all tracks, standings, results, records and retry.")
	quit()


func _check_map_markers(race: RaceController) -> void:
	var hud := race.get_node("HUD")
	var points := PackedVector2Array([hud._map_point(race.track.to_local(race.car.global_position))])
	for opponent in race.opponents:
		points.append(hud._map_point(race.track.to_local(opponent.global_position)))
	# All four numbers remain legible on the starting grid and at map edges.
	var cases: Array[PackedVector2Array] = [points]
	for origin: Vector2 in [hud.MAP_RECT.position, hud.MAP_RECT.end, hud.MAP_RECT.get_center()]:
		cases.append(PackedVector2Array([origin, origin, origin, origin]))
	for clustered in cases:
		var markers: PackedVector2Array = hud._separate_map_markers(clustered)
		assert(markers.size() == 4)
		for index in markers.size():
			assert(hud.MAP_RECT.grow(3.1).has_point(markers[index]))
			for other in range(index + 1, markers.size()):
				assert(markers[index].distance_to(markers[other]) >= 19.9)
