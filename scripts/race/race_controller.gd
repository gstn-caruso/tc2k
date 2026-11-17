class_name RaceController
extends Control
## One-lap practice or a grid race against CPU drivers, with results and retry.

enum State { COUNTDOWN, RACING, PAUSED, FINISHED }
const RECORDS_PATH := "user://lap_records.cfg"
var track_definition: Dictionary
var car_definition: Dictionary
var track_id: String
var mode_id := "practice"
var opponents: Array[CpuCar] = []
var finish_order: Array[ArcadeCar] = []
var race_time := 0.0
var state := State.COUNTDOWN
var countdown := 3.0
var lap := LapTracker.new()
var best_time := 0.0
var new_record := false
var pause_index := 0
var wrong_way := false
var car: ArcadeCar
var track: CircuitTrack
var camera: RaceCamera
var _resume_state := State.COUNTDOWN
var _previous_position := Vector3.ZERO
var _leaving := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var setup := get_node("/root/RaceSetup")
	track_definition = setup.TRACKS[setup.selected_index]
	car_definition = setup.CARS[setup.selected_car_index]
	mode_id = setup.MODES[setup.selected_mode_index]["id"]
	track_id = track_definition["id"]
	if track_definition["scene"].is_empty():
		_back_to_selection.call_deferred()
		return
	_build_world()
	lap.finish_line = track.global_transform * track.frame_at(0.0)
	lap.route_length = track.path.curve.get_baked_length()
	lap.half_width = track.rail_offset
	var records := ConfigFile.new()
	if records.load(RECORDS_PATH) == OK:
		best_time = maxf(0.0, float(records.get_value(track_id, "best_lap", 0.0)))
	var spawn := track.frame_at(-16.0) if is_competition() else track.frame_at(-14.0)
	if is_competition():
		spawn.origin += spawn.basis.x * 3.0
	car.reset_to(spawn)
	_previous_position = car.global_position
	camera.snap()


func _build_world() -> void:
	var viewport := $WorldViewport as SubViewport
	viewport.process_mode = Node.PROCESS_MODE_PAUSABLE
	var world := Node3D.new()
	world.name = "World"
	viewport.add_child(world)
	track = (load(track_definition["scene"]) as PackedScene).instantiate() as CircuitTrack
	world.add_child(track)
	car = ArcadeCar.new()
	car.name = "Car"
	car.track = track
	car.model_id = car_definition["id"]
	car.model_scene = load(car_definition["scene"]) as PackedScene
	world.add_child(car)
	if is_competition():
		_build_opponents(world)
	camera = RaceCamera.new()
	camera.name = "RaceCamera"
	camera.car = car
	camera.fov = 63
	camera.far = 1100
	world.add_child(camera)
	camera.current = true
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -30, 0)
	sun.light_color = Color("ffefd1")
	sun.light_energy = 1.15
	world.add_child(sun)
	var environment := WorldEnvironment.new()
	var setting := Environment.new()
	setting.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("347ca5")
	sky_material.sky_horizon_color = Color("c0d7d4")
	sky_material.ground_horizon_color = Color("c0d7d4")
	sky_material.ground_bottom_color = Color("6d8e58")
	sky.sky_material = sky_material
	setting.sky = sky
	setting.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	setting.ambient_light_color = Color("b5c7db")
	setting.ambient_light_energy = 0.65
	setting.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	setting.fog_enabled = true
	setting.fog_light_color = Color("b7d0cd")
	setting.fog_density = 0.0011
	environment.environment = setting
	world.add_child(environment)
	($WorldImage as TextureRect).texture = viewport.get_texture()


func _build_opponents(world: Node3D) -> void:
	var setup := get_node("/root/RaceSetup")
	for index in 3:
		var opponent := CpuCar.new()
		opponent.name = "CPU%d" % (index + 1)
		opponent.track = track
		var definition: Dictionary = setup.CARS[index % setup.CARS.size()]
		opponent.model_id = definition["id"]
		opponent.model_scene = load(definition["scene"]) as PackedScene
		opponent.lane_offset = 3.0 if index == 1 else -3.0
		opponent.cruising_speed = 38.0 + index * 2.0
		world.add_child(opponent)
		var spawn := track.frame_at(-8.0 if index < 2 else -16.0)
		spawn.origin += spawn.basis.x * opponent.lane_offset
		opponent.reset_to(spawn)
		opponent.previous_position = opponent.global_position
		opponent.lap.finish_line = track.global_transform * track.frame_at(0.0)
		opponent.lap.route_length = track.path.curve.get_baked_length()
		opponent.lap.half_width = track.rail_offset
		opponents.append(opponent)
	var traffic: Array[ArcadeCar] = [car]
	traffic.append_array(opponents)
	for opponent in opponents:
		opponent.traffic = traffic


