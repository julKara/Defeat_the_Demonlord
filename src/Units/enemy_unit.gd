class_name enemy_unit extends Node

@onready var character_manager: Node2D = $"../../../CharacterManager"
@onready var tile_map: TileMap = $"../../../../TileMap"
@onready var pass_turn: Button = $"../../../../GUI/Margin/ActionsMenu/VBoxContainer/Pass_Turn"
#@onready var battle_handler: BattleHandler = $BattleHandler

var battle_handler: Node = null

var astar_grid
var attack_target: CharacterBody2D
var selected:bool = false

# Keeps track of what moves are performed
var attack_used: bool = false
var skill_used: bool = false

# Stat-variables
var mobility
var move_speed
var attack_range

signal ai_movement_finished

# Maybe enemy AI will be stored here...
func _ready():
	
	battle_handler = BattleHandlerSingleton
	
	print("Enemy unit ready — AI active.")	# TESTING
	_set_stat_variables()
	astar_grid = character_manager.current_character.astar_grid

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
	
	if closest_player != null:
		# Create a path from the enemy to the closest player
		var id_path = (astar_grid.get_id_path(tile_map.local_to_map(get_parent().global_position),
				tile_map.local_to_map(closest_player.global_position)))
		
		
		# Shrink path down to be in the mobility range
		while id_path.size() > mobility + attack_range + 1: # attack_range+1 allows enemy to move full distance
			id_path.pop_back() # Remove last element
			
		for character in character_manager.character_list:
			if character.is_friendly == false and character != get_parent():
				print(id_path)
				var index = id_path.size() - attack_range - 1
				print(tile_map.local_to_map(character.global_position))
				print(id_path[index])
				if id_path[index] == tile_map.local_to_map(character.global_position):
					id_path.pop_back()
				print(id_path)
			
		var target_position
		
		# Perform the movement
		while id_path.size() > attack_range: # >attack_range stops enemies when in range
			target_position = tile_map.map_to_local(id_path.front())
			
			# Move towards target
			get_parent().global_position = get_parent().global_position.move_toward(target_position, move_speed)
			await get_tree().create_timer(0.01).timeout # Adds a delay which lets the move animation play
			
			# Remove the tile from the path
			if get_parent().global_position == target_position:
				id_path.pop_front()
		
		await get_tree().create_timer(0.01).timeout
		emit_signal("ai_movement_finished")	

	
func select_attack_target():
	attack_target = find_closest_player() # Closest player character is chosen as target


func attack():
	
	print("\t\tTarget selected: ", attack_target.profile.character_name)

	var attack_path = (astar_grid.get_id_path(tile_map.local_to_map(get_parent().global_position),
			tile_map.local_to_map(attack_target.global_position)))
			
	if attack_path.size() <= attack_range + 1 && attack_target != null:
		
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
