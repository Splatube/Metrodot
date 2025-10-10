@tool
extends Node2D

@export_enum('0', '1', '2', '3', '4', '5') var type = '0':
	set(value):
		if get_child_count() > 0 and value != null:
			type = value
			for child in $Options.get_children():
				child.hide()
			$Options.get_child(int(type)).show()
			$Options.get_child(int(type)).get_child(1).color = color
			$Options.get_child(int(type)).get_child(1).energy = strength
			
@export_color_no_alpha var color = Color(1.0,1.0,1.0):
	set(value):
		if get_child_count() > 0 and value != null:
			color = value
			$Options.get_child(int(type)).get_child(1).color = color

@export_range(0,10) var strength := 1.0:
	set(value):
		if get_child_count() > 0 and value != null:
			strength = value
			$Options.get_child(int(type)).get_child(1).energy = strength
		

func _process(delta):
	pass
