class_name Enemy
extends Unit

# Base class for all enemies.
# Enemy scripts extend this, set their stats, and either fill the `attacks`
# list (random pick each turn) or override take_turn() for a fixed pattern.

var attacks: Array = [] # Callables, each takes (battle)


func _init() -> void:
	is_player = false
	crit_rate = 0.0   # enemies don't crit by default


func take_turn(battle: Node) -> void:
	if attacks.is_empty():
		return
	var attack: Callable = attacks.pick_random()
	attack.call(battle)


# Hits `count` random opponents (count = 1 -> single target)
func hit_random(battle: Node, multiplier: float, label: String, count := 1) -> void:
	print("%s uses %s" % [unit_name, label])
	for t in battle.random_targets(self, count):
		deal_damage(t, multiplier)


# Hits EVERY opponent (AOE)
func hit_all(battle: Node, multiplier: float, label: String) -> void:
	print("%s uses %s (AOE)" % [unit_name, label])
	for t in battle.opponents_of(self):
		deal_damage(t, multiplier)
