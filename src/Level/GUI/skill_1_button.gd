# skill_1_button.gd
extends Button

@export var skill_index: int = 0    # make reusable for slot 0,1,2...
@onready var skill_menu := get_parent()                          # assumed immediate parent is SkillMenu
@onready var turn_manager: Node = $"../../../../../TileMapLayer/TurnManager"
@onready var skill_info_popup: PopupPanel = $"../../SkillInfoPopup"
@onready var skill_info_label: RichTextLabel = $"../../SkillInfoPopup/SkillInfoLabel"

var skill: SkillResource = null

var click_count := 0
var last_click_time := 0.0
const DOUBLE_CLICK_TIME := 0.4  # seconds allowed between clicks

func _ready() -> void:
	
	# Ensure popup is hidden at start
	if skill_info_popup:
		skill_info_popup.hide()

	# Disable on start, gets enabled in select target of playable unit
	disabled = true


func _pressed() -> void:
	
	click_count += 1
	
	var actor := ClickHandler.selected_unit
	if actor == null:
		print("No selected unit.")
		return
	if not ("skills" in actor) or actor.skills.size() <= skill_index:
		print("No skill in that slot.")
		return
	
	skill = actor.skills[skill_index]
	
	# Double-click (quick second press) => use immediately
	if click_count >= 2:
		_use_skill(actor, skill)
		click_count = 0
		return
	
	# Otherwise, show info (single click)
	text = "Use Skill"
	_show_skill_info(skill)

func _show_skill_info(skill: Resource) -> void:
	
	if skill_info_label == null or skill_info_popup == null:
		push_warning("SkillInfoPopup or SkillInfoLabel not found.")
		return
	
	# Build text
	var text := "[b]%s[/b]\n\n%s" % [skill.skill_name, skill.description]
	if "skill_type" in skill:
		text += "\n\n[b]Skill Type:[/b] %s" % skill.skill_type
	if "duration" in skill and skill.duration > 0:
		text += "\n\n[b]Duration:[/b] %d turn(s)" % skill.duration
	if "cooldown" in skill and skill.duration > 0:
		text += "\n\n[b]Cooldown:[/b] %d turn(s)" % skill.cooldown
	
	skill_info_label.bbcode_enabled = true
	skill_info_label.clear()
	skill_info_label.append_text(text)
	
	# Show popup
	skill_info_popup.popup()

func _use_skill(actor: Node, skill: Resource) -> void:
	
	# Determine target
	var target = null
	
	if skill.target_type == "Self":
		target = ClickHandler.selected_unit
		if target == null:
			return
	
	if skill.target_type == "Enemy":
		target = ClickHandler.selected_unit.get_behaviour().attack_target
		if target == null:
			return
	
	# If no target selected, keep popup open (or close and print)
	if target == null:
		print("No target selected for skill:", skill.skill_name)
		return
	
	# Call actor.use_skill (assumes this method exists)
	if actor.has_method("use_skill"):
		actor.use_skill(skill, target)
		print("\t%s uses %s on %s" % [actor.profile.character_name, skill.skill_name, target.name])
	else:
		push_warning("Actor missing use_skill() method.")
	
	# Hide popup after using skill
	if skill_info_popup:
		skill_info_popup.hide()
	
	# End unit turn if desired
	if turn_manager and skill.ends_turn:
		turn_manager.end_player_unit_turn(actor)
