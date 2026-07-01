extends Node2D

var players: Array = []
var index: int = 0

var battle_start: bool = false

func _ready() -> void:
	players = get_children()
	for i in players.size():
		players[i].position = Vector2(0, i*180)
		
	# focuses the first alive player on load
	_focus_first_alive()

# finds the first alive player
func _focus_first_alive():
	index = 0
	for i in players.size():
		if not players[i].is_dead:
			index = i
			players[i].focus()
			break

# moves to the next alive player for command selection
func _on_enemy_group_next_player() -> void:
	if not battle_start:
		var old_index = index
		var temp_index = index
		
		for i in players.size():
			temp_index += 1
			if temp_index >= players.size():
				temp_index = 0
			
			if not players[temp_index].is_dead:
				index = temp_index
				switch_focus(index, old_index)
				break

func switch_focus(x, y):
	players[x].focus()
	players[y].unfocus()

# resets focus for a new round
func _on_enemy_group_start_choose() -> void:
	for p in players:
		p.unfocus()
	_focus_first_alive()
	battle_start = false

# hides ui focus when action phase starts
func _on_enemy_group_start_attack() -> void:
	print("Battle starts!!!")
	battle_start = true
	for i in players.size():
		players[i].unfocus()
