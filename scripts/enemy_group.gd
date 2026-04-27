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
			_move_enemy_focus(-1)
		if Input.is_action_just_pressed("ui_down"):
			_move_enemy_focus(1)
		if Input.is_action_just_pressed("ui_accept"):
			# Prevent the player from attacking an enemy that is already dead
			if enemies[index].is_dead:
				return
				
			#enemies[index].take_damage(1)
			action_queue.push_back(index)
			emit_signal("next_player")
			
			# Count how many players are actually alive
			var alive_players_count = 0
			if player_group:
				for p in player_group.players:
					if not p.is_dead:
						alive_players_count += 1
			
			# Note: We now check against alive players instead of enemies.size()
			if action_queue.size() == alive_players_count and not is_battling:
				is_battling = true
				_action(action_queue)
			elif not is_battling:
				# If not all players have chosen, show the menu for the next player!
				_reset_focus()
				show_choice()

# Helper to skip dead enemies when pressing up/down
func _move_enemy_focus(direction: int):
	var old_index = index
	var temp_index = index
	for i in enemies.size():
		temp_index += direction
		
		if temp_index < 0:
			temp_index = enemies.size() - 1
		elif temp_index >= enemies.size():
			temp_index = 0
			
		if not enemies[temp_index].is_dead:
			index = temp_index
			switch_focus(index, old_index)
			break
	
func _action(stack):
	_reset_focus()
	emit_signal("start_attack")
	
	# --- PLAYER PHASE ---
	var acting_player_idx = 0
	for i in player_group.players.size():
		# Skip dead players in the attack execution phase
		if player_group.players[i].is_dead:
			continue
			
		var target_enemy_idx = stack[acting_player_idx]
		
		var player_name = "Player " + str(i + 1)
		var target_enemy_name = "Enemy " + str(target_enemy_idx + 1)
		var move_name = "Attack" # Hardcoded to attack until menu buttons are added
		
		_show_action_text(player_name, move_name, target_enemy_name)
		enemies[target_enemy_idx].take_damage(1)
		await get_tree().create_timer(1).timeout
		
		acting_player_idx += 1
		
	# --- ENEMY PHASE ---
	var enemy_idx = 0
	for enemy in enemies:
		# Skip dead enemies so they don't attack
		if enemy.is_dead:
			enemy_idx += 1
			continue
			
		var chosen_move = "Attack" # Hardcoded for now. Later: enemy_moves.pick_random()
		var enemy_name = "Enemy " + str(enemy_idx + 1)
		
		# Get only the ALIVE players
		var alive_players = []
		if player_group:
			for p in player_group.players:
				if not p.is_dead:
					alive_players.append(p)
		
		# Ensure there are players alive before attacking
		if alive_players.size() > 0:
			# RNG: Pick a random ALIVE player to attack
			var random_target = alive_players.pick_random()
			
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

# Helper to find which player number should be displayed in the text
func _get_current_acting_player_num() -> int:
	var alive_players = []
	if player_group:
		for p in player_group.players:
			if not p.is_dead:
				alive_players.append(p)
				
	if alive_players.size() > 0 and action_queue.size() < alive_players.size():
		var current_player = alive_players[action_queue.size()]
		return player_group.players.find(current_player) + 1
	return 1

func show_choice():
	# action_text.hide() # REMOVED: We now use this to show whose turn it is
	action_text.show()
	
	var current_player_num = _get_current_acting_player_num()
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
	var current_player_num = _get_current_acting_player_num()
	action_text.text = "(Choose target for Player " + str(current_player_num) + ")"
	
	# Find first alive enemy to focus for targeting
	for i in enemies.size():
		if not enemies[i].is_dead:
			index = i
			enemies[i].focus()
			break

	# REMOVED: emit_signal("start_choose") 
	# (Emitting it here kept overriding the turn back to Player 0)


func _on_attack_pressed() -> void:
	choice.hide()
	_start_choosing()