func is_competition() -> bool:
	return mode_id == "competition"


func player_position() -> int:
	if car in finish_order:
		return finish_order.find(car) + 1
	var rank := 1
	var progress := _race_progress(car, lap)
	for opponent in opponents:
		if opponent in finish_order or _race_progress(opponent, opponent.lap) >= progress:
			rank += 1
	return rank


func _race_progress(racer: ArcadeCar, tracker: LapTracker) -> float:
	if tracker.started:
		return tracker.progress
	return wrapf(track.nearest_distance(racer.global_position), -tracker.route_length * 0.5, tracker.route_length * 0.5)


func _set_driving_enabled(enabled: bool) -> void:
	car.driving_enabled = enabled
	for opponent in opponents:
		opponent.driving_enabled = enabled


func _physics_process(delta: float) -> void:
	if not car or _leaving:
		return
	if state == State.COUNTDOWN:
		countdown = maxf(0.0, countdown - delta)
		if countdown <= 0.0:
			state = State.RACING
			_set_driving_enabled(true)
	elif state == State.RACING:
		race_time += delta
		for opponent in opponents:
			opponent.lap.advance(opponent.previous_position, opponent.global_position, delta,
				track.nearest_distance(opponent.global_position))
			opponent.previous_position = opponent.global_position
			if opponent.lap.finished and opponent not in finish_order:
				finish_order.append(opponent)
		var distance := track.nearest_distance(car.global_position)
		lap.advance(_previous_position, car.global_position, delta, distance)
		_previous_position = car.global_position
		var tangent := -track.frame_at(distance).basis.z
		wrong_way = car.speed > 3 and (-car.global_basis.z).dot(tangent) < -0.3
		if lap.finished:
			finish_order.append(car)
			_finish()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or _leaving:
		return
	if state == State.PAUSED:
		if event.is_action_pressed("race_pause"):
			_resume()
		elif event.is_action_pressed("menu_up"):
			pause_index = wrapi(pause_index - 1, 0, 3)
		elif event.is_action_pressed("menu_down"):
			pause_index = wrapi(pause_index + 1, 0, 3)
		elif event.is_action_pressed("menu_confirm"):
			match pause_index:
				0: _resume()
				1: _retry.call_deferred()
				2: _back_to_selection.call_deferred()
		else:
			return
	elif state == State.FINISHED:
		if event.is_action_pressed("menu_confirm"):
			_retry.call_deferred()
		elif event.is_action_pressed("race_pause"):
			_back_to_selection.call_deferred()
		else:
			return
	elif event.is_action_pressed("race_pause"):
		pause_race()
	elif state == State.RACING and event.is_action_pressed("car_reset"):
		reset_car()
	else:
		return
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and car:
		pause_race()


func pause_race() -> void:
	if state != State.COUNTDOWN and state != State.RACING:
		return
	_resume_state = state
	state = State.PAUSED
	pause_index = 0
	_set_driving_enabled(false)
	get_tree().paused = true


func _resume() -> void:
	state = _resume_state
	get_tree().paused = false
	_set_driving_enabled(state == State.RACING)
	_previous_position = car.global_position


func reset_car() -> void:
	if state != State.RACING:
		return
	lap.invalid = true
	var distance := track.nearest_distance(car.global_position) if lap.started else -14.0
	car.reset_to(track.frame_at(distance))
	_previous_position = car.global_position
	lap.relocate(track.nearest_distance(car.global_position))
	camera.snap()


func _finish() -> void:
	state = State.FINISHED
	_set_driving_enabled(false)
	if not is_competition() and not lap.invalid and (best_time <= 0 or lap.elapsed < best_time):
		best_time = lap.elapsed
		new_record = true
		var records := ConfigFile.new()
		records.load(RECORDS_PATH)
		records.set_value(track_id, "best_lap", best_time)
		if records.save(RECORDS_PATH) != OK:
			push_warning("Could not save lap record")


func _retry() -> void:
	_leaving = true
	get_tree().paused = false
	get_tree().reload_current_scene()


func _back_to_selection() -> void:
	_leaving = true
	get_tree().paused = false
	get_node("/root/RaceSetup").confirmed = false
	get_tree().change_scene_to_file("res://scenes/track_selection.tscn")


func _exit_tree() -> void:
	get_tree().paused = false
