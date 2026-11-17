extends Control
## Keyboard model selection with a live preview of the same scene used in races.

const DESIGN_SIZE := Vector2(960, 720)
const PREVIEW_RECT := Rect2(72, 180, 816, 306)
const TITLE_FONT: Font = preload("res://assets/fonts/Lato-BlackItalic.ttf")
const HUD_FONT: Font = preload("res://assets/fonts/DejaVuSansMono-Bold.ttf")
const INK := Color("11141a")
const PAPER := Color("fffdf4")
const GOLD := Color("ffcf3e")
const SKY := Color("65c4ed")

var _canvas_transform := Transform2D.IDENTITY
var _leaving := false
var _turntable: Node3D
var _preview: CarVisual


func _ready() -> void:
	_build_studio()
	_show_car()
	RaceSetup.car_confirmed.connect(_on_car_confirmed)
	resized.connect(_update_layout)
	_update_layout()


func _update_layout() -> void:
	var factor := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	_canvas_transform = Transform2D(0.0, Vector2.ONE * factor, 0.0,
		(size - DESIGN_SIZE * factor) * 0.5)
	$PreviewImage.position = _canvas_transform * PREVIEW_RECT.position
	$PreviewImage.size = PREVIEW_RECT.size * factor
	queue_redraw()


func _build_studio() -> void:
	var viewport := $PreviewViewport as SubViewport
	var world := Node3D.new()
	viewport.add_child(world)
	_turntable = Node3D.new()
	world.add_child(_turntable)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("142a3d")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("c6d5e3")
	settings.ambient_light_energy = 0.7
	environment.environment = settings
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -35, 0)
	light.light_color = Color("ffefd1")
	light.light_energy = 1.2
	world.add_child(light)
	var platform := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 3.1
	disc.bottom_radius = 3.1
	disc.height = 0.12
	disc.radial_segments = 48
	platform.mesh = disc
	platform.position.y = -0.065
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("33495a")
	material.roughness = 0.85
	platform.material_override = material
	world.add_child(platform)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(3.8, 2.3, -4.8)
	camera.fov = 34
	camera.look_at(Vector3(0, 0.55, 0))
	camera.current = true
	($PreviewImage as TextureRect).texture = viewport.get_texture()


func _show_car() -> void:
	if _preview:
		_turntable.remove_child(_preview)
		_preview.queue_free()
	var definition: Dictionary = RaceSetup.CARS[RaceSetup.selected_car_index]
	_preview = (load(definition["scene"]) as PackedScene).instantiate() as CarVisual
	_turntable.add_child(_preview)
	_turntable.rotation.y = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	_turntable.rotate_y(delta * 0.3)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or _leaving:
		return
	if event.is_action_pressed("menu_left"):
		RaceSetup.select_car(RaceSetup.selected_car_index - 1)
		_show_car()
	elif event.is_action_pressed("menu_right"):
		RaceSetup.select_car(RaceSetup.selected_car_index + 1)
		_show_car()
	elif event.is_action_pressed("menu_confirm"):
		RaceSetup.confirm_car()
	elif event.is_action_pressed("menu_back"):
		_leaving = true
		_back_to_circuits.call_deferred()
	else:
		return
	get_viewport().set_input_as_handled()


func _on_car_confirmed(_car_id: String) -> void:
	_leaving = true
	_start_race.call_deferred()


func _start_race() -> void:
	if get_tree().change_scene_to_file("res://scenes/race/race.tscn") != OK:
		_leaving = false


func _back_to_circuits() -> void:
	RaceSetup.confirmed = false
	if get_tree().change_scene_to_file("res://scenes/track_selection.tscn") != OK:
		_leaving = false


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("070a0d"))
	draw_set_transform_matrix(_canvas_transform)
	draw_rect(Rect2(28, 25, 904, 670), INK)
	draw_rect(Rect2(30, 27, 900, 666), Color("64696b"), false, 2.0)
	draw_rect(Rect2(42, 42, 876, 636), PAPER)
	_draw_checkers(42.0)
	_draw_checkers(636.0)
	draw_rect(Rect2(42, 90, 876, 4), SKY)
	draw_rect(Rect2(42, 96, 876, 4), GOLD)
	draw_rect(Rect2(42, 628, 876, 4), GOLD)
	draw_rect(Rect2(195, 58, 570, 69), INK)
	draw_rect(Rect2(199, 62, 562, 61), GOLD)
	draw_rect(Rect2(203, 66, 554, 53), Color("b92323"))
	_text(tr("SELECT_CAR"), Vector2(480, 107), TITLE_FONT, 43, PAPER, 520.0)
	var track: Dictionary = RaceSetup.TRACKS[RaceSetup.selected_index]
	_text(track["name"] + " · " + tr(track["variant"]), Vector2(480, 158), HUD_FONT, 15, INK, 790.0)
	draw_rect(PREVIEW_RECT.grow(4), INK)
	draw_rect(PREVIEW_RECT.grow(2), SKY, false, 2.0)
	var count := RaceSetup.CARS.size()
	var card_width := minf(360.0, 740.0 / count)
	for index in count:
		var definition: Dictionary = RaceSetup.CARS[index]
		var center := 480.0 + (index - (count - 1) * 0.5) * (card_width + 12.0)
		var card := Rect2(center - card_width * 0.5, 506, card_width, 65)
		var active := index == RaceSetup.selected_car_index
		draw_rect(card.grow(3), GOLD if active else Color("b6bab6"))
		draw_rect(card, INK if active else Color("e8e6dc"))
		draw_rect(Rect2(card.position, Vector2(5, card.size.y)), definition["color"])
		_text(tr(definition["name"]), Vector2(center, 535), TITLE_FONT, 27,
			PAPER if active else INK, card_width - 24.0)
		_text(tr(definition["description"]), Vector2(center, 557), HUD_FONT, 11,
			GOLD if active else Color("53595c"), card_width - 24.0)
	for side in [-1.0, 1.0]:
		var center := Vector2(480 + side * 410, 539)
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(side * 13, 0), center + Vector2(-side * 8, -15), center + Vector2(-side * 8, 15)
		]), Color("bb2823"))
	_text(tr("CAR_COUNT") % [RaceSetup.selected_car_index + 1, count], Vector2(480, 597), HUD_FONT, 13, INK, 800.0)
	_text(tr("CAR_CONTROLS"), Vector2(480, 617), HUD_FONT, 16, INK, 837.0)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_checkers(y: float) -> void:
	for row in 3:
		for column in 55:
			var color := INK if (column + row) % 2 == 0 else Color("b6bab6")
			draw_rect(Rect2(42 + column * 16, y + row * 14, 16, 14), color)


func _text(value: String, baseline: Vector2, font: Font, font_size: int, color: Color, max_width: float) -> void:
	var fitted := font_size
	while fitted > 9 and font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x > max_width:
		fitted -= 1
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x
	draw_string(font, baseline - Vector2(width * 0.5, 0), value, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted, color)
