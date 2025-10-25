class_name playable_unit extends Node

# Refrences to objects
@onready var tile_map: TileMap = $"../../../../TileMap"
@onready var range_tile_map: TileMap = $"../../../../RangeTileMap"
@onready var draw_path: Node2D = $"../../../../DrawPath"
@onready var character_manager: Node2D = $"../../../CharacterManager"
@onready var actions_menu: PanelContainer = $"../../../../GUI/Margin/ActionsMenu"
@onready var actor_info: PanelContainer = $"../../../../GUI/Margin/ActorInfo"

# --- Variables for movement ---
var start_position: Vector2i
var current_id_path: Array[Vector2i] = []
var is_moving: bool = false
var move_speed: float = 3.0
var mobility: int = 3
var attack_range: int = 1
var attack_target: Actor = null
var selected: bool = false
var origin_tile: Vector2i            # Tile where unit started its current turn
var current_tile: Vector2i = Vector2i.ZERO	# Tile where unit is currently (after moving but not acting)


func _ready() -> void:
	print("Playable unit ready — player-controlled!")
	_set_stat_variables()
	origin_tile = tile_map.local_to_map(get_parent().global_position)
	current_tile = origin_tile
	start_position = origin_tile   # keep for compatibility with other code that need start_position

func _set_stat_variables() -> void:
	var stats = get_parent().stats
	mobility = stats.mobility
	move_speed = stats.speed
	attack_range = stats.attack_range

# --- UTIL ---
func get_move_tiles() -> Array[Vector2i]:
	var tiles_in_range: Array[Vector2i] = []
	for x in get_parent().astar_grid.get_size().x:
		for y in get_parent().astar_grid.get_size().y:
			if get_parent().astar_grid.is_point_solid(Vector2i(x, y)):
				continue
			var path = get_parent().astar_grid.get_id_path(start_position, Vector2i(x, y))
			if path.size() <= mobility + 1:
				tiles_in_range.append(Vector2i(x, y))
	return tiles_in_range

func get_behaviour() -> playable_unit:
	return self


# --- Movement ---
func move_to(tile: Vector2i) -> void:
	# tile is a map tile (Vector2i)
	if tile == origin_tile:
		return
	
	var id_path = get_parent().astar_grid.get_id_path(origin_tile, tile)  # compute path from origin_tile
	if id_path.is_empty():
		return
	
	current_id_path = id_path
	is_moving = true
	draw_path.show()
	
	while is_moving and current_id_path.size() > 0:
		var next_pos = tile_map.map_to_local(current_id_path.front())
		get_parent().global_position = get_parent().global_position.move_toward(next_pos, move_speed)
		if get_parent().global_position == next_pos:
			current_id_path.pop_front()
		await get_tree().process_frame
		
	is_moving = false
	# don't set origin_tile here — only confirm_position() should do that
	current_tile = tile
	draw_path.hide()
	
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
		start_position = origin_tile
		current_tile = origin_tile
		#print("%s reset to original position." % parent.profile.character_name)


# --- Selection ---

# Protocol for deselecting a unit
func select(has_acted: bool) -> void:
	
	# Update bool
	selected = true
	
	# Set current character in character manager
	character_manager.current_character = get_parent()
	
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
func set_attack_target(target: Actor) -> void: # Remove highlight from previous target if any
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
	# call this when the unit's action is finalized (e.g. TurnManager.notify_unit_acted)
	origin_tile = tile_map.local_to_map(get_parent().global_position)
	start_position = origin_tile
	current_tile = origin_tile
