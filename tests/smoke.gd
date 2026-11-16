extends SceneTree
## Exercise the entry scene and persisted language settings in an isolated user directory.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var localization := root.get_node("Localization")
	assert(TranslationServer.get_locale() == "es")
	assert(tr("WELCOME") == "¡Bienvenido!")
	assert(localization.set_language("en"))
	assert(tr("WELCOME") == "Welcome!")
	assert(not localization.set_language("unsupported"))
	assert(TranslationServer.get_locale() == "en")
	var settings := ConfigFile.new()
	assert(settings.load("user://settings.cfg") == OK)
	assert(settings.get_value("interface", "language") == "en")
	TranslationServer.set_locale("es")
	localization.load_language()
	assert(TranslationServer.get_locale() == "en")
	assert(localization.set_language("es"))
	assert(change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene")) == OK)
	await process_frame
	await process_frame
	var selector := current_scene.get_node("Center/Content/LanguageSelector") as OptionButton
	assert(selector != null)
	assert(selector.selected == 1)
	selector.select(0)
	selector.item_selected.emit(0)
	await process_frame
	assert(TranslationServer.get_locale() == "en")
	print("Smoke test passed: main scene, translations and persisted language preference.")
	quit()
