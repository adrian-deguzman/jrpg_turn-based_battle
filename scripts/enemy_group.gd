extends Node2D

var enemies: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	enemies = get_children()
	for i in enemies.size():
		enemies[i].position = Vector2(0, i*130)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
