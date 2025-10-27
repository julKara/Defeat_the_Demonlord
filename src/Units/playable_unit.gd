class_name playable_unit extends Node

# Refrences to objects
@onready var tile_map: TileMap = $"../../../../TileMap"
@onready var range_tile_map: TileMap = $"../../../../RangeTileMap"
@onready var draw_path: Node2D = $"../../../../DrawPath"
@onready var character_manager: Node2D = $"../../../CharacterManager"
@onready var actions_menu: PanelContainer = $"../../../../GUI/Margin/ActionsMenu"
@onready var actor_info: PanelContainer = $"../../../../GUI/Margin/ActorInfo"

# --- Variables ---
var start_position: Vector2i	# Where the unit starts
var origin_tile: Vector2i            # Tile where unit started its current turn
var current_tile: Vector2i = Vector2i.ZERO	# Tile where unit is currently (after moving but not acting)
var current_id_path: Array[Vector2i] = []	# Stores the movement-path of unit (updated as it moves)
var display_path: Array = []	# Stores the displayed red line when moving

var is_moving: bool = false
var selected: bool = false

var move_speed: float = 2.5
var mobility: int = 3

var attack_range: int = 1
var attack_target: Actor = null	# Is the enemy unit this unit hass selected to attack


func _ready() -> void:
	print("Playable unit ready — player-controlled!")
	_set_stat_variables()
	origin_tile = tile_map.local_to_map(get_parent().global_position)
	current_tile = origin_tile
	start_position = origin_tile   # keep for compatibility with other code that need start_position

func _set_stat_variables() -> void:
	var stats = get_parent().stats
	mobility = stats.mobility
	#move_speed = stats.speed
	attack_range = stats.attack_range

# --- Movement ---
func move_to(tile: Vector2i) -> void:
	# Only move to new tile
	if tile == origin_tile:
		return

	# Get path
	var id_path = get_parent().astar_grid.get_id_path(origin_tile, tile)
	if id_path.is_empty():
		return

	# Store a copy for drawing purposes (the entire original route)
	display_path = id_path.duplicate()

	current_id_path = id_path
	is_moving = true
	draw_path.show()
	calculate_direction(id_path)
	
	while is_moving and current_id_path.size() > 0:
		var next_pos = tile_map.map_to_local(current_id_path.front())
		get_parent().global_position = get_parent().global_position.move_toward(next_pos, move_speed)
		if get_parent().global_position == next_pos:
			current_id_path.pop_front()
		await get_tree().process_frame
		
	is_moving = false
	# Don't hide draw_path yet; keep visible until action or next move
	current_tile = tile
	
	# When moved manually, clear attack target
	if attack_target != null:
		var sprite = attack_target.get_node("Sprite")
		sprite.material.set("shader_parameter/width", 0.0)
		attack_target = null


# Reset back to origin_tile if moved but not acted
func reset_position_if_not_acted() -> void:
	
	# Get actor
	var parent = get_parent()
	if parent == null:
		return
	
	# Reset in not acted (acted gets set true after attacking/pass...)
	if not parent.acted:
		
		# place unit back at origin_tile
		parent.global_position = tile_map.map_to_local(origin_tile)
		
		# clear any in-progress path
		current_id_path.clear()
		is_moving = false
		draw_path.hide()
		
		# Reset start-pos and curr-til so highlight uses origin_tile
		confirm_position()
		#print("%s reset to original position." % parent.profile.character_name)


# --- Selection ---

# Protocol for deselecting a unit
func select(has_acted: bool) -> void:
	
	# Update bool
	selected = true
	
	# Set current character in character manager
	character_manager.current_character = get_parent()
	
	# Set selected_unit in click_handler
	ClickHandler.selected_unit = get_parent() 
	
	# Check if unit has already acted (should not get-actions menu, or animation)
	if not has_acted:
		get_parent().set_state(get_parent().UnitState.SELECTED)
		actions_menu.show()
	
	# Display info
	actor_info.display_actor_info(get_parent())
	
	# Display mobility- and range-tilemap
	highlight_range()
	print("\tPlayer unit turn:", get_parent().profile.character_name)

# Protocol for deselecting a unit
func deselect() -> void:
	
	# Update state
	selected = false
	get_parent().set_state(get_parent().UnitState.IDLE)
	
	# Set selected_unit in click_handler
	ClickHandler.selected_unit = null
	
	# Clear mobility- and range-map
	range_tile_map.clear_layer(0)
	range_tile_map.clear_layer(1)
	draw_path.hide()
	
	# Hide GUI-elements
	actions_menu.hide()
	actor_info.hide_actor_info()
	
	# Remove target-highlight if the is one
	if attack_target:
		var sprite = attack_target.get_node("Sprite")
		sprite.material.set("shader_parameter/width", 0.0)
		attack_target = null
		
# --- Range Highlight ---

# Display the range of a selected unit
func highlight_range() -> void:
	range_tile_map.clear_layer(0)
	range_tile_map.clear_layer(1)
	
	# Go through all tiles
	var grid_size = get_parent().astar_grid.get_size()
	for x in grid_size.x:
		for y in grid_size.y:
			
			var point = Vector2i(x, y)
			if get_parent().astar_grid.is_point_solid(point):
				continue
			var path = get_parent().astar_grid.get_id_path(origin_tile, point)
			
			# Add on range
			if path.size() <= (mobility + 1):
				range_tile_map.set_cell(1, point, 1, Vector2i(0, 1), 0)
			if path.size() <= (mobility + attack_range + 1):
				range_tile_map.set_cell(0, point, 1, Vector2i(1, 1), 0)

# --- UTIL ---

# Returns two arrays containing tiles within mobility-range and mobility-attack-range 
func get_range_tiles() -> Dictionary:
	var move_tiles: Array[Vector2i] = []
	var range_tiles: Array[Vector2i] = []

	var parent = get_parent()
	var astar = parent.astar_grid
	if not astar:
		return {"move_tiles": move_tiles, "range_tiles": range_tiles}

	var grid_size = astar.get_size()

	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var point = Vector2i(x, y)
			if astar.is_point_solid(point):
				continue

			var path = astar.get_point_path(origin_tile, point)
			if path.is_empty():
				continue

			# Within mobility range only
			if path.size() - 1 <= mobility:
				move_tiles.append(point)

			# Within attack + mobility range
			if path.size() - 1 <= mobility + attack_range:
				range_tiles.append(point)

	return {"move_tiles": move_tiles, "range_tiles": range_tiles}


func set_attack_target(target: Actor) -> void:
	
	# TODO: Make attack-button usable
	
	# Remove highlight from previous target if any
	if attack_target != null:
		var sprite = attack_target.get_node("Sprite")
		sprite.material.set("shader_parameter/width", 0.0)
	
	# Set new target
	attack_target = target
	if attack_target != null:
		var sprite = attack_target.get_node("Sprite")
		sprite.material.set("shader_parameter/width", 1.0)
		print("\tSelected attack target:", attack_target.profile.character_name)


func confirm_position() -> void:
	origin_tile = tile_map.local_to_map(get_parent().global_position)
	start_position = origin_tile
	current_tile = origin_tile


func calculate_direction(path: Array[Vector2i]):
	var start = path[0]
	var end = path[path.size()-1]
	var sprite = get_parent().get_sprite()
	
	if start.x - end.x > 0: # Left
		sprite.flip_h = true
	else: # Right
		sprite.flip_h = false
