extends Node

signal action_done

enum State { BUSY, CHOOSING_ACTION, CHOOSING_TARGET }

const MAX_SP := 7
const START_SP := 3

# Keybinds -> actions
var key_map := {
	KEY_A: Unit.Action.BASIC,
	KEY_S: Unit.Action.SKILL,
	KEY_R: Unit.Action.ULT,
}

var players: Array[Unit] = []
var enemies: Array[Unit] = []
var sp := START_SP   # shared skill points
var state := State.BUSY
var current_actor: Unit
var pending_action: Unit.Action
var pending_targets: Array[Unit] = []


func _ready() -> void:
	players = [
		_add(Seele.new()),
		_add(Sparkle.new()),
		_add(Himeko.new()),
		_add(Huohuo.new()),
	]
	enemies = [
		_add(EnemySmall.new()),
		_add(EnemySmall.new()),
		_add(EnemyBoss.new()),
	]
	# Enemies have no names for now, just numbers
	for i in enemies.size():
		enemies[i].unit_name = "Enemy%d" % (i + 1)
	run_battle()


func _add(u: Unit) -> Unit:
	u.died.connect(_on_unit_died)
	add_child(u)
	return u


# ---------- Skill points (call these from anywhere) ----------
func gain_sp(amount: int) -> void:
	sp = mini(sp + amount, MAX_SP)
	print("SP +%d (%d/%d)" % [amount, sp, MAX_SP])


func spend_sp(amount: int) -> void:
	sp = maxi(sp - amount, 0)
	print("SP -%d (%d/%d)" % [amount, sp, MAX_SP])


# ---------- Action advance / delay (call these from anywhere) ----------
# percent: 0.3 = 30%, 1.0 = 100% (acts next)
func advance_action(unit: Unit, percent: float) -> void:
	unit.av = maxf(unit.av - unit.base_av() * percent, 0.0)
	print("%s advanced %d%%" % [unit.unit_name, int(percent * 100)])


func delay_action(unit: Unit, percent: float) -> void:
	unit.av += unit.base_av() * percent


# ---------- Helpers ----------
func _alive(list: Array[Unit]) -> Array[Unit]:
	var out: Array[Unit] = []
	for u in list:
		if u.is_alive():
			out.append(u)
	return out


func allies_of(u: Unit) -> Array[Unit]:
	return _alive(players if u.is_player else enemies)


func opponents_of(u: Unit) -> Array[Unit]:
	return _alive(enemies if u.is_player else players)


func random_targets(actor: Unit, count: int) -> Array:
	var pool: Array = opponents_of(actor)
	pool.shuffle()
	return pool.slice(0, mini(count, pool.size()))


func _names(list: Array) -> String:
	var out := PackedStringArray()
	for u in list:
		out.append(u.unit_name)
	return ", ".join(out)


func _on_unit_died(victim: Unit, killer: Unit) -> void:
	print("*** %s is defeated ***" % victim.unit_name)
	if killer != null:
		killer.on_kill(victim, self)


func _print_status() -> void:
	print("-- Party --   SP %d/%d" % [sp, MAX_SP])
	for u in _alive(players):
		print("  %s  HP %d/%d  Energy %d/%d  CR %d%% CD %d%%" % [
			u.unit_name, u.hp, u.max_hp, u.energy, u.max_energy,
			int(u.get_crit_rate() * 100), int(u.get_crit_dmg() * 100)])
	print("-- Enemies --")
	for u in _alive(enemies):
		print("  %s  HP %d/%d" % [u.unit_name, u.hp, u.max_hp])


