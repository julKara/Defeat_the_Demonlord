@tool	# Remove near end (heavy on performance)

class_name Actor extends CharacterBody2D

""" Unit-Unique Reasources """
@export var stats: CharacterStats	# All stats to particular unit
@export var profile: UnitProfile	# All other unique aspects of a unit (name, skills, talent...)

# CONSTANTS
const FRIENDLY_COLOR: Color = Color("00a78f")
const ENEMY_COLOR: Color = Color.CRIMSON

# Refrences to objects in actor
@onready var shape = $CollisionShape2D	# TODO: Will be changed to healthbar instead
var behavior: Node = null	# Decides behavior based on if unit is playable, enemy, npc...
@onready var sprite_2d: Sprite2D = $Sprite
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# Refrences to objects in World
@onready var tile_map: TileMap = $"../../../TileMap"
@onready var draw_path: Node2D = $"../../../DrawPath"
@onready var character_manager: Node2D = $"../../CharacterManager"
@onready var pass_turn: Button = $"../../../GUI/Margin/ActionsMenu/VBoxContainer/Pass_Turn"
@onready var actions_menu: PanelContainer = $"../../../GUI/Margin/ActionsMenu"
@onready var actor_info: PanelContainer = $"../../../GUI/Margin/ActorInfo"

# Variables for movement
var astar_grid: AStarGrid2D
var current_id_path: Array[Vector2i]
var target_position: Vector2
var is_moving: bool
var current_point_path: PackedVector2Array
var tile_size: int = 48
var selected: bool = false
var start_position: Vector2i

# Stat-variables
var move_speed: float = 3.0	# 3.0 is considered default speed
var mobility: int = 3	# 3 is considered default mobility

# Export lets you toggle this in the inspector
@export var is_friendly: bool = false:
	set(value):
		is_friendly = value
		if is_node_ready():	# Must check if modulate should work
			_reload_behavior()	# Set/Toggles behavior

# Sets up AstarGrid for pathfinding, walkable tiles and sets friendly/enemy color/name
func _ready() -> void:	
	
	# Intialize all stat-variables through the CharacterStats resource
	_set_stat_variables()
	
	# Apply unit profile to current instance of actor
	_apply_profile()
	
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
	
	start_position = tile_map.local_to_map(global_position)
	
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

# Intialize all stat-variables through the CharacterStats resource (NEW from Julia)
func _set_stat_variables():
	if stats == null:
		return
	
	mobility = stats.mobility
	move_speed = stats.speed

# Apply unit profile to current instance of actor
func _apply_profile() -> void:
	if profile == null:
		return

	# Apply sprite of unit if there is one
	if sprite_2d and profile.sprite:
		sprite_2d.texture = profile.sprite

	# Apply idle-animation of unit if there is one
	if anim_player and profile.animation:
		anim_player.add_animation_library("default", profile.animation)

# Function that creates a path towards the selected tile
func _input(event):
	
	# Don't do anything unless the mouse is pressed
	if event.is_action_pressed("left_mouse_button") == false:
		return

	# Don't run the code if the mouse clicks outside of the map
	if (tile_map.local_to_map(get_global_mouse_position()).x > (tile_map.get_used_rect().size.x - 1) or
	tile_map.local_to_map(get_global_mouse_position()).y > (tile_map.get_used_rect().size.y - 1)):
		return
	
	# Click to select a character and display move range
	if (selected == false and
	tile_map.local_to_map(get_global_mouse_position()) == tile_map.local_to_map(global_position)):	
		# Prevents multiple characters being selected at once
		var all_characters_deselected: bool = true
		for x in character_manager.character_list:
			if x.selected:
				all_characters_deselected = false
				
		# This part is only meant to be run when no characters are selected
		# Above check ensures that
		if all_characters_deselected:
			character_manager.current_character = self
			pass_turn.counter = character_manager.character_list.find(self,0) + 1
			highlight_mobility_range()
			actions_menu.show()	# Show actions-menu when selecting actor
			actor_info.display_actor_info(character_manager.current_character) # Show actor info
			
		
	# Click to deselect character and hide move range
	elif (selected == true and
	tile_map.local_to_map(get_global_mouse_position()) == tile_map.local_to_map(global_position)):
		tile_map.clear_layer(1)
		selected = false
		draw_path.hide()
		global_position = tile_map.map_to_local(start_position)
		actions_menu.hide()	# Hide actions-menu when deselecting actor
		actor_info.hide_actor_info()
	
	# If a playable character is selected, perform the movement	
	elif (selected == true and
	tile_map.local_to_map(get_global_mouse_position()) != tile_map.local_to_map(global_position) and is_friendly):

		draw_path.show()

		var id_path
		
		if is_moving:
			id_path = astar_grid.get_id_path(
				tile_map.local_to_map(target_position),
				tile_map.local_to_map(get_global_mouse_position())
			)
		else:
			# Finds the coordinates on the grid of the selected tile and the path to get there
			id_path = astar_grid.get_id_path(
				start_position,
				tile_map.local_to_map(get_global_mouse_position())
			)
		
		# Calculate the path when the player cooses a new tile after already moving
		var changed_id_path
		if tile_map.local_to_map(global_position) != tile_map.local_to_map(start_position):
			changed_id_path = astar_grid.get_id_path(
				tile_map.local_to_map(global_position),
				start_position
			)
		
		var destination_occupied: bool = false
		for x in character_manager.character_list:
			if tile_map.local_to_map(get_global_mouse_position()) == tile_map.local_to_map(x.global_position):
				destination_occupied = true
				x.selected = false
				character_manager.current_character = self
				#stand_button.counter = character_manager.character_list.find(self,0) + 1
				highlight_mobility_range()
		
		# Only perform the movement if the path is valid and within range
		if id_path.is_empty() == false and id_path.size() <= mobility + 1 and destination_occupied == false:
			# Assign path depending on if it is the first move or the player changed their mind
			if tile_map.local_to_map(global_position) == tile_map.local_to_map(start_position):
				current_id_path = id_path
			else:
				changed_id_path.append_array(id_path)
				current_id_path = changed_id_path
			
			# Used for drawing the line for the path
			current_point_path = astar_grid.get_point_path(
				start_position,
				tile_map.local_to_map(get_global_mouse_position())
			)

			for i in current_point_path.size():
				current_point_path[i] += Vector2(tile_size/2, tile_size/2)

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
	global_position = global_position.move_toward(target_position, move_speed)
	
	# Remove the tile from the path
	if global_position == target_position:
		current_id_path.pop_front()
		
		# If there are still tiles in the path, select the next one
		if current_id_path.is_empty() == false:
			target_position = tile_map.map_to_local(current_id_path.front())
		else:
			is_moving = false

func highlight_mobility_range():
	# Variable used to calculate the tiles withing moving rang
	var mobility_path
	
	# Reset prevoius highlight. Prevents highlighting several characters at once
	tile_map.clear_layer(1)
		
	# Go through the entire grid and highlight the tiles that are possible to move to
	# depending on the characters mobility	
	for x in astar_grid.get_size().x:
		for y in astar_grid.get_size().y:
			# Skip tiles that are not "walkable"
			if astar_grid.is_point_solid(Vector2i(x,y)):
				continue
			# Calculate the path from the character to the current tile (x,y)
			mobility_path = astar_grid.get_id_path(
				start_position,
				Vector2i(x,y)
			)
				
			# Draw tiles with a path to it that is within the range
			if mobility_path.size() <= (mobility + 1): # mobility+1 since path includes start position
				tile_map.set_cell(1, Vector2i(x,y), 0, Vector2i(0,1), 0)
	
	selected = true
