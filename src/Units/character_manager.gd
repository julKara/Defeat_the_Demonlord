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
	
	for actor: Actor in actors.get_children():
		# Array storing all characters
		character_list.append(actor)
		# Array storing copies of all characters. Used for leveling up and saving
		character_list_copy.append(actor.duplicate())

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
				var current_resource = character.stats.resource_name
				character.stats = _save.get(current_resource)
				print("Loaded " + character.profile.character_name + " from save file")
			
		for character in character_list_copy:
			if character.is_friendly == true:
				var current_resource = character.stats.resource_name
				character.stats = _save.get(current_resource)
	
	
func _save_game():
	for character in character_list_copy:
		if character.is_friendly == true:
			var current_resource = character.stats.resource_name
			_save.set(current_resource, character.stats.duplicate())
			print("Saved " + character.profile.character_name)
	_save.write_save()
	
