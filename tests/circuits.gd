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
