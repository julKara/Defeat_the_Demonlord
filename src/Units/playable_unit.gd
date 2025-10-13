class_name playable_unit extends Node

# Refrences to objects
@onready var tile_map: TileMap = $"../../../../TileMap"
@onready var draw_path: Node2D = $"../../../../DrawPath"
@onready var character_manager: Node2D = $"../../../CharacterManager"
@onready var pass_turn: Button = $"../../../../GUI/Margin/ActionsMenu/VBoxContainer/Pass_Turn"
@onready var actions_menu: PanelContainer = $"../../../../GUI/Margin/ActionsMenu"
@onready var actor_info: PanelContainer = $"../../../../GUI/Margin/ActorInfo"

# Variables for movement
var current_id_path: Array[Vector2i]
var target_position: Vector2
var is_moving: bool
var current_point_path: PackedVector2Array
var selected: bool = false
var start_position: Vector2i
var destination_occupied: bool = false

# Variables for attacks
var attack_target: CharacterBody2D

# Stat-variables
var move_speed: float = 3.0	# 3.0 is considered default speed
var mobility: int = 3	# 3 is considered default mobility
var attack_range: int = 1 # 1 is considered default attack range

# Playable elements...
func _ready():
	print("Playable unit ready — player-controlled!")	# TESTING
	
	# Intialize all stat-variables through the CharacterStats resource
	_set_stat_variables()
	
	start_position = tile_map.local_to_map(get_parent().global_position)
	
	# No attack target by default
	attack_target = null



# Intialize all stat-variables through the CharacterStats resource (NEW from Julia)
func _set_stat_variables():
	mobility = get_parent().stats.mobility
	move_speed = get_parent().stats.speed
	attack_range = get_parent().stats.attack_range


