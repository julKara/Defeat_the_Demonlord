extends Node2D

@onready var player = $"../Player"

# Update drawing
func _process(_delta):
	queue_redraw()

# Draw a line along the selected path of the player
func _draw():
	if player.current_point_path.is_empty():
		return
		
	draw_polyline(player.current_point_path, Color.RED)
