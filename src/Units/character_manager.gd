extends Node2D

# Refrences world-objects
@onready var actors: Node2D = $"../Actors"
@onready var actions_menu: PanelContainer = $"../../GUI/Margin/ActionsMenu"
@onready var actor_info: PanelContainer = $"../../GUI/Margin/ActorInfo"

var character_list: Array
var character_list_copy: Array
var current_character
var num_characters: int
var _save: SaveGame

func _ready() -> void:
	# Default value for starting character
	current_character = actors.get_child(0)
	
	# Array storing all characters
	for actor: Actor in actors.get_children():
		character_list.append(actor)
	
	# Create copy of character_list to keep track of all character that were in the level before the game started
	character_list_copy = character_list.duplicate()

	num_characters = character_list.size()
	
	_load_save()
	

func set_current_character(character) -> void:
	current_character = character
	actor_info.display_actor_info(current_character)
	current_character.set_state(current_character.UnitState.SELECTED)	# Update state to selected
	if character.is_friendly:
				actions_menu.show()	# Show actions-menu when selecting playable actor
	
	
	
	
	
				
func _load_save():
	if SaveGame.save_exists():
		_save = SaveGame.load_save() as SaveGame
		
		for character in character_list:
			if character.is_friendly == true:
				if character.profile.battle_class_type == "Mage":
					character.stats = _save.playable_mage
				elif character.profile.battle_class_type == "Swordsman":
					character.stats = _save.playable_swordsman
			print("Loaded " + character.profile.character_name + " from save file")
	

	
func _save_game():
	print(_save)
	for character in character_list_copy:
			print("here ------ " + str(character))
			if character.is_friendly == true:
				if character.profile.battle_class_type == "Mage":
					_save.playable_mage = character.stats
				elif character.profile.battle_class_type == "Swordsman":
					_save.playable_swordsman = character.stats
			print("Saved " + character.profile.character_name)
	_save.write_save()
	
	
func _check_save() -> bool:
	if SaveGame.save_exists():
		return true
	else:
		return false
