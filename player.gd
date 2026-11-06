extends CharacterBody3D

@export var velocidad = 5.5
@export var fuerza_salto = 6.3
@export var gravedad = 17.0
@export var lava_kill_y = -0.5
@export var tamano_inicial: float = 1.0

@onready var colision = $Colision
@onready var malla = $Malla
@onready var rayo = $Rayo
@onready var raycast_techo = $RayCastTecho
@onready var warning_label = $HUD/WarningLabel
@onready var death_menu = $DeathMenu
@onready var soporte_rifle: Node3D = $SoporteRifle
@onready var boca_rifle: Marker3D = $SoporteRifle/BocaRifle
@onready var robot: Node3D = $Malla/Robot

var player_size = 1.0
var ya_intercambio = false
var cajas_iniciales = {}
var tiempo_aviso = 0.0
var muerto: bool = false
var nivel_completado: bool = false
var esqueleto: Skeleton3D
var animador: AnimationPlayer
var animaciones: Dictionary = {}
var mano_derecha: int = -1

func _ready():
	warning_label.text = ""
	_set_tamano_player(tamano_inicial)
	_aplicar_color_robot(robot, Color(0.62, 0.62, 0.64, 1.0))
	esqueleto = _buscar_esqueleto(robot)
	if esqueleto:
		mano_derecha = esqueleto.find_bone("hand.R")
	animador = _buscar_animador(robot)
	if animador:
		for pista in animador.get_animation_list():
			for nombre in ["Idle", "Walk", "Jump"]:
				if str(pista).ends_with(nombre):
					animaciones[nombre] = pista
					if nombre != "Jump":
						animador.get_animation(pista).loop_mode = Animation.LOOP_LINEAR
		# Mantener la postura de sostener el rifle en brazos durante Walk y Jump
		if animaciones.has("Idle"):
			var anim_idle: Animation = animador.get_animation(animaciones["Idle"])
			for nombre in ["Walk", "Jump"]:
				if animaciones.has(nombre):
					var anim: Animation = animador.get_animation(animaciones[nombre])
					for t in range(anim.get_track_count()):
						var path_str := str(anim.track_get_path(t))
						var bone_name := path_str.get_slice(":", 1).to_lower()
						if "arm" in bone_name or "hand" in bone_name:
							var idle_t := anim_idle.find_track(anim.track_get_path(t), anim.track_get_type(t))
							if idle_t != -1 and anim_idle.track_get_key_count(idle_t) > 0:
								while anim.track_get_key_count(t) > 0:
									anim.track_remove_key(t, 0)
								anim.track_insert_key(t, 0.0, anim_idle.track_get_key_value(idle_t, 0))
		_reproducir_animacion("Idle")
	for caja in get_tree().get_nodes_in_group("swappable"):
		var s = float(caja.get_meta("size", 1.0))
		cajas_iniciales[caja] = {"pos": caja.position, "tam": s}
		caja.set_meta("base_y", caja.position.y - (1.25 * s) / 2.0)

func _physics_process(delta):
	if muerto:
		return
	if global_position.y < lava_kill_y:
		_morir()
		return

	var cam = get_viewport().get_camera_3d()
	var adelante = Vector3.FORWARD
	var derecha = Vector3.RIGHT
	var es_primera_persona := false
	if cam:
		if cam.get("primera_persona") == true:
			es_primera_persona = true
		adelante = -cam.global_transform.basis.z
		adelante.y = 0
		adelante = adelante.normalized()
		derecha = cam.global_transform.basis.x
		derecha.y = 0
		derecha = derecha.normalized()

	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if nivel_completado:
		input = Vector2.ZERO
	var direccion = (derecha * input.x + adelante * -input.y).normalized()

	var vel_actual = velocidad * sqrt(player_size)
	if direccion != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direccion.x * vel_actual, 30.0 * delta)
		velocity.z = move_toward(velocity.z, direccion.z * vel_actual, 30.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 25.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 25.0 * delta)

	if es_primera_persona and cam:
		var dir_cam: Vector3 = -cam.global_transform.basis.z
		dir_cam.y = 0.0
		if dir_cam != Vector3.ZERO:
			malla.rotation.y = atan2(-dir_cam.x, -dir_cam.z)
	elif direccion != Vector3.ZERO:
		malla.rotation.y = lerp_angle(malla.rotation.y, atan2(-direccion.x, -direccion.z), 15.0 * delta)

	if is_on_floor():
		if velocity.y < 0:
			velocity.y = 0
		if not nivel_completado and Input.is_action_just_pressed("jump"):
			velocity.y = fuerza_salto * sqrt(player_size)
	else:
		velocity.y -= gravedad * delta

	move_and_slide()
	_manejar_laser()

