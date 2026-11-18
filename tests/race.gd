extends SceneTree
## Real physics/input integration plus continuous lap progress and reset rules.

const LapDriver = preload("res://tests/lap_driver.gd")

func _initialize() -> void:
	_run.call_deferred()


func _ticks(count: int) -> void:
	for i in count:
		await physics_frame
	await process_frame


func _key(key: Key, pressed: bool, physical := false, echo := false) -> void:
	var event := InputEventKey.new()
	if physical:
		event.physical_keycode = key
	else:
		event.keycode = key
	event.pressed = pressed
	event.echo = echo
	Input.parse_input_event(event)


func _tap(key: Key, physical := false, echo := false) -> void:
	_key(key, true, physical, echo)
	await process_frame
	_key(key, false, physical)
	await process_frame


func _release_driving() -> void:
	for action in ["drive_left", "drive_right", "drive_accelerate", "drive_brake"]:
		Input.action_release(action)


func _circle_point(distance: float) -> Vector3:
	var angle := distance / 100.0 * TAU
	return Vector3(1.0 - cos(angle), 0, -sin(angle)) * (100.0 / TAU)


func _advance_circle(tracker: LapTracker, previous: float, current: float) -> void:
	tracker.advance(_circle_point(previous), _circle_point(current), 0.1, fposmod(current, 100.0))


func _check_laps() -> void:
	var line := Transform3D.IDENTITY
	assert(LapTracker.crosses_forward(Vector3(0, 0, 0.95), Vector3(0, 0, -0.95), line, 18.0))
	assert(LapTracker.crosses_forward(Vector3(12, 0, 1), Vector3(12, 0, -1), line, 18.0))
	assert(not LapTracker.crosses_forward(Vector3(0, 0, -1), Vector3(0, 0, 1), line, 18.0))
	assert(not LapTracker.crosses_forward(Vector3(19, 0, 1), Vector3(19, 0, -1), line, 18.0))
	assert(not LapTracker.crosses_forward(Vector3(0, 5, 1), Vector3(0, 5, -1), line, 18.0))
	var tracker := LapTracker.new()
	tracker.route_length = 100.0
	_advance_circle(tracker, 20, 21)
	assert(not tracker.started)
	_advance_circle(tracker, -1, 1)
	assert(tracker.started)
	for i in 10:
		_advance_circle(tracker, 1, -1)
		_advance_circle(tracker, -1, 1)
	assert(not tracker.finished and is_zero_approx(tracker.progress))
	# A backward lap and retraced sections cannot accumulate a forward lap.
	for i in range(1, -100, -1):
		_advance_circle(tracker, i, i - 1)
	assert(not tracker.finished and tracker.progress < -99)
	for i in range(-100, 1):
		_advance_circle(tracker, i, i + 1)
	assert(not tracker.finished and is_zero_approx(tracker.progress))
	for i in range(1, 101):
		_advance_circle(tracker, i, i + 1)
	assert(tracker.finished)
	var elapsed := tracker.elapsed
	_advance_circle(tracker, 101, 102)
	assert(tracker.elapsed == elapsed)
	# Nearest-sector discontinuities and resets cannot manufacture progress.
	tracker = LapTracker.new()
	tracker.route_length = 100.0
	_advance_circle(tracker, -1, 1)
	tracker.advance(_circle_point(1), _circle_point(2), 0.1, 41)
	assert(is_zero_approx(tracker.progress))
	tracker.relocate(50)
	_advance_circle(tracker, 50, 51)
	assert(is_equal_approx(tracker.progress, 1.0) and not tracker.finished)


func _check_grass_lap(track: CircuitTrack) -> void:
	var tracker := LapTracker.new()
	tracker.finish_line = track.global_transform * track.frame_at(0)
	tracker.route_length = track.path.curve.get_baked_length()
	# Cross the entire circuit and finish on the grass, outside the old gates.
	var previous := track.frame_at(-2) * Vector3(12, 0, 0)
	var distance := 2.0
	while distance < tracker.route_length + 5.0:
		var current := track.frame_at(distance) * Vector3(12, 0, 0)
		tracker.advance(previous, current, 0.1, track.nearest_distance(current))
		previous = current
		distance += 2.0
	assert(tracker.finished and not tracker.invalid)


