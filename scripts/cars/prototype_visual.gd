extends CarVisual
## Original blue and white prototype, retained as a selectable model.


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	return material


func _box(parent: Node3D, dimensions: Vector3, location: Vector3, material: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	part.mesh = mesh
	part.material_override = material
	part.position = location
	parent.add_child(part)
	return part


func _ready() -> void:
	var blue := _material(Color("2676c7"))
	var white := _material(Color("f4ead3"))
	var glass := _material(Color("203546"))
	var rubber := _material(Color("171e25"))
	var metal := _material(Color("b6c4c5"))
	_box(self, Vector3(1.85, 0.52, 4.2), Vector3(0, 0.6, 0), blue)
	_box(self, Vector3(1.9, 0.16, 4.25), Vector3(0, 0.38, 0), white)
	_box(self, Vector3(1.58, 0.56, 1.85), Vector3(0, 1.12, 0.15), glass)
	_box(self, Vector3(1.62, 0.09, 1.45), Vector3(0, 1.43, 0.3), white)
	_box(self, Vector3(0.35, 0.035, 1.2), Vector3(0, 0.88, -1.4), white)
	_box(self, Vector3(1.98, 0.12, 0.35), Vector3(0, 1.04, 1.9), blue)
	for side in [-1.0, 1.0]:
		_box(self, Vector3(0.05, 0.44, 0.63), Vector3(side * 0.945, 0.68, 0.15), white)
		_box(self, Vector3(0.11, 0.22, 0.45), Vector3(side * 0.81, 1.02, -0.5), blue)
		_box(self, Vector3(0.51, 0.18, 0.04), Vector3(side * 0.57, 0.68, -2.12), white)
		_box(self, Vector3(0.57, 0.17, 0.04), Vector3(side * 0.56, 0.65, 2.13), _material(Color("c63329")))
		for axle in [-1.3, 1.35]:
			var wheel := MeshInstance3D.new()
			var tyre := CylinderMesh.new()
			tyre.top_radius = 0.36
			tyre.bottom_radius = 0.36
			tyre.height = 0.28
			tyre.radial_segments = 8
			wheel.mesh = tyre
			wheel.material_override = rubber
			wheel.position = Vector3(side * 0.94, 0.36, axle)
			wheel.rotation.z = PI / 2
			add_child(wheel)
			register_wheel(wheel, axle < 0.0)
			var hub := MeshInstance3D.new()
			var hub_mesh := CylinderMesh.new()
			hub_mesh.top_radius = 0.2
			hub_mesh.bottom_radius = 0.2
			hub_mesh.height = 0.29
			hub_mesh.radial_segments = 6
			hub.mesh = hub_mesh
			hub.material_override = metal
			wheel.add_child(hub)
