extends Node2D
class_name Character

@onready var tile_map = $"../../TileMap"
@onready var draw_path = $"../../DrawPath"
@onready var character_manager = $".."
@onready var stand_button = %StandButton

var astar_grid: AStarGrid2D
var current_id_path: Array[Vector2i]
var target_position: Vector2
var is_moving: bool
var current_point_path: PackedVector2Array
var tile_size: int = 48
var selected: bool = false
var start_position: Vector2i

@export var move_speed: float = 3.0

@export var mobility: int = 3


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Create an A* grid that will be used for pathfinding
	astar_grid = AStarGrid2D.new()
	
	# Set the region of the A* grid to cover the tilemap
	astar_grid.region = tile_map.get_used_rect()
	
	# Set the size of the cells in the grid
	astar_grid.cell_size = Vector2(tile_size, tile_size)
	
	# No diagonal movements allowed - use L shapes instead
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	
	# Apply the changes made above to the A* grid
	astar_grid.update()
	
	start_position = tile_map.local_to_map(global_position)
	
	# Go through all tiles and disables the tiles in the A* grid that are
	# not defined as "walkable" in the tilemap
	for x in tile_map.get_used_rect().size.x:
		for y in tile_map.get_used_rect().size.y:
			var tile_position = Vector2i(
				x + tile_map.get_used_rect().position.x,
				y + tile_map.get_used_rect().position.y
			)
			
			var tile_data = tile_map.get_cell_tile_data(0, tile_position)
			
			if tile_data == null or tile_data.get_custom_data("walkable") == false:
				astar_grid.set_point_solid(tile_position)


# Function that creates a path towards the selected tile
func _input(event):
	# Don't do anything unless the mouse is pressed
	if event.is_action_pressed("select") == false:
		return

	# Don't run the code if the mouse clicks outside of the map
	if (tile_map.local_to_map(get_global_mouse_position()).x > (tile_map.get_used_rect().size.x - 1) or
	tile_map.local_to_map(get_global_mouse_position()).y > (tile_map.get_used_rect().size.y - 1)):
		return
	
	
	# Click to select a character and display move range
	if (selected == false and
	tile_map.local_to_map(get_global_mouse_position()) == tile_map.local_to_map(global_position)):	
		character_manager.current_character = self
		stand_button.counter = character_manager.character_list.find(self,0) + 1
		highlight_mobility_range()
		
		
	# Click to deselect character and hide move range
	elif (selected == true and
	tile_map.local_to_map(get_global_mouse_position()) == tile_map.local_to_map(global_position)):
		tile_map.clear_layer(1)
		selected = false
		draw_path.hide()
		global_position = tile_map.map_to_local(start_position)
	
	# If the character is selected, perform the movement	
	elif (selected == true and
	tile_map.local_to_map(get_global_mouse_position()) != tile_map.local_to_map(global_position)):

		draw_path.show()

		var id_path
		
		if is_moving:
			id_path = astar_grid.get_id_path(
				tile_map.local_to_map(target_position),
				tile_map.local_to_map(get_global_mouse_position())
			)
		else:
			# Finds the coordinates on the grid of the selected tile and the path to get there
			id_path = astar_grid.get_id_path(
				start_position,
				tile_map.local_to_map(get_global_mouse_position())
			)
		
		# Calculate the path when the player cooses a new tile after already moving
		var changed_id_path
		if tile_map.local_to_map(global_position) != tile_map.local_to_map(start_position):
			changed_id_path = astar_grid.get_id_path(
				tile_map.local_to_map(global_position),
				start_position
			)
		
		# Only perform the movement if the path is valid and within range
		if id_path.is_empty() == false and id_path.size() <= mobility + 1:
			# Assign path depending on if it is the first move or the player changed their mind
			if tile_map.local_to_map(global_position) == tile_map.local_to_map(start_position):
				current_id_path = id_path
			else:
				changed_id_path.append_array(id_path)
				current_id_path = changed_id_path
			
			# Used for drawing the line for the path
			current_point_path = astar_grid.get_point_path(
				start_position,
				tile_map.local_to_map(get_global_mouse_position())
			)

			for i in current_point_path.size():
				current_point_path[i] += Vector2(tile_size/2, tile_size/2)


# This function perform the movement and loops constantly(important to remember)	
func _physics_process(_delta):
	# Don't move unless a destinatin has been selected
	if current_id_path.is_empty():
		return
	
	if is_moving == false: # Can only select a new destination when standing still
		# Selects the first tile in the path to the destination
		target_position = tile_map.map_to_local(current_id_path.front())
		is_moving = true
	
	# Move the player to the tile
	global_position = global_position.move_toward(target_position, move_speed)
	
	# Remove the tile from the path
	if global_position == target_position:
		current_id_path.pop_front()
		
		# If there are still tiles in the path, select the next one
		if current_id_path.is_empty() == false:
			target_position = tile_map.map_to_local(current_id_path.front())
		else:
			is_moving = false
			
			
func highlight_mobility_range():
	# Variable used to calculate the tiles withing moving rang
	var mobility_path
	
	# Reset prevoius highlight. Prevents highlighting several characters at once
	tile_map.clear_layer(1)
		
	# Go through the entire grid and highlight the tiles that are possible to move to
	# depending on the characters mobility	
	for x in astar_grid.get_size().x:
		for y in astar_grid.get_size().y:
			# Skip tiles that are not "walkable"
			if astar_grid.is_point_solid(Vector2i(x,y)):
				continue
			# Calculate the path from the character to the current tile (x,y)
			mobility_path = astar_grid.get_id_path(
				start_position,
				Vector2i(x,y)
			)
				
			# Draw tiles with a path to it that is within the range
			if mobility_path.size() <= (mobility + 1): # mobility+1 since path includes start position
				tile_map.set_cell(1, Vector2i(x,y), 2, Vector2i(0,1), 0)
				
	selected = true
