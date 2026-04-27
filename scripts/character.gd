extends CharacterBody2D

@onready var _focus: Sprite2D = $focus
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var shield: Sprite2D = $Shield # Make sure you added this node!
@onready var potion: Sprite2D = $Potion # NEW: Make sure you added the Potion node!

@export var MAX_HEALTH: float = 3

var is_dead: bool = false # Add variable to track if the character is dead
var is_defending: bool = false # Add variable to track if they are blocking

var health: float = MAX_HEALTH:
	set(value):
		# clampf ensures health never drops below 0 or goes above MAX_HEALTH
		health = clampf(value, 0, MAX_HEALTH) 
		_update_progress_bar()
		# REMOVED: _play_animation() from here so healing doesn't trigger "hurt"

func _update_progress_bar():
	progress_bar.value = (health / MAX_HEALTH) * 100

func _play_animation():
	if is_dead:
		animation_player.play("death")
		await get_tree().create_timer(1.0).timeout
		progress_bar.hide()
		
	else:
		animation_player.play("hurt")
		#animation_player.queue("idle")
	
func focus():
	# Only allow the focus ring to appear if the character is still alive
	if not is_dead:
		_focus.show()

func unfocus():
	_focus.hide()
	
# New Helper Functions for Defending
func defend():
	is_defending = true
	if shield:
		# reset the shield after "defense" animation
		shield.modulate = Color(1, 1, 1, 1)
		shield.self_modulate = Color(1, 1, 1, 1)
		shield.show()

func reset_defend():
	is_defending = false
	if shield:
		shield.hide()

# NEW: Helper function for healing
func heal(amount: float):
	if is_dead:
		return
		
	# Show the potion sprite
	if potion:
		potion.show()
		
	# Play the heal animation
	animation_player.play("heal")
	
	# Wait a bit, then hide the potion
	await get_tree().create_timer(2.0).timeout
	
	# Increase the health (the setter will automatically clamp it to MAX_HEALTH)
	# Because we removed _play_animation() from the setter, this will no longer override "heal"!
	health += amount 
	
	if potion:
		potion.hide()
	
func take_damage(value):
	# If they are already dead, ignore any further damage
	if is_dead:
		return
		
	# Check if they are defending
	if is_defending:
		is_defending = false # They can only block ONE attack
		
		# Play your custom animation instead of instantly hiding the shield!
		animation_player.play("defense") 
		
		return               # Exit the function early so NO damage is taken!
		
	# Check if this attack WILL kill them BEFORE changing the health
	if health - value <= 0:
		is_dead = true
		unfocus() # Immediately hide the focus ring when they die
		
	# Now update the health
	health -= value
	
	# explicitly call the animation ONLY when taking damage!
	_play_animation()

# NEW: Helper function to play the charge animation
func play_charge_animation():
	if not is_dead:
		animation_player.play("charge")
