extends Resource

# This script should be assigned to SkillResource.effect_script

func apply(caster: Actor, _target: Actor, skill: SkillResource) -> void:
	
	# This passive triggers only if the caster did NOT act this turn
	if not caster.passed_turn:
		return

	var stats := caster.get_stats_resource()
	if stats == null:
		return
	
	# --- 1. Apply temporary +30% buff to magic stats and +2 mobility for 1 turn
	# Local buff record to apply and register
	var buff_addition := {
		"curr_mobility": 2
	}  
	var buff_multiplier := {
		"curr_mag_attack": 1.3, 
		"curr_mag_defense": 1.4
	}
	
	# Apply immediately (like in skill_resource)
	for key in buff_multiplier.keys():
		if key in CharacterStats.MODIFIABLE_STATS:
			var curr = stats.get(key)
			stats.set(key, curr * buff_multiplier[key])
			
	for key in buff_addition.keys():
		if key in CharacterStats.MODIFIABLE_STATS:
			var curr = stats.get(key)
			stats.set(key, curr + buff_addition[key])
	
	# Register the buff so it gets reversed after duration
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
