extends Node2D

@onready var y_offset = get_parent().y_offset

func update_legs(direction, on_floor, ducking):
	# Flip
	if direction.x:
		$Legs.flip_h = direction.x < 0
	
	# State
	var state = 'idle' if not ducking else 'duck'
	if on_floor and direction.x and not ducking:
		state = 'run'
	if not on_floor:
		state = 'jump'
	$Legs.animation = state
	
func update_torso(direction, ducking, _current_gun):
	# Ducking
	$Torso.position.y = y_offset if ducking else 0
	
	$AnimationTree['parameters/AK/blend_position'] = direction
