class_name Huohuo
extends Player

# Player 2 (HUOHUO): support healer

func _init() -> void:
	unit_name = "Huohuo"
	max_hp = 100
	atk = 20
	speed = 100


func get_target_type(action: Action) -> Target:
	match action:
		Action.SKILL, Action.ULT: return Target.ALL_ALLIES
		_: return Target.ENEMY


# [A] Basic: weak attack, 80% ATK
func basic_attack(targets: Array, _battle: Node) -> void:
	print("%s uses Basic Attack" % unit_name)
	targets[0].take_damage(int(atk * 0.8), self)


# [S] Skill: heal ALL allies for 150% ATK
func skill(targets: Array, _battle: Node) -> void:
	print("%s uses Skill: Group Heal" % unit_name)
	for t in targets:
		t.heal(int(atk * 1.5))


# [R] Ultimate: heal ALL allies for 250% ATK and give them 40 energy
func ult(targets: Array, _battle: Node) -> void:
	print("%s uses ULTIMATE: Overheal!" % unit_name)
	for t in targets:
		t.heal(int(atk * 2.5))
		t.gain_energy(40)
		print("%s gains 40 energy (%d/%d)" % [t.unit_name, t.energy, t.max_energy])
