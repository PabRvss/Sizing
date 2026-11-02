extends SceneTree

var failures: int = 0

func _initialize() -> void:
	run.call_deferred()

func verify(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func run() -> void:
	for number in range(1, 6):
		for size in [0.5, 1.0, 2.0]:
			var path := "res://main.tscn" if number == 1 else "res://level_%d.tscn" % number
			var level = load(path).instantiate()
			root.add_child(level)
			current_scene = level
			var player = level.get_node("Player")
			var goal = level.get_node("Environment/Meta")
			player.set_physics_process(false)
			player._set_tamano_player(size)
			player.position = goal.global_position + Vector3(0, 0.35, 0)
			await physics_frame
			verify(not goal.puede_completar(player), "No completar en el aire")
			player.muerto = true
			verify(not goal.puede_completar(player), "No completar muerto")
			player.muerto = false
			for frame in range(60):
				await physics_frame
				player.velocity.y -= player.gravedad / Engine.physics_ticks_per_second
				player.move_and_slide()
				if player.nivel_completado:
					break
			verify(player.nivel_completado and level.panel_victoria.visible, "Aterrizar activa victoria")
			verify(not goal.puede_completar(player), "No duplicar victoria")
			verify(level.btn_siguiente.visible != level.es_nivel_final, "Siguiente solo en niveles intermedios")
			print("META_REVISADA nivel=", number, " tamaño=", size)
			level.queue_free()
			await process_frame
			await physics_frame
	print("GOAL_FAILURES=", failures)
	quit(0 if failures == 0 else 1)
