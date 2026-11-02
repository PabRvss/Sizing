extends CanvasLayer

@export_file("*.tscn") var main_menu_scene: String = "res://MainMenu.tscn"

@onready var overlay: ColorRect = $Overlay
@onready var menu_container: VBoxContainer = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer
@onready var controls_panel: Panel = $Overlay/ControlsPanel

@onready var resume_button: Button = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ResumeButton
@onready var restart_button: Button = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RestartButton
@onready var controls_button: Button = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ControlsButton
@onready var main_menu_button: Button = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/MainMenuButton
@onready var quit_button: Button = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/QuitButton

@onready var close_controls_button: Button = $Overlay/ControlsPanel/VBoxContainer/CloseControlsButton

func _ready() -> void:
	overlay.hide()
	controls_panel.hide()

	if resume_button:
		resume_button.pressed.connect(_on_resume_button_pressed)
	if restart_button:
		restart_button.pressed.connect(_on_restart_button_pressed)
	if controls_button:
		controls_button.pressed.connect(_on_controls_button_pressed)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)
	if close_controls_button:
		close_controls_button.pressed.connect(_on_close_controls_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		toggle_pause()

func toggle_pause() -> void:
	# Una pausa externa (como la muerte) solo se resuelve desde su propia pantalla.
	if get_tree().paused and not overlay.visible:
		return
	var is_paused := not get_tree().paused
	get_tree().paused = is_paused
	overlay.visible = is_paused
	controls_panel.hide()
	menu_container.get_parent().get_parent().show()

	if is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		resume_button.grab_focus()

func _on_resume_button_pressed() -> void:
	get_tree().paused = false
	overlay.hide()

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_controls_button_pressed() -> void:
	menu_container.get_parent().get_parent().hide()
	controls_panel.show()
	if close_controls_button:
		close_controls_button.grab_focus()

func _on_close_controls_pressed() -> void:
	controls_panel.hide()
	menu_container.get_parent().get_parent().show()
	resume_button.grab_focus()

func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(main_menu_scene)

func _on_quit_button_pressed() -> void:
	get_tree().quit()
