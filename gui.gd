extends CanvasLayer

# Refrences
@onready var actor_info: PanelContainer = $Margin/ActorInfo

func set_highlighted_actor(actor: Actor) -> void:
	
	# Stop showing info is player clicks on other than actor
	if not actor:
		actor_info.hide()
		return
		
	# Display some info (TODO: ADD MORE)
	var info_vbox: VBoxContainer = actor_info.get_child(0)	# First child
	actor_info.show()
	info_vbox.get_child(0).text = actor.stats.character_name + " the " + actor.stats.battle_class_type
	info_vbox.get_child(1).text = str(actor.stats.curr_health) + "/" + str(actor.stats.max_health)
