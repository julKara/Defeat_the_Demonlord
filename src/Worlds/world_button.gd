@tool
extends Button

signal world_selected

@export var world_num: int = 1
@export var locked: bool = true:
	set(value):
		locked = value
		world_locked() if locked else world_unlocked()
		
func world_locked():
	disabled = true
	
func world_unlocked():
	disabled = false

func _on_pressed() -> void:
	# Play click sound
	AudioManager.play_sfx("Click")
	
	world_selected.emit(world_num) # Signal used to specify which level was selected
