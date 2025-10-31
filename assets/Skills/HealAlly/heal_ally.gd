extends Resource

# Called from SkillResource.apply_effect(caster, target)
func apply(caster: Actor, target: Actor, skill: SkillResource) -> void:
	
	if target == null or not target.has_method("get_stats_resource"):
		push_warning("Heal Ally: Invalid target")
		return

	var target_stats := target.get_stats_resource()
	if target_stats == null:
		push_warning("Heal Ally, can't find target stats")
		return
		
	var caster_stats := caster.get_stats_resource()
	if caster_stats == null:
		push_warning("Heal Ally, can't find target stats")
		return

	# --- 1️. Heal logic
	var heal_amount := caster_stats.curr_mag_defense * 0.8
	target_stats.recieve_healing(heal_amount)

	# --- 2. Update healthbar
	if target.has_node("Healthbar"):
		target.healthbar._set_health(target.stats.curr_health)

	print("%s heals %s for %d HP using %s!" % [caster.profile.character_name, target.profile.character_name, heal_amount, skill.skill_name])

	# --- 3. Visual and AUDIO cue
	caster.set_state(caster.UnitState.USESKILL)

	# Start cooldown
	skill.current_cooldown = skill.cooldown
