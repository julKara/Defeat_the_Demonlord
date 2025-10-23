extends PanelContainer

@onready var world_handler: Node = $"../../../WorldHandler"

var current_world

func _ready() -> void:
	current_world = world_handler.world_script.current_world


# Return to level select and unlock next level
func _on_continue_pressed() -> void:
	
	# Unpause game
	get_tree().paused = false
	
	# Return to level select
	var level_select: String = "res://src/Worlds/World_" + str(current_world) + "/world_" + str(current_world) + "_level_select.tscn" # Filepath to selected level
	
	# Save level progression
	world_handler._save_game()
	
	# If the filepath is valid, change scene to the selected level
	if FileAccess.file_exists(level_select):
		get_tree().change_scene_to_file(level_select)
