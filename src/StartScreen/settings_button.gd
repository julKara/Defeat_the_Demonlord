extends Button

@onready var button_container: VBoxContainer = $".."
@onready var settings_menu: PanelContainer = $"../../SettingsMenu"
@onready var button_background: Panel = $"../../ButtonBackground"


func _pressed() -> void:
	# Play click sound
	AudioManager.play_sfx("Click")
	
	button_container.hide()
	button_background.hide()
	settings_menu.show()
