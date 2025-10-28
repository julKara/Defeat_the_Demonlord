extends Button

func _pressed() -> void:
	# Play click sound
	AudioManager.play_sfx("Click")
	
	var back: String = "res://src/Worlds/world_select.tscn"

	# If the filepath is valid, change scene to world select
	if FileAccess.file_exists(back):
		get_tree().change_scene_to_file(back)
