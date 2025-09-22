extends CharacterBody2D

# Refrences
@onready var input_delay: Timer = $InputDelay	# Refrence to delay for movement

# Executes every frame
func _process(delta: float) -> void:
	
	# If input-delay is running, code bellow doesnt run (timer is started after)
	if not input_delay.is_stopped():
		return
	
	# Checking inputs and returns a movement-vector (pressing up gives (0, -1) bc up iss negative y-axis)
	var movement: Vector2 = Vectors.get_four_direction_vector(false);	# From Utils/Static, Vector is a static script from Tampopo Interactive Media (will be replaced)
	
	# Move one pixel per frame
	move_and_collide(movement * 48)
	
	# Start timer
	input_delay.start()
