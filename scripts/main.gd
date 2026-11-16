extends Control
## Original arcade artwork, drawn at a 4:3 design size with proportional letterboxing.

const DESIGN_SIZE := Vector2(960, 720)
const LOGO_FONT: Font = preload("res://assets/fonts/racing.tres")
const HUD_FONT: Font = preload("res://assets/fonts/DejaVuSansMono-Bold.ttf")
const INK := Color("101116")
const PAPER := Color("fffdf4")
const SKY := Color("65c4ed")
const GOLD := Color("edb53f")

var _elapsed := 0.0
var _transitioning := false
var _canvas_transform := Transform2D.IDENTITY


func _ready() -> void:
	resized.connect(_update_layout)
	_update_layout()


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER] and not _transitioning:
			_transitioning = true
			get_viewport().set_input_as_handled()
			_enter_track_selection.call_deferred()


func _enter_track_selection() -> void:
	if get_tree().change_scene_to_file("res://scenes/track_selection.tscn") != OK:
		_transitioning = false


func _update_layout() -> void:
	var screen_scale := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	var origin := (size - DESIGN_SIZE * screen_scale) * 0.5
	_canvas_transform = Transform2D(0.0, Vector2.ONE * screen_scale, 0.0, origin)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("070a0d"))
	draw_set_transform_matrix(_canvas_transform)
	_draw_cabinet()
	_draw_flag()
	_draw_brand("TURISMO", Vector2(103, 332), 741.0, 132)
	_draw_brand("CARRETERA", Vector2(88, 432), 792.0, 125)
	_draw_brand("2K", Vector2(594, 548), 250.0, 146)
	_draw_speed_lines()
	_hud_text(tr("ARCADE_TAGLINE"), Vector2(111, 528), 15, INK, 445.0)
	_draw_start_prompt()
	# Fine, stationary scanlines give the card a CRT texture without flashing.
	for line in range(122, 584, 3):
		draw_line(Vector2(54, line), Vector2(906, line), Color(0.0, 0.0, 0.0, 0.035))
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_cabinet() -> void:
	draw_rect(Rect2(28, 25, 904, 670), Color("030506"))
	draw_rect(Rect2(30, 27, 900, 666), Color("45494b"), false, 2.0)
	draw_rect(Rect2(36, 33, 888, 654), Color("151a1e"))
	draw_line(Vector2(40, 36), Vector2(919, 36), Color("777a79"), 2.0)
	draw_line(Vector2(39, 37), Vector2(39, 684), Color("6d706e"), 2.0)
	for line in range(44, 107, 6):
		draw_line(Vector2(49, line), Vector2(911, line), Color("383d40"), 2.0)
		draw_line(Vector2(49, line + 2), Vector2(911, line + 2), Color("080b0f"), 2.0)
	# Three narrow stripes replace the reference's colored trim with national colors.
	for edge in [110, 588]:
		draw_rect(Rect2(52, edge, 856, 4), SKY)
		draw_rect(Rect2(52, edge + 4, 856, 3), PAPER)
		draw_rect(Rect2(52, edge + 7, 856, 4), GOLD)
	draw_rect(Rect2(52, 121, 856, 463), PAPER)
	draw_rect(Rect2(52, 121, 856, 463), Color("b5b5ad"), false, 2.0)
	for index in range(6):
		var opacity := 0.055 * (1.0 - float(index) / 6.0)
		draw_rect(Rect2(54 + index, 123 + index, 852 - index * 2, 459 - index * 2),
			Color(0.0, 0.0, 0.0, opacity), false, 2.0)


func _draw_flag() -> void:
	# A waving Argentine triband with the Sun of May and a racing-checkered tail.
	var flag_origin := Vector2(362, 162)
	for row in range(4):
		for column in range(5):
			if (row + column) % 2 == 0:
				var corner := flag_origin + Vector2(191 + column * 16, 26 + row * 16)
				draw_colored_polygon(PackedVector2Array([
					corner, corner + Vector2(15, -4), corner + Vector2(11, 11), corner + Vector2(-4, 15)
				]), INK if column % 2 == 0 else SKY)
	for band in range(3):
		var points := PackedVector2Array()
		for sample in range(33):
			points.append(flag_origin + _flag_point(float(sample) * 7.0, float(band) * 21.0))
		for sample in range(32, -1, -1):
			points.append(flag_origin + _flag_point(float(sample) * 7.0, float(band + 1) * 21.0))
		draw_colored_polygon(points, SKY if band != 1 else Color.WHITE)
	var sun := flag_origin + _flag_point(108.0, 31.5)
	for ray in range(16):
		var angle := float(ray) * TAU / 16.0
		var direction := Vector2.from_angle(angle)
		draw_line(sun + direction * 7.5, sun + direction * 13.0, GOLD, 1.7, true)
	draw_circle(sun, 7.0, GOLD)
	draw_arc(sun, 5.7, 0.0, TAU, 32, Color("bc7e20"), 0.8, true)
	draw_circle(sun + Vector2(-2, -1), 0.7, Color("98691c"))
	draw_circle(sun + Vector2(2, -1), 0.7, Color("98691c"))
	draw_arc(sun + Vector2(0, 1), 2.5, 0.3, PI - 0.3, 10, Color("98691c"), 0.6, true)


func _flag_point(x: float, y: float) -> Vector2:
	var wave := sin(x / 42.0 + _elapsed * 1.8) * 4.0
	return Vector2(x - y * 0.35, y - x * 0.18 + wave)


func _draw_brand(text: String, baseline: Vector2, width: float, font_size: int) -> void:
	var natural_width := LOGO_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var stretch := Transform2D(Vector2(width / natural_width, 0), Vector2(0, 1), baseline)
	draw_set_transform_matrix(_canvas_transform * stretch)
	draw_string(LOGO_FONT, Vector2(2, 3), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.12))
	draw_string(LOGO_FONT, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, INK)
	draw_set_transform_matrix(_canvas_transform)


func _draw_speed_lines() -> void:
	for stripe in range(3):
		var y := 466.0 + stripe * 9.0
		var x := 118.0 + stripe * 15.0
		var right := 543.0 - stripe * 17.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, y), Vector2(right, y), Vector2(right - 6, y + 4), Vector2(x - 6, y + 4)
		]), SKY if stripe != 1 else GOLD)


func _draw_start_prompt() -> void:
	var text := tr("PRESS_ENTER")
	var width := HUD_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	var color := GOLD
	color.a = 0.6 + sin(_elapsed * 3.0) * 0.4
	_hud_text(text, Vector2((DESIGN_SIZE.x - width) * 0.5, 638), 24, color)
	_hud_text(tr("ARCADE_COUNTRY"), Vector2(67, 681), 12, Color("929c9f"), 640.0)
	_hud_text("TC2K", Vector2(825, 681), 19, SKY)


func _hud_text(text: String, baseline: Vector2, font_size: int, color: Color, max_width := -1.0) -> void:
	var fitted_size := font_size
	if max_width > 0:
		while fitted_size > 10 and HUD_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted_size).x > max_width:
			fitted_size -= 1
	draw_string(HUD_FONT, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted_size, color)
