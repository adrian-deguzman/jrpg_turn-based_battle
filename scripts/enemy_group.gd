extends Node2D

@export var player_group: Node2D # Assign this in the Inspector!

var enemies: Array = []
var action_queue: Array = []
var is_battling: bool = false
var index: int = 0
@onready var choice: VBoxContainer = $"../CanvasLayer/choice"
@onready var action_text: Label = $"../CanvasLayer/ActionText" # Reference to our new UI

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
	for i in stack.size():
		var player_name = "Player " + str(i + 1)
		var target_enemy_name = "Enemy " + str(stack[i] + 1)
		var move_name = "Attack" # Hardcoded to attack until menu buttons are added
		
		_show_action_text(player_name, move_name, target_enemy_name)
		enemies[stack[i]].take_damage(1)
		await get_tree().create_timer(1).timeout
		
	# --- ENEMY PHASE ---
	var enemy_idx = 0
	for enemy in enemies:
		var chosen_move = "Attack" # Hardcoded for now. Later: enemy_moves.pick_random()
		var enemy_name = "Enemy " + str(enemy_idx + 1)
		
		# Ensure we have a reference to the player group and that there are players alive
		if player_group and player_group.players.size() > 0:
			# RNG: Pick a random player to attack
			var random_target = player_group.players.pick_random()
			
			# Find which player number this is for the text feed
			var target_idx = player_group.players.find(random_target)
			var target_player_name = "Player " + str(target_idx + 1)
			
			_show_action_text(enemy_name, chosen_move, target_player_name)
			random_target.take_damage(1)
			
		# Wait 1 second between enemy attacks for game feel
		await get_tree().create_timer(1).timeout
		enemy_idx += 1
		
	action_queue.clear()
	is_battling = false
	
	# Signal the start of a brand new round
	emit_signal("start_choose")
	show_choice()

# Helper function to generate the text based on the move used
func _show_action_text(actor: String, move: String, target: String):
	action_text.show()
	
	if move == "Attack":
		action_text.text = actor + " attacked " + target
	elif move == "Shoot":
		action_text.text = actor + " shot " + target
	elif move == "Drink Potion":
		action_text.text = actor + " drank potion"
	elif move == "Defend":
		action_text.text = actor + " defends themself."
	elif move == "Power Punch":
		# Note: The delayed 2-turn logic will need a state variable later, 
		# but here is the text generation for the charge phase!
		action_text.text = actor + " charges a punch..."

func switch_focus(x, y):
	enemies[x].focus()
	enemies[y].unfocus()

func show_choice():
	# action_text.hide() # REMOVED: We now use this to show whose turn it is
	action_text.show()
	
	var current_player_num = action_queue.size() + 1
	action_text.text = "(Choose move for Player " + str(current_player_num) + ")"
	
	choice.show()
	choice.find_child("Attack").grab_focus()

func _reset_focus():
	index = 0
	for enemy in enemies:
		enemy.unfocus()

func _start_choosing():
	_reset_focus()
	
	# Update text to reflect targeting phase
	var current_player_num = action_queue.size() + 1
	action_text.text = "(Choose target for Player " + str(current_player_num) + ")"
	
	# REMOVED: emit_signal("start_choose") 
	# (Emitting it here kept overriding the turn back to Player 0)
	enemies[0].focus()	


func _on_attack_pressed() -> void:
	choice.hide()
	_start_choosing()
