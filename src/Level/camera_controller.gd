# CameraController.gd
# Attach to CameraController (Node or Node2D) with a Camera2D child named "Camera2D".
extends Node

@onready var tile_map: TileMap = $"../TileMap"
@onready var camera: Camera2D = $Camera2D


# CONFIG
@export var zoom_step := 0.1           # how much zoom changes per wheel tick
@export var min_zoom := 0.5
@export var max_zoom := 2.5
@export var pan_speed := 1.0           # drag speed multiplier
@export var camera_smoothness := 8.0   # lerp speed when centering

# STATE
var dragging := false
var last_mouse_pos := Vector2.ZERO
var target_position := Vector2.ZERO
var active := true  # set false to freeze camera input

func _set_tilemap(node):
	tile_map = node

func _ready() -> void:
	# Make camera active/current for this viewport
	if camera:
		camera.make_current()
		target_position = camera.global_position
	_clamp_camera_inside_map()

func _process(delta: float) -> void:
	if not active:
		return
	# Smoothly move camera toward target position
	if camera:
		camera.global_position = camera.global_position.lerp(target_position, clamp(delta * camera_smoothness, 0.0, 1.0))
	_clamp_camera_inside_map()

func _unhandled_input(event: InputEvent) -> void:
	if not active or camera == null:
		return

	# Mouse wheel zoom
	if event is InputEventMouseButton:
		# Wheel up/down constants work in Godot 4 as button_index values
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_set_zoom(camera.zoom - Vector2.ONE * zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_set_zoom(camera.zoom + Vector2.ONE * zoom_step)

		# Start/stop drag with left mouse
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				last_mouse_pos = event.position
			else:
				dragging = false

	# Dragging movement
	elif event is InputEventMouseMotion and dragging:
		# Convert mouse delta to world space taking zoom into account
		var delta_pos = (event.position - last_mouse_pos) * (1.0 / camera.zoom.x) * -pan_speed
		target_position += delta_pos
		last_mouse_pos = event.position
		_clamp_camera_inside_map()

func _set_zoom(new_zoom: Vector2) -> void:
	if camera == null:
		return
	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
	camera.zoom = new_zoom
	_clamp_camera_inside_map()

# Center & optionally zoom on an actor (actor is Node2D)
func focus_on_unit(actor: Node2D, zoom_in := true, instant := false) -> void:
	if actor == null or camera == null:
		return
	target_position = actor.global_position
	if zoom_in:
		_set_zoom(Vector2.ONE * 0.8)
	else:
		_set_zoom(Vector2.ONE)
	if instant and camera:
		# jump instantly rather than lerp
		camera.global_position = target_position

# Helper: keep target_position inside map bounds
func _clamp_camera_inside_map() -> void:
	
	if tile_map == null or camera == null:
		return

	var map_rect = tile_map.get_used_rect()  # Rect2i in cell coords
	# Get tile size (works with Godot 4 TileMap API)
	var cell_size := Vector2i(48, 48)

	var world_rect = Rect2(map_rect.position * cell_size, map_rect.size * cell_size)

	# Get viewport size in pixels and convert to world size using camera.zoom
	var vp_rect: Rect2 = get_viewport().get_visible_rect()
	var viewport_size: Vector2 = vp_rect.size
	var half_screen_size = (viewport_size * camera.zoom) * 0.5

	var min_x = world_rect.position.x + half_screen_size.x
	var max_x = world_rect.position.x + world_rect.size.x - half_screen_size.x
	var min_y = world_rect.position.y + half_screen_size.y
	var max_y = world_rect.position.y + world_rect.size.y - half_screen_size.y

	var clamped = target_position

	# Map smaller than viewport checks => center map
	if min_x > max_x:
		clamped.x = world_rect.position.x + world_rect.size.x * 0.5
	else:
		clamped.x = clamp(clamped.x, min_x, max_x)

	if min_y > max_y:
		clamped.y = world_rect.position.y + world_rect.size.y * 0.5
	else:
		clamped.y = clamp(clamped.y, min_y, max_y)

	target_position = clamped
