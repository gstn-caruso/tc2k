@tool
class_name CircuitTrack
extends Node3D
## Edit Centerline's Curve3D, then bake once with the inspector button or tools/bake_track.gd.
## Runtime only samples the route; it never rebuilds meshes or drives the car along it.

const ROAD_WIDTH := 14.0
const ROAD_SURFACE_HEIGHT := 0.05
@export_tool_button("Bake track geometry") var bake_action: Callable = rebuild
@onready var path: Path3D = $Centerline
# Dummy/headless rendering cannot serialize MultiMesh server buffers. Keep the
# source transforms as scene data so headless and editor bakes agree visually.
@export_storage var tree_poses: Array[Transform3D] = []
@export_storage var tree_colors: PackedColorArray = []


func _ready() -> void:
	if has_node("Generated/Trees"):
		var trees := get_node("Generated/Trees") as MultiMeshInstance3D
		for i in tree_poses.size():
			trees.multimesh.set_instance_transform(i, tree_poses[i])
			trees.multimesh.set_instance_color(i, tree_colors[i])


func frame_at(distance: float) -> Transform3D:
	var curve := ($Centerline as Path3D).curve
	var length := curve.get_baked_length()
	var offset := fposmod(distance, length)
	var point := curve.sample_baked(offset, true)
	var direction := (curve.sample_baked(fposmod(offset + 1, length), true) - curve.sample_baked(fposmod(offset - 1, length), true)).normalized()
	return Transform3D(Basis.looking_at(direction, Vector3.UP), point)


func is_on_road(point: Vector3) -> bool:
	var local_point := to_local(point)
	var closest := path.curve.get_closest_point(local_point)
	return Vector2(closest.x - local_point.x, closest.z - local_point.z).length() <= ROAD_WIDTH * 0.5 + 0.9


func nearest_distance(point: Vector3) -> float:
	return path.curve.get_closest_offset(to_local(point))


