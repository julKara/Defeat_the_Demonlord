class_name Actor extends CharacterBody2D

# Refrences that executes before ready
@onready var position_target: Vector2 = position	# TAG : MOVEMENT (used in playable_unit)
@onready var input_delay: Timer = $InputDelay	# Refrence to delay for movement	# TAG : MOVEMENT (used in playable_unit)

# Constants
const CELL_SIZE: Vector2 = Vector2(48,48)	# TAG : MOVEMENT

# Executes every frame
func _process(delta: float) -> void:	# Delta not used
	
	position = position.move_toward(position_target, 2)	# Linear interpolation between postions	# TAG : MOVEMENT
	
	# If input-delay is running, code bellow doesnt run (timer is started after)	# TAG : MOVEMENT
	if not input_delay.is_stopped():
		return
	
	# Checking inputs and returns a movement-vector (pressing up gives (0, -1) bc up iss negative y-axis)
	var movement: Vector2 = Vectors.get_four_direction_vector(false);	# From Utils/Static, Vector is a static script from Tampopo Interactive Media (will be replaced)	# TAG : MOVEMENT
	
	# Update postion target with movement
	position_target = position + movement * CELL_SIZE	# TAG : MOVEMENT
	# Move one pixel per frame
	#move_and_collide(movement * 48)
	
	# Start timer
	input_delay.start()	# TAG : MOVEMENT
