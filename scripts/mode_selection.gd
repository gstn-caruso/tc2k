extends Control
## Explicit keyboard confirmation keeps every setup screen under player control.

const DESIGN_SIZE := Vector2(960, 720)
const TITLE_FONT: Font = preload("res://assets/fonts/Lato-BlackItalic.ttf")
const HUD_FONT: Font = preload("res://assets/fonts/DejaVuSansMono-Bold.ttf")
const INK := Color("11141a")
const PAPER := Color("fffdf4")
const GOLD := Color("ffcf3e")
const SKY := Color("65c4ed")

var _canvas_transform := Transform2D.IDENTITY
var _leaving := false


func _ready() -> void:
	RaceSetup.mode_confirmed.connect(_on_mode_confirmed)
	resized.connect(_update_layout)
	_update_layout()


func _update_layout() -> void:
	var factor := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	_canvas_transform = Transform2D(0.0, Vector2.ONE * factor, 0.0,
		(size - DESIGN_SIZE * factor) * 0.5)
	queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or _leaving:
		return
	if event.is_action_pressed("menu_left"):
		RaceSetup.select_mode(RaceSetup.selected_mode_index - 1)
	elif event.is_action_pressed("menu_right"):
		RaceSetup.select_mode(RaceSetup.selected_mode_index + 1)
	elif event.is_action_pressed("menu_confirm"):
		RaceSetup.confirm_mode()
	elif event.is_action_pressed("menu_back"):
		_leaving = true
		_change_scene.call_deferred("res://scenes/car_selection.tscn")
	else:
		return
	get_viewport().set_input_as_handled()
	queue_redraw()


func _on_mode_confirmed(_mode_id: String) -> void:
	_leaving = true
	_change_scene.call_deferred("res://scenes/race/race.tscn")


func _change_scene(scene: String) -> void:
	if get_tree().change_scene_to_file(scene) != OK:
		_leaving = false


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("070a0d"))
	draw_set_transform_matrix(_canvas_transform)
	draw_rect(Rect2(28, 25, 904, 670), INK)
	draw_rect(Rect2(30, 27, 900, 666), Color("64696b"), false, 2.0)
	draw_rect(Rect2(42, 42, 876, 636), PAPER)
	for y in [42, 636]:
		for row in 3:
			for column in 55:
				draw_rect(Rect2(42 + column * 16, y + row * 14, 16, 14),
					INK if (row + column) % 2 == 0 else Color("b6bab6"))
	draw_rect(Rect2(42, 90, 876, 4), SKY)
	draw_rect(Rect2(42, 96, 876, 4), GOLD)
	draw_rect(Rect2(42, 628, 876, 4), GOLD)
	draw_rect(Rect2(195, 58, 570, 69), INK)
	draw_rect(Rect2(199, 62, 562, 61), GOLD)
	draw_rect(Rect2(203, 66, 554, 53), Color("b92323"))
	_text(tr("SELECT_MODE"), Vector2(480, 107), TITLE_FONT, 43, PAPER, 520.0)
	var track: Dictionary = RaceSetup.TRACKS[RaceSetup.selected_index]
	var car: Dictionary = RaceSetup.CARS[RaceSetup.selected_car_index]
	_text(track["name"] + " · " + tr(car["name"]), Vector2(480, 157), HUD_FONT, 15, INK, 790.0)
	for index in RaceSetup.MODES.size():
		_draw_mode(index)
	_text(tr("MODE_CONTROLS"), Vector2(480, 617), HUD_FONT, 16, INK, 837.0)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_mode(index: int) -> void:
	var definition: Dictionary = RaceSetup.MODES[index]
	var center := 270.0 + index * 420.0
	var active := index == RaceSetup.selected_mode_index
	var card := Rect2(center - 193, 191, 386, 376)
	draw_rect(Rect2(card.position + Vector2(5, 7), card.size), Color(0, 0, 0, 0.12))
	draw_rect(card.grow(4), GOLD if active else Color("b6bab6"))
	draw_rect(card, INK if active else Color("e8e6dc"))
	var art := Rect2(center - 179, 205, 358, 204)
	draw_rect(art, Color("243d4e"))
	for side in [-1.0, 1.0]:
		draw_line(Vector2(center + side * 116, 211), Vector2(center + side * 116, 403), PAPER, 3)
	for stripe in 5:
		draw_rect(Rect2(center - 2, 215 + stripe * 42, 4, 22), GOLD)
	if definition["id"] == "practice":
		_draw_car(Vector2(center, 308), GOLD, "1")
	else:
		_draw_car(Vector2(center - 57, 258), SKY, "2")
		_draw_car(Vector2(center + 57, 258), Color("e5634e"), "3")
		_draw_car(Vector2(center - 57, 354), Color("79b870"), "4")
		_draw_car(Vector2(center + 57, 354), GOLD, "1")
	_text(tr(definition["name"]), Vector2(center, 452), TITLE_FONT, 32, PAPER if active else INK, 354.0)
	_text(tr(definition["description"]), Vector2(center, 493), HUD_FONT, 16,
		GOLD if active else Color("53595c"), 350.0)
	_text(tr(definition["rules"]), Vector2(center, 528), HUD_FONT, 14,
		PAPER if active else INK, 350.0)
	if active:
		draw_colored_polygon(PackedVector2Array([
			Vector2(center - 19, 579), Vector2(center + 19, 579), Vector2(center, 595)
		]), Color("bb2823"))


func _draw_car(center: Vector2, color: Color, number: String) -> void:
	for side in [-1.0, 1.0]:
		for axle in [-24.0, 25.0]:
			draw_rect(Rect2(center + Vector2(side * 23 - 5, axle - 9), Vector2(10, 18)), INK)
	draw_rect(Rect2(center - Vector2(21, 40), Vector2(42, 80)), color)
	draw_rect(Rect2(center + Vector2(-16, -15), Vector2(32, 22)), Color("152a38"))
	draw_rect(Rect2(center + Vector2(-15, 21), Vector2(30, 9)), Color("152a38"))
	_text(number, center + Vector2(0, 21), HUD_FONT, 16, PAPER, 35.0)


func _text(value: String, baseline: Vector2, font: Font, font_size: int, color: Color, max_width: float) -> void:
	var fitted := font_size
	while fitted > 9 and font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x > max_width:
		fitted -= 1
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x
	draw_string(font, baseline - Vector2(width * 0.5, 0), value, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted, color)
