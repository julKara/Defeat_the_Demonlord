extends Button

@onready var character_manager: Node2D = $"../../../../../TileMapLayer/CharacterManager"
@onready var battle_handler: BattleHandler = $"../../../../../BattleHandler"
@onready var turn_manager: Node2D = $"../../../../../TileMapLayer/TurnManager"

func _pressed() -> void:
	
	# Find behaviour node of the current character
	var selected_unit = character_manager.current_character
	var behaviour_node = selected_unit.get_behaviour()
	
	# Set up attacker and target, and define damage from physical attack stat
	var attacker: Actor = character_manager.current_character
	var target: Actor = behaviour_node.attack_target
	
	# Distance between attacker and target, influences damage
	var dist: float = attacker.position.distance_to(target.position)
	
	# Perform battle and wait for it to finish
	await battle_handler.perform_battle(attacker, target, dist)
	
	# Do a counter-attack if target is still alive and withing range
	if target.stats.curr_health > 0:
		var target_range = target.stats.attack_range
		
		# Only counterattack if attacker is within target’s range
		if target_range * attacker.tile_size >= dist:
			#print("Counter Attack!")
			await battle_handler.perform_battle(target, attacker, dist)
	
	turn_manager.end_player_unit_turn(character_manager.current_character)
