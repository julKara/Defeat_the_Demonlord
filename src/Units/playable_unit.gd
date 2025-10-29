class_name playable_unit extends Node

# Refrences to objects
@onready var tile_map: TileMap = $"../../../../TileMap"
@onready var range_tile_map: TileMap = $"../../../../RangeTileMap"
@onready var draw_path: Node2D = $"../../../../DrawPath"
@onready var character_manager: Node2D = $"../../../CharacterManager"
@onready var actions_menu: PanelContainer = $"../../../../GUI/Margin/ActionsMenu"
@onready var actor_info: PanelContainer = $"../../../../GUI/Margin/ActorInfo"
@onready var turn_manager: Node2D = $"../../../TurnManager"
@onready var default_attack: Button = $"../../../../GUI/Margin/ActionsMenu/VBoxContainer/Default_Attack"
@onready var skill_menu: PanelContainer = $"../../../../GUI/Margin/SkillMenu"
@onready var skill_1: Button = $"../../../../GUI/Margin/SkillMenu/VBoxContainer/Skill1"
@onready var skill_2: Button = $"../../../../GUI/Margin/SkillMenu/VBoxContainer/Skill2"


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
	mobility = stats.curr_mobility
	#move_speed = stats.speed
	attack_range = stats.curr_attack_range

# --- Movement ---
func move_to(tile: Vector2i) -> void:

	# Only allow movement within mobility range
	var range_data = get_range_tiles()
	var move_tiles: Array[Vector2i] = range_data.move_tiles
	if tile not in move_tiles:
		print("Destination not within mobility range!")
		return
	# Reset grid and mark enemies as solid
	get_parent().reset_astar_grid()
	var grid = get_parent().astar_grid
	for enemy in turn_manager.enemy_queue:
		var pos := tile_map.local_to_map(enemy.global_position)
		grid.set_point_solid(pos, true)
	# Get safe path
	var id_path = grid.get_id_path(origin_tile, tile)
	if id_path.is_empty():
		print("No path found, blocked by solid tiles!")
		return

	# Store a copy for drawing
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
	current_tile = tile
	
	# Clear target visuals after moving
	if attack_target != null:
		var sprite = attack_target.get_node("Sprite")
		sprite.material.set("shader_parameter/width", 0.0)
		attack_target = null
		default_attack.disabled = true
		skill_1.disabled = true
		skill_2.disabled = true


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
	
	get_parent().passed_turn = false	# Reset
	if get_parent().skills.size() > 0:
		skill_1.skill = get_parent().skills[0]
		skill_1.disabled = false
		skill_2.skill = get_parent().skills[1]
		skill_2.disabled = false
	
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
	skill_menu.hide_skill_menu()	# Must be first
	actions_menu.hide()
	actor_info.hide_actor_info()
	
	# Reset skill-buttons
	skill_1.skill = null
	skill_1.text = "skill1"
	skill_1.disabled = true
	skill_1.click_count = 0
	
	skill_2.skill = null
	skill_2.text = "skill2"
	skill_2.disabled = true
	skill_2.click_count = 0
	
	# Remove target-highlight if the is one
	if attack_target:
		var sprite = attack_target.get_node("Sprite")
		sprite.material.set("shader_parameter/width", 0.0)
		attack_target = null
		default_attack.disabled = true
		
# --- Range Highlight ---

# Display the range of a selected unit
func highlight_range() -> void:
	
	range_tile_map.clear_layer(0) # purple
	range_tile_map.clear_layer(1) # blue

	var data := get_range_tiles()
	var move_tiles: Array[Vector2i] = data.move_tiles
	var attack_tiles: Array[Vector2i] = data.attack_tiles

	# mobility = blue tiles
	for t in move_tiles:
		range_tile_map.set_cell(1, t, 1, Vector2i(0, 1), 0)

	# attack range = purple tiles
	for t in attack_tiles:
		range_tile_map.set_cell(0, t, 1, Vector2i(1, 1), 0)

