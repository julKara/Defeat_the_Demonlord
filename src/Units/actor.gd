@tool	# Remove near end (heavy on performance)

class_name Actor extends CharacterBody2D

@export var stats: CharacterStats	# All stats to particular unit

# Handles setting stats and colors
const FRIENDLY_COLOR: Color = Color("00a78f")
const ENEMY_COLOR: Color = Color.CRIMSON
@onready var shape = $CollisionShape2D
var behavior: Node = null	# Decides behavior based on if unit is playable, enemy, npc...

# Refrences to objects
@onready var tile_map: TileMap = $"../../../TileMap"

# Grid variables
var astar_grid: AStarGrid2D
var tile_size: int = 48

# Export lets you toggle this in the inspector
@export var is_friendly: bool = false:
	set(value):
		is_friendly = value
		if is_node_ready():	# Must check if modulate should work
			_reload_behavior()	# Set/Toggles behavior

# Sets up AstarGrid for pathfinding, walkable tiles and sets friendly/enemy color/name
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
	
	# Set friendly/enemy
	is_friendly = is_friendly
	

# Dynamically set or switch behaviour, can be done at runtime (very felixable and lightweight) (NEW from Julia)
func _reload_behavior():
	
	print("Reloading behavior for:", name)	# TESTING
	
	# Remove old behavior if one exists
	if behavior and is_instance_valid(behavior):
		behavior.queue_free()
		behavior = null

	# Choose the behavior scene path, can be added more if needed
	var behavior_path = (
		"res://src/Units/playable_unit.gd"
		if is_friendly
		else "res://src/Units/enemy_unit.gd"
	)

	# Load and attach the correct script dynamically
	var behavior_script = load(behavior_path)
	behavior = Node.new()	# Behavior of the actor gets attached as a child to the actor
	behavior.set_script(behavior_script)
	add_child(behavior)

	# Set name and color
	if shape:
		if is_friendly:
			shape.self_modulate = FRIENDLY_COLOR
			name = "playable_unit"
		else:
			shape.self_modulate = ENEMY_COLOR
			name = "enemy_unit"
