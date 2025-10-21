extends Button

func _pressed():
	
	# TEMP
	var world_select: String = "res://src/Worlds/world_select.tscn"

	if FileAccess.file_exists(world_select):
		get_tree().change_scene_to_file(world_select)