# Function that creates a path towards the selected tile
func _input(event):
	
	# Don't do anything unless the mouse is pressed
	if event.is_action_pressed("left_mouse_button") == false:
		return

	# Don't run the code if the mouse clicks outside of the map
	if (tile_map.local_to_map(get_parent().get_global_mouse_position()).x > (tile_map.get_used_rect().size.x - 1) or
	tile_map.local_to_map(get_parent().get_global_mouse_position()).y > (tile_map.get_used_rect().size.y - 1)):
		return
	
	destination_occupied = false
	
	# Click to select a character and display move range
	if (selected == false and
	tile_map.local_to_map(get_parent().get_global_mouse_position()) == tile_map.local_to_map(get_parent().global_position)):	
		# Prevents multiple characters being selected at once
		var all_characters_deselected: bool = true
		for character in character_manager.character_list:
			var all_children = character.get_children()
			var behaviour_node
		
			for child in all_children:
				if child is Node:
					behaviour_node = child
			if behaviour_node.selected:
				all_characters_deselected = false
				
		# This part is only meant to be run when no characters are selected
		# Above check ensures that
		if all_characters_deselected:
			character_manager.current_character = get_parent()
			pass_turn.counter = character_manager.character_list.find(get_parent(),0) + 1
			highlight_range()
			actions_menu.show()	# Show actions-menu when selecting actor
			actor_info.display_actor_info(character_manager.current_character) # Show actor info
			
		
	# Click to deselect character and hide move range
	elif (selected == true and
	tile_map.local_to_map(get_parent().get_global_mouse_position()) == tile_map.local_to_map(get_parent().global_position)):
		tile_map.clear_layer(1)
		tile_map.clear_layer(2)
		selected = false
		draw_path.hide()
		get_parent().global_position = tile_map.map_to_local(start_position)
		actions_menu.hide()	# Hide actions-menu when deselecting actor
		actor_info.hide_actor_info()
		attack_target = null # Remove target after deselecting

	
	# If a playable character is selected, perform the movement	
	elif (selected == true and
	tile_map.local_to_map(get_parent().get_global_mouse_position()) != tile_map.local_to_map(get_parent().global_position) 
	and get_parent().is_friendly):

		draw_path.show()

		var id_path
		
		if is_moving:
			# Prevents spam clicking
			return
		else:
			# Finds the coordinates on the grid of the selected tile and the path to get there
			id_path = get_parent().astar_grid.get_id_path(
				start_position,
				tile_map.local_to_map(get_parent().get_global_mouse_position())
			)
		
		# Calculate the path when the player cooses a new tile after already moving
		var changed_id_path
		if tile_map.local_to_map(get_parent().global_position) != tile_map.local_to_map(start_position):
			changed_id_path = get_parent().astar_grid.get_id_path(
				tile_map.local_to_map(get_parent().global_position),
				start_position
			)
		
		
		for character in character_manager.character_list:
			if tile_map.local_to_map(get_parent().get_global_mouse_position()) == tile_map.local_to_map(character.global_position):
				var all_children = character.get_children()
				var behaviour_node
		
				for child in all_children:
					if child is Node:
						behaviour_node = child
				
				destination_occupied = true
				behaviour_node.selected = false
				character_manager.current_character = get_parent()
				#stand_button.counter = character_manager.character_list.find(self,0) + 1
				highlight_range()
		
		# Only perform the movement if the path is valid and within range
		if id_path.is_empty() == false and id_path.size() <= mobility + 1 and destination_occupied == false:
			# Assign path depending on if it is the first move or the player changed their mind
			if tile_map.local_to_map(get_parent().global_position) == tile_map.local_to_map(start_position):
				current_id_path = id_path
			else:
				changed_id_path.append_array(id_path)
				current_id_path = changed_id_path
			
			# Used for drawing the line for the path
			current_point_path = get_parent().astar_grid.get_point_path(
				start_position,
				tile_map.local_to_map(get_parent().get_global_mouse_position())
			)

			for i in current_point_path.size():
				current_point_path[i] += Vector2(get_parent().tile_size/2, get_parent().tile_size/2)
	
	# Attack target selection			
	if selected == true and destination_occupied == true:
		for x in character_manager.character_list:
			if tile_map.local_to_map(get_parent().get_global_mouse_position()) == tile_map.local_to_map(x.global_position):
				var attack_path = get_parent().astar_grid.get_id_path(
				tile_map.local_to_map(get_parent().global_position),
				tile_map.local_to_map(x.global_position))
				
				if attack_path.size() <= (attack_range + 1):
					attack_target = x


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
	get_parent().global_position = get_parent().global_position.move_toward(target_position, move_speed)
	
	# Remove the tile from the path
	if get_parent().global_position == target_position:
		current_id_path.pop_front()
		
		# If there are still tiles in the path, select the next one
		if current_id_path.is_empty() == false:
			target_position = tile_map.map_to_local(current_id_path.front())
		else:
			is_moving = false


func highlight_range():
	# Variable used to calculate the tiles withing moving rang
	var mobility_path
	
	# Reset prevoius highlight. Prevents highlighting several characters at once
	tile_map.clear_layer(1)
	tile_map.clear_layer(2)
		
	# Go through the entire grid and highlight the tiles that are possible to move to
	# depending on the characters mobility and the tiles that are within attack range
	for x in get_parent().astar_grid.get_size().x:
		for y in get_parent().astar_grid.get_size().y:
			# Skip tiles that are not "walkable"
			if get_parent().astar_grid.is_point_solid(Vector2i(x,y)):
				continue
			# Calculate the path from the character to the current tile (x,y)
			mobility_path = get_parent().astar_grid.get_id_path(
				start_position,
				Vector2i(x,y)
			)
				
			# Draw tiles with a path to it that is within the mobility range
			if mobility_path.size() <= (mobility + 1): # mobility+1 since path includes start position
				tile_map.set_cell(2, Vector2i(x,y), 0, Vector2i(0,1), 0)
			
			# Draw tiles with a path to it that is within the attack range
			if mobility_path.size() <= (mobility + attack_range + 1): # mobility+1 since path includes start position
				tile_map.set_cell(1, Vector2i(x,y), 0, Vector2i(1,1), 0)
	
	selected = true
