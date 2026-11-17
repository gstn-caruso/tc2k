extends Control
## Floating arcade instruments, composed inside the same 4:3 frame as the road.

const FONT: Font = preload("res://assets/fonts/DejaVuSansMono-Bold.ttf")
const DIGITS: Font = preload("res://assets/fonts/arcade_hud.tres")
const TITLE: Font = preload("res://assets/fonts/Lato-BlackItalic.ttf")
const DESIGN_SIZE := Vector2(960, 720)
const MAP_RECT := Rect2(779, 320, 146, 182)
const GOLD := Color("ffe653")
const WHITE := Color("ffffd7")
const GREEN := Color("7bfa19")
const RED := Color("ff493e")
const INK := Color("101317")
var race: RaceController
var _layout := Transform2D.IDENTITY
var _map_transform := Transform2D.IDENTITY
var _map_line := PackedVector2Array()
var _frame: StyleBoxFlat


func _ready() -> void:
	race = get_parent() as RaceController
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame = _instrument_frame()
	_fit_map.call_deferred()


func _fit_map() -> void:
	if not race.track:
		return
	var points := race.track.path.curve.get_baked_points()
	var bounds := Rect2(Vector2(points[0].x, points[0].z), Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(Vector2(point.x, point.z))
	var factor := minf(MAP_RECT.size.x / maxf(bounds.size.x, 1.0),
		MAP_RECT.size.y / maxf(bounds.size.y, 1.0))
	_map_transform = Transform2D(0, Vector2.ONE * factor, 0,
		MAP_RECT.get_center() - bounds.get_center() * factor)
	_map_line.clear()
	for point in points:
		_map_line.append(_map_point(point))


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
	var factor := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	_layout = Transform2D(0, Vector2.ONE * factor, 0, (size - DESIGN_SIZE * factor) * 0.5)
	draw_set_transform_matrix(_layout)
	_draw_lap()
	_draw_speed()
	_draw_progress()
	_draw_inputs()
	_draw_map()
	_text(race.track_definition["hud_name"], Vector2(25, 667), 22, WHITE, TITLE)
	_text(tr(race.track_definition["variant"]), Vector2(25, 690), 13, GOLD)
	_text(tr("TIME_TRIAL_ONE_LAP"), Vector2(25, 711), 12, WHITE)
	_draw_state()
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_lap() -> void:
	_center(tr("HUD_LAP"), Vector2(103, 28), 23, WHITE, TITLE)
	_center("1/1", Vector2(103, 91), 65, WHITE, DIGITS)
	_text(tr("BEST_LAP"), Vector2(25, 129), 15, GOLD)
	_text(time_text(race.best_time), Vector2(25, 157), 23, GOLD, DIGITS)


func _draw_speed() -> void:
	_center(tr("HUD_TIME"), Vector2(480, 20), 15, WHITE, TITLE)
	# The large clock remains a lap timer; this mode has no time limit.
	var centiseconds := int(race.lap.elapsed * 100.0)
	var clock := "%02d:%02d.%02d" % [centiseconds / 6000,
		(centiseconds / 100) % 60, centiseconds % 100]
	_center(clock, Vector2(480, 72), 52, GOLD, DIGITS)
	# A curved speed scale uses actual km/h, rather than invented engine RPM.
	var maximum := race.car.tuning.top_speed * 3.6
	var ratio := clampf(race.car.speed / race.car.tuning.top_speed, 0, 1)
	var line := PackedVector2Array()
	for i in 61:
		line.append(_gauge_point(i / 60.0))
	draw_polyline(line, INK, 11, true)
	draw_polyline(line, WHITE, 4, true)
	for i in 41:
		var amount := i / 40.0
		var point := _gauge_point(amount)
		var tick := Vector2(0, 13 if i % 8 == 0 else 7)
		var color := WHITE if amount < 0.8 else RED
		draw_line(point, point + tick, INK, 7, true)
		draw_line(point, point + tick, color, 3, true)
		if i % 8 == 0:
			_center(str(roundi(amount * maximum / 10) * 10), point - Vector2(0, 10), 13, color, DIGITS)
	var needle := _gauge_point(ratio)
	draw_line(needle - Vector2(0, 6), needle + Vector2(0, 19), INK, 10, true)
	draw_line(needle - Vector2(0, 6), needle + Vector2(0, 19), GOLD, 5, true)
	_text("%03d" % roundi(race.car.speed * 3.6), Vector2(354, 199), 64, WHITE, DIGITS)
	_text(tr("HUD_SPEED_UNIT"), Vector2(477, 198), 24, WHITE, TITLE)
	var accelerating := race.car.driving_enabled and Input.get_action_strength("drive_accelerate") > 0
	var braking := race.car.driving_enabled and Input.get_action_strength("drive_brake") > 0
	var status := "HUD_BRAKE" if braking else "HUD_ACCELERATOR"
	var active := braking or accelerating
	_center(tr(status), Vector2(480, 224), 14, (RED if braking else GREEN) if active else WHITE, TITLE)


func _gauge_point(ratio: float) -> Vector2:
	return Vector2(272 + ratio * 416, 144 - sin(ratio * PI) * 39)


func _draw_progress() -> void:
	_center(tr("HUD_PROGRESS"), Vector2(841, 28), 20, WHITE, TITLE)
	var progress := clampf(race.lap.progress / maxf(race.lap.route_length, 1.0), 0, 1)
	if race.lap.finished:
		progress = 1.0
	_center("%d%%" % floori(progress * 100), Vector2(841, 91), 64, GREEN, DIGITS)


func _draw_inputs() -> void:
	var panel := Rect2(774, 112, 158, 138)
	draw_style_box(_frame, panel)
	for row in 11:
		for column in 13:
			if (row + column) % 2 == 0:
				draw_rect(Rect2(panel.position + Vector2(4 + column * 12, 4 + row * 12),
					Vector2(6, 6)), Color(0.5, 0.6, 0.7, 0.08))
	var center := Vector2(831, 180)
	var body := PackedVector2Array([
		center + Vector2(-12, -43), center + Vector2(12, -43),
		center + Vector2(17, -24), center + Vector2(17, 30),
		center + Vector2(11, 43), center + Vector2(-11, 43),
		center + Vector2(-17, 30), center + Vector2(-17, -24),
	])
	draw_colored_polygon(body, Color("a6b9c7"))
	body.append(body[0])
	draw_polyline(body, WHITE, 2, true)
	draw_rect(Rect2(center + Vector2(-11, -19), Vector2(22, 31)), Color("224359"))
	draw_line(center + Vector2(-10, -15), center + Vector2(10, -15), Color("8eeaff"), 4)
	for side in [-1.0, 1.0]:
		var front := center + Vector2(side * 22, -25)
		var wheel := Vector2(0, 10).rotated(race.car.steering * 0.5)
		draw_line(front - wheel, front + wheel, INK, 10, true)
		draw_line(front - wheel, front + wheel, GREEN, 5, true)
		draw_rect(Rect2(center + Vector2(side * 22 - 3, 21), Vector2(6, 18)), WHITE)
	var throttle := Input.get_action_strength("drive_accelerate") if race.car.driving_enabled else 0.0
	var brake := Input.get_action_strength("drive_brake") if race.car.driving_enabled else 0.0
	for i in 2:
		var bar := Rect2(883 + i * 20, 142, 9, 78)
		draw_rect(bar.grow(2), INK)
		draw_rect(bar, Color("34424a"))
		var value := throttle if i == 0 else brake
		draw_rect(Rect2(bar.position + Vector2(0, bar.size.y * (1 - value)),
			Vector2(bar.size.x, bar.size.y * value)), GREEN if i == 0 else RED)
	_center(tr("HUD_INPUTS"), Vector2(853, 273), 18, WHITE, TITLE)


func _instrument_frame() -> StyleBoxFlat:
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.025, 0.045, 0.065, 0.75)
	frame.border_color = Color("c4c9b9")
	frame.set_border_width_all(3)
	frame.set_corner_radius_all(12)
	frame.shadow_color = Color(0, 0, 0, 0.8)
	frame.shadow_size = 3
	frame.shadow_offset = Vector2(3, 3)
	return frame


