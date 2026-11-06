extends Camera3D

@export var target: Node3D
@export var altura: float = 14.5
@export var distancia: float = 9.0
@export var vel_rotacion: float = 2.5

var angulo_y: float = 0.58
var primera_persona: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("toggle_camera_view"):
		primera_persona = not primera_persona
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_C or event.keycode == KEY_C:
			primera_persona = not primera_persona

func _physics_process(delta):
	if not target:
		target = get_node_or_null(^"../Player")
		if not target:
			return

	if Input.is_action_pressed("camera_left"):
		angulo_y += vel_rotacion * delta
	if Input.is_action_pressed("camera_right"):
		angulo_y -= vel_rotacion * delta

	var dir_frente := Vector3(-sin(angulo_y), 0.0, -cos(angulo_y)).normalized()

	if primera_persona:
		var p_size: float = float(target.get("player_size")) if "player_size" in target else 1.0
		# Situar la cámara a la altura de la cabeza/ojos del personaje
		var pos_ojos := target.global_position + Vector3(0.0, 1.25 * p_size, 0.0) + dir_frente * (0.35 * p_size)
		global_position = pos_ojos
		# Rotación estrictamente horizontal (sin inclinación vertical)
		look_at(pos_ojos + dir_frente, Vector3.UP)
	else:
		var offset := Vector3(sin(angulo_y) * distancia, altura, cos(angulo_y) * distancia)
		global_position = global_position.lerp(target.global_position + offset, 6.0 * delta)
		look_at(target.global_position + Vector3(0, 0.5, 0), Vector3.UP)

