@tool
extends Button

signal level_selected

@export var level_num: int = 1
@export var locked: bool = true:
	set(value):
		locked = value
		level_locked() if locked else level_unlocked()
		
func level_locked():
	disabled = true
	
func level_unlocked():
	disabled = false

func _on_pressed() -> void:
	# Play click sound
	AudioManager.play_sfx("Click")
	
	level_selected.emit(level_num) # Signal used to specify which level was selected
