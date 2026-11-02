extends Node3D

const SPEED := 5.5
const ACCELERATION := 30.0
const FRICTION := 25.0
const GRAVITY := 17.0
const JUMP := 6.3
const BOX_SIDE := 1.25

@export_file("*.tscn") var next_level_scene: String = "res://level_2.tscn"
@export var is_final_level: bool = false
@export var lava_kill_y: float = -0.5

# Parámetros para vista aérea pronunciada (la cámara mira desde arriba para evitar obstrucción de muros)
@export var cam_radius: float = 9.0
@export var cam_height: float = 14.5
const CAM_ROT_SPEED := 2.5

@onready var player: CharacterBody3D = $Jugador
@onready var player_collision: CollisionShape3D = $Jugador/Colision
@onready var player_visual: MeshInstance3D = $Jugador/Malla
@onready var camera: Camera3D = $Camara
@onready var status: Label = get_node_or_null("Interfaz/Estado")
@onready var beam: MeshInstance3D = $Rayo

# Modal de Victoria
@onready var victory_panel: Control = $Interfaz/VictoriaPanel
@onready var next_level_button: Button = $Interfaz/VictoriaPanel/MarginContainer/VBoxContainer/NextLevelButton
@onready var retry_button: Button = $Interfaz/VictoriaPanel/MarginContainer/VBoxContainer/RetryButton
@onready var main_menu_button: Button = get_node_or_null("Interfaz/VictoriaPanel/MarginContainer/VBoxContainer/MainMenuButton")

var player_size := 1.0
var beam_time := 0.0
var won := false
var spawn_position := Vector3.ZERO
var initial_boxes: Dictionary = {}
var cam_angle := 0.578
var is_swap_locked := false
var warning_time := 0.0

func _ready() -> void:
	spawn_position = player.position

	# Inicializar ángulo horizontal de la cámara respecto al jugador
	var offset := camera.position - player.position
	if Vector2(offset.x, offset.z).length() > 0.1:
		cam_angle = atan2(offset.x, offset.z)

	# Registrar dinámicamente todas las cajas del grupo "swappable"
	for node in get_tree().get_nodes_in_group("swappable"):
		if node is StaticBody3D:
			var s := float(node.get_meta("size", 1.0))
			initial_boxes[node] = {"position": node.position, "size": s}
			node.set_meta("base_y", node.position.y - BOX_SIDE * s / 2.0)

	if has_node("Meta"):
		$Meta.body_entered.connect(_on_goal_entered)

	if victory_panel:
		victory_panel.hide()
	if next_level_button:
		next_level_button.pressed.connect(_on_next_level_pressed)
		if is_final_level:
			next_level_button.text = "Volver a Jugar (Nivel 1)"
	if retry_button:
		retry_button.pressed.connect(_reset_level)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)

	if status:
		status.text = ""

func _physics_process(delta: float) -> void:
	# Reinicio mediante acción única (evita el spam de R)
	if Input.is_action_just_pressed("reset_level"):
		_reset_level()
		return

	# Control de cámara aérea (flechas izquierda / derecha)
	var cam_rot_input := 0.0
	if Input.is_action_pressed("camera_left") or Input.is_key_pressed(KEY_LEFT):
		cam_rot_input += 1.0
	if Input.is_action_pressed("camera_right") or Input.is_key_pressed(KEY_RIGHT):
		cam_rot_input -= 1.0
	cam_angle += cam_rot_input * CAM_ROT_SPEED * delta

	# Movimiento del personaje relativo a la vista aérea de la cámara
	var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	var cam_forward := -camera.global_transform.basis.z
	cam_forward.y = 0.0
	cam_forward = cam_forward.normalized()
	
	var cam_right := camera.global_transform.basis.x
	cam_right.y = 0.0
	cam_right = cam_right.normalized()

	var move_dir := (cam_right * input_vec.x + cam_forward * (-input_vec.y))
	if move_dir.length() > 0.1:
		move_dir = move_dir.normalized()

	var current_speed := SPEED * sqrt(player_size)
	if move_dir.length() > 0.1:
		player.velocity.x = move_toward(player.velocity.x, move_dir.x * current_speed, ACCELERATION * delta)
		player.velocity.z = move_toward(player.velocity.z, move_dir.z * current_speed, ACCELERATION * delta)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, FRICTION * delta)
		player.velocity.z = move_toward(player.velocity.z, 0.0, FRICTION * delta)

	# Salto y Gravedad
	if player.is_on_floor():
		if player.velocity.y < 0.0:
			player.velocity.y = 0.0
		if Input.is_action_just_pressed("jump"):
			player.velocity.y = JUMP * sqrt(player_size)
	else:
		player.velocity.y -= GRAVITY * delta

	player.move_and_slide()

	# Detección de caída al vacío o lava
	if player.position.y < lava_kill_y:
		_reset_level()
		return

	# Proceso continuo del láser mientras se mantenga presionado el clic
	_process_continuous_laser()

