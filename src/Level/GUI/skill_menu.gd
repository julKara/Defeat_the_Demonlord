extends PanelContainer

@onready var actions_menu: PanelContainer = $"../ActionsMenu"


func _ready() -> void:
	# Battle is hidden on start, doesn't apear until clicking on skill-button
	hide()

func display_skill_menu() -> void:
	
	actions_menu.hide()
	
	show()

func hide_skill_menu() -> void:
	
	hide()
	
	actions_menu.show()
