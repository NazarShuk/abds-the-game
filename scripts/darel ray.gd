extends Node3D

@export var line_radius = 1
@export var line_resolution = 10

@export var curve : Curve3D

func set_curve():
	$Path3D.curve = curve
	
	var circle = PackedVector2Array()
	
	for degree in line_resolution:
		var x = line_radius * sin(PI * 2 * degree / line_resolution)
		var y = line_radius * cos(PI * 2 * degree / line_resolution)
		
		var cords = Vector2(x,y)
		circle.append(cords)
	
	$"darel ray".polygon = circle