func _process(delta: float) -> void:
	# Seguimiento orbital aéreo suave con ángulo pronunciado (evita que las paredes tapen)
	var orbit_offset := Vector3(sin(cam_angle) * cam_radius, cam_height, cos(cam_angle) * cam_radius)
	var desired := player.position + orbit_offset
	camera.position = camera.position.lerp(desired, minf(delta * 6.0, 1.0))
	camera.look_at(player.position + Vector3(0, 0.5, 0), Vector3.UP)

	# Temporizador para disparos de tecla E
	if beam_time > 0.0:
		beam_time -= delta
		if beam_time <= 0.0 and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			beam.visible = false

	# Temporizador para el aviso de tecla E
	if warning_time > 0.0:
		warning_time -= delta
		if warning_time <= 0.0 and status:
			status.text = ""

func _unhandled_input(_event: InputEvent) -> void:
	if won:
		return
	
	if Input.is_action_just_pressed("interact_nearest"):
		_swap_nearest()

# Gestión del láser visible continuo mientras se mantiene presionado el clic
func _process_continuous_laser() -> void:
	if won:
		beam.visible = false
		return

	var is_clicking := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	
	if not is_clicking:
		is_swap_locked = false
		if beam_time <= 0.0:
			beam.visible = false
		return

	if is_swap_locked:
		beam.visible = false
		return

	var mouse_pos := get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)
	var end := origin + ray_dir * 100.0

	var space_state := get_world_3d().direct_space_state
	var cam_query := PhysicsRayQueryParameters3D.create(origin, end)
	cam_query.exclude = [player.get_rid()]
	var cam_hit := space_state.intersect_ray(cam_query)

	var target_point: Vector3
	var hit_collider: Object = null

	if cam_hit.is_empty():
		target_point = origin + ray_dir * 30.0
	else:
		target_point = cam_hit["position"]
		hit_collider = cam_hit["collider"]

	# Origen del láser en el cuerpo del jugador
	var beam_start := player.global_position + Vector3(0, 0.9 * player_size, 0)

	# Raycast desde el jugador hacia el punto objetivo para que el láser se detenga en muros físicos
	var player_los_query := PhysicsRayQueryParameters3D.create(beam_start, target_point)
	player_los_query.collision_mask = 1 # Capa 1: Entorno/Muros/Barreras
	player_los_query.exclude = [player.get_rid()]
	var los_hit := space_state.intersect_ray(player_los_query)

	var final_laser_end: Vector3
	var wall_blocked := false

	if not los_hit.is_empty():
		final_laser_end = los_hit["position"]
		wall_blocked = true
	else:
		final_laser_end = target_point

	# El rayo es visible de forma continua mientras se mantenga presionado el clic
	_draw_laser(beam_start, final_laser_end)

	# Si toca un objeto intercambiable y no hay muro en medio
	if hit_collider is StaticBody3D and hit_collider.is_in_group("swappable") and not wall_blocked:
		var horizontal_speed := Vector2(player.velocity.x, player.velocity.z).length()
		if not player.is_on_floor() or horizontal_speed > 0.2:
			return

		if player.global_position.distance_to(hit_collider.global_position) < 22.0:
			if _swap(hit_collider):
				is_swap_locked = true
				beam.visible = false

