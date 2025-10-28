# click_handler.gd
extends Node

# --- Refrences ---
var tile_map: TileMap
var character_manager: Node2D

# --- Member variables ---
var level_active := false # Tells if we are in a level
var selected_unit: Actor = null
var ui_nodes = []	# Stores all GUI-elements that does not count as an empty click

# --- CONSTANTS ---
const INVALID_POS: Vector2i = Vector2i(-9999, -9999)	# Used to set "null" for vector

# --- The meat and potatoes ---
func _ready() -> void:
	get_tree().connect("node_added", Callable(self, "_on_node_added"))

func _on_node_added(node):
	if node.name.begins_with("Level_"):
		_find_level_nodes()

# Handles all input from the player, but only registers left-mouse-click
func _input(event: InputEvent) -> void:
	
	# If not in an real level, skip
	if not level_active:
		return
	
	# If not in a valid level yet, skip
	if not is_instance_valid(tile_map) or not is_instance_valid(character_manager):
		return
	
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


# Protocol for handeling click on a enemy
func _handle_enemy_click(enemy: Actor) -> void:
	
	# If clicked on unit is on already-selected, deselect
	if selected_unit == enemy:
		_deselect_unit(enemy)
		return
	
	# If no unit is selected, select
	if selected_unit == null:
		_select_unit(enemy)
		return
	
	# If another was selected while having a enemy already selected, deselect it first and select new
	if selected_unit and selected_unit != enemy && not selected_unit.is_friendly:
		_deselect_unit(selected_unit)
		_select_unit(enemy)
		return

	# --- If a playable is selected
	
	# Get behaviour and check is acted (should not be moving if already acted)
	var playable_behaviour = selected_unit.get_behaviour()
	if not playable_behaviour or selected_unit.acted:
		return
	
	# Get all mobility-tiles and all tiles within attack-range
	var range_data = playable_behaviour.get_range_tiles()
	var move_tiles: Array[Vector2i] = range_data.move_tiles

	# Get some other useful info
	var enemy_pos: Vector2i = tile_map.local_to_map(enemy.global_position)
	var attack_range = selected_unit.stats.attack_range
	var current_tile = playable_behaviour.current_tile

	# --- Case 1: If enemy is already within attack-range, do not move, only select target
	if _is_enemy_in_attack_range(current_tile, enemy_pos, attack_range):
		#print("Enemy already within attack range — no movement needed.")
		playable_behaviour.set_attack_target(enemy)
		return

	# --- Case 2: Enemy is outside "current" attack-range, find a tile to move to within range
	var best_tile: Vector2i = _find_best_attack_tile(move_tiles, enemy_pos, attack_range)

	# If there is a functioning tile, move to that one and set enemy to attack-target
	if best_tile != INVALID_POS:
		await playable_behaviour.move_to(best_tile)
		playable_behaviour.set_attack_target(enemy)
	# If the enemy was out of range, select it instead
	else:
		#print("Enemy out of reachable tiles")
		_deselect_unit(selected_unit)
		selected_unit = null
		enemy.get_behaviour().select(true)


# Protocol for handeling clicks on non-units (includes movement)
func _handle_empty_tile_click(click_tile: Vector2i) -> void:
	
	# If no unit is selected, do nothing
	if not selected_unit:
		return
		
	# Ignore clicks on UI
	if _is_mouse_over_gui():
		return
	
	# If selected is a enemy, do nothing since they can't be controlled
	if not selected_unit.is_friendly:
		_deselect_unit(selected_unit)
		return

	# If has acted, do nothing since they can't be controlled
	var behaviour = selected_unit.get_behaviour()
	if not behaviour or selected_unit.acted:
		return
	
	var range_data = behaviour.get_range_tiles()
	var move_tiles: Array[Vector2i] = range_data.move_tiles
	
	if click_tile in move_tiles:
		await behaviour.move_to(click_tile)
	else:
		# TODO: deselect() when clicking on not unit, (actions-menu should not count)
		_deselect_unit(selected_unit)
		#print("Invalid move tile.")

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
		#print("\tSelected: ", actor.profile.character_name)


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
	#print("\tDeselected: ", actor.profile.character_name)

# --- UTIL ---