func _run() -> void:
	_check_laps()
	for locale in ["es", "en"]:
		TranslationServer.set_locale(locale)
		for text in ["LAP_TIME", "LAP_INVALID", "TIME_TRIAL_ONE_LAP", "RESULT_CONTROLS",
			"TRACK_UNAVAILABLE", "HUD_LAP", "HUD_TIME", "HUD_PROGRESS", "HUD_SPEED_UNIT",
			"HUD_ACCELERATOR", "HUD_BRAKE", "HUD_INPUTS"]:
			assert(tr(text) != text)
	root.get_node("Localization").apply_system_language()
	root.get_node("RaceSetup").select_track(0)
	assert(change_scene_to_file("res://scenes/race/race.tscn") == OK)
	await process_frame
	await process_frame
	var race := current_scene as RaceController
	_check_grass_lap(race.track)
	var car := race.car
	var spawn := car.global_position
	assert(race.state == RaceController.State.COUNTDOWN)
	for pair in [[KEY_UP, "drive_accelerate"], [KEY_DOWN, "drive_brake"], [KEY_LEFT, "drive_left"], [KEY_RIGHT, "drive_right"]]:
		_key(pair[0], true)
		await process_frame
		assert(Input.is_action_pressed(pair[1]))
		_key(pair[0], false)
		await process_frame
	_key(KEY_W, true, true)
	await _ticks(60)
	assert(car.global_position.is_equal_approx(spawn))
	await _ticks(125)
	assert(race.state == RaceController.State.RACING)
	await _ticks(120)
	assert(car.speed > 12 and car.is_on_floor())
	assert(race.lap.started)
	# WASD and arrow alternatives, including both pedals and opposite directions.
	_key(KEY_S, true, true)
	var fast := car.speed
	await _ticks(25)
	assert(car.speed < fast - 5) # Brake wins over W.
	_key(KEY_S, false, true)
	_key(KEY_A, true, true)
	_key(KEY_D, true, true)
	await _ticks(10)
	assert(is_zero_approx(car.steering))
	_key(KEY_D, false, true)
	await _ticks(15)
	assert(car.steering < -0.5)
	_key(KEY_A, false, true)
	await _ticks(20)
	assert(is_zero_approx(car.steering))
	_key(KEY_W, false, true)
	await _tap(KEY_ESCAPE, false, true)
	assert(race.state == RaceController.State.RACING) # OS repeat ignored.
	await _tap(KEY_ESCAPE)
	assert(race.state == RaceController.State.PAUSED and paused)
	var position := car.global_position
	var elapsed := race.lap.elapsed
	await _ticks(30)
	assert(car.global_position == position and race.lap.elapsed == elapsed)
	await _tap(KEY_ESCAPE)
	assert(not paused and race.state == RaceController.State.RACING)
	var recovery_distance := race.track.nearest_distance(car.global_position)
	var progress := race.lap.progress
	await _tap(KEY_R, true)
	assert(race.lap.invalid and car.speed < 0.01 and Vector2(car.velocity.x, car.velocity.z).length() < 0.01)
	assert(car.global_position.distance_to(race.track.frame_at(recovery_distance).origin) < 0.2)
	await _ticks(3)
	assert(is_equal_approx(race.lap.progress, progress))
	# Focus loss pauses physics and the timer too.
	race.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	assert(paused and race.state == RaceController.State.PAUSED)
	await _tap(KEY_ENTER)
	assert(not paused)
	# Grass preserves momentum, allows acceleration and gently limits top speed.
	car.reset_to(Transform3D(Basis.IDENTITY, Vector3(700, 0, 500)))
	car.velocity = -car.global_basis.z * 40
	await _ticks(90)
	assert(not car.on_asphalt and car.speed > 36 and car.speed < 40)
	car.reset_to(Transform3D(Basis.IDENTITY, Vector3(700, 0, 500)))
	car.velocity = -car.global_basis.z * car.tuning.top_speed
	Input.action_press("drive_accelerate")
	await _ticks(60)
	assert(not car.on_asphalt and car.speed > 53 and car.speed < car.tuning.top_speed)
	await _ticks(360)
	assert(is_equal_approx(car.speed, car.tuning.grass_top_speed))
	car.reset_to(Transform3D(Basis.IDENTITY, Vector3(700, 0, 500)))
	await _ticks(600)
	assert(not car.on_asphalt and is_equal_approx(car.speed, car.tuning.grass_top_speed))
	_release_driving()
	# A real rail impact, with unchanged physics frequency.
	var rail_pose := race.track.frame_at(180)
	rail_pose.origin += rail_pose.basis.x * 14
	rail_pose.basis = Basis.looking_at(rail_pose.basis.x, Vector3.UP)
	car.reset_to(rail_pose)
	car.velocity = -car.global_basis.z * 56
	await _ticks(20)
	var lateral := (race.track.frame_at(180).affine_inverse() * car.global_position).x
	assert(lateral < 18.5 and car.speed < 20) # Does not tunnel through the rail.
	_release_driving()
	# A fresh session must clear the reset flag, route progress and countdown.
	race._retry()
	await process_frame
	await process_frame
	race = current_scene as RaceController
	car = race.car
	assert(not race.lap.invalid and not race.lap.started and is_zero_approx(race.lap.progress))
	# Finishing a reset lap must leave the stored best untouched.
	var previous_best := race.best_time
	race.lap.invalid = true
	race.lap.elapsed = 1.0
	race._finish()
	assert(race.best_time == previous_best and not race.new_record)
	race._retry()
	await process_frame
	await process_frame
	race = current_scene as RaceController
	car = race.car
	await _ticks(185)
	var result := await LapDriver.drive(self, race, true)
	assert(race.state == RaceController.State.FINISHED and not race.lap.invalid)
	assert(race.lap.elapsed > 60 and race.lap.elapsed < 240)
	assert(result.max_error < 14 and result.grass_ticks > 90)
	assert(race.new_record and race.best_time == race.lap.elapsed)
	# Results retry works and records survive a scene reload.
	var record := race.best_time
	await _tap(KEY_ENTER)
	await process_frame
	race = current_scene as RaceController
	assert(race.state == RaceController.State.COUNTDOWN and is_equal_approx(race.best_time, record))
	await _tap(KEY_ESCAPE)
	await _tap(KEY_DOWN)
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	await process_frame
	assert(current_scene.name == "TrackSelection" and not paused)
	print("Race tests passed: keyboard, continuous progress, grass lap/finish, pause/focus, grass recovery, collision, reset, complete physical lap, record and menus.")
	quit()
