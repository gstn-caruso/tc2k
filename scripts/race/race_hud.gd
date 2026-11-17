extends Control
## Draw HUD at native window resolution; only the 3D world is pixel scaled.

const FONT: Font = preload("res://assets/fonts/DejaVuSansMono-Bold.ttf")
const TITLE: Font = preload("res://assets/fonts/Lato-BlackItalic.ttf")
const GOLD := Color("ffd353")
const WHITE := Color("f8f3dc")
const INK := Color("0e1d2c")
var race: RaceController
var _layout := Transform2D.IDENTITY


func _ready() -> void:
	race = get_parent() as RaceController
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


static func time_text(seconds: float) -> String:
	if seconds <= 0.0:
		return "--:--.---"
	var milliseconds := int(seconds * 1000)
	return "%02d:%02d.%03d" % [milliseconds / 60000, (milliseconds / 1000) % 60, milliseconds % 1000]


func _draw() -> void:
	if not race or not race.car:
		return
	var factor := minf(size.x / 960.0, size.y / 720.0)
	_layout = Transform2D(0, Vector2.ONE * factor, 0, (size - Vector2(960, 720) * factor) * 0.5)
	draw_set_transform_matrix(_layout)
	draw_rect(Rect2(0, 0, 960, 76), Color(0.035, 0.07, 0.11, 0.92))
	draw_rect(Rect2(0, 74, 960, 3), GOLD)
	_text("GÁLVEZ · " + tr("CIRCUIT_8"), Vector2(22, 29), 22, WHITE, TITLE)
	_text(tr("TIME_TRIAL_ONE_LAP"), Vector2(22, 57), 13, Color("92d0ec"))
	_text(tr("LAP_TIME"), Vector2(469, 26), 13, Color("92d0ec"))
	_text(time_text(race.lap.elapsed), Vector2(466, 60), 27, GOLD)
	_text(tr("BEST_LAP"), Vector2(737, 26), 13, Color("92d0ec"))
	_text(time_text(race.best_time), Vector2(734, 60), 23, WHITE)
	# Speed readout, with an arcade rev strip instead of tiny instrument details.
	draw_rect(Rect2(21, 594, 221, 83), Color(0.035, 0.07, 0.11, 0.88))
	_text("%03d" % roundi(race.car.speed * 3.6), Vector2(36, 649), 54, WHITE, TITLE)
	_text("km/h", Vector2(161, 646), 18, GOLD)
	for i in 18:
		var color := GOLD if race.car.speed / race.car.tuning.top_speed * 18 > i else Color("314455")
		draw_rect(Rect2(33 + i * 11, 661, 8, 6), color)
	_draw_map()
	draw_rect(Rect2(0, 689, 960, 31), Color(0.035, 0.07, 0.11, 0.95))
	_center(tr("DRIVING_CONTROLS"), Vector2(480, 710), 13, WHITE)
	if race.state == RaceController.State.COUNTDOWN:
		_center(tr("READY"), Vector2(480, 256), 30, WHITE, TITLE)
		_center(str(ceili(race.countdown)), Vector2(480, 380), 114, GOLD, TITLE)
	elif race.state == RaceController.State.RACING:
		if not race.lap.started:
			_center(tr("GO"), Vector2(480, 320), 72, GOLD, TITLE)
		elif race.wrong_way:
			_message(tr("WRONG_WAY"), Color("ffbd4b"))
		elif race.lap.invalid:
			_message(tr("LAP_INVALID"), Color("ffbd4b"))
		elif not race.car.on_asphalt:
			_message(tr("OFF_TRACK"), WHITE)
	elif race.state == RaceController.State.PAUSED:
		_overlay(tr("PAUSED"))
		for i in 3:
			var label := tr(["RESUME", "RETRY", "CHANGE_CIRCUIT"][i])
			var color := GOLD if i == race.pause_index else WHITE
			if i == race.pause_index:
				label = "› " + label + " ‹"
			_center(label, Vector2(480, 335 + i * 49), 25, color, TITLE)
		_center(tr("PAUSE_CONTROLS"), Vector2(480, 510), 14, WHITE)
	elif race.state == RaceController.State.FINISHED:
		_overlay(tr("LAP_COMPLETE") if not race.lap.invalid else tr("LAP_INVALID"))
		_center(time_text(race.lap.elapsed), Vector2(480, 355), 48, GOLD, TITLE)
		var result := tr("NEW_RECORD") if race.new_record else tr("LAP_RECORDED")
		if race.lap.invalid:
			result = tr("INVALID_RECORD_NOTICE")
		_center(result, Vector2(480, 411), 18, WHITE)
		_center(tr("RESULT_CONTROLS"), Vector2(480, 484), 17, GOLD)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_map() -> void:
	var rect := Rect2(756, 494, 183, 183)
	draw_rect(rect, Color(0.035, 0.07, 0.11, 0.86))
	var points := race.track.path.curve.get_baked_points()
	var polyline := PackedVector2Array()
	for point in points:
		polyline.append(_map_point(point))
	draw_polyline(polyline, Color("dedfd2"), 3.0, true)
	var next := race.lap.gates[race.lap.next_gate].origin
	draw_circle(_map_point(next), 4, GOLD)
	var car := _map_point(race.car.global_position)
	var direction := Vector2(-race.car.global_basis.z.x, -race.car.global_basis.z.z).normalized()
	var side := Vector2(-direction.y, direction.x)
	draw_colored_polygon(PackedVector2Array([car + direction * 7, car - direction * 4 + side * 4, car - direction * 4 - side * 4]), Color("7de4ff"))


func _map_point(point: Vector3) -> Vector2:
	return Vector2(770, 513) + Vector2(point.x + 550, point.z + 380) * 0.153


func _overlay(title: String) -> void:
	draw_rect(Rect2(0, 77, 960, 612), Color(0.015, 0.035, 0.065, 0.68))
	draw_rect(Rect2(180, 215, 600, 328), Color(0.035, 0.07, 0.11, 0.96))
	draw_rect(Rect2(180, 215, 600, 5), GOLD)
	_center(title, Vector2(480, 282), 39, WHITE, TITLE)


func _message(message: String, color: Color) -> void:
	draw_rect(Rect2(238, 95, 484, 35), Color(0.035, 0.07, 0.11, 0.9))
	_center(message, Vector2(480, 119), 17, color)


func _text(value: String, baseline: Vector2, font_size: int, color: Color, font: Font = FONT) -> void:
	draw_string(font, baseline, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _center(value: String, baseline: Vector2, font_size: int, color: Color, font: Font = FONT) -> void:
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_text(value, baseline - Vector2(width / 2, 0), font_size, color, font)
