extends Node2D

# Refrences
@onready var actors: Node2D = $TileMapLayer/Actors

func _ready() -> void:
	actors.get_child(0).active = true
	
