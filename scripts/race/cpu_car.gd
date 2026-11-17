class_name CpuCar
extends ArcadeCar
## Steer toward a look-ahead point and brake before bends, using normal car physics.

var lane_offset := 0.0
var cruising_speed := 40.0
var traffic: Array[ArcadeCar] = []
var lap := LapTracker.new()
var previous_position := Vector3.ZERO


func _read_driving_input() -> Vector3:
	var offset := track.nearest_distance(global_position)
	lane_offset = _choose_lane(offset)
	var target := track.frame_at(offset + maxf(9.0, speed * 0.42)) * Vector3(lane_offset, 0, 0)
	var wanted := Vector3(target.x - global_position.x, 0, target.z - global_position.z).normalized()
	var forward := -global_basis.z
	forward.y = 0.0
	var angle := forward.normalized().signed_angle_to(wanted, Vector3.UP)
	var turn := clampf(-angle * 3.0, -1, 1)
	var curvature := 0.001
	for sample in [0.0, 20.0, 40.0, 65.0]:
		var here := -track.frame_at(offset + sample).basis.z
		var ahead := -track.frame_at(offset + sample + 20.0).basis.z
		here.y = 0.0
		ahead.y = 0.0
		curvature = maxf(curvature, absf(here.normalized().signed_angle_to(ahead.normalized(), Vector3.UP)) / 20.0)
	var target_speed := clampf(sqrt(5.2 / curvature), 10, cruising_speed)
	# Leave braking room behind traffic in this lane; adjacent lanes remain free.
	for other in traffic:
		if other == self:
			continue
		var relative := global_basis.inverse() * (other.global_position - global_position)
		var gap := -relative.z
		if gap > 0.0 and gap < 60.0 and absf(relative.x) < 2.3 and absf(relative.y) < 2.0:
			var braking_speed := sqrt(other.speed * other.speed + 2.0 * tuning.braking * maxf(gap - 8.0, 0.0))
			target_speed = minf(target_speed, minf(braking_speed, maxf(0.0, other.speed + gap - 7.0)))
	return Vector3(1.0 if speed < target_speed else 0.0,
		1.0 if speed > target_speed + 1.0 else 0.0, turn)


func _choose_lane(offset: float) -> float:
	var frame := track.frame_at(offset).affine_inverse()
	var local := frame * global_position
	for other in traffic:
		if other == self:
			continue
		var relative := global_basis.inverse() * (other.global_position - global_position)
		if -relative.z <= 0.0 or -relative.z > 40.0 or absf(relative.x) > 2.8 or absf(relative.y) > 2.0:
			continue
		if other.speed > minf(speed + 1.0, cruising_speed - 2.0):
			continue
		var passing_lane := -3.0 if local.x >= 0.0 else 3.0
		var clear := true
		for neighbour in traffic:
			if neighbour == self:
				continue
			var point := frame * neighbour.global_position
			if absf(point.x - passing_lane) < 2.8 and absf(point.z - local.z) < 14.0 and absf(point.y - local.y) < 2.0:
				clear = false
				break
		if clear:
			return passing_lane
	return lane_offset
