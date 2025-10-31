extends Node2D

"""
# The following script will handle turn. This includes:
	* Keep track of turn number, phase and which units can act.
	* Signal other scripts/objects when a new phase begins or when a turn ends.
	* Handle transitions between units, phases and full turns.
"""

enum Phase { PLAYER, ENEMY }	# The two possible phases

# --- Imports ---
@onready var character_manager: Node2D = $"../CharacterManager"
@onready var win_loss_condition: Node2D = $"../../WinLossCondition"
@onready var tile_map: TileMap = $"../../TileMap"
@onready var camera_controller: Node = $"../../CameraController"
@onready var turn_transition: Control = $"../../TurnTransitionCanvas/TurnTransition"

# --- Variables ---
@export var max_turns: int = 10
var game_is_paused: bool = false

var current_turn: int = 1
var current_phase: Phase = Phase.PLAYER	# Player always start
var player_queue: Array = []
var enemy_queue: Array = []


func _ready() -> void:
	await get_tree().create_timer(0.01).timeout	
	# Center camera on unit
	camera_controller.focus_on_unit(character_manager.current_character)
	_initialize_turn_order()
	start_phase(Phase.PLAYER)

# --- INITIAL SETUP ---
func _initialize_turn_order() -> void:
	
	# Clear in case of rest from prev level
	player_queue.clear()
	enemy_queue.clear()
	
	# Sort units into player/enemy queue
	for actor in character_manager.character_list:
		if actor.is_friendly:
			player_queue.append(actor)
		else:
			enemy_queue.append(actor)


# --- PHASE CONTROL ---

# Cleans up prev turn and sets up the current one (player starts when level starts)
func start_phase(phase: Phase) -> void:
	
	# Stop phase if game is paused
	if game_is_paused:
		return
		
	# Reset all actor grids to the clean base version before the enemy phase
	for actor in character_manager.character_list:
		if actor.has_method("reset_astar_grid"):
			actor.reset_astar_grid()

	# Delay between phases, TODO: Add transitions
	#await get_tree().create_timer(1.0).timeout
	
	current_phase = phase
	match phase:
		Phase.PLAYER:
			
			# Show the Turn number first
			await turn_transition.play_transition("Turn %d / %d" % [current_turn, max_turns], Color(0.382, 0.296, 0.8), 0.863)
			# Then show Player Turn banner
			await turn_transition.play_transition("Player Turn", Color(0, 0.536, 0.737), 1.0)
			
			print("\n--- Turn %d start!\n" % current_turn)
			print("--- Player Phase ---")
			ClickHandler.level_active = true
			_reset_acted_flag(player_queue)	# Clear the bool acted
			_next_player_unit()	# Select next playable unit in queue
		Phase.ENEMY:
			
			# Show Enemy Turn banner in darker color
			await turn_transition.play_transition("Enemy Turn", Color(0.764, 0.133, 0.143), 1.2)
			
			print("--- Enemy Phase ---")
			_reset_acted_flag(enemy_queue)	# Clear the bool acted
			_next_enemy_unit()	# Select next playable unit in queue

# Sets and start either player or enemy depending on the prev
func end_phase() -> void:
	if current_phase == Phase.PLAYER:
		ClickHandler.level_active = false
		start_phase(Phase.ENEMY)
	else:
		end_turn()


# --- TURN CONTROL ---

# Ends turn when both player and AI has acted
func end_turn() -> void:
	
	# Increase current turn
	current_turn += 1

	# Update all actors effects and cooldowns
	for actor in character_manager.character_list:
		if actor:
			if actor.has_method("tick_effects"):
				actor.tick_effects()
			if actor.has_method("tick_cooldowns"):
				actor.tick_cooldowns()

	# Check if level is over, otherwise move on to next player-phase
	if current_turn > max_turns:
		_trigger_defeat()
	else:
		start_phase(Phase.PLAYER)


# Triggers defeat TAG: MIRIJAM LOSE-CONDITION
func _trigger_defeat() -> void:
	print("\nDefeat! Max turns reached!")
	game_is_paused = true
	win_loss_condition.lose()