# --- UTIL ---

# Returns two arrays containing tiles within mobility-range and mobility-attack-range 
func get_range_tiles() -> Dictionary:
	
	# The two returns
	var move_tiles: Array[Vector2i] = []
	var attack_tiles: Array[Vector2i] = []

	# Test astar
	var parent = get_parent()
	var astar = parent.astar_grid
	if not astar:
		return {"move_tiles": move_tiles, "attack_tiles": attack_tiles}

	# --- 1. Compute move_tiles using a grid where enemies are solid (can't move into them)
	get_parent().reset_astar_grid()	# Reset just in case
	var grid: AStarGrid2D = get_parent().astar_grid

	# Mark enemy positions as solid so they block mobility
	for enemy in turn_manager.enemy_queue:
		var epos := tile_map.local_to_map(enemy.global_position)
		grid.set_point_solid(epos, true)

	var grid_size := grid.get_size()
	
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			
			var pos = Vector2i(x, y)
			if grid.is_point_solid(pos):	# Skip solid tiles
				continue
				
			# Add tiles within mobility-range to move_tiles
			var path := grid.get_id_path(origin_tile, pos)
			if path.size() > 0 and path.size() <= (mobility + 1):
				move_tiles.append(pos)

	# --- 2. Compute attack_tiles by expanding from each reachable tile and origin
	# REMINDER: Effective distance where diagonals cost +1 (aka range less over diagonals)

	# Copy move_tiles to not change anything
	var move_to_tiles: Array[Vector2i] = move_tiles.duplicate()

	# Work from base grid (terrain-only) to check walkability
	get_parent().reset_astar_grid()

	# Add all enemies at their position to array, for check later
	var actor_at_tile := {}
	for enemy in turn_manager.enemy_queue:
		actor_at_tile[tile_map.local_to_map(enemy.global_position)] = enemy

	var attack_set := {}
	for tile in move_to_tiles:
		var min_x = max(0, tile.x - attack_range)
		var max_x = min(grid_size.x - 1, tile.x + attack_range)
		var min_y = max(0, tile.y - attack_range)
		var max_y = min(grid_size.y - 1, tile.y + attack_range)

		for tx in range(min_x, max_x + 1):
			for ty in range(min_y, max_y + 1):
				var target = Vector2i(tx, ty)

				# Skip empty non-walkable tiles, allow targeting occupied non-walkable tiles (enemies on non-walkable places like demonlord)
				var tile_data = tile_map.get_cell_tile_data(0, target)
				if (tile_data == null or tile_data.get_custom_data("walkable") == false) and not (target in actor_at_tile):
					continue

				# Calculate effective attack-distance
				var eff = _effective_distance(tile, target)
				if eff <= attack_range:
					attack_set[target] = true

	# Convert attack_set to list
	for k in attack_set.keys():
		attack_tiles.append(k)

	# --- 3. Blue (move_tiles) should be prioritized — remove any attack tiles that are also movable	NOT NECESSARY ANYMORE (but maybe later...)
	#for t in move_tiles:
		#if t in attack_tiles:
			#attack_tiles.erase(t)

	return {"move_tiles": move_tiles, "attack_tiles": attack_tiles}


# Effective distance where diagonals cost +1
func _effective_distance(a: Vector2i, b: Vector2i) -> int:
	var dx = abs(a.x - b.x)
	var dy = abs(a.y - b.y)
	var eff = max(dx, dy)
	if dx > 0 and dy > 0:
		eff += 1
	return eff


func set_attack_target(target: Actor) -> void:
	
	# Make attack-button usable
	default_attack.disabled = false
	
	# Make skill if requiring enemy attack-target enabled
	if get_parent().skills.size() > 0:
		if skill_1.skill.target_type == "Enemy":
			skill_1.disabled = false
		if skill_2.skill.target_type == "Enemy":
			skill_2.disabled = false
	
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