# Get actor on clicked tile (if there is one)
func _get_actor_at(click_tile: Vector2i) -> Actor:

	# Check every possible actor and try to mach it to the clicked tile
	for actor in character_manager.character_list:
		if not is_instance_valid(actor):
			continue
		var actor_tile :Vector2i = tile_map.local_to_map(actor.global_position)
		if click_tile == actor_tile:
			return actor
	return null


# Checks if the enemy is within attack range (diagonal range counts as one less)
func _is_enemy_in_attack_range(from_tile: Vector2i, enemy_tile: Vector2i, attack_range: int) -> bool:
	
	# Calculate range
	var dx = abs(from_tile.x - enemy_tile.x)
	var dy = abs(from_tile.y - enemy_tile.y)
	var eff_dist = max(dx, dy)
	
	# Check if diagonal
	var is_diagonal = dx > 0 and dy > 0
	if is_diagonal:
		eff_dist += 1

	return eff_dist <= attack_range


# Automatically finds the best tile to move to when attacking a target
func _find_best_attack_tile(move_tiles: Array[Vector2i], enemy_pos: Vector2i, attack_range: int) -> Vector2i:
	var best_tile: Vector2i = INVALID_POS

	# --- Check every tile in move range to find one at optimal attack distance
	for tile in move_tiles:
		# Calculate distance
		var dx = abs(tile.x - enemy_pos.x)
		var dy = abs(tile.y - enemy_pos.y)
		var eff_dist = max(dx, dy)
		
		# Check if diagonal attack, if so "shortens range" (otherwise to long)
		var is_diagonal = dx > 0 and dy > 0
		if is_diagonal:
			eff_dist += 1

		# eff_dist must equal attack_range
		if eff_dist == attack_range:
			var occupied: Actor = _get_actor_at(tile)
			if occupied == null:  # Only move to non-occupied tiles
				best_tile = tile
				break
			#else:
				#print("Tile ", tile, " is already occupied by ", occupied.profile.character_name)

	# --- If no tile is at optimal distance, choose nearest in range instead
	if best_tile == INVALID_POS:
		
		var closest_eff = INF
		for tile in move_tiles:
			# Calculate distance
			var dx = abs(tile.x - enemy_pos.x)
			var dy = abs(tile.y - enemy_pos.y)
			var eff_dist = max(dx, dy)
			
			# Check if diagonal attack, if so "shortens range" (otherwise to long)
			var is_diagonal = dx > 0 and dy > 0
			if is_diagonal:
				eff_dist += 1

			var occupied: Actor = _get_actor_at(tile)  # # Only move to non-occupied tiles

			# Choose the tile with minimal effective distance but still within attack_range
			if eff_dist < closest_eff and eff_dist <= attack_range and occupied == null:
				closest_eff = eff_dist
				best_tile = tile
			#elif occupied != null:
				#print("Skipped occupied tile!")
	return best_tile


# Check if mouse is currently over gui when "clicking on empty tile"
func _is_mouse_over_gui() -> bool:
	
	# Get mouse-pos
	var mouse_pos = get_viewport().get_mouse_position()

	# Go through all ui-nodes and chick if they were clicked on
	for ui in ui_nodes:
		if ui.visible:
			var rect = Rect2(ui.global_position, ui.size)
			if rect.has_point(mouse_pos):
				return true
	return false


# Setup click_handler
func _find_level_nodes() -> void:
	
	# Reset old references, when starting a new level
	level_active = false
	tile_map = null
	character_manager = null
	ui_nodes.clear()

	# Wait until the level scene is ready
	await get_tree().process_frame

	for node in get_tree().root.get_children():
		if node.name.begins_with("Level_"):
			
			# Get tile_map
			tile_map = node.get_node_or_null("TileMap")

			# Get character_manager
			var tilemap_layer = node.get_node_or_null("TileMapLayer")
			if tilemap_layer:
				character_manager = tilemap_layer.get_node_or_null("CharacterManager")

			# Apphend gui-elements to ui_nodes
			var gui = node.get_node_or_null("GUI")
			if gui:
				var margin = gui.get_node_or_null("Margin")
				if margin:
					var actions_menu = margin.get_node_or_null("ActionsMenu")
					var actor_info = margin.get_node_or_null("ActorInfo")
					if actions_menu:
						ui_nodes.append(actions_menu)
					if actor_info:
						ui_nodes.append(actor_info)

			level_active = true
			print("ClickHandler: Found level nodes for ", node.name)
			return

	push_warning("ClickHandler: No level starting with 'Level_' found under root!")
