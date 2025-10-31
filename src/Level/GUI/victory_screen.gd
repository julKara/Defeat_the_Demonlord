extends PanelContainer

@onready var world_handler: Node = $"../../../WorldHandler"
@onready var character_manager: Node2D = $"../../../TileMapLayer/CharacterManager"


var current_world

func _ready() -> void:
	current_world = world_handler.world_script.current_world


# Return to level select and unlock next level
func _on_continue_pressed() -> void:
	
	# Play click sound
	AudioManager.play_sfx("Click")
	
	# Unpause game
	get_tree().paused = false
	
	# Save characters
	character_manager._save_game()
	
	
	# If this was the final level -> go to credits
	if world_handler.world_script.current_world == 2 and world_handler.world_script.current_level == 5:
		var credits: String = "res://src/Worlds/credits_scene.tscn"
		
		# If the filepath is valid, change scene to the selected level
		if FileAccess.file_exists(credits):
			get_tree().change_scene_to_file(credits)
			AudioManager.update_music_for_scene("Credits")
	# Otherwise -> go to level selects
	else:
		# Return to level select
		var level_select: String = "res://src/Worlds/World_" + str(current_world) + "/world_" + str(current_world) + "_level_select.tscn" # Filepath to selected level
		
		# If the filepath is valid, change scene to the selected level
		if FileAccess.file_exists(level_select):
			get_tree().change_scene_to_file(level_select)
			AudioManager.update_music_for_scene("Menu")
	
