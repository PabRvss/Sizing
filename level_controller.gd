extends Node3D

@export var es_nivel_2: bool = false
@export_file("*.tscn") var siguiente_nivel = "res://level_2.tscn"
@export_file("*.tscn") var menu_principal = "res://MainMenu.tscn"

@onready var panel_victoria = $VictoryUI/CenterContainer/PanelContainer
@onready var btn_siguiente = get_node_or_null("VictoryUI/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/NextLevelButton")
@onready var btn_reiniciar = get_node_or_null("VictoryUI/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RetryButton")
@onready var btn_menu = get_node_or_null("VictoryUI/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/MainMenuButton")

func _ready():
	panel_victoria.hide()
	if has_node("Environment/Meta"):
		$Environment/Meta.body_entered.connect(_on_meta_tocada)

	if btn_siguiente:
		btn_siguiente.pressed.connect(_on_siguiente_nivel)
	if btn_reiniciar:
		btn_reiniciar.pressed.connect(_on_reiniciar)
	if btn_menu:
		btn_menu.pressed.connect(_on_volver_al_menu)

func _on_meta_tocada(body):
	if body.name == "Player":
		panel_victoria.show()
		if btn_siguiente and not es_nivel_2:
			btn_siguiente.grab_focus()
		elif btn_reiniciar:
			btn_reiniciar.grab_focus()

func _on_siguiente_nivel():
	if not es_nivel_2:
		get_tree().change_scene_to_file(siguiente_nivel)

func _on_reiniciar():
	get_tree().reload_current_scene()

func _on_volver_al_menu():
	get_tree().change_scene_to_file(menu_principal)
