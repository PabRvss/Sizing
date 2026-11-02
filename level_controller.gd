extends Node3D

@export var es_nivel_final: bool = false
@export_file("*.tscn") var siguiente_nivel = "res://level_2.tscn"
@export_file("*.tscn") var menu_principal = "res://MainMenu.tscn"

@onready var panel_victoria = $VictoryUI/CenterContainer/PanelContainer
@onready var contenedor_victoria = $VictoryUI/CenterContainer
@onready var meta = $Environment/Meta
@onready var btn_siguiente = get_node_or_null("VictoryUI/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/NextLevelButton")
@onready var btn_reiniciar = get_node_or_null("VictoryUI/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RetryButton")
@onready var btn_menu = get_node_or_null("VictoryUI/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/MainMenuButton")

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
		contenedor_victoria.show()
		panel_victoria.show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if btn_siguiente and not es_nivel_final:
			btn_siguiente.grab_focus()
		elif btn_reiniciar:
			btn_reiniciar.grab_focus()

func _on_siguiente_nivel():
	if not es_nivel_final:
		get_tree().change_scene_to_file(siguiente_nivel)

func _on_reiniciar():
	get_tree().reload_current_scene()

func _on_volver_al_menu():
	get_tree().change_scene_to_file(menu_principal)
