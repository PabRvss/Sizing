extends Control

@export_file("*.tscn") var main_level_scene: String = "res://main.tscn"

@onready var menu_container: VBoxContainer = $MenuContainer
@onready var controls_panel: Control = $ControlsPanel
@onready var credits_panel: Control = $CreditsPanel

@onready var play_button: Button = $MenuContainer/PlayButton
@onready var controls_button: Button = $MenuContainer/ControlsButton
@onready var credits_button: Button = $MenuContainer/CreditsButton
@onready var quit_button: Button = $MenuContainer/QuitButton

@onready var close_controls_button: Button = $ControlsPanel/MarginContainer/VBoxContainer/CloseControlsButton
@onready var close_credits_button: Button = $CreditsPanel/MarginContainer/VBoxContainer/CloseCreditsButton

func _ready() -> void:
	controls_panel.hide()
	credits_panel.hide()
	menu_container.show()

	if play_button:
		play_button.pressed.connect(_on_play_button_pressed)
		play_button.grab_focus()
	if controls_button:
		controls_button.pressed.connect(_on_controls_button_pressed)
	if credits_button:
		credits_button.pressed.connect(_on_credits_button_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)

	if close_controls_button:
		close_controls_button.pressed.connect(_on_close_subpanels_pressed)
	if close_credits_button:
		close_credits_button.pressed.connect(_on_close_subpanels_pressed)

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file(main_level_scene)

func _on_controls_button_pressed() -> void:
	menu_container.hide()
	credits_panel.hide()
	controls_panel.show()
	if close_controls_button:
		close_controls_button.grab_focus()

func _on_credits_button_pressed() -> void:
	menu_container.hide()
	controls_panel.hide()
	credits_panel.show()
	if close_credits_button:
		close_credits_button.grab_focus()

func _on_close_subpanels_pressed() -> void:
	controls_panel.hide()
	credits_panel.hide()
	menu_container.show()
	if play_button:
		play_button.grab_focus()

func _on_quit_button_pressed() -> void:
	get_tree().quit()
