extends Node2D

@onready var character_manager: Node2D = $"../TileMapLayer/CharacterManager"

# Update drawing
func _process(_delta):
	queue_redraw()

# Draw a line along the selected path of the character
func _draw():
	var all_children = character_manager.current_character.get_children()
	var behaviour_node
		
	for x in all_children:
		if x is Node:
			behaviour_node = x
	
	if behaviour_node.current_point_path.is_empty():
		return
	
	if behaviour_node.current_point_path.size() > 1:
		draw_polyline(behaviour_node.current_point_path, Color.RED)