func _swap_nearest() -> void:
	var horizontal_speed := Vector2(player.velocity.x, player.velocity.z).length()
	if not player.is_on_floor() or horizontal_speed > 0.2:
		return

	var nearest: StaticBody3D = null
	var best := 6.5
	var player_eye := player.global_position + Vector3(0, 0.9 * player_size, 0)

	for candidate in initial_boxes.keys():
		var dist := player.global_position.distance_to(candidate.global_position)
		if dist < best:
			var los_query := PhysicsRayQueryParameters3D.create(player_eye, candidate.global_position)
			los_query.collision_mask = 1
			los_query.exclude = [player.get_rid(), candidate.get_rid()]
			var los_hit := get_world_3d().direct_space_state.intersect_ray(los_query)
			if los_hit.is_empty():
				nearest = candidate
				best = dist

	if nearest != null:
		_draw_laser(player_eye, nearest.global_position)
		beam_time = 0.35
		_swap(nearest)
	else:
		_show_e_warning("No hay cajas cerca para intercambiar.")

func _show_e_warning(msg: String) -> void:
	if status:
		status.text = msg
		warning_time = 2.0

func _swap(target: StaticBody3D) -> bool:
	var previous := player_size
	var incoming: float = target.get_meta("size")
	if is_equal_approx(previous, incoming):
		return false

	# REGLA DE COLISIÓN: Si el jugador va a crecer, verificar que tenga espacio vertical libre
	if incoming > previous and not _can_grow_to(incoming):
		return false

	_set_box_size(target, previous)
	_set_player_size(incoming)
	return true

func _can_grow_to(new_size: float) -> bool:
	var space_state := get_world_3d().direct_space_state
	var test_capsule := CapsuleShape3D.new()
	test_capsule.radius = 0.32 * new_size * 0.92
	test_capsule.height = 1.8 * new_size * 0.92
	
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = test_capsule
	params.transform = Transform3D(Basis(), player.global_position + Vector3(0, 0.9 * new_size, 0))
	params.collision_mask = 1
	params.exclude = [player.get_rid()]
	
	var hits := space_state.intersect_shape(params, 1)
	return hits.is_empty()

func _set_player_size(value: float) -> void:
	player_size = value
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32 * value
	capsule.height = 1.8 * value
	player_collision.shape = capsule
	player_collision.position.y = 0.9 * value
	player_visual.scale = Vector3.ONE * value
	player_visual.position.y = 0.9 * value
	player.floor_snap_length = 0.2 * value
	player.velocity.y = maxf(player.velocity.y, 0.0)

func _set_box_size(box: StaticBody3D, value: float) -> void:
	box.set_meta("size", value)
	box.scale = Vector3.ONE * value
	box.position.y = float(box.get_meta("base_y", 0.0)) + BOX_SIDE * value / 2.0

func _draw_laser(start: Vector3, finish: Vector3) -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var offsets := [
		Vector3.ZERO,
		Vector3(0.025, 0, 0), Vector3(-0.025, 0, 0),
		Vector3(0, 0.025, 0), Vector3(0, -0.025, 0),
		Vector3(0, 0, 0.025), Vector3(0, 0, -0.025)
	]
	for off in offsets:
		mesh.surface_add_vertex(start + off)
		mesh.surface_add_vertex(finish + off)
	mesh.surface_end()
	beam.mesh = mesh
	beam.visible = true

func _reset_level() -> void:
	player.position = spawn_position
	player.velocity = Vector3.ZERO
	_set_player_size(1.0)
	for box in initial_boxes:
		_set_box_size(box, initial_boxes[box]["size"])
		box.position = initial_boxes[box]["position"]
	won = false
	is_swap_locked = false
	beam.visible = false
	warning_time = 0.0
	if status:
		status.text = ""
	if victory_panel:
		victory_panel.hide()

func _on_goal_entered(body: Node3D) -> void:
	if body == player and not won:
		won = true
		beam.visible = false
		if status:
			status.text = ""
		if victory_panel:
			victory_panel.show()
			if next_level_button:
				next_level_button.grab_focus()

func _on_next_level_pressed() -> void:
	if is_final_level:
		get_tree().change_scene_to_file("res://main.tscn")
	elif next_level_scene != "":
		get_tree().change_scene_to_file(next_level_scene)

func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://MainMenu.tscn")
