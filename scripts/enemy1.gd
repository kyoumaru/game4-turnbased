class_name Enemy1
extends Enemy

# AOE enemy: always hits the whole party, but for lower damage

func _init() -> void:
	unit_name = "Enemy1"
	max_hp = 100
	atk = 14
	speed = 90
	attacks = [atk_1, atk_2]


# ATK 1: 70% to everyone
func atk_1(battle: Node) -> void:
	hit_all(battle, 0.7, "ATK 1")


# ATK 2: 100% to everyone
func atk_2(battle: Node) -> void:
	hit_all(battle, 1.0, "ATK 2")
