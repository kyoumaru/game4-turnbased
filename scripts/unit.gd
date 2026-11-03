class_name Unit
extends Node2D

# --- Visual Node References ---
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D # Change path if your sprite node is nested differently
@onready var health_bar: ProgressBar = $HealthBar
@onready var name_label: Label = $NameLabel
@onready var toughness_bar: ProgressBar = $ToughnessBar
@onready var weakness_label: Label = $WeaknessLabel


signal died(unit: Unit, killer: Unit)
signal weakness_broken(unit: Unit, breaker: Unit)

enum Action { BASIC, SKILL, ULT }
enum Target { ENEMY, ALLY, OTHER_ALLY, SELF, ALL_ENEMIES, ALL_ALLIES }
enum Element { PHYSICAL, FIRE, ICE, LIGHTNING, WIND, QUANTUM, IMAGINARY }

const BASIC_TOUGHNESS_DAMAGE := 30
# Based on HSR's broken dmg multiplier
const BROKEN_DAMAGE_MULTIPLIER := 1.0 / 0.9

var unit_name := "Unit"
var max_hp := 100
var hp := 100:
	set(value):
		hp = clampi(value, 0, max_hp)
		if health_bar:
			health_bar.value = hp
var atk := 20
var speed := 100
var is_player := true
var av := 0.0

# Only enemies have toughness in this implementation; playable chars keep default 0.
var element := Element.PHYSICAL
var weaknesses: Array[Element] = []
var max_toughness := 0
var toughness := 0:
	set(value):
		toughness = clampi(value, 0, max_toughness)
		_update_toughness_display()
var break_charge_value := 1   # Himeko gains 3 for a boss, 1 for a small enemy.

# ---------- Crit (base values, change per character in its _init) ----------
var crit_rate := 0.5   # 50% chance
var crit_dmg := 0.5    # +50% damage on crit (= 1.5x)

# ---------- Skill points (the pool itself lives in battle_manager) ----------
var sp_on_basic := 1   # SP gained when this unit uses a basic attack
var skill_cost := 1    # SP spent when this unit uses its skill

# ---------- Energy (set max_energy = 0 for units that don't use it) ----------
var max_energy := 0
var energy := 0
var energy_on_basic := 20
var energy_on_skill := 30
var energy_on_hit := 10   # gained when this unit takes damage
var start_energy_pct := 0.5   # starts the battle with 50% of max energy
var start_energy_bonus := 0   # extra flat energy at battle start (e.g. Sparkle +20)

# ---------- Buffs ----------
# Each buff: {"stat": String, "amount": float, "turns": int}
# Supported stats right now: "crit_rate", "crit_dmg"
# Buffs tick down at the END of this unit's own turn.
var buffs: Array = []


func _ready() -> void:
	hp = max_hp
	energy = 0
	reset_av()
	toughness = max_toughness
	
	if name_label:
		name_label.text = unit_name
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = hp
		
	play_anim("idle")


# ---------- Core stats / AV ----------
func base_av() -> float:
	return 10000.0 / speed


func reset_av() -> void:
	av = base_av()


func is_alive() -> bool:
	return hp > 0

# ---------- Weakness Break ----------
func is_weakness_broken() -> bool:
	return max_toughness > 0 and toughness == 0


func element_name() -> String:
	return Element.keys()[element].capitalize()


func weakness_names() -> String:
	var names := PackedStringArray()
	for weakness in weaknesses:
		names.append(Element.keys()[weakness].capitalize())
	return " / ".join(names)


func _update_toughness_display() -> void:
	var show_toughness := not is_player and max_toughness > 0
	if toughness_bar:
		toughness_bar.visible = show_toughness
		toughness_bar.max_value = max_toughness
		toughness_bar.value = toughness
	if weakness_label:
		weakness_label.visible = show_toughness
		var status := "BREAK" if is_weakness_broken() else "%d/%d toughness" % [toughness, max_toughness]
		weakness_label.text = "Weak: %s\n%s" % [weakness_names(), status]
		weakness_label.modulate = Color.GOLD if is_weakness_broken() else Color.WHITE


# Called by deal_damage while the target is alive. Report the transition only;
# the break signal is emitted after that hit's HP damage has also resolved.
func _reduce_toughness(amount: int, source: Unit) -> bool:
	if is_player or max_toughness <= 0 or is_weakness_broken() or amount <= 0:
		return false
	if not is_alive() or not source.is_player or not weaknesses.has(source.element):
		return false
	toughness -= amount
	return is_weakness_broken()


func recover_toughness() -> void:
	if not is_alive() or not is_weakness_broken():
		return
	toughness = max_toughness
	print("%s recovers toughness (%d/%d)" % [unit_name, toughness, max_toughness])


