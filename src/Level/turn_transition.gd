extends Control

@onready var label: Label = $Label
var tween: Tween = null

func _ready() -> void:
	label.visible = false
	hide()

# Animate text label: slide in from left, stay, slide out to right (is awaitable)
func play_transition(text: String, color: Color = Color.WHITE, stay_time: float = 1.5) -> void:
	
	# Prepare label text & show
	label.text = text
	label.visible = true
	show()

	# Ensure the font has an outline size > 0 in the inspector (Label -> Theme Overrides -> Font -> Outline Size)
	# Apply the outline color override on the label (this affects this instance only)
	label.add_theme_color_override("font_outline_color", color)

	# Let the UI update once so get_used_rect() returns accurate size
	#await get_tree().process_frame
	
	# Get the viewport size
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size

	# Ensure the label has a sensible size to use for off-screen positioning
	var label_min_size: Vector2 = label.get_minimum_size()
	var label_w: float = max(label_min_size.x, 10.0)  # safety fallback
	var label_h: float = max(label_min_size.y, 10.0)

	# Place label off-screen left, vertically centered in the viewport
	label.position = Vector2(-label_w, viewport_size.y * 0.5 - label_h * 0.5)

	# Kill previous tween if any
	if tween:
		tween.kill()

	# Create tween sequence: in -> wait -> out
	tween = create_tween()
	tween.tween_property(label, "position:x", viewport_size.x * 0.5 - label_w * 0.5, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(stay_time)
	tween.tween_property(label, "position:x", viewport_size.x + label_w, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# Wait for tween to finish before hiding
	await tween.finished

	print("Wooo")
	
	label.visible = false
	hide()
