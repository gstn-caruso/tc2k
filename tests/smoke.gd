extends SceneTree
## Verify OS language and the complete title → circuit → car → mode → race flow.


func _initialize() -> void:
	_run.call_deferred()


func _press(key: Key, echo := false) -> void:
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
	var localization := root.get_node("Localization")
	assert(localization.resolve_locale("es_AR") == "es")
	assert(localization.resolve_locale("es-MX") == "es")
	assert(localization.resolve_locale("en_US") == "en")
	assert(localization.resolve_locale("EN-GB") == "en")
	assert(localization.resolve_locale("fr_FR") == "es")
	assert(localization.resolve_locale("C") == "es")
	var system_language: String = localization.resolve_locale(OS.get_locale())
	assert(TranslationServer.get_locale() == system_language)
	# Older manual preferences must not override the OS language.
	var legacy := ConfigFile.new()
	legacy.set_value("interface", "language", "en" if system_language == "es" else "es")
	assert(legacy.save("user://settings.cfg") == OK)
	localization.apply_system_language()
	assert(TranslationServer.get_locale() == system_language)
	for locale in ["es", "en"]:
		TranslationServer.set_locale(locale)
		assert(tr("PRESS_ENTER") != "PRESS_ENTER")
		assert(tr("SELECT_CIRCUIT") != "SELECT_CIRCUIT")
		for key in ["SELECT_CAR", "PROTOTYPE_CAR", "FUEGO_LIVERY", "SIERRA_LIVERY", "PROTOTYPE_LIVERY",
			"GOL_LIVERY", "PEUGEOT_LIVERY", "CIVIC_LIVERY", "ASTRA_LIVERY", "CAR_COUNT", "CAR_CONTROLS"]:
			assert(tr(key) != key)
		for key in ["SELECT_MODE", "MODE_PRACTICE", "MODE_COMPETITION", "PRACTICE_DESCRIPTION",
			"PRACTICE_RULES", "COMPETITION_DESCRIPTION", "COMPETITION_RULES", "MODE_CONTROLS",
			"COMPETITION_ONE_LAP", "HUD_POSITION", "RACE_COMPLETE", "RACE_POSITION"]:
			assert(tr(key) != key)
	localization.apply_system_language()
	assert(change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene")) == OK)
	await process_frame
	await process_frame
	var title := current_scene
	assert(title.name == "TitleScreen")
	# Waiting longer than the old splash duration must never advance automatically.
	for frame in range(420):
		await process_frame
	assert(current_scene == title)
	assert(not title.has_node("LanguageSelector"))
	await _press(KEY_SPACE)
	assert(current_scene == title)
	await _press(KEY_ENTER, true)
	assert(current_scene == title)
	await _press(KEY_ENTER)
	await process_frame
	assert(current_scene.name == "TrackSelection")
	var setup := root.get_node("RaceSetup")
	assert(setup.TRACKS.size() == 3)
	assert(setup.TRACKS[0]["id"] == "galvez_8")
	assert(setup.TRACKS[1]["id"] == "cabalen_3")
	assert(setup.TRACKS[2]["id"] == "el_zonda")
	assert(setup.CARS.size() == 7 and setup.selected_car_index == 0)
	assert(setup.CARS[0]["id"] == "renault_fuego" and setup.CARS[1]["id"] == "prototype")
	assert(setup.CARS[2]["id"] == "ford_sierra_xr4")
	assert(setup.CARS[3]["id"] == "volkswagen_gol" and setup.CARS[4]["id"] == "peugeot_405")
	assert(setup.CARS[5]["id"] == "honda_civic" and setup.CARS[6]["id"] == "chevrolet_astra")
	for track: Dictionary in setup.TRACKS:
		var map := load(track["map"]) as Texture2D
		assert(map != null and map.get_width() > 0)
	await _press(KEY_LEFT)
	assert(setup.selected_index == 2)
	await _press(KEY_RIGHT)
	assert(setup.selected_index == 0)
	await _press(KEY_RIGHT)
	assert(setup.selected_index == 1)
	await _press(KEY_ESCAPE)
	await process_frame
	assert(current_scene.name == "TitleScreen")
	await _press(KEY_ENTER)
	await process_frame
	assert(current_scene.name == "TrackSelection")
	assert(setup.selected_index == 1)
	await _press(KEY_LEFT)
	for index in 3:
		if index > 0:
			await _press(KEY_RIGHT)
		assert(setup.selected_index == index)
		await _press(KEY_ENTER)
		await process_frame
		assert(current_scene.name == "CarSelection" and setup.confirmed)
		var selection := current_scene
		for frame in 420:
			await process_frame
		assert(current_scene == selection)
		await _press(KEY_ENTER, true)
		assert(current_scene == selection)
		await _press(KEY_SPACE)
		assert(current_scene == selection)
		var original_car: int = setup.selected_car_index
		await _press(KEY_LEFT)
		assert(setup.selected_car_index == wrapi(original_car - 1, 0, setup.CARS.size()))
		assert(current_scene._preview.scene_file_path == setup.CARS[setup.selected_car_index]["scene"])
		await _press(KEY_RIGHT, true)
		assert(setup.selected_car_index != original_car)
		await _press(KEY_ESCAPE)
		await process_frame
		assert(current_scene.name == "TrackSelection" and setup.selected_index == index and not setup.confirmed)
		await _press(KEY_ENTER)
		await process_frame
		assert(current_scene.name == "CarSelection" and setup.selected_car_index != original_car)
		await _press(KEY_RIGHT)
		assert(setup.selected_car_index == original_car)
		for car_index in setup.CARS.size():
			assert(setup.selected_car_index == car_index)
			assert(current_scene._preview.scene_file_path == setup.CARS[car_index]["scene"])
			var visible: Array[int] = current_scene.visible_car_indices()
			assert(visible == [wrapi(car_index - 1, 0, setup.CARS.size()), car_index,
				wrapi(car_index + 1, 0, setup.CARS.size())])
			await _press(KEY_KP_ENTER)
			await process_frame
			assert(current_scene.name == "ModeSelection" and setup.selected_mode_index == 0)
			var mode_selection := current_scene
			for frame in 420:
				await process_frame
			assert(current_scene == mode_selection)
			await _press(KEY_KP_ENTER)
			await process_frame
			assert(current_scene.name == "Race" and current_scene.track_id == setup.TRACKS[index]["id"])
			assert(current_scene.mode_id == "practice" and current_scene.opponents.is_empty())
			assert(current_scene.car is CharacterBody3D and current_scene.lap.route_length > 3000)
			assert(current_scene.car.model_id == setup.CARS[car_index]["id"])
			assert(current_scene.car._visual.scene_file_path == setup.CARS[car_index]["scene"])
			current_scene._retry()
			await process_frame
			await process_frame
			assert(current_scene.car.model_id == setup.CARS[car_index]["id"])
			current_scene._back_to_selection()
			await process_frame
			await process_frame
			await _press(KEY_ENTER)
			await process_frame
			assert(current_scene.name == "CarSelection" and setup.selected_car_index == car_index)
			await _press(KEY_RIGHT)
		await _press(KEY_ESCAPE)
		await process_frame
		await process_frame
	print("Smoke test passed: OS locale, Enter gates, three-card carousel, keyboard preview, mode selection, wraparound, back navigation, all seven cars on all circuits and model persistence on retry.")
	quit()
