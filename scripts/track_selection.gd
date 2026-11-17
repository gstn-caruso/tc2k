extends Control
## Arcade circuit selection: left/right browse, Enter confirms, Escape returns.

const DESIGN_SIZE := Vector2(960, 720)
const TITLE_FONT: Font = preload("res://assets/fonts/Lato-BlackItalic.ttf")
const HUD_FONT: Font = preload("res://assets/fonts/DejaVuSansMono-Bold.ttf")
const INK := Color("11141a")
const PAPER := Color("fffdf4")
const GOLD := Color("ffcf3e")
const SKY := Color("65c4ed")

var _canvas_transform := Transform2D.IDENTITY
var _elapsed := 0.0
var _selection_age := 0.0
var _leaving := false
var _maps: Array[Texture2D] = []


func _ready() -> void:
	for track: Dictionary in RaceSetup.TRACKS:
		_maps.append(load(track["map"]) as Texture2D)
	RaceSetup.track_confirmed.connect(_on_track_confirmed)
	resized.connect(_update_layout)
	_update_layout()


func _update_layout() -> void:
	var screen_scale := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	_canvas_transform = Transform2D(0.0, Vector2.ONE * screen_scale, 0.0,
		(size - DESIGN_SIZE * screen_scale) * 0.5)


func _process(delta: float) -> void:
	_elapsed += delta
	_selection_age += delta
	queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or _leaving:
		return
	match event.keycode:
		KEY_LEFT:
			RaceSetup.select_track(RaceSetup.selected_index - 1)
			_selection_age = 0.0
		KEY_RIGHT:
			RaceSetup.select_track(RaceSetup.selected_index + 1)
			_selection_age = 0.0
		KEY_ENTER, KEY_KP_ENTER:
			RaceSetup.confirm_track()
		KEY_ESCAPE:
			_leaving = true
			_return_to_title.call_deferred()
		_:
			return
	get_viewport().set_input_as_handled()


func _on_track_confirmed(_track_id: String) -> void:
	if not RaceSetup.TRACKS[RaceSetup.selected_index]["scene"].is_empty():
		_leaving = true
		_start_race.call_deferred()


func _start_race() -> void:
	if get_tree().change_scene_to_file("res://scenes/race/race.tscn") != OK:
		_leaving = false


func _return_to_title() -> void:
	if get_tree().change_scene_to_file("res://scenes/main.tscn") != OK:
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
	# An oversized, faint original wordmark echoes the arcade reference.
	_text("TC2K", Vector2(480, 457), TITLE_FONT, 275, Color("e8e6dc"), 830.0)
	draw_rect(Rect2(195, 58, 570, 69), INK)
	draw_rect(Rect2(199, 62, 562, 61), GOLD)
	draw_rect(Rect2(203, 66, 554, 53), Color("b92323"))
	_text(tr("SELECT_CIRCUIT"), Vector2(480, 107), TITLE_FONT, 43, PAPER, 520.0)
	for index in range(RaceSetup.TRACKS.size()):
		_draw_track(index)
	_draw_footer()
	for line in range(128, 626, 3):
		draw_line(Vector2(44, line), Vector2(916, line), Color(0, 0, 0, 0.025))
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_checkers(y: float) -> void:
	for row in range(3):
		for column in range(55):
			var color := INK if (column + row) % 2 == 0 else Color("b6bab6")
			draw_rect(Rect2(42 + column * 16, y + row * 14, 16, 14), color)


func _draw_track(index: int) -> void:
	var track: Dictionary = RaceSetup.TRACKS[index]
	var center := 192.0 + index * 288.0
	var active := index == RaceSetup.selected_index
	var card := Rect2(center - 132, 156, 264, 394)
	if active:
		draw_rect(Rect2(card.position + Vector2(5, 7), card.size), Color(0, 0, 0, 0.12))
		draw_rect(card.grow(5), GOLD)
		draw_rect(card, INK)
		draw_rect(card.grow(-3), PAPER)
	var sign := Rect2(center - 122, 168, 244, 116)
	draw_rect(sign.grow(3), Color("727a75"))
	draw_rect(sign, track["color"])
	draw_rect(sign.grow(-6), PAPER, false, 2.0)
	_text(tr(track["difficulty"]), Vector2(center, 219), TITLE_FONT, 45, PAPER, 214.0)
	_text(track["city"].to_upper(), Vector2(center, 260), HUD_FONT, 17, PAPER, 214.0)
	_draw_terrain(index, Vector2(center, 376), active)
	_text(track["name"], Vector2(center, 493), TITLE_FONT, 26, INK, 246.0)
	_text(tr(track["variant"]), Vector2(center, 521), HUD_FONT, 14, INK, 244.0)
	if active:
		var arrow_y := 559.0 + sin(_elapsed * 4.0) * 3.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(center - 24, arrow_y), Vector2(center + 24, arrow_y), Vector2(center, arrow_y + 17)
		]), Color("bb2823"))


func _draw_terrain(index: int, center: Vector2, active: bool) -> void:
	var track: Dictionary = RaceSetup.TRACKS[index]
	var angle := sin(_elapsed * 0.8) * 0.045 if active else 0.0
	var lift := sin(minf(_selection_age * 6.0, PI)) * 5.0 if active else 0.0
	var transform := Transform2D(angle, Vector2.ONE, 0.0, center - Vector2(0, lift))
	draw_set_transform_matrix(_canvas_transform * transform)
	var tile := PackedVector2Array([Vector2(-108, -67), Vector2(89, -81), Vector2(113, 63), Vector2(-91, 80)])
	var side := PackedVector2Array([tile[3], tile[2], tile[2] + Vector2(0, 13), tile[3] + Vector2(0, 13)])
	draw_colored_polygon(side, track["terrain"].darkened(0.45))
	draw_colored_polygon(tile, track["terrain"])
	# Decorative relief is a miniature terrain treatment, not survey elevation data.
	for patch in range(5):
		var origin := Vector2(-73 + patch * 34, -41 + (patch % 2) * 61)
		var radius := 17.0 + float(patch % 3) * 6.0
		var peak := origin + Vector2(0, -radius * 0.7)
		draw_colored_polygon(PackedVector2Array([
			origin + Vector2(-radius, radius * 0.45), peak, origin + Vector2(0, radius * 0.6)
		]), track["terrain"].lightened(0.13))
		draw_colored_polygon(PackedVector2Array([
			origin + Vector2(0, radius * 0.6), peak, origin + Vector2(radius, radius * 0.4)
		]), track["terrain"].darkened(0.1))
	var map: Texture2D = _maps[index]
	var extent := map.get_size()
	var ratio := minf(187.0 / extent.x, 128.0 / extent.y)
	var target := Rect2(-extent * ratio * 0.5, extent * ratio)
	draw_texture_rect(map, Rect2(target.position + Vector2(2, 3), target.size), false, INK)
	draw_texture_rect(map, target, false, Color.WHITE)
	draw_set_transform_matrix(_canvas_transform)


func _draw_footer() -> void:
	var help := tr("TRACK_CONTROLS")
	_text(help, Vector2(480, 617), HUD_FONT, 16, INK, 837.0)


func _text(value: String, baseline: Vector2, font: Font, font_size: int, color: Color, max_width: float) -> void:
	var fitted := font_size
	while fitted > 9 and font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x > max_width:
		fitted -= 1
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x
	draw_string(font, baseline - Vector2(width * 0.5, 0), value, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted, color)
