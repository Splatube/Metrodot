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

@export_group("Jump")
@export var jump_strength := 300
@export var gravity := 600
@export var terminal_velocity := 500
var jump := false
var faster_fall := false
var gravity_multiplier := 1.0

func _ready():
	$Timers/DashCooldown.wait_time = dash_cooldown

func _process(delta: float) -> void:
	apply_gravity(delta)
	if can_move:
		get_input()
		apply_movement(delta)
		
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
	
	if not is_on_wall_only() and not velocity.x:
		gravity_multiplier = 1
		
func on_dash_finished():
	velocity.x = move_toward(velocity.x, 0, 500)
	gravity_multiplier = 1

func apply_gravity(delta):
	velocity.y += gravity * delta
	velocity.y = velocity.y / 2 if faster_fall and velocity.y < 0 else velocity.y
	velocity.y *= gravity_multiplier
	velocity.y = min(velocity.y, terminal_velocity)
