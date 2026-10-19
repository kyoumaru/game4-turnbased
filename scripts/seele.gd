class_name Seele
extends Player

# Player 1 (SEELE): pure damage dealer (single target)

func _init() -> void:
	unit_name = "Seele"
	max_hp = 120
	atk = 25
	speed = 110


func get_target_type(_action: Action) -> Target:
	return Target.ENEMY   # basic, skill and ult all hit one enemy


# [A] Basic: 100% ATK
func basic_attack(targets: Array, _battle: Node) -> void:
	print("%s uses Basic Attack" % unit_name)
	targets[0].take_damage(atk, self)


# [S] Skill: 180% ATK
func skill(targets: Array, _battle: Node) -> void:
	print("%s uses Skill" % unit_name)
	targets[0].take_damage(int(atk * 1.8), self)


# [R] Ultimate: 350% ATK
func ult(targets: Array, _battle: Node) -> void:
	print("%s uses ULTIMATE!" % unit_name)
	targets[0].take_damage(int(atk * 3.5), self)
