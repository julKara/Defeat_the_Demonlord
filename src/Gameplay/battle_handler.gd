class_name BattleHandler
extends Node

"""
# Handles all combat interactions between two Actor instances.
# Gets called by the default_attack button.
"""

# Other scripts/objects in each level scene
var animation_timer: Timer
var character_manager: Node2D
var turn_manager: Node2D
var win_loss_condition: Node2D
var pause_button: Button

func _ready() -> void:
	# Create our own AnimationTimer if not already present
	if not has_node("AnimationTimer"):
		animation_timer = Timer.new()
		animation_timer.one_shot = true
		add_child(animation_timer)
	else:
		animation_timer = $AnimationTimer

	get_tree().connect("node_added", Callable(self, "_on_node_added"))

func _on_node_added(node):
	if node.name.begins_with("Level_"):
		_find_level_nodes()

# --- Main function ---
func perform_battle(attacker: Actor, defender: Actor, distance: float) -> void:
	
	# Disable pause-button
	pause_button.disabled = true
	
	# Check if actors are valid
	if attacker == null or defender == null:
		push_warning("BattleHandler: Invalid attacker or defender.")
		return
	
	var atk_stats: CharacterStats = attacker.stats
	var def_stats: CharacterStats = defender.stats
	
	# For TESTING
	var atk_prof: UnitProfile = attacker.profile
	var def_prof: UnitProfile = defender.profile

	# 1. Play attack animation and sfx, and wait for it to finish
	var attacker_sprite = attacker.get_sprite()
	attacker_sprite.flip_h = attacker.global_position.x > defender.global_position.x
	_play_attack_sfx(attacker) # Play attack sfx
	await _play_animation(attacker) # Play attack animation
	
	var damage: float
	
	if attacker.is_demon_lord:
		damage = _calculate_demon_damage(atk_stats, def_stats)
	else:
		# 2. Calculate damage based on stats
		damage = _calculate_damage(atk_stats, def_stats)
		
		# 3. If a unit with longer range (2 or more), they do less damage close up
		#print("Range: ", atk_stats.attack_range)
		if atk_stats.attack_range >= 2 && distance <= 48.0:
			print("\t\t\tRange Penalty!")
			damage *= 0.6

	# 4. Apply Damage to Defender
	def_stats.take_damage(int(damage))
	
	# 5. Update Health Bar
	defender.healthbar._set_health(def_stats.curr_health)
	_play_damage_sfx(attacker)
	
	# 6. TESTING Debug Output
	print("\t\t%s attacked %s for %d damage!" % [
		atk_prof.character_name, def_prof.character_name, damage
	])
	
	# 7. Check for death
	if def_stats.curr_health <= 0:
		_handle_death(defender)
	
	# Disable pause-button
	pause_button.disabled = false

# --- UTIL ---

func _play_animation(attacker: Actor) -> void:
	
	# 1. Update state and play animation
	attacker.set_state(attacker.UnitState.ATTACKING)
	
	# 2. Get lenght of animation in seconds
	var anim_length: float = 1.0  # fallback default if test fails, usually an attack last 1s
	var anim_player = attacker.anim_player
		
	var anim_name = attacker.state_to_anim.get(attacker.current_state, null)
	if anim_name == null:
		return

	# Dynamically put together filepath of animation (e.g default/idle)
	var full_name = "%s/%s" % [attacker.anim_library_name, anim_name]
	if anim_player.has_animation(full_name):
		anim_length = anim_player.get_animation(full_name).length

	# 3. Start the timer to wait for animation completion
	animation_timer.wait_time = anim_length
	animation_timer.start()
	await animation_timer.timeout  # Wait until finished

	# 4. Return to idle state
	attacker.set_state(attacker.UnitState.IDLE)

func _play_attack_sfx(attacker: Actor) -> void:
	# Add a slight delay since it sounds better
	await get_tree().create_timer(0.1).timeout
	# Set the audio clip to the attack sfx
	attacker.audio_player["parameters/switch_to_clip"] = "Attack"
	# Play sound
	attacker.audio_player.play()
	
func _play_damage_sfx(attacker: Actor) -> void:
	# Set the audio clip to the attack sfx
	attacker.audio_player["parameters/switch_to_clip"] = "Damage"
	# Play sound
	attacker.audio_player.play()

# Calculates base damage between two CharacterStats
func _calculate_damage(atk: CharacterStats, def: CharacterStats) -> float:
	var damage: float = 0.0
	
	# Simple logic using magical or physical damage
	if atk.curr_phys_attack >= atk.curr_mag_attack:
		#print("Using Physical")
		damage = max(1, atk.curr_phys_attack - def.curr_phys_defense)
	else:
		#print("Using magic")
		damage = max(1, atk.curr_mag_attack - def.curr_mag_defense)
	
	# Doubles damage if preforming a crit
	if randf() < float(atk.curr_crit_chance) / 100.0:
		damage *= 1.4
		print("\t\t\tCritical hit!")
	
	return damage
	
func _calculate_demon_damage(atk: CharacterStats, def: CharacterStats) -> float:
	var damage: float = 0.0
	
	damage = max(1, atk.curr_phys_attack - def.curr_phys_defense) + max(1, atk.curr_mag_attack - def.curr_mag_defense)
	
	# Doubles damage if preforming a crit
	if randf() < float(atk.curr_crit_chance) / 100.0:
		damage *= 1.4
		print("\t\t\tCritical hit!")
	
	return damage

# Handles what happens when a unit dies.
func _handle_death(dead_actor: Actor) -> void:
	print("\t\t%s is dead!" % dead_actor.profile.character_name)	# TESTING
	
	# Death behavoiur
	dead_actor.set_state(dead_actor.UnitState.DEAD)	# Dead state - updates animation
	
	# Remove actor from lists
	character_manager.character_list.erase(dead_actor)	# Remove character from list in manager
	turn_manager.player_queue.erase(dead_actor)
	turn_manager.enemy_queue.erase(dead_actor)
	
	dead_actor.queue_free()	# Remove actor from world
	character_manager.num_characters -= 1
	
	# Check if a win/loss condition has been met
	win_loss_condition.check_conditions()

# --- UTIL ---
func _find_level_nodes() -> void:
	
	# Reset from prev level
	character_manager = null
	turn_manager = null
	win_loss_condition = null
	
	# Find active level root (first child under root that isn’t an autoload)
	for node in get_tree().root.get_children():
		if node.name.begins_with("Level_"):  # adjust to your naming
			var tilemap_layer = node.get_node_or_null("TileMapLayer")
			if tilemap_layer:
				character_manager = tilemap_layer.get_node_or_null("CharacterManager")
				turn_manager = tilemap_layer.get_node_or_null("TurnManager")
				win_loss_condition = node.get_node_or_null("WinLossCondition")
			var gui = node.get_node_or_null("GUI")
			if gui:
				var margin = gui.get_node_or_null("Margin")
				if margin:
					pause_button = margin.get_node_or_null("PauseButton")
					return
	push_warning("BattleHandlerGlobal: Could not find CharacterManager or TurnManager in current level!")
