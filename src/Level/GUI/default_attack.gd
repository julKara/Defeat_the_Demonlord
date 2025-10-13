extends Button

@onready var character_manager: Node2D = $"../../../../../TileMapLayer/CharacterManager"
@onready var pass_turn: Button = $"../Pass_Turn"

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
	var damage
	
	# Magic users use mag_attack and weapon users use phys_attack
	if attacker.stats.battle_class_type == "Mage":
		damage = attacker.stats.mag_attack
	else:
		damage = attacker.stats.phys_attack
	
	# Perform attack if the target is valid and the attacker and the target are on different teams
	if target != null and attacker.is_friendly != target.is_friendly:
		target.stats.take_damage(damage)
		behaviour_node.attack_target = null # Reset target
		
		pass_turn._pressed() # Attacking ends turn
	
