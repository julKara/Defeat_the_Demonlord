extends Button

@onready var world_handler: Node = $"../../../WorldHandler"

func _ready():
	
	# If no save file exists -> continue button is disabled
	if world_handler._check_save() == false:
		disabled = true
	else:
		disabled = false

func _pressed():
	
	# Play click sound
	AudioManager.play_sfx("Click")
	
	# If a save file exists -> load the save and move to world select
	if world_handler._check_save() == true:
	
		world_handler._load_save()
		
		var world_select: String = "res://src/Worlds/world_select.tscn"

		if FileAccess.file_exists(world_select):
			get_tree().change_scene_to_file(world_select)
	
