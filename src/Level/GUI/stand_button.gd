extends Button

"""
# Ends a units turn without "attacking"
"""
@onready var turn_manager: Node2D = $"../../../../../TileMapLayer/TurnManager"
@onready var character_manager: Node2D = $"../../../../../TileMapLayer/CharacterManager"

func _pressed() -> void:
	var current = character_manager.current_character
	turn_manager.end_player_unit_turn(current)
