extends Button

func _pressed():
	
	# Play click sound
	AudioManager.play_sfx("Click")
	
	await get_tree().create_timer(0.2).timeout
	
	get_tree().quit()
