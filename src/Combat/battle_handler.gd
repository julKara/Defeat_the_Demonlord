class_name BattleHandler
extends Node

"""
# Handles all combat interactions between two Actor instances.
"""

# Refrences
@onready var character_manager: Node2D = $"../TileMapLayer/CharacterManager"

# Can be preloaded globally or add it as a child of World scene
# Like: `var battle_handler = BattleHandler.new()` or keep it as an autoload singleton.
# Probably connect it to default_attack button

func perform_battle(attacker: Actor, defender: Actor) -> void:
	
	# Check if actors are valid
	if attacker == null or defender == null:
		print("BattleHandler: Invalid attacker or defender.")
		return
	
	var atk_stats: CharacterStats = attacker.stats
	var def_stats: CharacterStats = defender.stats
	
	# For TESTING
	var atk_prof: UnitProfile = attacker.profile
	var def_prof: UnitProfile = defender.profile

	# 1. Update attacker state
	#attacker.set_state(attacker.UnitState.ATTACKING)
	
	# 2. Calculate Damage
	var damage: int = _calculate_damage(atk_stats, def_stats)

	# 3. Apply Damage to Defender
	var hit := {
		"damage": damage
	}
	def_stats.take_damage(hit)
	
	# 4. Update Health Bar
	defender.healthbar._set_health(def_stats.curr_health)
	attacker.healthbar._set_health(atk_stats.curr_health)
	
	# 5. Check for death
	if def_stats.curr_health <= 0:
		_handle_death(defender)
	elif atk_stats.curr_health <= 0:
		_handle_death(attacker)

	# 6. TESTING 5 Debug Output
	print("%s attacked %s for %d damage!" % [
		atk_prof.character_name, def_prof.character_name, damage
	])

# Calculates base damage between two CharacterStats
func _calculate_damage(atk: CharacterStats, def: CharacterStats) -> int:
	var damage: int = 0
	
	# Simple logic using magical or physical damage
	if atk.phys_attack > atk.mag_attack:
		damage = max(1, atk.phys_attack - def.phys_defense)
	else:
		damage = max(1, atk.mag_attack - def.mag_defense)
	
	# Doubles damage if preforming a crit
	if randf() < float(atk.crit_chance) / 100.0:
		damage *= 2
		print("Critical hit!")
	
	return damage

# Handles what happens when a unit dies.
func _handle_death(dead_actor: Actor) -> void:
	print("%s is dead!" % dead_actor.profile.character_name)	# TESTING
	
	# Death behavoiur
	dead_actor.set_state(dead_actor.UnitState.DEAD)	# Dead state - updates animation
	character_manager.character_list.erase(dead_actor)	# Remove character from list in manager
	dead_actor.queue_free()	# Remove actor from world
