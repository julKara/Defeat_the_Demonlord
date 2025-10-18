extends Control

@onready var level_container: HBoxContainer = $LevelContainer
@onready var world: Node = $WorldTracker

var world_num: int

func _ready() -> void:
	setup_level_button()
	connect_selected_level_to_level_button()
	world_num = world.world_script.world_num
	
func setup_level_button():
	for button in level_container.get_children():
		button.level_num = button.get_index() + 1 # Assign level number to the button
		button.text = "Level " + str(button.level_num) # Update text on button (Level number)
		button.locked = true # All levels are originally locked
	level_container.get_child(0).locked = false # First level is unlocked

func connect_selected_level_to_level_button():
	for button in level_container.get_children():
		button.connect("level_selected", change_to_scene) # Sends level_num from button to change_to_scene
		
func change_to_scene(level_num:int):
	var next_level: String = ("res://src/Worlds/World_" + str(world_num) + 
	"/Levels/Level_" + str(world_num) + "-" + str(level_num) + ".tscn") # Filepath to selected level

	# If the filepath is valid, change scene to the selected level
	if FileAccess.file_exists(next_level):
		get_tree().change_scene_to_file(next_level)
