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

func _ready() -> void:
	# Create our own AnimationTimer if not already present
	if not has_node("AnimationTimer"):
		animation_timer = Timer.new()
		animation_timer.one_shot = true
		add_child(animation_timer)
	else:
		animation_timer = $AnimationTimer

	# Try to locate level-specific managers each time a level loads
	_find_level_nodes()

func perform_battle(attacker: Actor, defender: Actor, distance: float) -> void:
	
	# Check if actors are valid
	if attacker == null or defender == null:
		push_warning("BattleHandler: Invalid attacker or defender.")
		return
	
	var atk_stats: CharacterStats = attacker.stats
	var def_stats: CharacterStats = defender.stats
	
	# For TESTING
	var atk_prof: UnitProfile = attacker.profile
	var def_prof: UnitProfile = defender.profile

	# 1. Play attack animation and wait for it to finish
	await _play_animation(attacker)
	
	# 2. Calculate damage based on stats
	var damage: float = _calculate_damage(atk_stats, def_stats)
	
	# 3. If a unit with longer range (2 or more), they do less damage close up
	#print("Range: ", atk_stats.attack_range)
	if atk_stats.attack_range >= 2 && distance <= 48.0:
		print("\t\t\tRange Penalty!")
		damage *= 0.6

	# 4. Apply Damage to Defender
	def_stats.take_damage(int(damage))
	
	# 5. Update Health Bar
	defender.healthbar._set_health(def_stats.curr_health)
	
	# 6. TESTING Debug Output
	print("\t\t%s attacked %s for %d damage!" % [
		atk_prof.character_name, def_prof.character_name, damage
	])
	
	# 7. Check for death
	if def_stats.curr_health <= 0:
		_handle_death(defender)
	

func _play_animation(attacker: Actor) -> void:
	
	# 1. Update state and play animation
	attacker.set_state(attacker.UnitState.ATTACKING)
	
	# 2. Get lenght of animation in seconds
	var anim_length: float = 1.0  # fallback default if test fails, usually an attack last 1s
	var anim_player = attacker.anim_player
	if anim_player and anim_player.has_animation("attack"):
		anim_length = anim_player.get_animation("attack").length

	# 3. Start the timer to wait for animation completion
	animation_timer.wait_time = anim_length
	animation_timer.start()
	await animation_timer.timeout  # Wait until finished

	# 4. Return to idle state
	attacker.set_state(attacker.UnitState.IDLE)

# Calculates base damage between two CharacterStats
func _calculate_damage(atk: CharacterStats, def: CharacterStats) -> float:
	var damage: float = 0.0
	
	# Simple logic using magical or physical damage
	if atk.phys_attack >= atk.mag_attack:
		#print("Using Physical")
		damage = max(1, atk.phys_attack - def.phys_defense)
	else:
		#print("Using magic")
		damage = max(1, atk.mag_attack - def.mag_defense)
	
	# Doubles damage if preforming a crit
	if randf() < float(atk.crit_chance) / 100.0:
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
	# Find active level root (first child under root that isn’t an autoload)
	for node in get_tree().root.get_children():
		if node.name.begins_with("Level_"):  # adjust to your naming
			var tilemap_layer = node.get_node_or_null("TileMapLayer")
			if tilemap_layer:
				character_manager = tilemap_layer.get_node_or_null("CharacterManager")
				turn_manager = tilemap_layer.get_node_or_null("TurnManager")
				win_loss_condition = node.get_node_or_null("WinLossCondition")
				return
	push_warning("BattleHandlerGlobal: Could not find CharacterManager or TurnManager in current level!")
