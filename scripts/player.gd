class_name Player
extends Unit

# Test character. Copy this file for each new character and edit the stats,
# the three actions, and the passive.

func _init() -> void:
	unit_name = "Hero"
	max_hp = 120
	atk = 25
	speed = 110
	is_player = true
	max_energy = 100
	energy_on_basic = 20
	energy_on_skill = 30
	energy_on_hit = 10


func get_target_type(action: Action) -> Target:
	match action:
		Action.SKILL: return Target.ALLY   # heal
		_: return Target.ENEMY


# [A] Basic attack: 100% ATK
func basic_attack(target: Unit, _battle: Node) -> void:
	print("%s uses Basic Attack" % unit_name)
	target.take_damage(atk, self)


# [S] Skill: heal an ally for 80% ATK
func skill(target: Unit, _battle: Node) -> void:
	print("%s uses Skill" % unit_name)
	target.heal(int(atk * 0.8))


# [R] Ultimate: 300% ATK (needs full energy)
func ult(target: Unit, _battle: Node) -> void:
	print("%s uses ULTIMATE!" % unit_name)
	target.take_damage(int(atk * 3.0), self)


# Passive: advance self 50% on kill
func on_kill(_victim: Unit, battle: Node) -> void:
	print("%s's passive triggers!" % unit_name)
	battle.advance_action(self, 0.5)


# --- action advance shi i cooked up ---
# func skill(target: Unit, battle: Node) -> void:
#     battle.advance_action(target, 1.0)   # 100% = acts next
