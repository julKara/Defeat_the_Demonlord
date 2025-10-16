extends Button
@onready var character_manager: Node2D = $"../../../../../TileMapLayer/CharacterManager"
@onready var tile_map: TileMap = $"../../../../../TileMap"
@onready var range_tile_map: TileMap = $"../../../../../RangeTileMap"
@onready var draw_path: Node2D = $"../../../../../DrawPath"
@onready var actor_info: PanelContainer = $"../../../ActorInfo"
@onready var actions_menu: PanelContainer = $"../.."

var counter: int = 0

func _pressed() -> void:
	# Find the behaviour node of the current character
	var all_children = character_manager.current_character.get_children()
	var behaviour_node
		
	for child in all_children:
		if child is Node:
			behaviour_node = child
	
	# Update the startposision of the current playable character to be where it ended its move
	if character_manager.current_character.is_friendly == true:
		behaviour_node.start_position = tile_map.local_to_map(character_manager.current_character.global_position)
	
	# Hide mobility and attack range
	range_tile_map.clear_layer(0)
	range_tile_map.clear_layer(1)
	
	# Deselect character
	behaviour_node.selected = false
	
	# Remove highlight from attack target
	if behaviour_node.attack_target != null:
		all_children = behaviour_node.attack_target.get_children()
		var sprite
		for child in all_children:
			if child is Sprite2D:
				sprite = child
		sprite.material.set("shader_parameter/width", 0.0)
	
	# Remove selected attack target
	behaviour_node.attack_target = null
	
	# Hidde movement path, actions-menu and actor info
	draw_path.hide()
	actions_menu.hide()
	actor_info.hide_actor_info()

	# Update the current character to the next in the array
	character_manager.set_current_character(character_manager.character_list[counter%character_manager.num_characters])
	counter = counter + 1
	
	# Update behaviour node to the new character
	all_children = character_manager.current_character.get_children()
	for child in all_children:
		if child is Node:
			behaviour_node = child
	
	if character_manager.current_character.is_friendly == true:	
		# Highlight and select the updated current character
		behaviour_node.highlight_range()
	else:		
		# AI enemy plays its turn
		behaviour_node.play_turn()
