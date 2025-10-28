extends Node

@export var music_player: AudioStreamPlayer
@export var sfx_player: AudioStreamPlayer


func update_music_for_scene(scene: String):
	var scene_music = str(scene + "Music")
	music_player["parameters/switch_to_clip"] = scene_music
