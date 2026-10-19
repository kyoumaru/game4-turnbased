class_name Enemy
extends Unit

var target_count := 1   # raise for multi-target
var attacks: Array = [] # Callables, each takes (battle)


func _init() -> void:
	unit_name = "Slime"
	max_hp = 100
	atk = 15
	speed = 95
	is_player = false
	# Add more attacks here (or in a subclass) and they join the random pool
	attacks = [atk_1, atk_2]


func take_turn(battle: Node) -> void:
	if attacks.is_empty():
		return
	var attack: Callable = attacks.pick_random()
	attack.call(battle)


# ATK 1: 100% damage
func atk_1(battle: Node) -> void:
	hit_random(battle, 1.0, "ATK 1")


# ATK 2: 150% damage
func atk_2(battle: Node) -> void:
	hit_random(battle, 1.5, "ATK 2")


# Helper so attacks stay one-liners
func hit_random(battle: Node, multiplier: float, label: String) -> void:
	print("%s uses %s" % [unit_name, label])
	for t in battle.random_targets(self, target_count):
		t.take_damage(int(atk * multiplier), self)
