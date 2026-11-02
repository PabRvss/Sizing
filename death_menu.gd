extends CanvasLayer

@export_file("*.tscn") var main_menu_scene: String = "res://MainMenu.tscn"

@onready var overlay: ColorRect = $Overlay
@onready var respawn_button: Button = $Overlay/CenterContainer/Panel/Margin/Buttons/RespawnButton
@onready var menu_button: Button = $Overlay/CenterContainer/Panel/Margin/Buttons/MenuButton

func _ready() -> void:
	hide()
	overlay.hide()
	respawn_button.pressed.connect(_on_respawn_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func show_death() -> void:
	show()
	overlay.show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	respawn_button.grab_focus()

func _on_respawn_pressed() -> void:
	get_tree().paused = false
	var error := get_tree().reload_current_scene()
	if error != OK:
		get_tree().paused = true
		push_error("No se pudo reiniciar el nivel: %s" % error)

func _on_menu_pressed() -> void:
	get_tree().paused = false
	var error := get_tree().change_scene_to_file(main_menu_scene)
	if error != OK:
		get_tree().paused = true
		push_error("No se pudo abrir el menú principal: %s" % error)
