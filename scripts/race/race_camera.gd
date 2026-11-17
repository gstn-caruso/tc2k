class_name RaceCamera
extends Camera3D
## Elevated chase camera with a stable horizon and speed-dependent look-ahead.

@export var height := 8.5
@export var distance := 15.0
@export var look_ahead := 15.0
@export var follow_rate := 6.0
var car: ArcadeCar
var _heading := Vector3.FORWARD


func snap() -> void:
	_heading = -car.global_basis.z
	_update_camera(1.0, true)


func _process(delta: float) -> void:
	if car:
		_update_camera(delta, false)


func _update_camera(delta: float, instant: bool) -> void:
	var weight := 1.0 if instant else 1.0 - exp(-follow_rate * delta)
	_heading = _heading.lerp(-car.global_basis.z, weight).normalized()
	var target := car.global_position - _heading * (distance + car.speed * 0.06) + Vector3.UP * height
	global_position = target if instant else global_position.lerp(target, weight)
	look_at(car.global_position + _heading * (look_ahead + car.speed * 0.13) + Vector3.UP * 0.6, Vector3.UP)
