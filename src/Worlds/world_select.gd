extends Control

@onready var world_container: HBoxContainer = $WorldContainer
@onready var world_handler: Node = $WorldHandler


func _ready() -> void:
	setup_world_button()
	connect_selected_world_to_world_button()
	
func setup_world_button():
	for button in world_container.get_children():
		button.world_num = button.get_index() + 1 # Assign world number to the button
		button.text = "World " + str(button.world_num) # Update text on button (World number)
		button.locked = true # All world are originally locked
		if button.world_num <= world_handler.world_script.worlds_unlocked:
			button.locked = false

func connect_selected_world_to_world_button():
	for button in world_container.get_children():
		button.connect("world_selected", change_to_scene) # Sends level_num from button to change_to_scene
		
func change_to_scene(world_num: int):
	var next_world: String = "res://src/Worlds/World_" + str(world_num) + "/world_" + str(world_num) + "_level_select.tscn" # Filepath to selected level
	
	# If the filepath is valid, change scene to the selected level
	if FileAccess.file_exists(next_world):
		get_tree().change_scene_to_file(next_world)
		print("Changed to world " + str(world_num))
		world_handler.world_script.set_current_world(world_num)
		world_handler._save_game()
	
