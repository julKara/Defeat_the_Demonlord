# skill_resource.gd
class_name SkillResource extends Resource

@export var skill_name: String = "Unnamed Skill"
@export var description: String = "lorem you know the drill"
@export var icon: Texture2D
@export_enum("Passive", "Active") var skill_type: String = "Active"
@export var ends_turn: bool = true

# Who the skill can target
@export_enum("Self", "Ally", "Enemy", "Any") var target_type: String = "Self"

# Duration (for buffs/debuffs)
@export var duration: int = 0  # 0 = instant/permanent
@export var cooldown: int = 0  # 0 = instant/permanent

# --- Generic buff/debuff stats
# Written in how much you want reduced (-1 = stat goes down, 1 = stat goes upp)
@export var stat_addition := {
	"curr_attack_range": 0,
	"curr_mobility": 0
}
# Written in percentage you want (0.7 = 70% debuff, 1.3 = 30% buff)
@export var stat_multiplier := {
	"curr_phys_attack": 0.0,
	"curr_mag_attack": 0.0,
	"curr_phys_defense": 0.0,
	"curr_mag_defense": 0.0,
	"curr_mobility": 0.0
}

# Custom script to handle unique skill logic
@export var effect_script: Script

var current_cooldown: int = 0    # remaining cooldown turns (>=0). 0 means usable.

func apply_effect(caster: Actor, target: Actor) -> void:
	
	# --- 1. Use scripts if there is one
	# If a custom script is defined, use it
	if effect_script:
		var inst = effect_script.new()
		if inst.has_method("apply"):
			inst.apply(caster, target, self)
		
		# start cooldown
		current_cooldown = cooldown
		# If this skill has duration-handled behavior, add code to track it in target.active_effects
		return
	
	# --- 2. Get abd set stats
	
	# Otherwise, apply built-in stat modifications
	if target == null or target.stats == null:
		current_cooldown = cooldown
		push_warning("No target or stats to modify for skill: %s" % skill_name)
		return

	var stats = target.get_stats_resource()
	if stats == null:
		push_warning("Target has no stats resource for skill: %s" % skill_name)
		current_cooldown = cooldown
		return

	# Apply stat additions
	for key in stat_addition.keys():
		# validate modifiable stat and existence
		if key in CharacterStats.MODIFIABLE_STATS:
			var curr = stats.get(key)
			stats.set(key, curr + stat_addition[key])

	# Apply stat multipliers
	for key in stat_multiplier.keys():
		if key in CharacterStats.MODIFIABLE_STATS:
			var curr = stats.get(key)
			stats.set(key, round(curr * stat_multiplier[key]))

	# --- 3. Record durations and cooldowns
	
	# If this skill has a duration, record a reversible effect so we can remove it later
	if duration > 0:
		
		if not target.has_method("register_active_effect"):
			push_warning("Target missing register_active_effect method")
		else:
			var effect_record := {
				"skill": self,
				"caster": caster,
				"remaining_duration": duration,
				# Save stat changes so they can be reverted exactly
				"stat_addition": stat_addition.duplicate(true),
				"stat_multiplier": stat_multiplier.duplicate(true)
			}
			target.register_active_effect(effect_record)
			
	# start cooldown
	current_cooldown = cooldown

# Reverses what apply_effect did (only stat changes, not scripts)
func remove_effect(target: Node, effect_record: Dictionary) -> void:
	
	if target == null or not target.has_method("get_stats_resource"):
		return
	
	var stats = target.get_stats_resource()
	if stats == null:
		return

	# --- 1. Reverse additions by subtracting what was added
	if "stat_addition" in effect_record:
		for key in effect_record.stat_addition.keys():
			if key in CharacterStats.MODIFIABLE_STATS:
				var curr = stats.get(key)
				stats.set(key, curr - effect_record.stat_addition[key])

	# --- 2. Reverse multipliers by dividing by multiplier factor
	if "stat_multiplier" in effect_record:
		for key in effect_record.stat_multiplier.keys():
			if key in CharacterStats.MODIFIABLE_STATS:
				var factor = effect_record.stat_multiplier[key]
				var curr_value = stats.get(key)

				if factor == 0:
					# Handle gracefully by restoring from the base stat
					var base_key = key.replace("curr_", "")
					print("Thing: ", base_key)
					var base_value = stats.get(base_key)
					stats.set(key, base_value)
					continue

				# Normal revert by dividing with factor
				stats.set(key, round(curr_value / factor))
