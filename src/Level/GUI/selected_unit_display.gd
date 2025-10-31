extends Control
class_name SelectDisplay

# Node-refs
@onready var portrait: TextureRect = $Panel/MainHBox/LeftCol/Portrait
@onready var name_label: Label = $Panel/MainHBox/LeftCol/VBoxContainer/NameLabel
@onready var class_label: Label = $Panel/MainHBox/LeftCol/VBoxContainer/ClassLabel
@onready var lv_label: Label = $Panel/MainHBox/LeftCol/VBoxContainer/Lv

@onready var hp_bar: ProgressBar = $Panel/MainHBox/CenterCol/HPBar
@onready var h_ptext: Label = $Panel/MainHBox/CenterCol/HPBar/HPtext
@onready var atk_range_label: Label = $Panel/MainHBox/CenterCol/RangeRow/AttackRangeLabel
@onready var move_range_label: Label = $Panel/MainHBox/CenterCol/RangeRow/MoveRangeLabel

@onready var stat_patk: Label = $Panel/MainHBox/CenterCol/StatsGrid/PAtkLabel
@onready var stat_matk: Label = $Panel/MainHBox/CenterCol/StatsGrid/MAtkLabel
@onready var stat_pdef: Label = $Panel/MainHBox/CenterCol/StatsGrid/PDefLabel
@onready var stat_mdef: Label = $Panel/MainHBox/CenterCol/StatsGrid/MDefLabel
@onready var stat_crit: Label = $Panel/MainHBox/CenterCol/StatsGrid/CritLabel

# Colour-consts
const COLOR_NORMAL = Color(1,1,1)
const COLOR_BUFF = Color(0.0,0.8,0.0)
const COLOR_DEBUFF = Color(0.9,0.2,0.2)
const COOLDOWN_TINT = Color(0.4,0.4,0.4,0.7)

# Keep current actor here too for convenience
var current_actor: Node = null

func _ready() -> void:
	
	# Should only be visable when selecting a charcter
	visible = false
	_clear_display()

# Call upon selection 
func show_for_actor(actor: Node) -> void:
		
	visible = true
	
	if actor == null:
		_clear_display()
		return

	current_actor = actor

	# --- Get resources
	var profile = null
	if "profile" in actor:
		profile = actor.profile
	elif actor.has_method("get_profile"):
		profile = actor.get_profile()

	var stats = null
	if actor.has_method("get_stats_resource"):
		stats = actor.get_stats_resource()
	elif "stats" in actor:
		stats = actor.stats

	# Fill basic profile info
	if profile:
		
		# 1. Level
		var lvl = 1	# Default
		if actor.is_friendly and stats and ("level" in stats):
			lvl = stats.level
		else:
			lvl = actor.enemy_level
		
		# 2. Name and Class
		name_label.text = "%s" % profile.character_name
		class_label.text = str(profile.battle_class_type)
		lv_label.text = "Lvl: %d" % lvl
		
		# 3. Portrait
		#if profile.sprite:
			#portrait.texture = profile.sprite
		#else:
			#portrait.texture = null
			
	else:
		
		# Default
		name_label.text = "John"
		class_label.text = "Class"

	
	# Fill HP, ranges and stats in order
	if stats:
		_update_hp(stats)
		_update_ranges(stats)
		_update_main_stats(stats)
	else:
		hp_bar.value = 0
		atk_range_label.text = ""
		move_range_label.text = ""
		_clear_stats_labels()


# Update HP bar
func _update_hp(stats) -> void:
	
	var curr_he : int = stats.curr_health if "curr_health" in stats else 0
	var max_he :int = stats.max_health if "max_health" in stats else 1

	var percent := 0.0
	if max_he > 0:
		percent = float(curr_he) / float(max_he) * 100.0

	# Make sure the ProgressBar's range matches percent (0..100)
	hp_bar.min_value = 0
	hp_bar.max_value = 100
	hp_bar.value = clamp(percent, 0.0, 100.0)

	# Update overlay label
	h_ptext.text = "%d / %d" % [curr_he, max_he]


# Update ranges row
func _update_ranges(stats) -> void:
	
	var base_atk = stats.attack_range if "attack_range" in stats else 0
	var base_move = stats.mobility if "mobility" in stats else 0
	
	var curr_atk = stats.curr_attack_range if "curr_attack_range" in stats else 0
	var curr_move = stats.curr_mobility if "curr_mobility" in stats else 0
	
	atk_range_label.text = "Range: %d" % curr_atk
	move_range_label.text = "Move: %d" % curr_move
	
	var col_a = COLOR_NORMAL
	if curr_atk > base_atk:
		col_a = COLOR_BUFF
	elif curr_atk < base_atk:
		col_a = COLOR_DEBUFF
	atk_range_label.add_theme_color_override("font_color", col_a)
	
	var col_m = COLOR_NORMAL
	if curr_move > base_move:
		col_m = COLOR_BUFF
	elif curr_move < base_move:
		col_m = COLOR_DEBUFF
	move_range_label.add_theme_color_override("font_color", col_m)

# Update main stats (red if debuffed, green if buffed)
func _update_main_stats(stats) -> void:
	
	# Base stats
	var base_patk = stats.phys_attack if "phys_attack" in stats else 0
	var base_matk = stats.mag_attack if "mag_attack" in stats else 0
	var base_pdef = stats.phys_defense if "phys_defense" in stats else 0
	var base_mdef = stats.mag_defense if "mag_defense" in stats else 0
	var base_crit = stats.crit_chance if "crit_chance" in stats else 0

	# Current stats
	var curr_patk = stats.curr_phys_attack if "curr_phys_attack" in stats else 1
	var curr_matk = stats.curr_mag_attack if "curr_mag_attack" in stats else 0
	var curr_pdef = stats.curr_phys_defense if "curr_phys_defense" in stats else 1
	var curr_mdef = stats.curr_mag_defense if "curr_mag_defense" in stats else 0
	var curr_crit = stats.curr_crit_chance if "curr_crit_chance" in stats else 1

	_set_stat_label(stat_patk, "P-ATK", curr_patk, base_patk)
	_set_stat_label(stat_matk, "M-ATK", curr_matk, base_matk)
	_set_stat_label(stat_pdef, "P-DEF", curr_pdef, base_pdef)
	_set_stat_label(stat_mdef, "M-DEF", curr_mdef, base_mdef)
	_set_stat_label(stat_crit, "CRIT", curr_crit, base_crit)

# Set label text and color depending on buff/debuff
func _set_stat_label(label_node: Label, short_name: String, curr_value: Variant, base_value: Variant) -> void:
	
	label_node.text = "%s: %s" % [short_name, str(curr_value)]
	
	var col = COLOR_NORMAL
	if curr_value > base_value:
		col = COLOR_BUFF
	elif curr_value < base_value:
		col = COLOR_DEBUFF
	label_node.add_theme_color_override("font_color", col)

# Clear stat labels
func _clear_stats_labels() -> void:
	for lab in [stat_patk, stat_matk, stat_pdef, stat_mdef, stat_crit]:
		lab.text = ""
		lab.add_theme_color_override("font_color", COLOR_NORMAL)

# Clear entire display
func _clear_display() -> void:
	portrait.texture = null
	name_label.text = ""
	class_label.text = ""
	hp_bar.value = 0
	_clear_stats_labels()
	atk_range_label.text = ""
	move_range_label.text = ""
