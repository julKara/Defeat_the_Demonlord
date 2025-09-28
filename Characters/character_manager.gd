extends Node2D

@onready var character1 = $Character1
@onready var character2 = $Character2
@onready var character3 = $Character3

var character_list: Array
var current_character
var num_characters: int

func _ready() -> void:
	# Default value for starting character
	current_character = character1
	
	# Array storing all characters
	character_list = [character1, character2, character3]
	
	num_characters = character_list.size()


func set_current_character(character) -> void:
	current_character = character
