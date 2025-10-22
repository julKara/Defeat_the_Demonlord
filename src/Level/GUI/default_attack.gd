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
	var attacker = character_manager.current_character
	var target = behaviour_node.attack_target
	
	battle_handler.perform_battle(attacker, target)
	
	pass_turn._pressed()
