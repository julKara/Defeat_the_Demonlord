extends ProgressBar

"""
This script manages everything that has to do with the unit's healthbar.
It gets updated when recieving healing or taking damage.
"""

@onready var timer: Timer = $Timer
@onready var damagebar: ProgressBar = $Damagebar

# Setter function
var health = 0 : set = _set_health

# Set the health to full in both bars
func init_health(health):
	health = health
	max_value = health
	value = health
	damagebar.max_value = health
	damagebar.value = health
	# print("Health set to :", health)	# TESTING

func _set_health(new_health):
	var prev_health = health
	
	# If healed
	health = min(max_value, new_health)
	value = health
	
	# If unit is dead, remove
	if health <= 0:
		queue_free()	# Ques healthbar and all its children to be deleted
	
	# If taking damage (but not dying)
	if health < prev_health:
		timer.start()
	else:	# Aka, when  getting healed and such...
		damagebar.value = health


func _on_timer_timeout() -> void:
	damagebar.value = health
