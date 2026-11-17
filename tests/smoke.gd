extends SceneTree
## Verify OS language, the Enter gate, keyboard browsing and circuit confirmation.


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
	for track: Dictionary in setup.TRACKS:
		var map := load(track["map"]) as Texture2D
		assert(map != null and map.get_width() > 0)
	await _press(KEY_LEFT)
	assert(setup.selected_index == 2)
	await _press(KEY_RIGHT)
	assert(setup.selected_index == 0)
	await _press(KEY_RIGHT)
	assert(setup.selected_index == 1)
	await _press(KEY_ENTER)
	assert(setup.confirmed)
	assert(current_scene.name == "TrackSelection")
	await _press(KEY_RIGHT)
	assert(setup.selected_index == 2)
	assert(not setup.confirmed)
	await _press(KEY_ESCAPE)
	await process_frame
	assert(current_scene.name == "TitleScreen")
	await _press(KEY_ENTER)
	await process_frame
	assert(current_scene.name == "TrackSelection")
	assert(setup.selected_index == 2)
	await _press(KEY_LEFT)
	await _press(KEY_LEFT)
	await _press(KEY_ENTER)
	await process_frame
	assert(current_scene.name == "Race")
	assert(current_scene.track.name == "Galvez8")
	assert(current_scene.car is CharacterBody3D)
	assert(current_scene.track.gates().size() > 30)
	print("Smoke test passed: OS locale, Enter-only title, arrow navigation, unavailable tracks, back navigation and playable Gálvez transition.")
	quit()
