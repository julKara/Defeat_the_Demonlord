extends Node2D

@onready var character_manager: Node2D = $"../TileMapLayer/CharacterManager"

func check_conditions():
	# If all enemy characters are dead -> win
	if character_manager.enemy_list.is_empty():
		win()
	
	# If all player characters are dead -> lose
	if character_manager.player_list.is_empty():
		lose()
	

func win():
	print("victory :3")
	
func lose():
	print("game over :(")
