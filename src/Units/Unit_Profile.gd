"""
This class stores everything unique for each unit (except for stats
 that is stored in instances ofCharacterStats.gb), such as:
	* Sprite
	* Skills 
	* Talents
And more...
It later gets used and intialized in actor.gb 
"""
class_name UnitProfile extends Resource

# Aspects of a character/unit
@export var character_name : String = "John"
@export var battle_class_type : String = "Class"
@export var sprite: Texture2D
@export var animation: AnimationLibrary

# TODO:
# @export var skills: Array[Resource] = []    # Each skill can be its own Resource later
# @export var talent: Resource                # Example: a Talent resource (passive ability)
