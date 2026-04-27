extends Node2D

@export var player_group: Node2D # handles player party

var enemies: Array = []
var action_queue: Array = []
var is_battling: bool = false
var index: int = 0
var wait_time: int = 2.5

# stores selected command
var current_selected_move: String = "Attack" 

# tracks charging state across turns
var player_charging_targets: Dictionary = {}
var enemy_charging_targets: Dictionary = {}

@onready var choice: VBoxContainer = $"../CanvasLayer/choice"
@onready var action_text: Label = $"../CanvasLayer/ActionText" # ui text

# ui for win or loss screens
@onready var game_over_screen: Panel = $"../CanvasLayer/GameOverScreen" 
@onready var game_over_text: Label = $"../CanvasLayer/GameOverScreen/GameOverText"
@onready var restart_button: Button = $"../CanvasLayer/GameOverScreen/RestartButton"

# enemy commands
var enemy_moves: Array = ["Attack", "Defend", "Drink Potion", "Shoot", "Power Punch"]

signal start_choose
signal next_player
signal start_attack

func _ready() -> void:
	enemies = get_children()
	for i in enemies.size():
		enemies[i].position = Vector2(0, i*180)
	show_choice()

func _process(delta: float) -> void:
	if not choice.visible and not game_over_screen.visible: # prevents input if game over
		if Input.is_action_just_pressed("ui_up"):
			_move_enemy_focus(-1)
		if Input.is_action_just_pressed("ui_down"):
			_move_enemy_focus(1)
		if Input.is_action_just_pressed("ui_accept"):
			if enemies[index].is_dead:
				return
			action_queue.push_back({"move": current_selected_move, "target": index})
			emit_signal("next_player")
			_check_action_queue()

func _check_action_queue():
	var alive_players_count = 0
	if player_group:
		for p in player_group.players:
			if not p.is_dead:
				alive_players_count += 1
	
	if action_queue.size() == alive_players_count and not is_battling:
		is_battling = true
		_action(action_queue)
	elif not is_battling:
		_reset_focus()
		show_choice()

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
			
# checks for party wipeouts
func _check_end_battle() -> bool:
	var alive_players = 0
	if player_group:
		for p in player_group.players:
			if not p.is_dead:
				alive_players += 1
				
	var alive_enemies = 0
	for e in enemies:
		if not e.is_dead:
			alive_enemies += 1
			
	if alive_enemies == 0:
		_show_game_over("You won!")
		return true
	elif alive_players == 0:
		_show_game_over("You lost!")
		return true
		
	return false

func _show_game_over(message: String):
	action_text.hide()
	choice.hide()
	_reset_focus()
	
	game_over_text.text = message
	game_over_screen.show()
	restart_button.grab_focus()
	
