extends Node2D

@onready var character_manager: Node2D = $"../TileMapLayer/CharacterManager"
@onready var victory_screen: PanelContainer = $"../GUI/Margin/VictoryScreen"
@onready var game_over_screen: PanelContainer = $"../GUI/Margin/GameOverScreen"



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
	victory_screen.show()
	
func lose():
	print("game over :(")
	game_over_screen.show()
