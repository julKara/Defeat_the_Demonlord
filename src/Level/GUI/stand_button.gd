extends Button

"""
# This file contains protocol for unit passing its turn.
"""
@onready var character_manager: Node2D = $"../../../../../TileMapLayer/CharacterManager"
@onready var turn_manager: Node2D = $"../../../../../TileMapLayer/TurnManager"

func _pressed() -> void:
	# Play click sound
	AudioManager.play_sfx("Click")
	
	var current = character_manager.current_character
	turn_manager.end_player_unit_turn(current)
