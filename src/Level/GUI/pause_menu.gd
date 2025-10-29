extends PanelContainer

@onready var music_volume_slider: HScrollBar = $VBoxContainer/MusicContainer/MusicVolume
@onready var sfx_volume_slider: HScrollBar = $VBoxContainer/SfxContainer/SfxVolume
@onready var world_handler: Node = $"../../../WorldHandler"

var current_world


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Pause menu hidden at startup
	hide()
	
	# Set current world
	current_world = world_handler.world_script.current_world
	
	# Find the audio busses
	var music_bus_index = AudioServer.get_bus_index("music")
	var sfx_bus_index = AudioServer.get_bus_index("sfx")
	
	# Get previous volume
	var music_volume = AudioServer.get_bus_volume_db(music_bus_index)
	var sfx_volume = AudioServer.get_bus_volume_db(sfx_bus_index)
	
	# Set previous volume
	music_volume_slider.value = music_volume
	sfx_volume_slider.value = sfx_volume


func _process(delta: float) -> void:
	update_volume()


func update_volume():
	# Get volume value from sliders
	var music_volume = music_volume_slider.value
	var sfx_volume = sfx_volume_slider.value
	
	# Find the audio busses
	var music_bus_index = AudioServer.get_bus_index("music")
	var sfx_bus_index = AudioServer.get_bus_index("sfx")
	
	# Update the volume of the busses
	AudioServer.set_bus_volume_db(music_bus_index, music_volume)
	AudioServer.set_bus_volume_db(sfx_bus_index, sfx_volume)


# Close the menu
func _on_close_pressed() -> void:
	# Play click sound
	AudioManager.play_sfx("Click")
	
	hide()
	get_tree().paused = false


func _on_return_level_select_pressed() -> void:
	get_tree().paused = false
	
	# Play click sound
	AudioManager.play_sfx("Click")
	
	# Return to level select
	var level_select: String = "res://src/Worlds/World_" + str(current_world) + "/world_" + str(current_world) + "_level_select.tscn" # Filepath to selected level
	# If the filepath is valid, change scene to the selected level
	if FileAccess.file_exists(level_select):
		get_tree().change_scene_to_file(level_select)
		AudioManager.update_music_for_scene("Menu")
