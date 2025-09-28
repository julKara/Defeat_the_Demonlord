extends Node2D

# If selecting actor was implemented...
#var highlighted_actor: Actor = null :
	#set(value):
		#highlighted_actor = value
		#gui.set_highlighted_actor(value)	# Call gui on selceted unit

# Refrences
@onready var actors: Node2D = $TileMapLayer/Actors
@onready var gui: CanvasLayer = $GUI

func _ready() -> void:
	actors.get_child(0).active = true
	gui.set_highlighted_actor(actors.get_child(0))	# Call gui on selceted unit
