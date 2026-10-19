class_name Unit
extends Node

signal died(unit: Unit, killer: Unit)

enum Action { BASIC, SKILL, ULT }
enum Target { ENEMY, ALLY, SELF }

var unit_name := "Unit"
var max_hp := 100
var hp := 100
var atk := 20
var speed := 100
var is_player := true
var av := 0.0

# Energy (set max_energy = 0 for units that don't use it, like enemies)
var max_energy := 0
var energy := 0
var energy_on_basic := 20
var energy_on_skill := 30
var energy_on_hit := 10   # gained when this unit takes damage


func _ready() -> void:
	hp = max_hp
	energy = 0
	reset_av()


# ---------- Core stats / AV ----------
func base_av() -> float:
	return 10000.0 / speed


func reset_av() -> void:
	av = base_av()


func is_alive() -> bool:
	return hp > 0


func take_damage(amount: int, source: Unit = null) -> void:
	hp = maxi(hp - amount, 0)
	print("%s takes %d damage (%d/%d)" % [unit_name, amount, hp, max_hp])
	if hp == 0:
		died.emit(self, source)
	else:
		gain_energy(energy_on_hit)


func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp)
	print("%s heals %d (%d/%d)" % [unit_name, amount, hp, max_hp])


# ---------- Energy ----------
func gain_energy(amount: int) -> void:
	if max_energy <= 0:
		return
	energy = mini(energy + amount, max_energy)


func can_use(action: Action) -> bool:
	if action == Action.ULT:
		return max_energy > 0 and energy >= max_energy
	return true


# ---------- Override these in Player / Enemy / character scripts ----------

# Who each action targets (battle manager uses this for target selection)
func get_target_type(_action: Action) -> Target:
	return Target.ENEMY


func basic_attack(target: Unit, _battle: Node) -> void:
	target.take_damage(atk, self)


func skill(_target: Unit, _battle: Node) -> void:
	pass


func ult(_target: Unit, _battle: Node) -> void:
	pass


# Passive hook: called when this unit kills something
func on_kill(_victim: Unit, _battle: Node) -> void:
	pass


# Enemies override this
func take_turn(_battle: Node) -> void:
	pass


# Used by battle manager. Handles energy spend/gain for you.
func perform(action: Action, target: Unit, battle: Node) -> void:
	match action:
		Action.BASIC:
			basic_attack(target, battle)
			gain_energy(energy_on_basic)
		Action.SKILL:
			skill(target, battle)
			gain_energy(energy_on_skill)
		Action.ULT:
			energy = 0
			ult(target, battle)
