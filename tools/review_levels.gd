extends SceneTree

var player: CharacterBody3D
var level: Node3D
var failures: int = 0

func _initialize() -> void:
	run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
	else:
		print("OK: ", message)

func move_to(target: Vector3, jump: bool = false) -> bool:
	if jump:
		player.velocity.y = player.fuerza_salto * sqrt(player.player_size)
	for frame in range(240):
		await physics_frame
		var delta := 1.0 / Engine.physics_ticks_per_second
		var offset := Vector2(target.x - player.position.x, target.z - player.position.z)
		var speed: float = player.velocidad * sqrt(player.player_size)
		var desired := offset.normalized() * minf(speed, offset.length() * 10.0)
		player.velocity.x = move_toward(player.velocity.x, desired.x, 30.0 * delta)
		player.velocity.z = move_toward(player.velocity.z, desired.y, 30.0 * delta)
		if not player.is_on_floor() or player.velocity.y > 0.0:
			player.velocity.y -= player.gravedad * delta
		else:
			player.velocity.y = 0
		player.move_and_slide()
		if player.position.y < -2.0:
			return false
		if frame > 3 and player.is_on_floor() and offset.length() < 0.15 and absf(player.position.y - target.y) < 0.15:
			player.velocity = Vector3.ZERO
			return true
	return false

func swap_box(name: String) -> void:
	var box = level.get_node("Environment/" + name)
	var eye := player.global_position + Vector3(0, 0.9 * player.player_size, 0)
	var query := PhysicsRayQueryParameters3D.create(eye, box.global_position, 1)
	query.exclude = [player.get_rid(), box.get_rid()]
	check(player.get_world_3d().direct_space_state.intersect_ray(query).is_empty(), "Visión libre hacia " + name)
	check(player.global_position.distance_to(box.global_position) < 6.0, "Alcance E hacia " + name)
	check(player._intercambiar_tamano(box), "Intercambio con " + name)

func run() -> void:
	for number in [4, 5]:
		level = load("res://level_%d.tscn" % number).instantiate()
		root.add_child(level)
		current_scene = level
		player = level.get_node("Player")
		player.set_physics_process(false)
		await physics_frame
		await physics_frame
		var gate: float = 1 if number == 4 else -12
		var base: float = 0 if number == 4 else 1.7
		if number == 5:
			check(await move_to(Vector3(0, 0, 6.5)), "Nivel 5: inicio")
			swap_box("CajaPequena")
			check(await move_to(Vector3(0, 0, 0)), "Nivel 5: cruzar túnel pequeño")
			swap_box("CajaGrande")
			check(await move_to(Vector3(0, 0, -3.3)), "Nivel 5: preparar salto grande")
			check(await move_to(Vector3(0, 1.7, -9), true), "Nivel 5: salto a isla elevada")
		check(await move_to(Vector3(2, base, gate + 1.8)), "Acercarse al paso, nivel %d" % number)
		check(is_equal_approx(player.player_size, 2.0), "Llegar grande al puzle")
		swap_box("CajaEscalon")
		check(await move_to(Vector3(-1.2, base, gate + 2.5)), "Acercarse a caja normal")
		swap_box("CajaNormal")
		check(await move_to(Vector3(-2, base, gate - 0.4)), "Cruzar paso con tamaño normal")
		check(not player._puede_crecer(2.0), "El paso impide crecer a tamaño 2")
		check(await move_to(Vector3(-2, base, gate - 1.1)), "Preparar escalera")
		check(await move_to(Vector3(-2, base + 0.8, gate - 2.6), true), "Salto al apoyo bajo")
		check(await move_to(Vector3(0, base + 1.6, gate - 3), true), "Salto al apoyo alto")
		check(await move_to(Vector3(2, base + 2.5, gate - 3), true), "Salto a la caja agrandada")
		check(await move_to(Vector3(2, base + 2.5, gate - 3.7)), "Preparar salto a salida")
		check(await move_to(Vector3(2, base + 3.4, gate - 5.8), true), "Salto a la salida elevada")
		if number == 5:
			check(await move_to(Vector3(0, 5.1, -20.5)), "Nivel 5: preparar salto final")
			check(await move_to(Vector3(0, 5.1, -23.8), true), "Nivel 5: aterrizar en isla final")
			check(await move_to(Vector3(0, 5.1, -25.5)), "Nivel 5: llegar a meta")
		else:
			check(await move_to(Vector3(0, 3.4, gate - 7.5)), "Nivel 4: llegar a meta")
		check(player.nivel_completado and level.panel_victoria.visible, "Meta activa y victoria visible")
		level.queue_free()
		await process_frame
		await physics_frame
	print("REVIEW_FAILURES=", failures)
	quit(0 if failures == 0 else 1)
