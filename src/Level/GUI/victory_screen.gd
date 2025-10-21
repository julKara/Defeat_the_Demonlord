extends PanelContainer

@onready var world_handler: Node = $"../../../WorldHandler"

var current_world
var current_level
var worlds_unlocked
var levels_unlocked

func _ready() -> void:
	current_world = world_handler.world_script.current_world
	current_level = world_handler.world_script.current_level
	worlds_unlocked = world_handler.world_script.worlds_unlocked
	levels_unlocked = world_handler.world_script.levels_unlocked


# Return to level select and unlock next level
func _on_continue_pressed() -> void:
	# If this was the latest level -> unlock the next one
	if current_world == worlds_unlocked and current_level == levels_unlocked:
		world_handler.world_script.unlock_next_level()
	
	# Unpause game
	get_tree().paused = false
	
	# Return to level select
	var level_select: String = "res://src/Worlds/World_" + str(current_world) + "/world_" + str(current_world) + "_level_select.tscn" # Filepath to selected level
	
	# If the filepath is valid, change scene to the selected level
	if FileAccess.file_exists(level_select):
		get_tree().change_scene_to_file(level_select)
