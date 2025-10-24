# click_handler.gd
extends Node

var tile_map: TileMap
var range_tile_map: TileMap
var character_manager: Node2D
var actions_menu: PanelContainer
var actor_info: PanelContainer

var selected_actor: Actor = null

func _ready() -> void:
	# Try to locate level-specific managers each time a level loads
	_find_level_nodes()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("left_mouse_button"):
		return

	# Get clikced tile
	var mouse_pos = tile_map.get_global_mouse_position()
	var clicked_tile = tile_map.local_to_map(mouse_pos)

	# Detect which actor (if any) was clicked and handle that
	var clicked_actor = _get_actor_at_tile(clicked_tile)
	if clicked_actor:
		_handle_actor_click(clicked_actor)
		return

	# Else, clicked on an "empty" tile (no actor detected)
	_handle_empty_tile_click(clicked_tile)


# Get the actor at which tile player clicked
func _get_actor_at_tile(tile_pos: Vector2i) -> Actor:
	for actor in character_manager.character_list:
		if tile_map.local_to_map(actor.global_position) == tile_pos:
			return actor
	return null

# Protocol for clicking on an unit
func _handle_actor_click(clicked_actor: Actor) -> void:
	
	# --- Deselect prev unit (if needed)
	# If clicking the same actor, deselect and return
	if selected_actor == clicked_actor:
		selected_actor.get_behaviour().deselect()
		selected_actor = null
		return
	# If another unit was already selected, deselect it
	if selected_actor and selected_actor != clicked_actor:
		selected_actor.get_behaviour().deselect()
		selected_actor = null

	# Select the clicked actor
	selected_actor = clicked_actor
	selected_actor.get_behaviour().select()

	# Display info and actions-menu (if friendly)
	actor_info.display_actor_info(clicked_actor)
	if clicked_actor.is_friendly:
		actions_menu.show()
	else:
		actions_menu.hide()


# Else, clicked on an "empty" tile (no actor detected)
func _handle_empty_tile_click(tile_pos: Vector2i) -> void:
	
	# If there is no selected actor, return
	if not selected_actor:
		return

	# Get need variables from currently selected actor
	var behaviour = selected_actor.get_behaviour()
	var move_range_tiles = behaviour.get_mobility_tiles()
	var attack_range_tiles = behaviour.get_attack_tiles()

	# If clicked tile is NOT inside move or attack range, deselect current unit
	if not (tile_pos in move_range_tiles or tile_pos in attack_range_tiles):
		behaviour.deselect()
		selected_actor = null

# --- UTIL ---
func _find_level_nodes() -> void:
	# Find active level root (first child under root that isn’t an autoload)
	for node in get_tree().root.get_children():
		if node.name.begins_with("Level_"):  # adjust to your naming
			# Get tilemaplayer-element
			var tilemap_layer = node.get_node_or_null("TileMapLayer")
			if tilemap_layer:
				character_manager = tilemap_layer.get_node_or_null("CharacterManager")
			# Get gui-elements
			var gui = node.get_node_or_null("GUI")
			if gui:
				actions_menu = gui.get_node_or_null("ActionsMenu")
				actor_info = gui.get_node_or_null("ActorInfo")
			# Get level-elements
			if node.get_node_or_null("TileMap"):
				tile_map = node.get_node_or_null("TileMap")
			if node.get_node_or_null("RangeTileMap"):
				range_tile_map = node.get_node_or_null("RangeTileMap")
			return
	push_warning("BattleHandlerGlobal: Could not find everything for click-handler in current level!")
