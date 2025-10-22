extends Node

@export var world_script: world_tracker

var _save: SaveGame

func _ready() -> void:
	pass
	
func _create_or_load_save():
	if SaveGame.save_exists():
		_save = SaveGame.load_save() as SaveGame
	else:
		_save = SaveGame.new()
