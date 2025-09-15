extends Node2D

@onready var character = $"../Character"

# Update drawing
func _process(_delta):
	queue_redraw()

# Draw a line along the selected path of the character
func _draw():
	if character.current_point_path.is_empty():
		return
		
	draw_polyline(character.current_point_path, Color.RED)
