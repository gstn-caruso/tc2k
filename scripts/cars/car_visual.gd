class_name CarVisual
extends Node3D
## Shared visual contract: metre scale, ground-level origin and front along -Z.

@export var wheel_radius := 0.36
@export var wheel_spin_direction := -1.0
var _front_wheels: Array[Node3D] = []
var _wheel_meshes: Array[Node3D] = []
var _wheel_rest: Array[Basis] = []
var _wheel_angle := 0.0


func register_wheel(wheel: Node3D, front: bool) -> void:
	# A separate steering pivot keeps rolling around the axle after turning.
	var pivot := Node3D.new()
	pivot.name = wheel.name + "Steering"
	pivot.position = wheel.position
	wheel.get_parent().add_child(pivot)
	wheel.reparent(pivot, false)
	wheel.position = Vector3.ZERO
	_wheel_meshes.append(wheel)
	_wheel_rest.append(wheel.basis)
	if front:
		_front_wheels.append(pivot)


func update_wheels(steering_angle: float, distance: float) -> void:
	_wheel_angle = fposmod(_wheel_angle + distance / wheel_radius * wheel_spin_direction, TAU)
	for pivot in _front_wheels:
		pivot.rotation.y = -steering_angle
	for index in _wheel_meshes.size():
		_wheel_meshes[index].basis = Basis(Vector3.RIGHT, _wheel_angle) * _wheel_rest[index]
