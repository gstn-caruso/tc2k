extends CarVisual
## Imported Sierra: +Z front corrected by the scene, with original wheel hubs.


func _ready() -> void:
	for wheel_name in ["Wheel_FL", "Wheel_FR", "Wheel_RL", "Wheel_RR"]:
		var wheel := find_child(wheel_name, true, false) as Node3D
		register_wheel(wheel, wheel_name in ["Wheel_FL", "Wheel_FR"])
