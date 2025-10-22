extends Node2D

"""
# The following script will handle turn. This includes:
	* Keep track of turn number, phase and which units can act.
	* Signal other scripts/objects when a new phase begins or when a turn ends.
	* Handle transitions between units, phases and full turns.
"""

enum Phase { PLAYER, ENEMY }	# The two possible phases

# --- Imports ---
@onready var actors: Node2D = $"../Actors"
@onready var character_manager: Node2D = $"../CharacterManager"
# For "deselecting"
@onready var tile_map: TileMap = $"../../TileMap"
@onready var draw_path: Node2D = $"../../DrawPath"
@onready var actor_info: PanelContainer = $"../../GUI/Margin/ActorInfo"
@onready var actions_menu: PanelContainer = $"../../GUI/Margin/ActionsMenu"


# --- Variables ---
@export var max_turns: int = 10
var current_turn: int = 1
var current_phase: Phase = Phase.PLAYER	# Player always start
var player_queue: Array = []
var enemy_queue: Array = []

func _ready() -> void:
	await get_tree().create_timer(0.01).timeout
	_initialize_turn_order()
	start_phase(Phase.PLAYER)

# --- INITIAL SETUP ---
func _initialize_turn_order() -> void:
	
	# Clear in case of rest from prev level
	player_queue.clear()
	enemy_queue.clear()
	
	# Sort units into player/enemy queue
	for actor in actors.get_children():
		if actor.is_friendly:
			player_queue.append(actor)
		else:
			enemy_queue.append(actor)


# --- PHASE CONTROL ---

# Cleans up prev turn and sets up the current one (player starts when level starts)
func start_phase(phase: Phase) -> void:
	current_phase = phase

	match phase:
		Phase.PLAYER:
			print("--- Player Phase ---")
			_reset_acted_flag(player_queue)	# Clear the bool acted
			_next_player_unit()	# Select next playable unit in queue
		Phase.ENEMY:
			print("--- Enemy Phase ---")
			_reset_acted_flag(enemy_queue)	# Clear the bool acted
			_next_enemy_unit()	# Select next playable unit in queue

# Sets and start either player or enemy depending on the prev
func end_phase() -> void:
	if current_phase == Phase.PLAYER:
		start_phase(Phase.ENEMY)
	else:
		end_turn()


# --- TURN CONTROL ---

# Ends turn when both player and AI has acted
func end_turn() -> void:
	
	# Increase current turn
	print("--- Turn %d ended." % current_turn)
	current_turn += 1
	print("\n--- Turn %d start!\n" % current_turn)
	
	# Check if level is over, otherwise move on to next player-phase
	if current_turn > max_turns:
		_trigger_defeat()
	else:
		start_phase(Phase.PLAYER)

# Triggers defeat TAG: MIRIJAM LOSE-CONDITION
func _trigger_defeat() -> void:
	print("\nDefeat! Max turns reached!")
	# TODO: call game over logic here.


# --- PLAYER TURN HANDLING ---
func _next_player_unit() -> void:
	
	# Get next playable unit is queue
	var next_unit: Actor = null
	for unit in player_queue:
		if not unit.acted:
			next_unit = unit
			break
			
	# If queue is empty, end phase, otherwise set current_character
	if next_unit == null:
		print("\nPlayer phase complete.")
		end_phase()
	else:
		character_manager.set_current_character(next_unit)
		print("\tPlayer unit turn: ", next_unit.profile.character_name)
		_pass_button()

func end_player_unit_turn(unit: Actor) -> void:
	unit.acted = true
	print("\t", unit.profile.character_name, " has ended their turn.")
	_next_player_unit()
	
	# Hide GUI and drawpath


# --- ENEMY TURN HANDLING ---
func _next_enemy_unit() -> void:
	
	# Get next enemy unit is queue
	var next_unit: Actor = null
	for unit in enemy_queue:
		if not unit.acted:
			next_unit = unit
			break
	
	# If queue is empty, end phase, otherwise set current_character
	if next_unit == null:
		print("\nEnemy phase complete.")
		end_phase()
	else:
		print("\tEnemy unit turn: ", next_unit.profile.character_name)
		
		# Get behaviour to play_turn
		var behaviour = next_unit.get_child(0)
		if behaviour.has_method("play_turn"):
			await behaviour.play_turn()  # if play_turn() is async
			await get_tree().create_timer(0.8).timeout  # delay between enemy actions
		
		next_unit.acted = true
		_next_enemy_unit()  # Auto-advance in queue, might add a delay

# --- UTIL ---
func _reset_acted_flag(list: Array) -> void:
	for unit in list:
		unit.acted = false

func _pass_button() -> void:
	# Find the behaviour node of the current character
	var all_children = character_manager.current_character.get_children()
	var behaviour_node
		
	for child in all_children:
		if child is Node:
			behaviour_node = child
	
	# Update the startposision of the current playable character to be where it ended its move
	if character_manager.current_character.is_friendly == true:
		behaviour_node.start_position = tile_map.local_to_map(character_manager.current_character.global_position)
	
	# Hide mobility and attack range
	tile_map.clear_layer(1)
	tile_map.clear_layer(2)
	
	# Deselect character
	behaviour_node.selected = false
	
	# Remove highlight from attack target
	if behaviour_node.attack_target != null:
		all_children = behaviour_node.attack_target.get_children()
		var sprite
		for child in all_children:
			if child is Sprite2D:
				sprite = child
		sprite.material.set("shader_parameter/width", 0.0)
	
	# Remove selected attack target
	behaviour_node.attack_target = null
	
	# Hidde movement path, actions-menu and actor info
	draw_path.hide()
	actions_menu.hide()
	actor_info.hide_actor_info()
	
	# Update behaviour node to the new character
	all_children = character_manager.current_character.get_children()
	for child in all_children:
		if child is Node:
			behaviour_node = child
	
	if character_manager.current_character.is_friendly == true:	
		# Highlight and select the updated current character
		behaviour_node.highlight_range()
