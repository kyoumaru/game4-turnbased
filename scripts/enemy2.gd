class_name Enemy2
extends Enemy

# Single-target enemy: hits one random player for big damage

func _init() -> void:
	unit_name = "Enemy2"
	max_hp = 130
	atk = 20
	speed = 105
	attacks = [atk_1, atk_2]


# ATK 1: 100% to one random target
func atk_1(battle: Node) -> void:
	hit_random(battle, 1.0, "ATK 1")


# ATK 2: 160% to one random target
func atk_2(battle: Node) -> void:
	hit_random(battle, 1.6, "ATK 2")