# ---------- Main loop ----------
func run_battle() -> void:
	while true:
		if _alive(players).is_empty():
			print("DEFEAT")
			return
		if _alive(enemies).is_empty():
			print("VICTORY")
			return

		var all := _alive(players) + _alive(enemies)
		all.sort_custom(func(a: Unit, b: Unit): return a.av < b.av)
		var actor: Unit = all[0]

		var elapsed := actor.av
		for u in all:
			u.av -= elapsed
		actor.reset_av()

		current_actor = actor
		print("\n=== %s's turn === (next: %s)" % [actor.unit_name, ", ".join(preview_order(6))])
		if actor.is_player:
			await player_turn(actor)
		else:
			actor.take_turn(self)
		actor.tick_buffs()
		await get_tree().create_timer(0.6).timeout


# Simulated turn order (use for a turn-order bar later)
func preview_order(count := 6) -> Array[String]:
	var sim := {}
	for u in _alive(players) + _alive(enemies):
		sim[u] = u.av
	var out: Array[String] = []
	for i in count:
		var first: Unit = null
		for u in sim:
			if first == null or sim[u] < sim[first]:
				first = u
		var t: float = sim[first]
		for u in sim:
			sim[u] -= t
		sim[first] = first.base_av()
		out.append(first.unit_name)
	return out


# ---------- Player input ----------
func player_turn(actor: Unit) -> void:
	_print_status()
	var skill_txt := "[S] Skill (-%d SP)%s" % [actor.skill_cost, "" if sp >= actor.skill_cost else " (no SP)"]
	var ult_txt := "[R] Ultimate%s" % ("" if actor.can_use(Unit.Action.ULT) else " (not ready)")
	print("[A] Basic (+%d SP)  %s  %s" % [actor.sp_on_basic, skill_txt, ult_txt])
	state = State.CHOOSING_ACTION
	await action_done
	state = State.BUSY


func _valid_targets(actor: Unit, action: Unit.Action) -> Array[Unit]:
	match actor.get_target_type(action):
		Unit.Target.ENEMY, Unit.Target.ALL_ENEMIES:
			return opponents_of(actor)
		Unit.Target.ALLY, Unit.Target.ALL_ALLIES:
			return allies_of(actor)
		Unit.Target.OTHER_ALLY:
			var out: Array[Unit] = []
			for u in allies_of(actor):
				if u != actor:
					out.append(u)
			return out
		_:
			return [actor] as Array[Unit]


func _is_multi_target(actor: Unit, action: Unit.Action) -> bool:
	var t := actor.get_target_type(action)
	return t == Unit.Target.ALL_ENEMIES or t == Unit.Target.ALL_ALLIES


func _select_action(action: Unit.Action) -> void:
	if action == Unit.Action.SKILL and sp < current_actor.skill_cost:
		print("Not enough skill points! (%d/%d)" % [sp, MAX_SP])
		return
	if not current_actor.can_use(action):
		print("Not enough energy! (%d/%d)" % [current_actor.energy, current_actor.max_energy])
		return
	var targets := _valid_targets(current_actor, action)
	if targets.is_empty():
		print("No valid targets!")
		return
	# AOE / all-allies, or only one choice: no target selection needed
	if _is_multi_target(current_actor, action) or targets.size() == 1:
		_execute(action, targets)
		return
	pending_action = action
	pending_targets = targets
	state = State.CHOOSING_TARGET
	print("Choose target:")
	for i in targets.size():
		print("  %d) %s (%d HP)" % [i + 1, targets[i].unit_name, targets[i].hp])


func _execute(action: Unit.Action, targets: Array) -> void:
	state = State.BUSY
	print("%s -> %s" % [current_actor.unit_name, _names(targets)])
	match action:
		Unit.Action.BASIC: gain_sp(current_actor.sp_on_basic)
		Unit.Action.SKILL: spend_sp(current_actor.skill_cost)
	current_actor.perform(action, targets, self)
	action_done.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match state:
		State.CHOOSING_ACTION:
			if key_map.has(event.keycode):
				_select_action(key_map[event.keycode])
		State.CHOOSING_TARGET:
			var idx: int = event.keycode - KEY_1
			if idx >= 0 and idx < pending_targets.size():
				_execute(pending_action, [pending_targets[idx]])
