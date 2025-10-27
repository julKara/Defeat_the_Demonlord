class_name enemy_unit extends Node

@onready var character_manager: Node2D = $"../../../CharacterManager"
@onready var tile_map: TileMap = $"../../../../TileMap"
@onready var range_tile_map: TileMap = $"../../../../RangeTileMap"
@onready var actor_info: PanelContainer = $"../../../../GUI/Margin/ActorInfo"

var battle_handler: Node = null

var astar_grid
var attack_target: Actor
var selected:bool = false

var solid_enemy_pos
var move_count

# Keeps track of what moves are performed
var attack_used: bool = false
var skill_used: bool = false

# Stat-variables
var mobility
var move_speed
var attack_range

signal ai_movement_finished

func _ready():
	
	battle_handler = BattleHandlerSingleton
	
	solid_enemy_pos = null
	
	print("Enemy unit ready — AI active.")	# TESTING
	_set_stat_variables()
	astar_grid = character_manager.current_character.astar_grid
	
	move_count = mobility

# Intialize all stat-variables through the CharacterStats resource
func _set_stat_variables():
	mobility = get_parent().stats.mobility
	move_speed = get_parent().stats.speed
	attack_range = get_parent().stats.attack_range

func find_closest_player() -> CharacterBody2D:
		
	# Define the longest possible path, which will later be updated
	var shortest_path
	var closest_player: CharacterBody2D
	var counter = 1
	
	# Find the shortest path from the enemy to a player
	for x in character_manager.character_list:
		if x.is_friendly == true: # Only look at friendly player characters
			
			# Path from the enemy to a player
			var temp = (astar_grid.get_id_path(tile_map.local_to_map(get_parent().global_position),
			tile_map.local_to_map(x.global_position)))
			
			# Assign shortest path on first loop, allowing for comparison
			if counter == 1:
				shortest_path = (astar_grid.get_id_path(tile_map.local_to_map(get_parent().global_position),
				tile_map.local_to_map(x.global_position)))

			# If the current path is shorter than the previous shortest path, update shortest_path and closest_player
			if temp.size() <= shortest_path.size():
				shortest_path = temp
				closest_player = x
				
			counter += 1

	return closest_player
	

# Calculate the shortest path from the enemy to the closest player
func calculate_path() -> Array[Vector2i]:
	var closest_player = find_closest_player()
	var id_path
	
	if closest_player != null:
		# Create a path from the enemy to the closest player
		id_path = (astar_grid.get_id_path(tile_map.local_to_map(get_parent().global_position),
				tile_map.local_to_map(closest_player.global_position)))
		
		# Shrink path down to be in the mobility range
		while id_path.size() > mobility + attack_range + 1: # attack_range+1 allows enemy to move full distance
			id_path.pop_back() # Remove last element
		
		return id_path
	else:
		return [] # Prevents crash at game over


