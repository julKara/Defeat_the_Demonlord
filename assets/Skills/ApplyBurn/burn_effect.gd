extends Resource

# A debuff that deals damage at the end of each turn lasting for the duration set in the SkillResource.


func apply(caster: Actor, target: Actor, skill: SkillResource) -> void:
	
	if target == null or caster == null:
		return

	# Save casters stats so if it dies it stays and doesn't get affected by caters new buffs
	var caster_stats = caster.get_stats_resource()
	var mag_atk_save := 0
	if caster_stats and "curr_mag_attack" in caster_stats:
		mag_atk_save = caster_stats.curr_mag_attack
	
	# Register this burn as an active effect on the target
	var effect_record := {
		"skill": skill,
		"caster": caster,  # Keep reference if still alive
		"caster_mag_attack_snapshot": mag_atk_save,
		"remaining_duration": skill.duration,
		"type": "burn"
	}
	target.register_active_effect(effect_record)
	
	# Optional: show visual feedback (burn animation or floating text)
	print("\t%s is now burning!" % target.profile.character_name)


# Called at end of each turn for active burn effects
func tick_effect(effect: Dictionary, target: Actor) -> void:
	
	if not effect or target == null:
		return

	var dmg := 0
	var caster_alive := effect.has("caster") and is_instance_valid(effect["caster"])

	if caster_alive:
		var caster: Actor = effect["caster"]
		var caster_stats = caster.get_stats_resource()
		if caster_stats and "curr_mag_attack" in caster_stats:
			dmg = round(caster_stats.curr_mag_attack * 0.15)
	else:
		# If caster is dead or freed
		if effect.has("caster_mag_attack_snapshot"):
			dmg = round(effect["caster_mag_attack_snapshot"] * 0.1)
			
	if dmg > 0:
		# Apply the damage to the target
		if target.stats.has_method("take_damage"):
			target.stats.take_damage(dmg)
			target.healthbar._set_health(target.get_stats_resource().curr_health)
			_play_damage_sfx(target)
			print("\n", target.profile.character_name, " took ", dmg, " in burn-damage")
	else:
		# Just print if no take_damage yet implemented
		print("Something wrong with burn_effect!")

func _play_damage_sfx(attacker: Actor) -> void:
	# Set the audio clip to the attack sfx
	attacker.audio_player["parameters/switch_to_clip"] = "Damage"
	# Play sound
	attacker.audio_player.play()
