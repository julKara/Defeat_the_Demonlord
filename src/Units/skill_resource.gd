# skill_resource.gd
class_name SkillResource extends Resource

@export var skill_name: String = "Unnamed Skill"
@export var description: String = "lorem you know the drill"
@export var icon: Texture2D
@export_enum("Passive", "Active") var skill_type: String = "Active"
@export var need_enemy_target: bool = false

# Who the skill can target
@export_enum("Self", "Ally", "Enemy", "Any") var target_type: String = "Self"

# Duration (for buffs/debuffs)
@export var duration: int = 0  # 0 = instant/permanent

# --- Generic buff/debuff stats
# Written in how much you want reduced (-1 = stat goes down, 1 = stat goes upp)
@export var stat_addition := {
	"attack_range": 0,
	"mobility": 0
}
# Written in percentage you want (0.7 = 70% debuff, 1.3 = 30% buff)
@export var stat_multiplier := {
	"phys_attack": 0.0,
	"mag_attack": 0.0,
	"phys_defense": 0.0,
	"mag_defense": 0.0
}

# Custom script to handle unique skill logic
@export var effect_script: Script

func apply_effect(caster: Actor, target: Actor) -> void:
	# If a custom script is defined, use it
	if effect_script:
		var inst = effect_script.new()
		if inst.has_method("apply"):
			inst.apply(caster, target, self)
		return
	
	# Otherwise, apply built-in stat modifications
	if target == null or target.stats == null:
		push_warning("No valid target or stats to modify for skill: %s" % skill_name)
		return

	for key in stat_addition.keys():
		if key in CharacterStats.MODIFIABLE_STATS:
			var current_value = target.stats.get(key)
			target.stats.set(key, current_value + stat_addition[key])

	for key in stat_multiplier.keys():
		if key in CharacterStats.MODIFIABLE_STATS:
			var current_value = target.stats.get(key)
			target.stats.set(key, current_value * stat_multiplier[key])
