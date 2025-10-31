extends Node2D

@onready var camera: Camera2D = $Camera
@onready var tile_map: TileMap = $"../TileMap"

@export var pan_speed := 1.0
@export var camera_smoothness := 8.0
@export var zoom_levels := [0.5, 0.75, 1.0]
var zoom_index := 1

var target_position: Vector2
var dragging := false
var last_mouse_pos := Vector2.ZERO
var active := true

func _ready() -> void:
	camera.make_current()
	target_position = global_position
	_set_zoom_level(0)

func _process(delta: float) -> void:
	if not active:
		return

	var new_pos = global_position.lerp(target_position, clamp(delta * camera_smoothness, 0.0, 1.0))
	# Snap to nearest pixel after zoom
	var snap_scale = camera.zoom.x
	new_pos = (new_pos / snap_scale).round() * snap_scale
	global_position = new_pos

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return

	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed: _set_zoom_level(-1)
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed: _set_zoom_level(1)
			MOUSE_BUTTON_LEFT:
				dragging = event.pressed
				last_mouse_pos = event.position

	# Move opposite the mouse drag, scaled by zoom
	elif event is InputEventMouseMotion and dragging:
		var delta_screen: Vector2 = event.position - last_mouse_pos
		target_position -= delta_screen * camera.zoom.x * pan_speed
		last_mouse_pos = event.position
		_clamp_camera_inside_map()

# --- Zoom ---
func _set_zoom_level(delta_idx: int) -> void:
	
	# Clamp new index
	zoom_index = clamp(zoom_index + delta_idx, 0, zoom_levels.size() - 1)
	var new_z : float = zoom_levels[zoom_index]

	# Screen point to focus on (mouse), use viewport canvas transform to convert to world.
	var mouse_screen : Vector2 = get_viewport().get_mouse_position()
	var canvas_inv := get_viewport().get_canvas_transform().affine_inverse()
	# world position under mouse before zoom
	var mouse_world_before : Vector2 = canvas_inv * mouse_screen

	# Temp set camera to new zoom to compute where the mouse would point AFTER zoom.
	var old_zoom_vec := camera.zoom
	camera.zoom = Vector2.ONE * new_z
	var mouse_world_after : Vector2 = canvas_inv * mouse_screen
	# Restore previous zoom so can tween it smoothly
	camera.zoom = old_zoom_vec

	# Adjust camera target so the zoom will feel centered on mouse position
	target_position += (mouse_world_before - mouse_world_after)

	# Clamp immediately to keep target valid, then animate the zoom
	_clamp_camera_inside_map()

	# Smoothly tween camera.zoom to the new value
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "zoom", Vector2.ONE * new_z, 0.18)

	# When tween finishes, re-clamp to ensure view inside bounds
	tween.connect("finished", Callable(self, "_clamp_camera_inside_map"))


# --- Center / Focus ---
func focus_on_unit(actor: Node2D, smooth := true) -> void:
	if actor == null: return
	if not smooth:
		target_position = actor.global_position
		global_position = actor.global_position
	else:
		# start from current target instead of origin
		var start := target_position
		var end := actor.global_position
		# run a tween for smooth centering
		var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tween.tween_property(self, "target_position", end, 0.6).from(start)

# --- Map bounds clamp ---
func _clamp_camera_inside_map() -> void:
	if tile_map == null:
		return

	var map_rect := tile_map.get_used_rect()
	var cell_size := tile_map.tile_set.tile_size
	var world_rect := Rect2(map_rect.position * cell_size, map_rect.size * cell_size)

	# viewport rect in world units
	var vp_size := get_viewport().get_visible_rect().size * camera.zoom
	var half_vp := vp_size * 0.5

	var min_x := world_rect.position.x + half_vp.x
	var max_x := world_rect.end.x - half_vp.x
	var min_y := world_rect.position.y + half_vp.y
	var max_y := world_rect.end.y - half_vp.y

	var clamped := target_position
	clamped.x = clamp(clamped.x, min_x, max_x)
	clamped.y = clamp(clamped.y, min_y, max_y)
	target_position = clamped
