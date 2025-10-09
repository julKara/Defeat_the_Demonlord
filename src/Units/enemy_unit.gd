class_name enemy_unit extends Node

@onready var character_manager: Node2D = $TileMapLayer/CharacterManager
@onready var actors: Node2D = $TileMapLayer/Actors

# Maybe enemy AI will be stored here...
func _ready():
	print("Enemy unit ready — AI active.")	# TESTING

# func _process(delta):
	# Simple AI behavior
	# print("Enemy thinking...")	# TESTING


#func find_closest_player() -> CharacterBody2D:
	#
	#var shortest_path = actors.astar_grid.get_id_path(Vector2i(0,0) ,actors.astar_grid.region.size)
	#
	#for x in character_manager.character_list:
		#var temp = (actors.astar_grid.get_id_path(actors.tile_map.local_to_map(global_position),
		#actors.tile_map.local_to_map(x.global_position)))
