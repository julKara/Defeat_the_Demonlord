extends Node2D

@onready var actors: Node2D = $"../Actors"

var character_list: Array
var current_character
var num_characters: int

func _ready() -> void:
	# Default value for starting character
	current_character = actors.get_child(0)
	
	# Array storing all characters
	for actor: Actor in actors.get_children():
		character_list.append(actor)
	
	num_characters = character_list.size()


func set_current_character(character) -> void:
	current_character = character
