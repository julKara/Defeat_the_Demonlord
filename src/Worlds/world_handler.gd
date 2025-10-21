class_name world_tracker extends Resource

@export var current_world: int = 1
@export var current_level: int = 1
@export var worlds_unlocked: int = 1
@export var levels_unlocked: int = 1

func set_current_world(value):
	current_world = value

func set_current_level(value):
	current_level = value

func unlock_next_level():
	# If there are levels left in the current world -> unlock the next level
	if levels_unlocked < 5:
		levels_unlocked += 1
	# If all levels in the world are completed -> unlock the next world and reset unlocked levels
	else:
		levels_unlocked = 1
		worlds_unlocked += 1
