extends CharacterBody2D

@onready var _focus: Sprite2D = $focus
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var shield: Sprite2D = $Shield
@onready var potion: Sprite2D = $Potion

@export var MAX_HEALTH: float = 3

var is_dead: bool = false # tracks if dead for win/loss
var is_defending: bool = false # tracks block

# health bar style
var fill_style: StyleBoxFlat 

var health: float = MAX_HEALTH:
	set(value):
		# keeps health from 0-100
		health = clampf(value, 0, MAX_HEALTH) 
		_update_progress_bar()
		# 

# setups health bar colors
func _ready() -> void:
	# creates unique stylebox
	# prevents coloring all enemies at once
	var default_style = progress_bar.get_theme_stylebox("fill")
	if default_style is StyleBoxFlat:
		fill_style = default_style.duplicate()
	else:
		fill_style = StyleBoxFlat.new()
		
	# applies unique style
	progress_bar.add_theme_stylebox_override("fill", fill_style)
	_update_progress_bar()

func _update_progress_bar():
	var percentage = (health / MAX_HEALTH) * 100
	progress_bar.value = percentage
	
	# changes color based on percentage
	if fill_style:
		if percentage >= 68:
			# green for high health
			fill_style.bg_color = Color("#2d5a27") 
		elif percentage >= 35:
			# yellow for mid health
			fill_style.bg_color = Color("#b58b00")
		else:
			# red for low health
			fill_style.bg_color = Color("#8b0000")

func _play_animation():
	if is_dead:
		animation_player.play("death")
		await get_tree().create_timer(1.0).timeout
		progress_bar.hide()
		
	else:
		animation_player.play("hurt")

	
func focus():
	# shows focus ring if alive
	if not is_dead:
		_focus.show()

func unfocus():
	_focus.hide()
	
# defend command logic
func defend():
	is_defending = true
	if shield:
		# resets shield color
		shield.modulate = Color(1, 1, 1, 1)
		shield.self_modulate = Color(1, 1, 1, 1)
		shield.show()

func reset_defend():
	is_defending = false
	if shield:
		shield.hide()

# item command for healing
func heal(amount: float):
	if is_dead:
		return
		
	# shows potion
	if potion:
		potion.show()
		
	# plays heal anim
	animation_player.play("heal")
	
	# waits before hiding
	await get_tree().create_timer(2.0).timeout
	
	# adds health
	health += amount 
	
	if potion:
		potion.hide()
	
func take_damage(value):
	# ignores damage if dead
	if is_dead:
		return
		
	# checks if defending
	if is_defending:
		is_defending = false # blocks one attack
		
		# plays defense anim
		animation_player.play("defense") 
		
		return               # exits early to prevent damage
		
	# checks for death
	if health - value <= 0:
		is_dead = true
		unfocus() # hides focus
		
	# updates health
	health -= value
	
	# plays damage anim
	_play_animation()

# animation for charging state
func play_charge_animation():
	if not is_dead:
		var tween = create_tween()
		# shrinks character
		tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.2)
		
		tween.parallel().tween_property(self, "modulate", Color(1, 0.3, 0.3), 0.2)

# animation for charge launch
func stop_charge_animation():
	if not is_dead:
		var tween = create_tween()
		
		# resets color
		tween.tween_property(self, "modulate", Color(1, 1, 1), 0.1)
		
		# scales up for big punch
		tween.parallel().tween_property(self, "scale", Vector2(1.5, 1.5), 0.1)
		
		# scales back to normal
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
		
		animation_player.play("idle") # returns to idle

# animation for normal attack
func play_attack_animation():
	if not is_dead:
		var tween = create_tween()
		# scales up
		tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
		# scales back
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
