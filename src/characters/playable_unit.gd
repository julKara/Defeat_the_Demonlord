@tool	# Makes script execute in the editor

class_name playable_unit extends Actor

# Playable elements...

const FRIENDLY_COLOR: Color = Color("00a78f")
const ENEMY_COLOR: Color = Color.CRIMSON

# Sets color based on bool (friendly/enemy) - may change to like healthbar or something else than collisionshape
@export var is_friendly: bool = false :
	set(value):
		is_friendly = value
		$CollisionShape2D.self_modulate = FRIENDLY_COLOR if is_friendly else ENEMY_COLOR
