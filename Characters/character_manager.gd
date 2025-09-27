extends Node2D

@onready var character1 = $Character1
@onready var character2 = $Character2

var character_list: Array
var current_character

func _ready() -> void:
	current_character = character2
	
	character_list = [character1, character2]
		
	print(character_list[1])

func set_current_character(character) -> void:
	current_character = character
