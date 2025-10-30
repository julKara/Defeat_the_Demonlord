extends Button

@onready var pause_menu: PanelContainer = $"../PauseMenu"
@onready var turn_manager: Node2D = $"../../../TileMapLayer/TurnManager"
@onready var camera_controller: Node2D = $"../../../CameraController"


func _pressed() -> void:
	# Play click sound
	AudioManager.play_sfx("Click")
	await get_tree().create_timer(0.1).timeout
	
	pause_menu.show()
	get_tree().paused = true
	# Pause game so that no more moves can be made
	turn_manager.game_is_paused = true
	camera_controller.active = false
