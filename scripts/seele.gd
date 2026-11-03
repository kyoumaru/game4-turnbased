class_name Seele
extends Player

# Damage dealer. Basic < Skill < Ult, all single target.
# Passive: killing an enemy gives her 100% action advance.

const SKILL_TOUGHNESS_DAMAGE := 60
const ULT_TOUGHNESS_DAMAGE := 90

func _init() -> void:
	super()
	unit_name = "Seele"
	element = Element.QUANTUM
	max_hp = 120
	atk = 25
	speed = 90
	crit_rate = 0.6   # change per character if you want
	crit_dmg = 0.5


func get_target_type(_action: Action) -> Target:
	return Target.ENEMY


# [A] Basic: uses the default (100% ATK) from unit.gd


# [S] Skill: 200% ATK
func skill(targets: Array, _battle: Node) -> void:
	play_anim("skill")
	deal_damage(targets[0], 2.0, SKILL_TOUGHNESS_DAMAGE)


# [R] Ultimate: 450% ATK
func ult(targets: Array, _battle: Node) -> void:
	play_anim("ultimate")
	deal_damage(targets[0], 4.5, ULT_TOUGHNESS_DAMAGE)


# Passive: 100% action advance on kill (she acts again right away)
func on_kill(_victim: Unit, battle: Node) -> void:
	print("%s's passive triggers!" % unit_name)
	battle.advance_action(self, 1.0)
