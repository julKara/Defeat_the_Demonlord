extends Button

@onready var world_handler: Node = $"../../WorldHandler"



func _pressed():
	
	# Play click sound
	AudioManager.play_sfx("Click")
	
	world_handler._create_save()
	
	var world_select: String = "res://src/Worlds/world_select.tscn"

	if FileAccess.file_exists(world_select):
		get_tree().change_scene_to_file(world_select)
