extends Button

@onready var skill_menu: PanelContainer = $"../../../SkillMenu"

func _pressed() -> void:
	
	skill_menu.hide_skill_menu()
