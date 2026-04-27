extends CharacterBody2D

@onready var _focus: Sprite2D = $focus
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var shield: Sprite2D = $Shield # Make sure you added this node!

@export var MAX_HEALTH: float = 7

var is_dead: bool = false # Add variable to track if the character is dead
var is_defending: bool = false # Add variable to track if they are blocking

var health: float = 3:
	set(value):
		# clampf ensures health never drops below 0 or goes above MAX_HEALTH
		health = clampf(value, 0, MAX_HEALTH) 
		_update_progress_bar()
		_play_animation()

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
		shield.show()

func reset_defend():
	is_defending = false
	if shield:
		shield.hide()
	
func take_damage(value):
	# If they are already dead, ignore any further damage
	if is_dead:
		return
		
	# Check if they are defending
	if is_defending:
		is_defending = false # They can only block ONE attack
		reset_defend()       # Hide the shield immediately
		return               # Exit the function early so NO damage is taken!
		
	# Check if this attack WILL kill them BEFORE changing the health
	# This ensures the setter plays the correct animation!
	if health - value <= 0:
		is_dead = true
		unfocus() # Immediately hide the focus ring when they die
		
	# Now update the health, which triggers the setter and plays the animation
	health -= value
