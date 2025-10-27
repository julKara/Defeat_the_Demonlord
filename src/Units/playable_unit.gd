class_name playable_unit extends Node

# Refrences to objects
@onready var tile_map: TileMap = $"../../../../TileMap"
@onready var range_tile_map: TileMap = $"../../../../RangeTileMap"
@onready var draw_path: Node2D = $"../../../../DrawPath"
@onready var character_manager: Node2D = $"../../../CharacterManager"
@onready var actions_menu: PanelContainer = $"../../../../GUI/Margin/ActionsMenu"
@onready var actor_info: PanelContainer = $"../../../../GUI/Margin/ActorInfo"
@onready var turn_manager: Node2D = $"../../../TurnManager"


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
	display_path.clear()
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
	range_tile_map.clear_layer(0) # purple
	range_tile_map.clear_layer(1) # blue

	var data := get_range_tiles()
	var move_tiles: Array[Vector2i] = data.move_tiles
	var attack_tiles: Array[Vector2i] = data.attack_tiles

	# Show blue (mobility)
	for t in move_tiles:
		range_tile_map.set_cell(1, t, 1, Vector2i(0, 1), 0)

	# Show purple (attack range)
	for t in attack_tiles:
		range_tile_map.set_cell(0, t, 1, Vector2i(1, 1), 0)

# --- UTIL ---

# Return an Array of Vector2i positions occupied by enemy actors
func _get_enemy_positions() -> Array:
	
	var positions := []
	for actor in character_manager.character_list:
		
		if not actor: continue
		
		# actor is a Node2D whose global position maps to a tile
		var actor_tile := tile_map.local_to_map(actor.global_position)
		
		# only consider enemies (is_friendly == false)
		if not actor.is_friendly:
			positions.append(actor_tile)

	return positions.duplicate()
	
# Mark enemy positions as solid or clear them (solid = false) on this unit's astar grid.
func _set_enemy_positions_solid_on_astar(solid: bool) -> void:
	
	var enemy_positions := _get_enemy_positions()
	for pos in enemy_positions:
		if solid:
			# make this grid position solid so pathfinding cannot pass through it
			# (Note: using set_point_solid used elsewhere in your code)
			get_parent().astar_grid.set_point_solid(pos)
		elif get_parent().astar_grid.is_point_solid(pos):
			# clear the solid flag so pathfinding ignores the actor
			# use clear_point_solid if available; if your version has a different API name replace accordingly
			get_parent().astar_grid.clear_point_solid(pos)


# Returns two arrays containing tiles within mobility-range and mobility-attack-range 
func get_range_tiles() -> Dictionary:
	# Always start from a fresh copy of the base grid (terrain-only)
	get_parent().reset_astar_grid()

	var grid: AStarGrid2D = get_parent().astar_grid
	var move_tiles: Array[Vector2i] = []
	var attack_tiles: Array[Vector2i] = []

	# Mark enemy positions as solid so they block mobility.
	for enemy in turn_manager.enemy_queue:
		var t := tile_map.local_to_map(enemy.global_position)
		grid.set_point_solid(t)

	var grid_size := grid.get_size()

	for x in grid_size.x:
		for y in grid_size.y:
			var p = Vector2i(x, y)
			if grid.is_point_solid(p):
				continue
			var path := grid.get_id_path(origin_tile, p)
			if path.size() > 0 and path.size() <= (mobility + 1):
				move_tiles.append(p)

	# ATTACK RANGE — reuse the *same* base grid (not marking enemies solid)
	get_parent().reset_astar_grid()
	grid = get_parent().astar_grid

	for x in grid_size.x:
		for y in grid_size.y:
			var p = Vector2i(x, y)
			var tile_data = tile_map.get_cell_tile_data(0, p)
			if tile_data == null or tile_data.get_custom_data("walkable") == false:
				continue
			var path := grid.get_id_path(origin_tile, p)
			if path.size() > 0 and path.size() <= (mobility + attack_range + 1):
				attack_tiles.append(p)

	# Ensure enemy positions are included in attack_tiles (so their tiles glow purple)
	for enemy in turn_manager.enemy_queue:
		var enemy_tile := tile_map.local_to_map(enemy.global_position)
		if enemy_tile not in attack_tiles:
			attack_tiles.append(enemy_tile)

	return {"move_tiles": move_tiles, "attack_tiles": attack_tiles}



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
