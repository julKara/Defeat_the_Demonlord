extends Node2D

@onready var character_manager: Node2D = $"../TileMapLayer/CharacterManager"
@onready var victory_screen: PanelContainer = $"../GUI/Margin/VictoryScreen"
@onready var game_over_screen: PanelContainer = $"../GUI/Margin/GameOverScreen"
@onready var world_handler: Node = $"../WorldHandler"
@onready var turn_manager: Node2D = $"../TileMapLayer/TurnManager"


var current_world
var current_level
var worlds_unlocked
var levels_unlocked

func _ready() -> void:
	world_handler._load_save()
	
	current_world = world_handler.world_script.current_world
	current_level = world_handler.world_script.current_level
	worlds_unlocked = world_handler.world_script.worlds_unlocked
	levels_unlocked = world_handler.world_script.levels_unlocked

func check_conditions():
	# If all enemy characters are dead -> win
	if turn_manager.enemy_queue.is_empty():
		win()
	
	# If all player characters are dead -> lose
	if turn_manager.player_queue.is_empty():
		lose()
		
	# Custom conditions can be added as child nodes and therefor be unique per level
	

func win():
	print("victory :3")
	
	# Pause game so that no more moves can be made
	get_tree().paused = true
	
	# Show victory screen
	victory_screen.show()
	
	print(current_world)
	print(worlds_unlocked)
	print(current_level)
	print(levels_unlocked)
	
	# If this was the latest level -> unlock the next one
	if current_world == worlds_unlocked and current_level == levels_unlocked:
		world_handler.world_script.unlock_next_level()
		
	character_level_up()
	
func lose():
	print("game over :(")
	get_tree().paused = true
	game_over_screen.show()
	
func character_level_up():

	for character in character_manager.character_list_copy:
		# Only increase level of playeble units when a level is finished for the first time
		if character.is_friendly == true and current_world == worlds_unlocked and current_level == levels_unlocked:
			
			# Increase level
			character.stats.level += 1
			print(character.profile.character_name + " reached level " + str(character.stats.level))
			
			# increase stats per level
			if character.profile.battle_class_type == "Mage":
				character.stats.mag_attack += 20
				character.stats.mag_defense += 10
				character.stats.max_health += 10
			elif character.profile.battle_class_type == "Swordsman":
				character.stats.phys_attack += 10
				character.stats.phys_defense += 20
				character.stats.max_health += 20
