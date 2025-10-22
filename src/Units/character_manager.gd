extends Node2D

# Refrences world-objects
@onready var actors: Node2D = $"../Actors"
@onready var actions_menu: PanelContainer = $"../../GUI/Margin/ActionsMenu"
@onready var actor_info: PanelContainer = $"../../GUI/Margin/ActorInfo"

var character_list: Array
var character_list_copy: Array
var current_character
var num_characters: int

func _ready() -> void:
	# Default value for starting character
	current_character = actors.get_child(0)
	
	# Array storing all characters
	for actor: Actor in actors.get_children():
		character_list.append(actor)
	
	# Create copy of character_list to keep track of all character that were in the level before the game started
	character_list_copy = character_list
	
	num_characters = character_list.size()
	



func set_current_character(character) -> void:
	current_character = character
	actor_info.display_actor_info(current_character)
	current_character.set_state(current_character.UnitState.SELECTED)	# Update state to selected
	if character.is_friendly:
				actions_menu.show()	# Show actions-menu when selecting playable actor
