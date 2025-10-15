extends ProgressBar

"""
Handles the unit’s healthbar UI:
 # main bar shows current HP
 # damagebar lags behind to show recent damage taken
"""

@onready var timer: Timer = $Timer
@onready var damagebar: ProgressBar = $Damagebar

var health := 0 : set = _set_health


# Initialize both bars (called in actor -ready()
func init_health(in_health: int) -> void:
	health = in_health
	
	# Set healthbar
	max_value = in_health
	value = in_health

	# Set damagebar
	damagebar.max_value = in_health
	damagebar.value = in_health


# Called whenever the units health updates
func _set_health(new_health: int) -> void:
	var prev_health := health
	health = clamp(new_health, 0, max_value)	# Not less than min, not more than max

	# If unit dies, set bars to 0
	if health <= 0:
		value = 0
		damagebar.value = 0
		return

	# Update the main health bar immediately
	value = health

	# If the unit took damage
	if health < prev_health:
		# Set damagebar to previous health so "gray health" is visible
		damagebar.value = prev_health
		# Start timer to trigger the delayed drop
		timer.start()
	else:
		# If healed, raise both instantly
		damagebar.value = health


# Called when the timer finishes (gray bar goes down)
func _on_timer_timeout() -> void:
	var tween = create_tween()
	tween.tween_property(damagebar, "value", health, 0.3)
