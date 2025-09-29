extends PanelContainer

func _ready() -> void:
	
	# Battle is hidden on start, doesn't apear until selecting a unit...
	hide()
	
func show_actions_menu() -> void:
	show()
