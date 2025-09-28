@tool # Can execute in editor
class_name Actor extends CharacterBody2D

# Refrences that executes before ready
@onready var position_target: Vector2 = position	# TAG : MOVEMENT (used in playable_unit)
@onready var input_delay: Timer = $InputDelay	# Refrence to delay for movement	# TAG : MOVEMENT (used in playable_unit)

# Constants
const CELL_SIZE: Vector2 = Vector2(48,48)	# TAG : MOVEMENT

# Gameplay variables
var active: bool = false	# Says if unit can act
var cells_traveled: Array[Vector2] = []	# Stores the cells traveled by an actor
@export var stats: CharacterStats	# All stats to particular unit

# Executes every frame
func _process(delta: float) -> void:	# Delta not used
	
	# Check if current unit is active (aka allowed to act)
	if not active:
		return
	
	position = position.move_toward(position_target, 2)	# Linear interpolation between postions	# TAG : MOVEMENT
	
	# If input-delay is running, code bellow doesnt run (timer is started after)	# TAG : MOVEMENT
	if not input_delay.is_stopped() or not position.is_equal_approx(position_target):
		return
	
	# Checking inputs and returns a movement-vector (pressing up gives (0, -1) bc up iss negative y-axis)
	var movement: Vector2 = Vectors.get_four_direction_vector(false);	# From Utils/Static, Vector is a static script from Tampopo Interactive Media (will be replaced)	# TAG : MOVEMENT
	if movement.is_zero_approx():
		return
	
	# Move one pixel per frame
	if move_and_collide(movement, true):
		return
	
	# Update postion target with movement
	movement *= CELL_SIZE
	position_target = position + movement	# TAG : MOVEMENT
	
	# Add movement to cells_traveled, act as a log # TAG : MOVEMENT & BACKTRACKING
	cells_traveled.append(position_target / CELL_SIZE)
	
	# Start timer
	input_delay.start()	# TAG : MOVEMENT
	
	# For debugging
	#print(cells_traveled)
	#print(stats.mag_attack)
	queue_redraw()
	
func _draw() -> void:
	if active:
		draw_string(ThemeDB.fallback_font, Vector2(42,42), str(cells_traveled.size()))

######################
# Handles setting stats and colors

const FRIENDLY_COLOR: Color = Color("00a78f")
const ENEMY_COLOR: Color = Color.CRIMSON

func _ready() -> void:
	is_friendly = is_friendly
# Sets color based on bool (friendly/enemy) - may change to like healthbar or something else than collisionshape
@export var is_friendly: bool = false :
	set(value):
		is_friendly = value
		
		if is_friendly:
			$CollisionShape2D.self_modulate = FRIENDLY_COLOR
			name = "playble_Unit"
		else:
			$CollisionShape2D.self_modulate = ENEMY_COLOR
			name = "enemy_unit"
			
#####################
