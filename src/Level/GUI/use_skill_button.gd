extends Button

@onready var skill_menu: PanelContainer = $"../../../SkillMenu"


func _pressed() -> void:
	
	skill_menu.display_skill_menu()
