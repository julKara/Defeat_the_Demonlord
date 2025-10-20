extends PanelContainer

# Return to level select and unlock next level
func _on_continue_pressed() -> void:
	get_tree().paused = false
