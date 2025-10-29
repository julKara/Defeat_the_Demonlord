extends Button

@onready var panel_container: PanelContainer = $"../.."
@onready var settings_menu: PanelContainer = $"../../../SettingsMenu"


func _pressed() -> void:
	# Play click sound
	AudioManager.play_sfx("Click")
	
	panel_container.hide()
	settings_menu.show()
