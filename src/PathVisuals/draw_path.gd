extends Node2D

@onready var character_manager: Node2D = $"../TileMapLayer/CharacterManager"

# Update drawing
func _process(_delta):
	queue_redraw()

# Draw a line along the selected path of the character
func _draw():
	if character_manager.current_character.current_point_path.is_empty():
		return
	
	if character_manager.current_character.current_point_path.size() > 1:
		draw_polyline(character_manager.current_character.current_point_path, Color.RED)
