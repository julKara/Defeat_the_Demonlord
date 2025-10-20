extends PanelContainer

# Restart level
func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
	

# Return to level select
func _on_return_pressed() -> void:
	get_tree().paused = false