# main loop for classic turn-based combat
func _action(stack):
	_reset_focus()
	emit_signal("start_attack")
	
	var enemy_chosen_moves = []
	for enemy_idx in enemies.size():
		var enemy = enemies[enemy_idx]
		if enemy.is_dead:
			enemy_chosen_moves.append("Skip")
		elif enemy_charging_targets.has(enemy_idx):
			# forces launch if charging last round
			enemy_chosen_moves.append("Power Punch Launch")
		else:
			var move = enemy_moves.pick_random()
			enemy_chosen_moves.append(move)
			if move == "Defend":
				enemy.defend()
				
	var setup_player_idx = 0
	for i in player_group.players.size():
		if not player_group.players[i].is_dead:
			var action = stack[setup_player_idx]
			if action.move == "Defend":
				player_group.players[i].defend()
			setup_player_idx += 1
	
	# player phase
	var acting_player_idx = 0
	for i in player_group.players.size():
		if player_group.players[i].is_dead:
			continue
			
		var action = stack[acting_player_idx]
		var player_name = "Player " + str(i + 1)
		
		if action.move == "Attack":
			var target_enemy_idx = action.target
			var target_enemy_name = "Enemy " + str(target_enemy_idx + 1)
			
			_show_action_text(player_name, action.move, target_enemy_name)
			player_group.players[i].play_attack_animation()
			enemies[target_enemy_idx].take_damage(1)
			
		elif action.move == "Shoot":
			var target_enemy_idx = action.target
			var target_enemy_name = "Enemy " + str(target_enemy_idx + 1)
			
			# rng hit chance
			var is_hit = randf() <= 0.5 
			_show_action_text(player_name, action.move, target_enemy_name, is_hit)
			
			if is_hit:
				player_group.players[i].play_attack_animation()
				enemies[target_enemy_idx].take_damage(2.5)
				
		elif action.move == "Power Punch":
			# charge phase
			var target_enemy_idx = action.target
			player_charging_targets[i] = target_enemy_idx
			_show_action_text(player_name, "Power Punch Charge", "")
			player_group.players[i].play_charge_animation() 
			
		elif action.move == "Power Punch Launch":
			# launch phase
			var target_enemy_idx = action.target
			player_charging_targets.erase(i)
			var target_enemy_name = "Enemy " + str(target_enemy_idx + 1)
			
			_show_action_text(player_name, "Power Punch Launch", target_enemy_name)
			player_group.players[i].stop_charge_animation()
			player_group.players[i].play_attack_animation()
			enemies[target_enemy_idx].take_damage(2.5)
			
		elif action.move == "Defend":
			_show_action_text(player_name, action.move, "")
			
		elif action.move == "Drink Potion":
			_show_action_text(player_name, action.move, "")
			player_group.players[i].heal(0.5)
			
		await get_tree().create_timer(wait_time).timeout
		action_text.hide()
		
		if _check_end_battle():
			return
			
		await get_tree().create_timer(0.5).timeout
		
		acting_player_idx += 1
	
	await get_tree().create_timer(0.5).timeout

	# enemy phase
	var enemy_idx = 0
	for enemy in enemies:
		if enemy.is_dead:
			enemy_idx += 1
			continue
			
		var chosen_move = enemy_chosen_moves[enemy_idx] 
		var enemy_name = "Enemy " + str(enemy_idx + 1)
		
		if chosen_move == "Attack":
			var alive_players = []
			if player_group:
				for p in player_group.players:
					if not p.is_dead:
						alive_players.append(p)
			
			if alive_players.size() > 0:
				# rng for enemy target selection
				var random_target = alive_players.pick_random()
				var target_idx = player_group.players.find(random_target)
				var target_player_name = "Player " + str(target_idx + 1)
				
				_show_action_text(enemy_name, chosen_move, target_player_name)
				enemy.play_attack_animation()
				random_target.take_damage(1)
				
		elif chosen_move == "Shoot":
			var alive_players = []
			if player_group:
				for p in player_group.players:
					if not p.is_dead:
						alive_players.append(p)
						
			if alive_players.size() > 0:
				var random_target = alive_players.pick_random()
				var target_idx = player_group.players.find(random_target)
				var target_player_name = "Player " + str(target_idx + 1)
				
				var is_hit = randf() <= 0.5 
				_show_action_text(enemy_name, chosen_move, target_player_name, is_hit)
				
				if is_hit:
					enemy.play_attack_animation()
					random_target.take_damage(2.5)
					
		elif chosen_move == "Power Punch":
			var alive_players = []
			if player_group:
				for p in player_group.players:
					if not p.is_dead:
						alive_players.append(p)
			if alive_players.size() > 0:
				var random_target = alive_players.pick_random()
				var target_idx = player_group.players.find(random_target)
				enemy_charging_targets[enemy_idx] = target_idx
				_show_action_text(enemy_name, "Power Punch Charge", "")
				enemy.play_charge_animation() 
				
		elif chosen_move == "Power Punch Launch":
			var target_idx = enemy_charging_targets[enemy_idx]
			enemy_charging_targets.erase(enemy_idx)
			var target_player_name = "Player " + str(target_idx + 1)
			
			_show_action_text(enemy_name, "Power Punch Launch", target_player_name)
			enemy.stop_charge_animation()
			enemy.play_attack_animation()
			player_group.players[target_idx].take_damage(2.5)
				
		elif chosen_move == "Defend":
			_show_action_text(enemy_name, chosen_move, "")
			
		elif chosen_move == "Drink Potion":
			_show_action_text(enemy_name, chosen_move, "")
			enemy.heal(0.5)
			
		await get_tree().create_timer(wait_time).timeout
		action_text.hide()
		
		if _check_end_battle():
			return
			
		await get_tree().create_timer(0.5).timeout
		enemy_idx += 1
		
	if player_group:
		for p in player_group.players:
			p.reset_defend()
	for enemy in enemies:
		enemy.reset_defend()
		
	action_queue.clear()
	is_battling = false
	
	emit_signal("start_choose")
	show_choice()

