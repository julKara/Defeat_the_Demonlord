extends Control

@onready var level_container: HBoxContainer = $LevelContainer
@onready var world_handler: Node = $WorldHandler

var level_music: String
var world_num: int

func _ready() -> void:
	setup_level_button()
	connect_selected_level_to_level_button()
	world_num = world_handler.world_script.current_world
	level_music = "Battle"
	
func setup_level_button():
	for button in level_container.get_children():
		button.level_num = button.get_index() + 1 # Assign level number to the button
		button.text = "Level " + str(button.level_num) # Update text on button (Level number)
		button.locked = true # All levels are originally locked
		
		# If this is the latest unlocked world -> set which levels are unlocked according to levels_unlocked
		if (button.level_num <= world_handler.world_script.levels_unlocked and 
		world_handler.world_script.current_world == world_handler.world_script.worlds_unlocked):
			button.locked = false
		# If this is not the latest unlocked world -> set all levels as unlocked
		elif world_handler.world_script.current_world < world_handler.world_script.worlds_unlocked:
			button.locked = false


func connect_selected_level_to_level_button():
	for button in level_container.get_children():
		button.connect("level_selected", change_to_scene) # Sends level_num from button to change_to_scene
		
func change_to_scene(level_num:int):
	var next_level: String = ("res://src/Worlds/World_" + str(world_num) + 
	"/Levels/Level_" + str(world_num) + "-" + str(level_num) + ".tscn") # Filepath to selected level

	# Check if last level
	if level_num == 5 and world_handler.world_script.current_world == 2:
		level_music = "Boss"

	# If the filepath is valid, change scene to the selected level
	if FileAccess.file_exists(next_level):
		get_tree().change_scene_to_file(next_level)
		world_handler.world_script.current_level = level_num
		world_handler._save_game()
		AudioManager.update_music_for_scene(level_music)
	