func _process(delta):
	_actualizar_animacion()
	if tiempo_aviso > 0:
		tiempo_aviso -= delta
		if tiempo_aviso <= 0:
			warning_label.text = ""

func _aplicar_color_robot(nodo: Node, color_gris: Color) -> void:
	if nodo is MeshInstance3D:
		var mat_existente = nodo.get_active_material(0)
		var mat: StandardMaterial3D
		if mat_existente is StandardMaterial3D:
			mat = mat_existente.duplicate() as StandardMaterial3D
		else:
			mat = StandardMaterial3D.new()
		mat.albedo_color = color_gris
		mat.roughness = 0.4
		nodo.set_surface_override_material(0, mat)
	for hijo in nodo.get_children():
		_aplicar_color_robot(hijo, color_gris)

func _buscar_esqueleto(nodo: Node) -> Skeleton3D:
	if nodo is Skeleton3D:
		return nodo
	for hijo in nodo.get_children():
		var encontrado := _buscar_esqueleto(hijo)
		if encontrado:
			return encontrado
	return null

func _buscar_animador(nodo: Node) -> AnimationPlayer:
	if nodo is AnimationPlayer:
		return nodo
	for hijo in nodo.get_children():
		var encontrado := _buscar_animador(hijo)
		if encontrado:
			return encontrado
	return null

func _reproducir_animacion(nombre: String) -> void:
	if animador and animaciones.has(nombre):
		var pista: StringName = animaciones[nombre]
		if animador.current_animation != pista:
			animador.play(pista, 0.15)

func _actualizar_animacion() -> void:
	var velocidad_suelo := Vector2(velocity.x, velocity.z).length()
	var caminando := is_on_floor() and velocidad_suelo > 0.2 and not nivel_completado
	var saltando := not is_on_floor() and absf(velocity.y) > 0.1
	if saltando:
		_reproducir_animacion("Jump")
	elif caminando:
		_reproducir_animacion("Walk")
	else:
		_reproducir_animacion("Idle")
	if esqueleto and mano_derecha >= 0:
		var mano_global: Vector3 = esqueleto.to_global(esqueleto.get_bone_global_pose(mano_derecha).origin)
		var offset_adelante: Vector3 = -malla.global_transform.basis.z * (0.14 * player_size)
		soporte_rifle.global_position = mano_global + offset_adelante
		soporte_rifle.rotation.y = malla.rotation.y

func _unhandled_input(_event):
	if muerto or nivel_completado:
		return
	if Input.is_action_just_pressed("interact_nearest"):
		_intercambiar_cercana()
	if Input.is_action_just_pressed("reset_level"):
		get_tree().reload_current_scene()

func completar_nivel() -> void:
	nivel_completado = true
	# Detener el desplazamiento; conservar la velocidad vertical para aterrizar.
	velocity.x = 0.0
	velocity.z = 0.0
	rayo.hide()
	warning_label.text = ""
	tiempo_aviso = 0.0

func _morir() -> void:
	if muerto:
		return
	muerto = true
	velocity = Vector3.ZERO
	rayo.hide()
	warning_label.text = ""
	death_menu.show_death()

