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
		skill_1.disabled = false
		skill_1.click_count = 0
		if skill_1.skill.current_cooldown > 0:
			skill_1.text = " (%d) " %  skill_1.skill.current_cooldown
	if skill_2.skill != null:
		skill_2.text = skill_2.skill.skill_name
		skill_2.disabled = false
		skill_2.click_count = 0
		if skill_2.skill.current_cooldown > 0:
			skill_2.text = " (%d) " %  skill_2.skill.current_cooldown
	
	show()

func hide_skill_menu() -> void:
	
	hide()
	
	skill_1.disabled = true
	skill_2.disabled = true
	
	actions_menu.show()

# Resets all other buttons than the one pressed
func reset_other_buttons(except_button: Button) -> void:
	
	var skill_buttons = [skill_1, skill_2]

	for btn in skill_buttons:
		if btn == except_button:
			continue  # skip the button that was pressed

		if btn.skill == null:
			continue

		# Reset state to "base"
		btn.click_count = 0
		btn.disabled = false

		# Reset text (show cooldown if active)
		if btn.skill.current_cooldown > 0:
			btn.text = "%s (%d)" % [btn.skill.skill_name, btn.skill.current_cooldown]
		else:
			btn.text = btn.skill.skill_name
