extends Button
@onready var character_manager: Node2D = $"../../../../../TileMapLayer/CharacterManager"
@onready var tile_map: TileMap = $"../../../../../TileMap"
@onready var draw_path: Node2D = $"../../../../../DrawPath"

var counter: int = 0

func _pressed() -> void:
	# Update the startposision of the current character to be where it ended its move
	character_manager.current_character.start_position = tile_map.local_to_map(character_manager.current_character.global_position)
	
	# Hide mobility range
	tile_map.clear_layer(1)
	
	# Deselect character
	character_manager.current_character.selected = false
	
	# Hidde movement path
	draw_path.hide()

	# Update the current character to the next in the array
	character_manager.set_current_character(character_manager.character_list[counter%character_manager.num_characters])
	counter = counter + 1
	
	# Highlight and select the updated current character
	character_manager.current_character.highlight_mobility_range()
