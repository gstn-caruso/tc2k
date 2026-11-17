extends SceneTree
## Real physics/input integration plus directional checkpoint and reset rules.

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


func _run() -> void:
	# Forward/reverse, edge/outside, height and a maximum-speed sweep.
	var gate := Transform3D.IDENTITY
	assert(LapTracker.crosses_forward(Vector3(0, 0, 0.95), Vector3(0, 0, -0.95), gate, 8.5))
	assert(not LapTracker.crosses_forward(Vector3(0, 0, -1), Vector3(0, 0, 1), gate, 8.5))
	assert(not LapTracker.crosses_forward(Vector3(9, 0, 1), Vector3(9, 0, -1), gate, 8.5))
	assert(not LapTracker.crosses_forward(Vector3(0, 5, 1), Vector3(0, 5, -1), gate, 8.5))
	var tracker := LapTracker.new()
	tracker.gates = [gate, Transform3D(Basis.IDENTITY, Vector3(0, 0, -20))]
	tracker.advance(Vector3(0, 0, -19), Vector3(0, 0, -21), 0.1)
	assert(not tracker.started) # Cannot skip the start.
	tracker.advance(Vector3(0, 0, 1), Vector3(0, 0, -1), 0.1)
	tracker.advance(Vector3(0, 0, 1), Vector3(0, 0, -1), 0.1)
	assert(not tracker.finished and tracker.next_gate == 1) # Repeated finish doesn't count.
	tracker.advance(Vector3(0, 0, -19), Vector3(0, 0, -21), 0.1)
	tracker.advance(Vector3(0, 0, 1), Vector3(0, 0, -1), 0.1)
	assert(tracker.finished)
	for locale in ["es", "en"]:
		TranslationServer.set_locale(locale)
		for text in ["LAP_TIME", "LAP_INVALID", "TIME_TRIAL_ONE_LAP", "RESULT_CONTROLS", "TRACK_UNAVAILABLE"]:
			assert(tr(text) != text)
	root.get_node("Localization").apply_system_language()
	root.get_node("RaceSetup").select_track(0)
	assert(change_scene_to_file("res://scenes/race/race.tscn") == OK)
	await process_frame
	await process_frame
	var race := current_scene as RaceController
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
	await _tap(KEY_R, true)
	assert(race.lap.invalid and car.speed < 0.01 and Vector2(car.velocity.x, car.velocity.z).length() < 0.01)
	var expected_gate := race.lap.next_gate
	await _ticks(3)
	assert(race.lap.next_gate == expected_gate)
	# Focus loss pauses physics and the timer too.
	race.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	assert(paused and race.state == RaceController.State.PAUSED)
	await _tap(KEY_ENTER)
	assert(not paused)
	# Grass drag and a real rail impact, with unchanged physics frequency.
	car.reset_to(race.track.frame_at(140) * Transform3D(Basis.IDENTITY, Vector3(11, 0, 0)))
	car.velocity = -car.global_basis.z * 40
	await _ticks(90)
	assert(not car.on_asphalt and car.speed < 30)
	var rail_pose := race.track.frame_at(180)
	rail_pose.origin += rail_pose.basis.x * 14
	rail_pose.basis = Basis.looking_at(rail_pose.basis.x, Vector3.UP)
	car.reset_to(rail_pose)
	car.velocity = -car.global_basis.z * 56
	await _ticks(20)
	var lateral := (race.track.frame_at(180).affine_inverse() * car.global_position).x
	assert(lateral < 18.5 and car.speed < 20) # Does not tunnel through the rail.
	_release_driving()
	# A fresh session must clear the reset flag, gate progress and countdown.
	race._retry()
	await process_frame
	await process_frame
	race = current_scene as RaceController
	car = race.car
	assert(not race.lap.invalid and not race.lap.started and race.lap.next_gate == 0)
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
	# Drive the whole physical circuit with a steering/pedal feedback controller.
	# This samples the route for test inputs only; the production car has no rail.
	var max_error := 0.0
	var frames := 0
	while race.state == RaceController.State.RACING and frames < 24000:
		var offset := race.track.nearest_distance(car.global_position)
		var target := race.track.frame_at(offset + maxf(9, car.speed * 0.42)).origin
		var wanted := (target - car.global_position).normalized()
		var angle := (-car.global_basis.z).signed_angle_to(wanted, Vector3.UP)
		var turn := clampf(-angle * 3, -1, 1)
		Input.action_press("drive_left", maxf(-turn, 0))
		Input.action_press("drive_right", maxf(turn, 0))
		var curvature := 0.001
		for sample in [0.0, 20.0, 40.0, 65.0]:
			var here := -race.track.frame_at(offset + sample).basis.z
			var ahead := -race.track.frame_at(offset + sample + 20).basis.z
			curvature = maxf(curvature, absf(here.signed_angle_to(ahead, Vector3.UP)) / 20)
		var target_speed := clampf(sqrt(6.0 / curvature), 10, 44)
		Input.action_press("drive_accelerate", 1.0 if car.speed < target_speed else 0.0)
		Input.action_press("drive_brake", 1.0 if car.speed > target_speed + 1.0 else 0.0)
		var nearest := race.track.path.curve.get_closest_point(car.global_position)
		max_error = maxf(max_error, Vector2(nearest.x - car.global_position.x, nearest.z - car.global_position.z).length())
		await physics_frame
		frames += 1
	_release_driving()
	await process_frame
	print("Physical lap: ", frames, " ticks; time=", race.lap.elapsed, "; max line error=", max_error, "; gate=",race.lap.next_gate)
	assert(race.state == RaceController.State.FINISHED and not race.lap.invalid)
	assert(race.lap.elapsed > 60 and race.lap.elapsed < 240)
	assert(max_error < 8.5)
	assert(race.new_record and race.best_time == race.lap.elapsed)
	# Results retry works and records survive a scene reload.
	var record := race.best_time
	await _tap(KEY_ENTER)
	await process_frame
	race = current_scene as RaceController
	assert(race.state == RaceController.State.COUNTDOWN and race.best_time == record)
	await _tap(KEY_ESCAPE)
	await _tap(KEY_DOWN)
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	await process_frame
	assert(current_scene.name == "TrackSelection" and not paused)
	print("Race tests passed: keyboard, gating, pause/focus, grass, collision, reset, complete physical lap, record and menus.")
	quit()
