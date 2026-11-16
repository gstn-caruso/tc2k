extends Control


func _ready() -> void:
	$Center/Content.add_child(Localization.make_selector())
