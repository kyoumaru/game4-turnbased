class_name Enemy
extends Unit

# Base class for all enemies.
# Enemy scripts extend this, set their stats, and fill the `attacks` list.

var target_count := 1   # for hit_random: how many random targets
var attacks: Array = [] # Callables, each takes (battle)


func _init() -> void:
	is_player = false


func take_turn(battle: Node) -> void:
	if attacks.is_empty():
		return
	var attack: Callable = attacks.pick_random()
	attack.call(battle)


# Hits `target_count` random opponents
func hit_random(battle: Node, multiplier: float, label: String) -> void:
	print("%s uses %s" % [unit_name, label])
	for t in battle.random_targets(self, target_count):
		t.take_damage(int(atk * multiplier), self)


# Hits EVERY opponent (AOE)
func hit_all(battle: Node, multiplier: float, label: String) -> void:
	print("%s uses %s (AOE)" % [unit_name, label])
	for t in battle.opponents_of(self):
		t.take_damage(int(atk * multiplier), self)
