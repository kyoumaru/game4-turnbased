class_name Sparkle
extends Player

# Support. Skill: crit dmg buff + 50% advance on one ally.
# Ult: team crit dmg buff, gives skill points, 24% advance for everyone.

# ---- Tuning (edit these to rebalance) ----
const SKILL_CDMG := 0.30        # +30% crit dmg
const SKILL_BUFF_TURNS := 2
const SKILL_ADVANCE := 0.5      # 50% action advance

const ULT_CDMG := 0.20          # +20% crit dmg to the whole team
const ULT_BUFF_TURNS := 2
const ULT_SP := 2               # skill points gained (nerfed)
const ULT_ADVANCE := 0.24       # 24% action advance for everyone


func _init() -> void:
	super()
	unit_name = "Sparkle"
	max_hp = 110
	atk = 18
	speed = 120   # fastest
	start_energy_bonus = 20   # +20 energy at the start of battle


func get_target_type(action: Action) -> Target:
	match action:
		Action.SKILL: return Target.OTHER_ALLY   # another ally, not herself
		Action.ULT: return Target.ALL_ALLIES
		_: return Target.ENEMY


# [S] Skill: crit dmg buff + 50% advance on 1 ally
func skill(targets: Array, battle: Node) -> void:
	var ally: Unit = targets[0]
	ally.add_buff("crit_dmg", SKILL_CDMG, SKILL_BUFF_TURNS)
	battle.advance_action(ally, SKILL_ADVANCE)


# [R] Ultimate: SP + team crit dmg + 24% advance for everyone
func ult(targets: Array, battle: Node) -> void:
	battle.gain_sp(ULT_SP)
	for t in targets:
		# Buffs tick at the end of the owner's turn. Sparkle is mid-turn right now,
		# so she gets +1 turn so she's buffed as long as everyone else.
		var turns := ULT_BUFF_TURNS + (1 if t == self else 0)
		t.add_buff("crit_dmg", ULT_CDMG, turns)
	for t in targets:
		battle.advance_action(t, ULT_ADVANCE)
