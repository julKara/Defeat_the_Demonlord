extends Resource

# This script should be assigned to SkillResource.effect_script

func apply(caster: Actor, _target: Actor, skill: SkillResource) -> void:
	
	# This passive triggers only if the caster did NOT act this turn
	if not caster.passed_turn:
		return

	# --- 1️. Heal 30% of missing HP
	var stats := caster.get_stats_resource()
	if stats == null:
		return
	
	var heal_amount = int(stats.max_health * 0.3)
	stats.recieve_healing(heal_amount)
	caster.healthbar._set_health(caster.stats.curr_health)	# Update healthbar
	print("%s recovers %d HP due to %s!" % [caster.profile.character_name, heal_amount, skill.skill_name])
	
	# --- 2️. Apply temporary +20% defense buff for 2 turns
	# Local buff record to apply and register
	var buff_addition := {}  # no additive change
	var buff_multiplier := {
		"curr_phys_defense": 1.2, 
		"curr_mag_defense": 1.2
	}
	
	# Apply immediately (like in skill_resource)
	for key in buff_multiplier.keys():
		if key in CharacterStats.MODIFIABLE_STATS:
			var curr = stats.get(key)
			stats.set(key, curr * buff_multiplier[key])
	
	# Register the buffa so it gets reversed after duration
	var effect_record := {
		"skill": skill,
		"caster": caster,
		"remaining_duration": 2,
		"stat_addition": buff_addition,
		"stat_multiplier": buff_multiplier
	}
	
	# --- 3. Visual and AUDIO cue
	caster.set_state(caster.UnitState.USESKILL)
	
	caster.register_active_effect(effect_record)
