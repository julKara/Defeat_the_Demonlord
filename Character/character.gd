extends Node2D

@onready var tile_map = $"../TileMap"

var astar_grid: AStarGrid2D
var current_id_path: Array[Vector2i]
var target_position: Vector2
var is_moving: bool
var current_point_path: PackedVector2Array
var tile_size: int = 64

var mobility: int = 3


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
	
	# Go through all tiles and disables the tiles in the A* grid that are
	# not deined as "walkable" in the tilemap
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
	
	for n in range(-mobility, mobility+1):
		tile_map.set_cell(1, tile_map.local_to_map(global_position) + Vector2i(n,0), 0, Vector2i(0,1), 0)
		tile_map.set_cell(1, tile_map.local_to_map(global_position) + Vector2i(0,n), 0, Vector2i(0,1), 0)
	
	var id_path
	
	if is_moving:
		id_path = astar_grid.get_id_path(
			tile_map.local_to_map(target_position),
			tile_map.local_to_map(get_global_mouse_position())
		)
	else:
		# Finds the coordinates on the grid of the selected tile and the path to get there
		id_path = astar_grid.get_id_path(
			tile_map.local_to_map(global_position),
			tile_map.local_to_map(get_global_mouse_position())
		).slice(1) # Removes the first coordinates, since they are the current position, which is irrelevant
	
	if id_path.is_empty() == false:
		current_id_path = id_path
		
		current_point_path = astar_grid.get_point_path(
			tile_map.local_to_map(target_position),
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
	global_position = global_position.move_toward(target_position, 2)
	
	# Remove the tile from the path
	if global_position == target_position:
		current_id_path.pop_front()
		
		# If there are still tiles in the path, select the next one
		if current_id_path.is_empty() == false:
			target_position = tile_map.map_to_local(current_id_path.front())
		else:
			is_moving = false