func avoid_penalty(id_path: Array[Vector2i]):
	
	var enemy_pos = id_path[0]
	var target_pos = id_path[id_path.size() - 1]
	var move_pos = enemy_pos
	var relative_pos: String
	var final_path: Array[Vector2i] = [enemy_pos]
	
	# Find the position of the enemy relative to the target
	if target_pos.y - enemy_pos.y < 0 and target_pos.x == enemy_pos.x:
		relative_pos = "Down"
	elif target_pos.y - enemy_pos.y > 0 and target_pos.x == enemy_pos.x:
		relative_pos = "Up"
	elif target_pos.y == enemy_pos.y and target_pos.x - enemy_pos.x < 0:
		relative_pos = "Right"
	elif target_pos.y == enemy_pos.y and target_pos.x - enemy_pos.x > 0:
		relative_pos = "Left"
	
	# Depending on the relative position, try to move away one tile
	match relative_pos:
		"Down":
			# If possible -> move down
			if (astar_grid.is_point_solid(Vector2i(enemy_pos.x, enemy_pos.y + 1)) == false
			and check_if_occupied([enemy_pos, Vector2i(enemy_pos.x, enemy_pos.y + 1)]) == false):
				move_pos.y += 1
			# If not possible -> try moving left
			elif (astar_grid.is_point_solid(Vector2i(enemy_pos.x - 1, enemy_pos.y)) == false
			and check_if_occupied([enemy_pos, Vector2i(enemy_pos.x - 1, enemy_pos.y)]) == false):
				move_pos.x -= 1
			# If not possible -> try moving right
			elif (astar_grid.is_point_solid(Vector2i(enemy_pos.x + 1, enemy_pos.y)) == false
			and check_if_occupied([enemy_pos, Vector2i(enemy_pos.x + 1, enemy_pos.y)]) == false):
				move_pos.x += 1
		"Up":
			# If possible -> move up
			if (astar_grid.is_point_solid(Vector2i(enemy_pos.x, enemy_pos.y - 1)) == false
			and check_if_occupied([enemy_pos, Vector2i(enemy_pos.x, enemy_pos.y - 1)]) == false):
				move_pos.y -= 1
			# If not possible -> try moving left
			elif (astar_grid.is_point_solid(Vector2i(enemy_pos.x - 1, enemy_pos.y)) == false
			and check_if_occupied([enemy_pos, Vector2i(enemy_pos.x - 1, enemy_pos.y)]) == false):
				move_pos.x -= 1
			# If not possible -> try moving right
			elif (astar_grid.is_point_solid(Vector2i(enemy_pos.x + 1, enemy_pos.y)) == false
			and check_if_occupied([enemy_pos, Vector2i(enemy_pos.x + 1, enemy_pos.y)]) == false):
				move_pos.x += 1
		"Right":
			# If possible -> move right
			if (astar_grid.is_point_solid(Vector2i(enemy_pos.x + 1, enemy_pos.y)) == false
			and check_if_occupied([enemy_pos, Vector2i(enemy_pos.x + 1, enemy_pos.y)]) == false):
				move_pos.x += 1
			# If not possible -> try moving up
			elif (astar_grid.is_point_solid(Vector2i(enemy_pos.x, enemy_pos.y - 1)) == false
			and check_if_occupied([enemy_pos, Vector2i(enemy_pos.x, enemy_pos.y - 1)]) == false):
				move_pos.y -= 1
			# If not possible -> try moving down
			elif (astar_grid.is_point_solid(Vector2i(enemy_pos.x, enemy_pos.y + 1)) == false
			and check_if_occupied([enemy_pos, Vector2i(enemy_pos.x, enemy_pos.y + 1)]) == false):
				move_pos.y += 1
		"Left":
			# If possible -> move left
			if (astar_grid.is_point_solid(Vector2i(enemy_pos.x - 1, enemy_pos.y)) == false
			and check_if_occupied([enemy_pos, Vector2i(enemy_pos.x - 1, enemy_pos.y)]) == false):
				move_pos.x -= 1
			# If not possible -> try moving up
			elif (astar_grid.is_point_solid(Vector2i(enemy_pos.x, enemy_pos.y - 1)) == false
			and check_if_occupied([enemy_pos, Vector2i(enemy_pos.x, enemy_pos.y - 1)]) == false):
				move_pos.y -= 1
			# If not possible -> try moving down
			elif (astar_grid.is_point_solid(Vector2i(enemy_pos.x, enemy_pos.y + 1)) == false
			and check_if_occupied([enemy_pos, Vector2i(enemy_pos.x, enemy_pos.y + 1)]) == false):
				move_pos.y += 1
		
	if move_pos != enemy_pos:
		final_path.append(move_pos)	
		perform_movement(final_path, 0)
		# If still in range penalty after moving away, try again until all mobility is used
		move_count -= 1
		await get_tree().create_timer(1.0).timeout
		var check_adjacency = calculate_path()
		if check_adjacency.size()-1 < 2 and move_count > 0:
			avoid_penalty(check_adjacency)


func move():

	var id_path = calculate_path()
	
	# Only move if there is a path to move along
	if id_path.is_empty() == false:
		
		# If the enemy will get a range penalty -> move away
		if id_path.size()-1 < 2 and attack_range >= 2:
			move_count = mobility
			avoid_penalty(id_path)
		# Otherwise perform movement like normal
		else:	
			var occupied = check_if_occupied(id_path)
			
			# If the final destination is occupied -> recalculate path without the occupied tile
			if occupied == true:
				id_path = calculate_path()
			
			# Perform the movement
			perform_movement(id_path, attack_range)
		
		# Large timer needed, otherwise the attack is based on the start position rather than the final position
		await get_tree().create_timer(1.0).timeout
		
		# If a tile was set to be solid -> reset it back to "not solid" after the move is done
		if solid_enemy_pos != null:
			astar_grid.set_point_solid(solid_enemy_pos, false)
		
		emit_signal("ai_movement_finished")	

