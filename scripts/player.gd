class_name Player
extends Unit

# Base class for all playable characters.
# Character scripts extend this and set their own stats + actions.

func _init() -> void:
	is_player = true
	max_energy = 100
	energy_on_basic = 20
	energy_on_skill = 30
	energy_on_hit = 10
