extends Node2D

@export var player_group: Node2D # Assign this in the Inspector!

var enemies: Array = []
var action_queue: Array = []
var is_battling: bool = false
var index: int = 0
@onready var choice: VBoxContainer = $"../CanvasLayer/choice"

# The choices the enemy can make
var enemy_moves: Array = ["Attack", "Shoot", "Defend", "Drink Potion", "Power Punch"]

signal start_choose
signal next_player
signal start_attack

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	enemies = get_children()
	for i in enemies.size():
		enemies[i].position = Vector2(0, i*180)
		
		#enemies[0].focus()
	show_choice()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not choice.visible:
		if Input.is_action_just_pressed("ui_up"):
			if index > 0:
				index -= 1
				switch_focus(index, index + 1)
		if Input.is_action_just_pressed("ui_down"):
			if index < enemies.size() - 1:
				index += 1
				switch_focus(index, index - 1)
		if Input.is_action_just_pressed("ui_accept"):
			#enemies[index].take_damage(1)
			action_queue.push_back(index)
			emit_signal("next_player")
			
			# Note: Using enemies.size() assumes player party size is equal to enemy party size.
			if action_queue.size() == enemies.size() and not is_battling:
				is_battling = true
				_action(action_queue)
			elif not is_battling:
				# If not all players have chosen, show the menu for the next player!
				_reset_focus()
				show_choice()
	
func _action(stack):
	_reset_focus()
	emit_signal("start_attack")
	
	# --- PLAYER PHASE ---
	for i in stack:
		enemies[i].take_damage(1)
		await get_tree().create_timer(1).timeout
		
	# --- ENEMY PHASE ---
	for enemy in enemies:
		var chosen_move = "Attack" # Hardcoded for now. Later: enemy_moves.pick_random()
		print("Enemy uses: ", chosen_move)
		
		# Ensure we have a reference to the player group and that there are players alive
		if player_group and player_group.players.size() > 0:
			# RNG: Pick a random player to attack
			var random_target = player_group.players.pick_random()
			random_target.take_damage(1)
			
		# Wait 1 second between enemy attacks for game feel
		await get_tree().create_timer(1).timeout
		
	action_queue.clear()
	is_battling = false
	
	# Signal the start of a brand new round
	emit_signal("start_choose")
	show_choice()
	
func switch_focus(x, y):
	enemies[x].focus()
	enemies[y].unfocus()

func show_choice():
	choice.show()
	choice.find_child("Attack").grab_focus()

func _reset_focus():
	index = 0
	for enemy in enemies:
		enemy.unfocus()

func _start_choosing():
	_reset_focus()
	# REMOVED: emit_signal("start_choose") 
	# (Emitting it here kept overriding the turn back to Player 0)
	enemies[0].focus()	


func _on_attack_pressed() -> void:
	choice.hide()
	_start_choosing()