# ---------- Visual Animation Helper ----------
func play_anim(anim_name: String) -> void:
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
		
		# Auto-return to idle after non-looping actions finish
		if anim_name in ["attack", "skill", "hit"]:
			await sprite.animation_finished
			if hp > 0:
				play_anim("idle")

func take_damage(amount: int, source: Unit = null) -> void:
	play_anim("hit")
	hp = maxi(hp - amount, 0)
	print("%s takes %d damage (%d/%d)" % [unit_name, amount, hp, max_hp])
	if hp == 0:
		died.emit(self, source)
	else:
		gain_energy(energy_on_hit)


func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp)
	print("%s heals %d (%d/%d)" % [unit_name, amount, hp, max_hp])


# ---------- Crit + damage ----------
func get_crit_rate() -> float:
	return clampf(crit_rate + buff_total("crit_rate"), 0.0, 1.0)


func get_crit_dmg() -> float:
	return crit_dmg + buff_total("crit_dmg")


# Deals (ATK x multiplier) damage to one target, rolling a crit.
# Returns false if the target was already dead (so nothing happened).
func deal_damage(target: Unit, multiplier: float, toughness_damage := 0) -> bool:
	if not target.is_alive():
		return false
	var dmg := float(atk) * multiplier
	if randf() < get_crit_rate():
		dmg *= 1.0 + get_crit_dmg()
		print("CRIT! (x%.2f)" % (1.0 + get_crit_dmg()))
	# The breaking hit itself deals normal damage
	# Toughness reduced to 0 only after the breaking hit
	# Only following hits receive the broken-state bonus
	if target.is_weakness_broken():
		dmg *= BROKEN_DAMAGE_MULTIPLIER
	var broke := target._reduce_toughness(toughness_damage, self)
	target.take_damage(int(dmg), self)
	if broke:
		target.weakness_broken.emit(target, self)
	return true


# Hits every unit in `targets`. Returns how many were actually hit.
func deal_damage_to(targets: Array, multiplier: float, toughness_damage := 0) -> int:
	var hits := 0
	for t in targets:
		if deal_damage(t, multiplier, toughness_damage):
			hits += 1
	return hits


# ---------- Buffs ----------
func add_buff(stat: String, amount: float, turns: int) -> void:
	buffs.append({"stat": stat, "amount": amount, "turns": turns})
	print("%s gains %s +%d%% for %d turn(s)" % [unit_name, stat, int(amount * 100), turns])


func buff_total(stat: String) -> float:
	var total := 0.0
	for b in buffs:
		if b["stat"] == stat:
			total += b["amount"]
	return total


# Called by the battle manager at the end of this unit's turn
func tick_buffs() -> void:
	for i in range(buffs.size() - 1, -1, -1):
		buffs[i]["turns"] -= 1
		if buffs[i]["turns"] <= 0:
			print("%s's %s buff wore off" % [unit_name, buffs[i]["stat"]])
			buffs.remove_at(i)


# ---------- Energy ----------
func gain_energy(amount: int) -> void:
	if max_energy <= 0:
		return
	energy = mini(energy + amount, max_energy)


func can_use(action: Action) -> bool:
	if action == Action.ULT:
		return max_energy > 0 and energy >= max_energy
	return true


# ---------- Override these in character scripts ----------
# Every action receives an ARRAY of targets:
#   single target -> targets[0]
#   AOE / all allies -> loop over targets

# What each action targets (battle manager uses this for target selection)
func get_target_type(_action: Action) -> Target:
	return Target.ENEMY


# Default basic attack: 100% ATK to one target
func basic_attack(targets: Array, _battle: Node) -> void:
	play_anim("attack")
	deal_damage(targets[0], 1.0, BASIC_TOUGHNESS_DAMAGE)


func skill(_targets: Array, _battle: Node) -> void:
	pass


func ult(_targets: Array, _battle: Node) -> void:
	pass


# Passive hook: called when this unit kills something
func on_kill(_victim: Unit, _battle: Node) -> void:
	pass

# This does nothing; may be overidden by a specific character
func on_enemy_broken(_enemy: Unit, _battle: Node) -> void:
	pass

# This does nothing; may be overidden by a specific character
func resolve_follow_up(_battle: Node) -> void:
	pass


# Enemies override this
func take_turn(_battle: Node) -> void:
	pass


# Used by battle manager. Handles energy spend/gain for you.
# (Skill points are handled by the battle manager.)
func perform(action: Action, targets: Array, battle: Node) -> void:
	match action:
		Action.BASIC:
			print("%s uses Basic Attack" % unit_name)
			basic_attack(targets, battle)
			gain_energy(energy_on_basic)
		Action.SKILL:
			print("%s uses Skill" % unit_name)
			skill(targets, battle)
			gain_energy(energy_on_skill)
		Action.ULT:
			print("%s uses ULTIMATE!" % unit_name)
			energy = 0
			ult(targets, battle)