func _draw_map() -> void:
	if _map_line.size() < 2:
		return
	draw_polyline(_map_line, INK, 12, true)
	draw_polyline(_map_line, Color("e1e5d4"), 5, true)
	var finish := _map_point(race.track.to_local(race.lap.finish_line.origin))
	for row in 2:
		for column in 3:
			draw_rect(Rect2(finish + Vector2(column * 4 - 6, row * 4 - 4), Vector2(4, 4)),
				WHITE if (row + column) % 2 == 0 else INK)
	var car := _map_point(race.track.to_local(race.car.global_position))
	draw_rect(Rect2(car - Vector2(9, 12), Vector2(18, 24)), INK)
	draw_rect(Rect2(car - Vector2(7, 10), Vector2(14, 20)), RED)
	_center("1", car + Vector2(0, 6), 16, WHITE, DIGITS, 1)


func _map_point(point: Vector3) -> Vector2:
	return _map_transform * Vector2(point.x, point.z)


func _draw_state() -> void:
	if race.state == RaceController.State.COUNTDOWN:
		_center(tr("READY"), Vector2(480, 312), 35, WHITE, TITLE)
		_center(str(ceili(race.countdown)), Vector2(480, 435), 126, GOLD, DIGITS, 8)
		_center(tr("DRIVING_CONTROLS"), Vector2(480, 587), 14, WHITE)
	elif race.state == RaceController.State.RACING:
		if not race.lap.started:
			_center(tr("GO"), Vector2(480, 389), 90, GREEN, TITLE, 6)
		elif race.wrong_way:
			_message(tr("WRONG_WAY"), GOLD)
		elif race.lap.invalid:
			_message(tr("LAP_INVALID"), GOLD)
		elif not race.car.on_asphalt:
			_message(tr("OFF_TRACK"), WHITE)
	elif race.state == RaceController.State.PAUSED:
		_overlay(tr("PAUSED"))
		for i in 3:
			var label := tr(["RESUME", "RETRY", "CHANGE_CIRCUIT"][i])
			var color := GOLD if i == race.pause_index else WHITE
			if i == race.pause_index:
				label = "› " + label + " ‹"
			_center(label, Vector2(480, 348 + i * 49), 25, color, TITLE)
		_center(tr("PAUSE_CONTROLS"), Vector2(480, 519), 14, WHITE)
	elif race.state == RaceController.State.FINISHED:
		_overlay(tr("LAP_COMPLETE") if not race.lap.invalid else tr("LAP_INVALID"))
		_center(time_text(race.lap.elapsed), Vector2(480, 365), 48, GOLD, DIGITS)
		var result := tr("NEW_RECORD") if race.new_record else tr("LAP_RECORDED")
		if race.lap.invalid:
			result = tr("INVALID_RECORD_NOTICE")
		_center(result, Vector2(480, 423), 18, WHITE)
		_center(tr("RESULT_CONTROLS"), Vector2(480, 498), 17, GOLD)


