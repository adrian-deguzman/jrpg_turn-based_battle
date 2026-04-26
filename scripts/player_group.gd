extends Node2D

var players: Array = []
var index: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	players = get_children()
	for i in players.size():
		players[i].position = Vector2(0, i*180)
		
		players[0].focus()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	#if Input.is_action_just_pressed("ui_up"):
		#if index > 0:
			#index -= 1
			#switch_focus(index, index + 1)
	#if Input.is_action_just_pressed("ui_down"):
		#if index < enemies.size() - 1:
			#index += 1
			#switch_focus(index, index - 1)
	
func _on_enemy_group_next_player() -> void:
	if index < players.size() - 1:
		index += 1
		switch_focus(index, index - 1)
	else:
		index = 0 
		switch_focus(index, players.size() - 1)

func switch_focus(x, y):
	players[x].focus()
	players[y].unfocus()
