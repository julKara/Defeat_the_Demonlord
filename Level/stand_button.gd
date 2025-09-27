extends Button
@onready var character_manager = $"../CharacterManager"
@onready var tile_map = $"../TileMap"
@onready var draw_path = $"../DrawPath"

func _pressed() -> void:
	character_manager.current_character.start_position = tile_map.local_to_map(character_manager.current_character.global_position)
	tile_map.clear_layer(1)
	character_manager.current_character.selected = false
	draw_path.hide()

	character_manager.set_current_character(character_manager.character_list[1])
