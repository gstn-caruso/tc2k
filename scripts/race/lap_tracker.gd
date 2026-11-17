class_name LapTracker
extends RefCounted
## Continuous route progress, with a swept, directional start/finish line.
## Leaving the asphalt never creates a checkpoint the driver has to recover.

var finish_line := Transform3D.IDENTITY
var half_width := 18.0
var route_length := 0.0
var progress := 0.0
var started := false
var finished := false
var invalid := false
var elapsed := 0.0
var _previous_distance := 0.0


func advance(previous: Vector3, current: Vector3, delta: float, route_distance: float) -> void:
	if finished:
		return
	if started:
		elapsed += delta
		if route_length > 0.0:
			var step := wrapf(route_distance - _previous_distance, -route_length * 0.5, route_length * 0.5)
			# A nearest-point jump to a neighbouring sector is not distance driven.
			if absf(step) <= maxf(5.0, previous.distance_to(current) * 3.0):
				progress += step
		finished = route_length > 0.0 and progress >= route_length * 0.9 and crosses_forward(previous, current, finish_line, half_width)
	elif crosses_forward(previous, current, finish_line, half_width):
		started = true
		elapsed = 0.0
	_previous_distance = route_distance


func relocate(route_distance: float) -> void:
	# Repositioning must not add lap progress or introduce a discontinuity.
	_previous_distance = route_distance


static func crosses_forward(previous: Vector3, current: Vector3, gate: Transform3D, width: float) -> bool:
	var a := gate.affine_inverse() * previous
	var b := gate.affine_inverse() * current
	if a.z <= 0.0 or b.z > 0.0:
		return false
	var crossing := a.lerp(b, a.z / (a.z - b.z))
	return absf(crossing.x) <= width and crossing.y >= -0.5 and crossing.y <= 3.0
