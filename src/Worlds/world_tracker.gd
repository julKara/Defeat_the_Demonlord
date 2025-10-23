extends Node

@export var world_script: world_tracker

var _save: SaveGame

func _ready() -> void:
	_load_save()
	
func _load_save():
	if SaveGame.save_exists():
		_save = SaveGame.load_save() as SaveGame
		world_script = _save.level_progression
		print("Loaded game from save file")
	
func _create_save():
	_save = SaveGame.new()
	_save.level_progression = world_tracker.new()
	_save.write_save()
	world_script = _save.level_progression
	print("New save file created")
	
func _save_game():
	print(_save)
	_save.level_progression = world_script
	_save.write_save()
	print("Saved the game")
	
func _check_save() -> bool:
	if SaveGame.save_exists():
		return true
	else:
		return false
