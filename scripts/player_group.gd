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
	
	# Give focus to the first player right when the scene loads
	if players.size() > 0:
		players[0].focus()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
	
func _on_enemy_group_next_player() -> void:
	if not battle_start:
		if index < players.size() - 1:
			index += 1
			switch_focus(index, index - 1)
		else:
			index = 0 
			switch_focus(index, players.size() - 1)

func switch_focus(x, y):
	players[x].focus()
	players[y].unfocus()


func _on_enemy_group_start_choose() -> void:
	# Reset back to Player 0 for a brand new round
	index = 0
	for p in players:
		p.unfocus()
	players[0].focus()
	battle_start = false


func _on_enemy_group_start_attack() -> void:
	print("Battle starts!!!")
	battle_start = true
	for i in players.size():
		players[i].unfocus()
