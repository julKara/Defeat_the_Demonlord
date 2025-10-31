extends Node

@onready var turn_manager: Node2D = $"../TileMapLayer/TurnManager"
@onready var demon_lord: Actor = $"../TileMapLayer/Actors/enemy_unit"

var phase

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	phase = turn_manager.current_phase
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if phase != turn_manager.current_phase:
		phase = turn_manager.current_phase
		if phase == 1:
			buff_demon_lord()

# Increases stats every turn, including hp
func buff_demon_lord():
	demon_lord.stats.curr_health += 5
	demon_lord.stats.max_health += 5
	demon_lord.stats.curr_mag_attack += 2
	demon_lord.stats.curr_mag_defense += 2
	demon_lord.stats.curr_phys_attack += 2
	demon_lord.stats.curr_phys_defense += 2
	
	# Update healthbar
	var hp_bar : ProgressBar = demon_lord.healthbar
	hp_bar.damagebar.max_value = demon_lord.stats.max_health
	hp_bar.max_value = demon_lord.stats.max_health
	hp_bar._set_health(demon_lord.stats.curr_health)
