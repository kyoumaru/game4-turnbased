class_name Himeko
extends Player

# Basic = single target. Skill and Ult = AOE.
# Charges: she gains 1 charge per enemy her attacks hit (this will become
# "per enemy broken" once break exists). At 3 charges she does a follow-up.

const CHARGES_NEEDED := 3
const FOLLOW_UP_MULT := 1.2
const SKILL_TOUGHNESS_DAMAGE := 60
const ULT_TOUGHNESS_DAMAGE := 60
const FOLLOW_UP_TOUGHNESS_DAMAGE := 30

var charges := 0


func _init() -> void:
	super()
	unit_name = "Himeko"
	element = Element.FIRE
	max_hp = 130
	atk = 24
	speed = 100   # second slowest


func get_target_type(action: Action) -> Target:
	match action:
		Action.SKILL, Action.ULT: return Target.ALL_ENEMIES
		_: return Target.ENEMY


# [A] Basic: 100% ATK, single target
func basic_attack(targets: Array, _battle: Node) -> void:
	play_anim("attack")
	deal_damage_to(targets, 1.0, BASIC_TOUGHNESS_DAMAGE)


# [S] Skill: 120% ATK to all enemies
func skill(targets: Array, _battle: Node) -> void:
	play_anim("skill")
	deal_damage_to(targets, 1.2, SKILL_TOUGHNESS_DAMAGE)


# [R] Ultimate: 220% ATK to all enemies
func ult(targets: Array, _battle: Node) -> void:
	play_anim("ultimate")
	deal_damage_to(targets, 2.2, ULT_TOUGHNESS_DAMAGE)


func gain_charge(amount: int) -> void:
	if amount <= 0:
		return
	charges = mini(charges + amount, CHARGES_NEEDED)
	print("%s charges: %d/%d" % [unit_name, charges, CHARGES_NEEDED])


func resolve_follow_up(battle: Node) -> void:
	if not is_alive() or charges < CHARGES_NEEDED or battle.opponents_of(self).is_empty():
		return
	charges = 0
	follow_up(battle)


# Follow-up: 120% ATK to all enemies. Only a new break can generate more charges.
func follow_up(battle: Node) -> void:
	print("%s uses FOLLOW-UP!" % unit_name)
	deal_damage_to(battle.opponents_of(self), FOLLOW_UP_MULT, FOLLOW_UP_TOUGHNESS_DAMAGE)


func on_enemy_broken(enemy: Unit, _battle: Node) -> void:
	gain_charge(enemy.break_charge_value)
