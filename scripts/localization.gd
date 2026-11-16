extends Node
## Follow the operating system locale on every startup.

const SUPPORTED: Array[String] = ["en", "es"]
const FALLBACK := "es"


func _ready() -> void:
	apply_system_language()


func resolve_locale(system_locale: String) -> String:
	var language := system_locale.replace("-", "_").get_slice("_", 0).to_lower()
	return language if language in SUPPORTED else FALLBACK


func apply_system_language() -> void:
	TranslationServer.set_locale(resolve_locale(OS.get_locale()))
