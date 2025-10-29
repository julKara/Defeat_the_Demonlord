extends PanelContainer

@onready var actions_menu: PanelContainer = $"../ActionsMenu"
@onready var skill_1: Button = $VBoxContainer/Skill1
@onready var skill_2: Button = $VBoxContainer/Skill2


func _ready() -> void:
	# Battle is hidden on start, doesn't apear until clicking on skill-button
	hide()

func display_skill_menu() -> void:
	
	actions_menu.hide()
	
	# If skill doesn't require attack-target
	if skill_1.skill != null:
		skill_1.text = skill_1.skill.skill_name
		if skill_1.skill.current_cooldown > 0:
			skill_1.text = " (%d) " %  skill_1.skill.current_cooldown
	#if skill_2.skill != null:
		#skill_2.text = skill_2.skill.skill_name
	
	show()

func hide_skill_menu() -> void:
	
	hide()
	
	skill_1.disabled = true
	
	actions_menu.show()
