extends Control

@onready var demonlord_defeated: Label = $DemonlordDefeated
@onready var text_container: VBoxContainer = $TextContainer

func _ready() -> void:

	var tween = create_tween()
	tween.tween_property(demonlord_defeated, "modulate", Color(1,1,1,1), 5.0)
	tween.tween_interval(0.3)
	tween.tween_property(demonlord_defeated, "modulate", Color(1,1,1,0), 2.0)
	tween.tween_interval(0.3)
	tween.tween_property(text_container, "position:y", -650, 30.0)
	
	await tween.finished
	
	var main_menu: String = "res://src/StartScreen/start_menu.tscn"

	if FileAccess.file_exists(main_menu):
		get_tree().change_scene_to_file(main_menu)
		AudioManager.update_music_for_scene("Menu")
