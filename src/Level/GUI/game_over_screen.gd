extends PanelContainer

@onready var world_handler: Node = $"../../../WorldHandler"

var current_world

func _ready() -> void:
	current_world = world_handler.world_script.current_world


# Restart level
func _on_retry_pressed() -> void:
	# Play click sound
	AudioManager.play_sfx("Click")
	
	# Play battle music
	AudioManager.update_music_for_scene("Battle")
	
	# Unpause game
	get_tree().paused = false
	
	# Reload the scene
	get_tree().reload_current_scene()
	

# Return to level select
func _on_return_pressed() -> void:
	# Play click sound
	AudioManager.play_sfx("Click")
	
	#Unpause game
	get_tree().paused = false
	
	# Return to level select
	var level_select: String = "res://src/Worlds/World_" + str(current_world) + "/world_" + str(current_world) + "_level_select.tscn" # Filepath to selected level
	
	# If the filepath is valid, change scene to the selected level
	if FileAccess.file_exists(level_select):
		get_tree().change_scene_to_file(level_select)
		AudioManager.update_music_for_scene("Menu")
