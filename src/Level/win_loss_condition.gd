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
	turn_manager.game_is_paused = true
	get_tree().paused = true
	
	# Show victory screen
	victory_screen.show()
	
	# Play victory sound
	AudioManager.play_sfx("Victory")
	
	# Play victory music
	AudioManager.update_music_for_scene("Victory")
	
	# If this was the latest level -> unlock the next one
	if current_world == worlds_unlocked and current_level == levels_unlocked:
		world_handler.world_script.unlock_next_level()
		
	character_level_up()
	
func lose():
	print("game over :(")
	turn_manager.game_is_paused = true
	get_tree().paused = true
	
	# Show game over screen
	game_over_screen.show()
	
	# Play loss sound
	AudioManager.play_sfx("Loss")
	
	# Play loss music
	AudioManager.update_music_for_scene("Loss")
	
func character_level_up():

	for character in character_manager.character_list_copy:
		# Only increase level of playeble units when a level is finished for the first time
		if character.is_friendly == true and current_world == worlds_unlocked and current_level == levels_unlocked:
			
			# Increase level
			character.stats.level += 1
			print(character.profile.character_name + " reached level " + str(character.stats.level))
			
			# Increase stats
			character.stats.max_health = character.stats.original_max_health + character.stats.health_gain * (character.stats.level-1)
			character.stats.phys_attack = character.stats.original_phys_attack + character.stats.phys_atk_gain * (character.stats.level-1)
			character.stats.mag_attack = character.stats.original_mag_attack + character.stats.mag_atk_gain * (character.stats.level-1)
			character.stats.phys_defense = character.stats.original_phys_defense + character.stats.phys_def_gain * (character.stats.level-1)
			character.stats.mag_defense = character.stats.original_mag_defense + character.stats.mag_def_gain * (character.stats.level-1)
			character.stats.crit_chance = character.stats.original_crit_chance + character.stats.crit_gain * (character.stats.level-1)
			
