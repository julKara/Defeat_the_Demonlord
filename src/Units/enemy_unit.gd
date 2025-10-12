class_name enemy_unit extends Node

@onready var character_manager: Node2D = $"../../../CharacterManager"
@onready var tile_map: TileMap = $"../../../../TileMap"
@onready var pass_turn: Button = $"../../../../GUI/Margin/ActionsMenu/VBoxContainer/Pass_Turn"
@onready var default_attack: Button = $"../../../../GUI/Margin/ActionsMenu/VBoxContainer/Default_Attack"

var astar_grid
var attack_target: CharacterBody2D

# Keeps track of what moves are performed
var attack_used: bool = false
var skill_used: bool = false

# Stat-variables
var mobility
var move_speed
var attack_range

# Maybe enemy AI will be stored here...
func _ready():
	print("Enemy unit ready — AI active.")	# TESTING
	_set_stat_variables()
	astar_grid = character_manager.current_character.astar_grid

# func _process(delta):
	# Simple AI behavior
	# print("Enemy thinking...")	# TESTING

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
	

func move():
	
	var closest_player = find_closest_player()
	
	# Create a path from the enemy to the closest player
	var id_path = (astar_grid.get_id_path(tile_map.local_to_map(get_parent().global_position),
			tile_map.local_to_map(closest_player.global_position)))
	
	# Shrink path down to be in the mobility range
	while id_path.size() > mobility + 1:
		id_path.pop_back() # Remove last element
		
	var target_position
	
	# Perform the movement
	while id_path.size() > 1: # >1 prevents enemies from standing on top of players
		target_position = tile_map.map_to_local(id_path.front())
	
		# Move towards target
		get_parent().global_position = get_parent().global_position.move_toward(target_position, move_speed)

		# Remove the tile from the path
		if get_parent().global_position == target_position:
			id_path.pop_front()
			

	
func select_attack_target():
	attack_target = find_closest_player() # Closest player character is chosen as target


func attack():
	select_attack_target()
	
	var attack_path = (astar_grid.get_id_path(tile_map.local_to_map(get_parent().global_position),
			tile_map.local_to_map(attack_target.global_position)))
			
	if attack_path.size() <= attack_range + 1:
		default_attack._pressed()
	
	attack_used = true
	
				
func play_turn():
	
	attack_used = false
	
	# Move towards the closest player
	move()
	
	# Attack
	attack()
	
	# Skill
	# TO BE IMPLEMENTED
	
	# If no attack or skill was used -> end turn
	if attack_used == false and skill_used == false:
		pass_turn._pressed()
