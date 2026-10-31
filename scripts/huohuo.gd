class_name Huohuo
extends Player

# Healer. Skill heals 3 allies (the 3 lowest HP%). Ult heals everyone + gives energy.

var skill_heal_count := 3
const SKILL_HEAL := 2.5     # x ATK
const ULT_HEAL := 3.0       # x ATK
const ULT_ENERGY := 30


func _init() -> void:
	super()
	unit_name = "Huohuo"
	max_hp = 140
	atk = 15
	speed = 110


func get_target_type(action: Action) -> Target:
	match action:
		Action.SKILL, Action.ULT: return Target.ALL_ALLIES
		_: return Target.ENEMY


# [A] Basic: default (100% ATK, single target)


# [S] Skill: heal the 3 lowest-HP% allies
func skill(targets: Array, _battle: Node) -> void:
	var pool: Array = targets.duplicate()
	pool.sort_custom(func(a, b): return float(a.hp) / a.max_hp < float(b.hp) / b.max_hp)
	for i in mini(skill_heal_count, pool.size()):
		pool[i].heal(int(atk * SKILL_HEAL))


# [R] Ultimate: heal ALL allies + give them energy
func ult(targets: Array, _battle: Node) -> void:
	for t in targets:
		t.heal(int(atk * ULT_HEAL))
		t.gain_energy(ULT_ENERGY)
		print("%s gains %d energy (%d/%d)" % [t.unit_name, ULT_ENERGY, t.energy, t.max_energy])