func _manejar_laser():
	if nivel_completado:
		rayo.hide()
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		ya_intercambio = false
		rayo.visible = false
		return

	if ya_intercambio:
		rayo.visible = false
		return

	var cam = get_viewport().get_camera_3d()
	if not cam:
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var desde = cam.project_ray_origin(mouse_pos)
	var hasta = desde + cam.project_ray_normal(mouse_pos) * 100.0

	var query = PhysicsRayQueryParameters3D.create(desde, hasta)
	query.exclude = [get_rid()]
	var hit = get_world_3d().direct_space_state.intersect_ray(query)

	var punto_destino = hasta
	var objeto_tocado = null

	if not hit.is_empty():
		punto_destino = hit.position
		objeto_tocado = hit.collider

	var inicio_rayo = boca_rifle.global_position

	var los_query = PhysicsRayQueryParameters3D.create(inicio_rayo, punto_destino)
	los_query.collision_mask = 1
	los_query.exclude = [get_rid()]
	var los_hit = get_world_3d().direct_space_state.intersect_ray(los_query)

	if not los_hit.is_empty():
		punto_destino = los_hit.position

	_dibujar_laser(inicio_rayo, punto_destino)

	if objeto_tocado and objeto_tocado.is_in_group("swappable") and los_hit.is_empty():
		var vel_suelo = Vector2(velocity.x, velocity.z).length()
		if not is_on_floor() or vel_suelo > 0.2:
			return

		if global_position.distance_to(objeto_tocado.global_position) < 20.0:
			if _intercambiar_tamano(objeto_tocado):
				ya_intercambio = true
				rayo.visible = false

func _intercambiar_cercana():
	var vel_suelo = Vector2(velocity.x, velocity.z).length()
	if not is_on_floor() or vel_suelo > 0.2:
		return

	var mas_cercana = null
	var menor_dist = 6.0
	var inicio = global_position + Vector3(0, 0.9 * player_size, 0)

	for caja in cajas_iniciales.keys():
		if not is_instance_valid(caja):
			continue
		var dist = global_position.distance_to(caja.global_position)
		if dist < menor_dist:
			var query = PhysicsRayQueryParameters3D.create(inicio, caja.global_position)
			query.collision_mask = 1
			query.exclude = [get_rid(), caja.get_rid()]
			if get_world_3d().direct_space_state.intersect_ray(query).is_empty():
				mas_cercana = caja
				menor_dist = dist

	if mas_cercana != null:
		_intercambiar_tamano(mas_cercana)
	else:
		warning_label.text = "No hay cajas cerca para intercambiar."
		tiempo_aviso = 2.0

func _intercambiar_tamano(caja: StaticBody3D) -> bool:
	var tam_caja = float(caja.get_meta("size", 1.0))
	if tam_caja == player_size:
		return false

	if tam_caja > player_size and not _puede_crecer(tam_caja):
		return false

	var mi_tamano_anterior = player_size
	_set_tamano_caja(caja, mi_tamano_anterior)
	_set_tamano_player(tam_caja)
	return true

func _puede_crecer(tam: float) -> bool:
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.32 * tam * 0.98
	capsule.height = 1.8 * tam - 0.04
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(Basis(), global_position + Vector3(0, 0.9 * tam, 0))
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func _set_tamano_player(tam: float):
	player_size = tam
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.32 * tam
	capsule.height = 1.8 * tam
	colision.shape = capsule
	colision.position.y = 0.9 * tam
	malla.scale = Vector3.ONE * tam
	malla.position.y = 0.0
	soporte_rifle.position = Vector3(0.82, 0.93, -0.22) * tam
	soporte_rifle.scale = Vector3.ONE * tam
	floor_snap_length = 0.2 * tam
	raycast_techo.target_position = Vector3(0, 2.0 * tam, 0)

func _set_tamano_caja(caja: StaticBody3D, tam: float):
	caja.set_meta("size", tam)
	caja.scale = Vector3.ONE * tam
	var base_y = float(caja.get_meta("base_y", 0.0))
	caja.position.y = base_y + (1.25 * tam) / 2.0

func _dibujar_laser(desde: Vector3, hasta: Vector3):
	var local_desde = to_local(desde)
	var local_hasta = to_local(hasta)
	var mesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(local_desde)
	mesh.surface_add_vertex(local_hasta)
	mesh.surface_add_vertex(local_desde + Vector3(0.015, 0, 0))
	mesh.surface_add_vertex(local_hasta + Vector3(0.015, 0, 0))
	mesh.surface_add_vertex(local_desde + Vector3(-0.015, 0, 0))
	mesh.surface_add_vertex(local_hasta + Vector3(-0.015, 0, 0))
	mesh.surface_add_vertex(local_desde + Vector3(0, 0.015, 0))
	mesh.surface_add_vertex(local_hasta + Vector3(0, 0.015, 0))
	mesh.surface_add_vertex(local_desde + Vector3(0, -0.015, 0))
	mesh.surface_add_vertex(local_hasta + Vector3(0, -0.015, 0))
	mesh.surface_end()
	rayo.mesh = mesh
	rayo.visible = true
