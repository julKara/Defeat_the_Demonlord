extends Button
@onready var character = $"../Character"
@onready var tile_map = $"../TileMap"
@onready var draw_path = $"../DrawPath"

func _pressed() -> void:
	character.start_position = tile_map.local_to_map(character.global_position)
	tile_map.clear_layer(1)
	character.selected = false
	draw_path.hide()
