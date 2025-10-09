class_name enemy_unit extends Node

@onready var character_manager: Node2D = $"../../../CharacterManager"
@onready var tile_map: TileMap = $"../../../../TileMap"

var astar_grid
var attack_target: CharacterBody2D

# Maybe enemy AI will be stored here...
func _ready():
	print("Enemy unit ready — AI active.")	# TESTING
	
	astar_grid = character_manager.current_character.astar_grid

# func _process(delta):
	# Simple AI behavior
	# print("Enemy thinking...")	# TESTING


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
	
	
func select_attack_target():
	attack_target = find_closest_player() # Closest player character is chosen as target


func move():
	
	var closest_player = find_closest_player()
	
	# Create a path from the enemy to the closest player
	var id_path = (astar_grid.get_id_path(tile_map.local_to_map(get_parent().global_position),
			tile_map.local_to_map(closest_player.global_position)))
			
	var mobility = get_parent().stats.mobility
	
	# Shrink path down to be in the mobility range
	while id_path.size() > mobility + 1:
		id_path.pop_back() # Remove last element
		
	var target_position
	
	# Perform the movement
	while id_path.is_empty() == false:
		target_position = tile_map.map_to_local(id_path.front())
	
		# Move towards target
		get_parent().global_position = get_parent().global_position.move_toward(target_position, get_parent().move_speed)
	
		# Remove the tile from the path
		if get_parent().global_position == target_position:
			id_path.pop_front()
