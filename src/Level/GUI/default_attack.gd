extends Button

@onready var character_manager: Node2D = $"../../../../../TileMapLayer/CharacterManager"
#@onready var battle_handler: BattleHandler = $"../../../../../BattleHandler"
@onready var turn_manager: Node2D = $"../../../../../TileMapLayer/TurnManager"
@onready var tile_map: TileMap = $"../../../../../TileMap"


var battle_handler: Node = null

func _ready() -> void:
	battle_handler = BattleHandlerSingleton

func _pressed() -> void:
	
	# Play click sound
	AudioManager.sfx_player.play()
	
	# Find behaviour node of the current character
	var selected_unit = character_manager.current_character
	var behaviour_node = selected_unit.get_behaviour()
	
	# Set up attacker and target, and define damage from physical attack stat
	var attacker: Actor = character_manager.current_character
	var target: Actor = behaviour_node.attack_target
	
	# Distance between attacker and target, influences damage
	var dist: float = attacker.position.distance_to(target.position)
	
	# Path between attacker and target, used for flipping sprites
	var path = attacker.astar_grid.get_id_path(tile_map.local_to_map(attacker.global_position),
	tile_map.local_to_map(target.global_position))
	
	# Perform battle and wait for it to finish
	await battle_handler.perform_battle(attacker, target, dist, path)
	
	# Do a counter-attack if target is still alive and withing range
	if target.stats.curr_health > 0:
		
		var target_range = target.stats.attack_range
		
		# Only counterattack if attacker is within target’s range
		if target_range * attacker.tile_size >= dist:
			print("\t\t\tCounter!")
			path.reverse()
			await battle_handler.perform_battle(target, attacker, dist, path)
	
	turn_manager.end_player_unit_turn(character_manager.current_character)
