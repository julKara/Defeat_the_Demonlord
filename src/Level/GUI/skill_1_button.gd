extends Button

@onready var info_label: RichTextLabel = $"../../SkillInfoPopup/SkillInfoLabel"
@onready var turn_manager: Node2D = $"../../../../../TileMapLayer/TurnManager"


var click_count := 0
var last_click_time := 0.0
const DOUBLE_CLICK_TIME := 0.4  # seconds allowed between clicks

func _ready() -> void:
	disabled = true	# Active skills-buttons are disabled on start

func _pressed() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	
	# Reset click count if too much time passed
	if now - last_click_time > DOUBLE_CLICK_TIME:
		click_count = 0
	
	click_count += 1
	last_click_time = now
	
	var actor = ClickHandler.selected_unit
	if actor == null or actor.skills.is_empty():
		print("Mo skills available.")
		return
	
	# Get first skill
	var skill: SkillResource = actor.skills[0]
	
	# If pressed once, display skill info
	if click_count == 1:
		# Show info
		_show_skill_info(skill)
	elif click_count == 2:	# If pressed twice, use skill
		# Use skill
		_use_skill(actor, skill)
		click_count = 0  # reset after use

func _show_skill_info(skill: SkillResource) -> void:
	if not info_label:
		push_warning("SkillInfoLabel not found in SkillMenu.")
		return

	var texten := "[b]%s[/b]\n%s" % [skill.skill_name, skill.description]
	if skill.duration > 0:
		texten += "\n[b]Duration:[/b] %d turns" % skill.duration
	
	info_label.text = texten
	info_label.visible = true  # show again if previously hidden


func _use_skill(actor, skill: SkillResource) -> void:
	print("\t%s uses %s!" % [actor.name, skill.skill_name])
	
	# Determine target (you can later expand this)
	var target = ClickHandler.selected_unit.get_behaviour().attack_target
	if target == null:
		return
		
	actor.use_skill(skill, target)
	
	# Hide info label after using the skill
	if info_label:
		if info_label.get_parent() is PopupPanel:
			info_label.get_parent().hide()
		else:
			info_label.visible = false
			
	turn_manager.end_player_unit_turn(ClickHandler.selected_unit)
