extends Node3D

@export var nivel_numero: int = 0
@export var es_nivel_final: bool = false
@export_file("*.tscn") var siguiente_nivel = "res://level_2.tscn"
@export_file("*.tscn") var menu_principal = "res://MainMenu.tscn"

@onready var panel_victoria = $VictoryUI/CenterContainer/PanelContainer
@onready var contenedor_victoria = $VictoryUI/CenterContainer
@onready var meta = $Environment/Meta
@onready var btn_siguiente = get_node_or_null("VictoryUI/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/NextLevelButton")
@onready var btn_reiniciar = get_node_or_null("VictoryUI/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RetryButton")
@onready var btn_menu = get_node_or_null("VictoryUI/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/MainMenuButton")
@onready var label_coleccionable = get_node_or_null("VictoryUI/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CollectibleLabel")

func _ready():
	contenedor_victoria.hide()
	panel_victoria.hide()
	if btn_siguiente and es_nivel_final:
		btn_siguiente.hide()

	if btn_siguiente:
		btn_siguiente.pressed.connect(_on_siguiente_nivel)
	if btn_reiniciar:
		btn_reiniciar.pressed.connect(_on_reiniciar)
	if btn_menu:
		btn_menu.pressed.connect(_on_volver_al_menu)

func _physics_process(_delta: float) -> void:
	if meta.puede_completar($Player):
		$Player.completar_nivel()
		if label_coleccionable:
			var n = _determinar_numero_nivel()
			var recogido = Moneda.esta_recogida(n)
			var total = Moneda.total_recogidas()
			if recogido:
				label_coleccionable.text = "🪙 Coleccionable: ¡Obtenido! (Total: %d/5)" % total
			else:
				label_coleccionable.text = "🪙 Coleccionable: No encontrado (Total: %d/5)" % total
		contenedor_victoria.show()
		panel_victoria.show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if btn_siguiente and not es_nivel_final:
			btn_siguiente.grab_focus()
		elif btn_reiniciar:
			btn_reiniciar.grab_focus()

func _determinar_numero_nivel() -> int:
	if nivel_numero > 0:
		return nivel_numero
	var n_str: String = name.to_lower()
	if n_str == "main":
		return 1
	var num: int = n_str.replace("level_", "").replace("level", "").to_int()
	if num > 0:
		return num
	if scene_file_path != "":
		var base = scene_file_path.get_file().get_basename()
		if base == "main":
			return 1
		var fnum = base.replace("level_", "").to_int()
		if fnum > 0:
			return fnum
	return 1

func _on_siguiente_nivel():
	if not es_nivel_final:
		get_tree().change_scene_to_file(siguiente_nivel)

func _on_reiniciar():
	get_tree().reload_current_scene()

func _on_volver_al_menu():
	get_tree().change_scene_to_file(menu_principal)
