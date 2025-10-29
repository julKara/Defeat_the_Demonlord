extends PanelContainer

func _ready() -> void:
	# Battle is hidden on start, doesn't apear until selecting a unit...
	hide()
	
func display_actor_info(actor: Actor) -> void:
		
	# Display some info (TODO: ADD MORE)
	var info_vbox: VBoxContainer = get_child(0)	# First child
	show()
	
	# Name
	info_vbox.get_child(0).text = actor.profile.character_name + " the " + actor.profile.battle_class_type
	# HP
	info_vbox.get_child(1).text = "HP: " + str(actor.stats.curr_health) + "/" + str(actor.stats.max_health)
	# Phys-Attack
	info_vbox.get_child(2).text = "P_attack: " + str(actor.stats.curr_phys_attack)
	
func hide_actor_info() -> void:
	hide()
