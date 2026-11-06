extends Camera3D

@export var target: Node3D
@export var altura: float = 14.5
@export var distancia: float = 9.0
@export var vel_rotacion: float = 2.5

var angulo_y: float = 0.58
var angulo_pitch: float = 0.0
var primera_persona: bool = false

func _ready() -> void:
	# Distancia cercana reducida para evitar ver dentro de las texturas/mallas al acercarse
	near = 0.01

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("toggle_camera_view"):
		primera_persona = not primera_persona
		if primera_persona:
			angulo_pitch = 0.0
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_C or event.keycode == KEY_C:
			primera_persona = not primera_persona
			if primera_persona:
				angulo_pitch = 0.0

func _physics_process(delta):
	if not target:
		target = get_node_or_null(^"../Player")
		if not target:
			return

	if Input.is_action_pressed("camera_left") or Input.is_key_pressed(KEY_LEFT):
		angulo_y += vel_rotacion * delta
	if Input.is_action_pressed("camera_right") or Input.is_key_pressed(KEY_RIGHT):
		angulo_y -= vel_rotacion * delta

	var dir_frente_h := Vector3(-sin(angulo_y), 0.0, -cos(angulo_y)).normalized()

	if primera_persona:
		if Input.is_action_pressed("camera_up") or Input.is_key_pressed(KEY_UP):
			angulo_pitch = minf(angulo_pitch + vel_rotacion * delta, deg_to_rad(80.0))
		if Input.is_action_pressed("camera_down") or Input.is_key_pressed(KEY_DOWN):
			angulo_pitch = maxf(angulo_pitch - vel_rotacion * delta, deg_to_rad(-80.0))

		var cos_p := cos(angulo_pitch)
		var sin_p := sin(angulo_pitch)
		var dir_frente := Vector3(-sin(angulo_y) * cos_p, sin_p, -cos(angulo_y) * cos_p).normalized()

		var p_size: float = float(target.get("player_size")) if "player_size" in target else 1.0
		var pos_cabeza: Vector3 = target.global_position + Vector3(0.0, 1.25 * p_size, 0.0)

		# Comprobar colisión hacia el frente para evitar atravesar paredes o cajas
		var dist_adelante: float = 0.18 * p_size
		var espacio = get_world_3d().direct_space_state
		var check_dest: Vector3 = pos_cabeza + dir_frente * (dist_adelante + 0.15)
		var rayo = PhysicsRayQueryParameters3D.create(pos_cabeza, check_dest)
		rayo.exclude = [target.get_rid()]
		rayo.collision_mask = 1 | 2
		var hit = espacio.intersect_ray(rayo)
		if not hit.is_empty():
			var hit_dist: float = pos_cabeza.distance_to(hit.position)
			dist_adelante = minf(dist_adelante, maxf(0.0, hit_dist - 0.06))

		var pos_ojos: Vector3 = pos_cabeza + dir_frente_h * dist_adelante
		global_position = pos_ojos
		look_at(pos_ojos + dir_frente, Vector3.UP)
	else:
		var offset := Vector3(sin(angulo_y) * distancia, altura, cos(angulo_y) * distancia)
		var pos_ideal: Vector3 = target.global_position + offset
		var espacio = get_world_3d().direct_space_state
		var origen_3p: Vector3 = target.global_position + Vector3(0.0, 1.0, 0.0)
		var rayo_3p = PhysicsRayQueryParameters3D.create(origen_3p, pos_ideal)
		rayo_3p.exclude = [target.get_rid()]
		rayo_3p.collision_mask = 1 | 2
		var hit_3p = espacio.intersect_ray(rayo_3p)
		if not hit_3p.is_empty():
			var dir_to_cam: Vector3 = (pos_ideal - origen_3p).normalized()
			pos_ideal = hit_3p.position - dir_to_cam * 0.15
		global_position = global_position.lerp(pos_ideal, 6.0 * delta)
		look_at(target.global_position + Vector3(0, 0.5, 0), Vector3.UP)


