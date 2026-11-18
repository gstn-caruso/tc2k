extends SceneTree
## Exercise real contacts, not just the impulse calculation, in both update orders.

class TestCar extends ArcadeCar:
	var controls := Vector3.ZERO

	func _read_driving_input() -> Vector3:
		return controls


var world: Node3D


func _initialize() -> void:
	_run.call_deferred()


func _ticks(count: int) -> void:
	for i in count:
		await physics_frame
	await process_frame


func _pair(first_position: Vector3, second_position: Vector3, reverse_order := false) -> Array[TestCar]:
	world = Node3D.new()
	root.add_child(world)
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400, 1, 400)
	floor_shape.shape = box
	floor_shape.position.y = -0.5
	floor_body.add_child(floor_shape)
	world.add_child(floor_body)
	var first := TestCar.new()
	var second := TestCar.new()
	for car: TestCar in ([second, first] if reverse_order else [first, second]):
		# Avoid registering both physics bodies at the same initial position.
		car.position = first_position if car == first else second_position
		car.position.y += 0.08
		world.add_child(car)
		car.driving_enabled = true
	await _ticks(8)
	return [first, second]


func _contact(first: ArcadeCar, second: ArcadeCar) -> void:
	for tick in 60:
		await _ticks(1)
		for car in [first, second]:
			for index in car.get_slide_collision_count():
				var hit: KinematicCollision3D = car.get_slide_collision(index)
				for contact in hit.get_collision_count():
					if hit.get_collider(contact) in [first, second]:
						return
	assert(false, "The cars must actually collide during the test.")


func _rear_impact(front_speed: float, reverse_order: bool) -> void:
	var cars := await _pair(Vector3(0, 0, 4.25), Vector3.ZERO, reverse_order)
	var rear := cars[0]
	var front := cars[1]
	rear.velocity = Vector3(0, 0, -40)
	front.velocity = Vector3(0, 0, -front_speed)
	await _contact(rear, front)
	assert(rear.speed > 15.0, "A rear impact must retain forward momentum.")
	assert(front.speed > front_speed + 5.0, "The struck car must receive an impulse.")
	var momentum := -rear.velocity.z - front.velocity.z
	assert(absf(momentum - 40.0 - front_speed) < 1.0, "The impact must conserve horizontal momentum.")
	assert(rear.speed * rear.speed + front.speed * front.speed <= 1600.0 + front_speed * front_speed)
	await _ticks(30)
	assert(rear.speed > 14.0 and front.speed > 14.0, "Both cars must keep moving after contact.")
	assert(front.global_position.z < rear.global_position.z - 3.9)
	world.free()
	await _ticks(1)


func _side_swipe(reverse_order: bool) -> void:
	var cars := await _pair(Vector3(-2.0, 0, 0), Vector3.ZERO, reverse_order)
	cars[0].velocity = Vector3(7, 0, -30)
	cars[1].velocity = Vector3(0, 0, -30)
	await _contact(cars[0], cars[1])
	assert(-cars[0].velocity.z > 29.0 and -cars[1].velocity.z > 29.0,
		"A side swipe must preserve the tangential forward speed.")
	assert(cars[1].velocity.x > 1.0, "A side swipe must push the other car sideways.")
	await _ticks(30)
	assert(cars[0].speed > 28.0 and cars[1].speed > 28.0)
	world.free()
	await _ticks(1)


func _head_on(reverse_order: bool) -> void:
	var cars := await _pair(Vector3(0, 0, 4.25), Vector3.ZERO, reverse_order)
	cars[1].rotation.y = PI
	cars[0].velocity = Vector3(0, 0, -30)
	cars[1].velocity = Vector3(0, 0, 30)
	await _contact(cars[0], cars[1])
	assert(cars[0].velocity.z > 1.0 and cars[1].velocity.z < -1.0,
		"A head-on impact must produce a small separating rebound.")
	await _ticks(10)
	assert(cars[0].velocity.z > 1.0 and cars[1].velocity.z < -1.0,
		"Backward collision momentum must survive the following driving ticks.")
	assert(cars[0].speed < 4.0 and cars[1].speed < 4.0)
	cars[0].controls.x = 1.0
	cars[1].controls.y = 1.0
	await _ticks(30)
	assert(cars[0].velocity.z < -1.0 and cars[1].speed < 0.01,
		"Acceleration must recover forward drive and braking must stop the rebound.")
	world.free()
	await _ticks(1)


func _sustained_contact(reverse_order: bool) -> void:
	var cars := await _pair(Vector3(0, 0, 4.05), Vector3.ZERO, reverse_order)
	cars[0].velocity = Vector3(0, 0, -20)
	cars[1].velocity = Vector3(0, 0, -20)
	cars[0].controls.x = 1.0
	var start := cars[1].global_position
	await _contact(cars[0], cars[1])
	for tick in 120:
		await _ticks(1)
		assert(cars[0].speed > 18.0 and cars[1].speed > 18.0,
			"Sustained bumper contact must not repeatedly brake the cars.")
		assert(cars[0].speed < 40.0 and cars[1].speed < 40.0,
			"Repeated contact must not create runaway acceleration.")
	assert(start.z - cars[1].global_position.z > 38.0)
	world.free()
	await _ticks(1)


func _rail_shove(reverse_order: bool) -> void:
	var cars := await _pair(Vector3(-2.0, 0, 0), Vector3.ZERO, reverse_order)
	var rail := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.2, 2, 80)
	shape.shape = box
	rail.add_child(shape)
	rail.position = Vector3(1.05, 1, 0)
	world.add_child(rail)
	await _ticks(1)
	cars[0].velocity = Vector3(16, 0, -30)
	cars[1].velocity = Vector3(0, 0, -30)
	await _contact(cars[0], cars[1])
	var touched_rail := false
	for tick in 60:
		await _ticks(1)
		for index in cars[1].get_slide_collision_count():
			var hit := cars[1].get_slide_collision(index)
			for contact in hit.get_collision_count():
				touched_rail = touched_rail or hit.get_collider(contact) == rail
		assert(cars[1].global_position.x < 0.085, "A car impulse must not push another car through a rail.")
	assert(touched_rail, "The shove must reach the rail during the test.")
	world.free()
	await _ticks(1)


func _run() -> void:
	for reverse_order in [false, true]:
		await _rear_impact(20.0, reverse_order)
		await _rear_impact(0.0, reverse_order)
		await _side_swipe(reverse_order)
		await _head_on(reverse_order)
		await _sustained_contact(reverse_order)
		await _rail_shove(reverse_order)
	print("Car collision tests passed: moving/stationary rear impacts, momentum/energy, side swipes, head-on rebounds, pedals, sustained contact and rail shoves in both update orders.")
	quit()
