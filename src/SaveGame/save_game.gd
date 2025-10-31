class_name SaveGame
extends Resource

const SAVE_GAME_PATH := "user://save.tres"

# Resources that get saved
@export var level_progression: Resource
@export var mageStats: Resource
@export var knightStats: Resource
@export var healerStats: Resource


func write_save():
	ResourceSaver.save(self, SAVE_GAME_PATH)
	
static func save_exists() -> bool:
	return ResourceLoader.exists(SAVE_GAME_PATH)

static func load_save() -> Resource:
	return ResourceLoader.load(SAVE_GAME_PATH, "", 4)