# updates text feed with battle events
func _show_action_text(actor: String, move: String, target: String, is_hit: bool = true):
	action_text.show()
	
	if move == "Attack":
		action_text.text = actor + " attacked " + target
	elif move == "Shoot":
		if is_hit:
			action_text.text = actor + " shot " + target + " for 2.5 damage!"
		else:
			action_text.text = actor + " shot at " + target + " but missed!"
	elif move == "Drink Potion":
		action_text.text = actor + " drank potion"
	elif move == "Defend":
		action_text.text = actor + " defends themself."
	elif move == "Power Punch Charge":
		action_text.text = actor + " is charging a Power Punch!"
	elif move == "Power Punch Launch":
		action_text.text = actor + " launches a Power Punch at " + target + " for 2.5 damage!"

func switch_focus(x, y):
	enemies[x].focus()
	enemies[y].unfocus()

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

# shows command menu for current player
func show_choice():
	action_text.show()
	
	var alive_players = []
	if player_group:
		for p in player_group.players:
			if not p.is_dead:
				alive_players.append(p)
				
	if alive_players.size() > 0 and action_queue.size() < alive_players.size():
		var current_player = alive_players[action_queue.size()]
		var current_player_idx = player_group.players.find(current_player)
		
		if player_charging_targets.has(current_player_idx):
			action_queue.push_back({"move": "Power Punch Launch", "target": player_charging_targets[current_player_idx]})
			emit_signal("next_player")
			_check_action_queue()
			return
			
		var current_player_num = current_player_idx + 1
		action_text.text = "(Choose move for Player " + str(current_player_num) + ")"
	
	choice.show()
	choice.find_child("Attack").grab_focus()

func _reset_focus():
	index = 0
	for enemy in enemies:
		enemy.unfocus()

func _start_choosing():
	_reset_focus()
	
	var current_player_num = _get_current_acting_player_num()
	action_text.text = "(Choose target for Player " + str(current_player_num) + ")"
	
	for i in enemies.size():
		if not enemies[i].is_dead:
			index = i
			enemies[i].focus()
			break

func _on_attack_pressed() -> void:
	current_selected_move = "Attack" 
	choice.hide()
	_start_choosing()

func _on_shoot_pressed() -> void:
	current_selected_move = "Shoot" 
	choice.hide()
	_start_choosing()
	
func _on_power_punch_pressed() -> void:
	current_selected_move = "Power Punch" 
	choice.hide()
	_start_choosing()

func _on_defend_pressed() -> void:
	choice.hide()
	action_queue.push_back({"move": "Defend", "target": -1})
	emit_signal("next_player")
	_check_action_queue()

func _on_drink_potion_pressed() -> void:
	choice.hide()
	action_queue.push_back({"move": "Drink Potion", "target": -1})
	emit_signal("next_player")
	_check_action_queue()

func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()
