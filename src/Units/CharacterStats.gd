# Numerically represents stats to all instances of the class [Character]
class_name CharacterStats extends Resource

# Non-modifiable aspects of Character
@export var character_name : String = "John"
@export var battle_class_type : String = "Class"

# Character Stats
@export var curr_health : int
@export var max_health : int
@export var phys_attack : int
@export var mag_attack : int  
@export var phys_defense : int
@export var mag_defense : int
@export var crit_chance : int
@export var level : int
@export var attack_range : int	# How many blocks away unit can attack
@export var mobility : int	# How many blocks a unit can move
@export var speed: float	# How fast each unit moves/attack??

# Signals
signal health_changed
signal health_depleated

# List of all stats that can be modified
const MODIFIABLE_STATS = [
	"curr_health", "max_health", "phys_attack", "mag_attack", "phys_defense", "mag_defense", "crit_chance", "level", "mobility"
]

# Set-functions
func set_max_health(value):
	max_health = max(0, value)

# Basic combat functions
func take_damage(hit):
	curr_health -= hit
	curr_health = max(0, curr_health)	# Make sure health is 0 or more
	
	emit_signal("health_changed", curr_health)
	
	if(curr_health == 0):	# Death
		emit_signal("health_depleated")
		
func recieve_healing(amount):
	curr_health += amount
	curr_health = min(curr_health, max_health)
	emit_signal("health_changed", amount)
