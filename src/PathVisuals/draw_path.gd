extends Node2D

@onready var character_manager: Node2D = $"../TileMapLayer/CharacterManager"
@onready var tile_map: TileMap = $"../TileMap"

# Update drawing
func _process(_delta):
	queue_redraw()

# Draw a line along the selected path of the character
func _draw():
	# Make sure a unit is selected
	var actor = character_manager.current_character
	if not actor:
		return

	var behaviour = actor.get_behaviour()
	if not behaviour:
		return

	# Path array check
	var path: Array = behaviour.display_path
	if path.is_empty():
		return

	# Convert tile coords to global points
	var points: Array[Vector2] = []
	for id_tile in path:
		points.append(tile_map.map_to_local(id_tile))

	# Draw line
	if points.size() > 1:
		draw_polyline(points, Color.RED , 3.0)
