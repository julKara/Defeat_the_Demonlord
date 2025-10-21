extends Node2D

@onready var character_manager: Node2D = $"../TileMapLayer/CharacterManager"
@onready var victory_screen: PanelContainer = $"../GUI/Margin/VictoryScreen"
@onready var game_over_screen: PanelContainer = $"../GUI/Margin/GameOverScreen"
@onready var world_handler: Node = $"../WorldHandler"


var current_world
var current_level
var worlds_unlocked
var levels_unlocked

func _ready() -> void:
	current_world = world_handler.world_script.current_world
	current_level = world_handler.world_script.current_level
	worlds_unlocked = world_handler.world_script.worlds_unlocked
	levels_unlocked = world_handler.world_script.levels_unlocked

func check_conditions():
	# If all enemy characters are dead -> win
	if character_manager.enemy_list.is_empty():
		win()
	
	# If all player characters are dead -> lose
	if character_manager.player_list.is_empty():
		lose()
		
	# Custom conditions can be added as child nodes and therefor be unique per level
	

func win():
	print("victory :3")
	
	# Pause game so that no more moves can be made
	get_tree().paused = true
	
	# Show victory screen
	victory_screen.show()
	
	# If this was the latest level -> unlock the next one
	if current_world == worlds_unlocked and current_level == levels_unlocked:
		world_handler.world_script.unlock_next_level()
		
	# Characters level up
	for character in character_manager.character_list_copy:
		if character.is_friendly == true:
			character.stats.level += 1
			print(character.profile.character_name + " reached level " + str(character.stats.level))
	
func lose():
	print("game over :(")
	get_tree().paused = true
	game_over_screen.show()