# --- PLAYER TURN HANDLING ---
func _next_player_unit() -> void:
	
	# Stop phase if game is paused
	if game_is_paused:
		return
	
	# Get next playable unit is queue
	var next_unit: Actor = null
	for unit in player_queue:
		if not unit.acted:
			next_unit = unit
			break
			
	# If queue is empty, end phase, otherwise set current_character
	if next_unit == null:
		print("Player phase complete.\n")
		
		# End current phase and start ENEMY Phase
		end_phase()
	else:
		
		# Select next playable unit (print-statement in function)
		var next_behaviour_node: Node = next_unit.get_behaviour()
		next_behaviour_node.select(false)

func end_player_unit_turn(unit: Actor) -> void:
	
	unit.acted = true
	print("\t", unit.profile.character_name, " has ended their turn.")
	
	# Deselect current character
	var next_behaviour_node: Node = unit.get_behaviour()
	next_behaviour_node.deselect()
	
	if next_behaviour_node and next_behaviour_node.has_method("confirm_position"):
			next_behaviour_node.confirm_position()
	
	# Check for passives triggered at end of turn
	_trigger_end_turn_passives(unit)
	
	next_behaviour_node.deselect()
	
	# Select next unit
	_next_player_unit()


# --- ENEMY TURN HANDLING ---
func _next_enemy_unit() -> void:
	
	# Get next enemy unit is queue
	var next_unit: Actor = null
	for unit in enemy_queue:
		if not unit.acted:
			next_unit = unit
			break
			
	
	# If queue is empty, end phase
	if next_unit == null:
		print("Enemy phase complete.\n")
		end_phase()
	else:
		print("\tEnemy unit turn: ", next_unit.profile.character_name)
		
		# Center camera on unit
		camera_controller.focus_on_unit(next_unit)

		
		# Get behaviour to play_turn
		var next_behaviour_node: Node = next_unit.get_behaviour()
		if next_behaviour_node.has_method("play_turn"):
			await next_behaviour_node.play_turn()  # Wait for AI to truly finish
			await get_tree().create_timer(0.6).timeout  # Delay between enemy units
		
		if next_behaviour_node and next_behaviour_node.has_method("confirm_position"):
			next_behaviour_node.confirm_position()
		
		# Test if unit survivied the attack
		if next_unit != null:
			next_unit.acted = true
			_trigger_end_turn_passives(next_unit)
			
		# Stop phase if game is paused
		if game_is_paused:
			return
			
		# Auto-advance in queue, might add a delay
		_next_enemy_unit()

# --- UTIL ---

# Triggers passive skills and effects that gets triggered at the end of a units turn
func _trigger_end_turn_passives(actor: Actor) -> void:
	if not actor:
		return
	
	# --- 1. Passive skills (Buff Defence)
	if "skills" in actor:
		for skill in actor.skills:
			if skill.skill_type == "Passive" and skill.effect_script:
				var script_inst = skill.effect_script.new()
				if script_inst.has_method("apply"):
					script_inst.apply(actor, actor, skill)

	# --- 2. Active ticking effects (Burn)
	if "active_effects" in actor:
		for effect in actor.active_effects:
			if effect.has("skill") and effect.skill and effect.skill.effect_script:
				var script_inst = effect.skill.effect_script.new()
				if script_inst.has_method("tick_effect"):
					script_inst.tick_effect(effect, actor)
					
	if actor.stats.curr_health <= 0:
		_handle_death(actor)


# Handles what happens when a unit dies.
func _handle_death(dead_actor: Actor) -> void:
	print("\t\t%s is dead!" % dead_actor.profile.character_name)	# TESTING
	
	# Death behavoiur
	dead_actor.set_state(dead_actor.UnitState.DEAD)	# Dead state - updates animation
	
	# Remove actor from lists
	character_manager.character_list.erase(dead_actor)	# Remove character from list in manager
	player_queue.erase(dead_actor)
	enemy_queue.erase(dead_actor)
	
	dead_actor.queue_free()	# Remove actor from world
	character_manager.num_characters -= 1
	
	# Check if a win/loss condition has been met
	win_loss_condition.check_conditions()

func _reset_acted_flag(list: Array) -> void:
	for unit in list:
		unit.acted = false
