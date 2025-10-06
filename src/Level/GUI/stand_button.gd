extends Button
@onready var character_manager: Node2D = $"../../../../../TileMapLayer/CharacterManager"
@onready var tile_map: TileMap = $"../../../../../TileMap"
@onready var draw_path: Node2D = $"../../../../../DrawPath"
@onready var actor_info: PanelContainer = $"../../../ActorInfo"
@onready var actions_menu: PanelContainer = $"../.."

var counter: int = 0

func _pressed() -> void:
	# Update the startposision of the current character to be where it ended its move
	character_manager.current_character.start_position = tile_map.local_to_map(character_manager.current_character.global_position)
	
	# Hide mobility and attack range
	tile_map.clear_layer(1)
	tile_map.clear_layer(2)
	
	# Deselect character
	character_manager.current_character.selected = false
	
	# Hidde movement path, actions-menu and actor info
	draw_path.hide()
	actions_menu.hide()
	actor_info.hide_actor_info()

	# Update the current character to the next in the array
	character_manager.set_current_character(character_manager.character_list[counter%character_manager.num_characters])
	counter = counter + 1
	
	# Highlight and select the updated current character
	character_manager.current_character.highlight_range()