# Check if the final destination of the enemy is occupied by a different enemy
func check_if_occupied(id_path: Array[Vector2i]) -> bool:
	for character in character_manager.character_list:
		if character.is_friendly == false and character != get_parent():
			# The index of the tile the enemy will stop at. They always stops as soon as they're in range.
			var index = id_path.size() - attack_range - 1 
			if id_path[index] == tile_map.local_to_map(character.global_position):
				solid_enemy_pos = tile_map.local_to_map(character.global_position)
				# If the tile is occupied -> set tile to solid. The tile will then not be includen in pathfinding
				astar_grid.set_point_solid(solid_enemy_pos, true)
				return true
	return false


func perform_movement(id_path: Array[Vector2i], target_dist: int):
	# Flip sprite based on move direction
	calculate_direction(id_path)
	
	var target_position
	while id_path.size() > target_dist: 
			target_position = tile_map.map_to_local(id_path.front())
			
			# Move towards target
			get_parent().global_position = get_parent().global_position.move_toward(target_position, move_speed)
			await get_tree().create_timer(0.01).timeout # Adds a delay which lets the move animation play
			
			# Remove the tile from the path
			if get_parent().global_position == target_position:
				id_path.pop_front()


func calculate_direction(path: Array[Vector2i]):
	var start = path[0]
	var end = path[path.size()-1]
	var sprite = get_parent().get_sprite()
	
	if start.x - end.x > 0: # Left
		sprite.flip_h = true
	else: # Right
		sprite.flip_h = false

	
func select_attack_target():
	attack_target = find_closest_player() # Closest player character is chosen as target


func attack():

	print("\t\tTarget selected: ", attack_target.profile.character_name)

	if attack_target != null:
		# Set up attacker and target, and define damage from physical attack stat
		var attacker: Actor = get_parent()
		var target: Actor = attack_target
		
		# Distance between attacker and target, influences damage
		var dist: float = attacker.position.distance_to(target.position)
		
		# Perform battle and wait for it to finish
		await battle_handler.perform_battle(attacker, target, dist)
		
		# Do a counter-attack if target is still alive and withing range
		if target.stats.curr_health > 0:
			
			var target_range = target.stats.attack_range
			
			# Only counterattack if attacker is within target’s range
			if target_range * attacker.tile_size >= dist:
				print("\t\t\tCounter!")
				await battle_handler.perform_battle(target, attacker, dist)
				
		attack_used = true
	
				
func play_turn():
	
	attack_used = false
	skill_used = false
	
	# Move towards the closest player
	move()
	await ai_movement_finished
	
	# Set attack_target
	await select_attack_target()
	
	# Attack
	if attack_target != null:
		await attack()

	# Skill
	# TO BE IMPLEMENTED
	
	# Log enemy passed their turn
	if attack_used == false and skill_used == false:
		print("\t", get_parent().profile.character_name, " has ended their turn.")


# --- Selection logic ---
func highlight_enemy_range() -> void:
	range_tile_map.clear_layer(0)
	range_tile_map.clear_layer(1)

	var parent = get_parent()
	if not parent.astar_grid:
		return
	
	var astar = parent.astar_grid
	var grid_size = astar.get_size()

	# Convert the actor's position to grid coordinates
	var start = range_tile_map.local_to_map(parent.global_position)

	for x in range(grid_size.x):
		for y in range(grid_size.y):
			
			# Get point
			var point = Vector2i(x, y)
			if astar.is_point_solid(point):
				continue

			# get_point_path expects grid coordinates
			var path = astar.get_point_path(start, point)
			if path.is_empty():
				continue

			# Add range
			if path.size() <= (mobility + 1):
				range_tile_map.set_cell(1, point, 1, Vector2i(0, 1), 0)
			elif path.size() <= (mobility + attack_range + 1):
				range_tile_map.set_cell(0, point, 1, Vector2i(1, 1), 0)

func select(_has_acted: bool) -> void:	# Has to have input for override to function
	
	# Update state
	selected = true
	get_parent().set_state(get_parent().UnitState.SELECTED)
	
	# Set selected_unit in click_handler
	ClickHandler.selected_unit = get_parent() 
	
	# Display info
	actor_info.display_actor_info(get_parent())
	
	# Display mobility- and range-tilemap
	highlight_enemy_range()
	print("\tEnemy selected:", get_parent().profile.character_name)
	
func deselect() -> void:
	
	# Update state
	selected = false
	get_parent().set_state(get_parent().UnitState.IDLE)
	
	# Set selected_unit in click_handler
	ClickHandler.selected_unit = null
	
	# Clear mobility- and range-map
	range_tile_map.clear_layer(0)
	range_tile_map.clear_layer(1)
	
	# Hide gui
	actor_info.hide_actor_info()
