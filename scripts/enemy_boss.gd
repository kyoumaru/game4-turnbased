class_name EnemyBoss
extends Enemy

# Big enemy: alternates between ATK 1 (one ally) and ATK 2 (3 allies).

var turn_count := 0


func _init() -> void:
	super()
	unit_name = "Boss"
	max_hp = 600
	atk = 18
	speed = 115


func take_turn(battle: Node) -> void:
	if turn_count % 2 == 0:
		atk_1(battle)
	else:
		atk_2(battle)
	turn_count += 1


# ATK 1: 150% to 1 random ally
func atk_1(battle: Node) -> void:
	hit_random(battle, 1.5, "ATK 1 (single)")


# ATK 2: 90% to 3 random allies
func atk_2(battle: Node) -> void:
	hit_random(battle, 0.9, "ATK 2 (hits 3)", 3)
