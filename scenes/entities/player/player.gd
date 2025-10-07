extends CharacterBody2D

@export_category("Movement")

@export_group("Move")
@export var speed := 200
@export var acceleration := 700
@export var friction := 900
@export var dash_strength := 600
@export_range(0.1,2) var dash_cooldown := 0.5
var direction := Vector2.ZERO
var can_move := true
var dash = false
var ducking = false
var on_wall = false

@export_group("Jump")
@export var jump_strength := 300
@export var gravity := 600
@export var terminal_velocity := 500
var jump := false
var faster_fall := false
var gravity_multiplier := 1.0

@export_group("Gun")
@export var crosshair_distance := 20
var aim_direction := Vector2.RIGHT
var gamepad_active = true
var current_gun = Global.guns.AK
const y_offset = 6

func _ready():
	$Timers/DashCooldown.wait_time = dash_cooldown

func _process(delta: float) -> void:
	apply_gravity(delta)
	if can_move:
		get_input()
		apply_movement(delta)
		animate()

func animate():
	$Crosshair.update(aim_direction, crosshair_distance, ducking)
	$Sprite.update_legs(direction, is_on_floor(), ducking)
	$Sprite.update_torso(aim_direction, ducking, current_gun)

func get_input():
	# Horizontal input
	direction.x = Input.get_axis("left", "right")
	
	# Jump input
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or $Timers/Coyote.time_left:
			jump = true
		
		if not is_on_floor() and velocity.y > 0:
			$Timers/JumpBuffer.start()
	if Input.is_action_just_released("jump") and not is_on_floor() and velocity.y < 0:
		faster_fall = true
	
	# Dash input
	if Input.is_action_just_pressed("dash") and velocity.x and $Timers/DashCooldown.is_stopped():
		dash = true
		$Timers/DashCooldown.start()
		
	# Duck input
	if Input.is_action_pressed("duck") and is_on_floor():
		ducking = true
	else:
		ducking = false
	
	## Gun inputs
		
	# Aim
	var aim_input_gamepad = Input.get_vector("aim_left","aim_right","aim_up","aim_down")
	var aim_input_mouse = get_local_mouse_position().normalized()
	var aim_input = aim_input_gamepad if gamepad_active else aim_input_mouse
	if aim_input.length() > 0.5:
		aim_direction = Vector2(round(aim_input.x), round(aim_input.y))
		
	# Switch gun
	if Input.is_action_just_pressed("switch"):
		current_gun = Global.guns[Global.guns.keys()[(current_gun + 1) % len(Global.guns)]]

func _input(event):
	if event is InputEventMouseMotion:
		gamepad_active = false
	if Input.get_vector("aim_left","aim_right","aim_up","aim_down"):
		gamepad_active = true 

func apply_movement(delta):
	# Horizontal movement
	if direction.x and not ducking:
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
	else: 
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	
	# Jump movement
	if jump or (is_on_floor() and $Timers/JumpBuffer.time_left):
		velocity.y = -jump_strength
		jump = false
		faster_fall = false
	var was_on_floor = is_on_floor()
	move_and_slide() ## Apply physics
	if was_on_floor and not is_on_floor() and velocity.y >= 0:
		$Timers/Coyote.start()
	
	# Dash movement
	if dash:
		dash = false
		var dash_tween = create_tween() ## Tween lets you interpolate two values plus more (move_toward with extra steps)
		dash_tween.tween_property(self, 'velocity:x', velocity.x + direction.x * dash_strength, 0.3)
		dash_tween.connect("finished", on_dash_finished)
		gravity_multiplier = 0.2
	
	if is_on_wall_only():
		gravity_multiplier = 0.5
		on_wall = true
		
	
	if not is_on_wall() and on_wall:
		$Timers/Coyote.start()
		gravity_multiplier = 1
		on_wall = false
		
func on_dash_finished():
	velocity.x = move_toward(velocity.x, 0, 500)
	gravity_multiplier = 1

func apply_gravity(delta):
	velocity.y += gravity * delta
	velocity.y = velocity.y / 2 if faster_fall and velocity.y < 0 else velocity.y
	velocity.y *= gravity_multiplier
	velocity.y = min(velocity.y, terminal_velocity)
