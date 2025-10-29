extends Button

@onready var button_container: VBoxContainer = $".."
@onready var settings_menu: PanelContainer = $"../../SettingsMenu"


func _pressed() -> void:
	# Play click sound
	AudioManager.play_sfx("Click")
	
	button_container.hide()
	settings_menu.show()
