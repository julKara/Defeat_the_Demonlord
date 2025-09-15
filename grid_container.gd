@tool
extends GridContainer

@export var width := 5:
	set(value):
		width = value
		_remove_grid()
		_create_grid()

@export var height := 5:
	set(value):
		height = value
		_remove_grid()
		_create_grid()

@export var cell_width := 60:
	set(value):
		cell_width = value
		_remove_grid()
		_create_grid()

@export var cell_height := 60:
	set(value):
		cell_height = value
		_remove_grid()
		_create_grid()

const grid_cell = preload("res://grid_cell.tscn")
const border_size: int = 4

func _ready():
	_create_grid()
	
func _create_grid():
	columns = width
	
	for i in height:
		var grid_cell_node = grid_cell.instantiate()
		grid_cell_node.custom_minimum_size = Vector2(cell_width, cell_height)
		add_child(grid_cell_node.duplicate())
		
func _remove_grid():
	for node in get_children():
		node.queue_free()
	
