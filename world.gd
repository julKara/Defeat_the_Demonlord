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
	actors.get_child(0).selected = true
	gui.set_highlighted_actor(actors.get_child(0))	# Call gui on selceted unit
	
	for actor: Actor in actors.get_children():
		# actor.selected.connect(_on_actor_selcted)
		# actor.deselected.connect(on_actor_deselected)
		actor.ready_to_act.connect(_on_actor_ready_to_act)
		
func _on_actor_ready_to_act(actor: Actor) -> void:
	gui.open_actions_menu()
