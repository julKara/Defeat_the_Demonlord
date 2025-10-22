extends Button
@onready var character_manager: Node2D = $"../../../../../TileMapLayer/CharacterManager"
@onready var turn_manager: Node2D = $"../../../../../TileMapLayer/TurnManager"



var counter: int = 0

func _pressed() -> void:
	
	var current = character_manager.current_character
	turn_manager.end_player_unit_turn(current)
