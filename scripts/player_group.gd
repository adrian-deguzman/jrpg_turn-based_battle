extends Node2D

var players: Array = []
var index: int = 0

var battle_start: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	players = get_children()
	for i in players.size():
		players[i].position = Vector2(0, i*180)
		
		#players[0].focus()
	
	# Give focus to the first alive player right when the scene loads
	_focus_first_alive()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass

# Helper function to find the first player that isn't dead
func _focus_first_alive():
	index = 0
	for i in players.size():
		if not players[i].is_dead:
			index = i
			players[i].focus()
			break

func _on_enemy_group_next_player() -> void:
	if not battle_start:
		var old_index = index
		var temp_index = index
		
		# Loop through the array to find the NEXT alive player
		for i in players.size():
			temp_index += 1
			# If we reach the end of the array, loop back to the start
			if temp_index >= players.size():
				temp_index = 0
			
			if not players[temp_index].is_dead:
				index = temp_index
				switch_focus(index, old_index)
				break

func switch_focus(x, y):
	players[x].focus()
	players[y].unfocus()


func _on_enemy_group_start_choose() -> void:
	# Reset back to the first ALIVE player for a brand new round
	for p in players:
		p.unfocus()
	_focus_first_alive()
	battle_start = false


func _on_enemy_group_start_attack() -> void:
	print("Battle starts!!!")
	battle_start = true
	for i in players.size():
		players[i].unfocus()
