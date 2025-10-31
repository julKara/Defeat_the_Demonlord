extends Node

@export var world_script: world_tracker

var _save: SaveGame

func _ready() -> void:
	_load_save()
	
func _load_save():
	if SaveGame.save_exists():
		_save = SaveGame.load_save() as SaveGame
		world_script = _save.level_progression.duplicate()
		print("Loaded game from save file")
	
func _create_save():
	_save = SaveGame.new()
	_save.level_progression = world_tracker.new()
	_save.mageStats = preload("res://characters/Mage/mageStats.tres").duplicate()
	_save.knightStats = preload("res://characters/Knight/knightStats.tres").duplicate()
	_save.healerStats = preload("res://characters/Healer/healerStats.tres").duplicate()
	_save.write_save()
	world_script = _save.level_progression
	print("New save file created")
	
func _save_game():
	_save.level_progression = world_script.duplicate()
	_save.write_save()
	print("Saved the game")
	
func _check_save() -> bool:
	if SaveGame.save_exists():
		return true
	else:
		return false
