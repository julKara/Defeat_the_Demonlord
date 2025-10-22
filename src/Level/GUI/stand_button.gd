extends Button
@onready var character_manager: Node2D = $"../../../../../TileMapLayer/CharacterManager"
<<<<<<< Updated upstream
@onready var tile_map: TileMap = $"../../../../../TileMap"
@onready var draw_path: Node2D = $"../../../../../DrawPath"
@onready var actor_info: PanelContainer = $"../../../ActorInfo"
@onready var actions_menu: PanelContainer = $"../.."
=======
@onready var turn_manager: Node2D = $"../../../../../TileMapLayer/TurnManager"

>>>>>>> Stashed changes

var counter: int = 0

func _pressed() -> void:
<<<<<<< Updated upstream
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
	tile_map.clear_layer(1)
	tile_map.clear_layer(2)
	
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
=======
>>>>>>> Stashed changes

	
	var current = character_manager.current_character
	turn_manager.end_player_unit_turn(current)
