extends Node

@export var music_player: AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_music_for_scene(scene: String):
	var scene_music = str(scene + "Music")
	music_player["parameters/switch_to_clip"] = scene_music
