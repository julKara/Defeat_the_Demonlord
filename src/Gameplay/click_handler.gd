# click_handler.gd
extends Node

# --- Refrences ---
var tile_map: TileMap
var range_tile_map: TileMap
var character_manager: Node2D
var actions_menu: PanelContainer
var actor_info: PanelContainer

# --- Member variables ---
var selected_unit: Actor = null

# --- CONSTANTS ---
const INVALID_POS: Vector2i = Vector2i(-9999, -9999)
const ADJACENT_TILES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

# --- The meat and potatoes ---
func _ready() -> void:
	# Should not be able to click imideiatly 
	await get_tree().create_timer(0.05).timeout
	
	# Intialize all refrence-variables seen on top of ducoment
	_find_level_nodes()

# Handles all input from the player, but only registers left-mouse-click
func _input(event: InputEvent) -> void:
	
	# Check correct button
	if not event.is_action_pressed("left_mouse_button"):
		return

	# Convert mouse position into the local space of the TileMap before mapping to a cell # Needs FIX when new level
	var local_mouse := tile_map.to_local(event.position)
	var click_pos: Vector2i = tile_map.local_to_map(local_mouse)

	# Get the actor on the tile if there is one.
	var clicked_actor: Actor = _get_actor_at(click_pos)

	# If clicked on an actor, handle depending on if it is friendly or enemy
	if clicked_actor != null:
		if clicked_actor.is_friendly:
			_handle_playable_click(clicked_actor)
		else:
			_handle_enemy_click(clicked_actor)
		return

	# Otherwise handle empty tile click
	if selected_unit:
		_handle_empty_tile_click(click_pos)

# --- Handelers ---

# Protocol for handeling click on a player
func _handle_playable_click(actor: Actor) -> void:
	
	# If click is on already-selected, deselect
	if selected_unit == actor:
		_deselect_unit(actor)
		return

	# If another was selected while having a unit already selected, deselect it first
	if selected_unit and selected_unit != actor:
		_deselect_unit(selected_unit)

	# Then select the clicked actor
	_select_unit(actor)

func _handle_enemy_click(enemy: Actor) -> void:
	
	# TODO: Deselect, check if within range to select even if there is a selected unit
	
	# If no playable unit is selected: show enemy info (inspect)
	if selected_unit == null:
		enemy.get_behaviour().selectEnemy()
		return

	# If a friendly is selected, try to move to the unit
	var behaviour = selected_unit.get_behaviour()
	if not behaviour or selected_unit.acted:
		return

	var move_tiles: Array[Vector2i] = behaviour.get_move_tiles()
	var enemy_pos: Vector2i = tile_map.local_to_map(enemy.global_position)

	# Find an adjacent tile within move range (prefer nearest)
	var best_tile: Vector2i = INVALID_POS
	for offset in ADJACENT_TILES:
		var check_tile = enemy_pos + offset
		if check_tile in move_tiles:
			best_tile = check_tile
			break

	if best_tile != INVALID_POS:
		# Move there but do NOT auto-finalize acted — allow repositioning after move
		await behaviour.move_to(best_tile)
		# set the target (visual highlight) but do not auto-attack here; the UI/attack button can be used
		behaviour.set_attack_target(enemy)
		print("Moved to attack-adjacent tile for target: ", enemy.profile.character_name)
	else:
		# If enemy is not reachable by movement but we want to just show info, do so
		print("Enemy out of reachable tiles from origin.")
		# also show enemy info as helpful feedback
		if actor_info:
			actor_info.display_actor_info(enemy)

func _handle_empty_tile_click(click_tile: Vector2i) -> void:
	if not selected_unit:
		return

	var behaviour = selected_unit.get_behaviour()
	if not behaviour or selected_unit.acted:
		return

	var move_tiles: Array[Vector2i] = behaviour.get_move_tiles()
	if click_tile in move_tiles:
		await behaviour.move_to(click_tile)
	else:
		print("Invalid move tile.")

# --- Selection logic ---
func _select_unit(actor: Actor) -> void:
	selected_unit = actor
	var behaviour = actor.get_behaviour()
	if behaviour:
		# Check if already acted, will not get actions-menu if acted
		if actor.acted:
			behaviour.select(true)
		else:
			behaviour.select(false)
		print("\tSelected: ", actor.profile.character_name)

# Protocol for deselecting a unit
func _deselect_unit(actor: Actor) -> void:
	if not actor:
		return

	# Get playable_unit or enemy_unit and call its deselection
	var behaviour = actor.get_behaviour()
	if behaviour:
		behaviour.deselect()
		if not actor.acted && actor.is_friendly:	# Only friendly units should be reset
			behaviour.reset_position_if_not_acted()
	selected_unit = null
	print("\tDeselected: ", actor.profile.character_name)

# --- UTIL ---

# Get acotr on clicked tile (if there is one)
func _get_actor_at(click_tile: Vector2i) -> Actor:

	# Check every possible actor and try to mach it to the clicked tile
	for actor in character_manager.character_list:
		if not is_instance_valid(actor):
			continue
		var actor_tile :Vector2i = tile_map.local_to_map(actor.global_position)
		if click_tile == actor_tile:
			return actor
	return null

func _find_level_nodes() -> void:
	# Find active level root (first child under root that isn’t an autoload)
	for node in get_tree().root.get_children():
		if node.name.begins_with("Level_"):  # adjust to your level naming
			#print("Found level root: ", node.name)
			tile_map = node.get_node_or_null("TileMap")
			range_tile_map = node.get_node_or_null("RangeTileMap")	
			# --- TILEMAPLAYER ELEMENTS ---
			var tilemap_layer = node.get_node_or_null("TileMapLayer")
			if tilemap_layer:
				character_manager = tilemap_layer.get_node_or_null("CharacterManager")
				#print("CharacterManager found: ", character_manager != null)
			# --- GUI ELEMENTS ---
			var gui = node.get_node_or_null("GUI")
			if gui:
				#print("Found GUI.")
				var margin = gui.get_node_or_null("Margin")
				if margin:
					#print("Found Margin.")
					actions_menu = margin.get_node_or_null("ActionsMenu")
					actor_info = margin.get_node_or_null("ActorInfo")
					#print("ActionsMenu found: ", actions_menu != null)
					#print("ActorInfo found: ", actor_info != null)
				else:
					push_warning("ClickHandler: MarginContainer not found under GUI.")
			else:
				push_warning("ClickHandler: GUI not found under level root.")
			# Exit once set everything up for this level
			return
	push_warning("ClickHandler: No level starting with 'Level_' found under root!")
