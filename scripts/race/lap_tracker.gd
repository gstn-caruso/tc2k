class_name LapTracker
extends RefCounted
## Swept, directional gates: a fast car cannot tunnel past a thin Area3D.
## Gate 0 is the start/finish; all others must be crossed in order.

var gates: Array[Transform3D] = []
var half_width := 9.0
var next_gate := 0
var last_gate := -1
var started := false
var finished := false
var invalid := false
var elapsed := 0.0


func advance(previous: Vector3, current: Vector3, delta: float) -> void:
	if finished:
		return
	if started:
		elapsed += delta
	if gates.is_empty() or not crosses_forward(previous, current, gates[next_gate], half_width):
		return
	last_gate = next_gate
	if next_gate == 0 and started:
		finished = true
		return
	if next_gate == 0:
		started = true
		elapsed = 0.0
	next_gate = (next_gate + 1) % gates.size()


static func crosses_forward(previous: Vector3, current: Vector3, gate: Transform3D, width: float) -> bool:
	var a := gate.affine_inverse() * previous
	var b := gate.affine_inverse() * current
	if a.z <= 0.0 or b.z > 0.0:
		return false
	var crossing := a.lerp(b, a.z / (a.z - b.z))
	return absf(crossing.x) <= width and crossing.y >= -0.5 and crossing.y <= 3.0