func _overlay(title: String) -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), Color(0.015, 0.025, 0.045, 0.68))
	var rect := Rect2(166, 232, 628, 325)
	draw_style_box(_frame, rect)
	for row in 2:
		for column in 39:
			draw_rect(Rect2(168 + column * 16, 234 + row * 8, 16, 8), WHITE if (row + column) % 2 == 0 else INK)
	_center(title, Vector2(480, 302), 39, WHITE, TITLE)


func _message(message: String, color: Color) -> void:
	_center(message, Vector2(480, 280), 22, color, TITLE)


func _text(value: String, baseline: Vector2, font_size: int, color: Color, font: Font = FONT, outline := 3) -> void:
	font.draw_string_outline(get_canvas_item(), baseline + Vector2(2, 3), value,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline + 1, Color(0, 0, 0, 0.8))
	font.draw_string_outline(get_canvas_item(), baseline, value,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline, INK)
	draw_string(font, baseline, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
	if font == DIGITS and font_size >= 40:
		draw_string(font, baseline - Vector2(0, 1), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 1, 1, 0.22))


func _center(value: String, baseline: Vector2, font_size: int, color: Color, font: Font = FONT, outline := 3) -> void:
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_text(value, baseline - Vector2(width / 2, 0), font_size, color, font, outline)
