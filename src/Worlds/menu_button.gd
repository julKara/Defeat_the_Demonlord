extends Button

func _pressed():
	var main_menu: String = "res://src/StartScreen/start_menu.tscn"

	if FileAccess.file_exists(main_menu):
		get_tree().change_scene_to_file(main_menu)
