extends Button

@onready var character_manager: Node2D = $"../../../../../TileMapLayer/CharacterManager"
@onready var pass_turn: Button = $"../Pass_Turn"
@onready var battle_handler: BattleHandler = $"../../../../../BattleHandler"

func _pressed() -> void:
	
	# Find behaviour node of the current character
	var all_children = character_manager.current_character.get_children()
	var behaviour_node	
	for child in all_children:
		if child is Node:
			behaviour_node = child
	
	# Set up attacker and target, and define damage from physical attack stat
	var attacker: Actor = character_manager.current_character
	var target: Actor = behaviour_node.attack_target
	
	# Perform battle and wait for it to finish
	await battle_handler.perform_battle(attacker, target)
	
	# Do a counter-attack if target is still alive and withing range
	if target.stats.curr_health > 0:
		var attacker_range = attacker.stats.attack_range
		var target_range = target.stats.attack_range

		# Only counterattack if attacker is within target’s range
		if target_range >= attacker_range:
			await battle_handler.perform_battle(target, attacker)
	
	pass_turn._pressed()
