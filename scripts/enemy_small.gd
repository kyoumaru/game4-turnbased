class_name EnemySmall
extends Enemy

# Small enemy: just attacks a random target.

# Speed is passed in so each small enemy can have its own: EnemySmall.new(99)
func _init(spd := 99) -> void:
	super()
	unit_name = "Small"
	max_hp = 200
	atk = 12
	speed = spd
	attacks = [atk_1]


func atk_1(battle: Node) -> void:
	hit_random(battle, 1.0, "ATK 1")
