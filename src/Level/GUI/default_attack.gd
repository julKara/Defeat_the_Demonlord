extends Button

@onready var character_manager: Node2D = $"../../../../../TileMapLayer/CharacterManager"
@onready var battle_handler: BattleHandler = $"../../../../../BattleHandler"

func _pressed() -> void:
	
	# Get the selected current actor and selected target
	var attacker: Actor = character_manager.current_character
	var target: Actor = character_manager.selected_target	# FIX TARGETING

	# Test if valid
	if attacker == null or target == null:
		push_warning("No valid attacker or target selected!")
		return

	# Perform battle
	battle_handler.perform_battle(attacker, target)
