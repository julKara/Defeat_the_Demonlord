@tool	# Remove near end (heavy on performance)

class_name Actor extends CharacterBody2D
"""
# This class manages everything concerning the units in the level (both playable and enemies). 
# It stores important information such as state and is_friendly but also setters and initialzers
# for most info.
"""


# --- Unit-Unique Reasources ---
@export var stats: CharacterStats	# All stats to particular unit
@export var profile: UnitProfile	# All other unique aspects of a unit (name, skills, talent...)
var anim_library_name := "default"	# Liberary name for unit-animations, is the .tres file attached to profile
@export var enemy_level: int

# --- CONSTANTS ---
const FRIENDLY_COLOR: Color = Color("00a78f")
const ENEMY_COLOR: Color = Color.CRIMSON
enum UnitState { IDLE, SELECTED, MOVING, ATTACKING, USESKILL, DEAD }	# Possible unit-states
var state_to_anim = {	# For animation filepaths
		UnitState.IDLE: "idle",
		UnitState.SELECTED: "selected",
		UnitState.MOVING: "move",
		UnitState.ATTACKING: "attack",
		UnitState.USESKILL: "useSkill",
		UnitState.DEAD: "dead"
	}

# --- Refrences to objects in actor ---
var behavior: Node = null	# Decides behavior based on if unit is playable, enemy, npc...
@onready var sprite_2d: Sprite2D = $Sprite	# Just the default sprite to all characters
@onready var anim_player: AnimationPlayer = $AnimationPlayer	# Used to play animations
@onready var healthbar: ProgressBar = $Healthbar	# The units healthbar, gets set up in _ready()
@onready var audio_player: AudioStreamPlayer = $AudioPlayer

# Skills
var skills: Array[SkillResource] = []	# Stores the actual skills
var active_effects: Array = []	# Stores active effects on the unit (skill, caster, remaining_duration, stat_addition, stat_multiplier)
var passed_turn: bool = false	# Set to true when pressing pass-turn button to trigger certain passives

# --- Refrences to objects in level ---
@onready var tile_map: TileMap = $"../../../TileMap"

# --- Variables for movement ---
var astar_grid: AStarGrid2D
var base_solid_points: Array[Vector2i] = []	# Contains all solid points from when the level was made
var tile_size: int = 48

# --- Unit info while in gameplay: ---
var selected: bool = false	# True if unit is selected
var acted: bool = false    # True if the unit has acted this turn
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
	
	# Duplicate stats so this actor has its own instance
	if stats:
		stats = stats.duplicate(true)
	
	init_stats()
	stats.init_stats()
	
	# Initialize healthbar at start of level to max-health
	healthbar.init_health(stats.max_health)
	
	# Start idle-state animation
	_update_state_animation()
	
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
				base_solid_points.append(tile_position)	# Add "red" tiles
	
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
		#else:
			#print("Library already exists:", anim_library_name)
	
	# Connect the audio from the profile to the characters audio player		
	if audio_player and profile.audio:
		audio_player.stream = profile.audio
		
	# Load skills
	if profile.skills.size() > 0:
		skills = []
		for skill in profile.skills:
			if skill:
				var inst = skill.duplicate(true)
				skills.append(inst)
		print("Loaded skills:", skills.map(func(s): return s.skill_name))

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
		

# Initiate stats
func init_stats():
	# Scale stats based on level for enemy units
	if is_friendly == false:
		stats.max_health = stats.original_max_health + stats.health_gain * (enemy_level-1)
		stats.phys_attack = stats.original_phys_attack + stats.phys_atk_gain * (enemy_level-1)
		stats.mag_attack = stats.original_mag_attack + stats.mag_atk_gain * (enemy_level-1)
		stats.phys_defense = stats.original_phys_defense + stats.phys_def_gain * (enemy_level-1)
		stats.mag_defense = stats.original_mag_defense + stats.mag_def_gain * (enemy_level-1)
		stats.crit_chance = stats.original_crit_chance + stats.crit_gain * (enemy_level-1)


# Resets astar back to before adding enemies
func reset_astar_grid() -> void:
	
	for x in astar_grid.get_size().x:
		for y in astar_grid.get_size().y:
			var pos = Vector2i(x, y)
			astar_grid.set_point_solid(pos, false)
			
	for p in base_solid_points:
		astar_grid.set_point_solid(p, true)

# --- Skill Handling ---

# Use a skill
func use_skill(skill: SkillResource, target: Actor) -> bool:
	
	if skill == null:
		return false
	
	# Check cooldown
	if skill.current_cooldown > 0:
		print("Skill %s is on cooldown (%d turns left)." % [skill.skill_name, skill.current_cooldown])
		return false

	# Check target validit
	match skill.target_type:
		"Self":
			target = self
		"Ally":
			# Allow only friendly targets
			if not target or target.is_friendly != self.is_friendly:
				print("Invalid ally target.")
				return false
		"Enemy":
			if not target or target.is_friendly == self.is_friendly:
				print("Invalid enemy target.")
				return false
		"Any":
			pass

	# Use the skill
	skill.apply_effect(self, target)

	# Tells that the skill was succesfully used (which ends units turn)
	return true

# Called by skill_resource.gd to record an effect with duration
func register_active_effect(effect_record: Dictionary) -> void:
	
	# Append the effect applied by skill_resource.apply_effect
	active_effects.append(effect_record)

# Called each turn to decrement durations and/or remove effects
func tick_effects() -> void:
	
	# Go backwards and remove expired effects
	for i in range(active_effects.size() - 1, -1, -1):
		
		# Tick down duration
		var effect = active_effects[i]
		effect.remaining_duration -= 1
		
		# Remove effect if expired
		if effect.remaining_duration <= 0:
			
			if effect.skill and effect.skill.has_method("remove_effect"):
				effect.skill.remove_effect(self, effect)	# Remove effect on skills
			active_effects.remove_at(i)	# Remove from list

# Called each turn to decrement cooldowns of skills
func tick_cooldowns() -> void:

	if not ("skills" in self):
		return
		
	for s in skills:
		if s and s.current_cooldown > 0:
			s.current_cooldown -= 1	# Decrement cooldown
			
			# Just in canse
			if s.current_cooldown < 0:
				s.current_cooldown = 0

# --- Get functions ---
func get_stats_resource() -> CharacterStats:
	return stats

func get_sprite() -> Sprite2D:
	return sprite_2d

func get_behaviour() -> Node:
	return behavior
