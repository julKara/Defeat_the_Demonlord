@tool	# Remove near end (heavy on performance)

class_name Actor extends CharacterBody2D
"""
# This class manages everything concerning the units in the level (both playable and enemies). 
# It stores important information such as state and is_friendly but also setters and initialzers
# for most info.
"""


""" Unit-Unique Reasources """
@export var stats: CharacterStats	# All stats to particular unit
@export var profile: UnitProfile	# All other unique aspects of a unit (name, skills, talent...)
var anim_library_name := "default"	# Liberary name for unit-animations, is the .tres file attached to profile

# CONSTANTS
const FRIENDLY_COLOR: Color = Color("00a78f")
const ENEMY_COLOR: Color = Color.CRIMSON
enum UnitState { IDLE, SELECTED, MOVING, ATTACKING, DEAD }	# Possible unit-states
var state_to_anim = {	# For animation filepaths
		UnitState.IDLE: "idle",
		UnitState.SELECTED: "selected",
		UnitState.MOVING: "move",
		UnitState.ATTACKING: "attack",
		UnitState.DEAD: "dead"
	}

# Refrences to objects in actor
var behavior: Node = null	# Decides behavior based on if unit is playable, enemy, npc...
@onready var sprite_2d: Sprite2D = $Sprite	# Just the default sprite to all characters
@onready var anim_player: AnimationPlayer = $AnimationPlayer	# Used to play animations
@onready var healthbar: ProgressBar = $Healthbar	# The units healthbar, gets set up in _ready()


# Refrences to objects in World
@onready var tile_map: TileMap = $"../../../TileMap"

# Variables for movement
var astar_grid: AStarGrid2D
var tile_size: int = 48

""" Unit info while in gameplay: """
var selected: bool = false	# True if unit is selected
var current_state: UnitState = UnitState.IDLE	# Current state of unit
# Export lets you toggle this in the inspector
@export var is_friendly: bool = false:
	set(value):
		is_friendly = value
		if is_node_ready():	# Must check if modulate should work
			_reload_behavior()	# Set/Toggles behavior

# Sets up AstarGrid for pathfinding, walkable tiles and sets friendly/enemy color/name
func _ready() -> void:	
	
	# Apply unit profile to current instance of actor
	_apply_profile()
	
	# Start idle-state animation
	_update_state_animation()
	
	# Initialize healthbar at start of level to max-health
	healthbar.init_health(stats.max_health)
	
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

	# Change name and healthbar based on friendly
	if healthbar:
		
		# Fetch the shared stylebox from the healthbar
		var shared_style = healthbar.get("theme_override_styles/fill")
		
		# Duplicate the shared stylebox (deep copy) so we don't mutate the shared resource
		var local_sb : StyleBoxFlat = shared_style.duplicate(true)
		
		# Set name and color
		if is_friendly:
			local_sb.bg_color = FRIENDLY_COLOR
			name = "playable_unit"
		else:
			local_sb.bg_color = ENEMY_COLOR
			name = "enemy_unit"
		
		# Apply override only to this healthbar instance
		healthbar.add_theme_stylebox_override("fill", local_sb)

# Apply unit profile to current instance of actor
func _apply_profile() -> void:
	if profile == null:
		return

	# Apply sprite of unit if there is one
	if sprite_2d and profile.sprite:
		sprite_2d.texture = profile.sprite

	# Connect profiles `animation` to anim_player here which is the object AnimationPlayer
	if anim_player and profile.animation:
		var lib_path := profile.animation.resource_path
		# Use the filename (without .tres) as library name
		anim_library_name = lib_path.get_file().get_basename() if lib_path != "" else "default"

		# Only add if not already present
		if not anim_player.has_animation_library(anim_library_name):
			anim_player.add_animation_library(anim_library_name, profile.animation)
			print("Added animation library:", anim_library_name)
		else:
			print("Library already exists:", anim_library_name)

# Updates current_state and calls update-animation
func set_state(new_state: UnitState) -> void:
	if new_state == current_state:
		return
	current_state = new_state
	_update_state_animation()

# Updates the animation of the unit based on its state
func _update_state_animation() -> void:
	
	# Test unit
	if anim_player == null or profile == null:
		return

	# Get the current state name and test it
	var anim_name = state_to_anim.get(current_state, null)
	if anim_name == null:
		return

	# Dynamically put together filepath of animation (e.g default/idle)
	var full_name = "%s/%s" % [anim_library_name, anim_name]
	if anim_player.has_animation(full_name):
		anim_player.play(full_name)
		# print("full_name:", full_name)	# TESTING