func _material(color: Color, vertex_color := false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.vertex_color_use_as_albedo = vertex_color
	mat.roughness = 1.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


func _mesh(parent: Node3D, mesh: Mesh, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	parent.add_child(node)
	return node


func _box(parent: Node3D, dimensions: Vector3, pose: Transform3D, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var node := _mesh(parent, mesh, mat)
	node.transform = pose
	return node


func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> void:
	for point in [a, b, c, c, b, d]:
		surface.set_color(color)
		surface.set_normal(Vector3.UP)
		surface.add_vertex(point)


func _strip(parent: Node3D, edge_a: float, edge_b: float, height: float, color: Color, alternate := false) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var length := ($Centerline as Path3D).curve.get_baked_length()
	var steps := ceili(length / 6.0)
	for i in steps:
		var a := frame_at(length * i / steps)
		var b := frame_at(length * (i + 1) / steps)
		var tint := Color("f7eed7") if alternate and (i / 2) % 2 == 0 else color
		_quad(surface, a * Vector3(edge_a, height, 0), a * Vector3(edge_b, height, 0), b * Vector3(edge_a, height, 0), b * Vector3(edge_b, height, 0), tint)
	return _mesh(parent, surface.commit(), _material(Color.WHITE, true))


func rebuild() -> void:
	if has_node("Generated"):
		var old := get_node("Generated")
		remove_child(old)
		old.free()
	var generated := Node3D.new()
	generated.name = "Generated"
	add_child(generated)
	_build_ground(generated)
	_strip(generated, -11.5, 11.5, 0.015, Color("b1a37e"))
	var asphalt := _strip(generated, -7.0, 7.0, ROAD_SURFACE_HEIGHT, Color("515761"))
	asphalt.name = "Asphalt"
	var road_body := StaticBody3D.new()
	road_body.name = "RoadCollision"
	generated.add_child(road_body)
	var road_shape := CollisionShape3D.new()
	road_shape.shape = asphalt.mesh.create_trimesh_shape()
	(road_shape.shape as ConcavePolygonShape3D).backface_collision = true
	# Raise only the visual road to avoid z-fighting; collision meets the grass.
	road_shape.position.y = -ROAD_SURFACE_HEIGHT
	road_body.add_child(road_shape)
	_strip(generated, -8.1, -7.0, 0.065, Color("c43f34"), true)
	_strip(generated, 7.0, 8.1, 0.065, Color("c43f34"), true)
	_strip(generated, -6.9, -6.65, 0.07, Color("f0e9d3"))
	_strip(generated, 6.65, 6.9, 0.07, Color("f0e9d3"))
	_build_rails(generated)
	_build_paddock(generated)
	_build_trees(generated)
	_set_owners(generated)


func _set_owners(node: Node) -> void:
	node.owner = self
	for child in node.get_children():
		_set_owners(child)


func _build_ground(parent: Node3D) -> void:
	var ground := StaticBody3D.new()
	ground.name = "Terrain"
	parent.add_child(ground)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1900, 2, 1700)
	shape.shape = box
	shape.position.y = -1.0
	ground.add_child(shape)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2408
	for x in range(-10, 10):
		for z in range(-9, 9):
			var p := Vector3(x * 95, -0.005, z * 95)
			var color := Color("71965e").darkened(rng.randf_range(0, 0.09))
			_quad(surface, p, p + Vector3(95, 0, 0), p + Vector3(0, 0, 95), p + Vector3(95, 0, 95), color)
	_mesh(ground, surface.commit(), _material(Color.WHITE, true))


func _build_rails(parent: Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = "Guardrails"
	parent.add_child(body)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var length := ($Centerline as Path3D).curve.get_baked_length()
	var steps := ceili(length / 14)
	for i in steps:
		var a := frame_at(length * i / steps)
		var b := frame_at(length * (i + 1) / steps)
		for side in [-1.0, 1.0]:
			var p := a * Vector3(side * 18, 0, 0)
			var q := b * Vector3(side * 18, 0, 0)
			var color := Color("d9dfd9") if (i / 4) % 2 == 0 else Color("508eaf")
			_quad(surface, p + Vector3.UP * 0.35, q + Vector3.UP * 0.35, p + Vector3.UP * 1.05, q + Vector3.UP * 1.05, color)
			var collision := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(0.5, 1.2, p.distance_to(q) + 0.3)
			collision.shape = box
			collision.transform = Transform3D(Basis.looking_at((q - p).normalized(), Vector3.UP), (p + q) * 0.5 + Vector3.UP * 0.6)
			body.add_child(collision)
	_mesh(body, surface.commit(), _material(Color.WHITE, true))


func _build_paddock(parent: Node3D) -> void:
	var white := _material(Color("e2e2ce"))
	var blue := _material(Color("2e729a"))
	var dark := _material(Color("344959"))
	var gold := _material(Color("eec85a"))
	var start := frame_at(0)
	for side in [-1.0, 1.0]:
		_box(parent, Vector3(0.8, 7, 0.8), start * Transform3D(Basis.IDENTITY, Vector3(side * 9.5, 3.5, 0)), white)
	_box(parent, Vector3(20, 1.8, 0.8), start * Transform3D(Basis.IDENTITY, Vector3(0, 7.1, 0)), blue)
	_box(parent, Vector3(20, 0.35, 0.85), start * Transform3D(Basis.IDENTITY, Vector3(0, 6.2, 0)), gold)
	# Start line and grid boxes stay separate from the road collision surface.
	for row in 2:
		for column in 14:
			var color := dark if (row + column) % 2 == 0 else white
			_box(parent, Vector3(1, 0.015, 1), start * Transform3D(Basis.IDENTITY, Vector3(column - 6.5, 0.082, row - 0.5)), color)
	for i in 5:
		var frame := frame_at(35.0 + i * 24)
		_box(parent, Vector3(15, 5, 20), frame * Transform3D(Basis.IDENTITY, Vector3(32, 2.5, 0)), white)
		_box(parent, Vector3(17, 0.5, 22), frame * Transform3D(Basis.IDENTITY, Vector3(32, 5.25, 0)), blue)
		_box(parent, Vector3(0.2, 3, 15), frame * Transform3D(Basis.IDENTITY, Vector3(24.4, 1.5, 0)), dark)
		for step in 5:
			_box(parent, Vector3(2.8, 0.7 + step * 0.7, 20), frame * Transform3D(Basis.IDENTITY, Vector3(-25.0 - step * 2.8, (0.7 + step * 0.7) / 2, 0)), blue if step % 2 == 0 else white)
		_box(parent, Vector3(17, 0.35, 22), frame * Transform3D(Basis.IDENTITY, Vector3(-31, 7, 0)), white)
		_box(parent, Vector3(0.35, 7, 0.35), frame * Transform3D(Basis.IDENTITY, Vector3(-39, 3.5, -8)), dark)
		_box(parent, Vector3(0.35, 7, 0.35), frame * Transform3D(Basis.IDENTITY, Vector3(-39, 3.5, 8)), dark)
	# Argentine colours, without borrowing sponsor graphics.
	for i in 3:
		_box(parent, Vector3(0.08, 0.8, 4), start * Transform3D(Basis.IDENTITY, Vector3(11, 5.2 + i * 0.8, -5)), white if i == 1 else blue)
	_box(parent, Vector3(0.15, 8, 0.15), start * Transform3D(Basis.IDENTITY, Vector3(11, 4, -3)), dark)


func _build_trees(parent: Node3D) -> void:
	tree_poses.clear()
	tree_colors.clear()
	var leaves := MultiMesh.new()
	leaves.transform_format = MultiMesh.TRANSFORM_3D
	leaves.use_colors = true
	var cone := CylinderMesh.new()
	cone.top_radius = 0.6
	cone.bottom_radius = 4.5
	cone.height = 9
	cone.radial_segments = 5
	leaves.mesh = cone
	leaves.instance_count = 270
	var rng := RandomNumberGenerator.new()
	rng.seed = 850
	var length := ($Centerline as Path3D).curve.get_baked_length()
	for i in leaves.instance_count:
		var distance := length * i / leaves.instance_count
		var frame := frame_at(distance)
		var side := -1.0 if i % 2 == 0 else 1.0
		var p := frame * Vector3(side * rng.randf_range(43, 88), 5.0, 0)
		# Keep neighbouring sectors and paddock clear.
		var near := ($Centerline as Path3D).curve.get_closest_point(p)
		if Vector2(near.x - p.x, near.z - p.z).length() < 22 or (distance < 210 and side < 0):
			p.y = -30
		var scale_factor := rng.randf_range(0.7, 1.45)
		if p.y >= 0:
			p.y = cone.height * 0.5 * scale_factor
		var pose := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * scale_factor), p)
		var color := Color("3d6d49").lightened(rng.randf_range(0, 0.18))
		tree_poses.append(pose)
		tree_colors.append(color)
		leaves.set_instance_transform(i, pose)
		leaves.set_instance_color(i, color)
	var trees := MultiMeshInstance3D.new()
	trees.name = "Trees"
	trees.multimesh = leaves
	trees.material_override = _material(Color.WHITE, true)
	parent.add_child(trees)
