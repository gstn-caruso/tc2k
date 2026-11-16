extends Node
## Store the language preference separately from game saves.

const SUPPORTED: Array[String] = ["en", "es"]
const FALLBACK := "es"
var storage_path := "user://settings.cfg"


func _ready() -> void:
	load_language()


func load_language() -> void:
	var settings := ConfigFile.new()
	var locale := FALLBACK
	if settings.load(storage_path) == OK:
		var stored: Variant = settings.get_value("interface", "language", FALLBACK)
		if stored is String and stored in SUPPORTED:
			locale = stored
	TranslationServer.set_locale(locale)


func set_language(locale: String) -> bool:
	if locale not in SUPPORTED:
		return false
	var settings := ConfigFile.new()
	settings.set_value("interface", "language", locale)
	if settings.save(storage_path) != OK:
		return false
	TranslationServer.set_locale(locale)
	return true


func make_selector() -> OptionButton:
	var selector := OptionButton.new()
	selector.name = "LanguageSelector"
	selector.add_item("English")
	selector.add_item("Español")
	selector.select(SUPPORTED.find(TranslationServer.get_locale()))
	selector.tooltip_text = "LANGUAGE"
	selector.item_selected.connect(func(index: int) -> void:
		if not set_language(SUPPORTED[index]):
			selector.select(SUPPORTED.find(TranslationServer.get_locale()))
			var dialog := AcceptDialog.new()
			dialog.title = tr("ERROR_TITLE")
			dialog.dialog_text = tr("ERROR_LANGUAGE_SAVE")
			dialog.ok_button_text = tr("OK")
			selector.add_child(dialog)
			dialog.confirmed.connect(dialog.queue_free)
			dialog.canceled.connect(dialog.queue_free)
			dialog.popup_centered(Vector2i(420, 160))
	)
	return selector
