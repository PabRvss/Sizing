extends Camera3D

@export var target: Node3D
@export var altura: float = 14.5
@export var distancia: float = 9.0
@export var vel_rotacion: float = 2.5

var angulo_y: float = 0.58

func _physics_process(delta):
	if not target:
		target = get_node_or_null(^"../Player")
		if not target:
			return

	if Input.is_action_pressed("camera_left"):
		angulo_y += vel_rotacion * delta
	if Input.is_action_pressed("camera_right"):
		angulo_y -= vel_rotacion * delta

	var offset = Vector3(sin(angulo_y) * distancia, altura, cos(angulo_y) * distancia)
	global_position = global_position.lerp(target.global_position + offset, 6.0 * delta)
	look_at(target.global_position + Vector3(0, 0.5, 0), Vector3.UP)
