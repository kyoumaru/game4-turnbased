class_name Himeko
extends Player

# Basic = single target. Skill and Ult = AOE.
# Charges: she gains 1 charge per enemy her attacks hit (this will become
# "per enemy broken" once break exists). At 3 charges she does a follow-up.

const CHARGES_NEEDED := 3
const FOLLOW_UP_MULT := 1.2

var charges := 0


func _init() -> void:
	super()
	unit_name = "Himeko"
	max_hp = 130
	atk = 24
	speed = 100   # second slowest


func get_target_type(action: Action) -> Target:
	match action:
		Action.SKILL, Action.ULT: return Target.ALL_ENEMIES
		_: return Target.ENEMY


# [A] Basic: 100% ATK, single target
func basic_attack(targets: Array, battle: Node) -> void:
	var hits := deal_damage_to(targets, 1.0)
	gain_charge(hits, battle)


# [S] Skill: 120% ATK to all enemies
func skill(targets: Array, battle: Node) -> void:
	var hits := deal_damage_to(targets, 1.2)
	gain_charge(hits, battle)


# [R] Ultimate: 220% ATK to all enemies
func ult(targets: Array, battle: Node) -> void:
	var hits := deal_damage_to(targets, 2.2)
	gain_charge(hits, battle)


func gain_charge(amount: int, battle: Node) -> void:
	if amount <= 0:
		return
	charges += amount
	print("%s charges: %d/%d" % [unit_name, mini(charges, CHARGES_NEEDED), CHARGES_NEEDED])
	while charges >= CHARGES_NEEDED and not battle.opponents_of(self).is_empty():
		charges -= CHARGES_NEEDED
		follow_up(battle)


# Follow-up: 120% ATK to all enemies (does NOT give charges, so it can't chain itself)
func follow_up(battle: Node) -> void:
	print("%s uses FOLLOW-UP!" % unit_name)
	deal_damage_to(battle.opponents_of(self), FOLLOW_UP_MULT)


# When break is coded, call this from the battle manager when Himeko breaks
# an enemy, and remove the gain_charge(hits) calls above.
func on_enemy_broken(_enemy: Unit, battle: Node) -> void:
	gain_charge(1, battle)
