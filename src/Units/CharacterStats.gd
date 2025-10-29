# Numerically represents stats to all instances of the class [actor]
class_name CharacterStats extends Resource

# Character Stats
@export var curr_health : int
@export var max_health : int
@export var original_max_health : int

@export var phys_attack : int
@export var original_phys_attack : int
var curr_phys_attack : int

@export var mag_attack : int  
@export var original_mag_attack : int
var curr_mag_attack : int

@export var phys_defense : int
@export var original_phys_defense : int
var curr_phys_defense : int

@export var mag_defense : int
@export var original_mag_defense : int
var curr_mag_defense : int

@export var crit_chance : int
@export var original_crit_chance : int
var curr_crit_chance : int

@export var attack_range : int	# How many blocks away unit can attack
@export var original_attack_range : int
var curr_attack_range : int

@export var mobility : int	# How many blocks a unit can move
@export var original_mobility : int
var curr_mobility : int

@export var level : int
@export var speed: float	# How fast each unit moves/attack??

# Stats for leveling up
@export var health_gain : int
@export var phys_atk_gain : int
@export var phys_def_gain : int
@export var mag_atk_gain : int
@export var mag_def_gain : int
@export var crit_gain : int

# List of all stats that can be modified
const MODIFIABLE_STATS = [
	"curr_health", "max_health", "curr_phys_attack", "curr_mag_attack", "curr_phys_defense", "curr_mag_defense", "curr_crit_chance"
	, "curr_mobility", "curr_attack_range"
]

# Set-functions
func init_stats():
	curr_health = max_health
	curr_phys_attack = phys_attack
	curr_mag_attack = mag_attack
	curr_phys_defense = phys_defense
	curr_mag_defense = mag_defense
	curr_crit_chance = crit_chance
	curr_attack_range = attack_range
	curr_mobility = mobility

# Set-functions
func set_max_health(value):
	max_health = max(0, value)

# Basic combat functions
func take_damage(hit):
	curr_health -= hit
	curr_health = max(0, curr_health)	# Make sure health is 0 or more
		
func recieve_healing(amount):
	curr_health += amount
	curr_health = min(curr_health, max_health)
